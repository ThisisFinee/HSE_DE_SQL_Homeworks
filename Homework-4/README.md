# Homework-3 (Глава 5)
## Перед выполнением
Создадим таблицы progress и student:

```sql
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
```
## Задача номер 2 из главы 5
Ограничения progress + ограничение, зависящее от test_form (экзамен/зачет) и проверка конфликтов со старым CHECK на mark.

Решение:
```sql
-- \d progress

ALTER TABLE progress ADD COLUMN IF NOT EXISTS test_form text;
ALTER TABLE progress ALTER COLUMN test_form SET NOT NULL;
ALTER TABLE progress ALTER COLUMN mark SET NOT NULL;

ALTER TABLE progress DROP CONSTRAINT IF EXISTS progress_mark_check;
ALTER TABLE progress DROP CONSTRAINT IF EXISTS validmark;
ALTER TABLE progress DROP CONSTRAINT IF EXISTS progress_validmark_check;

ALTER TABLE progress
  ADD CONSTRAINT progress_test_form_mark_check
  CHECK (
    (test_form = 'экзамен' AND mark IN (3, 4, 5))
    OR
    (test_form = 'зачет' AND mark IN (0, 1))
  );

INSERT INTO students (record_book, name)
VALUES (12345, 'Ivan');
-- Успешные вставки
INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Математика', '2024/2025', 1, 'экзамен', 5);

INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Физкультура', '2024/2025', 1, 'зачет', 1);

-- Ошибочные вставки
INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'История', '2024/2025', 1, 'экзамен', 1);

INSERT INTO progress (record_book, subject, acad_year, term, test_form, mark)
VALUES (12345, 'Английский', '2024/2025', 1, 'зачет', 4);

-- Идея доп. ограничения:
ALTER TABLE progress ADD UNIQUE (record_book, subject, acad_year, term);
```

Результат запроса:
```sql
INSERT 0 1 -- student

INSERT 0 1
INSERT 0 1

ERROR:  new row for relation "progress" violates check constraint "progress_test_form_mark_check"
DETAIL:  Failing row contains (12345, История, 2024/2025, 1, 1, экзамен).

ERROR:  new row for relation "progress" violates check constraint "progress_test_form_mark_check"
DETAIL:  Failing row contains (12345, Английский, 2024/2025, 1, 4, зачет).
```

Вывод:
```
Старое ограничение CHECK на mark конфликтует с новым правилом, потому что для test_form='зачет' нужны значения 0 и 1.
Чтобы добавить новое ограничение, старый CHECK на mark нужно удалить (по имени, найденному через \d), после чего новое составное CHECK начнет корректно отсеивать неверные комбинации.
Дополнительно логично запретить дубликаты попыток сдачи одной дисциплины в один год/семестр (UNIQUE по record_book, subject, acad_year, term).
```


## Задача номер 9 из главы 5
Проверка: пустая строка проходит NOT NULL для students.name; запрет пустых и «невидимых» значений.

Решение:
```sql
INSERT INTO students (record_book, name, doc_ser, doc_num)
VALUES (12300, '', 0402, 543281);

ALTER TABLE students
  ADD CONSTRAINT students_name_not_empty_check
  CHECK (name <> '');

INSERT INTO students (record_book, name, doc_ser, doc_num)
VALUES (12346, ' ', 0406, 112233);

INSERT INTO students (record_book, name, doc_ser, doc_num)
VALUES (12347, '  ', 0407, 112234);

SELECT *, length(name) AS name_len
FROM students
WHERE record_book IN (12300, 12346, 12347);

ALTER TABLE students DROP CONSTRAINT IF EXISTS students_name_not_empty_check;

ALTER TABLE students
  ADD CONSTRAINT students_name_not_blank_check
  CHECK (btrim(name) <> '');
```

Результат запроса:
```sql
ALTER TABLE

INSERT 0 1
INSERT 0 1

record_book | name | doc_ser | doc_num | name_len
-------------+------+---------+---------+----------
       12346 |      |     406 |  112233 |        1
       12347 |      |     407 |  112234 |        2
(2 rows)
```

