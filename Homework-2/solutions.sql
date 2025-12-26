-- 1) Попытка вставить уже существующий aircraft_code
INSERT INTO bookings.aircrafts VALUES ('SU9', 'Sukhoi SuperJet-100', 3000);

-- 2) ORDER BY по убыванию range
SELECT *
FROM aircrafts
ORDER BY range DESC;

-- 3) UPDATE range в 2 раза + проверка
UPDATE aircrafts
SET range = range * 2
WHERE model = 'Sukhoi SuperJet-100';

SELECT aircraft_code, model, range
FROM aircrafts
WHERE model = 'Sukhoi SuperJet-100';

-- 4) DELETE 0 без ошибки
DELETE FROM aircrafts
WHERE aircraft_code IS NULL;

SELECT count(*)
FROM aircrafts
WHERE aircraft_code IS NULL;
