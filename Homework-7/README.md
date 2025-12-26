# Homework-7

## Задача номер 1 из главы 8
Уникальный индекс по (column1, column2) и NULL: пройдет ли вторая вставка (ABC, NULL)?

Решение:
```SQL
CREATE TABLE t_uq (column1 text, column2 text);
CREATE UNIQUE INDEX t_uq_idx ON t_uq (column1, column2);

INSERT INTO t_uq VALUES ('ABC', NULL);
INSERT INTO t_uq VALUES ('ABC', NULL);
SELECT * FROM t_uq;
```

Результат запроса:
```SQL
CREATE TABLE
CREATE INDEX

INSERT 0 1
INSERT 0 1

 column1 | column2
---------+---------
 ABC     |
 ABC     |
(2 rows)
```

Вывод:
```
В PostgreSQL по умолчанию NULL в UNIQUE считается «не равным» другому NULL, поэтому вторая вставка (ABC, NULL) успешна.
Если нужно запретить дубликаты с NULL, применяют UNIQUE/INDEX с режимом NULLS NOT DISTINCT (в новых версиях) либо альтернативные приемы (частичные индексы/нормализация).
```


## Задача номер 3 из главы 8
Проверить эффект индекса по ticket_flights.fare_conditions при низкой селективности.

Решение:
```sql

SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Comfort';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Business';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Economy';

CREATE INDEX IF NOT EXISTS ticket_flights_fare_conditions_idx
  ON ticket_flights (fare_conditions);

ANALYZE ticket_flights;

SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Comfort';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Business';
SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Economy';
```

Результат запроса:
```sql
-- SELECT count(*) FROM ticket_flights WHERE fa 
 count
-------
 17291
(1 row)

--SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Business';
 count
--------
 107642
(1 row)

-- SELECT count(*) FROM ticket_flights WHERE fare_conditions = 'Economy';
 count
--------
 920793
(1 row)
```

Вывод:
```
При трех значениях fare_conditions каждая выборка обычно затрагивает большую долю таблицы, поэтому планировщик часто предпочитает последовательное сканирование, и время для разных значений почти не отличается.
Индекс может не дать выигрыша (или даже дать проигрыш) из‑за накладных расходов и низкой селективности условия.
```