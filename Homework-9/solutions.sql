-- 3) EXPLAIN для CTE
EXPLAIN
WITH t AS MATERIALIZED (
  SELECT flight_id, flight_no
  FROM flights
  WHERE status = 'Scheduled'
)
SELECT count(*)
FROM t;

-- 6) EXPLAIN для оконной функции: узел WindowAgg
EXPLAIN
SELECT
  f.flight_id,
  f.departure_airport,
  f.scheduled_departure,
  row_number() OVER (PARTITION BY f.departure_airport ORDER BY f.scheduled_departure) AS rn
FROM flights f;

-- 8) Пара запросов: коррелированный подзапрос vs LEFT JOIN
EXPLAIN ANALYZE
SELECT
  a.aircraft_code,
  a.model,
  (
    SELECT count(*)
    FROM seats s
    WHERE s.aircraft_code = a.aircraft_code
  ) AS num_seats
FROM aircrafts a
ORDER BY num_seats DESC;

EXPLAIN ANALYZE
SELECT
  a.aircraft_code,
  a.model,
  count(s.seat_no) AS num_seats
FROM aircrafts a
LEFT JOIN seats s ON s.aircraft_code = a.aircraft_code
GROUP BY 1, 2
ORDER BY num_seats DESC;