# Session Log

## 2026-05-24 - Milestone 20E CP Leaderboard Staging Rollout and Validation

- Completed staging-only CP Leaderboard rollout and validation.
- Confirmed Supabase CLI linked to staging project `ckyihuxkioeibzpgwenc`.
- Confirmed production project `mzflfyxxkascrfpteexz` was not linked or used.
- Staging dry-run showed only `20260524000300_cp_rankings.sql` pending.
- Applied only `20260524000300_cp_rankings.sql` to staging.
- Remote migration list confirmed `20260524000300` applied.
- Verified ranking RPCs exist and authenticated execute grants are present.
- Verified member ranking shape contains no CP/private fields.
- Verified Owner admin ranking returns CP values and non-Owner global admin ranking is denied.
- Verified pending ranking access and Admin-without-CP ranking access are denied.
- Browser-validated `staging_member` My Guild and Global member rankings with no CP values.
- Browser-validated Owner AdminPanel CP roster/window controls and separate `CP Ranking` tab with Guild/Global admin rankings.
- Browser-validated `staging_admin_noperms` restricted state with no CP/CP Ranking access.
- Fixed a staging validation UI finding by moving AdminPanel CP leaderboard out of the bottom of the CP tab into its own `CP Ranking` AdminPanel tab.
- `npm.cmd run build` passed after the UI placement fix.
- `.env.local` was restored to local Supabase after validation.
- No production, Vercel env, deployment, commit, SQL migration edit, or new migration action was performed.

## 2026-05-24 - Milestone 20D AdminPanel CP Leaderboard Upgrade Implemented

- Implemented frontend-only AdminPanel CP leaderboard upgrade.
- Updated AdminPanel CP loading to use `get_admin_cp_rankings`.
- Added separate AdminPanel `CP Ranking` tab with Guild / Global tabs.
- Guild tab uses the selected CP guild scope.
- Global tab is visible only to Owner in the frontend; backend RPC authorization remains the authority.
- Added compact decorated admin rank rows with rank, IGN, username, guild, CP value, and last updated.
- Added top-rank, Elite 5, and Top 10 row decoration for admin rows.
- Added EN/FR/DE i18n labels for admin leaderboard scope, rank, guild, last updated, empty, and permission/error states.
- Preserved existing CP roster, manual CP update, and CP Update Window controls.
- Preserved member-facing CP Ranking page behavior.
- `npm.cmd run build` passed.
- Static source checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.
- Static source checks confirmed the member leaderboard still uses only `get_member_cp_rankings`.
- Authenticated AdminPanel CP leaderboard browser validation remains pending until staging receives `20260524000300_cp_rankings.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, CP Update Window behavior, member CP Ranking behavior, GvG, audit, role, permission, member-status behavior, production, staging, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 20C Member CP Leaderboard Frontend Implemented

- Implemented frontend-only member-facing CP Ranking page.
- Added `src/services/cpLeaderboardService.js` with a wrapper for `get_member_cp_rankings(p_scope)`.
- Added `src/pages/Leaderboard.jsx`.
- Added a member nav item and app routing entry for CP Ranking.
- Added My Guild and Global tabs.
- My Guild shows rank and IGN.
- Global shows rank, IGN, and guild label.
- Added current-user row highlighting.
- Added top-rank, Elite 5, and Top 10 row decoration styles.
- Added EN/FR/DE i18n labels for the member leaderboard.
- Added compact mobile-first leaderboard styling.
- Confirmed the member leaderboard path does not call admin CP rankings, admin CP roster, admin CP leaderboard, or direct CP tables.
- `npm.cmd run build` passed.
- Local browser smoke loaded the unauthenticated app shell at `http://127.0.0.1:5173/`.
- Authenticated leaderboard browser validation remains pending until staging receives `20260524000300_cp_rankings.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, AdminPanel CP behavior, CP Update Window behavior, GvG, audit, role, permission, member-status behavior, production, staging, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 20B CP Leaderboard Backend Implemented

- Implemented backend/database-only CP Leaderboard support.
- Created migration `supabase/migrations/20260524000300_cp_rankings.sql`.
- Added member-safe RPC `get_member_cp_rankings(p_scope text default 'guild')`.
- Added admin/staff RPC `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
- Added ranking support indexes on `member_cp`.
- Member rankings return rank order only: `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member rankings do not return CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, or audit metadata.
- Admin guild rankings require existing scoped `view_cp` authority and return CP values only to authorized staff.
- Admin global rankings are Owner-only in v1.
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.
- Ranks use deterministic `row_number()` order by `cp_value desc`, then IGN/profile tie-breaker.
- Updated local validation SQL with Milestone 20B checks.
- Local `npx.cmd supabase db reset` passed.
- `npx.cmd supabase db query --local --file supabase/tests/local_validation_anteiku.sql` could not run the multi-statement validation file, so the validation SQL was executed through Docker `psql`.
- Local validation passed, including Milestone 20B result 14 PASS / 0 FAIL / 0 SKIP.
- Existing Milestone 19B and 19B.1 CP Update Window validation still passed.
- No frontend UI, React component, service behavior, staging, production, Vercel, deployment, or commit action was performed.
- `20260524000300_cp_rankings.sql` remains local-only; do not deploy frontend CP leaderboard UI until each target DB has the migration applied and verified.

## 2026-05-24 - Milestone 19E CP Update Window Production Rollout Complete

- Completed Milestone 19E production rollout for CP Update Window / Member CP Self-Submit.
- Confirmed clean working tree and latest commit `6a3a181 feat: add CP update window self-submit` before rollout.
- Relinked Supabase CLI to production project `mzflfyxxkascrfpteexz`; staging project `ckyihuxkioeibzpgwenc` was not used.
- Production dry-run showed only `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.
- Applied both migrations to production and verified both are present remotely.
- Verified production `cp_update_windows` table, RLS, one-open-window unique index, safe RPC existence/grants, direct grant absence, `member_cp_self_submitted` redaction handling, and active Owner count `1`.
- Pushed `main`; Vercel deployed commit `6a3a181`.
- Production Owner smoke passed for AdminPanel CP tab and CP Update Window block showing `Closed`.
- Production Member smoke passed for Profile `Your CP` card, own-CP-only display, closed-window message, no Admin navigation, and no CP roster/leaderboard exposure.
- Captured console errors were empty for the checked Owner/member paths.
- Static source checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls and no Profile/admin CP roster/leaderboard calls.
- Controlled production CP mutation smoke was not performed by design; no production CP window was opened/closed and no production CP value was submitted.
- Supabase CLI remains linked to production and must be relinked before future staging/local Supabase commands.

## 2026-05-24 - Milestone 19C CP Update Window Frontend Implemented