Вывод:
```
NOT NULL запрещает только NULL, но не запрещает пустую строку '' и строки из пробелов.
Чтобы запретить и пробелы, нужен CHECK с trim/btrim: btrim(name) <> ''.
Похожая уязвимость возможна и в progress (например subject/acad_year), если для них не задан аналогичный CHECK на «непустоту после trim».
```


## Задача номер 17 из главы 5
Создать полезные представления (вертикальные/горизонтальные) для разных групп пользователей: пилоты, диспетчеры, пассажиры, кассиры.

Решение:
```sql
CREATE OR REPLACE VIEW v_passengers_timetable AS
SELECT
  flight_no,
  scheduled_departure,
  scheduled_arrival,
  departure_city,
  arrival_city,
  status
FROM flights_v;

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

SELECT * FROM v_passengers_timetable LIMIT 5;
SELECT * FROM v_pilots_roster LIMIT 5;
SELECT * FROM v_dispatchers_control LIMIT 5;
SELECT * FROM v_cashiers_sales LIMIT 5;
```

Результат запроса:
```sql
-- v_passengers_timetable
 flight_no |  scheduled_departure   |   scheduled_arrival    | departure_city |  arrival_city   |  status
-----------+------------------------+------------------------+----------------+-----------------+-----------
 PG0405    | 2016-09-13 05:35:00+00 | 2016-09-13 06:30:00+00 | Москва         | Санкт-Петербург | Arrived
 PG0404    | 2016-10-03 15:05:00+00 | 2016-10-03 16:00:00+00 | Москва         | Санкт-Петербург | Arrived
 PG0405    | 2016-10-03 05:35:00+00 | 2016-10-03 06:30:00+00 | Москва         | Санкт-Петербург | Arrived
 PG0402    | 2016-11-07 08:25:00+00 | 2016-11-07 09:20:00+00 | Москва         | Санкт-Петербург | Scheduled
 PG0405    | 2016-10-14 05:35:00+00 | 2016-10-14 06:30:00+00 | Москва         | Санкт-Петербург | On Time
(5 rows)

-- v_pilots_roster
flight_id | flight_no |  scheduled_departure   |   scheduled_arrival    | departure_airport | arrival_airport | aircraft_code |      model      |  status
-----------+-----------+------------------------+------------------------+-------------------+-----------------+---------------+-----------------+-----------
1 | PG0405    | 2016-09-13 05:35:00+00 | 2016-09-13 06:30:00+00 | DME               | LED             | 321           | Airbus A321-200 | Arrived
2 | PG0404    | 2016-10-03 15:05:00+00 | 2016-10-03 16:00:00+00 | DME               | LED             | 321           | Airbus A321-200 | Arrived
3 | PG0405    | 2016-10-03 05:35:00+00 | 2016-10-03 06:30:00+00 | DME               | LED             | 321           | Airbus A321-200 | Arrived
4 | PG0402    | 2016-11-07 08:25:00+00 | 2016-11-07 09:20:00+00 | DME               | LED             | 321           | Airbus A321-200 | Scheduled
5 | PG0405    | 2016-10-14 05:35:00+00 | 2016-10-14 06:30:00+00 | DME               | LED             | 321           | Airbus A321-200 | On Time
(5 rows)

-- v_dispatchers_control
 flight_id | flight_no |  status   |  scheduled_departure   |    actual_departure    |   scheduled_arrival    |     actual_arrival     | departure_airport | arrival_airport | aircraft_code
-----------+-----------+-----------+------------------------+------------------------+------------------------+------------------------+-------------------+-----------------+---------------
1 | PG0405    | Arrived   | 2016-09-13 05:35:00+00 | 2016-09-13 05:44:00+00 | 2016-09-13 06:30:00+00 | 2016-09-13 06:39:00+00 | DME               | LED             | 321
2 | PG0404    | Arrived   | 2016-10-03 15:05:00+00 | 2016-10-03 15:06:00+00 | 2016-10-03 16:00:00+00 | 2016-10-03 16:01:00+00 | DME               | LED             | 321
3 | PG0405    | Arrived   | 2016-10-03 05:35:00+00 | 2016-10-03 05:39:00+00 | 2016-10-03 06:30:00+00 | 2016-10-03 06:34:00+00 | DME               | LED             | 321
4 | PG0402    | Scheduled | 2016-11-07 08:25:00+00 |                        | 2016-11-07 09:20:00+00 |                        | DME               | LED             | 321
5 | PG0405    | On Time   | 2016-10-14 05:35:00+00 |                        | 2016-10-14 06:30:00+00 |                        | DME               | LED             | 321
(5 rows)

--v_cashiers_sales
 book_ref |       book_date        | total_amount |   ticket_no   |   passenger_name   |                                contact_data
----------+------------------------+--------------+---------------+--------------------+-----------------------------------------------------------------------------
 06B046   | 2016-09-02 16:19:00+00 |     12400.00 | 0005432000987 | VALERIY TIKHONOV   | {"phone": "+70127117011"}
 06B046   | 2016-09-02 16:19:00+00 |     12400.00 | 0005432000988 | EVGENIYA ALEKSEEVA | {"phone": "+70378089255"}
 E170C3   | 2016-08-26 21:55:00+00 |     24700.00 | 0005432000989 | ARTUR GERASIMOV    | {"phone": "+70760429203"}
 E170C3   | 2016-08-26 21:55:00+00 |     24700.00 | 0005432000990 | ALINA VOLKOVA      | {"email": "volkova.alina_03101973@postgrespro.ru", "phone": "+70582584031"}
 F313DD   | 2016-08-31 00:37:00+00 |     30900.00 | 0005432000991 | MAKSIM ZHUKOV      | {"email": "m-zhukov061972@postgrespro.ru", "phone": "+70149562185"}
(5 rows)

```

