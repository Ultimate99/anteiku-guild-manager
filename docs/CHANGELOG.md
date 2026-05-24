# Changelog

## 2026-05-24 - Milestone 17A Password Recovery Flow Implemented

- Implemented frontend/auth UX for required password reset after Supabase recovery links.
- Added password reset email request and recovered-password update wrappers.
- Added Supabase `PASSWORD_RECOVERY` handling, recovery URL fallback detection, and a sessionStorage recovery marker.
- Added a `Set new password` screen that blocks normal app navigation while recovery mode is active.
- Added a forgot-password mode to the sign-in screen with neutral reset-email copy.
- Preserved existing approval, membership, roster status, role/guild/permission, CP, GvG, and audit behavior.
- `npm.cmd run build` passed.
- Local browser smoke confirmed forgot-password UI, recovery-gated reset screen, blocked normal navigation, sign-out recovery cleanup, and no captured console warnings/errors.
- No SQL migrations, Supabase/RLS/RPC logic, Vercel env, deployment, or commit action was performed.
- Real staging recovery-email validation remains pending before production rollout.

## 2026-05-24 - Milestone 16D.1 AdminPanel Compact Roster Implemented

- Implemented frontend-only AdminPanel compact member cards and technical text cleanup.
- Changed Members tab from tall always-open cards to compact roster rows.
- Added per-member `Manage` disclosure areas for IGN editing, username reset, roster status, role, and guild-transfer controls.
- Preserved hard-block status reason/confirmation flow and transfer warnings.
- Removed visible environment/status pill copy such as `Supabase configured`.
- Shortened auth, dashboard, GvG, pending, and rejected-state copy.
- Preserved the Permissions copy fix for `Reset username/username`.
- `npm.cmd run build` passed.
- Static checks found no service, SQL migration, Supabase test, protected table, or unsafe GvG write changes.
- Authenticated staging browser validation passed for Owner Members compact rows, expanded Manage controls, and CP/GvG/Audit/Permissions/Tools rendering.
- `.env.local` was restored to local Supabase and Vite was restarted after validation.
- No production, deployment, Vercel env, SQL, Supabase/RLS/RPC, service behavior, or commit action was performed.

## 2026-05-24 - Milestone 16C Authenticated AdminPanel Validation Passed

- Authenticated AdminPanel/UI validation passed against staging through the local frontend.
- Validated Owner AdminPanel tabs, Members status UI, CP, GvG, Audit Logs, Permissions, Tools, and mobile AdminPanel layout.
- Validated restricted admin, normal member, pending user, audit no-CP, audit+CP, and wrong-guild staging accounts.
- Confirmed CP redaction still shows `Sensitive CP metadata hidden.` for users without `view_cp`.
- Confirmed permitted CP audit metadata is visible for the `view_cp` audit account.
- Rephrased user-facing "Profile slug" UI copy to "Username".
- Adjusted limited-admin AdminPanel shell copy to avoid naming unavailable tools.
- `npm.cmd run build` passed after validation fixes.
- Source/security-path validation found no service, SQL migration, Supabase test, protected table, or unsafe GvG write changes.
- `.env.local` was restored to local Supabase settings after validation.
- Vite was restarted locally after the environment restore.
- Staging test credentials were not stored in docs/source.
- No production, Vercel env, deployment, SQL, Supabase/RLS/RPC, service, or commit action was performed.

## 2026-05-24 - Milestone 16B AdminPanel UI Cleanup Implemented

- Implemented a frontend-only AdminPanel UI/copy cleanup.
- Shortened AdminPanel shell copy and removed implementation-facing wording from AdminPanel UI text.
- Tightened Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools tab copy.
- Added compact AdminPanel styling for cards, empty states, metadata rows, controls, tabs, and narrow mobile layout.
- Preserved destructive confirmations, hard-block member-status confirmation/reason flow, CP redaction notice, transfer reset warning, and permission-denial meaning.
- Preserved existing service/RPC paths and behavior; no SQL migrations, Supabase/RLS/RPC logic, CP, GvG, audit, role/guild, permission, or member-status behavior changed.
- `npm.cmd run build` passed.
- Static source checks found no service changes, no Supabase migration/test changes, no new direct protected CP/audit/history table calls, and no unsafe GvG writes.
- Local app loaded at `http://localhost:5173/` with no captured console warnings/errors on the unauthenticated page.
- Authenticated AdminPanel browser validation remains pending before rollout.
- No deployment or commit was performed.

## 2026-05-24 - Milestone 15E Member Status Production Rollout Complete

