-- Migration: Update leaderboard functions to use net_worth column
-- Purpose: Use pre-calculated net_worth instead of average_buy_price
-- Depends on: 004_add_networth_columns.sql
--
-- Context: Previously calculated net worth using average_buy_price which was
-- inaccurate for users with gains/losses. Now we use the net_worth column
-- that's updated hourly by the background job with current market prices.

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
  SELECT
    u.id as user_id,
    u.username,
    u.avatar_emoji,
    -- Use pre-calculated net_worth from portfolios table
    p.net_worth,
    -- Use pre-calculated gain_percentage from portfolios table
    p.gain_percentage,
    -- Rank users by net worth (highest first)
    ROW_NUMBER() OVER (ORDER BY p.net_worth DESC, p.last_networth_update DESC) as rank
  FROM users u
  JOIN portfolios p ON u.id = p.user_id
  ORDER BY rank
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

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
  WITH ranked_users AS (
    SELECT
      u.id as user_id,
      u.username,
      u.avatar_emoji,
      p.net_worth,
      p.gain_percentage,
      ROW_NUMBER() OVER (ORDER BY p.net_worth DESC, p.last_networth_update DESC) as rank
    FROM users u
    JOIN portfolios p ON u.id = p.user_id
  )
  SELECT * FROM ranked_users WHERE ranked_users.user_id = input_user_id;
END;
$$ LANGUAGE plpgsql;

-- Permissions remain the same
GRANT EXECUTE ON FUNCTION get_leaderboard(INT) TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_rank(UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_leaderboard(INT) IS
'Returns top N users by net worth. Net worth is calculated hourly by background job using current market prices.';

COMMENT ON FUNCTION get_user_rank(UUID) IS
'Returns a specific user''s rank and stats. Net worth is calculated hourly by background job using current market prices.';
