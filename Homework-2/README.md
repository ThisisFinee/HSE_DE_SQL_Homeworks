# Homework-2

## Задача номер 1 из главы 3
Решение:
```sql
INSERT INTO aircrafts VALUES ('SU9', 'Sukhoi SuperJet-100', 3000);
```

Результат запроса:
```sql
ERROR:  duplicate key value violates unique constraint "aircrafts_pkey"
DETAIL:  Key (aircraft_code)=(SU9) already exists.
```

Вывод:
Ошибка возникает из-за нарушения уникальности первичного ключа (aircraft_code).

## Задача номер 2 из главы 3
Решение:
```sql
SELECT *
FROM aircrafts
ORDER BY range DESC;
```

Результат запроса:
```sql
 773           | Boeing 777-300      | 11100
 763           | Boeing 767-300      |  7900
 319           | Airbus A319-100     |  6700
 320           | Airbus A320-200     |  5700
 321           | Airbus A321-200     |  5600
 733           | Boeing 737-300      |  4200
 SU9           | Sukhoi SuperJet-100 |  3000
 CR2           | Bombardier CRJ-200  |  2700
 CN1           | Cessna 208 Caravan  |  1200
```

Вывод:
Строки отсортированы по убыванию дальности полёта.

## Задача номер 3 из главы 3
Решение:
```sql
UPDATE aircrafts
SET range = range * 2
WHERE model = 'Sukhoi SuperJet-100';

SELECT aircraft_code, model, range
FROM aircrafts
WHERE model = 'Sukhoi SuperJet-100';
```

Результат запроса:
```sql
UPDATE 1

 SU9           | Sukhoi SuperJet-100 |  6000
```

Вывод:
Проверка показывает обновлённое значение range для одной модели.

## Задача номер 4 из главы 3
Решение:
```sql
DELETE FROM aircrafts
WHERE aircraft_code IS NULL;
```

Результат запроса:
```sql
DELETE 0
```

Вывод:
Ожидается DELETE 0, т.к. условию не соответствует ни одна строка.
