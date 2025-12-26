-- Предполагается, что schema.sql уже применён.
-- Покрытие данными: агентства -> пользователи/роли -> кампании -> реклама -> размещения -> расходы -> согласования.

BEGIN;

SET search_path TO ad_platform, public;


-- 1) Роли (полномочия)
INSERT INTO role (role_code, role_name, can_create_ad, can_add_cost, can_approve, max_cost_amount)
VALUES
  ('JUNIOR',  'Junior specialist', TRUE,  TRUE,  FALSE,  5000.00),
  ('MANAGER', 'Campaign manager',  TRUE,  TRUE,  TRUE,   50000.00),
  ('FINANCE', 'Finance controller',FALSE, TRUE,  TRUE,   NULL),
  ('VIEWER',  'Read only',         FALSE, FALSE, FALSE,  NULL)
ON CONFLICT (role_code) DO NOTHING;


-- 2) Агентства
INSERT INTO ad_agency (name, description)
VALUES
  ('Volga Media Group', 'Полный цикл: стратегия, креатив, закупка трафика.'),
  ('NN Performance Lab', 'Performance-агентство: контекст, таргет, аналитика.')
ON CONFLICT (name) DO NOTHING;


-- 3) Рекламодатели (клиенты)
INSERT INTO advertiser (name, description, industry_type)
VALUES
  ('Snegiri Retail', 'Федеральная сеть магазинов у дома.', 'retail'),
  ('VolgaBank', 'Региональный банк, продукты для физ/юр лиц.', 'banking'),
  ('IT Nizhny', 'ИТ-компания: SaaS для бизнеса.', 'software')
ON CONFLICT (name) DO NOTHING;


-- 4) Пользователи (сотрудники агентств)
-- Привязка делается через SELECT по уникальным полям (name, role_code, email)
INSERT INTO app_user (agency_id, role_id, email, full_name)
SELECT a.agency_id, r.role_id, v.email, v.full_name
FROM (VALUES
  ('Volga Media Group', 'MANAGER', 'ivan.manager@volga.example',  'Иван Петров'),
  ('Volga Media Group', 'JUNIOR',  'olga.junior@volga.example',   'Ольга Смирнова'),
  ('NN Performance Lab', 'MANAGER','pavel.manager@nnpl.example',  'Павел Иванов'),
  ('NN Performance Lab', 'FINANCE','maria.finance@nnpl.example',  'Мария Кузнецова'),
  ('NN Performance Lab', 'VIEWER', 'egor.viewer@nnpl.example',    'Егор Соколов')
) AS v(agency_name, role_code, email, full_name)
JOIN ad_agency a ON a.name = v.agency_name
JOIN role r ON r.role_code = v.role_code
ON CONFLICT (email) DO NOTHING;


-- 5) Кампании
INSERT INTO campaign (advertiser_id, title, objective, start_date, end_date, total_budget, status)
SELECT adv.advertiser_id, v.title, v.objective, v.start_date, v.end_date, v.total_budget, v.status
FROM (VALUES
  ('Snegiri Retail', 'Новый год: акции и скидки', 'traffic', '2025-12-01'::date, '2026-01-15'::date, 1200000.00, 'active'),
  ('VolgaBank',      'Ипотека 2026: лидогенерация', 'leads', '2025-11-15'::date, '2026-02-28'::date, 2500000.00, 'active'),
  ('IT Nizhny',      'SaaS: пробный период', 'leads', '2025-12-10'::date, '2026-03-10'::date, 800000.00, 'draft')
) AS v(advertiser_name, title, objective, start_date, end_date, total_budget, status)
JOIN advertiser adv ON adv.name = v.advertiser_name;


-- 6) Участие агентств в кампаниях (campaign_agency)
INSERT INTO campaign_agency (campaign_id, agency_id, agency_role, contract_budget)
SELECT c.campaign_id, a.agency_id, v.agency_role, v.contract_budget
FROM (VALUES
  ('Новый год: акции и скидки',         'Volga Media Group',   'full_service',  700000.00),
  ('Новый год: акции и скидки',         'NN Performance Lab',  'media_buying',  400000.00),
  ('Ипотека 2026: лидогенерация',       'NN Performance Lab',  'performance',   1200000.00),
  ('SaaS: пробный период',             'Volga Media Group',   'creative',      250000.00)
) AS v(campaign_title, agency_name, agency_role, contract_budget)
JOIN campaign c ON c.title = v.campaign_title
JOIN ad_agency a ON a.name = v.agency_name
ON CONFLICT (campaign_id, agency_id) DO NOTHING;

