# Production Readiness Checklist

Milestone 13A production Supabase setup is complete through migration apply, production schema/RLS/seed verification, and manual Owner bootstrap.

Do not perform additional production actions until explicitly approved.

Current production checkpoint:
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations are applied remotely.
- Production schema/RLS/seed verification passed.
- Manual Owner bootstrap completed for `ultimatesrb` / `UltimateSRB` in `Anteiku`.
- Exactly one active Owner membership exists.
- Vercel is not configured.
- Production deployment has not happened.

## Production Supabase Setup

- [x] Create a fresh production Supabase project.
- [x] Record project ref, region, dashboard URL, and production API URL.
- [x] Keep production separate from local development.
- [ ] Decide whether a staging Supabase project is needed for Vercel previews.
- [ ] Configure email/password Auth.
- [ ] Decide whether email confirmations are required.
- [ ] Keep anonymous sign-ins disabled.
- [ ] Configure production Site URL.
- [ ] Configure exact production redirect URLs.
- [ ] Avoid broad preview redirect wildcards against production.
- [ ] Confirm no service role key or secret key is copied into frontend/Vercel public env.

## Environment Variables

Production Vercel frontend env must include only browser-safe values:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

- [ ] `VITE_SUPABASE_URL` points to production Supabase only in Production Vercel env.
- [ ] `VITE_SUPABASE_ANON_KEY` is the production browser-safe anon/publishable value.
- [ ] Preview env points to staging Supabase or is intentionally unconfigured.
- [ ] No `SUPABASE_SERVICE_ROLE_KEY`.
- [ ] No `sb_secret_*`.
- [ ] No database URL.
- [ ] No JWT secret.
- [ ] No SMTP/OAuth/provider secrets.
- [ ] No secrets committed to `.env.example`, `.env.local`, docs, or source.

## Migration Checklist

Apply migrations in this order:

1. `20260514000100_core_schema.sql`
2. `20260514000200_constraints_indexes.sql`
3. `20260514000300_private_helper_functions.sql`
4. `20260514000400_seed_core_data.sql`
5. `20260514000500_rls_policies.sql`
6. `20260514000600_public_rpc_functions.sql`
7. `20260515000100_member_guild_role_management.sql`
8. `20260515000200_cp_rpc_hardening.sql`
9. `20260515000300_audit_log_read_hardening.sql`

Preferred flow:

- [x] Confirm local repo has the expected migration files.
- [x] Confirm target project ref before linking.
- [x] Run `supabase link` only after approval.
- [x] Run `supabase migration list`.
- [x] Run `supabase db push --dry-run`.
- [x] Review dry-run output.
- [x] Run `supabase db push`.
- [x] Verify `supabase_migrations.schema_migrations`.

Hazard:

- `supabase/config.toml` references `./seed.sql`, but `supabase/seed.sql` is missing.
- Core production seed data is in migration `20260514000400_seed_core_data.sql`.
- Do not use `supabase db push --include-seed` until the seed-file hazard is resolved.

## Forbidden Production Commands

Never run against production:

```powershell
supabase db reset
```

Do not run:

- `supabase/tests/local_validation_anteiku.sql`.
- Any fake-user validation script.
- Any broad destructive SQL.
- Any SQL that disables RLS.
- Any broad grant that exposes protected tables.
- Any direct CP/audit/GvG vote data patch unless separately approved and reviewed.

## Owner Bootstrap Checklist

Owner assignment is manual-only.

- [x] Production migrations are applied.
- [x] First real production Auth user exists.
- [x] Real `auth.users.id` is copied from Supabase.
- [x] `supabase/templates/owner_bootstrap_TEMPLATE.sql` placeholders are replaced.
- [x] Guard block is removed only in the reviewed copy being executed.
- [x] Initial guild ID is reviewed.
- [x] SQL is run in a controlled production SQL editor/session.
- [x] Owner profile is approved.
- [x] Owner membership is active and primary.
- [x] Owner role is `owner`.
- [x] There is exactly one active primary membership for the Owner.
- [x] Owner bootstrap audit log exists.
- [x] No frontend UI exposes Owner assignment.

