# Homework-8

## Задача номер 2 из главы 9
Read Committed: повторить сценарий, но в первой транзакции сделать ROLLBACK — будет ли удаление и какая строка.

Решение:
```sql
-- Терминал 1
BEGIN;
SELECT * FROM aircrafts_tmp WHERE range < 2000;
UPDATE aircrafts_tmp SET range = 2100 WHERE aircraft_code = 'CN1';
UPDATE aircrafts_tmp SET range = 1900 WHERE aircraft_code = 'CR2';
ROLLBACK;

-- Терминал 2 (в это же время)
BEGIN;
SELECT * FROM aircrafts_tmp WHERE range < 2000;
DELETE FROM aircrafts_tmp WHERE range < 2000;
END;

-- Проверка после
SELECT * FROM aircrafts_tmp ORDER BY aircraft_code;
```

Результат запроса:
```sql
ROLLBACK
COMMIT

 aircraft_code |        model        | range |                     specifications
---------------+---------------------+-------+---------------------------------------------------------
 319           | Airbus A319-100     |  6700 |
 320           | Airbus A320-200     |  5700 | {"crew": 2, "engines": {"num": 2, "type": "IAE V2500"}}
 321           | Airbus A321-200     |  5600 |
 733           | Boeing 737-300      |  4200 |
 763           | Boeing 767-300      |  7900 |
 773           | Boeing 777-300      | 11100 |
 CR2           | Bombardier CRJ-200  |  2700 |
 SU9           | Sukhoi SuperJet-100 |  3000 |
(8 rows)
```

Вывод:
```
При ROLLBACK в первой транзакции изменения range откатываются, и строка CN1 снова имеет range < 2000.
DELETE во второй транзакции после снятия блокировки перечитывает строку CN1 и удаляет ее (ожидаемый результат DELETE 1).
Строка CR2 не удаляется, потому что условие DELETE было рассчитано на исходном наборе строк и повторный поиск других подходящих строк не выполняется.
```


## Задача номер 3 из главы 9
Потерянное обновление при присваивании (range = 2100 vs range = 2500): есть ли lost update и как предотвратить.

Решение:
```sql
-- Пример сценария (2 терминала):
-- T1:
BEGIN; UPDATE aircrafts_tmp SET range = 2100 WHERE aircraft_code = 'CR2'; COMMIT;
-- T2:
BEGIN; UPDATE aircrafts_tmp SET range = 2500 WHERE aircraft_code = 'CR2'; COMMIT;
```

Результат запроса:
```sql
BEGIN
UPDATE 1
COMMIT
BEGIN
UPDATE 1
COMMIT
```

Вывод:
```
Да, это потерянное обновление в прикладном смысле: одно присваивание перезаписывает результат другого, и итог зависит от порядка коммитов.
Защита: блокировка строки перед вычислением решения (SELECT ... FOR UPDATE), оптимистическая проверка версионности (WHERE range = старое_значение и контроль rowcount), либо более строгий уровень изоляции (например, SERIALIZABLE) с повтором транзакции при конфликте.
```
