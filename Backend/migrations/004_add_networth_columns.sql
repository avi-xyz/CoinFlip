-- Migration: Add net worth calculation columns to portfolios
-- Purpose: Enable accurate leaderboard rankings for all users (active + inactive)
-- Strategy: Periodic background job recalculates net worth every 1 hour
--
-- Context: Previously, leaderboard used average_buy_price which made rankings
-- inaccurate for users with gains/losses. This migration stores calculated
-- net worth using current market prices.

-- Add columns for storing calculated net worth
ALTER TABLE portfolios
ADD COLUMN IF NOT EXISTS net_worth DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS gain_percentage DECIMAL DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_networth_update TIMESTAMPTZ DEFAULT NOW();

-- Index for fast leaderboard queries (ORDER BY net_worth DESC)
CREATE INDEX IF NOT EXISTS idx_portfolios_networth
ON portfolios(net_worth DESC);

-- Index for finding stale data (useful for manual triggers)
CREATE INDEX IF NOT EXISTS idx_portfolios_networth_update
ON portfolios(last_networth_update);

-- Comments for documentation
COMMENT ON COLUMN portfolios.net_worth IS
'Calculated net worth: cash_balance + SUM(quantity * current_price). Updated by background job every 1 hour.';

COMMENT ON COLUMN portfolios.gain_percentage IS
'Percentage gain: ((net_worth - starting_balance) / starting_balance) * 100. Updated with net_worth.';

COMMENT ON COLUMN portfolios.last_networth_update IS
'Timestamp of last net worth calculation. Used to detect stale data.';

-- Initialize existing portfolios with current cash balance as net worth
-- (Will be recalculated accurately on first job run)
UPDATE portfolios
SET
  net_worth = cash_balance,
  gain_percentage = ((cash_balance - starting_balance) / NULLIF(starting_balance, 0)) * 100,
  last_networth_update = NOW()
WHERE net_worth = 0;
