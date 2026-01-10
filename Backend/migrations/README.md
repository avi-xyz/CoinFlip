# Database Migrations

## Overview

This folder contains SQL migration files for the CoinFlip database schema. Each migration is applied sequentially in Supabase.

## Naming Convention

`XXX_description.sql`

- **XXX** = Sequential number (001, 002, 003, etc.)
- **description** = snake_case brief description

### Examples
- `001_initial_schema.sql`
- `002_add_user_indexes.sql`
- `003_add_leaderboard_function.sql`

## How to Create a Migration

1. **Create new file** in this folder: `00X_your_change.sql`
2. **Write SQL** (forward migration only - no rollback needed)
3. **Test locally** in Supabase SQL Editor
4. **Document the change** in the Migration History section below
5. **Commit** with your related iOS code changes

## How to Apply a Migration

### Via Supabase Dashboard (Recommended)

1. Open [Supabase Dashboard](https://supabase.com/dashboard) → Your Project
2. Navigate to **SQL Editor**
3. Copy contents of migration file
4. Click **Run** to execute
5. Verify changes in **Table Editor**

### Via Supabase CLI (Advanced)

```bash
# Install Supabase CLI
npm install -g supabase

# Link to your project
supabase link --project-ref your-project-ref

# Run migration
supabase db push
```

## Migration Best Practices

### ✅ Do:
- Use transactions for complex migrations
- Add `IF NOT EXISTS` for idempotent operations
- Include comments explaining the "why"
- Test migrations on dev environment first
- Keep migrations small and focused

### ❌ Don't:
- Don't modify existing migration files after they're applied
- Don't delete applied migrations
- Don't include data changes in schema migrations (use seed files)
- Don't forget to add indexes for foreign keys

## Migration Template

```sql
-- Migration: XXX - Description
-- Created: YYYY-MM-DD
-- Sprint: XX
-- Purpose: Brief explanation of why this change is needed

BEGIN;

-- Your SQL here
CREATE TABLE IF NOT EXISTS example (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_example_name ON example(name);

-- Add RLS policies
ALTER TABLE example ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own records"
  ON example FOR SELECT
  USING (auth.uid() = user_id);

COMMIT;
```

## Migration History

### Sprint 11: Backend Foundation

#### 001_initial_schema.sql
**Date:** TBD (Sprint 11, Task 11.2)
**Description:** Initial database setup
**Changes:**
- Created `users` table
- Created `portfolios` table
- Created `holdings` table
- Created `transactions` table
- Set up Row Level Security policies for all tables
- Added indexes for foreign keys
- Created `updated_at` trigger function

---

## Rollback Strategy

Since Supabase doesn't have native rollback, if you need to undo a migration:

1. **Create a new migration** that reverses the changes
2. **Name it:** `00X_rollback_YYY.sql` (where YYY is the migration you're rolling back)
3. **Document** what you're rolling back and why

Example:
```sql
-- Migration: 005 - Rollback: Remove favorites table
-- This rolls back migration 004

DROP TABLE IF EXISTS favorites;
```

## Troubleshooting

### Migration fails with "permission denied"
- Check RLS policies aren't blocking admin operations
- Run as superuser or disable RLS temporarily

### Migration creates duplicate items
- Use `IF NOT EXISTS` clauses
- Check if migration was already applied

### Changes don't appear in app
- Verify Swift models match database schema
- Check CodingKeys match column names (snake_case)
- Restart app to reload schema

## Resources

- [Supabase SQL Editor](https://supabase.com/docs/guides/database/sql-editor)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
