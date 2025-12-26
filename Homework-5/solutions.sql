-- 2) LIKE: фамилия из 5 букв (формат "Имя Фамилия")
SELECT passenger_name
FROM tickets
WHERE passenger_name LIKE '% _____'
  AND passenger_name NOT LIKE '% _____ %'
  LIMIT 10;

-- 7) Уникальные пары городов для Boeing 777-300 без дублей "туда/обратно"
SELECT DISTINCT
  r.departure_city,
  r.arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
  AND r.departure_city > r.arrival_city
ORDER BY 1, 2;

-- 9) Кол-во рейсов Москва -> Санкт-Петербург в виде строки-агрегата
SELECT
  departure_city,
  arrival_city,
  count(*) AS count
FROM routes
WHERE departure_city = 'Москва'
  AND arrival_city = 'Санкт-Петербург'
GROUP BY 1, 2;

-- 13) Направления без проданных билетов: max/min будут NULL (LEFT JOIN)
SELECT
  f.departure_city,
  f.arrival_city,
  max(tf.amount) AS max,
  min(tf.amount) AS min
FROM flights_v f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- 19) Рекурсия: добавляем iteration + сравнение UNION ALL vs UNION

WITH RECURSIVE ranges (min_sum, max_sum, iteration) AS (
  VALUES (0::numeric, 100000::numeric, 1)
  UNION
  SELECT min_sum + 100000, max_sum + 100000, iteration + 1
  FROM ranges
  WHERE max_sum < (SELECT max(total_amount) FROM bookings)
)
SELECT * FROM ranges;

-- 21) Города, куда нет рейсов из Москвы (EXCEPT)
SELECT city
FROM airports
WHERE city <> 'Москва'
EXCEPT
SELECT arrival_city
FROM routes
WHERE departure_city = 'Москва'
ORDER BY city;

-- 23) Теоретическое число маршрутов между всеми городами: переписать с CTE
WITH cities AS (
  SELECT DISTINCT city FROM airports
)
SELECT count(*)
FROM cities a1
JOIN cities a2 ON a1.city <> a2.city;