-- 7) Реклама (ad)
INSERT INTO ad (erid, campaign_id, created_by_user_id, title, description, format, ad_budget, status)
SELECT v.erid, c.campaign_id, u.user_id, v.title, v.description, v.format, v.ad_budget, v.status
FROM (VALUES
  ('ERID-0001', 'Новый год: акции и скидки',   'ivan.manager@volga.example',
   'Баннер: -20% на товары', 'Статичный баннер для display-сетей', 'banner', 250000.00, 'ready'),

  ('ERID-0002', 'Новый год: акции и скидки',   'olga.junior@volga.example',
   'Видео: новогодние предложения', '15 секунд, вертикальное видео', 'video', 350000.00, 'draft'),

  ('ERID-0003', 'Ипотека 2026: лидогенерация', 'pavel.manager@nnpl.example',
   'Текст+картинка: ипотека', 'Объявления для соцсетей', 'native', 600000.00, 'ready'),

  ('ERID-0004', 'SaaS: пробный период',        'ivan.manager@volga.example',
   'Текст: 14 дней бесплатно', 'Поиск/контекст, варианты заголовков', 'text', 150000.00, 'draft')
) AS v(erid, campaign_title, creator_email, title, description, format, ad_budget, status)
JOIN campaign c ON c.title = v.campaign_title
JOIN app_user u ON u.email = v.creator_email
ON CONFLICT (erid) DO NOTHING;


-- 8) Размещения (placement)
INSERT INTO placement
(campaign_id, ad_id, channel, inventory_source, pricing_model, planned_impressions, planned_clicks, start_date, end_date, status)
SELECT c.campaign_id, a.ad_id,
       v.channel, v.inventory_source, v.pricing_model,
       v.planned_impressions, v.planned_clicks,
       v.start_date, v.end_date, v.status
FROM (VALUES
  ('Новый год: акции и скидки',   'ERID-0001', 'display', 'AdNetwork X', 'CPM', 1200000::bigint, NULL::bigint, '2025-12-05'::date, '2025-12-31'::date, 'running'),
  ('Новый год: акции и скидки',   'ERID-0002', 'social',  'Social Y',    'CPC', NULL::bigint,  25000::bigint, '2025-12-15'::date, '2026-01-10'::date, 'planned'),
  ('Ипотека 2026: лидогенерация', 'ERID-0003', 'social',  'Social Y',    'CPA', NULL::bigint,  NULL::bigint,  '2025-11-20'::date, '2026-02-28'::date, 'running'),
  ('SaaS: пробный период',        'ERID-0004', 'search',  'Search Z',    'CPC', NULL::bigint,  18000::bigint, '2025-12-12'::date, '2026-03-10'::date, 'planned')
) AS v(campaign_title, erid, channel, inventory_source, pricing_model, planned_impressions, planned_clicks, start_date, end_date, status)
JOIN campaign c ON c.title = v.campaign_title
JOIN ad a ON a.erid = v.erid;


-- 9) Расходы (ad_cost)
-- в schema.sql стоит триггер check_cost_permissions, он может запретить вставку.
-- Поэтому здесь расходы подбираются так, чтобы:
-- - Junior <= 5000
-- - Manager <= 50000
-- - Finance без лимита

-- 9.1) Расходы менеджера (в пределах лимита 50000)
INSERT INTO ad_cost (ad_id, placement_id, created_by_user_id, cost_type, title, description, amount, currency_code, cost_date)
SELECT a.ad_id, p.placement_id, u.user_id, v.cost_type, v.title, v.description, v.amount, v.currency_code, v.cost_date
FROM (VALUES
  ('ERID-0001', 'display', 'ivan.manager@volga.example', 'media', 'Закупка показов (декабрь)', 'CPM закупка', 48000.00, 'RUB', '2025-12-20'::date),
  ('ERID-0003', 'social',  'pavel.manager@nnpl.example', 'fee',   'Комиссия агентства', 'Ведение кампании', 35000.00, 'RUB', '2025-12-05'::date)
) AS v(erid, channel, creator_email, cost_type, title, description, amount, currency_code, cost_date)
JOIN ad a ON a.erid = v.erid
JOIN placement p ON p.ad_id = a.ad_id AND p.channel = v.channel
JOIN app_user u ON u.email = v.creator_email;

-- 9.2) Расход junior (в пределах 5000)
INSERT INTO ad_cost (ad_id, placement_id, created_by_user_id, cost_type, title, description, amount, currency_code, cost_date)
SELECT a.ad_id, p.placement_id, u.user_id, 'production', 'Монтаж/адаптация креатива', 'Нарезка под форматы', 4500.00, 'RUB', '2025-12-16'::date
FROM ad a
JOIN placement p ON p.ad_id = a.ad_id AND p.channel = 'social'
JOIN app_user u ON u.email = 'olga.junior@volga.example'
WHERE a.erid = 'ERID-0002';