- Implemented Milestone 19C as a frontend-only local integration for CP Update Window / Member CP Self-Submit.
- Added `src/services/cpWindowService.js` with RPC-only wrappers for `get_my_cp`, `get_active_cp_update_window_for_me`, `submit_my_cp_update`, `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.
- Added Profile `Your CP` UI that reads only the signed-in member's own CP and active window status.
- Added member CP self-submit using only `submit_my_cp_update(...)`, with local required/numeric/non-negative validation and success/error refresh behavior.
- Added AdminPanel CP Update Window status/open/close controls for the selected CP guild.
- Added EN/FR/DE i18n keys for member CP, admin CP window controls, and new CP-window audit labels.
- Added compact styling for the Profile CP panel and Admin CP window block.
- `npm.cmd run build` passed.
- Static source checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.
- Static source checks confirmed Profile and `cpWindowService` do not call admin CP roster/leaderboard RPCs.
- Local unauthenticated browser smoke loaded the auth page with no captured console errors.
- No SQL migrations, Supabase/RLS/RPC logic, services beyond the new display/RPC wrapper, staging, production, Vercel, deployment, or commit action was performed.
- Authenticated staging validation remains pending because staging does not yet have migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.

## 2026-05-24 - Milestone 19B.1 CP Update Window Staff Read RPC Implemented

- Implemented Milestone 19B.1 as a backend/database-only follow-up.
- Added migration `20260524000200_cp_update_window_staff_read.sql`.
- Added `get_cp_update_window_for_guild(p_guild_id uuid)` for safe AdminPanel selected-guild CP Update Window status.
- The RPC returns open window first, otherwise latest closed window, otherwise no row.
- Authorized staff are Owner, scoped Leader/Vice, or scoped Admin with `view_cp` or `update_cp`.
- Member, wrong-guild, and Admin-without-CP-permission access is denied.
- No direct `cp_update_windows` table grants or frontend access were added.
- Updated local validation SQL with Milestone 19B.1 checks.
- `npx.cmd supabase db reset` passed.
- Local validation passed, including Milestone 19B.1 result 13 PASS / 0 FAIL / 0 SKIP and existing Milestone 19B result 32 PASS / 0 FAIL / 0 SKIP.
- No frontend UI, React components, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 19B CP Update Window Backend Implemented

- Implemented Milestone 19B as a backend/database-only CP Update Window and Member CP Self-Submit foundation.
- Added migration `20260524000100_cp_update_window_self_submit.sql`.
- Added guild-scoped `cp_update_windows` with one-open-window-per-guild enforcement.
- Added RPCs `get_active_cp_update_window_for_me()`, `get_my_cp()`, `submit_my_cp_update(integer)`, `open_cp_update_window(...)`, and `close_cp_update_window(uuid)`.
- Kept member CP privacy RPC-only: members can read only own CP and submit only own CP.
- Kept members blocked from direct `member_cp`, `cp_snapshots`, and `cp_update_windows` table access.
- Added audit actions `member_cp_self_submitted`, `cp_update_window_opened`, and `cp_update_window_closed`.
- Extended `get_audit_logs(...)` redaction so CP old/new metadata from member self-submit rows is hidden unless the viewer has scoped `view_cp`.
- Updated `supabase/tests/local_validation_anteiku.sql` with Milestone 19B checks.
- `npx.cmd supabase db reset` passed.
- Local validation passed, including Milestone 19B result 32 PASS / 0 FAIL / 0 SKIP.
- No frontend UI, React components, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 16H Member-Facing UI Production Rollout Complete

- Completed Milestone 16H production rollout for the member-facing compact UI/copy pass.
- Pushed and deployed commit `53c7907 style: clean up member-facing UI`.
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- EN/FR/DE language switcher worked and persisted after reload.
- Login/Register panels were compact and translated.
- Forgot Password remained visible.
- Production Owner login and AdminPanel access worked.
- Controlled production Member login worked.
- Member Dashboard/Profile/GvG were compact and translated.
- Member had no Admin navigation or AdminPanel access.
- No other-member CP exposure was found.
- No raw translation keys or console errors were captured.
- Mobile/narrow viewport had no horizontal overflow.
- No SQL, Supabase commands, Supabase/RLS/RPC, service behavior, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.

## 2026-05-24 - Milestone 16F Member-Facing UI Compact Pass Implemented

- Implemented Milestone 16F as a frontend-only member-facing UI/copy compact pass.
- Added compact member-facing panel classes for auth, recovery, gate, Dashboard/Home, Profile, and GvG surfaces.
- Tightened app shell, page heading, form, panel, metric, profile, and GvG vote spacing.
- Dashboard/Home now shows compact guild/role/roster/GvG status plus member summary.
- Profile keeps IGN edit behavior and shortens locked-field copy.
- GvG copy is shorter while preserving event loading, eligibility, and vote behavior.
- Pending/rejected/suspended/restricted copy is shorter while preserving lockout meaning.
- Updated EN/FR/DE i18n dictionaries for changed member-facing copy.
- `npm.cmd run build` passed.
- Static checks found no Supabase migration or service changes and no new direct protected table calls.
- Local browser smoke passed for Login/Register/Forgot Password in EN/FR/DE with no raw translation keys, no console errors, and no horizontal overflow.
- Authenticated staging/member validation remains pending as Milestone 16G.
- No SQL, Supabase/RLS/RPC, auth behavior, CP, GvG voting, audit, role/guild/permission, member-status behavior, deployment, or commit action was performed.

## 2026-05-24 - Milestone 18F Language Pack Production Rollout Complete

- Completed Milestone 18F production rollout for the frontend-only language pack.
- Pushed and deployed commit `1f5b956 feat: add English French German language pack`.
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- EN/FR/DE language switcher worked logged out and logged in.
- Selected language persisted after reload.
- Login, registration, and forgot-password copy translated in production.
- Production Owner sign-in worked and AdminPanel opened.
- AdminPanel tabs translated across EN/FR/DE.
- Members, CP, GvG, Audit Logs, Permissions, and Tools tabs rendered in production.
- No raw translation keys were visible.
- No console errors were captured during production smoke.
- Mobile/narrow viewport had no horizontal overflow.
- Existing production Member had no Admin navigation.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.
- No SQL, Supabase/RLS/RPC, service behavior, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.
- Recommended future improvement: French/German admin wording review by native speakers.

## 2026-05-24 - Milestone 18B i18n Foundation Implemented

- Implemented Milestone 18B as a frontend-only language-pack foundation.
- Added English, French, and German dictionaries under `src/i18n/`.
- Added `LanguageProvider`, `useLanguage()`, `t(key, params?)`, English fallback behavior, and `agm_language` localStorage persistence.
- Wrapped the app with `LanguageProvider > AuthProvider > AppContent`.
- Added a compact EN/FR/DE selector in the topbar, visible for logged-out and logged-in users.
- Translated common shell/navigation/auth/register/forgot-password/recovery/status gate surfaces.
- Translated member-facing roster status labels/summaries and core GvG voting copy included in 18B scope.
- Wired basic AdminPanel tab labels only; detailed AdminPanel content remains out of scope for 18B.
- `npm.cmd run build` passed.
- Built-app preview validation passed for EN/FR/DE switching, reload persistence, auth/register/recovery copy, missing-key check, and captured console errors.
- Static checks found no Supabase migration changes and no new protected-table paths in touched files.
- No SQL, Supabase/RLS/RPC, auth behavior, CP/GvG/audit/role/permission/member-status logic, deployment, or commit action was performed.

## 2026-05-24 - Milestone 17D Registration Copy Update Implemented

- Implemented Milestone 17D as a frontend copy/auth UX preparation pass for controlled guild onboarding.
- Updated registration hero copy to `Register for guild approval.`
- Added registration email warning: `Use a real email. You'll need it for password reset.`
- Changed registration submit button to `Request approval`.
- Changed the no-session signup fallback to `If a confirmation email was sent, confirm it first. Your account still needs guild approval.`
- Changed pending screen title to `Awaiting approval.`
- Recorded that production email confirmation remains enabled until a separately approved Auth setting change.
- Recorded staging-first validation instructions for disabling email confirmation in project `ckyihuxkioeibzpgwenc`.
- `npm.cmd run build` passed.
- Static checks found no Supabase migration changes, no service file changes, and no new protected-table paths.
- No SQL, Supabase/RLS/RPC, Supabase Auth setting, Vercel env, role/guild/permission, CP, GvG, audit, member-status, approval, membership, deployment, or commit action was performed.

## 2026-05-24 - Milestone 17C Password Recovery Production Rollout Complete

