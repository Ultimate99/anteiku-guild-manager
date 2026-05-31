# Production Readiness Checklist

Milestone 13B production Vercel deployment, Supabase Auth URL configuration, and production smoke/security validation are complete.

Current production checkpoint:
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All approved production migrations through `20260531000200_active_profile_profile_cosmetics.sql` are applied remotely, including `20260523000100_member_roster_status_system.sql`, `20260524000100_cp_update_window_self_submit.sql`, `20260524000200_cp_update_window_staff_read.sql`, `20260524000300_cp_rankings.sql`, `20260524000400_cp_rank_badge_summary.sql`, `20260525000100_cosmetics_catalog_unlocks.sql`, `20260525000200_cp_rankings_cosmetics.sql`, `20260525000300_premium_cosmetics_grant_helper.sql`, cosmetics catalog sync/frame hotfix migrations, `20260526000100_admin_analytics_foundation.sql`, live CP growth migrations, `20260528000100_three_v_three_team_finder.sql`, `20260530000100_guild_wall_mvp.sql`, `20260530000200_guild_wall_scope_hotfix.sql`, `20260530000300_global_wall_scope.sql`, Ghoul Rep/Public Profile/Push migrations, `20260531000100_account_switcher_foundation.sql`, and `20260531000200_active_profile_profile_cosmetics.sql`.
- Production schema/RLS/seed verification passed.
- Manual Owner bootstrap completed for `ultimatesrb` / `UltimateSRB` in `Anteiku`.
- Exactly one active Owner membership exists.
- Vercel deployment is live.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Site URL and Redirect URL allow-list are configured for the production URL.
- Production smoke/security validation passed with documented deferred production-only items.
- Milestone 14C AdminPanel tabs refactor is complete in production.
- Milestone 14E staging Supabase migration/apply/verification is complete for `ckyihuxkioeibzpgwenc`.
- Milestone 14F staging Owner bootstrap is complete and verified.
- Milestone 14G controlled staging test users and permission matrix setup is complete.
- Milestone 14H staging CP audit redaction and GvG full-smoke validation is complete.
- Milestone 15D Member Status staging migration/browser validation is complete.
- Milestone 15E Member Status production rollout is complete.
- Production has `20260523000100_member_roster_status_system.sql` applied and verified.
- Member Status frontend is deployed and smoke-tested in production.
- Milestone 17C Password Recovery Required Reset Flow is live and production-validated.
- Milestone 17D registration copy is prepared for admin-approval-based onboarding.
- Milestone 19E CP Update Window / Member CP Self-Submit is live and production read-only-smoke validated.
- Controlled production CP mutation smoke was not performed and requires explicit approval before any production CP window/test submit action.
- Milestone 20F CP Leaderboard / CP Ranking is live and production-smoke validated.
- Member leaderboard is rank-only; CP values remain hidden from members.
- AdminPanel `CP Ranking` is permission-protected and Owner Global ranking was smoke-tested.
- Milestone 21E Rank Badge / Profile Border is live and production-smoke validated.
- Rank badge/profile border uses only `get_my_cp_rank_summary()` and does not expose CP values or private CP metadata.
- Milestone 22E Cosmetics production rollout is complete. Production has `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified, Vercel serves the cosmetics picker/assets, and production smoke passed.
- Milestone 23D Premium Cosmetics production rollout is complete. Production has `20260525000300_premium_cosmetics_grant_helper.sql` applied and verified.
- Owner Cosmetics is live in AdminPanel -> Tools, visible only to Owner, and production-smoke validated for locked avatar/frame grant by exact profile slug / username plus member equip after grant.
- Milestone 24E AdminPanel Analytics production rollout is complete. Production has `20260526000100_admin_analytics_foundation.sql` applied and verified, AdminPanel -> Analytics is live, Weekly Growth is live, and Owner production smoke passed.
- Weekly Growth snapshot capture creates persistent production snapshot rows and was not tested in production by design; require explicit approval before capture.
- Milestone 25D 3v3 Team Finder production rollout is complete. Production has `20260528000100_three_v_three_team_finder.sql` applied and verified, the member-facing `3v3` UI is live, and controlled production smoke passed for create/request/approve/slot-fill.
- 3v3 Combined CP is public/self-entered and separate from protected normal CP. Normal CP was not visible during controlled production smoke.
- Controlled 3v3 test team cleanup status was not specified in the smoke note; verify before assuming retained or disbanded state.
- Milestone 26A/26B PWA install support is live in production. Production serves the manifest, service worker, icons, and standalone app metadata.
- PWA service worker caches same-origin app shell/static assets only and does not cache Supabase Auth/RPC/API responses.
- PWA update-available banner is live in production through `bb570a6 feat: add PWA update available banner`. It waits for a service worker update, shows `Update App` / `Later`, and reloads only after user-triggered `SKIP_WAITING` plus `controllerchange`.
- The update banner keeps Supabase/API/Auth/RPC/CP/GvG/3v3/admin/analytics data uncached.
- Offline Notice Banner is live in production through `2bbd24a feat: add offline notice banner`. It uses `navigator.onLine` plus `online` / `offline` browser events, shows only while offline, and hides automatically when online returns.
- Offline Notice Banner is UI-only: no queued actions, no full offline mode, no service worker/cache behavior change, and no Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data caching.
- Global Wall scope is live in production through `feaf2ff feat: add global wall scope` and `20260530000300_global_wall_scope.sql`. `My Guild` is explicit-guild scoped, `Global` uses null `guild_id`, RLS/direct-grant/RPC/Owner-count checks passed, and controlled production mutation smoke remains pending.
- Push Notifications are live in production. Production has `20260530000800_push_notifications_foundation.sql` applied, `send-push-notifications` deployed and active, Vercel `VITE_VAPID_PUBLIC_KEY` configured, Supabase Edge Function secret names configured, frontend commit `c761d38 feat: add push notification settings UI` pushed to `main`, and manual production smoke passed for permission grant, subscription registration, preference save, test notification receipt, notification click opening the app, and disable flow available/working.
- Account Switcher active-profile Profile/Cosmetics migration is live in production. Production has `20260531000200_active_profile_profile_cosmetics.sql` applied, frontend commit `401e67e feat: migrate profile cosmetics to active profile` pushed to `main`, and production smoke passed for Profile active identity/details, Customize active cosmetics load, active frame equip-and-restore, single-profile CP unchanged, and no captured console errors.
- Push Notifications payloads remain fixed server-generated title/body/route data; manual smoke found no CP/private/admin data in notifications.
- Browser-native install prompt / standalone launch still needs a manual device/browser check if install UX confirmation is required.
- Offline banner DevTools Network Offline/Online verification remains a recommended manual check.
- Cosmetics v1 uses approved repo static assets only. Do not add arbitrary URLs, player uploads, or Supabase Storage without a planned security review.
- Vercel Preview env has not been configured for staging yet.

Push Notifications security checkpoint:
- Do not expose service-role keys to frontend/Vercel public env.
- Do not expose `VAPID_PRIVATE_KEY` to frontend/Vercel public env or committed files.
- Do not include normal CP values, email, auth IDs, audit/admin/private metadata, or arbitrary user content in push payloads.
- Do not add automatic GvG, CP Update Window, 3v3, Wall, or profile-reaction notification hooks without a separate approved milestone.

Controlled guild onboarding checkpoint:

- [x] Password recovery is fixed and production-validated.
- [x] Registration copy is prepared for admin-approval-based onboarding in Milestone 17D.
- [ ] Disable email confirmation in staging only.
- [ ] Validate staging signup creates pending users without email confirmation.
- [ ] Validate pending users remain blocked.
- [ ] Validate Owner approval and approved member access.
- [ ] Validate password recovery still works after staging email confirmation is disabled.
- [ ] Keep production email confirmation enabled until a separate production gate is approved.

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
- Optional Member Status mutation smoke must use this controlled production test member only, require explicit approval, and restore `roster_status` to `active`.

## Preview And Staging Policy

- Production Vercel env values must exist only for Production deployments.
- Preview deployments should have no Supabase env vars until the approved Vercel Preview configuration milestone.
- Staging Supabase is separate from production and must continue to use separate Auth URLs, anon key, database, users, and seed/test data.
- Preview deployments must never mutate production by default.
- Avoid broad Supabase redirect wildcards for preview URLs against production.
- If a preview must connect to production for emergency validation, require explicit approval and a narrow time-boxed checklist.

## Milestone 14E Staging Supabase Verification

Milestone 14E is complete.

- [x] Staging Supabase project exists: `ckyihuxkioeibzpgwenc`.
- [x] Project name is `Anteiku Guild Manager Staging`.
- [x] Same 9 migrations as production were applied.
- [x] Staging schema/RLS/seed verification passed.
- [x] Permission catalog count is 10.
- [x] Permission catalog exactly matches `20260514000400_seed_core_data.sql`.
- [x] Earlier "7 permissions" report was confirmed as a partial summary mistake.
- [x] `manage_permissions` is not seeded and remains a future/open permission question unless explicitly approved later.
- [x] No production project was touched.
- [x] No Vercel env vars were changed.
- [x] No source or SQL files were changed.
- [x] Staging Owner was not bootstrapped during 14E; it was bootstrapped later in 14F.
- [x] Staging test users were not created during 14E; they were created later in 14G.

Recommended next milestone:

- Milestone 14F: staging Owner bootstrap planning. Completed later.

## Milestone 14F Staging Owner Bootstrap

Milestone 14F is complete.

- [x] Staging Owner Auth user exists.
- [x] Staging Owner profile exists.
- [x] `approval_status = approved`.
- [x] Username/profile slug is `staging_owner`.
- [x] IGN is `Staging Owner`.
- [x] Initial guild is `Anteiku`.
- [x] Membership role is `owner`.
- [x] Membership status is `active`.
- [x] Primary membership is `true`.
- [x] `active_owner_count = 1`.
- [x] `owner_bootstrapped` audit log count is `1`.
- [x] Production project was not touched.
- [x] Vercel env vars were not changed.
- [x] Source and SQL files were not changed.
- [x] Controlled staging test users were created later in 14G.
- [ ] Vercel Preview env has not been configured yet.

Staging Owner record:

- Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.

Recommended next milestone:

- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution.

## Milestone 14H Staging Validation

Milestone 14H is complete.

- [x] CP audit redaction browser scenario passed in staging.
- [x] `staging_audit_nocp` saw `Sensitive CP metadata hidden.`.
- [x] `staging_audit_nocp` did not see CP value, `cp_old`, or `cp_new`.
- [x] `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- [x] Full GvG smoke test passed in staging.
- [x] `staging_member` voted Present, switched Absent with reason, then switched back Present.
- [x] SQL confirmed exactly one `gvg_votes` row with final status `present` and `absence_reason = null`.
- [x] Wrong-guild access denial passed.
- [x] Permission denial checks passed.
- [x] Pending-user lockout passed.
- [x] Active Owner count remained `1`.
- [x] Production project was not touched.
- [x] Vercel env vars were not changed.
- [x] Source and SQL files were not changed.
- [x] Staging test data remains intentionally.

