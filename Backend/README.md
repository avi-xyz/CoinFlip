# CoinFlip Backend

This folder contains all backend-related code for CoinFlip.

## Structure

- `migrations/` - SQL migration files for database schema changes
- `seed/` - SQL files for seeding test/demo data
- `functions/` - Supabase Edge Functions (serverless functions)
- `scripts/` - Utility scripts for deployment and management

## Migrations

Migrations are numbered sequentially:
- `001_initial_schema.sql` - Initial database setup
- `002_add_indexes.sql` - Performance indexes
- etc.

See `migrations/README.md` for migration guidelines.

## Development

All backend code is managed through Supabase:
- **Database:** PostgreSQL via Supabase
- **Auth:** Supabase Auth
- **Storage:** Supabase Storage (if needed)
- **Functions:** Supabase Edge Functions

## Technology Stack

- **Backend Platform:** Supabase
- **Database:** PostgreSQL 15+
- **Auth:** Supabase Auth (supports email/password, OAuth, Passkey)
- **API:** Auto-generated REST API via PostgREST
- **Real-time:** WebSocket subscriptions via Supabase Realtime

## Setup

See main project README and Documentation folder for setup instructions.

## Sprints

This backend was developed across multiple sprints:
- **Sprint 11:** Backend foundation, database schema, service layer
- **Sprint 12:** Authentication and user management
- **Sprint 13:** Real-time crypto price integration
- **Sprint 14:** Portfolio persistence
- **Sprint 15:** Settings and preferences
- **Sprint 16:** Leaderboard backend
- **Sprint 17:** Caching and offline support
- **Sprint 18:** Production polish

See `Documentation/Backend-Implementation-Plan.md` for complete details.
