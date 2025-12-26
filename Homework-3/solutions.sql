
-- 2) numeric without (precision, scale)
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


-- 4) double precision very small numbers (subnormal/rounding effects)
SELECT (5e-324::double precision = 4e-324::double precision) AS eq_5e_324_4e_324;

SELECT 5e-324::double precision AS v1,
       4e-324::double precision AS v2;

-- 8) serial PRIMARY KEY + sequence behavior after DELETE
DROP TABLE IF EXISTS testserial;

CREATE TABLE testserial (
  id serial PRIMARY KEY,
  name text
);

INSERT INTO testserial (name) VALUES ('A');
INSERT INTO testserial (name) VALUES ('B');
INSERT INTO testserial (name) VALUES ('C');

-- Явно вставим id (последовательность при этом "сама" не откатывается назад)
INSERT INTO testserial (id, name) VALUES (10, 'X');

-- Следующая вставка без id получит значение из sequence
INSERT INTO testserial (name) VALUES ('D');

-- Удалим строку и снова вставим
DELETE FROM testserial WHERE id = 4;
INSERT INTO testserial (name) VALUES ('E');

SELECT * FROM testserial ORDER BY id;


-- 12) datestyle + разбор дат
SHOW datestyle;

SELECT '18-05-2016'::date AS d_dmy;

SET datestyle TO 'ISO, MDY';
SELECT '05-18-2016'::date AS d_mdy;

RESET datestyle;
SHOW datestyle;

-- 15) to_char(currenttimestamp, ...)
SELECT to_char(CURRENT_TIMESTAMP, 'MISS') AS mmss;
SELECT to_char(CURRENT_TIMESTAMP, 'DD') AS day_of_month;
SELECT to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD') AS yyyy_mm_dd;



-- 21) date + interval '1 mon' (разные концы месяца)
SELECT DATE '2016-01-31' + INTERVAL '1 mon' AS d1;
SELECT DATE '2016-02-29' + INTERVAL '1 mon' AS d2;


-- 30) bool: допустимые/недопустимые литералы (ошибки ловим)
DROP TABLE IF EXISTS testbool;

CREATE TABLE testbool (
  a boolean,
  b text
);

-- Валидные варианты
INSERT INTO testbool VALUES (TRUE, 'yes');
INSERT INTO testbool VALUES ('yes', 'yes');
INSERT INTO testbool VALUES ('1', 'true');
INSERT INTO testbool VALUES ('t', 'true');
INSERT INTO testbool VALUES ('true', 'true');

-- Невалидные варианты: выполняем в DO-блоках, чтобы файл не падал
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


-- 33) arrays + NULL vs non-NULL text in meal
DROP TABLE IF EXISTS pilots;

CREATE TABLE pilots (
  pilotname text,
  schedule integer[],
  meal text
);

-- часть строк с NULL в meal, часть с пустой строкой
INSERT INTO pilots VALUES ('Ivan',  ARRAY[1,3,5,6,7]::integer[], NULL);
INSERT INTO pilots VALUES ('Petr',  ARRAY[1,2,5,7]::integer[],   '');
INSERT INTO pilots VALUES ('Pavel', ARRAY[2,5]::integer[],       NULL);
INSERT INTO pilots VALUES ('Boris', ARRAY[3,5,6]::integer[],     '');

SELECT * FROM pilots ORDER BY pilotname;

-- Выборка строк, где meal именно NULL
SELECT * FROM pilots
WHERE meal IS NULL
ORDER BY pilotname;



-- 35 JSONB: обновление значения по ключу (jsonb_set)
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
