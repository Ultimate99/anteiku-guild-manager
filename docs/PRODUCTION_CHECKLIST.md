# Production Readiness Checklist

Milestone 13B production Vercel deployment, Supabase Auth URL configuration, and production smoke/security validation are complete.

Current production checkpoint:
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations are applied remotely.
- Production schema/RLS/seed verification passed.
- Manual Owner bootstrap completed for `ultimatesrb` / `UltimateSRB` in `Anteiku`.
- Exactly one active Owner membership exists.
- Vercel deployment is live.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Site URL and Redirect URL allow-list are configured for the production URL.
- Production smoke/security validation passed with documented deferred production-only items.
- Milestone 14C AdminPanel tabs refactor is complete in production.
- Milestone 14D staging Supabase + Vercel Preview planning is documented; staging has not been created yet.

## Milestone 14A Production Hardening Policy

Milestone 14A is a documentation-only production hardening and cleanup policy pass.

- [x] No production commands were run.
- [x] No source logic was changed.
- [x] No SQL migrations were changed or created.
- [x] No Vercel settings were changed.
- [x] No GitHub App settings were changed.
- [x] No users were disabled, deleted, or suspended.
- [x] Vercel GitHub App restriction is recommended below but was not executed.
- [x] The controlled production test member remains in production and is documented below.
- [x] Preview/staging policy is documented.
- [x] Deferred production smoke tests and safer future testing paths are documented.

## Milestone 14B GitHub App Restriction Checkpoint

Milestone 14B verified and recorded the manual Vercel GitHub App hardening action.

- [x] Vercel GitHub App installation is now limited to `Ultimate99/anteiku-guild-manager` per manual user confirmation.
- [x] Vercel project remains connected to `Ultimate99/anteiku-guild-manager`.
- [x] Production URL remains `https://anteiku-guild-manager.vercel.app`.
- [x] Production app health was checked in the browser after the restriction.
- [x] Browser check loaded title `Anteiku Guild Manager` at the production URL.
- [x] No captured browser console errors were observed during the checkpoint check.
- [x] No Vercel env vars were changed as part of this checkpoint.
- [x] No source logic or SQL migrations were changed.
- [x] No deploy or commit was performed.

## Vercel GitHub App Hardening Checklist

Manual action only. Do not change Vercel env vars during this step.

- [x] Open GitHub.
- [x] Go to `Settings -> Applications -> Installed GitHub Apps`.
- [x] Select `Vercel`.
- [x] Restrict repository access to only `Ultimate99/anteiku-guild-manager`.
- [x] Save the GitHub App installation changes.
- [x] Confirm the Vercel project still points to `Ultimate99/anteiku-guild-manager` on `main`.
- [x] Confirm current production deployment remains healthy after the restriction.
- [ ] Do not broaden Vercel access to unrelated repositories unless separately approved.

## Controlled Production Test Member Policy

Controlled test member currently present in production:

- Email: `krsticmiroslav99+m13b21144225@gmail.com`.
- Username/profile slug: `m13bmember21056302`.
- IGN: `M13B Member 21056302`.
- Status: approved Member.

Recommended policy:

- Keep the controlled test member documented for now.
- Do not hard-delete the user or related profile/membership rows.
- Preserve validation and audit history.
- Prefer a future safe status change, Auth-user disable action, or dedicated suspend/leave feature if cleanup is needed.
- Any cleanup action requires explicit approval, a rollback note, and post-action verification.

## Preview And Staging Policy

- Production Vercel env values must exist only for Production deployments.
- Preview deployments should have no Supabase env vars until a separate staging Supabase project exists.
- A future staging Supabase project must be separate from production and must use separate Auth URLs, anon key, database, users, and seed/test data.
- Preview deployments must never mutate production by default.
- Avoid broad Supabase redirect wildcards for preview URLs against production.
- If a preview must connect to production for emergency validation, require explicit approval and a narrow time-boxed checklist.

## Milestone 14D Staging Supabase And Vercel Preview Plan

Milestone 14D is documentation-only. No staging project was created, no Supabase commands were run, no Vercel env vars were changed, and no deployment was performed.

Staging Supabase architecture:

- [ ] Create a fresh staging Supabase project only after explicit approval.
- [ ] Apply the same 9 migrations as production.
- [ ] Use a separate staging Supabase URL.
- [ ] Use a separate staging anon/publishable key.
- [ ] Use separate staging Auth users.
- [ ] Bootstrap a separate staging Owner.
- [ ] Allow fake/test users and data only in staging.
- [ ] Do not copy production data to staging unless explicitly approved.
- [ ] Do not use `db push --include-seed`; core seed data is in migration `20260514000400_seed_core_data.sql`.

Vercel Preview env policy:

