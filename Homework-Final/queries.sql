-- Набор запросов для демонстрации работы БД ad_platform

SET search_path TO ad_platform, public;

-- 1) Отчёт: траты по рекламе + сравнение с бюджетом рекламы (JOIN + GROUP BY + HAVING)
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

-- 2) Топ расходов по кампании (CTE + JOIN + LIMIT)
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

-- 3) Кампании, где суммарные траты превысили 70% бюджета (CTE + фильтрация по выражению)
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

-- 4) Ранжирование рекламы по тратам внутри кампании (JOIN + оконная функция RANK)
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

-- 5) “Бегущий итог” трат по датам для каждой рекламы (JOIN + window SUM OVER)
SELECT
  a.erid,
  a.title AS ad_title,
  ac.cost_date,
  ac.amount,
  SUM(ac.amount) OVER (PARTITION BY a.ad_id ORDER BY ac.cost_date, ac.cost_id) AS running_spend
FROM ad a
JOIN ad_cost ac ON ac.ad_id = a.ad_id
ORDER BY a.erid, ac.cost_date, ac.cost_id;

-- 6) Находим “последнее размещение” для каждой рекламы (оконная ROW_NUMBER + фильтрация)
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

-- 7) объявления, у которых траты выше среднего по их кампании (коррелированный подзапрос)
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

-- 8) Кто и сколько добавил расходов: разрез по агентству и пользователю (JOIN + GROUP BY)
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

-- 9) Кампании без активных размещений (подзапрос NOT EXISTS)
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

-- 10) Согласования pending + кто запросил/кому адресовано (JOIN + сортировка)
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

-- 11) Распределение бюджетов и расходов по агентствам внутри кампаний (JOIN + агрегирование)
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

-- 12) Найти проблемные объявления: budget < spend (JOIN + GROUP BY + HAVING)
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

-- 13) Права по ролям: кто что может (JOIN user->role, фильтры по полномочиям)
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

-- 14) Проверка хватит ли прав добавить расход X через хранимую функцию (функция в SELECT + JOIN)
-- Пример для суммы 6000 (в seed: JUNIOR лимит 5000, MANAGER 50000, FINANCE без лимита).
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
