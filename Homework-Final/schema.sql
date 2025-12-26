-- Платформа для работы рекламных агентств с рекламой
-- Идея: пользователь (сотрудник агентства) создаёт рекламу/расходы, а полномочия задаются ролью.
-- Часть действий может требовать согласования (approval_request).

BEGIN;

-- 0) Схема (namespace) проекта
CREATE SCHEMA IF NOT EXISTS ad_platform;
COMMENT ON SCHEMA ad_platform IS 'рекламная платформа (агентства, кампании, реклама, расходы, согласования).';

SET search_path TO ad_platform, public;

-- 1) Справочник ролей (полномочия)
CREATE TABLE role (
  role_id BIGSERIAL PRIMARY KEY,
  role_code TEXT NOT NULL UNIQUE,
  role_name TEXT NOT NULL,
  can_create_ad BOOLEAN NOT NULL DEFAULT FALSE,
  can_add_cost BOOLEAN NOT NULL DEFAULT FALSE,
  can_approve BOOLEAN NOT NULL DEFAULT FALSE,
  max_cost_amount NUMERIC(14,2) NULL CHECK (max_cost_amount IS NULL OR max_cost_amount >= 0)
);

COMMENT ON TABLE role IS 'Роли пользователей (полномочия и лимиты).';
COMMENT ON COLUMN role.max_cost_amount IS 'Максимальная сумма расхода, которую роль может добавить без аппрува (NULL = без лимита).';