Network caveat:

- Literal DevTools request capture was unavailable through browser automation.
- Source-path inspection confirmed Audit uses `get_audit_logs`.
- Source-path inspection confirmed CP uses `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- Source-path inspection confirmed GvG writes use approved RPCs, with the own-vote `gvg_votes` read expected and safe.
- This caveat is non-blocking for Milestone 14H completion.

Deferred production tests now covered in staging:

- [x] Full GvG smoke test.
- [x] CP audit redaction browser scenario.
- [x] Permission denial flows.
- [x] Wrong-guild access.
- [x] Pending-user lockout.

## Milestone 15D Member Status Staging Validation

Milestone 15D is complete for staging only.

- [x] Staging project confirmed: `ckyihuxkioeibzpgwenc`.
- [x] Production project `mzflfyxxkascrfpteexz` was not touched.
- [x] Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- [x] `20260523000100_member_roster_status_system.sql` was applied to staging.
- [x] Staging schema/RLS verification passed for `roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, backfilled memberships, and active Owner count.
- [x] Milestone 15B frontend is browser-validated through staging.
- [x] `staging_member` was restored to `membership_status = active` and `roster_status = active`.
- [x] Status history/audit rows were verified.
- [x] `.env.local` was restored to local Supabase.
- [x] Production rollout was not performed.
- [ ] Production migration rollout is pending.
- [ ] Production frontend deployment is blocked until production DB migration verification passes.