- Milestone 17C production rollout completed for the Password Recovery Required Reset Flow.
- Pushed and deployed commit `23dd956 fix: require password reset after recovery link`.
- Production smoke passed at `https://anteiku-guild-manager.vercel.app`.
- Forgot-password UI is visible in production.
- Controlled production test member `krsticmiroslav99+m13b21144225@gmail.com` was used for the first production recovery validation.
- Production recovery link opened the app and showed the required `Set new password` gate.
- Normal navigation was blocked before password update.
- Password update succeeded and new password login worked.
- Role/access remained unchanged after reset.
- No passwords, recovery tokens, or secrets were stored in docs/source.
- No SQL, Supabase/RLS/RPC, Supabase Auth settings, Vercel env, CP, GvG, audit, role/guild/permission, member-status, approval, or membership behavior was changed.
- Recommended next milestone: Milestone 17D / 16F Disable email confirmation + registration copy update planning for controlled guild onboarding.

## 2026-05-24 - Milestone 17A Password Recovery Flow Implemented

- Implemented Milestone 17A as a frontend/auth UX fix.
- Added password reset email and recovered-password update wrappers in `authService`.
- Added Supabase `PASSWORD_RECOVERY` handling, recovery URL fallback detection, and a sessionStorage recovery marker in `AuthContext`.
- Added an app-level recovery gate that renders `Set new password` before normal pending/member/admin navigation while recovery is active.
- Added `src/pages/SetNewPassword.jsx` with new password, confirmation, validation, update action, and sign-out escape.
- Added a forgot-password mode to the auth screen with neutral reset-email success copy.
- `npm.cmd run build` passed.
- Local browser smoke confirmed the auth page shows `Forgot password?`, `#type=recovery` forces the reset screen, normal navigation is hidden during recovery, sign-out clears recovery mode, and no console warnings/errors were captured.
- Static checks found no Supabase migration changes and no new protected-table paths.
- No SQL, Supabase/RLS/RPC, profile approval, membership status, roster status, role/guild/permission, CP, GvG, audit, Vercel env, deployment, or commit action was performed.
- Real staging recovery-email validation remains pending before production rollout.

## 2026-05-24 - Milestone 16D.1 AdminPanel Compact Roster Implemented

- Implemented Milestone 16D.1 as a frontend-only AdminPanel compact roster and copy cleanup pass.
- Changed AdminPanel Members from tall always-open cards to compact roster rows with per-member `Manage` disclosure controls.
- Preserved access to IGN editing, username reset, roster status changes, hard-block reason/confirmation flow, role management, and guild transfer.
- Removed the visible environment/status pill copy from the app chrome, including `Supabase configured`.
- Shortened auth, dashboard, GvG, pending, and rejected-state copy.
- Preserved the Permissions display fix so `Reset username/username` formats cleanly.
- `npm.cmd run build` passed.
- Static checks found no service changes and no Supabase migration/test changes.
- Technical-term search found no remaining product-facing UI strings for `Supabase configured`, `RPC`, `RLS`, `backend`, `policies`, `scaffold`, or `milestone`; remaining matches are internal code/config identifiers only.
- Staging browser validation passed with `staging_owner`: compact Members rows rendered, one Manage section expanded, controls remained accessible, CP/GvG/Audit/Permissions/Tools rendered, and no console warnings/errors were captured.
- `.env.local` was restored to local Supabase and Vite was restarted after validation.
- No production, deployment, Vercel env, Supabase command, SQL, service behavior, or commit action was performed.
- Recommended next step: commit checkpoint for 16D.1 when approved, then explicit production rollout planning/execution if desired.

## 2026-05-24 - Milestone 16C Authenticated AdminPanel Validation Passed

- Milestone 16C authenticated browser validation passed against staging through the local frontend.
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- `staging_owner` opened AdminPanel and validated Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, Members badges/filter/status controls, and mobile AdminPanel layout.
- `staging_admin_noperms` saw only safe Tools access and no restricted admin sections.
- `staging_member` had no AdminPanel access, saw no admin UI, and saw no other-member CP exposure.
- `staging_pending` remained locked to the pending approval screen.
- `staging_audit_nocp` could access Audit Logs, did not see CP tools, and saw `Sensitive CP metadata hidden.` without CP values or raw CP metadata keys.
- `staging_audit_cp` could access Audit Logs and permitted CP visibility, including backend-returned `New CP 1,234,567`.
- `staging_wrongguild` remained scoped to Anteiku:Rose and did not see/vote on the Anteiku GvG smoke event.
- Fixed UI copy found during validation: rephrased user-facing "Profile slug" text to "Username".
- Fixed restricted AdminPanel shell copy so limited admins see neutral available-section copy instead of unavailable tool names.
- `npm.cmd run build` passed after validation fixes.
- Source/security-path checks found no service changes, no Supabase migration/test changes, no new direct protected CP/audit/history table calls, and no unsafe GvG writes.
- `.env.local` was restored to local Supabase settings after validation.
- Vite was restarted locally after restoring `.env.local`.
- Staging test credentials were used transiently for validation and were not stored in docs/source.
- No production, Vercel env, deployment, SQL, Supabase/RLS/RPC, service, or commit action was performed.
- Recommended next step: commit checkpoint for Milestone 16B/16C when approved, then Milestone 16D member-facing UI cleanup planning or rollout planning.

## 2026-05-24 - Milestone 16B AdminPanel UI Cleanup Implemented

- Implemented Milestone 16B as a frontend-only AdminPanel UI/copy cleanup.
- Shortened AdminPanel shell copy and removed implementation-facing wording from the AdminPanel UI.
- Tightened Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools copy.
- Added compact AdminPanel styles for cards, empty states, metadata rows, controls, tab spacing, and narrow mobile layout.
- Preserved existing services, RPC call paths, permission gates, CP visibility, GvG flow, audit access, role/guild behavior, and member-status behavior.
- Preserved destructive confirmations, hard-block roster status reason/confirmation flow, CP redaction notice, transfer reset warning, and permission-denial meaning.
- `npm.cmd run build` passed.
- Static checks found no service changes, no Supabase migration/test changes, no new direct protected CP/audit/history table calls, and no unsafe GvG writes.
- Local browser smoke opened `http://localhost:5173/` and found no captured console warnings/errors on the unauthenticated page.
- Authenticated AdminPanel browser validation remains pending because the local app/browser state was unauthenticated.
- No deployment or commit was performed.
- Recommended next step: Milestone 16C authenticated AdminPanel browser validation before rollout.

## 2026-05-24 - Milestone 15E Member Status Production Rollout Complete

- Milestone 15E production rollout completed.
- Production project: `mzflfyxxkascrfpteexz` / `Anteiku Guild Manager Production`.
- Applied only `20260523000100_member_roster_status_system.sql` to production.
- Production DB verification passed for `guild_memberships.roster_status`, default `active`, `NOT NULL`, allowed status check, roster-status index, `member_status_history`, RLS/policies/grants, and `update_member_roster_status(...)`.
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- Pushed commit `23866be feat: add member roster status system` to `main`.
- Vercel deployed the Member Status frontend.
- Production smoke validation passed for Owner Home/Profile/GvG/Admin, Members tab roster status badges/filter/controls, CP tab, Audit Logs, Member Home/Profile/GvG, Member AdminPanel denial, and CP non-leakage.
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke should use the controlled production test member only, require explicit approval, and restore to `active`.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; future staging/local work must explicitly relink before Supabase commands.
- Recommended next options: optional controlled production status mutation smoke, CP Update Window planning, Weekly CP Snapshot/Growth Reports planning, Member status history UI planning, or announcements/onboarding/invite-code planning.

## 2026-05-24 - Milestone 15D Staging Member Status Validation Passed

