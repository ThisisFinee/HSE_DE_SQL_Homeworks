-- 2) Read Committed + ROLLBACK в первой транзакции (сценарий для 2 терминалов)
-- Терминал 1:
BEGIN;
UPDATE aircrafts_tmp SET range = 2100 WHERE aircraft_code = 'CN1';
UPDATE aircrafts_tmp SET range = 1900 WHERE aircraft_code = 'CR2';
ROLLBACK;

-- Терминал 2:
BEGIN;
SELECT * FROM aircrafts_tmp WHERE range < 2000;
DELETE FROM aircrafts_tmp WHERE range < 2000;
END;

-- 3) Потерянное обновление: демонстрация
-- Терминал 1: 
BEGIN; UPDATE aircrafts_tmp SET range = 2100 WHERE aircraft_code = 'CR2'; COMMIT;
-- Терминал 2:
BEGIN; UPDATE aircrafts_tmp SET range = 2500 WHERE aircraft_code = 'CR2'; COMMIT;