- [ ] Keep Production env pointed at production Supabase only.
- [ ] Configure Preview env only after staging exists.
- [ ] Set Preview `VITE_SUPABASE_URL` to the staging Supabase URL.
- [ ] Set Preview `VITE_SUPABASE_ANON_KEY` to the staging anon/publishable key.
- [ ] Do not add a service role key.
- [ ] Do not add a database password or database URL.
- [ ] Do not add `sb_secret_*` keys.
- [ ] Leave Preview env unconfigured if staging is not ready.

Auth URL strategy:

- [x] Keep production Site URL as `https://anteiku-guild-manager.vercel.app`.
- [x] Keep production redirect URLs production-only.
- [ ] Configure staging Site URL to match the chosen staging/preview URL strategy.
- [ ] Add Preview wildcard redirects only to staging Supabase if needed.
- [ ] Do not add broad Preview wildcard redirects to production Supabase.

Future staging test users:

- [ ] Owner.
- [ ] Approved Member.
- [ ] Admin with `view_audit_logs` but without `view_cp`.
- [ ] Admin with both `view_audit_logs` and `view_cp`.
- [ ] Wrong-guild Member.
- [ ] Pending user.

Future staging validation targets:

- [ ] Full GvG smoke test.
- [ ] CP audit redaction browser scenario.
- [ ] Permission denial flows.
- [ ] Wrong-guild access.
- [ ] Cleanup/archive experiments.

Recommended future phases:

- Milestone 14E: create/link staging Supabase, dry-run/apply migrations, verify schema/RLS/seed.
- Milestone 14F: configure Vercel Preview env with staging Supabase only and staging Auth URLs.
- Milestone 14G: staging validation with controlled test users/data.

## Deferred Production Smoke Tests

Deferred by design:

- GvG production smoke was intentionally not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- CP redaction browser scenario was intentionally not tested because the needed production staff/data combination does not currently exist.

Preferred future strategy:

- Test GvG event/vote flows in a staging Supabase project first.
- Test CP audit redaction in staging with a controlled staff user that has `view_audit_logs` but not `view_cp`, plus a controlled CP-sensitive audit entry.
- Run production GvG or CP-redaction tests only after explicit approval and a cleanup/data-retention plan.

## Production Supabase Setup

- [x] Create a fresh production Supabase project.
- [x] Record project ref, region, dashboard URL, and production API URL.
- [x] Keep production separate from local development.
- [ ] Decide whether a staging Supabase project is needed for Vercel previews.
- [x] Configure email/password Auth.
- [x] Decide whether email confirmations are required. Production email confirmation is enabled.
- [ ] Keep anonymous sign-ins disabled.
- [x] Configure production Site URL.
- [x] Configure exact production redirect URLs.
- [ ] Avoid broad preview redirect wildcards against production.
- [ ] Confirm no service role key or secret key is copied into frontend/Vercel public env.

## Environment Variables

Production Vercel frontend env must include only browser-safe values:

```text
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
```

- [x] `VITE_SUPABASE_URL` points to production Supabase only in Production Vercel env.
- [x] `VITE_SUPABASE_ANON_KEY` is the production browser-safe anon/publishable value.
- [x] Preview env does not intentionally point to production Supabase.
- [x] No `SUPABASE_SERVICE_ROLE_KEY`.
- [x] No `sb_secret_*`.
- [x] No database URL.
- [x] No JWT secret.
- [x] No SMTP/OAuth/provider secrets.
- [x] No secrets committed to `.env.example`, `.env.local`, docs, or source.

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
- [x] Controlled production test member is documented and intentionally left in place until cleanup is approved.

## RLS And Security Validation

- [x] RLS enabled on protected tables.
- [x] Members cannot see CP in deployed production member pages.
- [x] Member Home/Profile/GvG pages triggered no CP RPC/table calls in manual Network validation.
- [x] Members cannot read `member_cp`.
- [x] Members cannot read `cp_snapshots`.
- [x] Members cannot call CP roster/leaderboard/growth RPCs successfully.
- [ ] Admin without `view_cp` cannot view CP.
- [ ] Admin with `view_cp` can view scoped CP only.
- [ ] Admin with `update_cp` can update scoped approved active profiles only.
- [ ] Leader/Vice CP access is scoped to assigned guild.
- [ ] Wrong-guild CP access is denied.
- [x] Pending users cannot access member/admin areas.
- [ ] Admin without needed permissions is denied.
- [ ] Guild transfer is Owner-only.
- [ ] Normal app role assignment cannot assign `owner`.
- [x] Direct `gvg_votes` writes are unavailable through direct table policies.
- [ ] GvG vote switching keeps one row per event/profile in deployed production browser validation. Deferred intentionally to avoid persistent production GvG test data; Milestone 10 local live-browser validation covered this.
- [x] Audit viewer uses `get_audit_logs` in deployed production browser validation.
- [x] Direct non-Owner `audit_logs` reads are blocked or return no rows.
- [ ] CP-sensitive audit metadata redacts for users without scoped `view_cp` in deployed production browser validation. Deferred intentionally because no current production staff/data combination exists; Milestone 11A backend validation covered this.
- [x] `private.write_audit_log` is not executable by normal authenticated users.

