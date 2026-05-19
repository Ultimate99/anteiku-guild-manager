# Deployment

Vercel is the intended hosting target. Production deployment has not been performed yet.

Milestone 13A completed production Supabase migration apply, production schema/RLS/seed verification, and manual Owner bootstrap. Do not deploy, configure Auth URLs, or run additional production commands without explicit approval.

## Production Supabase Project

Production Supabase project is created and separate from local development.

Recorded production project:

- Project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- Production app domain: pending Milestone 13B.
- Production Supabase URL: retrieve from Supabase dashboard for Vercel `VITE_SUPABASE_URL`.
- Browser-safe anon or publishable key: retrieve from Supabase dashboard for Vercel `VITE_SUPABASE_ANON_KEY`.

Do not copy service role keys, `sb_secret_*` keys, database URLs, JWT secrets, or SMTP/OAuth secrets into frontend code or Vercel public env.

## Supabase Auth Configuration

Still pending for Milestone 13B. Configure Auth in the Supabase dashboard before production smoke testing:

- Site URL: production Vercel/custom domain.
- Redirect URLs: exact production URLs.
- Preview URLs: use a staging Supabase project when possible; avoid broad preview wildcards pointing at production.
- Email signup and email confirmation: decide intentionally before launch.
- Anonymous sign-ins: keep disabled.

The app uses email/password auth through Supabase JS.

## Migration Workflow

Milestone 13A completed this workflow using the local Supabase CLI dev tooling:

```powershell
npx.cmd supabase link
npx.cmd supabase migration list
npx.cmd supabase db push --dry-run
npx.cmd supabase db push
npx.cmd supabase migration list
```

Linked project ref was confirmed as `mzflfyxxkascrfpteexz`.

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

After applying migrations, production verification passed:

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

Owner bootstrap remains manual-only. Production Owner bootstrap was completed in Milestone 13A using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.

Completed bootstrap record:

- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.

Verified after bootstrap:

- Owner profile is `approved`.
- Owner has exactly one active primary membership.
- Owner role is `owner`.
- Owner belongs to the intended guild.
- An owner bootstrap audit log exists.
- No UI exposes Owner assignment.

Do not rerun Owner bootstrap unless a separate recovery plan is approved.

## Vercel Project

Pending for Milestone 13B.

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

Pending for Milestone 13B.

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