-- 2) Рекламное агентство
CREATE TABLE ad_agency (
  agency_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ad_agency IS 'Рекламное агентство (организация-исполнитель).';

-- 3) Рекламодатель (клиент)
CREATE TABLE advertiser (
  advertiser_id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  industry_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE advertiser IS 'Рекламодатель (клиент/компания).';
COMMENT ON COLUMN advertiser.industry_type IS 'Сфера деятельности рекламодателя (упрощённо текстом).';

-- 4) Пользователь (сотрудник агентства)
CREATE TABLE app_user (
  user_id BIGSERIAL PRIMARY KEY,
  agency_id BIGINT NOT NULL REFERENCES ad_agency(agency_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  role_id BIGINT NOT NULL REFERENCES role(role_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE app_user IS 'Пользователь системы (сотрудник агентства).';
COMMENT ON COLUMN app_user.role_id IS 'Роль определяет полномочия (создание рекламы, добавление расходов, согласование).';

-- 5) Рекламная кампания
CREATE TABLE campaign (
  campaign_id BIGSERIAL PRIMARY KEY,
  advertiser_id BIGINT NOT NULL REFERENCES advertiser(advertiser_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  title TEXT NOT NULL,
  objective TEXT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_budget NUMERIC(14,2) NOT NULL CHECK (total_budget >= 0),
  status TEXT NOT NULL CHECK (status IN ('draft','active','paused','completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT campaign_dates_chk CHECK (end_date >= start_date)
);

COMMENT ON TABLE campaign IS 'Рекламная кампания рекламодателя.';
COMMENT ON COLUMN campaign.total_budget IS 'Общий бюджет кампании на рекламу(план).';

-- 6) Связка кампании и агентства (M:N)
CREATE TABLE campaign_agency (
  campaign_id BIGINT NOT NULL REFERENCES campaign(campaign_id) ON UPDATE CASCADE ON DELETE CASCADE,
  agency_id BIGINT NOT NULL REFERENCES ad_agency(agency_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  agency_role TEXT NOT NULL,
  contract_budget NUMERIC(14,2) NULL CHECK (contract_budget IS NULL OR contract_budget >= 0),
  PRIMARY KEY (campaign_id, agency_id)
);

COMMENT ON TABLE campaign_agency IS 'Какие агентства участвуют в кампании и в какой роли.';

-- 7) Единичная реклама (креатив)
CREATE TABLE ad (
  ad_id BIGSERIAL PRIMARY KEY,
  erid TEXT UNIQUE,
  campaign_id BIGINT NOT NULL REFERENCES campaign(campaign_id) ON UPDATE CASCADE ON DELETE CASCADE,
  created_by_user_id BIGINT NOT NULL REFERENCES app_user(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  title TEXT NOT NULL,
  description TEXT,
  format TEXT NOT NULL CHECK (format IN ('banner','video','native','audio','text')),
  ad_budget NUMERIC(14,2) NOT NULL CHECK (ad_budget >= 0),
  status TEXT NOT NULL CHECK (status IN ('draft','ready','archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ad IS 'Единичная реклама/креатив внутри кампании.';
COMMENT ON COLUMN ad.erid IS 'Внешний идентификатор.';

-- 8) Размещение рекламы
CREATE TABLE placement (
  placement_id BIGSERIAL PRIMARY KEY,
  campaign_id BIGINT NOT NULL REFERENCES campaign(campaign_id) ON UPDATE CASCADE ON DELETE CASCADE,
  ad_id BIGINT NOT NULL REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('search','social','display','video_network','offline')),
  inventory_source TEXT,
  pricing_model TEXT NOT NULL CHECK (pricing_model IN ('CPM','CPC','CPA','flat')),
  planned_impressions BIGINT NULL CHECK (planned_impressions IS NULL OR planned_impressions >= 0),
  planned_clicks BIGINT NULL CHECK (planned_clicks IS NULL OR planned_clicks >= 0),
  start_date DATE,
  end_date DATE,
  status TEXT NOT NULL CHECK (status IN ('planned','running','stopped','done')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT placement_dates_chk CHECK (
    start_date IS NULL OR end_date IS NULL OR end_date >= start_date
  )
);

COMMENT ON TABLE placement IS 'Размещение (площадка/канал/модель оплаты) для конкретной рекламы.';

-- 9) Расходы по рекламе
CREATE TABLE ad_cost (
  cost_id BIGSERIAL PRIMARY KEY,
  ad_id BIGINT NOT NULL REFERENCES ad(ad_id) ON UPDATE CASCADE ON DELETE CASCADE,
  placement_id BIGINT NULL REFERENCES placement(placement_id) ON UPDATE CASCADE ON DELETE SET NULL,
  created_by_user_id BIGINT NOT NULL REFERENCES app_user(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  cost_type TEXT NOT NULL CHECK (cost_type IN ('production','media','fee','tax','other')),
  title TEXT NOT NULL,
  description TEXT,
  amount NUMERIC(14,2) NOT NULL CHECK (amount >= 0),
  currency_code CHAR(3) NOT NULL,
  cost_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE ad_cost IS 'Расходы/траты в рамках рекламы (и опционально размещения).';
COMMENT ON COLUMN ad_cost.placement_id IS 'NULL = общий расход по рекламе, иначе привязка к размещению.';

-- 10) Запросы на согласование (полиморфная ссылка на сущность)
CREATE TABLE approval_request (
  request_id BIGSERIAL PRIMARY KEY,
  requested_by_user_id BIGINT NOT NULL REFERENCES app_user(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  approved_by_user_id BIGINT NULL REFERENCES app_user(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('ad','ad_cost','placement')),
  entity_id BIGINT NOT NULL,
  action TEXT NOT NULL CHECK (action IN ('create','update','delete','submit_cost')),
  reason TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending','approved','rejected','canceled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  decided_at TIMESTAMPTZ NULL
);

COMMENT ON TABLE approval_request IS 'Согласования действий, когда у пользователя недостаточно прав/лимита.';
COMMENT ON COLUMN approval_request.entity_id IS 'Полиморфная ссылка: ID сущности указанного типа (FK не задаётся из-за разных таблиц).';

-- Индексы для связей/фильтрации
CREATE INDEX IF NOT EXISTS ix_app_user_agency ON app_user(agency_id);
CREATE INDEX IF NOT EXISTS ix_app_user_role ON app_user(role_id);

CREATE INDEX IF NOT EXISTS ix_campaign_advertiser ON campaign(advertiser_id);
CREATE INDEX IF NOT EXISTS ix_ad_campaign ON ad(campaign_id);
CREATE INDEX IF NOT EXISTS ix_placement_ad ON placement(ad_id);
CREATE INDEX IF NOT EXISTS ix_ad_cost_ad ON ad_cost(ad_id);
CREATE INDEX IF NOT EXISTS ix_approval_request_status ON approval_request(status);


-- VIEW: свод по расходам рекламы
CREATE OR REPLACE VIEW v_ad_spend AS
SELECT
  a.ad_id,
  a.title AS ad_title,
  a.campaign_id,
  COALESCE(SUM(c.amount), 0) AS total_spend
FROM ad a
LEFT JOIN ad_cost c ON c.ad_id = a.ad_id
GROUP BY a.ad_id, a.title, a.campaign_id;

COMMENT ON VIEW v_ad_spend IS 'Свод расходов по каждой рекламе (ad_id).';


-- ТРИГГЕРЫ + ТРИГГЕРНЫЕ ФУНКЦИИ

-- Trigger function #1: авто-проставление updated_at
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_set_updated_at() IS 'Триггерная функция: автоматически обновляет updated_at.';

-- Триггеры на таблицы, где есть updated_at
CREATE TRIGGER set_campaign_updated_at
BEFORE UPDATE ON campaign
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER set_ad_updated_at
BEFORE UPDATE ON ad
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER set_placement_updated_at
BEFORE UPDATE ON placement
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

COMMENT ON TRIGGER set_campaign_updated_at ON campaign IS 'Авто-обновление campaign.updated_at.';
COMMENT ON TRIGGER set_ad_updated_at ON ad IS 'Авто-обновление ad.updated_at.';
COMMENT ON TRIGGER set_placement_updated_at ON placement IS 'Авто-обновление placement.updated_at.';

-- Trigger function #2: проверка полномочий при добавлении расхода.
-- Если роль не позволяет добавлять расходы или превышен лимит -> RAISE EXCEPTION.
CREATE OR REPLACE FUNCTION trg_check_cost_permissions()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_can_add_cost BOOLEAN;
  v_max_cost NUMERIC(14,2);
BEGIN
  SELECT r.can_add_cost, r.max_cost_amount
    INTO v_can_add_cost, v_max_cost
  FROM app_user u
  JOIN role r ON r.role_id = u.role_id
  WHERE u.user_id = NEW.created_by_user_id
    AND u.is_active = TRUE;

  IF v_can_add_cost IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'User % has no permission to add costs', NEW.created_by_user_id;
  END IF;

  IF v_max_cost IS NOT NULL AND NEW.amount > v_max_cost THEN
    RAISE EXCEPTION 'Cost %.2f exceeds role limit %.2f for user %',
      NEW.amount, v_max_cost, NEW.created_by_user_id;
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION trg_check_cost_permissions() IS 'Триггерная функция: запрещает добавлять расходы без полномочий/при превышении лимита.';

CREATE TRIGGER check_cost_permissions
BEFORE INSERT ON ad_cost
FOR EACH ROW
EXECUTE FUNCTION trg_check_cost_permissions();

COMMENT ON TRIGGER check_cost_permissions ON ad_cost IS 'Проверка полномочий и лимита роли при INSERT расхода.';

-- ХРАНИМЫЕ ФУНКЦИИ (НЕ ТРИГГЕРНЫЕ!)

-- Function #1: посчитать потрачено по кампании (сумма расходов всех ad)
CREATE OR REPLACE FUNCTION fn_campaign_spend(p_campaign_id BIGINT)
RETURNS NUMERIC(14,2)
LANGUAGE plpgsql
AS $$
DECLARE
  v_sum NUMERIC(14,2);
BEGIN
  SELECT COALESCE(SUM(c.amount), 0)
    INTO v_sum
  FROM ad a
  JOIN ad_cost c ON c.ad_id = a.ad_id
  WHERE a.campaign_id = p_campaign_id;

  RETURN v_sum;
END;
$$;

COMMENT ON FUNCTION fn_campaign_spend(BIGINT) IS 'Хранимая функция: возвращает сумму расходов по кампании.';

-- Function #2: проверка "может ли пользователь добавить расход на сумму" (без вставки)
CREATE OR REPLACE FUNCTION fn_can_user_add_cost(p_user_id BIGINT, p_amount NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
  v_can BOOLEAN;
  v_max NUMERIC(14,2);
BEGIN
  SELECT r.can_add_cost, r.max_cost_amount
    INTO v_can, v_max
  FROM app_user u
  JOIN role r ON r.role_id = u.role_id
  WHERE u.user_id = p_user_id
    AND u.is_active = TRUE;

  IF v_can IS DISTINCT FROM TRUE THEN
    RETURN FALSE;
  END IF;

  IF v_max IS NOT NULL AND p_amount > v_max THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION fn_can_user_add_cost(BIGINT, NUMERIC) IS 'Хранимая функция: true, если роль пользователя позволяет добавить расход на указанную сумму.';

COMMIT;
