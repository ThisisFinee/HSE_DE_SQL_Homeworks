CREATE TEMP TABLE aircrafts_tmp AS
SELECT * FROM aircrafts WITH NO DATA;
ALTER TABLE aircrafts_tmp
ADD PRIMARY KEY ( aircraft_code );
ALTER TABLE aircrafts_tmp
ADD UNIQUE ( model );
CREATE TEMP TABLE aircrafts_log AS
SELECT * FROM aircrafts WITH NO DATA;
ALTER TABLE aircrafts_log
ADD COLUMN when_add timestamp;
ALTER TABLE aircrafts_log
ADD COLUMN operation text;

WITH add_row AS
( INSERT INTO aircrafts_tmp
SELECT * FROM aircrafts
RETURNING *
)
INSERT INTO aircrafts_log
SELECT add_row.aircraft_code, add_row.model, add_row.range,
current_timestamp, 'INSERT'
FROM add_row;

-- 1) aircrafts_log: default current_timestamp + правка INSERT (пример)
-- Если aircrafts_log уже существует:
ALTER TABLE aircrafts_log
  ALTER COLUMN when_add SET DEFAULT current_timestamp;

-- Пример вставки в aircrafts_log: теперь when_add можно не указывать
-- INSERT INTO aircrafts_log (aircraft_code, model, range, operation)
-- SELECT aircraft_code, model, range, 'INSERT'
-- FROM aircrafts_tmp;

-- 2) RETURNING: что вместо "?" (вставить все столбцы из add_row)
TRUNCATE aircrafts_tmp;
WITH add_row AS (
  INSERT INTO aircrafts_tmp
  SELECT * FROM aircrafts
  RETURNING aircraft_code, model, range, specifications
)
INSERT INTO aircrafts_log (aircraft_code, model, range, specifications, when_add, operation)
SELECT aircraft_code, model, range, specifications, current_timestamp, 'INSERT'
FROM add_row;

-- 4) ON CONFLICT для составного PK seats (aircraft_code, seat_no) на копии
CREATE TEMP TABLE seats_tmp (LIKE seats INCLUDING CONSTRAINTS INCLUDING INDEXES);

-- Вариант 1: ON CONFLICT (перечисление столбцов)
INSERT INTO seats_tmp (aircraft_code, seat_no, fare_conditions)
VALUES ('SU9', '99A', 'Economy')
ON CONFLICT (aircraft_code, seat_no) DO NOTHING;

-- Вариант 2: ON CONFLICT ON CONSTRAINT
INSERT INTO seats_tmp (aircraft_code, seat_no, fare_conditions)
VALUES ('SU9', '99A', 'Business')
ON CONFLICT ON CONSTRAINT seats_tmp_pkey
DO UPDATE SET fare_conditions = EXCLUDED.fare_conditions;