Production Owner record:
- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- `active_owner_membership_count = 1`.
- `owner_active_primary_membership_count = 1`.
- `owner_bootstrap_audit_count = 1`.

## Production Data Checklist

- [x] Guild `Anteiku` exists.
- [x] Guild `Anteiku:Re` exists.
- [x] Guild `Anteiku:Rose` exists.
- [x] Guild `Anteiku:Goat` exists.
- [x] Permission catalog exists.
- [x] `view_cp` and `update_cp` are marked sensitive.
- [x] No local fake users are present.
- [x] No fake CP/GvG/audit demo data was pushed.

## RLS And Security Validation

- [x] RLS enabled on protected tables.
- [ ] Members cannot read `member_cp`.
- [ ] Members cannot read `cp_snapshots`.
- [ ] Members cannot call CP roster/leaderboard/growth RPCs successfully.
- [ ] Admin without `view_cp` cannot view CP.
- [ ] Admin with `view_cp` can view scoped CP only.
- [ ] Admin with `update_cp` can update scoped approved active profiles only.
- [ ] Leader/Vice CP access is scoped to assigned guild.
- [ ] Wrong-guild CP access is denied.
- [ ] Pending users cannot access member/admin areas.
- [ ] Admin without needed permissions is denied.
- [ ] Guild transfer is Owner-only.
- [ ] Normal app role assignment cannot assign `owner`.
- [x] Direct `gvg_votes` writes are unavailable through direct table policies.
- [ ] GvG vote switching keeps one row per event/profile in deployed production browser validation.
- [ ] Audit viewer uses `get_audit_logs` in deployed production browser validation.
- [x] Direct non-Owner `audit_logs` reads are blocked or return no rows.
- [ ] CP-sensitive audit metadata redacts for users without scoped `view_cp` in deployed production browser validation.
- [x] `private.write_audit_log` is not executable by normal authenticated users.

## Vercel Deployment Checklist

- [ ] Vercel project created.
- [ ] Framework preset is Vite.
- [ ] Build command is `npm run build`.
- [ ] Output directory is `dist`.
- [ ] Production env contains only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- [ ] Preview env does not accidentally point to production Supabase.
- [ ] Production domain is known.
- [ ] Supabase Auth Site URL matches production domain.
- [ ] Supabase redirect URLs include the production domain.
- [ ] Build passes in Vercel.

## Post-Deploy Smoke Test

- [ ] Production app loads.
- [ ] No console errors on first load.
- [ ] Sign up creates a pending user.
- [ ] Pending user sees only pending state.
- [ ] Owner can sign in.
- [ ] Owner can open AdminPanel.
- [ ] Owner can approve/reject controlled test user.
- [ ] Approved Member cannot access AdminPanel.
- [ ] Approved Member cannot see CP.
- [ ] Authorized staff can access scoped CP as expected.
- [ ] GvG event/voting flow works.
- [ ] One vote row per event/profile is preserved.
- [ ] Audit Logs load for Owner.
- [ ] Audit Logs are denied for Member/pending/Admin without permission.
- [ ] CP-sensitive audit metadata redacts without `view_cp`.
- [ ] Mobile viewport is readable.

## Network Checks

After clearing Network and performing only the target action:

- [ ] CP UI uses only approved CP RPCs.
- [ ] Member pages make no CP calls.
- [ ] Audit viewer uses `get_audit_logs` only.
- [ ] Audit viewer does not call `audit_logs` table directly.
- [ ] Audit viewer does not call CP RPCs/tables.
- [ ] GvG voting uses `submit_gvg_vote`.
- [ ] GvG event management uses approved GvG RPCs/safe reads.
- [ ] No direct frontend writes to `gvg_votes`.
- [ ] Permission management writes use only grant/revoke RPCs.

## Rollback And Safety Notes

- [ ] Export/backup production data before risky changes.
- [ ] Keep the previous Vercel deployment available for rollback.
- [ ] Do not roll back database schema casually after users create data.
- [ ] Prefer forward-fix migrations for production database issues.
- [ ] If a secret leaks, rotate it from Supabase/Vercel dashboards and remove all exposure.
- [ ] If CP or audit metadata leaks, stop deployment validation and treat as a security incident.
