# Leaderboard Net Worth Accuracy - Deployment Guide

## Problem Solved

Previously, the leaderboard calculated net worth using `average_buy_price` (purchase price), which made rankings inaccurate for users with gains or losses. For example:

- User buys USOR at $0.02 (18,490 coins)
- Current price: $0.03
- **App shows**: $554.70 net worth ✅
- **Leaderboard showed**: $369.80 net worth ❌ (wrong!)

This made leaderboard rankings unfair, especially for volatile viral coins.

## Solution

Implemented a **1-hour periodic background job** that:
1. Fetches current market prices for all coins (CoinGecko API)
2. Calculates accurate net worth for ALL users: `cash_balance + SUM(quantity * current_price)`
3. Stores results in `portfolios.net_worth` column
4. Updates every 1 hour (well within API rate limits)

### Why 1-Hour?

- **API Usage**: Only 2,880 calls/month (30% of free tier)
- **Cost**: Pennies per month (negligible)
- **Accuracy**: Max 1 hour stale (critical for volatile coins)
- **Scalability**: Works for 100K+ users
- **UX**: Leaderboard feels "live"

## Deployment Steps

### 1. Run Database Migrations

Run these migrations in order on your Supabase SQL editor:

```bash
# First, add net_worth columns
psql -f Backend/migrations/004_add_networth_columns.sql

# Then, update leaderboard functions
psql -f Backend/migrations/005_update_leaderboard_to_use_networth.sql
```

**Via Supabase Dashboard:**
1. Go to **SQL Editor** → **New Query**
2. Copy contents of `004_add_networth_columns.sql`
3. Click **Run**
4. Repeat for `005_update_leaderboard_to_use_networth.sql`

### 2. Deploy Edge Function

```bash
# Navigate to your Supabase project
cd Backend

# Deploy the Edge Function
supabase functions deploy recalculate-networth

# Set environment variables (if not already set)
supabase secrets set SUPABASE_URL=your-project-url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

### 3. Schedule the Cron Job

**Via Supabase Dashboard:**

1. Go to **Edge Functions** → `recalculate-networth`
2. Click **Settings** → **Cron Schedules**
3. Add new schedule:
   - **Cron Expression**: `0 * * * *` (every hour)
   - **HTTP Method**: POST
   - **Timezone**: UTC

**Or via Supabase CLI:**

```bash
supabase functions schedule recalculate-networth --cron "0 * * * *"
```

### 4. Manual Test Run

Test the function manually before enabling the cron:

```bash
# Test locally
supabase functions serve recalculate-networth

# In another terminal, trigger it
curl -X POST http://localhost:54321/functions/v1/recalculate-networth \
  -H "Authorization: Bearer YOUR_ANON_KEY"

# Or test deployed version
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/recalculate-networth \
  -H "Authorization: Bearer YOUR_ANON_KEY"
```

**Expected Response:**

```json
{
  "success": true,
  "portfolios_updated": 150,
  "portfolios_total": 150,
  "unique_coins": 45,
  "prices_fetched": 45,
  "duration_ms": 3421
}
```

### 5. Monitor Function Logs

```bash
# View real-time logs
supabase functions logs recalculate-networth --follow

# Check for errors
supabase functions logs recalculate-networth --level error
```

## Verification Steps

### 1. Check Database

```sql
-- Verify net_worth column exists and has data
SELECT id, cash_balance, net_worth, gain_percentage, last_networth_update
FROM portfolios
LIMIT 10;

-- Check that net_worth is different from cash_balance (means holdings are calculated)
SELECT COUNT(*)
FROM portfolios
WHERE net_worth != cash_balance;
```

### 2. Test Leaderboard Query

```sql
-- Test the updated leaderboard function
SELECT * FROM get_leaderboard(10);

-- Verify it uses net_worth (not average_buy_price)
EXPLAIN ANALYZE SELECT * FROM get_leaderboard(50);
```

### 3. Compare App vs Leaderboard

1. Open app, note your net worth on Home screen
2. View Leaderboard, check your rank and net worth
3. **They should match** (within 1 hour of last update)

### 4. Test After Buy/Sell

1. Buy a coin in the app
2. Wait for next hourly job run (check `last_networth_update`)
3. Refresh leaderboard
4. Net worth should reflect the purchase

## Rollback Plan

If something goes wrong:

```sql
-- Rollback migration 005 (revert to old leaderboard logic)
-- This will restore the old calculation using average_buy_price

-- Copy contents of 002_leaderboard_function.sql and re-run
-- Then drop the new columns if needed:
ALTER TABLE portfolios DROP COLUMN IF EXISTS net_worth;
ALTER TABLE portfolios DROP COLUMN IF EXISTS gain_percentage;
ALTER TABLE portfolios DROP COLUMN IF EXISTS last_networth_update;
```

## Monitoring & Maintenance

### Expected Metrics (10,000 users)

- **Function duration**: 2-5 seconds
- **API calls per run**: 4-8 (batched)
- **Database updates**: 10,000 rows
- **Runs per day**: 24
- **Total monthly API calls**: ~2,880
- **Monthly cost**: < $0.50

### Alerts to Set Up

1. **Function failures**: Get notified if job fails 3 times in a row
2. **Stale data**: Alert if `last_networth_update` is > 2 hours old
3. **API rate limits**: Monitor CoinGecko API response codes (429 = rate limited)

### Troubleshooting

**Issue: Function times out**
- Increase function timeout in Supabase settings (default 60s → 120s)
- Batch updates in smaller chunks (reduce `updateBatchSize`)

**Issue: API rate limited (HTTP 429)**
- Increase delay between batch requests
- Consider upgrading to CoinGecko Pro tier

**Issue: Net worth stuck at $0**
- Check function logs for errors
- Manually trigger function to backfill
- Verify CoinGecko API key is valid

**Issue: Leaderboard still shows old values**
- Clear app cache
- Verify migration 005 was applied (check function definition)
- Check `last_networth_update` timestamp

## Performance Optimization

### For 100K+ Users

If you scale beyond 100K users:

1. **Parallel batch updates** - Use Supabase batch upsert
2. **Incremental updates** - Only update portfolios with changes
3. **Cache prices** - Store in `coin_prices` table, reuse across users
4. **Horizontal scaling** - Split users into shards, process in parallel

### For High-Frequency Trading

If users make 100+ trades/day:

1. **Real-time updates** - Update net_worth on every buy/sell
2. **Webhook triggers** - React to portfolio changes immediately
3. **Redis cache** - Store live prices in Redis for instant lookups

## Next Steps

After successful deployment:

1. ✅ Run migrations
2. ✅ Deploy Edge Function
3. ✅ Schedule cron job
4. ✅ Monitor first few runs
5. ✅ Verify accuracy in app
6. 📊 Set up monitoring alerts
7. 📈 Track API usage and costs

## Questions?

- Check Edge Function logs: `supabase functions logs recalculate-networth`
- Test manually: `curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/recalculate-networth`
- Review migration status: `SELECT * FROM portfolios WHERE last_networth_update IS NULL;`
