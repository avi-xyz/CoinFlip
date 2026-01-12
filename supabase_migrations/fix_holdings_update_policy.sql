-- Fix holdings UPDATE policy to allow updates

-- Drop existing UPDATE policy
DROP POLICY IF EXISTS "Users can update own holdings" ON holdings;

-- Create new UPDATE policy with both USING and WITH CHECK
CREATE POLICY "Users can update own holdings"
ON holdings
FOR UPDATE
USING (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
)
WITH CHECK (
  portfolio_id IN (
    SELECT id FROM portfolios WHERE user_id IN (
      SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
  )
);
