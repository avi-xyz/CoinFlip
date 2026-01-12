-- Fix price_per_coin constraint to allow very small prices (for meme coins)

-- Drop the existing constraint
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS price_per_coin_positive;

-- Add a new constraint that allows any positive number (including very small decimals)
ALTER TABLE transactions ADD CONSTRAINT price_per_coin_positive CHECK (price_per_coin > 0::numeric);

-- Also check if there's a similar constraint on total_value
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS total_value_positive;
ALTER TABLE transactions ADD CONSTRAINT total_value_positive CHECK (total_value > 0::numeric);

-- Check quantity constraint too
ALTER TABLE transactions DROP CONSTRAINT IF EXISTS quantity_positive;
ALTER TABLE transactions ADD CONSTRAINT quantity_positive CHECK (quantity > 0::numeric);
