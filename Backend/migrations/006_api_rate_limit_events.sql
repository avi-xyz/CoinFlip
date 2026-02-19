-- Migration: 006 - API Rate Limit Events Table
-- Created: 2026-01-31
-- Purpose: Create table to track API rate limit events for production monitoring
--   - Logs rate limit hits from CoinGecko and GeckoTerminal APIs
--   - Enables monitoring and alerting for API usage issues

BEGIN;

-- ============================================================================
-- API_RATE_LIMIT_EVENTS TABLE
-- ============================================================================
-- This table stores rate limit events from external APIs
-- Used for monitoring and alerting in production

CREATE TABLE IF NOT EXISTS api_rate_limit_events (
    -- Primary Key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Event Data
    api_name TEXT NOT NULL,                           -- 'CoinGecko' or 'GeckoTerminal'
    endpoint TEXT NOT NULL,                           -- The specific endpoint that was rate limited
    call_count INTEGER NOT NULL DEFAULT 0,            -- Total API calls in the session when rate limit was hit
    session_duration_seconds INTEGER NOT NULL DEFAULT 0, -- Duration of the session in seconds
    calls_per_minute DECIMAL(10, 2) NOT NULL DEFAULT 0,  -- Calculated calls per minute

    -- Device & App Info
    device_model TEXT,                                -- Device identifier (e.g., 'iPhone14,3')
    app_version TEXT,                                 -- App version (e.g., '1.3.0 (42)')

    -- Timestamp
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_api_name CHECK (api_name IN ('CoinGecko', 'GeckoTerminal')),
    CONSTRAINT call_count_non_negative CHECK (call_count >= 0),
    CONSTRAINT session_duration_non_negative CHECK (session_duration_seconds >= 0)
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_rate_limit_events_api_name ON api_rate_limit_events(api_name);
CREATE INDEX IF NOT EXISTS idx_rate_limit_events_timestamp ON api_rate_limit_events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_rate_limit_events_created_at ON api_rate_limit_events(created_at DESC);

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
-- Note: This table uses service role for inserts (no user context)
-- We only enable RLS but allow authenticated users to insert

ALTER TABLE api_rate_limit_events ENABLE ROW LEVEL SECURITY;

-- Allow any authenticated user to insert rate limit events
-- (These are anonymous app telemetry events, not user-specific data)
CREATE POLICY "Authenticated users can insert rate limit events"
    ON api_rate_limit_events FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Only service role can read events (for admin dashboard)
-- Regular users should not be able to read other users' rate limit events
CREATE POLICY "Service role can read all rate limit events"
    ON api_rate_limit_events FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

COMMIT;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
-- Table created: api_rate_limit_events
-- Indexes created: api_name, timestamp, created_at
-- RLS enabled: Insert for authenticated users, select for service role
--
-- Usage in app:
-- The APIRateLimitLogger service automatically logs rate limit events
-- when they occur in CryptoAPIService or GeckoTerminalService
--
-- Query examples for monitoring:
--
-- Count rate limits by API in last 24 hours:
-- SELECT api_name, COUNT(*)
-- FROM api_rate_limit_events
-- WHERE timestamp > NOW() - INTERVAL '24 hours'
-- GROUP BY api_name;
--
-- Average calls per minute when rate limit hits:
-- SELECT api_name, AVG(calls_per_minute) as avg_calls_per_min
-- FROM api_rate_limit_events
-- WHERE timestamp > NOW() - INTERVAL '7 days'
-- GROUP BY api_name;
--
-- Rate limits by app version:
-- SELECT app_version, COUNT(*)
-- FROM api_rate_limit_events
-- WHERE timestamp > NOW() - INTERVAL '7 days'
-- GROUP BY app_version
-- ORDER BY COUNT(*) DESC;
-- ============================================================================
