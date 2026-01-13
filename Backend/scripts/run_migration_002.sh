#!/bin/bash
# Script to run migration 002_leaderboard_function.sql in Supabase
# Sprint 16 - Leaderboard Backend

echo "📋 Migration 002: Leaderboard Functions"
echo "======================================="
echo ""
echo "This migration creates two PostgreSQL functions:"
echo "  1. get_leaderboard(limit) - Fetch top users by net worth"
echo "  2. get_user_rank(user_id) - Fetch specific user's rank"
echo ""
echo "To run this migration:"
echo ""
echo "Option 1: Supabase Dashboard (Recommended)"
echo "  1. Go to https://supabase.com/dashboard"
echo "  2. Select your project"
echo "  3. Go to 'SQL Editor'"
echo "  4. Click 'New Query'"
echo "  5. Copy the contents of Backend/migrations/002_leaderboard_function.sql"
echo "  6. Paste into the editor and click 'Run'"
echo ""
echo "Option 2: Supabase CLI"
echo "  supabase db push"
echo ""
echo "✅ After running the migration, the leaderboard will show real data!"
echo ""

# Read the migration file and display it
echo "Migration SQL:"
echo "=============="
cat "$(dirname "$0")/../migrations/002_leaderboard_function.sql"
