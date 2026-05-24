# Deployment

Vercel is the production hosting target.

Milestone 13B completed Vercel setup, Supabase Auth URL configuration, deployment, and production smoke/security validation.

## Production Supabase Project

Production Supabase project is created and separate from local development.

Recorded production project:

- Project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- Production app domain: `https://anteiku-guild-manager.vercel.app`.
- Production Supabase URL: retrieve from Supabase dashboard for Vercel `VITE_SUPABASE_URL`.
- Browser-safe anon or publishable key: retrieve from Supabase dashboard for Vercel `VITE_SUPABASE_ANON_KEY`.

Do not copy service role keys, `sb_secret_*` keys, database URLs, JWT secrets, or SMTP/OAuth secrets into frontend code or Vercel public env.

## Supabase Auth Configuration

Completed in Milestone 13B:

- Site URL: `https://anteiku-guild-manager.vercel.app`.
- Redirect URLs: `https://anteiku-guild-manager.vercel.app`.
- Preview URLs: use a staging Supabase project when possible; avoid broad preview wildcards pointing at production.
- Email signup and email confirmation: production email confirmation is enabled.
- Anonymous sign-ins: keep disabled.

The app uses email/password auth through Supabase JS.

Password recovery status:

- Milestone 17C deployed the Password Recovery Required Reset Flow to production.
- Supabase recovery links now open the app into a required `Set new password` gate.
- Normal app navigation is blocked until the password update succeeds or the user signs out.
- Production recovery validation passed with the controlled production test member.
- Do not disable email confirmation or change Auth settings until the controlled guild onboarding plan is separately approved.

Controlled guild onboarding plan:

- Milestone 17D updates app copy for admin-approval-based onboarding.
- Production email confirmation remains enabled until a separate production Auth setting gate is approved.
- Validate disabling email confirmation in staging project `ckyihuxkioeibzpgwenc` first.
- When email confirmation is disabled, admin approval remains mandatory and pending users remain blocked.
- Registration copy should tell users to use a real email because password recovery depends on it.

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

Additional migration status:

- `20260523000100_member_roster_status_system.sql` is applied and verified in staging as of Milestone 15D.
- `20260523000100_member_roster_status_system.sql` is applied and verified in production as of Milestone 15E.
- Member Status frontend deployment to production completed after production DB verification.

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
- Member Status production verification passed for `roster_status`, `member_status_history`, RLS/policies/grants, `update_member_roster_status(...)`, backfilled memberships, and active Owner count.

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
- Production roster-status mutation smoke without explicit approval. If approved later, use the controlled production test member only and restore to `active`.

Operational warning:

- Supabase CLI is currently linked to production project `mzflfyxxkascrfpteexz` after Milestone 15E.
- Future staging/local Supabase work must explicitly relink before running Supabase commands.

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

Completed in Milestone 13B.

Vercel configuration:

- Framework preset: Vite.
- Build command: `npm run build`.
- Output directory: `dist`.
- Install command: default npm install behavior unless intentionally changed.
- Production branch: `main`.
- GitHub repo: `Ultimate99/anteiku-guild-manager`.

Required Vercel environment variables:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

Only browser-safe Supabase values were set. Do not set service role keys or secret keys in frontend env.

Production URL:

- `https://anteiku-guild-manager.vercel.app`

Security note:

- Vercel GitHub App installation is restricted to only `Ultimate99/anteiku-guild-manager` as of Milestone 14B.

## Vercel GitHub App Hardening

Milestone 14A documented this as a recommended manual hardening action. Milestone 14B records that the user manually completed it.

Completed manual checklist:

- GitHub `Settings -> Applications -> Installed GitHub Apps` was used.
- `Vercel` was selected.
- Repository access was restricted to only `Ultimate99/anteiku-guild-manager`.
- Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Production URL remains `https://anteiku-guild-manager.vercel.app`.
- Production app health was checked after the restriction.
- No Vercel env vars were changed during this step.
- No deploy was performed during the documentation checkpoint.

## Preview And Staging Policy

Preview deployments can accidentally touch production if they inherit production Supabase env values.

Recommended policy:

- Production Vercel env points to production Supabase.
- Preview Vercel env remains unconfigured until the approved Vercel Preview milestone.
- Future staging Vercel env points to the separate staging Supabase project, never production.
- Do not allow preview branches to mutate production data by default.
- Avoid broad Supabase redirect wildcards for preview URLs against production.
- Require explicit approval for any temporary production-connected preview validation.

