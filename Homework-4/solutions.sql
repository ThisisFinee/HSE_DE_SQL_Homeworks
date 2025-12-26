-- Создадим таблицы перед выполнением задач
CREATE TABLE students
  ( record_book numeric( 5 ) NOT NULL,
  name text NOT NULL,
  doc_ser numeric( 4 ),
  doc_num numeric( 6 ),
  PRIMARY KEY ( record_book )
);

CREATE TABLE progress
  ( record_book numeric( 5 ) NOT NULL,
  subject text NOT NULL,
  acad_year text NOT NULL,
  term numeric( 1 ) NOT NULL CHECK ( term = 1 OR term = 2 ),
  mark numeric( 1 ) NOT NULL CHECK ( mark >= 3 AND mark <= 5 )
  DEFAULT 5,
  FOREIGN KEY ( record_book )
  REFERENCES students ( record_book )
  ON DELETE CASCADE
  ON UPDATE CASCADE
);


-- 1) Добавляем столбец test_form (если таблица не пустая — добавляйте сначала NULL, потом заполнение и SET NOT NULL)
ALTER TABLE progress
  ADD COLUMN IF NOT EXISTS test_form text;

-- Если в таблице уже есть строки:
-- UPDATE progress SET test_form = 'экзамен' WHERE test_form IS NULL;

ALTER TABLE progress
  ALTER COLUMN test_form SET NOT NULL;

-- Убедимся, что mark тоже NOT NULL (по условию задания)
ALTER TABLE progress
  ALTER COLUMN mark SET NOT NULL;

-- 2) Пробуем добавить новое ограничение (может конфликтовать со старым CHECK на mark 3..5)
-- На всякий случай удалим наиболее типичные имена старого ограничения (если есть)
ALTER TABLE progress DROP CONSTRAINT IF EXISTS progress_mark_check;
ALTER TABLE progress DROP CONSTRAINT IF EXISTS validmark;
ALTER TABLE progress DROP CONSTRAINT IF EXISTS progress_validmark_check;

-- 3) Добавляем новое ограничение уровня таблицы
ALTER TABLE progress
  ADD CONSTRAINT progress_test_form_mark_check
  CHECK (
    (test_form = 'экзамен' AND mark IN (3, 4, 5))
    OR
    (test_form = 'зачет' AND mark IN (0, 1))
  );

-- 4) Проверка: корректные вставки
INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Математика', '2024/2025', 1, 'экзамен', 5);

INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Физкультура', '2024/2025', 1, 'зачет', 1);

-- 5) Проверка: нарушения (должны падать по CHECK)
-- экзамен не допускает 1
INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'История', '2024/2025', 1, 'экзамен', 1);

-- зачет не допускает 4
INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Английский', '2024/2025', 1, 'зачет', 4);

-- 9) Запрет пустых/пробельных name в students
-- 1) Демонстрация: NOT NULL пропускает пустую строку
-- INSERT INTO students (record_book, name, doc_ser, doc_num)
-- VALUES (12300, '', 0402, 543281);

-- 2) Добавляем CHECK против пустых строк
ALTER TABLE students
  ADD CONSTRAINT students_name_not_empty_check
  CHECK (name <> '');

-- 3) Пробуем пробелы (они пройдут, т.к. length(' ') > 0)
INSERT INTO students (record_book, name, doc_ser, doc_num)
VALUES (12346, ' ', 0406, 112233);

INSERT INTO students (record_book, name, doc_ser, doc_num)
VALUES (12347, '  ', 0407, 112234);

SELECT *, length(name) AS name_len
FROM students
WHERE record_book IN (12300, 12346, 12347);

-- 4) Усиливаем ограничение: запрещаем строки из пробелов (trim/btrim)
ALTER TABLE students DROP CONSTRAINT IF EXISTS students_name_not_empty_check;

ALTER TABLE students
  ADD CONSTRAINT students_name_not_blank_check
  CHECK (btrim(name) <> '');


-- 17) Представления для разных групп пользователей (пример)
-- Пассажиры: расписание (без внутренних ID, только полезные поля)
CREATE OR REPLACE VIEW v_passengers_timetable AS
SELECT
  flight_no,
  scheduled_departure,
  scheduled_arrival,
  departure_city,
  arrival_city,
  status
FROM flights_v;

-- Пилоты: расписание + тип ВС
CREATE OR REPLACE VIEW v_pilots_roster AS
SELECT
  f.flight_id,
  f.flight_no,
  f.scheduled_departure,
  f.scheduled_arrival,
  f.departure_airport,
  f.arrival_airport,
  a.aircraft_code,
  a.model,
  f.status
FROM flights f
JOIN aircrafts a ON a.aircraft_code = f.aircraft_code;

-- Диспетчеры: расширенный контроль (факт. времена + статус)
CREATE OR REPLACE VIEW v_dispatchers_control AS
SELECT
  f.flight_id,
  f.flight_no,
  f.status,
  f.scheduled_departure,
  f.actual_departure,
  f.scheduled_arrival,
  f.actual_arrival,
  f.departure_airport,
  f.arrival_airport,
  f.aircraft_code
FROM flights f;

-- Кассиры: брони + билеты (основные реквизиты)
CREATE OR REPLACE VIEW v_cashiers_sales AS
SELECT
  b.book_ref,
  b.book_date,
  b.total_amount,
  t.ticket_no,
  t.passenger_name,
  t.contact_data
FROM bookings b
JOIN tickets t ON t.book_ref = b.book_ref;

-- Проверка представлений
SELECT * FROM v_passengers_timetable LIMIT 5;
SELECT * FROM v_pilots_roster LIMIT 5;
SELECT * FROM v_dispatchers_control LIMIT 5;
SELECT * FROM v_cashiers_sales LIMIT 5;


-- 18) jsonb в aircrafts.specifications + предложения, куда еще добавить jsonb
ALTER TABLE aircrafts
  ADD COLUMN IF NOT EXISTS specifications jsonb;

UPDATE aircrafts
SET specifications = '{ "crew": 2, "engines": { "type": "IAE V2500", "num": 2 } }'::jsonb
WHERE aircraft_code = '320';

SELECT model, specifications
FROM aircrafts
WHERE aircraft_code = '320';

SELECT model, specifications->'engines' AS engines
FROM aircrafts
WHERE aircraft_code = '320';

SELECT model, specifications #> '{engines,type}' AS engine_type
FROM aircrafts
WHERE aircraft_code = '320';

-- Пример 1: дополним airports произвольными jsonb-метаданными (контакты/сервисы/заметки)
ALTER TABLE airports
  ADD COLUMN IF NOT EXISTS meta jsonb;

UPDATE airports
SET meta = '{ "contacts": { "phone": "+7-000-000-00-00" }, "services": ["wifi","lounge"] }'::jsonb
WHERE airport_code = (SELECT airport_code FROM airports ORDER BY airport_code LIMIT 1);

SELECT airport_code, airport_name, meta
FROM airports
WHERE meta IS NOT NULL
ORDER BY airport_code
LIMIT 3;
