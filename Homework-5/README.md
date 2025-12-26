# Homework-5

## Задача номер 2 из главы 6
LIKE-шаблон для фамилий из 5 букв (при формате passenger_name = 'Имя Фамилия').

Решение:
```sql
SELECT passenger_name
FROM tickets
WHERE passenger_name LIKE '% _____'
  AND passenger_name NOT LIKE '% _____ %'
  LIMIT 10;
```

Результат запроса:
```sql
 passenger_name
-----------------
 ILYA POPOV
 VLADIMIR POPOV
 PAVEL GUSEV
 LEONID ORLOV
 EVGENIY GUSEV
 NIKOLAY FOMIN
 EKATERINA ILINA
 ANTON POPOV
 ARTEM BELOV
 VLADIMIR POPOV
(10 rows)
```

Вывод:
```
Шаблон '% _____' означает: строка заканчивается пробелом и ровно пятью символами.
Дополнительное условие NOT LIKE '% _____ %' помогает отсечь случаи, когда после этих 5 символов есть еще один пробел и продолжение.
```


## Задача номер 7 из главы 6
Убрать дублирование пар городов (туда/обратно) для Boeing 777-300.

Решение:
```sql
SELECT DISTINCT
  r.departure_city,
  r.arrival_city
FROM routes r
JOIN aircrafts a ON r.aircraft_code = a.aircraft_code
WHERE a.model = 'Boeing 777-300'
  AND r.departure_city > r.arrival_city
ORDER BY 1, 2;
```

Результат запроса:
```sql
 departure_city | arrival_city
----------------+--------------
 Москва         | Екатеринбург
 Новосибирск    | Москва
 Пермь          | Москва
 Сочи           | Москва
(4 rows)
```

Вывод:
```
Условие departure_city > arrival_city оставляет только одно направление из пары взаимных маршрутов, потому что для обратного рейса неравенство будет ложным.
```


## Задача номер 9 из главы 6
Вывести count рейсов Москва → Санкт-Петербург с группировкой.

Решение:
```sql
SELECT
  departure_city,
  arrival_city,
  count(*) AS count
FROM routes
WHERE departure_city = 'Москва'
  AND arrival_city = 'Санкт-Петербург'
GROUP BY 1, 2;
```

Результат запроса:
```sql
 departure_city |  arrival_city   | count
----------------+-----------------+-------
 Москва         | Санкт-Петербург |    12
(1 row)
```

Вывод:
```
GROUP BY по двум столбцам позволяет вернуть агрегат (count) вместе с самими значениями departure_city/arrival_city.
```


## Задача номер 13 из главы 6
Показать также направления, где не продано ни одного билета: max/min должны быть NULL.

Решение:
```sql
SELECT
  f.departure_city,
  f.arrival_city,
  max(tf.amount) AS max,
  min(tf.amount) AS min
FROM flights_v f
LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
GROUP BY 1, 2
ORDER BY 1, 2;
```

Результат запроса:
```sql
      departure_city      |       arrival_city       |    max    |   min
--------------------------+--------------------------+-----------+----------
 Абакан                   | Архангельск              |           |
 Абакан                   | Грозный                  |           |
 Абакан                   | Кызыл                    |           |
 Абакан                   | Москва                   | 101000.00 | 33700.00
 Абакан                   | Новосибирск              |   5800.00 |  5800.00
 Абакан                   | Томск                    |   4900.00 |  4900.00
 Анадырь                  | Москва                   | 185300.00 | 61800.00
 Анадырь                  | Хабаровск                |  92200.00 | 30700.00
 Анапа                    | Белгород                 |  18900.00 |  6300.00
 Анапа                    | Москва                   |  36600.00 | 12200.00
 Анапа                    | Новокузнецк              |           |
 Архангельск              | Абакан                   |           |
 Архангельск              | Иркутск                  |           |
 Архангельск              | Москва                   |  11100.00 | 10100.00
 Архангельск              | Нарьян-Мар               |   7300.00 |  6600.00
 Архангельск              | Пермь                    |  11000.00 | 11000.00
 ...
```

Вывод:
```
LEFT JOIN сохраняет направления даже при отсутствии связанных строк ticket_flights.
Для групп без строк tf агрегаты max/min возвращают NULL, что и сигнализирует «не было продаж».
```


## Задача номер 19 из главы 6
Рекурсивный CTE: добавить iteration и сравнить UNION ALL vs UNION.

Решение:
```sql
WITH RECURSIVE ranges (min_sum, max_sum, iteration) AS (
  VALUES (0::numeric, 100000::numeric, 1)
  UNION
  SELECT min_sum + 100000, max_sum + 100000, iteration + 1
  FROM ranges
  WHERE max_sum < (SELECT max(total_amount) FROM bookings)
)
SELECT * FROM ranges;
```

Результат запроса:
```sql

-- UNION
 min_sum | max_sum | iteration
---------+---------+-----------
       0 |  100000 |         1
  100000 |  200000 |         2
  200000 |  300000 |         3
  300000 |  400000 |         4
  400000 |  500000 |         5
  500000 |  600000 |         6
  600000 |  700000 |         7
  700000 |  800000 |         8
  800000 |  900000 |         9
  900000 | 1000000 |        10
 1000000 | 1100000 |        11
 1100000 | 1200000 |        12
 1200000 | 1300000 |        13
(13 rows)
```

Вывод:
```
iteration на каждом шаге увеличивается на 1 и показывает номер итерации рекурсии.
UNION ALL сохраняет все строки рекурсивного процесса, а UNION дополнительно удаляет дубликаты, что может «скрыть» повторяющиеся промежуточные состояния и обычно дороже по вычислениям.
```


## Задача номер 21 из главы 6
Города, куда нет рейсов из Москвы: выбрать UNION/INTERSECT/EXCEPT.

Решение:
```SQL
SELECT city
FROM airports
WHERE city <> 'Москва'
EXCEPT
SELECT arrival_city
FROM routes
WHERE departure_city = 'Москва'
ORDER BY city;
```

Результат запроса:
```sql
         city
----------------------
 Благовещенск
 Иваново
 Иркутск
 Калуга
 Когалым
 Комсомольск-на-Амуре
 Кызыл
 Магадан
 Нижнекамск
 Новокузнецк
 Стрежевой
 Сургут
 Удачный
 Усть-Илимск
 Усть-Кут
 Ухта
 Череповец
 Чита
 Якутск
 Ярославль
(20 rows)
```

Вывод:
```
Нужна разность множеств: все города (кроме Москвы) минус города, куда есть рейсы из Москвы.
Поэтому правильная операция — EXCEPT.
```


## Задача номер 23 из главы 6
Переписать запрос на self-join городов через CTE.

Решение:
```sql
WITH cities AS (
  SELECT DISTINCT city FROM airports
)
SELECT count(*)
FROM cities a1
JOIN cities a2 ON a1.city <> a2.city;
```

Результат запроса:
```sql
 count
-------
 10100
(1 row)
```

Вывод:
```
CTE cities вычисляет множество различных городов один раз, после чего выполняется соединение cities с самой собой по неравенству.
```