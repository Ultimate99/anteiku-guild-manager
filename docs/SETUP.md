# Setup

This guide covers local development only. Production setup is documented in [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

## Prerequisites

- Node.js compatible with Vite 5.
- npm.
- Supabase CLI for local Supabase work.
- A local Supabase stack for development and validation.

## Install

```powershell
npm install
```

## Local Environment

Copy `.env.example` to `.env.local`:

```powershell
copy .env.example .env.local
```

Use local Supabase values for development:

```text
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_ANON_KEY=<local anon key>
```

Only browser-safe Supabase values belong in `.env.local`.

Never add service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, or OAuth secrets to frontend env files.

## Local Supabase

Use local Supabase for development and disposable validation.

Typical local flow:

```powershell
npx.cmd supabase start
npx.cmd supabase db reset
```

`supabase/config.toml` is local-dev oriented. Its `[db.seed]` section references `./seed.sql`, but this repo currently does not include `supabase/seed.sql`. The core production seed data is in the timestamped migration `20260514000400_seed_core_data.sql`, so do not use `db push --include-seed` or seed-dependent production commands until that missing seed-file hazard is deliberately resolved.

## Local Validation Warning

`supabase/tests/local_validation_anteiku.sql` is for local/disposable Supabase only.

Do not run it against production. It inserts fake auth users and test data before rolling back, and production should not depend on fake-user validation scripts.

## Run The App

```powershell
npm run dev
```

The app displays whether Supabase is configured and whether the URL appears local.

## Build

```powershell
npm run build
```

## Avoid Accidental Production Usage

- Keep `.env.local` pointed at local Supabase for development.
- Do not copy production service credentials to local frontend env files.
- Confirm the Supabase URL before running any Supabase CLI command.
- Never run `supabase db reset` against a production project.
- Clear browser localStorage/sessionStorage after local DB resets if auth tests behave strangely; stale local sessions can cause profile foreign-key errors after resets.