- Milestone 15D staging migration rollout and browser validation passed.
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Production project `mzflfyxxkascrfpteexz` was not touched.
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending for staging.
- Applied `20260523000100_member_roster_status_system.sql` to staging only.
- Staging schema/RLS verification passed for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, default/backfilled memberships, and active Owner count.
- Milestone 15B frontend is now browser-validated through staging.
- `staging_owner` validated Members tab roster badges, status filter, and status controls.
- `staging_member` was transitioned through `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, and restored to `active`.
- `suspended` showed restricted notice and blocked member/admin areas.
- `on_break` allowed Home/Profile and showed not expected for GvG with no vote controls.
- `staging_admin_noperms` had no Members/status/CP/Audit/GvG management controls.
- Final `staging_member` state was verified as `membership_status = active` and `roster_status = active`.
- Read-only verification found 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows.
- Source-path validation passed: status updates use `update_member_roster_status` only, no direct `guild_memberships` writes, no frontend `member_status_history` calls, no new direct `member_cp`/`cp_snapshots`/`audit_logs` table calls, and CP privacy unchanged.
- `.env.local` was restored to local Supabase settings and Vite was restarted locally.
- No Vercel env vars were changed, no deployment was performed, no commit was made, and no production rollout was attempted.
- Production rollout later completed in Milestone 15E.

## 2026-05-23 - Milestone 15B Member Status Frontend Implemented

- Implemented frontend Member Status UI/access gating locally.
- Added `roster_status` to safe own-membership and admin roster reads.
- Added frontend roster status helpers and `updateMemberRosterStatus(...)` RPC wrapper.
- Admin Members tab now shows roster status badges, roster status filter, and status change controls.
- Hard-block roster status changes require reason input and confirmation.
- Dashboard and Profile show safe roster status badges/notes.
- Added `RosterRestrictedStatus` for roster `suspended`, `left`, and `kicked`.
- GvG page hides vote controls for `inactive` and `on_break` and shows a not-expected/not-eligible message.
- Private `member_status_history` reasons/history are not displayed.
- `npm.cmd run build` passed.
- Static source/security checks passed: no direct `member_status_history`, no direct `guild_memberships` updates, and no new direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- Automated browser validation could not complete because browser automation blocked `http://127.0.0.1:5174/`.
- No SQL migrations, backend/RLS/RPC logic, Supabase tests, production, Vercel env, deployment, or commit actions were included.
- Browser validation later passed through staging in Milestone 15D.

## 2026-05-23 - Milestone 15A Member Status Backend Complete

- Milestone 15A backend/database implementation completed locally.
- Added migration `20260523000100_member_roster_status_system.sql`.
- Added `guild_memberships.roster_status`.
- Added private `member_status_history`.
- Added `update_member_roster_status(...)` RPC.
- Added `member_roster_status_changed` audit logging.
- Added GvG eligibility protection so `inactive` and `on_break` users keep active membership but cannot see/vote on active GvG events.
- Hard-block statuses map to hard membership states:
  - `suspended` -> `membership_status = 'suspended'`
  - `left` -> `membership_status = 'left'`
  - `kicked` -> `membership_status = 'left'`
- Local validation passed:
  - `npx.cmd supabase db reset`
  - `supabase/tests/local_validation_anteiku.sql`
  - Milestone 15A section: 22 PASS / 0 FAIL / 0 SKIP
- No React/frontend UI was implemented.
- No production Supabase project was touched.
- No Vercel env vars were changed.
- No deployment or commit was performed.
- Recommended next milestone: Milestone 15B frontend planning for Member Status UI/access gating.

## 2026-05-23 - Milestone 14H Staging CP Redaction And GvG Smoke Complete

- Milestone 14H staging validation completed.
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` saw `Sensitive CP metadata hidden.` and did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke`.
- `staging_member` voted Present, switched Absent with reason, then switched back Present.
- Owner closed the GvG event.
- Read-only SQL confirmed exactly one `gvg_votes` row for `staging_member` and the event, final status `present`, and `absence_reason = null`.
- `staging_wrongguild` could not see or vote on the Anteiku event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.
- Active Owner count remained `1`.
- Deferred production GvG smoke and CP audit redaction scenarios are now covered in staging.
- Literal DevTools request capture was unavailable through browser automation; source-path inspection confirmed approved RPC usage. This caveat is non-blocking.
- Test data remains in staging intentionally.
- No production Supabase project was touched.
- No Vercel env vars were changed.
- No source files, SQL migrations, new migrations, deployment, cleanup/delete, or commit were included.
- `.env.local` was restored to local Supabase settings after validation.
- Recommended next milestone: Vercel Preview env configuration with staging Supabase, or Member Status System planning.

## 2026-05-23 - Milestone 14F Staging Owner Bootstrap Complete

- Milestone 14F staging Owner bootstrap completed and was verified.
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Staging Owner Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Staging Owner email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild: `Anteiku`.
- Owner membership role is `owner`, status is `active`, and `is_primary = true`.
- `active_owner_count = 1`.
- `owner_bootstrapped` audit log count is `1`.
- No controlled staging test users were created during 14F.
- No production Supabase project was touched.
- No Vercel env vars were changed.
- No source files, SQL migrations, new migrations, deployment, or commit were included.
- Recommended next milestone: Milestone 14G staging controlled test users plus permission matrix setup planning/execution.

## 2026-05-23 - Milestone 14E Staging Supabase Verification Complete

- Milestone 14E staging Supabase migration/apply/verification completed.
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Staging URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.
- Same 9 migrations as production were applied to staging.
- Staging schema/RLS/seed verification passed.
- Permission catalog count is 10 and exactly matches `20260514000400_seed_core_data.sql`.
- Earlier "7 permissions" report was confirmed to be a partial summary mistake.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.
- No staging Owner or test users were created during 14E.
- No production Supabase project was touched.
- No Vercel env vars were changed.
- No source files, SQL migrations, new migrations, deployment, or commit were included.
- Recommended next milestone: Milestone 14F staging Owner bootstrap planning.

## 2026-05-22 - Milestone 14D Staging And Preview Planning Docs

- Implemented Milestone 14D as a documentation-only staging Supabase + Vercel Preview planning checkpoint.
- Documented that future staging should use a fresh Supabase project with the same 9 migrations as production.
- Documented that staging must have separate Auth users, URL, anon/publishable key, Owner bootstrap, and fake/test data.
- Documented that production data must not be copied into staging unless explicitly approved.
- Documented Vercel Preview env policy:
  - Production env remains production Supabase only.
  - Preview env should point only to staging Supabase when staging exists.
  - Preview env should remain unconfigured until staging is ready.
  - No service role key, database credentials, `sb_secret_*`, JWT secret, SMTP secret, or OAuth/provider secret belongs in frontend/Vercel env.
- Documented Auth URL policy:
  - Production Site URL remains `https://anteiku-guild-manager.vercel.app`.
  - Production redirect URLs remain production-only.
  - Preview wildcard redirects, if needed, belong only in staging Supabase.
- Documented future staging users and validation targets for GvG, CP audit redaction, permission denial, wrong-guild access, and cleanup/archive experiments.
- No staging Supabase project was created.
- No Supabase CLI link or command was run.
- No Vercel env vars were changed.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, deployment, commit, CP logic, GvG logic, audit logic, role/guild management logic, or permission checkbox logic was changed.

## 2026-05-22 - Milestone 14C Production Rollout Complete

