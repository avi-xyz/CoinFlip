-- Migration: 002_leaderboard_function
-- Description: Create SQL function to calculate leaderboard rankings
-- Sprint: 16
-- Date: 2026-01-13

-- Create leaderboard function that calculates user rankings based on net worth
CREATE OR REPLACE FUNCTION get_leaderboard(limit_count INT DEFAULT 50)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_emoji TEXT,
  net_worth DECIMAL,
  gain_percentage DECIMAL,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH user_portfolio_values AS (
    SELECT
      u.id as user_id,
      u.username,
      u.avatar_emoji,
      p.id as portfolio_id,
      p.cash_balance,
      p.starting_balance,
      -- Calculate total holdings value (sum of quantity * average_buy_price for all holdings)
      COALESCE(SUM(h.quantity * h.average_buy_price), 0) as holdings_value
    FROM users u
    JOIN portfolios p ON u.id = p.user_id
    LEFT JOIN holdings h ON p.id = h.portfolio_id
    GROUP BY u.id, u.username, u.avatar_emoji, p.id, p.cash_balance, p.starting_balance
  )
  SELECT
    upv.user_id,
    upv.username,
    upv.avatar_emoji,
    -- Net worth = cash + holdings value
    (upv.cash_balance + upv.holdings_value)::DECIMAL as net_worth,
    -- Gain percentage = ((current - starting) / starting) * 100
    (((upv.cash_balance + upv.holdings_value - upv.starting_balance) / NULLIF(upv.starting_balance, 0)) * 100)::DECIMAL as gain_percentage,
    -- Rank users by net worth (highest first)
    ROW_NUMBER() OVER (ORDER BY (upv.cash_balance + upv.holdings_value) DESC) as rank
  FROM user_portfolio_values upv
  ORDER BY rank
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Create function to get a specific user's rank
CREATE OR REPLACE FUNCTION get_user_rank(input_user_id UUID)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_emoji TEXT,
  net_worth DECIMAL,
  gain_percentage DECIMAL,
  rank BIGINT
) AS $$
BEGIN
  RETURN QUERY
  WITH user_portfolio_values AS (
    SELECT
      u.id as user_id,
      u.username,
      u.avatar_emoji,
      p.id as portfolio_id,
      p.cash_balance,
      p.starting_balance,
      COALESCE(SUM(h.quantity * h.average_buy_price), 0) as holdings_value
    FROM users u
    JOIN portfolios p ON u.id = p.user_id
    LEFT JOIN holdings h ON p.id = h.portfolio_id
    GROUP BY u.id, u.username, u.avatar_emoji, p.id, p.cash_balance, p.starting_balance
  ),
  ranked_users AS (
    SELECT
      upv.user_id,
      upv.username,
      upv.avatar_emoji,
      (upv.cash_balance + upv.holdings_value)::DECIMAL as net_worth,
      (((upv.cash_balance + upv.holdings_value - upv.starting_balance) / NULLIF(upv.starting_balance, 0)) * 100)::DECIMAL as gain_percentage,
      ROW_NUMBER() OVER (ORDER BY (upv.cash_balance + upv.holdings_value) DESC) as rank
    FROM user_portfolio_values upv
  )
  SELECT * FROM ranked_users WHERE ranked_users.user_id = input_user_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permissions on the functions
GRANT EXECUTE ON FUNCTION get_leaderboard(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_rank(UUID) TO authenticated;

-- Add RLS policies for leaderboard access
-- Users can view the leaderboard (read-only)
-- No special policy needed as functions are already restricted to authenticated users