Вывод:
```
Пассажирам обычно достаточно расписания без внутренних идентификаторов.
Пилотам полезны рейсы с типом самолета и аэропортами, диспетчерам — статус и фактические времена, кассирам — связка бронирование/билет и контакты пассажира.
Представления позволяют выдавать разным ролям разные «срезы» данных без дублирования таблиц.
```


## Задача номер 18 из главы 5
Добавить jsonb-столбцы (кроме tickets.contact_data): пример с aircrafts.specifications и предложения по другим таблицам.

Решение:
```sql
-- ALTER TABLE aircrafts
--   ADD COLUMN IF NOT EXISTS specifications jsonb;

-- UPDATE aircrafts
-- SET specifications = '{ "crew": 2, "engines": { "type": "IAE V2500", "num": 2 } }'::jsonb
-- WHERE aircraft_code = '320';

-- SELECT model, specifications FROM aircrafts WHERE aircraft_code = '320';
-- SELECT model, specifications->'engines' AS engines FROM aircrafts WHERE aircraft_code = '320';
-- SELECT model, specifications #> '{engines,type}' AS engine_type FROM aircrafts WHERE aircraft_code = '320';

-- Пример: airports.meta
ALTER TABLE airports ADD COLUMN IF NOT EXISTS meta jsonb;

UPDATE airports
SET meta = '{ "contacts": { "phone": "+7-000-000-00-00" }, "services": ["wifi","lounge"] }'::jsonb
WHERE airport_code = (SELECT airport_code FROM airports ORDER BY airport_code LIMIT 1);

SELECT airport_code, airport_name, meta
FROM airports
WHERE meta IS NOT NULL
ORDER BY airport_code
LIMIT 3;

```

Результат запроса:
```sql
ALTER TABLE
UPDATE 1
-- airports.meta
 airport_code | airport_name |                                    meta
--------------+--------------+-----------------------------------------------------------------------------
 AAQ          | Витязево     | {"contacts": {"phone": "+7-000-000-00-00"}, "services": ["wifi", "lounge"]}
(1 row)

```

Вывод:
```
jsonb удобен для «редко используемых» или часто меняющихся атрибутов (характеристики, услуги, произвольные метаданные) без изменения схемы.
Логично добавлять jsonb туда, где свойства сильно вариативны: aircrafts (характеристики), airports (сервисы/контакты).
```
