-- 1) UNIQUE индекс (column1, column2) и NULL: проверка поведения
-- Пример:
-- CREATE TABLE t(u1 text, u2 text);
-- CREATE UNIQUE INDEX t_uq ON t(u1, u2);
-- INSERT INTO t VALUES ('ABC', NULL);
-- INSERT INTO t VALUES ('ABC', NULL);  -- в PostgreSQL по умолчанию пройдёт

-- 3) Эксперимент с индексом по ticket_flights.fare_conditions
-- В psql:
-- \timing on

SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Comfort';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Business';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Economy';

CREATE INDEX IF NOT EXISTS ticket_flights_fare_conditions_idx
  ON ticket_flights (fare_conditions);

ANALYZE ticket_flights;

SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Comfort';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Business';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Economy';
