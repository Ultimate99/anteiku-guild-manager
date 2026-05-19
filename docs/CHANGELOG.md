# Changelog

## 2026-05-19 - Milestone 13A Production Supabase Checkpoint

- Production Supabase project was created and linked: `mzflfyxxkascrfpteexz`.
- Production project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations were applied remotely.
- Production schema/RLS/seed verification passed.
- Verified protected tables, RLS, policies, RPCs, grants, indexes, constraints, and seed data.
- Manual Owner bootstrap completed using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.
- Owner profile `ultimatesrb` / `UltimateSRB` is approved in `Anteiku`.
- Exactly one active Owner membership exists.
- `owner_bootstrapped` audit log exists.
- Vercel is not configured.
- Production deployment has not happened.
- Added documentation/handoff checkpoint for Milestone 13B.
- Noted that `package.json` and `package-lock.json` are modified because Supabase CLI was installed locally as dev tooling and should be committed later with a tooling/docs checkpoint.
- No source logic, React files, SQL migrations, CP logic, GvG logic, audit logic, role/guild management logic, permission checkbox logic, Vercel config, deploy, or commit actions were included.

## 2026-05-15 - Milestone 12 Production Readiness Docs

- Added docs-only production readiness runbook/checklist.
- Created `docs/PRODUCTION_CHECKLIST.md`.
- Expanded `docs/DEPLOYMENT.md` with production Supabase, migration, Owner bootstrap, Vercel, preview, and post-deploy validation guidance.
- Refreshed setup and README docs to reflect the current Milestone 11B-complete app state.
- Documented browser-safe Vercel env variables: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Documented that service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- Documented production migration order and forbidden production commands.
- Documented that `supabase/tests/local_validation_anteiku.sql` must not run against production because it inserts fake auth users/test data.
- Documented the `supabase/config.toml` missing `seed.sql` hazard and that core seed data currently comes from migration `20260514000400_seed_core_data.sql`.
- Updated ai_agents handoff docs for Milestone 12 completion and Milestone 13 readiness.
- No source logic, React files, SQL migrations, deployment, dependencies, or commits were included.

## 2026-05-15 - Milestone 11B Audit Log Viewer Validation Passed