- Applied `20260523000100_member_roster_status_system.sql` to production only after dry-run showed it was the only pending migration.
- Verified production DB schema/RLS/RPC state for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, indexes, and backfilled memberships.
- Confirmed production memberships were backfilled to `roster_status = active`.
- Confirmed active Owner count remains `1`.
- Pushed `main` and Vercel deployed the Member Status frontend.
- Production smoke validation passed for Owner AdminPanel Members status UI, CP tab, Audit Logs, GvG, Member Dashboard/Profile/GvG, Member AdminPanel denial, and CP non-leakage.
- No production roster-status mutation smoke was performed.
- Optional future production mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; future staging/local work must explicitly relink before Supabase commands.

## 2026-05-24 - Milestone 15D Member Status Staging Validation Passed

- Applied `20260523000100_member_roster_status_system.sql` to staging only after a dry-run showed it was the only pending migration.
- Verified staging schema/RLS for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, backfilled memberships, and active Owner count.
- Browser-validated the Milestone 15B frontend through staging users.
- Confirmed Owner Members tab roster badges, status filter, and status controls worked.
- Tested `staging_member` through `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, and restored `active`.
- Confirmed `suspended` blocks member/admin areas with a restricted notice.
- Confirmed `on_break` allows Home/Profile and shows not expected for GvG with no vote controls.
- Confirmed `staging_admin_noperms` has no Members/status/CP/Audit/GvG management controls.
- Verified final `staging_member` state: `membership_status = active`, `roster_status = active`.
- Verified 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows from validation.
- Source-path validation still shows status updates use only `update_member_roster_status`, with no direct frontend `guild_memberships` writes, no frontend `member_status_history` calls, no new direct `member_cp`/`cp_snapshots`/`audit_logs` calls, and CP privacy unchanged.
- Restored `.env.local` to local Supabase and restarted Vite locally.
- Production, Vercel env, deployment, and commit actions were not performed.
- Production rollout later completed in Milestone 15E.

## 2026-05-23 - Milestone 15B Member Status Frontend Implemented

- Implemented frontend Member Status UI/access gating locally.
- Added safe frontend `roster_status` reads for current viewer membership and Admin Members roster.
- Added roster status badges, filter, status change control, reason input, and hard-block confirmation to Admin Members.
- Added `updateMemberRosterStatus(...)` frontend wrapper using only `update_member_roster_status`.
- Added Dashboard/Profile roster status badges and safe notes without adding CP reads.
- Added roster hard-block restricted notice for `suspended`, `left`, and `kicked`.
- Updated GvG UX so `inactive` and `on_break` users do not get vote controls.
- Preserved private status history/reason privacy; no `member_status_history` UI was added.
- `npm.cmd run build` passed.
- Source/security checks found no direct frontend `guild_memberships` updates, no direct `member_status_history` calls, and no new direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- Browser validation later passed through staging in Milestone 15D.
- This frontend was later deployed to production in Milestone 15E after the production migration was applied and verified.
- No SQL migrations, backend/RLS/RPC changes, production, Vercel env, deployment, or commit action was included.

## 2026-05-23 - Milestone 15A Member Status Backend Complete

- Added backend Member Status support.
- Added migration `20260523000100_member_roster_status_system.sql`.
- Added `guild_memberships.roster_status` with statuses `active`, `trial`, `inactive`, `on_break`, `suspended`, `left`, `kicked`, and `pending_transfer`.
- Added private `member_status_history` table for staff-only reasons/history.
- Added `update_member_roster_status(...)` RPC.
- Added `member_roster_status_changed` audit logging without private reason text in audit metadata.
- Added GvG eligibility protection: `inactive` and `on_break` keep active membership but cannot see/vote on active GvG events; `trial` remains eligible.
- Mapped hard-block statuses:
  - `suspended` -> `membership_status = 'suspended'`
  - `left` -> `membership_status = 'left'`
  - `kicked` -> `membership_status = 'left'`
- Local validation passed:
  - `npx.cmd supabase db reset`
  - `supabase/tests/local_validation_anteiku.sql`
  - Milestone 15A: 22 PASS / 0 FAIL / 0 SKIP
- No React/frontend UI, production Supabase, Vercel env, deployment, or commit action was included.

## 2026-05-23 - Milestone 14H Staging CP Redaction And GvG Smoke Complete

- Completed staging CP audit redaction browser validation.
- Completed staging CP metadata visibility validation for a scoped `view_cp` user.
- Completed staging GvG full smoke validation.
- Completed staging permission denial, wrong-guild denial, and pending lockout checks.
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` saw `Sensitive CP metadata hidden.` and did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke`.
- `staging_member` voted Present, switched Absent with reason, then switched back Present.
- Owner closed the GvG event.
- Read-only SQL confirmed exactly one `gvg_votes` row with final status `present` and `absence_reason = null`.
- `staging_wrongguild` could not see or vote on the Anteiku event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.
- Active Owner count remained `1`.
- Deferred production GvG smoke and CP audit redaction browser scenarios are now covered in staging.
- Recorded network caveat: literal DevTools request capture was unavailable through browser automation, but source-path inspection confirmed approved RPC usage. This is not a 14H blocker.
- Test data remains in staging intentionally.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-23 - Future CP Update Window / Member CP Self-Submit Roadmap Note

- Recorded future CP-focused milestone candidate: CP Update Window / Member CP Self-Submit.
- Corrected future CP privacy rule: members may see their own CP through safe backend/RPC flow, but must not see other members' CP.
- Recorded that members must not see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Recorded future backend-first direction: `cp_update_windows` plus safe RPCs such as `create_cp_update_window`, `set_cp_update_window_status`, `get_active_cp_update_window_for_me`, `get_my_cp`, and `submit_my_cp_update`.
- Recorded security requirements for self-only CP submission, database/server-time window checks, guild/scope checks, audit logging, and audit metadata redaction.
- Recorded future frontend surfaces for AdminPanel CP window controls and Member Profile "Your CP".
- No source code, SQL migrations, Supabase/RLS/RPC behavior, production data, deployment, or commit action was included.

## 2026-05-23 - Milestone 14F Staging Owner Bootstrap Complete

- Completed and verified staging Owner bootstrap for `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Recorded staging Owner Auth UUID `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Recorded staging Owner email `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Recorded username/profile slug `staging_owner` and IGN `Staging Owner`.
- Verified Owner membership in `Anteiku` with role `owner`, status `active`, and primary membership `true`.
- Verified `active_owner_count = 1`.
- Verified `owner_bootstrapped` audit log count is `1`.
- Recorded that no controlled staging test users existed at the 14F checkpoint.
- Recorded that Vercel Preview remains unconfigured.
- Recorded next milestone recommendation: Milestone 14G staging controlled test users plus permission matrix setup planning/execution.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-23 - Milestone 14E Staging Supabase Verification Complete

