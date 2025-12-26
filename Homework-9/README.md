# Homework-9

## Задача номер 3 из главы 10
EXPLAIN для запроса с CTE: найти узел плана для CTE и понять, где он материализуется.

Решение:
```sql
EXPLAIN
WITH t AS MATERIALIZED (
  SELECT flight_id, flight_no
  FROM flights
  WHERE status = 'Scheduled'
)
SELECT count(*)
FROM t;
```

Результат запроса:
```sql
                              QUERY PLAN
----------------------------------------------------------------------
 Aggregate  (cost=1151.57..1151.58 rows=1 width=8)
   CTE t
     ->  Seq Scan on flights  (cost=0.00..806.01 rows=15358 width=11)
           Filter: ((status)::text = 'Scheduled'::text)
   ->  CTE Scan on t  (cost=0.00..307.16 rows=15358 width=0)
(5 rows)
```

Вывод:
```
-
```


## Задача номер 6 из главы 10
EXPLAIN для оконной функции: найти WindowAgg и объяснить его положение в плане.

Решение:
```sql
EXPLAIN
SELECT
  f.flight_id,
  f.departure_airport,
  f.scheduled_departure,
  row_number() OVER (PARTITION BY f.departure_airport ORDER BY f.scheduled_departure) AS rn
FROM flights f;
```

Результат запроса:
```
QUERY PLAN
----------------------------------------------------------------------------
 WindowAgg  (cost=3209.87..3872.27 rows=33121 width=24)
   ->  Sort  (cost=3209.85..3292.65 rows=33121 width=16)
         Sort Key: departure_airport, scheduled_departure
         ->  Seq Scan on flights f  (cost=0.00..723.21 rows=33121 width=16)
(4 rows)
```

Вывод:
```
WindowAgg появляется после этапов, которые обеспечивают нужный порядок строк для оконной функции.
Это связано с тем, что оконные функции вычисляются «по окну», которому обычно требуется упорядоченный поток строк внутри PARTITION.
Полный путь:
Внизу плана выполняется Seq Scan on flights, то есть PostgreSQL читает все строки таблицы flights.
​
Далее идёт Sort с ключом departure_airport, scheduled_departure: это обязательная подготовка данных, чтобы внутри каждой “группы” (PARTITION BY departure_airport) строки шли в нужном порядке (ORDER BY scheduled_departure).
​
И только после этого выполняется WindowAgg: этот узел применяет оконную функцию к уже отсортированному потоку и добавляет вычисленные значения к каждой строке, поэтому он расположен над сортировкой.
​
```


## Задача номер 8 из главы 10
Аналог пары запросов: коррелированный подзапрос vs LEFT JOIN, и сравнение EXPLAIN ANALYZE.

Решение:
```sql
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
```

Результат запроса:
```sql
-- коррелированный подзапрос
 QUERY PLAN                                          
-------------------------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=66.64..66.66 rows=9 width=56) (actual time=1.345..1.348 rows=9 loops=1)
   Sort Key: ((SubPlan 1)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  Seq Scan on aircrafts a  (cost=0.00..66.50 rows=9 width=56) (actual time=0.265..0.480 rows=9 loops=1)
         SubPlan 1
           ->  Aggregate  (cost=7.26..7.27 rows=1 width=8) (actual time=0.050..0.050 rows=1 loops=9)
                 ->  Index Only Scan using seats_pkey on seats s  (cost=0.28..6.88 rows=149 width=0) (actual time=0.032..0.045 rows=149 loops=9)
                       Index Cond: (aircraft_code = a.aircraft_code)
                       Heap Fetches: 0
 Planning Time: 0.364 ms
 Execution Time: 1.378 ms
(11 rows)


--LEFT JOIN
QUERY PLAN                                                   
------------------------------------------------------------------------------------------------------------------------------
 Sort  (cost=34.69..34.72 rows=9 width=56) (actual time=0.917..0.930 rows=9 loops=1)
   Sort Key: (count(s.seat_no)) DESC
   Sort Method: quicksort  Memory: 25kB
   ->  HashAggregate  (cost=34.46..34.55 rows=9 width=56) (actual time=0.898..0.911 rows=9 loops=1)
         Group Key: a.aircraft_code
         Batches: 1  Memory Usage: 24kB
         ->  Hash Right Join  (cost=1.20..27.77 rows=1339 width=51) (actual time=0.171..0.766 rows=1339 loops=1)
               Hash Cond: (s.aircraft_code = a.aircraft_code)
               ->  Seq Scan on seats s  (cost=0.00..21.39 rows=1339 width=7) (actual time=0.093..0.480 rows=1339 loops=1)
               ->  Hash  (cost=1.09..1.09 rows=9 width=48) (actual time=0.025..0.025 rows=9 loops=1)
                     Buckets: 1024  Batches: 1  Memory Usage: 9kB
                     ->  Seq Scan on aircrafts a  (cost=0.00..1.09 rows=9 width=48) (actual time=0.011..0.012 rows=9 loops=1)
 Planning Time: 0.266 ms
 Execution Time: 0.981 ms
(14 rows)
```

Вывод:
```
Вывод: в варианте с коррелированным подзапросом план содержит SubPlan 1, который выполняется для каждой строки aircrafts (в твоём плане loops=9), поэтому происходит 9 отдельных агрегирований и 9 Index Only Scan по seats.
​
Во втором варианте LEFT JOIN + GROUP BY таблица seats читается один раз (Seq Scan on seats), затем всё агрегируется через HashAggregate, поэтому итоговое время получилось меньше (0.981 ms против 1.378 ms).
​
На маленьких таблицах разница невелика, но при росте числа строк коррелированный подзапрос обычно масштабируется хуже из‑за повторных проходов/подпланов, тогда как join-агрегация чаще остаётся однопроходной.

```