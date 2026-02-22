-- CoinDojo Pre-Launch: Clean Test Data
-- Run this in Supabase Dashboard → SQL Editor
-- WARNING: This deletes ALL user data

BEGIN;

-- Delete in correct order (respecting foreign keys)
DELETE FROM api_rate_limit_events;
DELETE FROM transactions;
DELETE FROM holdings;
DELETE FROM portfolios;
DELETE FROM user_profiles;

COMMIT;

-- Verify all tables are empty
SELECT 'user_profiles' as table_name, count(*) as remaining FROM user_profiles
UNION ALL
SELECT 'portfolios', count(*) FROM portfolios
UNION ALL
SELECT 'holdings', count(*) FROM holdings
UNION ALL
SELECT 'transactions', count(*) FROM transactions
UNION ALL
SELECT 'api_rate_limit_events', count(*) FROM api_rate_limit_events;
