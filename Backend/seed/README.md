# Seed Data

This folder contains SQL files for populating the database with test/demo data.

## Files

- `dev-seed.sql` - Development environment seed data (mock users, portfolios)
- `test-seed.sql` - Test environment seed data (for automated tests)
- `demo-seed.sql` - Demo data for app store screenshots/reviews

## Usage

### Load Seed Data

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of desired seed file
3. Run SQL
4. Verify data in Table Editor

### Dev Seed

Contains:
- 10-20 mock users
- Portfolios with various balances
- Sample holdings
- Transaction history

Use this for local development and testing.

### Test Seed

Contains:
- Minimal data for unit/integration tests
- Predictable data for assertions
- Covers edge cases

Use this for automated testing.

## Creating Seed Files

```sql
-- dev-seed.sql example

-- Insert test users
INSERT INTO users (id, auth_user_id, username, avatar_emoji) VALUES
  ('...', '...', 'testuser1', '🚀'),
  ('...', '...', 'testuser2', '💎');

-- Insert portfolios
INSERT INTO portfolios (id, user_id, cash_balance, starting_balance) VALUES
  ('...', '...', 1500.00, 1000.00);

-- etc.
```

## Best Practices

- Use realistic but fake data
- Don't include sensitive information
- Make data easily identifiable (e.g., usernames like "testuser1")
- Include various scenarios (profit, loss, empty portfolios)
- Keep files under 100KB for quick loading
