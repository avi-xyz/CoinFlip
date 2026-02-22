-- Migration: 008 - Analytics Events Table
-- Created: 2026-02-21
-- Purpose: Track app usage, errors, and performance metrics

BEGIN;

-- ============================================================================
-- ANALYTICS EVENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Event identification
    event_type TEXT NOT NULL,           -- 'app_open', 'screen_view', 'trade', 'error', 'rate_limit', etc.
    event_name TEXT NOT NULL,           -- Specific event name

    -- User context (optional - for anonymous tracking)
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id TEXT,                    -- Client-generated session ID
    device_id TEXT,                     -- Anonymous device identifier

    -- Event data
    properties JSONB DEFAULT '{}',      -- Flexible event properties

    -- Device/App info
    app_version TEXT,
    os_version TEXT,
    device_model TEXT,

    -- Timestamps
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient querying
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_timestamp ON analytics_events(timestamp DESC);
CREATE INDEX idx_analytics_events_user ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_session ON analytics_events(session_id);
CREATE INDEX idx_analytics_events_type_timestamp ON analytics_events(event_type, timestamp DESC);

-- ============================================================================
-- APP SESSIONS TABLE (for DAU/MAU tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS app_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    session_id TEXT NOT NULL,
    device_id TEXT,

    -- Session timing
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    duration_seconds INTEGER,

    -- Session info
    app_version TEXT,
    os_version TEXT,
    device_model TEXT,

    -- Activity counts
    screens_viewed INTEGER DEFAULT 0,
    trades_made INTEGER DEFAULT 0,
    errors_encountered INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_app_sessions_user ON app_sessions(user_id);
CREATE INDEX idx_app_sessions_started ON app_sessions(started_at DESC);
CREATE INDEX idx_app_sessions_device ON app_sessions(device_id);

-- ============================================================================
-- DAILY METRICS TABLE (aggregated for fast dashboard queries)
-- ============================================================================

CREATE TABLE IF NOT EXISTS daily_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    date DATE NOT NULL UNIQUE,

    -- User metrics
    daily_active_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    total_sessions INTEGER DEFAULT 0,

    -- Trade metrics
    total_buys INTEGER DEFAULT 0,
    total_sells INTEGER DEFAULT 0,
    total_trade_volume DECIMAL(20, 2) DEFAULT 0,

    -- Error metrics
    total_errors INTEGER DEFAULT 0,
    rate_limit_events INTEGER DEFAULT 0,

    -- Engagement
    avg_session_duration_seconds INTEGER DEFAULT 0,
    screens_per_session DECIMAL(5, 2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_daily_metrics_date ON daily_metrics(date DESC);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Analytics events - insert only for authenticated users, no read
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert analytics events"
    ON analytics_events FOR INSERT
    WITH CHECK (true);  -- Allow all inserts (we want to track even anonymous events)

-- App sessions - users can only see their own
ALTER TABLE app_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert sessions"
    ON app_sessions FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Users can update their sessions"
    ON app_sessions FOR UPDATE
    USING (user_id = auth.uid() OR user_id IS NULL);

-- Daily metrics - read only (populated by cron job)
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;

-- No user access to daily_metrics - only service role

-- ============================================================================
-- FUNCTION: Aggregate daily metrics (called by cron job)
-- ============================================================================

CREATE OR REPLACE FUNCTION aggregate_daily_metrics(target_date DATE DEFAULT CURRENT_DATE - INTERVAL '1 day')
RETURNS void AS $$
DECLARE
    dau_count INTEGER;
    new_users_count INTEGER;
    sessions_count INTEGER;
    buys_count INTEGER;
    sells_count INTEGER;
    trade_vol DECIMAL(20, 2);
    errors_count INTEGER;
    rate_limits_count INTEGER;
    avg_duration INTEGER;
    avg_screens DECIMAL(5, 2);
BEGIN
    -- Count daily active users (unique users with sessions)
    SELECT COUNT(DISTINCT user_id) INTO dau_count
    FROM app_sessions
    WHERE DATE(started_at) = target_date AND user_id IS NOT NULL;

    -- Count new users
    SELECT COUNT(*) INTO new_users_count
    FROM users
    WHERE DATE(created_at) = target_date;

    -- Count sessions
    SELECT COUNT(*) INTO sessions_count
    FROM app_sessions
    WHERE DATE(started_at) = target_date;

    -- Count trades
    SELECT
        COUNT(*) FILTER (WHERE event_name = 'buy_success'),
        COUNT(*) FILTER (WHERE event_name = 'sell_success')
    INTO buys_count, sells_count
    FROM analytics_events
    WHERE DATE(timestamp) = target_date AND event_type = 'trade';

    -- Trade volume
    SELECT COALESCE(SUM((properties->>'amount')::DECIMAL), 0) INTO trade_vol
    FROM analytics_events
    WHERE DATE(timestamp) = target_date
      AND event_type = 'trade'
      AND event_name IN ('buy_success', 'sell_success');

    -- Errors
    SELECT COUNT(*) INTO errors_count
    FROM analytics_events
    WHERE DATE(timestamp) = target_date AND event_type = 'error';

    -- Rate limit events
    SELECT COUNT(*) INTO rate_limits_count
    FROM api_rate_limit_events
    WHERE DATE(timestamp) = target_date;

    -- Average session duration
    SELECT COALESCE(AVG(duration_seconds), 0)::INTEGER INTO avg_duration
    FROM app_sessions
    WHERE DATE(started_at) = target_date AND duration_seconds IS NOT NULL;

    -- Average screens per session
    SELECT COALESCE(AVG(screens_viewed), 0)::DECIMAL(5,2) INTO avg_screens
    FROM app_sessions
    WHERE DATE(started_at) = target_date;

    -- Upsert daily metrics
    INSERT INTO daily_metrics (
        date, daily_active_users, new_users, total_sessions,
        total_buys, total_sells, total_trade_volume,
        total_errors, rate_limit_events,
        avg_session_duration_seconds, screens_per_session,
        updated_at
    ) VALUES (
        target_date, dau_count, new_users_count, sessions_count,
        buys_count, sells_count, trade_vol,
        errors_count, rate_limits_count,
        avg_duration, avg_screens,
        NOW()
    )
    ON CONFLICT (date) DO UPDATE SET
        daily_active_users = EXCLUDED.daily_active_users,
        new_users = EXCLUDED.new_users,
        total_sessions = EXCLUDED.total_sessions,
        total_buys = EXCLUDED.total_buys,
        total_sells = EXCLUDED.total_sells,
        total_trade_volume = EXCLUDED.total_trade_volume,
        total_errors = EXCLUDED.total_errors,
        rate_limit_events = EXCLUDED.rate_limit_events,
        avg_session_duration_seconds = EXCLUDED.avg_session_duration_seconds,
        screens_per_session = EXCLUDED.screens_per_session,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'analytics_events' as table_name, COUNT(*) as rows FROM analytics_events
UNION ALL
SELECT 'app_sessions', COUNT(*) FROM app_sessions
UNION ALL
SELECT 'daily_metrics', COUNT(*) FROM daily_metrics;