- Manual live browser validation passed for the AdminPanel Audit Logs section.
- Owner loaded logs, used filters, and used Load Older successfully.
- Leader/Vice and Admin with `view_audit_logs` saw scoped logs only.
- Admin without `view_audit_logs`, normal Member, and pending user could not access audit logs.
- CP-sensitive metadata was hidden for users without `view_cp`.
- CP metadata appeared only for an authorized `view_cp` user when the backend returned it.
- Network validation after clearing initial AdminPanel load showed `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- Empty/error states, metadata rendering, filters, and mobile layout passed.
- No bugs or incomplete tests were reported.
- Milestone 11B is complete.

## 2026-05-15 - Milestone 11B Audit Log Viewer Implemented

- Added frontend-only, read-only AdminPanel Audit Logs section.
- Added isolated `src/services/adminAuditService.js`.
- Audit reads use only `public.get_audit_logs(...)`.
- Added refresh, action filter, safe/simple guild filter, date from/to filters, limit selector, and load older pagination.
- Added loading, error, empty, and not-authorized states.
- Audit cards show action, timestamp, actor, optional target, guild/global scope, entity table/id, safe metadata summary, and CP redaction notice.
- Metadata rendering is whitelist-based and does not dump raw metadata JSON.
- Redacted CP-sensitive rows show `Sensitive CP metadata hidden.`
- No SQL migrations, `get_audit_logs` changes, CP logic, role/guild logic, permission checkbox logic, GvG logic, dependencies, deploy, or commit were included.
- `npm.cmd run build` passed.
- Source validation confirmed no direct frontend `audit_logs` table calls, no CP RPC/table calls in the audit viewer path, and no audit write/update/delete/export UI.
- Manual browser validation later passed; Milestone 11B is complete.

## 2026-05-15 - Milestone 11A Audit Log Read Hardening Validated

- Added backend-only audit log read hardening.
- Added `public.get_audit_logs(...)` as the safe audit reader RPC.
- Restricted direct non-Owner `audit_logs` SELECT.
- Added SQL-side CP metadata redaction for audit viewers without scoped `view_cp`.
- Kept audit writes, CP update logic, role/guild logic, permission checkbox logic, GvG logic, and frontend UI unchanged.
- Updated local validation with audit visibility, redaction, direct table read, private audit writer grant, and audit spoof checks.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 11A validation passed with 14 PASS / 0 FAIL / 0 SKIP.
- Milestone 11B frontend audit log viewer was implemented later as a separate frontend-only pass.

## 2026-05-15 - Milestone 10 GvG Validation Passed

- Corrected live browser validation passed for GvG event management and member voting persistence.
- Build passed with `npm.cmd run build`.
- Owner event creation, voting open, and voting close were validated.
- Same-guild Member voting was validated for Present, Absent with reason, and switching back to Present.
- Read-only SQL confirmed one vote row per event/profile, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff can see present/absent counts and absence reasons.
- Normal Members cannot see other users' absence reasons.
- Admin without `manage_gvg`, wrong-guild Member, and out-of-scope staff denial paths passed.
- Closed events reject vote changes.
- Network validation confirmed GvG actions use only GvG RPCs/safe reads after clearing Network.
- No CP RPC/table calls were triggered by GvG actions.
- No direct frontend writes to `gvg_votes` or `gvg_events` were observed.
- No bugs, security issues, or incomplete validation items were reported.

## 2026-05-15 - Milestone 10 GvG UI Implemented

- Added isolated GvG service.
- Added persistent member GvG voting UI.
- Added AdminPanel GvG event management/results section.
- Member voting uses `submit_gvg_vote`.
- Event management uses `create_gvg_event` and `set_gvg_event_status`.
- Staff results use `get_gvg_results`.
- No direct GvG vote writes were added.
- No CP, role/guild, permission checkbox, SQL, or package changes were made.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 9 Permission Management Validation Passed

- Manual browser validation passed for Admin permission checkbox management.
- Owner permission management validated, including CP permissions.
- Leader scoped non-CP permission management validated.
- CP permissions remain Owner-only.
- Admin users do not get Permission Management UI.
- Member users do not get Admin tab.
- Network writes used only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes were found.
- No CP data/RPC calls occurred during permission-management actions.
- No GvG logic was touched.

## 2026-05-15 - Milestone 9 Permission Management Implemented

- Added Admin permission checkbox management UI.
- Added isolated permission management service.
- Permission checkboxes apply only to active Admin memberships.
- Owner can manage all Admin permissions.
- Leader/Vice can manage non-CP Admin permissions inside assigned guild scope.
- CP permission checkboxes are disabled for Leader/Vice.
- Writes use only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes were added.
- No CP data/RPC calls were added by permission management.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Frontend CP Validation Passed

- Manual browser validation passed for Admin-only CP management and leaderboard.
- Owner can view CP roster, update CP, and view leaderboard.
- Missing CP displays as "Not entered".
- Invalid CP inputs are blocked.
- Normal Member cannot see Admin tab or CP UI.
- CP does not appear on Dashboard/Profile/member-facing pages.
- Network validation confirmed CP uses only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found.
- No GvG logic was touched.
- Recorded local stale-session note after DB reset.

## 2026-05-15 - Milestone 8 Frontend CP UI Implemented

- Added isolated admin CP service.
- Added AdminPanel CP Management section.
- Added CP roster through `get_current_cp_roster`.
- Added CP leaderboard through `get_cp_leaderboard`.
- Added CP update controls through `update_member_cp`.
- Missing CP displays as `Not entered`.
- CP remains isolated from Dashboard, Profile, member-facing pages, and normal member roster cards.
- No direct `member_cp` / `cp_snapshots` reads or writes were added.
- No GvG logic was changed.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Backend CP Hardening Validation Passed

- Local validation passed for backend CP hardening.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- CP update for pending/rejected/suspended profiles is blocked.
- CP update for approved active profile works.
- Admin with `update_cp` cannot update CP for non-approved profiles.
- CP roster includes approved active members with missing CP as `null`.
- Members and Admins without `view_cp` cannot read CP.
- Direct `member_cp` / `cp_snapshots` access remains blocked.
- CP update audit logging works.
- No GvG logic changed.

## 2026-05-15 - Milestone 8 Backend CP Hardening Implemented

- Added CP hardening migration.
- `update_member_cp` now requires approved target profiles.
- `get_current_cp_roster` now includes active approved members without CP rows.
- Missing CP is returned as `null`.
- Added local validation checks for non-approved CP update denial, missing CP roster rows, CP read denial, direct CP table access denial, and CP audit logs.
- No frontend, package, GvG, or direct CP policy changes were made.
- Local validation is pending.

## 2026-05-15 - Milestone 7 Frontend Validation Passed

- Manual browser validation passed for Admin member role and guild management.
- Owner role changes, Owner-only guild transfer, and transfer role reset behavior were validated.
- Leader scoped permissions were validated.
- Normal Member still cannot access Admin tab.
- Network writes used only `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were observed.

