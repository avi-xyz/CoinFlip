-- Migration: Add chain_id column to holdings table
-- Purpose: Store blockchain network identifier for viral coins to enable price lookups
-- Date: 2026-01-20

-- Add chain_id column to holdings table (nullable for backward compatibility)
ALTER TABLE holdings
ADD COLUMN IF NOT EXISTS chain_id TEXT;

-- Add index for faster lookups by chain_id
CREATE INDEX IF NOT EXISTS idx_holdings_chain_id ON holdings(chain_id);

-- Comment explaining the column
COMMENT ON COLUMN holdings.chain_id IS 'Blockchain network identifier (e.g., solana, eth, base) - used for fetching prices of viral coins from GeckoTerminal API';
