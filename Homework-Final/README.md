# Финальная домашняя работа — Рекламная платформа

## Навигация
- [Общее описание](#общее-описание)
  - [Идея БД](#идея-бд)
- [Таблицы и поля](#таблицы-и-поля)
  - [Примерная схема](#примерная-схема)    
- [Работа с контейнером](#работа-с-контейнером)
  - [Требования](#требования)
  - [Быстрый старт](#быстрый-старт)
  - [Подключаемся к бд](#подключаемся-к-бд)
- [Выполнение запросов](#выполнение-запросов)
  - [1) Отчёт: траты по рекламе vs бюджет](#1-отчёт-траты-по-рекламе-vs-бюджет)
  - [2) Топ кампаний по тратам (CTE)](#2-топ-кампаний-по-тратам-cte)
  - [3) Кампании с расходом > 70% бюджета](#3-кампании-с-расходом--70-бюджета)
  - [4) Рейтинг рекламы по тратам в кампании (window)](#4-рейтинг-рекламы-по-тратам-в-кампании-window)
  - [5) Бегущий итог трат по датам (window)](#5-бегущий-итог-трат-по-датам-window)
  - [6) Последнее размещение для каждой рекламы (ROW_NUMBER)](#6-последнее-размещение-для-каждой-рекламы-row_number)
  - [7) Объявления дороже среднего по кампании (коррелированный подзапрос)](#7-объявления-дороже-среднего-по-кампании-коррелированный-подзапрос)
  - [8) Кто добавлял расходы: агентство/пользователь](#8-кто-добавлял-расходы-агентствопользователь)
  - [9) Кампании без активных размещений (NOT EXISTS)](#9-кампании-без-активных-размещений-not-exists)
  - [10) Pending-согласования + кто запросил/кто одобряет](#10-pending-согласования--кто-запросилкто-одобряет)
  - [11) Бюджеты/траты по агентствам внутри кампаний](#11-бюджетытраты-по-агентствам-внутри-кампаний)
  - [12) Проблемные объявления: spend > budget](#12-проблемные-объявления-spend--budget)
  - [13) Права по ролям: кто что может](#13-права-по-ролям-кто-что-может)
  - [14) Проверка прав на расход X через функцию](#14-проверка-прав-на-расход-x-через-функцию)

---

## Общее описание

### Идея БД
База данных симулирует платформу для работы рекламных агентств с рекламой: сотрудники агентств создают рекламные объекты (креативы), планируют размещения, добавляют расходы, а также отправляют действия на согласование, если полномочий/лимитов роли недостаточно.

## Таблицы и поля

### role — роли и полномочия
`role_id` — PK роли  
`role_code` — код роли (уникальный)  
`role_name` — человекочитаемое имя роли  
`can_create_ad` — право создавать рекламу  
`can_add_cost` — право добавлять расходы  
`can_approve` — право согласовывать  
`max_cost_amount` — лимит суммы расхода (NULL = без лимита)  

### ad_agency — рекламные агентства
`agency_id` — PK агентства  
`name` — название (уникальное)  
`description` — описание агентства  
`created_at` — дата/время создания записи  

### advertiser — рекламодатели (клиенты)
`advertiser_id` — PK рекламодателя  
`name` — название (уникальное)  
`description` — описание рекламодателя  
`industry_type` — сфера деятельности (тип/индустрия)  
`created_at` — дата/время создания записи  

### app_user — пользователи системы (сотрудники)
`user_id` — PK пользователя  
`agency_id` — FK на агентство пользователя  
`role_id` — FK на роль (полномочия)  
`email` — email (уникальный логин)  
`full_name` — ФИО  
`is_active` — признак активности пользователя  
`created_at` — дата/время создания записи  

### campaign — рекламные кампании
`campaign_id` — PK кампании  
`advertiser_id` — FK на рекламодателя (владельца кампании)  
`title` — название кампании  
`objective` — цель кампании (traffic/leads/…)  
`start_date` — дата старта  
`end_date` — дата окончания  
`total_budget` — общий бюджет кампании  
`status` — статус кампании (draft/active/paused/completed)  
`created_at` — дата/время создания  
`updated_at` — дата/время последнего изменения  

### campaign_agency — участие агентств в кампаниях (M:N)
`campaign_id` — FK на кампанию (часть составного PK)  
`agency_id` — FK на агентство (часть составного PK)  
`agency_role` — роль агентства в кампании (creative/media_buying/…)  
`contract_budget` — бюджет по контракту/договорённости (опционально)  

### ad — единичная реклама/креатив
`ad_id` — PK рекламы  
`erid` — внешний идентификатор (уникальный)  
`campaign_id` — FK на кампанию  
`created_by_user_id` — FK на пользователя-автора  
`title` — заголовок/название рекламы  
`description` — описание  
`format` — формат (banner/video/native/audio/text)  
`ad_budget` — бюджет рекламы  
`status` — статус рекламы (draft/ready/archived)  
`created_at` — дата/время создания  
`updated_at` — дата/время последнего изменения  

### placement — размещение рекламы
`placement_id` — PK размещения  
`campaign_id` — FK на кампанию  
`ad_id` — FK на рекламу (что размещаем)  
`channel` — канал размещения (search/social/display/…)  
`inventory_source` — источник инвентаря/площадка  
`pricing_model` — модель оплаты (CPM/CPC/CPA/flat)  
`planned_impressions` — план показов (опционально)  
`planned_clicks` — план кликов (опционально)  
`start_date` — дата старта размещения (опционально)  
`end_date` — дата окончания размещения (опционально)  
`status` — статус размещения (planned/running/stopped/done)  
`created_at` — дата/время создания  
`updated_at` — дата/время последнего изменения  

### ad_cost — расходы (траты)
`cost_id` — PK расхода  
`ad_id` — FK на рекламу (к чему относится расход)  
`placement_id` — FK на размещение (NULL = общий расход по рекламе)  
`created_by_user_id` — FK на пользователя (кто добавил расход)  
`cost_type` — тип расхода (production/media/fee/tax/other)  
`title` — название расхода  
`description` — описание расхода  
`amount` — сумма расхода  
`currency_code` — валюта (например, RUB)  
`cost_date` — дата расхода  
`created_at` — дата/время добавления расхода  

### approval_request — запросы на согласование
`request_id` — PK запроса  
`requested_by_user_id` — FK на пользователя (кто запросил)  
`approved_by_user_id` — FK на пользователя (кто согласовал; NULL пока не решено)  
`entity_type` — тип сущности (ad/ad_cost/placement)  
`entity_id` — ID сущности указанного типа (полиморфная ссылка)  
`action` — действие (create/update/delete/submit_cost)  
`reason` — причина/комментарий  
`status` — статус (pending/approved/rejected/canceled)  
`created_at` — дата/время создания запроса  
`decided_at` — дата/время решения (NULL если pending)  

Также используется представление:
- `v_ad_spend` — свод расходов по каждой рекламе (агрегация `ad_cost`).

### Примерная схема:
[![](https://mermaid.ink/img/pako:eNq1V9tu4zYQ_RWBwL45QWLLiS2gD6qjpEZsx3WcRbswIDAiY7OVSJWXdN1s_r2jm6MLd9fb7j7FnhkP5xyemWFeUCQIRR6i8orhrcTJhjvO6m4WOC_ZJ8f5eXozXawdKWIaMuIsbwvzOvitNGYJnA0ynP1l6Aa13RwntMx0B2n9hRNhHkaSYk1DTLouTAjkVNriSVMpnstsi4d5sJpOnAR_zMNDnAjDNVSyeJjNfjI8ZgnTlBQVvW549se_Cv2bYDH5vYUObymP9h18We12aISqSLJUM8FL63Qe3K_9-XL9wSnAkRDrxtHvg9V6eh-s2meTZyo1U1T-r_MzK-PEKC33od6n9Ni6lsvwoVuVadXTIer61qqP63r9NMEstgN4MnFs0QZTIY40ez62-gn4_OnNolV9hJMUsy23IWjQ3ShXMx3T2nfx-AetFXPlrwNHaSx1SKCSmpFyUjNVytRC4zh8NGRLdS0rZNBGfQ1f02dS8nnsdkk3Kei176uu-F6ThtKV3WgTUCS4lnA9NUwHcXdE3REzlWBpa8FSbKvQipbHfWiOuTR7ZzwJmVTEVnCgxh93OcuZPwnmAQBoEpPGOKIJ5doizS-wUPDZAB7tMOc0brT_MyQW0P9KGBnVWUklixjfhgkM67hdEKSB9EkqqVJAm7L6o5hFf6pv64TvSykM78ndfZvQfPbb2tzCYoP861tQI4cxhB_jjh6_Irr80NqQPUqIB93li6qwTX7xV05kpMxbLlulNTLzU2psHjHKV3fv_Vm4Cn59CDpMSQqNZyWr9NgBV4QWy7cVYqGwaHYOdNT3UJmltDNSnzdRq1kBm2oY_ouECI0YaTP07p2zojHOzlM7lqrmm-DTp5MT8fK2ET1YYGks9urwJupGwJOJa9VZ8WXgYT15jvi7aKyDqcp1Bc5ssmJWBBySNwJypKq19FqnVDg8Z4ft0LqRKTQxjIb089nfJpmXD4Mys80tDVdhdnPNkKpx87ryx5pqjshOnMwuiZK32C4pVSg8F1XrJfN2S8128CqhqyPDS81DOOqhLewv5D3hWNEeSijsk-w7yntsg_QOBssGefCR0CdsYp31wyv8LsX8gxAJ8rQ08EspzHZ3yFMMuvLpfQiBKUrlJJsSyBsP-nkO5L2gj8g7OR8MT123Pxyf9S8G4_PR6LKH9sgbuqfj4bA_GrkXZ5fn567rvvbQP_m5_dPh6GIwHI377lm_f3nmDnqIEgaLYl68_fN_AV7_BfS_xdc?type=png)](https://mermaid.live/edit#pako:eNq1V9tu4zYQ_RWBwL45QWLLiS2gD6qjpEZsx3WcRbswIDAiY7OVSJWXdN1s_r2jm6MLd9fb7j7FnhkP5xyemWFeUCQIRR6i8orhrcTJhjvO6m4WOC_ZJ8f5eXozXawdKWIaMuIsbwvzOvitNGYJnA0ynP1l6Aa13RwntMx0B2n9hRNhHkaSYk1DTLouTAjkVNriSVMpnstsi4d5sJpOnAR_zMNDnAjDNVSyeJjNfjI8ZgnTlBQVvW549se_Cv2bYDH5vYUObymP9h18We12aISqSLJUM8FL63Qe3K_9-XL9wSnAkRDrxtHvg9V6eh-s2meTZyo1U1T-r_MzK-PEKC33od6n9Ni6lsvwoVuVadXTIer61qqP63r9NMEstgN4MnFs0QZTIY40ez62-gn4_OnNolV9hJMUsy23IWjQ3ShXMx3T2nfx-AetFXPlrwNHaSx1SKCSmpFyUjNVytRC4zh8NGRLdS0rZNBGfQ1f02dS8nnsdkk3Kei176uu-F6ThtKV3WgTUCS4lnA9NUwHcXdE3REzlWBpa8FSbKvQipbHfWiOuTR7ZzwJmVTEVnCgxh93OcuZPwnmAQBoEpPGOKIJ5doizS-wUPDZAB7tMOc0brT_MyQW0P9KGBnVWUklixjfhgkM67hdEKSB9EkqqVJAm7L6o5hFf6pv64TvSykM78ndfZvQfPbb2tzCYoP861tQI4cxhB_jjh6_Irr80NqQPUqIB93li6qwTX7xV05kpMxbLlulNTLzU2psHjHKV3fv_Vm4Cn59CDpMSQqNZyWr9NgBV4QWy7cVYqGwaHYOdNT3UJmltDNSnzdRq1kBm2oY_ouECI0YaTP07p2zojHOzlM7lqrmm-DTp5MT8fK2ET1YYGks9urwJupGwJOJa9VZ8WXgYT15jvi7aKyDqcp1Bc5ssmJWBBySNwJypKq19FqnVDg8Z4ft0LqRKTQxjIb089nfJpmXD4Mys80tDVdhdnPNkKpx87ryx5pqjshOnMwuiZK32C4pVSg8F1XrJfN2S8128CqhqyPDS81DOOqhLewv5D3hWNEeSijsk-w7yntsg_QOBssGefCR0CdsYp31wyv8LsX8gxAJ8rQ08EspzHZ3yFMMuvLpfQiBKUrlJJsSyBsP-nkO5L2gj8g7OR8MT123Pxyf9S8G4_PR6LKH9sgbuqfj4bA_GrkXZ5fn567rvvbQP_m5_dPh6GIwHI377lm_f3nmDnqIEgaLYl68_fN_AV7_BfS_xdc)
---

## Работа с контейнером

### Требования
- Docker + Docker Compose.
- Репозиторий примонтирован в контейнер как `./:/work`.

### Быстрый старт
1) Перейти в папку проекта (где лежит `docker-compose.yml`).

2) Запустить bootstrap-скрипт финальной домашки:

```bash
chmod +x Homework-Final/bootstrap_ad_platform.sh
./Homework-Final/bootstrap_ad_platform.sh
```

Скрипт по очереди делает:
- `docker compose down -v`
- `docker compose up -d`
- создаёт отдельную БД `ad_platform`
- применяет `Homework-Final/schema.sql`
- применяет `Homework-Final/seed.sql`
- задаёт `search_path` для роли `postgres` в этой БД

### Подключаемся к бд

Зайти в контейнер:

```bash
docker compose exec -it postgres bash
```

Подключаемся к бд:
```bash
psql -U postgres -d ad_platform
```

После этого можем выполнять команды 

------

## Выполнение запросов

### 1) Отчёт: траты по рекламе vs бюджет
Запрос:  
```sql
SELECT
  adv.name AS advertiser,
  c.title AS campaign,
  a.erid,
  a.title AS ad_title,
  a.ad_budget,
  COALESCE(SUM(ac.amount), 0) AS spend,
  (a.ad_budget - COALESCE(SUM(ac.amount), 0)) AS remaining
FROM advertiser adv
JOIN campaign c ON c.advertiser_id = adv.advertiser_id
JOIN ad a ON a.campaign_id = c.campaign_id
LEFT JOIN ad_cost ac ON ac.ad_id = a.ad_id
GROUP BY adv.name, c.title, a.erid, a.title, a.ad_budget
HAVING COALESCE(SUM(ac.amount), 0) > 0
ORDER BY spend DESC;
```

Результат запроса:    
```sql
   advertiser   |          campaign           |   erid    |           ad_title            | ad_budget |   spend   | remaining
----------------+-----------------------------+-----------+-------------------------------+-----------+-----------+-----------
 VolgaBank      | Ипотека 2026: лидогенерация | ERID-0003 | Текст+картинка: ипотека       | 600000.00 | 155000.00 | 445000.00
 Snegiri Retail | Новый год: акции и скидки   | ERID-0001 | Баннер: -20% на товары        |  10000.00 |  53000.00 | -43000.00
 Snegiri Retail | Новый год: акции и скидки   | ERID-0002 | Видео: новогодние предложения | 350000.00 |   4500.00 | 345500.00
(3 rows)
```

### 2) Топ кампаний по тратам (CTE)
Запрос:  
```sql
WITH campaign_spend AS (
  SELECT
    c.campaign_id,
    c.title,
    COALESCE(SUM(ac.amount), 0) AS spend
  FROM campaign c
  LEFT JOIN ad a ON a.campaign_id = c.campaign_id
  LEFT JOIN ad_cost ac ON ac.ad_id = a.ad_id
  GROUP BY c.campaign_id, c.title
)
SELECT *
FROM campaign_spend
ORDER BY spend DESC
LIMIT 5;
```

Результат запроса:  
```sql
 campaign_id |             title             |   spend
-------------+-------------------------------+-----------
           2 | Ипотека 2026: лидогенерация   | 155000.00
           1 | Новый год: акции и скидки     |  57500.00
           4 | Тест: кампания без размещений |         0
           3 | SaaS: пробный период          |         0
(4 rows)
```

### 3) Кампании с расходом > 70% бюджета
Запрос:  
```sql
WITH totals AS (
  SELECT
    c.campaign_id,
    c.title,
    c.total_budget,
    COALESCE(SUM(ac.amount), 0) AS spend
  FROM campaign c
  LEFT JOIN ad a ON a.campaign_id = c.campaign_id
  LEFT JOIN ad_cost ac ON ac.ad_id = a.ad_id
  GROUP BY c.campaign_id, c.title, c.total_budget
)
SELECT
  title,
  total_budget,
  spend,
  ROUND((spend / NULLIF(total_budget, 0)) * 100, 2) AS pct_used
FROM totals
WHERE spend >= total_budget * 0.70
ORDER BY pct_used DESC;
```

Результат запроса:  
```sql
           title           | total_budget |  spend   | pct_used
---------------------------+--------------+----------+----------
 Новый год: акции и скидки |     50000.00 | 57500.00 |   115.00
(1 row)
```

### 4) Рейтинг рекламы по тратам в кампании (window)
Запрос:  
```sql
SELECT
  c.title AS campaign,
  a.erid,
  a.title AS ad_title,
  COALESCE(SUM(ac.amount), 0) AS spend,
  RANK() OVER (PARTITION BY c.campaign_id ORDER BY COALESCE(SUM(ac.amount), 0) DESC) AS spend_rank_in_campaign
FROM campaign c
JOIN ad a ON a.campaign_id = c.campaign_id
LEFT JOIN ad_cost ac ON ac.ad_id = a.ad_id
GROUP BY c.campaign_id, c.title, a.erid, a.title
ORDER BY c.title, spend_rank_in_campaign, a.erid;
```

Результат запроса:  
```sql
           campaign            |   erid    |            ad_title             |   spend   | spend_rank_in_campaign
-------------------------------+-----------+---------------------------------+-----------+------------------------
 SaaS: пробный период          | ERID-0004 | Текст: 14 дней бесплатно        |         0 |                      1
 Ипотека 2026: лидогенерация   | ERID-0003 | Текст+картинка: ипотека         | 155000.00 |                      1
 Новый год: акции и скидки     | ERID-0001 | Баннер: -20% на товары          |  53000.00 |                      1
 Новый год: акции и скидки     | ERID-0002 | Видео: новогодние предложения   |   4500.00 |                      2
 Тест: кампания без размещений | ERID-0099 | Тестовый креатив без размещений |         0 |                      1
(5 rows)
```

### 5) Бегущий итог трат по датам (window)
Запрос:  
```sql
SELECT
  a.erid,
  a.title AS ad_title,
  ac.cost_date,
  ac.amount,
  SUM(ac.amount) OVER (PARTITION BY a.ad_id ORDER BY ac.cost_date, ac.cost_id) AS running_spend
FROM ad a
JOIN ad_cost ac ON ac.ad_id = a.ad_id
ORDER BY a.erid, ac.cost_date, ac.cost_id;
```

Результат запроса:  
```sql
   erid    |           ad_title            | cost_date  |  amount   | running_spend
-----------+-------------------------------+------------+-----------+---------------
 ERID-0001 | Баннер: -20% на товары        | 2025-12-20 |  48000.00 |      48000.00
 ERID-0001 | Баннер: -20% на товары        | 2025-12-22 |   5000.00 |      53000.00
 ERID-0002 | Видео: новогодние предложения | 2025-12-16 |   4500.00 |       4500.00
 ERID-0003 | Текст+картинка: ипотека       | 2025-12-05 |  35000.00 |      35000.00
 ERID-0003 | Текст+картинка: ипотека       | 2025-12-25 | 120000.00 |     155000.00
(5 rows)
```

### 6) Последнее размещение для каждой рекламы (ROW_NUMBER)
Запрос:  
```sql
WITH ranked_placements AS (
  SELECT
    p.*,
    ROW_NUMBER() OVER (
      PARTITION BY p.ad_id
      ORDER BY COALESCE(p.end_date, DATE '9999-12-31') DESC, p.placement_id DESC
    ) AS rn
  FROM placement p
)
SELECT
  a.erid,
  a.title AS ad_title,
  rp.channel,
  rp.pricing_model,
  rp.status,
  rp.start_date,
  rp.end_date
FROM ranked_placements rp
JOIN ad a ON a.ad_id = rp.ad_id
WHERE rp.rn = 1
ORDER BY a.erid;
```

Результат запроса:  
```sql
   erid    |           ad_title            | channel | pricing_model | status  | start_date |  end_date
-----------+-------------------------------+---------+---------------+---------+------------+------------
 ERID-0001 | Баннер: -20% на товары        | display | CPM           | running | 2025-12-05 | 2025-12-31
 ERID-0002 | Видео: новогодние предложения | social  | CPC           | planned | 2025-12-15 | 2026-01-10
 ERID-0003 | Текст+картинка: ипотека       | social  | CPA           | running | 2025-11-20 | 2026-02-28
 ERID-0004 | Текст: 14 дней бесплатно      | search  | CPC           | planned | 2025-12-12 | 2026-03-10
(4 rows)
```

### 7) Объявления дороже среднего по кампании (коррелированный подзапрос)
Запрос:  
```sql
SELECT
  c.title AS campaign,
  a.erid,
  a.title AS ad_title,
  COALESCE((
    SELECT SUM(ac2.amount)
    FROM ad_cost ac2
    WHERE ac2.ad_id = a.ad_id
  ), 0) AS ad_spend
FROM ad a
JOIN campaign c ON c.campaign_id = a.campaign_id
WHERE COALESCE((
    SELECT SUM(ac3.amount)
    FROM ad_cost ac3
    WHERE ac3.ad_id = a.ad_id
  ), 0) >
  COALESCE((
    SELECT AVG(ad_sum.sp)
    FROM (
      SELECT a2.ad_id, COALESCE(SUM(ac4.amount),0) AS sp
      FROM ad a2
      LEFT JOIN ad_cost ac4 ON ac4.ad_id = a2.ad_id
      WHERE a2.campaign_id = a.campaign_id
      GROUP BY a2.ad_id
    ) ad_sum
  ), 0)
ORDER BY c.title, ad_spend DESC;
```

Результат запроса:  
```sql
         campaign          |   erid    |        ad_title        | ad_spend
---------------------------+-----------+------------------------+----------
 Новый год: акции и скидки | ERID-0001 | Баннер: -20% на товары | 53000.00
(1 row)
```

### 8) Кто добавлял расходы: агентство/пользователь
Запрос:  
```sql
SELECT
  ag.name AS agency,
  u.full_name,
  u.email,
  COUNT(*) AS costs_count,
  SUM(ac.amount) AS total_amount
FROM ad_cost ac
JOIN app_user u ON u.user_id = ac.created_by_user_id
JOIN ad_agency ag ON ag.agency_id = u.agency_id
GROUP BY ag.name, u.full_name, u.email
ORDER BY total_amount DESC, costs_count DESC;
```

Результат запроса:  
```sql
       agency       |    full_name    |           email            | costs_count | total_amount
--------------------+-----------------+----------------------------+-------------+--------------
 NN Performance Lab | Мария Кузнецова | maria.finance@nnpl.example |           1 |    120000.00
 Volga Media Group  | Иван Петров     | ivan.manager@volga.example |           2 |     53000.00
 NN Performance Lab | Павел Иванов    | pavel.manager@nnpl.example |           1 |     35000.00
 Volga Media Group  | Ольга Смирнова  | olga.junior@volga.example  |           1 |      4500.00
(4 rows)
```

### 9) Кампании без активных размещений (NOT EXISTS)
Запрос:  
```sql
SELECT
  c.campaign_id,
  c.title,
  c.status,
  c.start_date,
  c.end_date
FROM campaign c
WHERE NOT EXISTS (
  SELECT 1
  FROM placement p
  WHERE p.campaign_id = c.campaign_id
    AND p.status IN ('running', 'planned')
)
ORDER BY c.title;
```

Результат запроса:  
```sql
 campaign_id |             title             | status | start_date |  end_date
-------------+-------------------------------+--------+------------+------------
           4 | Тест: кампания без размещений | draft  | 2025-12-01 | 2026-01-31
(1 row)
```

### 10) Pending-согласования + кто запросил/кто одобряет
Запрос:  
```sql
SELECT
  ar.request_id,
  ar.entity_type,
  ar.entity_id,
  ar.action,
  ar.reason,
  ar.status,
  ar.created_at,
  req.email  AS requested_by,
  appr.email AS approved_by
FROM approval_request ar
JOIN app_user req ON req.user_id = ar.requested_by_user_id
LEFT JOIN app_user appr ON appr.user_id = ar.approved_by_user_id
WHERE ar.status = 'pending'
ORDER BY ar.created_at DESC;
```

Результат запроса:  
```sql
 request_id | entity_type | entity_id | action |                      reason                       | status  |          created_at           |       requested_by       | approved_by
------------+-------------+-----------+--------+---------------------------------------------------+---------+-------------------------------+--------------------------+-------------
          1 | placement   |         4 | update | Изменение модели оплаты требует аппрува менеджера | pending | 2025-12-25 23:35:12.403811+00 | egor.viewer@nnpl.example |
(1 row)
```

### 11) Бюджеты/траты по агентствам внутри кампаний
Запрос:  
```sql
SELECT
  c.title AS campaign,
  ag.name AS agency,
  ca.agency_role,
  ca.contract_budget,
  COALESCE(SUM(ac.amount), 0) AS spend_by_agency_users
FROM campaign c
JOIN campaign_agency ca ON ca.campaign_id = c.campaign_id
JOIN ad_agency ag ON ag.agency_id = ca.agency_id
LEFT JOIN app_user u ON u.agency_id = ag.agency_id
LEFT JOIN ad_cost ac ON ac.created_by_user_id = u.user_id
LEFT JOIN ad a ON a.ad_id = ac.ad_id AND a.campaign_id = c.campaign_id
GROUP BY c.title, ag.name, ca.agency_role, ca.contract_budget
ORDER BY c.title, spend_by_agency_users DESC;
```

Результат запроса:  
```sql
           campaign            |       agency       | agency_role  | contract_budget | spend_by_agency_users
-------------------------------+--------------------+--------------+-----------------+-----------------------
 SaaS: пробный период          | Volga Media Group  | creative     |       250000.00 |              57500.00
 Ипотека 2026: лидогенерация   | NN Performance Lab | performance  |      1200000.00 |             155000.00
 Новый год: акции и скидки     | NN Performance Lab | media_buying |       400000.00 |             155000.00
 Новый год: акции и скидки     | Volga Media Group  | full_service |       700000.00 |              57500.00
 Тест: кампания без размещений | Volga Media Group  | creative     |        50000.00 |              57500.00
(5 rows)
```

### 12) Проблемные объявления: spend > budget
Запрос:  
```sql
SELECT
  a.erid,
  a.title AS ad_title,
  a.ad_budget,
  COALESCE(SUM(ac.amount), 0) AS spend,
  (COALESCE(SUM(ac.amount), 0) - a.ad_budget) AS overspend
FROM ad a
LEFT JOIN ad_cost ac ON ac.ad_id = a.ad_id
GROUP BY a.erid, a.title, a.ad_budget
HAVING COALESCE(SUM(ac.amount), 0) > a.ad_budget
ORDER BY overspend DESC;
```

Результат запроса:  
```sql
   erid    |        ad_title        | ad_budget |  spend   | overspend
-----------+------------------------+-----------+----------+-----------
 ERID-0001 | Баннер: -20% на товары |  10000.00 | 53000.00 |  43000.00
(1 row)
```

### 13) Права по ролям: кто что может
Запрос:  
```sql
SELECT
  ag.name AS agency,
  u.full_name,
  u.email,
  r.role_code,
  r.can_create_ad,
  r.can_add_cost,
  r.can_approve,
  r.max_cost_amount
FROM app_user u
JOIN role r ON r.role_id = u.role_id
JOIN ad_agency ag ON ag.agency_id = u.agency_id
WHERE u.is_active = TRUE
ORDER BY ag.name, r.role_code, u.email;
```

Результат запроса:  
```sql
       agency       |    full_name    |           email            | role_code | can_create_ad | can_add_cost | can_approve | max_cost_amount
--------------------+-----------------+----------------------------+-----------+---------------+--------------+-------------+-----------------
 NN Performance Lab | Мария Кузнецова | maria.finance@nnpl.example | FINANCE   | f             | t            | t           |
 NN Performance Lab | Павел Иванов    | pavel.manager@nnpl.example | MANAGER   | t             | t            | t           |        50000.00
 NN Performance Lab | Егор Соколов    | egor.viewer@nnpl.example   | VIEWER    | f             | f            | f           |
 Volga Media Group  | Ольга Смирнова  | olga.junior@volga.example  | JUNIOR    | t             | t            | f           |         5000.00
 Volga Media Group  | Иван Петров     | ivan.manager@volga.example | MANAGER   | t             | t            | t           |        50000.00
(5 rows)
```

### 14) Проверка прав на расход X через функцию
Запрос:  
```sql
SELECT
  ag.name AS agency,
  u.email,
  r.role_code,
  fn_can_user_add_cost(u.user_id, 6000.00) AS can_add_cost_6000,
  fn_can_user_add_cost(u.user_id, 50000.00) AS can_add_cost_50000
FROM app_user u
JOIN role r ON r.role_id = u.role_id
JOIN ad_agency ag ON ag.agency_id = u.agency_id
WHERE u.is_active = TRUE
ORDER BY ag.name, r.role_code, u.email;
```

Результат запроса:  
```sql
       agency       |           email            | role_code | can_add_cost_6000 | can_add_cost_50000
--------------------+----------------------------+-----------+-------------------+--------------------
 NN Performance Lab | maria.finance@nnpl.example | FINANCE   | t                 | t
 NN Performance Lab | pavel.manager@nnpl.example | MANAGER   | t                 | t
 NN Performance Lab | egor.viewer@nnpl.example   | VIEWER    | f                 | f
 Volga Media Group  | olga.junior@volga.example  | JUNIOR    | f                 | f
 Volga Media Group  | ivan.manager@volga.example | MANAGER   | t                 | t
(5 rows)
```