## Vercel Deployment Checklist

- [x] Vercel project created.
- [x] Framework preset is Vite.
- [x] Build command is `npm run build`.
- [x] Output directory is `dist`.
- [x] Production env contains only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- [x] Preview env does not accidentally point to production Supabase.
- [x] Production domain is known: `https://anteiku-guild-manager.vercel.app`.
- [x] Supabase Auth Site URL matches production domain.
- [x] Supabase redirect URLs include the production domain.
- [x] Build passes in Vercel.

## Post-Deploy Smoke Test

- [x] Production app loads.
- [x] No major console errors on first load.
- [x] Sign up creates a pending user after email confirmation.
- [x] Pending user sees only pending state.
- [x] Owner can sign in.
- [x] Owner can open AdminPanel.
- [x] Owner can approve controlled test user.
- [x] Approved Member cannot access AdminPanel.
- [x] Approved Member cannot see CP.
- [ ] Authorized staff can access scoped CP as expected.
- [ ] GvG event/voting flow works in production. Deferred intentionally to avoid persistent production GvG test data.
- [ ] One vote row per event/profile is preserved in production. Deferred intentionally; Milestone 10 local validation passed.
- [x] Audit Logs load for Owner.
- [ ] Audit Logs are denied for Member/pending/Admin without permission.
- [ ] CP-sensitive audit metadata redacts without `view_cp` in production browser. Deferred intentionally; Milestone 11A backend validation passed.
- [x] Mobile viewport is readable.

## Network Checks

After clearing Network and performing only the target action:

- [x] CP UI uses only approved CP RPCs.
- [x] Member pages make no CP calls.
- [x] Audit viewer uses `get_audit_logs` only.
- [x] Audit viewer does not call `audit_logs` table directly.
- [x] Audit viewer does not call CP RPCs/tables.
- [ ] GvG voting uses `submit_gvg_vote`.
- [ ] GvG event management uses approved GvG RPCs/safe reads.
- [ ] No direct frontend writes to `gvg_votes`.
- [ ] Permission management writes use only grant/revoke RPCs.

## Launch Operations Checklist

Before inviting real members:

- [x] Confirm Vercel GitHub App access is repository-scoped.
- [ ] Confirm Production env contains only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- [ ] Confirm Preview env has no production Supabase credentials unless a separately approved policy exists.
- [ ] Confirm Supabase Auth Site URL and Redirect URLs still match the production domain.
- [ ] Confirm the controlled test member is intentionally retained or has an approved cleanup plan.
- [ ] Review the deferred GvG and CP-redaction production tests.

Approval queue operations:

- [ ] Approve only expected users.
- [ ] Assign the lowest role needed.
- [ ] Keep Owner assignment manual-only and out of the UI.
- [ ] Reject unknown registrations with a clear reason when appropriate.
- [ ] Review audit logs after bulk approval sessions.

CP update operations:

- [ ] Verify the target member and guild before changing CP.
- [ ] Use only the AdminPanel CP Management UI or approved RPC workflow.
- [ ] Do not patch `member_cp` or `cp_snapshots` directly.
- [ ] Review audit logs after CP update sessions.

GvG operations:

- [ ] Create production GvG events only when the event is real or a production test is explicitly approved.
- [ ] Avoid creating throwaway production GvG events without a cleanup/data-retention plan.
- [ ] Confirm voting scope and event status before inviting votes.
- [ ] Use audit/log review after event lifecycle changes where useful.

Admin permission operations:

- [ ] Grant only the minimum required permissions.
- [ ] Treat `view_cp`, `update_cp`, and `view_audit_logs` as sensitive.
- [ ] Review permission changes in audit logs.
- [ ] Revoke temporary permissions after the need ends.

Production SQL safety:

- [ ] Prefer app UI/RPC workflows over manual SQL.
- [ ] Use read-only SQL for verification whenever possible.
- [ ] Never run `supabase db reset` on production.
- [ ] Never run `supabase/tests/local_validation_anteiku.sql` on production.
- [ ] Never disable RLS or add broad grants.
- [ ] Never use `db push --include-seed` until the missing `supabase/seed.sql` hazard is resolved.
- [ ] Never place service-role or secret keys in frontend/Vercel env.

## Rollback And Safety Notes

- [ ] Export/backup production data before risky changes.
- [ ] Keep the previous Vercel deployment available for rollback.
- [ ] Do not roll back database schema casually after users create data.
- [ ] Prefer forward-fix migrations for production database issues.
- [ ] If a secret leaks, rotate it from Supabase/Vercel dashboards and remove all exposure.
- [ ] If CP or audit metadata leaks, stop deployment validation and treat as a security incident.
