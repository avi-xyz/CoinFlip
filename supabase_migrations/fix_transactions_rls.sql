-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON transactions;

DROP POLICY IF EXISTS "Users can view own holdings" ON holdings;
DROP POLICY IF EXISTS "Users can insert own holdings" ON holdings;
DROP POLICY IF EXISTS "Users can update own holdings" ON holdings;
DROP POLICY IF EXISTS "Users can delete own holdings" ON holdings;

-- Enable RLS on transactions table
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own transactions
CREATE POLICY "Users can view own transactions"
ON transactions
FOR SELECT
USING (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);

-- Policy: Users can insert their own transactions
CREATE POLICY "Users can insert own transactions"
ON transactions
FOR INSERT
WITH CHECK (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);

-- Enable RLS on holdings table
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own holdings
CREATE POLICY "Users can view own holdings"
ON holdings
FOR SELECT
USING (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);

-- Policy: Users can insert their own holdings
CREATE POLICY "Users can insert own holdings"
ON holdings
FOR INSERT
WITH CHECK (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);

-- Policy: Users can update their own holdings
CREATE POLICY "Users can update own holdings"
ON holdings
FOR UPDATE
USING (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);

-- Policy: Users can delete their own holdings
CREATE POLICY "Users can delete own holdings"
ON holdings
FOR DELETE
USING (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);