- Milestone 14C AdminPanel tabs refactor was committed and pushed to GitHub `main` before this documentation checkpoint.
- Vercel deployed the production build.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Manual production smoke validation passed:
  - Owner can log in.
  - AdminPanel opens.
  - Admin tabs are visible.
  - Owner can switch Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
  - Audit Logs tab loads.
  - CP tab loads.
  - Mobile tab layout is usable.
  - Member cannot access AdminPanel.
- Local browser/network validation had already confirmed lazy-loading behavior:
  - CP tab used approved CP RPCs only.
  - Audit Logs tab used `get_audit_logs` only.
  - GvG tab used safe GvG reads/RPC paths only.
  - No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- This checkpoint updated docs/handoff only.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, Vercel env, deployment, commit, CP logic, GvG logic, audit logic, role/guild management logic, or permission checkbox logic was changed during this checkpoint.
- Milestone 14C is complete in production.

## 2026-05-20 - Milestone 14C AdminPanel Tabs Implementation

- Implemented Milestone 14C as a frontend-only AdminPanel tabs + section organization refactor.
- Split the large AdminPanel UI into section components under `src/components/admin/`.
- Kept `src/pages/AdminPanel.jsx` as the coordinator for current membership, admin permission-key loading, visible tabs, active tab state, section data loading, and action handlers.
- Added mobile-first AdminPanel tabs for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Added sticky dark/crimson tab styling in `src/styles/app.css`.
- Rendered only the active tab section.
- Lazy-loaded CP, Audit Logs, and GvG management data when their tabs are opened instead of during initial AdminPanel render.
- Preserved existing service paths:
  - Audit reads remain through `get_audit_logs`.
  - CP reads/writes remain through approved CP RPCs.
  - GvG management remains through existing approved GvG RPCs/safe reads.
- `npm.cmd run build` passed.
- Static source validation found no direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- No SQL migrations, Supabase schema/RLS/RPC logic, CP logic, GvG logic, audit logic, role/guild behavior, permission checkbox behavior, deployment, or commit actions were changed.
- Manual browser and production rollout validation were completed later; Milestone 14C is now complete in production.

## 2026-05-20 - Milestone 14B Vercel GitHub App Restriction Checkpoint

- User manually restricted the Vercel GitHub App installation to only `Ultimate99/anteiku-guild-manager`.
- Recorded that the Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Production URL remains `https://anteiku-guild-manager.vercel.app`.
- Production app health was checked in the browser after the restriction.
- Browser check loaded title `Anteiku Guild Manager`.
- No captured browser console errors were observed during the checkpoint check.
- No Vercel env vars were changed.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, production commands, deployment, commit, CP logic, GvG logic, audit logic, role/guild management logic, or permission checkbox logic was changed.
- Milestone 14B is complete.
- Historical next options at that checkpoint included staging Supabase + Vercel Preview environment planning or controlled production test-member cleanup planning.

## 2026-05-20 - Milestone 14A Production Hardening Policy Docs

- Implemented Milestone 14A as a documentation-only production hardening and cleanup policy pass.
- Documented manual Vercel GitHub App restriction checklist.
- Recorded that Vercel GitHub App restriction is recommended but not executed.
- Recorded controlled production test member remains in production:
  - Email: `krsticmiroslav99+m13b21144225@gmail.com`.
  - Username/profile slug: `m13bmember21056302`.
  - IGN: `M13B Member 21056302`.
  - Status: approved Member.
- Documented controlled test member policy: keep documented for now, do not hard-delete, preserve validation/audit history, and require explicit approval for cleanup.
- Documented Preview/Staging policy: Production env only on Production deployments, Preview env unconfigured until staging exists, staging Supabase separate from production, and no broad preview redirect wildcards against production.
- Recorded deferred production smoke tests:
  - GvG production smoke was deferred to avoid persistent production GvG test data. Milestone 14H later covered full GvG smoke in staging.
  - CP redaction browser scenario was deferred due to missing production staff/data combination. Milestone 14H later covered the browser scenario in staging.
- Added launch operations guidance for before inviting real members, approvals, audit log monitoring, CP update safety, GvG event safety, admin permission safety, and production SQL safety.
- No production commands were run.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, Vercel settings, GitHub App settings, user cleanup action, deployment, commit, CP logic, GvG logic, audit logic, role/guild management logic, or permission checkbox logic was changed.

## 2026-05-19 - Milestone 13B Production Deployment Validation Passed

- Milestone 13B Vercel setup, Supabase Auth URL configuration, and production smoke/security validation completed.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel project deployed from `Ultimate99/anteiku-guild-manager` on `main`.
- Vercel framework preset: Vite.
- Vercel build command: `npm run build`.
- Vercel output directory: `dist`.
- Vercel Production env contains only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- No service role key, database password/URL, JWT secret, SMTP/OAuth/provider secret, or `sb_secret_*` key was added to frontend/Vercel env.
- Supabase Auth Site URL is configured as `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Redirect URL allow-list includes `https://anteiku-guild-manager.vercel.app`.
- Owner login on production passed.
- Owner AdminPanel access passed.
- Owner mobile AdminPanel validation passed.
- Audit Logs are readable/usable on desktop and mobile.
- CP Management is readable/usable on desktop and mobile.
- Controlled production test user registered after email confirmation, started pending, and was locked out of member/admin areas.
- Owner approved the controlled user as Member.
- Approved Member login passed.
- Approved Member cannot access AdminPanel.
- Approved Member sees no CP values.
- Manual DevTools Network validation passed for Audit Logs, CP Management, and Member pages.
- Audit Logs actions used `rpc/get_audit_logs`; no direct `/rest/v1/audit_logs`, CP calls, or audit write/update/delete/export calls were observed.
- CP Management actions used approved CP RPCs only; no direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls after clearing Network.
- Controlled production test member remains in production:
  - Email: `krsticmiroslav99+m13b21144225@gmail.com`.
  - Username/profile slug: `m13bmember21056302`.
  - IGN: `M13B Member 21056302`.
  - Status: approved Member.
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- CP redaction browser test was intentionally not tested because the needed production staff/data combination does not exist.
- Backend/source/local validation coverage remains: GvG Milestone 10 and audit CP redaction Milestone 11A/11B.
- Recommendation recorded: restrict the Vercel GitHub App installation to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, Vercel env, redeploy, commit, CP logic, GvG logic, audit logic, role/guild management logic, or permission checkbox logic changes were made during the final validation review.

## 2026-05-19 - Milestone 13A Production Supabase Checkpoint

- Production Supabase project exists.
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- Production migrations were applied successfully before this documentation checkpoint.
- All 9 approved migrations are applied remotely.
- Production schema/RLS/seed verification passed.
- Protected tables, RLS, policies, RPCs, grants, indexes, constraints, and seed data were verified.
- Manual Owner bootstrap completed using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.
- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Owner role is `owner`, membership status is `active`, and primary membership is `true`.
- `active_owner_membership_count = 1`.
- `owner_active_primary_membership_count = 1`.
- `owner_bootstrap_audit_count = 1`.
- At the time of the Milestone 13A checkpoint, Vercel had not been configured yet.
- At the time of the Milestone 13A checkpoint, production deployment had not happened yet.
- Next required milestone: Milestone 13B Vercel setup, Supabase Auth URL configuration, production deploy, and production smoke/security validation.
- Supabase CLI was installed locally as dev tooling during Milestone 13A; the CLI tooling/package changes were committed before Milestone 13B planning/execution.
- This checkpoint updated docs/handoff only.
- No source logic, React files, Supabase migrations, SQL migrations, CP logic, GvG logic, audit logic, role/guild management logic, permission checkbox logic, Vercel configuration, deployment, or commit actions were performed.

## 2026-05-15 - Milestone 12 Production Readiness Docs