Recommended next milestone:

- Milestone 15E: production rollout planning/execution gate.

## Milestone 15E Member Status Production Rollout

Milestone 15E is complete.

- [x] Production project confirmed: `mzflfyxxkascrfpteexz`.
- [x] Staging project `ckyihuxkioeibzpgwenc` was not touched.
- [x] Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- [x] `20260523000100_member_roster_status_system.sql` was applied to production.
- [x] Production DB verification passed for `roster_status`, `member_status_history`, RLS/policies/grants, backfilled memberships, and `update_member_roster_status(...)`.
- [x] Existing production memberships were backfilled to `roster_status = active`.
- [x] Active Owner count remained `1`.
- [x] `main` was pushed.
- [x] Vercel deployed the Member Status frontend.
- [x] Production Owner smoke validation passed.
- [x] Production Member smoke validation passed.
- [x] Member had no AdminPanel access.
- [x] No CP leakage was found.
- [x] No production roster-status mutation smoke was performed.
- [x] No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.

Operational note:

- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`.
- Future staging/local work must explicitly relink before Supabase commands.

## Milestone 14D Staging Supabase And Vercel Preview Plan

Milestone 14D was documentation-only. No staging project was created, no Supabase commands were run, no Vercel env vars were changed, and no deployment was performed during that checkpoint. Milestone 14E later created/linked staging and applied/verified migrations.

Staging Supabase architecture:

- [x] Create a fresh staging Supabase project only after explicit approval.
- [x] Apply the same 9 migrations as production.
- [x] Use a separate staging Supabase URL.
- [x] Use a separate staging anon/publishable key.
- [x] Use separate staging Auth users.
- [x] Bootstrap a separate staging Owner.
- [x] Allow fake/test users and data only in staging.
- [x] Do not copy production data to staging unless explicitly approved.
- [x] Do not use `db push --include-seed`; core seed data is in migration `20260514000400_seed_core_data.sql`.

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

- [x] Owner.
- [x] Approved Member.
- [x] Admin with `view_audit_logs` but without `view_cp`.
- [x] Admin with both `view_audit_logs` and `view_cp`.
- [x] Wrong-guild Member.
- [x] Pending user.

Future staging validation targets:

- [x] Full GvG smoke test.
- [x] CP audit redaction browser scenario.
- [x] Permission denial flows.
- [x] Wrong-guild access.
- [ ] Cleanup/archive experiments.

Recommended future phases:

- Milestone 14E: create/link staging Supabase, dry-run/apply migrations, verify schema/RLS/seed. Complete.
- Milestone 14F: bootstrap and verify staging Owner. Complete.
- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution. Complete.
- Milestone 14H: staging CP audit redaction and GvG full-smoke validation. Complete.

## Deferred Production Smoke Tests

Deferred by design:

- GvG production smoke was intentionally not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope. Milestone 14H now covers the full GvG smoke in staging.
- CP redaction browser scenario was intentionally not tested in production because the needed production staff/data combination does not currently exist. Milestone 14H now covers the browser scenario in staging.

Preferred future strategy:

- Keep future GvG event/vote experiments in staging unless production execution is explicitly approved.
- Keep future CP audit redaction experiments in staging unless production execution is explicitly approved.
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
