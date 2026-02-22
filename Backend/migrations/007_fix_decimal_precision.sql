-- Migration: 007 - Fix Decimal Precision for Viral Coins
-- Created: 2026-02-21
-- Purpose: Increase decimal precision for price columns to support viral coins
--          with micro-prices (e.g., $0.00000138)
--
-- Problem: DECIMAL(15, 2) rounds prices like $0.00000138 to $0.00
--          This violates the price_per_coin > 0 constraint
--          Causing silent transaction failures for viral coins
--
-- Solution: Change to DECIMAL(20, 10) to support up to 10 decimal places

BEGIN;

-- ============================================================================
-- TRANSACTIONS TABLE - Fix price_per_coin precision
-- ============================================================================

-- First, drop the constraint that references the column
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS price_per_coin_positive;

-- Change column type to support micro-prices
ALTER TABLE transactions
    ALTER COLUMN price_per_coin TYPE DECIMAL(20, 10);

-- Re-add the constraint
ALTER TABLE transactions
    ADD CONSTRAINT price_per_coin_positive CHECK (price_per_coin > 0);

-- ============================================================================
-- HOLDINGS TABLE - Fix average_buy_price precision
-- ============================================================================

-- First, drop the constraint that references the column
ALTER TABLE holdings DROP CONSTRAINT IF EXISTS average_buy_price_positive;

-- Change column type to support micro-prices
ALTER TABLE holdings
    ALTER COLUMN average_buy_price TYPE DECIMAL(20, 10);

-- Re-add the constraint
ALTER TABLE holdings
    ADD CONSTRAINT average_buy_price_positive CHECK (average_buy_price > 0);

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Run this after the migration to verify the changes:

-- Check transactions column type
SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_name = 'transactions' AND column_name = 'price_per_coin';

-- Check holdings column type
SELECT column_name, data_type, numeric_precision, numeric_scale
FROM information_schema.columns
WHERE table_name = 'holdings' AND column_name = 'average_buy_price';

-- Expected output for both:
-- numeric_precision: 20
-- numeric_scale: 10

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- After running this migration:
-- - Viral coins with micro-prices (e.g., $0.00000138) can be stored
-- - Existing data is preserved (no precision loss for values already stored)
-- - Constraints still enforce positive prices
