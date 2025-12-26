# Homework-3

## Задача номер 2 из главы 4
Решение:
```sql
DROP TABLE IF EXISTS testnumeric;

CREATE TABLE testnumeric (
  measurement numeric,
  description text
);

INSERT INTO testnumeric VALUES (1234567890.0987654321, '20 знаков, 10 после точки');
INSERT INTO testnumeric VALUES (1.5, '2 знака, 1 после точки');
INSERT INTO testnumeric VALUES (0.12345678901234567890, '21 знак, 20 после точки');
INSERT INTO testnumeric VALUES (1234567890, '10 знаков, 0 после точки');

SELECT * FROM testnumeric;
```

Результат запроса:
```sql
DROP TABLE
CREATE TABLE
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
```

Вывод:
Демонстрация хранения numeric без ограничения precision/scale; фактический вывод зависит от окружения.

## Задача номер 4 из главы 4
Решение:
```sql
SELECT (5e-324::double precision = 4e-324::double precision) AS eq_5e_324_4e_324;

SELECT 5e-324::double precision AS v1,
       4e-324::double precision AS v2;
```

Результат запроса:
```sql
 t

 5e-324 | 5e-324 
```

Вывод:
Проверяется поведение double precision на очень малых числах.

## Задача номер 8 из главы 4
Решение:
```sql
DROP TABLE IF EXISTS testserial;

CREATE TABLE testserial (
  id serial PRIMARY KEY,
  name text
);

INSERT INTO testserial (name) VALUES ('A');
INSERT INTO testserial (name) VALUES ('B');
INSERT INTO testserial (name) VALUES ('C');

INSERT INTO testserial (id, name) VALUES (10, 'X');
INSERT INTO testserial (name) VALUES ('D');

DELETE FROM testserial WHERE id = 4;
INSERT INTO testserial (name) VALUES ('E');

SELECT * FROM testserial ORDER BY id;
```

Результат запроса:
```sql
DROP TABLE

CREATE TABLE

INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
DELETE 1
INSERT 0 1

  1 | A
  2 | B
  3 | C
  5 | E
 10 | X
```

Вывод:
Показывается поведение sequence/serial при ручной вставке id и при удалении.

## Задача номер 12 из главы 4
Решение:
```sql
SHOW datestyle;

SELECT '18-05-2016'::date AS d_dmy;

SET datestyle TO 'ISO, MDY';
SELECT '05-18-2016'::date AS d_mdy;

RESET datestyle;
SHOW datestyle;
```

Результат запроса:
```sql
 ISO, MDY

ERROR:  date/time field value out of range: "18-05-2016"
LINE 1: SELECT '18-05-2016'::date AS d_dmy;

SET

2016-05-18

RESET
ISO, MDY
```

Вывод:
Демонстрируется влияние DateStyle на разбор строковых дат.

## Задача номер 15 из главы 4
Решение:
```sql
SELECT to_char(current_timestamp, 'mi:ss');
SELECT to_char(current_timestamp, 'dd');
SELECT to_char(current_timestamp, 'yyyy-mm-dd');
```

Результат запроса:
```sql
---------
 01:30
(1 row)
---------
 24
(1 row)
------------
 2025-12-24
(1 row)
```

Вывод:
Форматирование текущего timestamp; результат зависит от времени выполнения.

## Задача номер 21 из главы 4
Решение:
```sql
SELECT DATE '2016-01-31' + INTERVAL '1 mon' AS d1;
SELECT DATE '2016-02-29' + INTERVAL '1 mon' AS d2;
```

Результат запроса:
```sql
2016-02-29 00:00:00
2016-03-29 00:00:00
```

Вывод:
Показаны особенности добавления "1 mon" к датам конца месяца.

## Задача номер 30 из главы 4
Решение:
```sql
DROP TABLE IF EXISTS testbool;

CREATE TABLE testbool (
  a boolean,
  b text
);

INSERT INTO testbool VALUES (TRUE, 'yes');
INSERT INTO testbool VALUES ('yes', 'yes');
INSERT INTO testbool VALUES ('1', 'true');
INSERT INTO testbool VALUES ('t', 'true');
INSERT INTO testbool VALUES ('true', 'true');

DO $$
BEGIN
  INSERT INTO testbool VALUES ('truth', 'should fail');
EXCEPTION WHEN others THEN
  RAISE NOTICE 'Expected error for ''truth'': %', SQLERRM;
END $$;

DO $$
BEGIN
  INSERT INTO testbool VALUES ('111'::boolean, 'should fail');
EXCEPTION WHEN others THEN
  RAISE NOTICE 'Expected error for ''111''::boolean: %', SQLERRM;
END $$;

SELECT * FROM testbool;
```

Результат запроса:
```sql
DROP TABLE
CREATE TABLE
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1

NOTICE:  Expected error for 'truth': invalid input syntax for type boolean: "truth"
DO

NOTICE:  Expected error for '111'::boolean: invalid input syntax for type boolean: "111"
DO

t | yes
t | yes
t | true
t | true
t | true
```

Вывод:
Проверяются допустимые/недопустимые литералы boolean.

## Задача номер 33 из главы 4
Решение:
```sql
DROP TABLE IF EXISTS pilots;

CREATE TABLE pilots (
  pilotname text,
  schedule integer[],
  meal text
);

INSERT INTO pilots VALUES ('Ivan',  ARRAY[1,3,5,6,7]::integer[], NULL);
INSERT INTO pilots VALUES ('Petr',  ARRAY[1,2,5,7]::integer[],   '');
INSERT INTO pilots VALUES ('Pavel', ARRAY[2,5]::integer[],       NULL);
INSERT INTO pilots VALUES ('Boris', ARRAY[3,5,6]::integer[],     '');

SELECT * FROM pilots ORDER BY pilotname;

SELECT * FROM pilots
WHERE meal IS NULL
ORDER BY pilotname;
```

Результат запроса:
```sql
DROP TABLE

CREATE TABLE

INSERT 0 1
INSERT 0 1
INSERT 0 1
INSERT 0 1

Boris     | {3,5,6}     |
Ivan      | {1,3,5,6,7} |
Pavel     | {2,5}       |
Petr      | {1,2,5,7}   |

Ivan      | {1,3,5,6,7} |
Pavel     | {2,5}       |
```

Вывод:
Демонстрация различия NULL и пустой строки в текстовом поле.

## Задача номер 35 из главы 4
Решение:
```sql
DROP TABLE IF EXISTS pilothobbies;

CREATE TABLE pilothobbies (
  pilotname text,
  hobbies jsonb
);

INSERT INTO pilothobbies VALUES
('Ivan',  '{"trips": 3, "sports": ["ski","football"], "homelib": true}'::jsonb),
('Petr',  '{"trips": 2, "sports": ["football"], "homelib": true}'::jsonb),
('Pavel', '{"trips": 4, "sports": ["swim"], "homelib": false}'::jsonb),
('Boris', '{"trips": 0, "sports": ["chess"], "homelib": true}'::jsonb);

UPDATE pilothobbies
SET hobbies = jsonb_set(hobbies, '{sports}', '1'::jsonb)
WHERE pilotname = 'Boris';

SELECT pilotname, hobbies
FROM pilothobbies
WHERE pilotname = 'Boris';
```

Результат запроса:
```sql
DROP TABLE

CREATE TABLE

INSERT 0 4

UPDATE 1

pilotnademo-# WHERE pilotname = 'Boris';
Boris     | {"trips": 0, "sports": 1, "homelib": true}
```

Вывод:
Показано обновление значения по ключу в JSONB.