- Implemented Milestone 12 as a documentation-only production readiness pass.
- Created `docs/PRODUCTION_CHECKLIST.md`.
- Expanded `docs/DEPLOYMENT.md`.
- Refreshed `docs/SETUP.md`, `.env.example`, and `README.md`.
- Added production validation guidance to `docs/TESTING.md`.
- Added Milestone 12 changelog entry.
- Refreshed stale database/RLS/roles docs with current production-readiness context.
- Updated ai_agents handoff docs and `INDEX.json`.
- Documented production migration order.
- Documented forbidden production commands, especially `supabase db reset`.
- Documented that `supabase/tests/local_validation_anteiku.sql` must not run on production because it inserts fake auth users/test data.
- Documented `supabase/config.toml` missing `seed.sql` hazard.
- Documented browser-safe Vercel env variables only: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Documented that service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- No source logic, React files, Supabase migrations, SQL migrations, deployment, production linking, dependencies, commit, CP logic, GvG logic, audit logic, role/guild management, or permission checkbox logic were changed.

## 2026-05-15 - Milestone 11B Audit Log Viewer Browser Validation Passed

- User completed manual live browser validation for Milestone 11B.
- All provided validation checks passed.
- Owner loaded Audit Logs, used filters, and used Load Older successfully.
- Leader/Vice saw assigned guild-scope logs only.
- Admin with `view_audit_logs` loaded scoped logs.
- Admin without `view_audit_logs`, normal Member, and pending user could not access audit logs.
- CP-sensitive metadata was hidden for users without `view_cp`; `cp_old` and `cp_new` were not visible.
- CP metadata appeared only for an authorized `view_cp` user when the backend returned it.
- Metadata rendering was compact and safe.
- Action, guild, date, and limit filters worked without scope bypass.
- Empty, error, and mobile layout states passed.
- Network validation after clearing initial AdminPanel load showed `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- No bugs were found.
- No tests are incomplete.
- Milestone 11B is complete.
- No source logic, SQL migrations, `get_audit_logs`, CP logic, role/guild management, permission checkbox logic, GvG logic, deployment, or commit actions were performed.

## 2026-05-15 - Milestone 11B Frontend Audit Log Viewer

- Implemented frontend-only AdminPanel Audit Logs section.
- Created `src/services/adminAuditService.js`.
- Audit viewer reads use only `public.get_audit_logs(...)`.
- Added action, safe/simple guild, date from/to, and limit filters.
- Added load older pagination using `p_before` from the oldest loaded row.
- Added loading, error, empty, and clean not-authorized states.
- Added audit cards with action label, timestamp, actor, optional target, guild/global display, entity table/id, safe metadata summary, and redaction notice.
- Metadata rendering is whitelist-based and does not dump raw metadata JSON.
- CP-redacted rows show `Sensitive CP metadata hidden.` and the frontend does not attempt unredaction or CP reconstruction.
- No SQL migrations, `get_audit_logs` changes, CP logic, CP tables/RPCs, role/guild logic, permission checkbox logic, GvG logic, dependencies, deploy, or commit were included.
- `npm.cmd run build` passed.
- Source validation confirmed `adminAuditService.js` calls only `get_audit_logs`.
- Source validation found no direct frontend `audit_logs` table calls.
- Source validation found no CP RPC/table calls in the audit viewer path.
- Source validation found no audit write/update/delete UI in the audit viewer path.
- Manual browser validation later passed; Milestone 11B is complete.

## 2026-05-15 - Milestone 11A Audit Log Read Hardening

- Implemented backend-only audit log read hardening.
- Created `supabase/migrations/20260515000300_audit_log_read_hardening.sql`.
- Added `public.get_audit_logs(...)` as the safe frontend-facing audit reader.
- Restricted direct non-Owner `audit_logs` SELECT so scoped staff cannot bypass SQL-side redaction.
- Added SQL-side CP metadata redaction for audit viewers without scoped `view_cp`.
- Kept audit writes unchanged and did not touch CP update logic, role/guild logic, permission checkbox logic, GvG logic, or frontend UI.
- Updated local validation script with Milestone 11A audit hardening checks.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 11A validation result: 14 PASS / 0 FAIL / 0 SKIP.
- Validation confirmed Owner/global audit reads, scoped Leader/Vice/Admin audit reads, Member/pending/Admin-without-permission denial, CP metadata redaction, direct non-Owner audit table read hardening, private audit writer grant revocation, and audit spoof insert denial.
- Local validation note: directly executing `private.write_audit_log` as `authenticated` crashed the local Postgres container, so the test now verifies revoked EXECUTE privilege with `has_function_privilege`.
- Milestone 11B frontend audit log viewer was implemented later as a separate frontend-only pass.

## 2026-05-15 - Milestone 10 GvG Browser Validation Passed

- User completed corrected live browser validation for Milestone 10 GvG.
- Event stayed active through member voting, refresh checks, staff visibility, and SQL one-row persistence checks.
- Event was closed only after member/staff validation passed.
- `npm.cmd run build` passed.
- Owner created a draft event, opened voting, verified active state, and closed the event after validation.
- Same-guild approved Member saw the active event, voted Present, switched to Absent with reason, then switched back to Present.
- Read-only SQL confirmed exactly one vote row for the event/profile, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff saw present/absent counts and absence reasons.
- Normal Member could not see other users' absence reasons.
- Admin without `manage_gvg` could not manage events.
- Wrong-guild Member could not see/vote for the guild-specific event.
- Out-of-scope Leader/Vice/Admin could not manage the event.
- Closed event rejected vote changes.
- Network validation after clearing initial AdminPanel load showed only GvG RPCs/safe reads for GvG actions.
- No CP RPC/table calls and no direct `gvg_votes` / `gvg_events` frontend writes were observed during GvG actions.
- No bugs, security issues, or incomplete items were reported.

## 2026-05-15 - Milestone 10 GvG Implementation

- Inspected GvG SQL/RLS before frontend work.
- Confirmed safe support for:
  - `create_gvg_event`
  - `set_gvg_event_status`
  - `submit_gvg_vote`
  - `get_gvg_results`
  - `gvg_votes_event_profile_uidx`
  - member own-vote reads
  - staff-only result/reason reads
  - `manage_gvg` enforcement
- Created `src/services/gvgService.js`.
- Replaced GvG placeholder with persistent member voting UI.
- Added AdminPanel GvG management/results section.
- No SQL migrations, CP changes, role/guild changes, or permission checkbox changes were made.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 9 Permission Management Browser Validation Passed

- User completed manual Milestone 9 permission checkbox validation.
- Permission Management section appears for authorized Owner/Leader users.
- Empty state appears when no active Admin memberships exist.
- After promoting a member to Admin, that Admin appears in Permission Management.
- Permission checkboxes load from `permission_catalog`.
- Owner can grant/revoke Admin permissions.
- Owner can grant/revoke `view_cp` and `update_cp`.
- Leader can manage allowed non-CP Admin permissions inside assigned guild scope.
- Leader cannot toggle `view_cp` / `update_cp`.
- CP permissions remain Owner-only.
- Admin users do not get Permission Management UI.
- Member users do not get Admin tab.
- Network writes used only `grant_admin_permission` / `revoke_admin_permission`.
- No direct `admin_permissions` writes were found.
- No CP data/RPC calls occurred during permission-management actions.
- No GvG logic was touched.

## 2026-05-15 - Milestone 9 Permission Management Implementation

- Inspected permission RPCs/RLS-safe reads.
- Confirmed support for:
  - `permission_catalog` reads.
  - scoped active Admin membership reads.
  - scoped `admin_permissions` reads.
  - `grant_admin_permission`.
  - `revoke_admin_permission`.
- Created `src/services/adminPermissionService.js`.
- Added AdminPanel Permission Management section.
- Owner can manage all Admin permissions.
- Leader/Vice can manage non-CP permissions in assigned guild scope.
- CP permission checkboxes are disabled for Leader/Vice with Owner-only messaging.
- Admin and Member users do not get permission-management UI.
- No direct `admin_permissions`, `guild_memberships`, or `profiles` writes were added.
- No CP data/RPC calls were added by permission management.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Frontend CP Browser Validation Passed

- User completed manual Milestone 8 frontend CP browser validation.
- Owner could see CP Management section.
- Owner loaded CP roster.
- Missing CP displayed as "Not entered".
- Owner updated member CP successfully.
- CP roster refreshed after update.
- CP leaderboard displayed correctly.
- Invalid CP inputs were blocked.
- Normal Member could not see Admin tab or CP UI.
- CP did not appear on Dashboard/Profile/member-facing pages.
- Member Network tab showed no CP RPC/table calls.
- Owner Network tab used only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found.
- No GvG logic was touched.
- Note: stale browser auth after local DB reset caused a `profiles_id_fkey` registration error; clearing localStorage/sessionStorage fixed it.

## 2026-05-15 - Milestone 8 Frontend CP Implementation

- Created `src/services/adminCpService.js`.
- Added AdminPanel CP Management section.
- Added CP roster using `get_current_cp_roster`.
- Added CP leaderboard using `get_cp_leaderboard`.
- Added CP update controls using `update_member_cp`.
- Kept CP out of AuthContext, profileService, Dashboard, Profile, member-facing pages, and normal member roster cards.
- No direct `member_cp` or `cp_snapshots` reads/writes were added.
- No GvG logic was changed.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Backend CP Hardening Validation Passed

- User completed local validation for Milestone 8 backend CP hardening.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- CP update for pending/rejected/suspended profiles is blocked.
- CP update for approved active profile works.
- Admin with `update_cp` cannot update CP for non-approved profiles.
- `get_current_cp_roster` includes approved active members with missing CP as `null`.
- Members still cannot read CP.
- Admin without `view_cp` still cannot read CP.
- Direct `member_cp` / `cp_snapshots` access remains blocked.
- CP update audit log works.
- No GvG logic changed.

## 2026-05-15 - Milestone 8 Backend CP Hardening Implemented

- Created `supabase/migrations/20260515000200_cp_rpc_hardening.sql`.
- Hardened `public.update_member_cp` to require approved target profiles.
- Improved `public.get_current_cp_roster` to include active approved members without CP rows.
- Missing CP now returns `null`, not `0`.
- Added Milestone 8 CP hardening tests to `supabase/tests/local_validation_anteiku.sql`.
- No frontend, package, GvG, or direct CP table policy changes were made.
- Local Supabase validation is pending.

## 2026-05-15 - Milestone 7 Frontend Browser Validation Passed

- User completed manual Milestone 7 frontend browser validation successfully.
- Owner changed member role `member -> admin -> member`.
- `owner` role option was not visible.
- Owner transferred member from Anteiku:Re to Anteiku.
- Transfer warning appeared before confirm.
- Transfer reset member role to `member`.
- Member could sign in after transfer.
- Member showed new guild and member role.
- Normal Member still had no Admin tab.
- Leader permissions work correctly inside assigned guild scope.
- Leader does not have Owner/global powers.
- Owner-only guild transfer remains hidden from Leader.
- Network writes used `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were found.