## Future Staging Supabase And Preview Setup

Milestone 14E completed staging Supabase migration/apply/verification. Milestone 14F completed and verified staging Owner bootstrap. Milestone 14G completed controlled staging test-user and permission matrix setup. Milestone 14H completed staging CP audit redaction and GvG full-smoke validation. Milestone 15D applied and verified the Member Status migration in staging and browser-validated the frontend against staging users. No Vercel Preview env vars were changed and no deployment was performed.

Staging architecture:

- Staging Supabase project: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Project URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.
- Same 9 baseline migrations as production are applied and verified.
- The additional Member Status migration `20260523000100_member_roster_status_system.sql` is applied and verified in staging.
- Keep staging separate from production for URL, anon/publishable key, Auth users, Owner bootstrap, and test data.
- Allow fake/test data only in staging.
- Do not copy production data into staging unless explicitly approved.
- Do not use `db push --include-seed`; this repo has no `supabase/seed.sql`, and core seed data comes from migration `20260514000400_seed_core_data.sql`.
- Permission catalog count is 10 and exactly matches the seed migration.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.

Staging Owner:

- Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_count = 1`.
- `owner_bootstrapped` audit log count: `1`.

Preview env variables, once staging exists:

```text
VITE_SUPABASE_URL=<staging Supabase URL>
VITE_SUPABASE_ANON_KEY=<staging anon/publishable key>
```

Forbidden in Vercel frontend env:

- service role key
- `sb_secret_*` keys
- database password or database URL
- JWT secret
- SMTP secrets
- OAuth/provider secrets

If staging is not ready, keep Vercel Preview env unconfigured.

Auth URL strategy:

- Production Supabase Site URL remains `https://anteiku-guild-manager.vercel.app`.
- Production redirect URLs should remain production-only.
- Staging Supabase Site URL and Redirect URLs should match the chosen staging/preview URL strategy.
- Preview wildcard redirects, if needed, belong only in staging Supabase.
- Avoid broad Preview wildcard redirects in production Supabase.

Future implementation split:

- Milestone 14E: create/link staging Supabase, run migration dry-run/apply, verify schema/RLS/seed. Complete.
- Milestone 14F: staging Owner bootstrap. Complete.
- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution. Complete.
- Milestone 14H: staging CP audit redaction and GvG full-smoke validation. Complete.
- Later: configure Vercel Preview env with staging Supabase only and configure staging Auth URLs.

## Post-Deployment Validation

Completed in Milestone 13B:

- Production app loads.
- Owner can sign in.
- Owner can access AdminPanel.
- Owner mobile AdminPanel validation passed.
- Audit Logs are readable/usable on desktop and mobile.
- CP Management is readable/usable on desktop and mobile.
- Controlled signup created a pending production user after email confirmation.
- Pending user could not access member/admin areas.
- Owner approved controlled user as Member.
- Approved Member cannot access AdminPanel.
- Approved Member cannot see CP.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls after clearing Network.
- Audit Logs refresh/load observed `rpc/get_audit_logs`.
- No direct `/rest/v1/audit_logs` calls were observed during Audit Logs actions.
- No CP RPC/table calls or audit write/update/delete/export calls were observed during Audit Logs actions.
- CP Management load/refresh observed approved CP RPCs only.
- No direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- Mobile viewport validation passed.

Controlled production test member:

- Email: `krsticmiroslav99+m13b21144225@gmail.com`.
- Username/profile slug: `m13bmember21056302`.
- IGN: `M13B Member 21056302`.
- Status: approved Member.
- This member remains in production unless cleanup/member management is explicitly approved later.
- Do not hard-delete the user/profile/membership rows.
- Preserve validation/audit history.
- Prefer a future safe status change, Auth-user disable action, or dedicated suspend/leave feature if cleanup is needed.
- Any cleanup action needs explicit approval and post-action verification.

Deferred / intentionally not tested in production:

- GvG production smoke was not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope. Milestone 10 local live-browser validation covered GvG one-row vote switching, and Milestone 14H now covers full GvG smoke in staging.
- CP redaction browser test was not tested in production because no production staff/data combination exists for `view_audit_logs` without `view_cp` plus fresh CP-sensitive audit metadata. Milestone 11A backend validation covered SQL-side CP metadata redaction, and Milestone 14H now covers the browser scenario in staging.

Use [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) as the launch checklist.
