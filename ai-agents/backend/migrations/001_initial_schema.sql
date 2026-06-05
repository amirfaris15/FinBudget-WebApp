CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================
-- 1) AUTH / USER
-- =========================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name TEXT,
  home_currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (home_currency IN ('MYR', 'GBP')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash TEXT NOT NULL UNIQUE,
  expires_at TIMESTAMPTZ NOT NULL,
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
-- 2) TRANSACTIONS
-- =========================
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- raw ingestion / duplicate detection
  source_provider TEXT NOT NULL DEFAULT 'shortcut',
  raw_notification_text TEXT NOT NULL,
  raw_notification_hash TEXT NOT NULL,

  -- parsed fields
  transaction_date DATE NOT NULL,
  merchant TEXT NOT NULL,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  category TEXT NOT NULL
    CHECK (category IN (
      'food', 'transport', 'entertainment', 'utilities',
      'salary', 'transfer', 'shopping', 'other'
    )),
  confidence NUMERIC(5, 2) NOT NULL DEFAULT 0 CHECK (confidence >= 0 AND confidence <= 100),

  -- direction helps dashboard totals
  flow TEXT NOT NULL DEFAULT 'out'
    CHECK (flow IN ('in', 'out')),

  -- review / analytics
  categorization_status TEXT NOT NULL DEFAULT 'auto'
    CHECK (categorization_status IN ('auto', 'needs_review', 'manual')),
  is_unusual BOOLEAN NOT NULL DEFAULT false,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  recurring_label TEXT,
  expected_flag BOOLEAN NOT NULL DEFAULT false,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, raw_notification_hash)
);

CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_category_date ON transactions(user_id, category, transaction_date DESC);
CREATE INDEX idx_transactions_user_created_at ON transactions(user_id, created_at DESC);

-- =========================
-- 3) BUDGETS
-- =========================
CREATE TABLE budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  category TEXT NOT NULL
    CHECK (category IN (
      'food', 'transport', 'entertainment', 'utilities',
      'salary', 'transfer', 'shopping', 'other'
    )),
  budget_month DATE NOT NULL, -- first day of the budget month
  limit_minor INTEGER NOT NULL CHECK (limit_minor >= 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),

  rollover_enabled BOOLEAN NOT NULL DEFAULT false,
  payday_day INTEGER CHECK (payday_day BETWEEN 1 AND 31),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, category, budget_month, currency)
);

CREATE INDEX idx_budgets_user_month ON budgets(user_id, budget_month);

CREATE TABLE budget_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  budget_id UUID REFERENCES budgets(id) ON DELETE CASCADE,

  category TEXT NOT NULL
    CHECK (category IN (
      'food', 'transport', 'entertainment', 'utilities',
      'salary', 'transfer', 'shopping', 'other'
    )),
  alert_type TEXT NOT NULL CHECK (alert_type IN ('approaching', 'exceeded')),
  threshold_percent NUMERIC(5, 2) NOT NULL CHECK (threshold_percent >= 0 AND threshold_percent <= 100),

  spent_minor INTEGER NOT NULL CHECK (spent_minor >= 0),
  limit_minor INTEGER NOT NULL CHECK (limit_minor >= 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  message TEXT NOT NULL,

  dedupe_key TEXT NOT NULL UNIQUE, -- prevents duplicate alerts in same minute
  triggered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  dismissed_at TIMESTAMPTZ
);

CREATE INDEX idx_budget_alerts_user_triggered ON budget_alerts(user_id, triggered_at DESC);

-- =========================
-- 4) SAVINGS GOALS
-- =========================
CREATE TABLE savings_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  name TEXT NOT NULL,
  target_minor INTEGER NOT NULL CHECK (target_minor > 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  target_date DATE NOT NULL,

  monthly_contribution_minor INTEGER CHECK (monthly_contribution_minor >= 0),
  contribution_percent NUMERIC(5, 2) CHECK (contribution_percent >= 0 AND contribution_percent <= 100),

  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'archived', 'achieved')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_savings_goals_user_status ON savings_goals(user_id, status);

CREATE TABLE savings_goal_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  goal_id UUID NOT NULL REFERENCES savings_goals(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  source_type TEXT NOT NULL DEFAULT 'manual'
    CHECK (source_type IN ('manual', 'auto', 'income_allocation')),

  contributed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
-- 5) NET WORTH
-- =========================
CREATE TABLE net_worth_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  snapshot_month DATE NOT NULL, -- first day of the snapshot month
  notes TEXT,

  total_assets_minor INTEGER NOT NULL DEFAULT 0,
  total_liabilities_minor INTEGER NOT NULL DEFAULT 0,
  net_worth_minor INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (user_id, snapshot_month, currency)
);

CREATE TABLE net_worth_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  snapshot_id UUID NOT NULL REFERENCES net_worth_snapshots(id) ON DELETE CASCADE,

  item_type TEXT NOT NULL CHECK (item_type IN ('asset', 'liability')),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  amount_minor INTEGER NOT NULL CHECK (amount_minor >= 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  notes TEXT,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_net_worth_snapshots_user_month ON net_worth_snapshots(user_id, snapshot_month DESC);

-- =========================
-- 6) RECURRING / ANALYTICS
-- =========================
CREATE TABLE recurring_patterns (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  merchant_normalized TEXT NOT NULL,
  amount_minor INTEGER NOT NULL CHECK (amount_minor > 0),
  currency TEXT NOT NULL DEFAULT 'MYR'
    CHECK (currency IN ('MYR', 'GBP')),
  cadence_days INTEGER NOT NULL CHECK (cadence_days > 0),

  label TEXT,
  estimated_annual_minor INTEGER,
  is_active BOOLEAN NOT NULL DEFAULT true,

  first_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_recurring_patterns_user_merchant ON recurring_patterns(user_id, merchant_normalized);

-- =========================
-- 7) EXCHANGE RATES (POST-MVP)
-- =========================
CREATE TABLE exchange_rates (
  rate_date DATE NOT NULL,
  base_currency TEXT NOT NULL CHECK (base_currency IN ('MYR', 'GBP')),
  quote_currency TEXT NOT NULL CHECK (quote_currency IN ('MYR', 'GBP')),
  rate NUMERIC(18, 8) NOT NULL CHECK (rate > 0),
  source TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  PRIMARY KEY (rate_date, base_currency, quote_currency)
);