## 2026-05-15 - Milestone 7 Frontend Role/Guild UI Implementation

- Implemented Admin member role-management UI.
- Implemented Owner-only member guild-transfer UI.
- Added safe active guild options read for transfer targets.
- Added RPC wrappers for:
  - `assign_member_role`
  - `transfer_member_guild`
- Kept Owner assignment out of frontend UI.
- Kept guild transfer hidden from Leader/Vice/Admin in v1.
- Confirmed no direct table writes were added.
- Confirmed no CP/GvG access was added.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 7 Backend Local Validation Passed

- User completed Milestone 7 backend local validation successfully.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 7 role assignment tests passed.
- Milestone 7 guild transfer tests passed.
- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner` through normal app RPC.
- Leader/Vice can assign `member` and `admin` only.
- Admin with `manage_roles` can assign `member` and `admin` only.
- Admin/Leader/Vice/Member cannot transfer guilds.
- Owner-only guild transfer works.
- Transfer resets role to `member`.
- Old membership becomes `left` and is not deleted.
- New membership becomes active primary.
- Exactly one active primary membership remains.
- Role-change and transfer audit logs are written.
- No CP/GvG logic was changed.

## 2026-05-15 - Milestone 7 Backend SQL/RPC Implementation

- Created backend migration for member role hardening and Owner-only guild transfer:
  - `supabase/migrations/20260515000100_member_guild_role_management.sql`
- Hardened normal app role assignment:
  - Owner can assign `member`, `admin`, `vice`, and `leader`.
  - Normal app RPC rejects assigning `owner`.
  - Leader/Vice can assign `member` and `admin` inside guild scope.
  - Admin with `manage_roles` can assign `member` and `admin` inside guild scope.
  - Admin without `manage_roles` and Member cannot assign roles.
- Added Owner-only member guild transfer RPC:
  - Old membership becomes `left` and non-primary.
  - New membership becomes active primary.
  - Transferred role resets to `member`.
  - No hard delete.
  - Audit metadata records old/new guild and role details.
- Updated local validation script with Milestone 7 role and guild transfer checks.
- No frontend, package, CP, or GvG changes were made.
- Local Supabase validation is pending.

## 2026-05-14

- User provided full project rules for Anteiku Guild Manager.
- Repository was inspected and found empty.
- `ai_agents/` was missing.
- Git was not available in the current shell PATH.
- User approved Milestone 1 scaffold with amendments:
  - no copyrighted assets
  - no Tailwind
  - no extra dependencies
  - run only `npm install` and `npm run build`
  - placeholders and documentation only for security-sensitive features.
- Created the React + Vite scaffold, original abstract SVG mark, placeholder pages, plain CSS, human docs, and AI handoff docs.
- Attempted `npm install`; it failed because `npm` is not available in the current shell.
- Attempted `npm run build`; it failed for the same reason.
- `package-lock.json`, `node_modules/`, and `dist/` were not generated.
- User later ran local validation:
  - `npm.cmd install`: passed.
  - `npm.cmd run build`: passed.
  - `npm.cmd audit`: completed with 2 moderate vulnerabilities.
- `package-lock.json` and `dist/` were generated by local validation.
- Audit finding is `esbuild <=0.24.2` via `vite <=6.4.1`; do not run `npm audit fix --force` because it would install Vite 8.0.13 as a breaking major upgrade.
- User approved Milestone 2 schema/RLS direction for documentation/spec updates only, with no migrations or app code changes.
- Recorded resolved Milestone 2 decisions for profile id, CP privacy, role CP access, one active primary membership, GvG scope, slug/IGN permissions, reapply flow, Owner bootstrap, weekly CP snapshots, GvG vote correction limits, constraints, and audit visibility.
- Created Supabase migration files and a manual-only owner bootstrap template outside migrations.
- Performed SQL security review iterations on migrations. Key fixes included RPC-only GvG writes, private audit helper revoke, scoped approval/reapply handling, public core-guild visibility only, active-member CP filtering, and safer helper grants.
- Local validation initially exposed a real security bug: private helper parameter shadowing caused CP/RPC permission leakage and role-scope failures.
- Fixed helper functions by renaming parameters to prefixed `p_*` names and removing ambiguous comparisons.
- User reran local Supabase validation successfully:
  - migrations apply with `npx.cmd supabase db reset`
  - validation result: 29 PASS / 0 FAIL / 0 SKIP
  - setup failures: 0
  - security failures: 0
- Validated CP privacy, role-scoped CP access, GvG vote upsert/integrity, direct GvG write denial, approval/reapply audit behavior, and audit spoof denial.
- User approved Milestone 3 local frontend auth integration.
- Implemented local Supabase session restore, auth state listener, signin, signup, signout, safe profile loading, registration through `register_profile`, pending manual refresh, rejected/suspended gates, and role-based AdminPanel UX visibility.
- Frontend integration intentionally does not query CP tables or CP RPCs.
- Ran `npm.cmd run build`; Vite production build passed.
- Manual browser testing found React runtime import issues; JSX-rendering modules were updated to import the default `React` binding and `npm.cmd run build` passed afterward.
- Manual browser testing then found a stuck Loading state after auth/register/signout/signin/refresh flows.
- Fixed the `AuthContext` loading issue by keeping `onAuthStateChange` synchronous, ignoring duplicate `INITIAL_SESSION`, deferring profile loading safely, and always clearing state/loading on sign out.
- User reran manual Milestone 3 browser validation successfully:
  - Local Supabase badge displays correctly.
  - Register flow works and creates a pending user.
  - Sign in, sign out, pending refresh, hard refresh session restore, and signed-out refresh all work.
  - Pending users remain locked to the Pending page.
  - Stuck Loading state no longer reproduces.
  - DevTools Network inspection found no protected CP table/RPC calls.
- User approved Milestone 4 frontend approval UI/service implementation with no SQL, no bootstrap, no package changes, no new RPCs, and no frontend Owner approval option.
- Added `src/services/adminApprovalService.js` for current RLS-safe approval queue reads, own Admin permission lookup, and `approve_registration` / `reject_registration` RPC wrappers.
- Reworked `src/pages/AdminPanel.jsx` into a registration approval queue with refresh, per-row approve/reject actions, rejection reason input, and role options limited by current role.
- Added mobile-first approval queue styles.
- Confirmed source contains no protected CP table/RPC identifiers.
- Ran `npm.cmd run build`; Vite production build passed.
- Full Owner browser validation remains pending until a local Owner auth user id is provided and bootstrapped manually.
- User manually applied local Owner bootstrap outside migrations for `test1@local.dev`.
- Manual Milestone 4 browser testing initially found approved users had no visible Sign out control in the app shell.
- Added Sign out to the `AppShell` header and `npm.cmd run build` passed.
- User reran Milestone 4 browser validation successfully:
  - `test1@local.dev` became approved Owner in Anteiku.
  - Owner could access app shell and Admin tab.
  - Approval queue loaded pending users.
  - Owner approved `test2` as Member; `test2` could access app shell as role `member` in Anteiku:Re.
  - Admin tab was hidden for normal member.
  - Owner rejected `test3` with reason; `test3` was locked to `RejectedStatus`.
  - Rejected user did not see app shell/member/admin screens.
  - No CP UI or CP data was exposed.
- User corrected the next milestone: GvG is later; Milestone 5 is member profile editing.
- Inspected existing `public.update_my_profile(p_ign text, p_avatar_key text default null)` RPC before coding.
- Confirmed it updates only the authenticated user's `ign`, `avatar_key`, and `updated_at`, with no username/profile slug/role/guild/approval edits.
- Added `updateMyProfile` wrapper in `profileService.js`.
- Added Profile page edit mode for own IGN only, with Save/Cancel/loading/success/error states and profile refresh after save.
- Kept username, profile slug, guild, role, approval status, and avatar/profile icon read-only.
- Confirmed source contains no protected CP table/RPC identifiers and no direct profile/membership table updates for profile editing.
- Ran `npm.cmd run build`; Vite production build passed.
- User completed manual Milestone 5 browser validation successfully:
  - Owner and Member could edit their own IGN.
  - Changed IGN displayed correctly after save.
  - Empty/invalid IGN validation works or was checked as implemented.
  - Cancel keeps/restores original IGN.
  - Username/profile slug remained locked and not editable.
  - Guild, role, and approval status remained display-only.
  - Avatar editing was not implemented.
  - Profile update used `update_my_profile` RPC only.
  - No direct `profiles` or `guild_memberships` updates were added.
  - No protected CP table/RPC calls were added or observed.
  - `npm.cmd run build` passed.
- User approved Milestone 6 admin member profile management implementation.
- Inspected `public.admin_update_member_ign(p_profile_id uuid, p_ign text)` and confirmed it uses `auth.uid()`, checks `private.can_edit_member_ign`, updates target IGN, and writes audit metadata.
- Inspected `public.admin_reset_profile_slug(p_profile_id uuid, p_new_slug text)` and confirmed it uses `auth.uid()`, normalizes/validates slug, checks `private.can_reset_profile_slug`, updates `username` and `profile_slug` together, and writes audit metadata.
- Added `src/services/adminMemberService.js` for active approved roster reads, member-management permission helpers, and admin member IGN/slug RPC wrappers.
- Extended `src/pages/AdminPanel.jsx` with active approved member roster, search, guild filter, edit member IGN, and reset username/profile slug actions.
- Added mobile-first member-management styles.
- Confirmed source contains no protected CP table/RPC identifiers and no direct profile/membership/permission writes.
- Ran `npm.cmd run build`; Vite production build passed.
- User completed manual Milestone 6 browser validation successfully:
  - Owner could view active approved member roster.
  - Roster excluded pending/rejected/left/suspended users.
  - Owner edited `test2` member IGN successfully.
  - `test2` saw updated IGN after sign in.
  - Owner reset `test2` username/profile_slug successfully.
  - `username` and `profile_slug` stayed equal and lowercase.
  - `test2` could still sign in by email.
  - `test2` remained Member in Anteiku:Re.
  - Admin tab remained hidden for normal member.
  - No CP table/RPC calls were found in Network tab.
- New product requirement recorded: admins/staff should be able to change a member's guild and role, but this needs Milestone 7 planning/security review and must not be added as an unsafe quick patch.
- User approved Milestone 7 backend SQL/RPC implementation pass only.
- Created `supabase/migrations/20260515000100_member_guild_role_management.sql`.
- Hardened `private.can_assign_role` so normal app RPCs cannot assign `owner`, Owner can assign `member/admin/vice/leader`, Leader/Vice can assign `member/admin`, and Admin with `manage_roles` can assign `member/admin`.
- Replaced `public.assign_member_role` behavior in the new migration to reject `owner`, validate active approved target membership, audit changes, and avoid CP/GvG changes.
- Added `private.can_transfer_member_guild` and `public.transfer_member_guild` for Owner-only guild transfer.
- Transfer preserves history by setting old membership to `left`, creates/reactivates target active primary membership, resets role to `member`, audits old/new guild and role, and avoids CP/GvG changes.
- Updated local validation script with Milestone 7 role and transfer checks.
- No frontend files, package files, CP logic, or GvG logic were changed.
- No commands were run and migrations were not applied.
## 2026-05-24 - Milestone 18D AdminPanel Translation Implemented

- Implemented full AdminPanel EN/FR/DE display translation.
- Added admin translation keys for shell copy, tab content, Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, errors, success messages, permission labels/descriptions, audit action labels, and audit metadata labels.
- Updated AdminPanel and extracted admin section components to render translated display labels while preserving backend/logic values.
- Kept usernames, IGN, guild names, CP numeric values, GvG event titles, absence reasons, raw audit values, and user-generated notes untranslated.
- `npm.cmd run build` passed.
- Static checks found no Supabase migration changes, no service changes, and no new direct protected table calls in frontend source.
- Authenticated staging browser validation remains the next gate.