## 2026-05-15 - Milestone 7 Frontend Role/Guild UI Implemented

- Added Admin member role-change UI using `assign_member_role`.
- Added Owner-only member guild-transfer UI using `transfer_member_guild`.
- Added safe active guild option reads for transfer targets.
- Kept Owner assignment out of frontend UI.
- Kept transfer UI Owner-only in v1.
- Confirmed no direct table writes were added.
- Confirmed no CP/GvG access was added.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 7 Backend Validation Passed

- Local Supabase validation passed after backend role/guild SQL changes.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Role assignment tests passed.
- Guild transfer tests passed.
- Owner-only guild transfer behavior validated.
- Owner assignment remains blocked through normal app RPC.
- Transfer audit logs and role-change audit logs are written.
- No CP/GvG logic was changed.

## 2026-05-15 - Milestone 7 Backend Role/Guild SQL Prepared

- Added backend migration for normal app role assignment hardening.
- Added Owner-only member guild transfer RPC.
- Updated local validation SQL with role assignment and guild transfer checks.
- Documented that Owner assignment remains manual-only and is not exposed through normal app RPC.
- No frontend, package, CP, or GvG changes were made.
- Local Supabase validation is pending.

## 0.1.0

- Added Milestone 1 scaffold for React + Vite.
- Added documentation-first security notes.
- Added placeholder Supabase client configuration.
- Completed local Milestone 1 validation with `npm.cmd install` and `npm.cmd run build`.
- Recorded development-only Vite/esbuild audit issue without upgrading Vite.
- Documented approved Milestone 2 schema/RLS decisions for future migrations.
- Recorded CP privacy, role permission, GvG, Owner bootstrap, reapply, audit visibility, and constraint decisions.
- Added Supabase SQL migrations and local validation script.
- Fixed private helper parameter shadowing that caused CP/RPC permission leakage during validation.
- Completed Milestone 2 local Supabase validation: 29 PASS / 0 FAIL / 0 SKIP.
- Added Milestone 3 local Supabase frontend auth integration.
- Fixed AuthContext loading state issue caused by async auth-state handling.
- Completed Milestone 3 manual browser validation for register, pending gating, signin/signout, session restore, and no frontend CP calls.
- Added Milestone 4 frontend registration approval/rejection UI and service.
- Approval workflow uses current RLS-safe reads plus `approve_registration` and `reject_registration` RPC writes only.
- Kept Owner assignment out of the frontend approval UI and left Owner bootstrap manual-only.
- Completed Milestone 4 build validation with `npm.cmd run build`; full Owner browser testing awaits local Owner bootstrap.
- Fixed approved app shell missing Sign out control by adding Sign out to the `AppShell` header.
- Completed Milestone 4 manual browser validation after local Owner bootstrap: Owner approval/rejection flow passed, normal member Admin tab stayed hidden, rejected user stayed gated, and no CP UI/data was exposed.
- Added Milestone 5 own-profile IGN editing using the existing `update_my_profile` RPC.
- Kept username, profile slug, guild, role, approval status, and avatar/profile icon locked/display-only in the Profile UI.
- Completed Milestone 5 manual browser validation: Owner and Member can edit own IGN, locked fields stayed read-only/display-only, update used `update_my_profile` only, and no protected CP calls were observed.
- Added Milestone 6 admin member management for active approved members only.
- Added safe roster search/filter UI, admin member IGN edit via `admin_update_member_ign`, and username/profile slug reset via `admin_reset_profile_slug`.
- Completed Milestone 6 manual browser validation: Owner roster access, member IGN edit, username/profile slug reset, normal member Admin denial, and no CP calls passed.
- Recorded Milestone 7 requirement: admin/staff member guild + role management must be planned safely and not patched in quickly.
