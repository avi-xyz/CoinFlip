-- Migration: 001 - Initial Schema
-- Created: 2026-01-10
-- Sprint: 11
-- Purpose: Create core database tables for CoinFlip app
--   - users: User profiles and stats
--   - portfolios: User portfolios with cash balance
--   - holdings: Cryptocurrency holdings per portfolio
--   - transactions: Buy/sell transaction history

BEGIN;

-- ============================================================================
-- Enable UUID extension
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- USERS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Supabase Auth Integration
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- User Profile
    username TEXT NOT NULL UNIQUE,
    avatar_emoji TEXT NOT NULL DEFAULT '🚀',

    -- Portfolio Settings
    starting_balance DECIMAL(15, 2) NOT NULL DEFAULT 1000.00,

    -- Stats & Achievements
    highest_net_worth DECIMAL(15, 2) NOT NULL DEFAULT 1000.00,
    current_streak INTEGER NOT NULL DEFAULT 0,
    best_streak INTEGER NOT NULL DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
    CONSTRAINT starting_balance_positive CHECK (starting_balance > 0),
    CONSTRAINT highest_net_worth_positive CHECK (highest_net_worth >= 0),
    CONSTRAINT streak_non_negative CHECK (current_streak >= 0 AND best_streak >= 0)
);

-- Indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at DESC);

-- ============================================================================
-- PORTFOLIOS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS portfolios (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Foreign Keys
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Portfolio Data
    cash_balance DECIMAL(15, 2) NOT NULL DEFAULT 1000.00,
    starting_balance DECIMAL(15, 2) NOT NULL DEFAULT 1000.00,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT cash_balance_non_negative CHECK (cash_balance >= 0),
    CONSTRAINT starting_balance_positive CHECK (starting_balance > 0),
    CONSTRAINT one_portfolio_per_user UNIQUE (user_id)
);

-- Indexes for portfolios table
CREATE INDEX IF NOT EXISTS idx_portfolios_user_id ON portfolios(user_id);

-- ============================================================================
-- HOLDINGS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS holdings (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Foreign Keys
    portfolio_id UUID NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,

    -- Coin Information (denormalized for performance)
    coin_id TEXT NOT NULL,
    coin_symbol TEXT NOT NULL,
    coin_name TEXT NOT NULL,
    coin_image TEXT,

    -- Holding Data
    quantity DECIMAL(20, 8) NOT NULL,
    average_buy_price DECIMAL(15, 2) NOT NULL,

    -- Timestamps
    first_purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    CONSTRAINT average_buy_price_positive CHECK (average_buy_price > 0),
    CONSTRAINT unique_coin_per_portfolio UNIQUE (portfolio_id, coin_id)
);

-- Indexes for holdings table
CREATE INDEX IF NOT EXISTS idx_holdings_portfolio_id ON holdings(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_holdings_coin_id ON holdings(coin_id);
CREATE INDEX IF NOT EXISTS idx_holdings_first_purchase_date ON holdings(first_purchase_date DESC);

-- ============================================================================
-- TRANSACTIONS TABLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS transactions (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Foreign Keys
    portfolio_id UUID NOT NULL REFERENCES portfolios(id) ON DELETE CASCADE,

    -- Coin Information (denormalized for immutability)
    coin_id TEXT NOT NULL,
    coin_symbol TEXT NOT NULL,

    -- Transaction Data
    type TEXT NOT NULL CHECK (type IN ('buy', 'sell')),
    quantity DECIMAL(20, 8) NOT NULL,
    price_per_coin DECIMAL(15, 2) NOT NULL,
    total_value DECIMAL(15, 2) NOT NULL,

    -- Timestamp
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT quantity_positive CHECK (quantity > 0),
    CONSTRAINT price_per_coin_positive CHECK (price_per_coin > 0),
    CONSTRAINT total_value_positive CHECK (total_value > 0)
);

-- Indexes for transactions table
CREATE INDEX IF NOT EXISTS idx_transactions_portfolio_id ON transactions(portfolio_id);
CREATE INDEX IF NOT EXISTS idx_transactions_coin_id ON transactions(coin_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_timestamp ON transactions(timestamp DESC);

-- ============================================================================
-- TRIGGER FUNCTION: updated_at timestamp
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_portfolios_updated_at
    BEFORE UPDATE ON portfolios
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_holdings_updated_at
    BEFORE UPDATE ON holdings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolios ENABLE ROW LEVEL SECURITY;
ALTER TABLE holdings ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = auth_user_id);

-- Users can insert their own profile (on first login)
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = auth_user_id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = auth_user_id)
    WITH CHECK (auth.uid() = auth_user_id);

-- Users can view all users for leaderboard (read-only)
CREATE POLICY "Users can view all profiles for leaderboard"
    ON users FOR SELECT
    USING (true);

-- ============================================================================
-- PORTFOLIOS TABLE POLICIES
-- ============================================================================

-- Users can view their own portfolio
CREATE POLICY "Users can view own portfolio"
    ON portfolios FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = portfolios.user_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can insert their own portfolio
CREATE POLICY "Users can insert own portfolio"
    ON portfolios FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = portfolios.user_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can update their own portfolio
CREATE POLICY "Users can update own portfolio"
    ON portfolios FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = portfolios.user_id
            AND users.auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE users.id = portfolios.user_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- ============================================================================
-- HOLDINGS TABLE POLICIES
-- ============================================================================

-- Users can view their own holdings
CREATE POLICY "Users can view own holdings"
    ON holdings FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = holdings.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can insert holdings to their own portfolio
CREATE POLICY "Users can insert own holdings"
    ON holdings FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = holdings.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can update their own holdings
CREATE POLICY "Users can update own holdings"
    ON holdings FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = holdings.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = holdings.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can delete their own holdings
CREATE POLICY "Users can delete own holdings"
    ON holdings FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = holdings.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- ============================================================================
-- TRANSACTIONS TABLE POLICIES
-- ============================================================================

-- Users can view their own transactions
CREATE POLICY "Users can view own transactions"
    ON transactions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = transactions.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Users can insert transactions to their own portfolio
CREATE POLICY "Users can insert own transactions"
    ON transactions FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM portfolios
            JOIN users ON users.id = portfolios.user_id
            WHERE portfolios.id = transactions.portfolio_id
            AND users.auth_user_id = auth.uid()
        )
    );

-- Transactions are immutable (no update or delete)
-- Users should not be able to edit or delete transaction history

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to calculate user's total portfolio value
-- (Will be used in leaderboard queries)
CREATE OR REPLACE FUNCTION calculate_portfolio_value(p_portfolio_id UUID, p_coin_prices JSONB)
RETURNS DECIMAL AS $$
DECLARE
    v_cash_balance DECIMAL;
    v_holdings_value DECIMAL;
BEGIN
    -- Get cash balance
    SELECT cash_balance INTO v_cash_balance
    FROM portfolios
    WHERE id = p_portfolio_id;

    -- Calculate holdings value
    -- Note: This is a placeholder - actual implementation will need real-time prices
    v_holdings_value := 0;

    RETURN COALESCE(v_cash_balance, 0) + COALESCE(v_holdings_value, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Tables created: users, portfolios, holdings, transactions
-- Indexes created: All foreign keys and query-optimized fields
-- RLS enabled: All tables have row-level security
-- Triggers created: updated_at auto-update
-- Helper functions: calculate_portfolio_value
--
-- Next steps:
-- 1. Execute this migration in Supabase SQL Editor
-- 2. Verify tables in Supabase Table Editor
-- 3. Update Swift models to include new fields (auth_user_id, portfolio_id, etc.)
-- ============================================================================