- Completed staging Supabase migration/apply/verification.
- Recorded staging project `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Applied and verified the same 9 migrations as production.
- Verified staging schema/RLS/seed state.
- Confirmed permission catalog count is 10 and exactly matches `20260514000400_seed_core_data.sql`.
- Confirmed the earlier "7 permissions" report was a partial summary mistake.
- Recorded that `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.
- Recorded that no staging Owner or test users existed at the 14E checkpoint.
- Recorded next milestone recommendation: Milestone 14F staging Owner bootstrap planning.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-22 - Milestone 14D Staging And Preview Planning Docs

- Added documentation-only staging Supabase + Vercel Preview planning.
- Documented future staging architecture: fresh Supabase project, same 9 migrations as production, separate URL, separate anon/publishable key, separate Auth users, separate Owner bootstrap, and staging-only fake/test data.
- Documented that production data must not be copied into staging unless explicitly approved.
- Documented Vercel Preview env policy: Production env remains production-only; Preview env should point only to staging Supabase when staging exists.
- Documented allowed Preview env vars: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Documented forbidden frontend/Vercel env values: service role keys, database passwords/URLs, `sb_secret_*` keys, JWT secrets, SMTP secrets, and OAuth/provider secrets.
- Documented Auth URL strategy: production Site URL remains `https://anteiku-guild-manager.vercel.app`, production redirects stay production-only, and Preview wildcard redirects belong only in staging Supabase if needed.
- Documented future staging test users and moved deferred GvG smoke, CP audit redaction, permission denial, wrong-guild access, and cleanup/archive experiments to staging.
- Documented future phases: 14E staging Supabase create/link/migrate/verify, 14F Vercel Preview env + staging Auth URLs, and 14G staging validation.
- No staging project was created, no Supabase commands were run, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-22 - Milestone 14C AdminPanel Tabs Production Rollout Complete

