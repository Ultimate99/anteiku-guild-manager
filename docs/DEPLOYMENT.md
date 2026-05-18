# Deployment

Vercel is the intended hosting target. Production deployment has not been performed yet.

This document is a runbook for a future approved milestone. Do not deploy, link a production Supabase project, or run production commands without explicit approval.

## Production Supabase Project

Create a fresh Supabase project for production. Keep it separate from local development and any future staging project.

Record before proceeding:

- Supabase organization.
- Production project reference.
- Region.
- Production app domain.
- Production Supabase URL.
- Browser-safe anon or publishable key.

Do not copy service role keys, `sb_secret_*` keys, database URLs, JWT secrets, or SMTP/OAuth secrets into frontend code or Vercel public env.

## Supabase Auth Configuration

Configure Auth in the Supabase dashboard before production smoke testing:

- Site URL: production Vercel/custom domain.
- Redirect URLs: exact production URLs.
- Preview URLs: use a staging Supabase project when possible; avoid broad preview wildcards pointing at production.
- Email signup and email confirmation: decide intentionally before launch.
- Anonymous sign-ins: keep disabled.

The app uses email/password auth through Supabase JS.

## Migration Workflow

Preferred future workflow:

```powershell
supabase login
supabase link
supabase migration list
supabase db push --dry-run
supabase db push
```

Confirm the linked project ref before every remote command.

Migration order:

1. `20260514000100_core_schema.sql`
2. `20260514000200_constraints_indexes.sql`
3. `20260514000300_private_helper_functions.sql`
4. `20260514000400_seed_core_data.sql`
5. `20260514000500_rls_policies.sql`
6. `20260514000600_public_rpc_functions.sql`
7. `20260515000100_member_guild_role_management.sql`
8. `20260515000200_cp_rpc_hardening.sql`
9. `20260515000300_audit_log_read_hardening.sql`

After applying migrations, verify:

- Core tables exist.
- Constraints and indexes exist.
- RLS is enabled.
- Policies exist.
- RPC functions exist.
- Function grants match expectations.
- Core guild seed rows exist.
- Permission catalog rows exist.
- `supabase_migrations.schema_migrations` reflects the expected migration timestamps.

Do not use `db push --include-seed` until the missing `supabase/seed.sql` hazard in `supabase/config.toml` is resolved. The required core seed data is currently handled by migration `20260514000400_seed_core_data.sql`.

## Forbidden Production Commands

Do not run against production:

```powershell
supabase db reset
```

Also forbidden unless separately reviewed and approved:

- Destructive SQL such as broad `drop`, `truncate`, or unsafe `delete`.
- `alter table ... disable row level security`.
- Broad grants that expose CP, audit logs, GvG votes, or admin permissions.
- `supabase/tests/local_validation_anteiku.sql`.
- Any fake-user local validation script.
- Any command that uses service role credentials from frontend or public env.

## Owner Bootstrap

Owner bootstrap remains manual-only.

Use `supabase/templates/owner_bootstrap_TEMPLATE.sql` only after:

- Production migrations are applied.
- A real production Supabase Auth user exists.
- The real `auth.users.id` is known.
- Placeholders are replaced.
- The safety guard is intentionally removed.
- The selected initial guild ID is reviewed.
- The SQL is run in a controlled SQL editor/session.

After bootstrap, verify:

- Owner profile is `approved`.
- Owner has exactly one active primary membership.
- Owner role is `owner`.
- Owner belongs to the intended guild.
- An owner bootstrap audit log exists.
- No UI exposes Owner assignment.

## Vercel Project

Configure Vercel:

- Framework preset: Vite.
- Build command: `npm run build`.
- Output directory: `dist`.
- Install command: default npm install behavior unless intentionally changed.

Required Vercel environment variables:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Only set browser-safe Supabase values. Do not set service role keys or secret keys in frontend env.

## Preview Deployment Caution

Preview deployments can accidentally touch production if they inherit production Supabase env values.

Recommended policy:

- Production Vercel env points to production Supabase.
- Preview Vercel env points to staging Supabase or is left unconfigured.
- Do not allow preview branches to mutate production data unless a separate policy is approved.

## Post-Deployment Validation

After deployment:

- Open production URL.
- Confirm app loads without console errors.
- Sign up a controlled pending user.
- Confirm pending user cannot access member/admin areas.
- Sign in as Owner.
- Confirm AdminPanel access.
- Confirm core guilds render.
- Confirm member CP denial for normal Member.
- Confirm scoped CP access only for authorized staff.
- Confirm GvG voting keeps one row per event/profile.
- Confirm Audit Logs use `get_audit_logs` only.
- Confirm CP-sensitive audit metadata redacts for users without `view_cp`.
- Confirm Admin without needed permissions is denied.
- Confirm wrong-guild access is denied.
- Inspect Network for CP, audit, GvG, and role/permission paths.

Use [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) as the launch checklist.
