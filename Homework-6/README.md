# Homework-6
## Перед выполнением
```sql
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

```

## Задача номер 1 из главы 7
В aircrafts_log задать DEFAULT current_timestamp и изменить INSERT.

Решение:
```sql
ALTER TABLE aircrafts_log
  ALTER COLUMN when_add SET DEFAULT current_timestamp;

-- Пример: при вставке when_add можно не задавать
INSERT INTO aircrafts_log (aircraft_code, model, range, operation)
SELECT aircraft_code, model, range, 'INSERT'
FROM aircrafts_tmp;
```

Результат запроса:
```sql
ALTER TABLE
INSERT 0 1
```

Вывод:
```
DEFAULT current_timestamp делает заполнение времени логирования автоматическим и избавляет от необходимости передавать current_timestamp в каждом INSERT.
```


## Задача номер 2 из главы 7
В запросе с RETURNING: что написать вместо "?" при вставке в aircrafts_log.

Решение:
```sql
TRUNCATE aircrafts_tmp;
WITH add_row AS (
  INSERT INTO aircrafts_tmp
  SELECT * FROM aircrafts
  RETURNING aircraft_code, model, range, specifications
)
INSERT INTO aircrafts_log (aircraft_code, model, range, specifications, when_add, operation)
SELECT aircraft_code, model, range, specifications, current_timestamp, 'INSERT'
FROM add_row;

```

Результат запроса:
```sql
INSERT 0 9
```

Вывод:
```
CTE add_row уже возвращает ровно те 5 столбцов, которые нужно вставить в лог, поэтому в INSERT ... SELECT достаточно написать SELECT * FROM add_row.
```


## Задача номер 4 из главы 7
INSERT в seats с составным PK: два варианта ON CONFLICT (по столбцам и ON CONSTRAINT) на копии таблицы.

Решение:
```SQL
CREATE TEMP TABLE seats_tmp (LIKE seats INCLUDING CONSTRAINTS INCLUDING INDEXES);

-- 1) По перечислению столбцов составного ключа
INSERT INTO seats_tmp (aircraft_code, seat_no, fare_conditions)
VALUES ('SU9', '99A', 'Economy')
ON CONFLICT (aircraft_code, seat_no) DO NOTHING;

-- 2) По имени ограничения
INSERT INTO seats_tmp (aircraft_code, seat_no, fare_conditions)
VALUES ('SU9', '99A', 'Business')
ON CONFLICT ON CONSTRAINT seats_tmp_pkey
DO UPDATE SET fare_conditions = EXCLUDED.fare_conditions;
```

Результат запроса:
```SQL
CREATE TABLE
INSERT 0 1
INSERT 0 1
```

Вывод:
```
Для составного ключа в ON CONFLICT нужно перечислять оба поля ключа (aircraft_code, seat_no) или ссылаться на ограничение первичного ключа через ON CONSTRAINT.
Эксперименты безопасно проводить на копии seats_tmp, чтобы не менять исходные данные.
```