- Refactored AdminPanel into a frontend-only tabbed coordinator plus section components.
- Added AdminPanel tabs for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Added mobile-first sticky horizontal tab styling with dark/crimson Anteiku styling.
- Rendered only the active AdminPanel section.
- Lazy-loaded CP, Audit Logs, and GvG management data when their tabs are opened instead of on initial AdminPanel render.
- Preserved existing security paths: Audit Logs use `get_audit_logs`, CP uses approved CP RPCs, and GvG uses approved RPCs/safe reads.
- `npm.cmd run build` passed.
- Source validation found no direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- Local browser/network validation passed: CP used approved CP RPCs only, Audit Logs used `get_audit_logs` only, GvG used safe GvG paths only, and no direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- The committed/pushed `main` build was deployed by Vercel.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Production smoke validation passed: Owner login, AdminPanel open, visible tabs, Owner switching through Approvals/Members/CP/GvG/Audit Logs/Permissions/Tools, Audit Logs load, CP load, mobile tab usability, and Member AdminPanel denial.
- No SQL migrations, Supabase schema/RLS/RPC logic, CP logic, GvG logic, audit logic, role/guild behavior, permission checkbox behavior, Vercel env, deployment, or commit actions were changed during the final documentation checkpoint.
- Milestone 14C is complete in production.

## 2026-05-20 - Milestone 14B Vercel GitHub App Restriction Checkpoint

- Recorded user-confirmed Vercel GitHub App restriction to only `Ultimate99/anteiku-guild-manager`.
- Recorded that the Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Verified production URL still loads at `https://anteiku-guild-manager.vercel.app`.
- Browser health check loaded title `Anteiku Guild Manager` and showed no captured console errors.
- Recorded that no Vercel env vars, source logic, SQL migrations, Supabase schema/RLS/RPC, deployment, or commit actions were changed during this checkpoint.

## 2026-05-20 - Milestone 14A Production Hardening Policy Docs

- Added documentation-only production hardening and cleanup policy guidance.
- Documented manual Vercel GitHub App restriction checklist for repository-only access to `Ultimate99/anteiku-guild-manager`.
- Recorded that no Vercel settings, GitHub App settings, production commands, source logic, SQL migrations, deployment, user cleanup, or commit actions were performed.
- Recorded controlled production test member policy for `krsticmiroslav99+m13b21144225@gmail.com`: keep documented for now, do not hard-delete, preserve validation/audit history, and require explicit approval for cleanup.
- Documented Preview/Staging policy: Production env only for Production deployments, Preview env unconfigured until staging exists, future staging Supabase must be separate, and broad production redirect wildcards should be avoided.
- Recorded deferred production smoke tests: GvG production smoke deferred to avoid persistent production test data, and CP redaction browser scenario deferred due missing staff/data setup.
- Added launch operations checklist for member approvals, audit monitoring, CP updates, GvG event safety, admin permission safety, and production SQL safety.

## 2026-05-19 - Milestone 13B Production Deployment Validation Passed

- Vercel setup completed for `Ultimate99/anteiku-guild-manager` on production branch `main`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel framework preset: Vite.
- Vercel build command: `npm run build`.
- Vercel output directory: `dist`.
- Production env uses only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- No service role key, database password/URL, JWT secret, SMTP/OAuth/provider secret, or `sb_secret_*` key was added to frontend/Vercel env.
- Supabase Auth Site URL and Redirect URL allow-list were configured for `https://anteiku-guild-manager.vercel.app`.
- Production smoke/security validation passed for Owner login, AdminPanel, Audit Logs, CP Management, pending user lockout, Member approval, Member CP denial, mobile layout, and manual Network checks.
- Audit Logs Network validation observed `rpc/get_audit_logs`; no direct `/rest/v1/audit_logs`, CP calls, or audit write/update/delete/export calls were observed.
- CP Management Network validation observed approved CP RPCs only; no direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls after clearing Network.
- Controlled production test member remains in production as an approved Member: `krsticmiroslav99+m13b21144225@gmail.com` / `m13bmember21056302`.
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- CP redaction browser test was intentionally not tested because no current production staff/data combination exists for the scenario; Milestone 11A backend validation covered CP metadata redaction.
- Recommendation recorded to restrict Vercel GitHub App access to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, Vercel env changes after validation, redeploy, or commit were included in the final documentation checkpoint.

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
- At the time of the Milestone 13A checkpoint, Vercel was not configured yet.
- At the time of the Milestone 13A checkpoint, production deployment had not happened yet.
- Added documentation/handoff checkpoint for Milestone 13B.
- Supabase CLI was installed locally as dev tooling during Milestone 13A; the CLI tooling/package changes were committed before Milestone 13B planning/execution.
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