-- 9.3) Расход finance (без лимита)
INSERT INTO ad_cost (ad_id, placement_id, created_by_user_id, cost_type, title, description, amount, currency_code, cost_date)
SELECT a.ad_id, NULL::bigint, u.user_id, 'tax', 'НДС/налоги', 'Условный пример', 120000.00, 'RUB', '2025-12-25'::date
FROM ad a
JOIN app_user u ON u.email = 'maria.finance@nnpl.example'
WHERE a.erid = 'ERID-0003';

-- 10) Согласования (approval_request)
-- две записи для демонстрации выборок "pending/approved".

-- 10.1) Pending на размещение
INSERT INTO approval_request
(requested_by_user_id, approved_by_user_id, entity_type, entity_id, action, reason, status, created_at, decided_at)
SELECT
  req.user_id,
  NULL::bigint,
  'placement',
  p.placement_id,
  'update',
  'Изменение модели оплаты требует аппрува менеджера',
  'pending',
  now(),
  NULL
FROM placement p
JOIN ad a ON a.ad_id = p.ad_id
JOIN app_user req ON req.email = 'egor.viewer@nnpl.example'
WHERE a.erid = 'ERID-0004'
LIMIT 1;

-- 10.2) Approved на рекламу
INSERT INTO approval_request
(requested_by_user_id, approved_by_user_id, entity_type, entity_id, action, reason, status, created_at, decided_at)
SELECT
  req.user_id,
  appr.user_id,
  'ad',
  a.ad_id,
  'create',
  'Согласование нового креатива перед запуском',
  'approved',
  now() - interval '2 days',
  now() - interval '1 day'
FROM ad a
JOIN app_user req  ON req.email  = 'olga.junior@volga.example'
JOIN app_user appr ON appr.email = 'ivan.manager@volga.example'
WHERE a.erid = 'ERID-0002'
LIMIT 1;

COMMIT;

--- Дополнительные данные для просмотра результата запросов

INSERT INTO placement
(campaign_id, ad_id, channel, inventory_source, pricing_model, planned_impressions, planned_clicks, start_date, end_date, status)
SELECT
  c.campaign_id,
  a.ad_id,
  'search',
  'Search Z',
  'CPC',
  NULL::bigint,
  5000::bigint,
  '2025-12-12'::date,
  '2025-12-20'::date,
  'done'
FROM campaign c
JOIN ad a ON a.campaign_id = c.campaign_id
WHERE c.title = 'SaaS: пробный период'
  AND a.erid = 'ERID-0004'
ON CONFLICT DO NOTHING;

UPDATE ad
SET ad_budget = 10000.00
WHERE erid = 'ERID-0001';

UPDATE campaign
SET total_budget = 50000.00
WHERE title = 'Новый год: акции и скидки';

INSERT INTO ad_cost (ad_id, placement_id, created_by_user_id, cost_type, title, description, amount, currency_code, cost_date)
SELECT
  a.ad_id,
  p.placement_id,
  u.user_id,
  'media',
  'Дозакупка трафика',
  'Небольшой добор бюджета для демонстрации overspend',
  5000.00,
  'RUB',
  '2025-12-22'::date
FROM ad a
JOIN placement p ON p.ad_id = a.ad_id AND p.channel = 'display'
JOIN app_user u ON u.email = 'ivan.manager@volga.example'
WHERE a.erid = 'ERID-0001'
ON CONFLICT DO NOTHING;

-- 1) Кампания (draft, без размещений)
INSERT INTO campaign (advertiser_id, title, objective, start_date, end_date, total_budget, status)
SELECT adv.advertiser_id,
       'Тест: кампания без размещений',
       'awareness',
       '2025-12-01'::date,
       '2026-01-31'::date,
       300000.00,
       'draft'
FROM advertiser adv
WHERE adv.name = 'IT Nizhny'
ON CONFLICT DO NOTHING;

-- 2) Привязываем агентство к кампании (чтобы была “живая” связь M:N)
INSERT INTO campaign_agency (campaign_id, agency_id, agency_role, contract_budget)
SELECT c.campaign_id, a.agency_id, 'creative', 50000.00
FROM campaign c
JOIN ad_agency a ON a.name = 'Volga Media Group'
WHERE c.title = 'Тест: кампания без размещений'
ON CONFLICT (campaign_id, agency_id) DO NOTHING;

-- 3) Реклама в кампании (без размещений)
INSERT INTO ad (erid, campaign_id, created_by_user_id, title, description, format, ad_budget, status)
SELECT
  'ERID-0099',
  c.campaign_id,
  u.user_id,
  'Тестовый креатив без размещений',
  'Создан для демонстрации запроса NOT EXISTS по активным размещениям',
  'banner',
  20000.00,
  'draft'
FROM campaign c
JOIN app_user u ON u.email = 'ivan.manager@volga.example'
WHERE c.title = 'Тест: кампания без размещений'
ON CONFLICT (erid) DO NOTHING;