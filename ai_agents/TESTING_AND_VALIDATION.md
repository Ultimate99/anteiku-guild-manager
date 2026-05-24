# Testing And Validation

## Milestone 20B CP Leaderboard Backend Validation

Milestone 20B backend/database implementation passed local validation.

Migration:
- `supabase/migrations/20260524000300_cp_rankings.sql`

Validation commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Tooling note:
- `npx.cmd supabase db query --local --file supabase/tests/local_validation_anteiku.sql` was attempted, but the Supabase CLI query wrapper rejected the multi-statement validation file with `cannot insert multiple commands into a prepared statement`.
- The same validation SQL was then run against the local Supabase Postgres container with `psql` and passed.

Focused 20B validation result:
- 14 PASS / 0 FAIL / 0 SKIP.

Validated:
- `get_member_cp_rankings(text)` and `get_admin_cp_rankings(uuid,text)` exist.
- Member ranking RPC shape has no CP fields or private identifiers.
- Member guild ranking returns deterministic rank order and excludes ineligible roster statuses.
- Member global ranking returns guild labels without CP values.
- Current user row marks `is_current_user = true`.
- `inactive` active-membership users can view rank order.
- Hard-blocked users are denied by active-membership requirements.
- Normal members cannot call admin ranking RPC.
- Admin with scoped `view_cp` can read guild CP values.
- Admin without scoped `view_cp` is denied.
- Non-Owner Admin is denied global admin CP rankings.
- Owner can read global admin CP values.
- Direct `member_cp` and `cp_snapshots` reads remain denied for normal members.
- Existing Milestone 19B and 19B.1 CP Update Window checks still pass.

Not run:
- `npm.cmd run build` was not needed because 20B changed only database migration/tests/docs and no frontend source.
- Staging/production rollout and frontend browser validation are pending future milestones.

## Milestone 19E CP Update Window Production Rollout Validation

Milestone 19E production rollout and read-only smoke validation passed.

Preflight:
- Working tree was clean before rollout.
- Latest commit before rollout was `6a3a181 feat: add CP update window self-submit`.
- Supabase CLI was relinked to production project `mzflfyxxkascrfpteexz`.
- Staging project `ckyihuxkioeibzpgwenc` was not used.

Migration:
- Production dry-run showed only:
  - `20260524000100_cp_update_window_self_submit.sql`
  - `20260524000200_cp_update_window_staff_read.sql`
- Both migrations were applied to production.
- Post-push migration list showed both migrations applied remotely.

Production DB verification:
- `cp_update_windows` exists.
- RLS is enabled on `cp_update_windows`.
- Direct anon/authenticated table grants were absent.
- One-open-window-per-guild unique index exists.
- Safe RPCs exist and have authenticated execute grants:
  - `get_active_cp_update_window_for_me`
  - `get_my_cp`
  - `submit_my_cp_update`
  - `open_cp_update_window`
  - `close_cp_update_window`
  - `get_cp_update_window_for_guild`
- `get_audit_logs(...)` includes redaction handling for `member_cp_self_submitted`.
- Production active Owner count remained `1`.

Frontend deployment:
- `git push origin main` deployed commit `6a3a181 feat: add CP update window self-submit`.
- Production bundle contained the CP Update Window frontend RPC paths after Vercel deployment.

Production smoke:
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- Owner sign-in worked.
- Owner AdminPanel CP tab loaded.
- CP Update Window block rendered for selected guild and showed `Closed`.
- Member sign-in worked.
- Member Profile showed `Your CP`.
- Member Profile loaded own CP only; no other-member CP, CP roster, or CP leaderboard was exposed.
- With no production CP window open, submit controls were not exposed and the closed-window message rendered.
- Member had no Admin navigation.
- No captured console errors were observed on the checked Owner/member paths.

Source/security validation:
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were found.
- Profile and `cpWindowService` do not call `get_current_cp_roster` or `get_cp_leaderboard`.
- Admin CP Window controls use only the approved CP window RPCs.

Not performed:
- Controlled production CP mutation smoke was not performed by design. No production CP window was opened/closed and no production CP value was submitted.
- Any future mutation smoke requires explicit approval and a controlled production test member.

## Milestone 19C CP Update Window Frontend Build/Source Validation

Milestone 19C frontend implementation passed local build and source/security-path validation.

Build:
- `npm.cmd run build` passed.

Browser smoke:
- Local app loaded at `http://127.0.0.1:5173/`.
- Unauthenticated auth page rendered with title `Anteiku Guild Manager`.
- Captured console errors were empty for the smoke path.

Static/source validation:
- No Supabase migration files changed.
- No Supabase test files changed.
- `src/services/cpWindowService.js` uses RPCs only.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were found.
- Profile and `cpWindowService` do not call `get_current_cp_roster` or `get_cp_leaderboard`.
- The new member Profile CP flow calls only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.
- The new AdminPanel CP window flow calls only `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.
- No GvG, audit, role, permission, or member-status behavior was changed.

Validation boundary:
- Authenticated CP-window browser validation was not run because staging and production do not yet have `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.
- Do not deploy this frontend to an environment until both CP Update Window migrations are applied and verified there.

Pending validation:
- Milestone 19D staging migration rollout, staging backend verification, and staging browser validation for Owner opening/closing a CP Update Window and an eligible Member submitting own CP.

## Milestone 19B.1 CP Update Window Staff Read RPC Validation

Milestone 19B.1 backend/database follow-up passed local validation.

Migration:
- `supabase/migrations/20260524000200_cp_update_window_staff_read.sql`

Validation commands:
- `npx.cmd supabase db reset`
- `supabase/tests/local_validation_anteiku.sql`

Focused 19B.1 validation result:
- 13 PASS / 0 FAIL / 0 SKIP.

Validated:
- `get_cp_update_window_for_guild(uuid)` exists.
- Normal authenticated users still have no direct `cp_update_windows` read access.
- Owner can read selected-guild open window status.
- Leader/Vice can read scoped guild window status.
- Leader wrong-guild read is denied.
- Admin with CP permission can read scoped window status.
- Admin with only `view_cp` can read scoped window status.
- Admin without CP permission is denied.
- Member is denied.
- Wrong-guild user is denied.
- Open window is returned first.
- Latest closed window is returned when no open window exists.
- No row is returned when the guild has no CP windows.

## Milestone 19B CP Update Window Backend Validation

Milestone 19B backend/database implementation passed local validation.

Migration:
- `supabase/migrations/20260524000100_cp_update_window_self_submit.sql`

Validation commands:
- `npx.cmd supabase db reset`
- `supabase/tests/local_validation_anteiku.sql`

Focused 19B validation result:
- 32 PASS / 0 FAIL / 0 SKIP.

Validated:
- `cp_update_windows` exists with RLS enabled.
- Direct client table grants are absent.
- One-open-window-per-guild constraint works.
- Owner and authorized staff can open/close windows.
- Member and Admin without `update_cp` cannot open/close windows.
- Members can read active window status only for their own guild.
- Members can read only their own CP through `get_my_cp()`.
- Members cannot directly read `member_cp`, `cp_snapshots`, or `cp_update_windows`.
- Members can submit own CP while a valid window is open.
- Submits are denied when no window is open, window is closed, future, or expired.
- Negative CP is rejected.
- Wrong-guild, inactive, on_break, suspended, left, and kicked submit paths are denied.
- Multiple submissions update latest CP and keep audit trail.
- `member_cp_self_submitted` audit rows are created.
- `cp_old`/`cp_new` are redacted in `get_audit_logs(...)` for audit users without `view_cp`.
- `cp_old`/`cp_new` are visible through `get_audit_logs(...)` for scoped users with `view_cp`.
- Existing admin CP RPC behavior still passed.

Not run:
- `npm.cmd run build` was not needed because 19B changed only database migration/tests/docs and no frontend code.
- Staging and production rollout were not performed.

## Milestone 16H Member-Facing UI Production Smoke Passed

Milestone 16H deployed the member-facing compact UI/copy pass to production.

Deployment:
- Commit deployed: `53c7907 style: clean up member-facing UI`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.

Production smoke:
- Production app loaded successfully.
- EN/FR/DE language switcher worked and persisted after reload.
- Login/Register panels were compact and translated.
- Forgot Password remained visible.
- Production Owner sign-in worked and AdminPanel access remained available.
- Controlled production Member sign-in worked.
- Member Dashboard, Profile, and GvG rendered with compact member-facing panels.
- Member had no Admin navigation or AdminPanel access.
- No other-member CP exposure was found.
- No raw translation keys were visible.
- No console errors were captured.
- Mobile/narrow viewport had no horizontal overflow.

Security/source notes:
- No SQL migrations changed.
- No Supabase commands were run during this checkpoint.
- No Supabase/RLS/RPC, service behavior, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.

## Milestone 16F Member-Facing Compact UI Validation

Milestone 16F is implemented locally as a frontend-only member-facing UI/copy compact pass.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- No Supabase migration files changed.
- No `src/services/` files changed.
- No SQL, Supabase/RLS/RPC, auth behavior, CP, GvG voting, audit, role/guild/permission, or member-status logic was changed.
- No new direct protected-table paths were found in the frontend diff.
- Changed copy is routed through existing EN/FR/DE i18n dictionaries.

Local browser smoke:
- Local app was running at `http://localhost:5173/`.
- Local app was pointed at local Supabase.
- Login, Register, and Forgot Password screens rendered in EN/FR/DE.
- Language switching worked on checked auth surfaces.
- No raw translation keys were visible.
- No captured console errors were observed.
- No horizontal overflow was detected in the checked narrow viewport.

Validation boundary:
- Authenticated member/staging validation was not run during 16F because the local app was pointed at local Supabase.
- A fake `#type=recovery` URL without a live Supabase recovery session did not show the Set New Password screen; real recovery behavior was already production-validated in Milestone 17C.

Pending validation:
- Milestone 16G authenticated staging validation for member Dashboard/Profile/GvG, pending/restricted gates, member no-AdminPanel, CP non-leakage, GvG eligibility, and mobile EN/FR/DE layout.

## Milestone 18F Language Pack Production Smoke Passed

Milestone 18F deployed the frontend-only language pack to production.

Deployment:
- Commit deployed: `1f5b956 feat: add English French German language pack`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.

Production language smoke:
- App loaded successfully.
- Language switcher was visible logged out and logged in.
- EN/FR/DE switching worked.
- Selected language persisted after reload.
- Login, registration, and forgot-password copy translated.
- Production Owner sign-in worked.
- Owner AdminPanel opened.
- AdminPanel tabs translated in EN/FR/DE.
- Members, CP, GvG, Audit Logs, Permissions, and Tools tabs rendered.
- No raw translation keys were visible.
- No console errors were captured.
- Mobile/narrow viewport had no horizontal overflow.
- Existing production Member had no Admin navigation.

Security/source notes:
- No SQL migrations changed.
- No Supabase commands were run during docs checkpoint.
- No Supabase/RLS/RPC, service behavior, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.

Future validation:
- French/German admin wording review by native speakers is recommended.

## Milestone 18B i18n Foundation Build/Preview Validation Passed

Milestone 18B implements the frontend-only language foundation for English, French, and German.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- No Supabase migration files changed.
- No SQL, Supabase/RLS/RPC, auth behavior, CP, GvG, audit, role, permission, or member-status logic was changed.
- No new protected-table paths were found in the touched files.
- Translation dictionaries do not translate usernames, IGN, guild names, database permission keys, raw audit metadata values, or user-generated notes/reasons.

Built-app preview validation:
- Local preview served the built app at `http://127.0.0.1:4173/`.
- Language switcher was visible on the unauthenticated auth screen.
- EN/FR/DE switching updated shell/auth copy.
- Reload persistence passed for the selected language.
- Register mode showed translated registration copy, email warning, guild selector label, and request-approval button.
- Recovery URL `#type=recovery` showed translated Set New Password screen and kept normal navigation hidden.
- No missing translation-key strings were visible in checked auth/register/recovery paths.
- Captured console errors were empty during the preview checks.
- Language selector rendered as a compact 56px control in the checked topbar.

Not fully browser-validated in 18B:
- Authenticated Owner/member pages in all languages.
- Pending/rejected/suspended/roster-restricted gates in live authenticated states.
- Full AdminPanel content translation, which is intentionally out of scope for 18B.

## Milestone 17D Registration Copy Build/Source Validation

Milestone 17D prepares registration copy for controlled guild onboarding without assuming email confirmation.

Validation scope:
- Frontend copy/auth UX only.
- No production Auth settings changed.
- No SQL migrations changed.
- No Supabase/RLS/RPC behavior changed.
- No service files changed.
- No role/guild/permission, CP, GvG, audit, member-status, approval, or membership behavior changed.
- `ai_agents/INDEX.json` parses.

Validation targets:
- `npm.cmd run build` passed.
- Registration copy says `Register for guild approval.`
- Registration email warning says users need a real email for password reset.
- Registration submit button says `Request approval`.
- No-session signup fallback mentions confirmation only conditionally and still says guild approval is required.
- Pending screen says `Awaiting approval.`

Staging validation still required:
- Disable email confirmation in staging project `ckyihuxkioeibzpgwenc` only.
- Register a new controlled staging user without email confirmation.
- Confirm the user lands pending and cannot access member/admin areas.
- Confirm Owner sees and can approve the request.
- Confirm approved user can access member area.
- Confirm forgot password still sends recovery email and recovery link still forces `Set new password`.

## Milestone 17C Password Recovery Production Validation Passed

Milestone 17C production rollout and recovery validation passed.

Production rollout:
- Commit deployed: `23dd956 fix: require password reset after recovery link`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Production smoke passed after deployment.

Production smoke:
- App loads.
- Login/register screen works.
- Forgot-password UI is visible.
- Controlled member access remains member-only.
- No AdminPanel exposure for the controlled member.
- Captured production console warnings/errors were empty.

Production recovery validation:
- Controlled production test member `krsticmiroslav99+m13b21144225@gmail.com` was used.
- Reset request was sent through production forgot-password UI.
- Recovery email link opened production.
- `Set new password` gate appeared.
- Normal navigation was blocked before password update.
- Password update succeeded.
- New password login worked.
- Role/access remained unchanged after reset.

Security/scope:
- No passwords, recovery tokens, or secrets were stored in docs/source.
- No SQL migrations changed.
- No Supabase/RLS/RPC logic changed.
- No Supabase Auth settings changed.
- No Vercel env vars changed.
- No CP, GvG, audit, role, permission, member-status, approval, or membership behavior changed.

## Milestone 17A Password Recovery Build/Source Validation Passed

Milestone 17A local implementation passed build, source/security-path checks, and limited local browser smoke validation.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- No Supabase migration files changed.
- No SQL, Supabase/RLS/RPC, profile approval, membership status, roster status, role/guild, permission, CP, GvG, or audit behavior was changed.
- Only `src/services/authService.js` changed under `src/services`, adding password reset/update auth wrappers.
- No new direct frontend `member_cp`, `cp_snapshots`, `audit_logs`, `member_status_history`, or unsafe `gvg_votes` paths were added.

Local browser smoke:
- Local app loaded at `http://localhost:5173/`.
- Auth screen showed `Forgot password?`.
- Forgot-password mode showed `Send reset link` and `Back to sign in` without showing a password field.
- Reloading `http://localhost:5173/#type=recovery` forced the `Set new password` screen.
- Normal navigation was not shown while recovery mode was active.
- Signing out from the recovery screen cleared the recovery marker and returned to the auth screen.
- Captured console warnings/errors were empty for this smoke path.

Not yet validated:
- Real Supabase recovery email click-through.
- Successful password update through a real recovery session.
- New password sign-in and old password rejection.
- Pending/member/admin/suspended gate preservation after a real reset.

Recommended next validation:
- Milestone 17B staging recovery-email validation using a controlled staging test account.

## Milestone 16D.1 AdminPanel Compact Roster Validation Passed

Milestone 16D.1 local implementation and staging browser validation passed.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- No service files changed.
- No Supabase migration files changed.
- No Supabase test files changed.
- No SQL, Supabase/RLS/RPC, CP, GvG, audit, role/guild, permission, or member-status behavior was changed.
- Technical-term search found no product-facing UI strings for `Supabase configured`, `RPC`, `RLS`, `backend`, `policies`, `scaffold`, or `milestone`; remaining matches are internal identifiers/config code only.

Authenticated staging browser validation:
- Local frontend was temporarily pointed at staging project `ckyihuxkioeibzpgwenc`.
- `staging_owner` opened AdminPanel and the Members tab.
- Members tab rendered compact roster rows instead of always-open large cards.
- A member `Manage` disclosure expanded successfully.
- Expanded controls still showed IGN editing, username reset, roster status controls, reason input, role management, and guild transfer.
- CP, GvG, Audit Logs, Permissions, and Tools tabs still rendered.
- No captured console warnings/errors were reported during the validation path.
- `.env.local` was restored to local Supabase and Vite was restarted after validation.

Scope:
- No production, deployment, Vercel env, Supabase command, SQL, service behavior, or commit action was performed.

## Milestone 16C Authenticated AdminPanel Browser Validation Passed

Milestone 16C authenticated browser validation passed against staging through the local frontend temporarily pointed at `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.

Accounts validated:
- `staging_owner`: AdminPanel opened; Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools tabs rendered and switched; mobile AdminPanel viewport remained readable/tappable.
- `staging_admin_noperms`: only safe Tools access was exposed; no CP, Audit Logs, GvG management, Permissions, Approvals, or Members controls were visible.
- `staging_member`: no AdminPanel access; no admin UI; no other-member CP exposure; Profile displays user-facing "Username" copy.
- `staging_pending`: locked to the pending approval screen with no member/admin navigation.
- `staging_audit_nocp`: Audit Logs access worked; CP tab/tools were not visible; CP-sensitive audit metadata showed `Sensitive CP metadata hidden.` with no CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp`: Audit Logs access worked; CP visibility was available as permitted; CP audit metadata showed backend-returned `New CP 1,234,567`.
- `staging_wrongguild`: remained scoped to Anteiku:Rose; no Admin/CP/Audit/Members navigation; no Anteiku GvG smoke event or vote controls were visible.

Fixes made during validation:
- Rephrased user-facing "Profile slug" UI text to "Username".
- Changed restricted AdminPanel shell copy to neutral available-section text for users with limited admin scopes.

Build/source validation:
- `npm.cmd run build` passed after validation fixes.
- No service files changed.
- No Supabase migration or Supabase test files changed.
- No new direct frontend `member_cp`, `cp_snapshots`, `audit_logs`, `member_status_history`, or unsafe `gvg_votes` paths were added.
- Existing approved service paths remain unchanged: Audit uses `get_audit_logs`, CP uses approved CP RPCs, GvG uses approved RPCs/safe reads, and roster status updates use `update_member_roster_status`.

Scope:
- `.env.local` was temporarily pointed at staging and restored to local Supabase after validation.
- Vite was restarted locally after the `.env.local` restore.
- Staging test credentials were used transiently and were not stored in docs/source.
- No production, Vercel env, deployment, SQL, Supabase/RLS/RPC, service, or commit action was performed.

## Milestone 16B AdminPanel UI Cleanup Build/Source Validation Passed

Milestone 16B AdminPanel UI cleanup is implemented locally, build/source validated, and authenticated-browser validated through staging in Milestone 16C.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- No Supabase migration files changed.
- No Supabase test files changed.
- No service files changed.
- No SQL, RLS, RPC, CP, GvG, audit, role/guild, permission, or member-status behavior was changed.
- No new direct frontend `member_cp`, `cp_snapshots`, `audit_logs`, or `member_status_history` table calls were found.
- No unsafe direct GvG vote writes were added.
- Existing allowed service paths remain unchanged.

Browser smoke:
- Local Vite app was reachable at `http://localhost:5173/`.
- Page title loaded as `Anteiku Guild Manager`.
- Captured console warnings/errors were empty on the unauthenticated local page.
- Authenticated staging browser validation later passed in Milestone 16C.

## Milestone 15E Member Status Production Rollout Validation Passed

Milestone 15E production rollout validation passed.

Production target:
- Project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Staging project `ckyihuxkioeibzpgwenc` was not touched.

Migration:
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- `20260523000100_member_roster_status_system.sql` was applied to production.
- Post-push migration history showed `20260523000100` applied remotely.

Production DB verification:
- `guild_memberships.roster_status` exists with default `active` and `NOT NULL`.
- Allowed status check constraint exists.
- Roster-status index exists.
- `member_status_history` exists.
- RLS is enabled on `member_status_history`.
- No public/client write policies were found for `member_status_history`.
- `update_member_roster_status(...)` exists with authenticated execute grant.
- Four production membership rows were verified and all were backfilled to `roster_status = active`.
- Active Owner count remained `1`.

Frontend deployment:
- Commit `23866be feat: add member roster status system` was pushed to `main`.
- Vercel served the deployed production bundle containing Member Status frontend paths.

Production smoke validation:
- Production app loaded.
- Owner sign-in passed.
- Owner Home/Profile/GvG/Admin loaded.
- Members tab loaded with roster status badges, filter, and controls.
- CP tab loaded for Owner.
- Audit Logs loaded for Owner.
- Member sign-in passed.
- Member had no Admin nav.
- Member Profile showed own roster status safely.
- Member GvG loaded.
- Member saw no CP roster, leaderboard, snapshots, or other-member CP exposure.
- No captured console errors were observed.

Scope:
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.

Operational warning:
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; explicitly relink before future staging/local Supabase commands.

## Milestone 15D Member Status Staging Validation Passed

Milestone 15D staging migration rollout and browser validation passed.

Staging target:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Production project `mzflfyxxkascrfpteexz` was not touched.

Migration:
- `npx.cmd supabase db push --dry-run` showed only `20260523000100_member_roster_status_system.sql` pending for staging.
- `20260523000100_member_roster_status_system.sql` was applied to staging.
- Staging migration history includes the 15A migration after apply.

Schema/RLS verification:
- `guild_memberships.roster_status` exists.
- `member_status_history` exists with RLS/policy/grants.
- `update_member_roster_status(...)` exists and is executable by authenticated users.
- Existing staging memberships were backfilled to `roster_status = active`.
- Exactly one active staging Owner remains.

Browser validation:
- `staging_owner` Members tab showed roster status badges, filter, and status controls.
- `staging_member` transitions passed: `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, restored `active`.
- `suspended` showed the restricted notice and blocked member/admin areas.
- `on_break` allowed Home/Profile and showed not expected for GvG with no vote controls.
- `staging_admin_noperms` had no Members/status/CP/Audit/GvG management controls.
- Final `staging_member` state was verified as `membership_status = active` and `roster_status = active`.
- Status changes created 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows.

Source/security-path validation:
- Status changes use only `update_member_roster_status(...)`.
- No direct frontend `guild_memberships` writes were found.
- No frontend `member_status_history` calls or writes were found.
- No new direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls were found.
- CP privacy is unchanged.

Scope:
- `.env.local` was temporarily pointed at staging and restored to local Supabase.
- Vite was restarted locally after the restore.
- No production, Vercel, deployment, commit, source, or SQL migration changes were performed during this 15D docs checkpoint.

Production gate:
- Production rollout later passed in Milestone 15E.

## Milestone 15B Member Status Frontend Build/Source Validation Passed

Milestone 15B frontend implementation is build-passed, source/security-path validated, and browser-validated through staging in Milestone 15D.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- Status changes call only `update_member_roster_status` from `src/services/adminMemberService.js`.
- No direct frontend `guild_memberships` updates were found.
- No direct frontend `member_status_history` calls or writes were found.
- No direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls were added.
- No `supabase/migrations` or `supabase/tests` files changed during Milestone 15B.
- `git diff --check` reported only CRLF normalization warnings.

Implemented validation targets confirmed through staging and production where applicable:
- Owner sees roster status badges/filter/control in Admin Members.
- Owner can set member roster statuses through the RPC wrapper.
- Admin with `manage_members` is offered non-terminal statuses only; backend/local validation covers enforcement, and no matching production/staging account was used for browser confirmation.
- Admin without `manage_members` cannot use roster status controls.
- Member cannot change own roster status.
- `suspended` restricted notice was browser-validated in staging; `left` and `kicked` backend behavior was locally validated.
- `inactive` and `on_break` can still reach profile/dashboard but do not get GvG vote controls.
- Status changes should produce backend audit/history rows through Milestone 15A RPC behavior.
- No CP appears on member Dashboard/Profile/GvG pages.

Browser validation:
- Staging browser validation passed in Milestone 15D after the 15A migration was applied to staging.
- Production browser validation passed in Milestone 15E after the production database migration was applied and verified.

## Milestone 15A Member Status Backend Validation Passed

Milestone 15A backend/database validation is complete.

Local validation passed:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.

Milestone 15A results:
- Total PASS: 22
- Total FAIL: 0
- Total SKIP: 0

Validated:
- Migration applies cleanly.
- `guild_memberships.roster_status` defaults to `active`.
- Invalid roster status values are rejected.
- Owner can set all statuses.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only allowed non-terminal statuses.
- Admin without `manage_members` is denied.
- Admin cannot set `suspended`, `left`, or `kicked`.
- Admin cannot affect Owners or change self.
- Member status changes are denied.
- Last active Owner protection works.
- `suspended`, `left`, and `kicked` remove active membership access.
- `inactive` and `on_break` preserve active membership but cannot see/vote on active GvG events.
- `trial` retains normal GvG voting access.
- `member_status_history` rows are inserted with private reasons.
- `member_roster_status_changed` audit logs are inserted without private reason text.
- Members cannot read private status history.
- Scoped staff can read status history.

Build:
- `npm.cmd run build` was not run because Milestone 15A changed only SQL and docs, with no frontend/source changes.

## Milestone 14H Staging CP Redaction And GvG Smoke Validation Passed

Milestone 14H is complete.

Staging target:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.

Browser validation passed:
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` could access Audit Logs.
- `staging_audit_nocp` saw `Sensitive CP metadata hidden.` for the CP-sensitive audit row.
- `staging_audit_nocp` did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` could access Audit Logs.
- `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke` for Anteiku.
- `staging_member` voted Present, switched to Absent with reason, then switched back to Present.
- Owner closed the event.
- `staging_wrongguild` could not see or vote on the Anteiku-scoped event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.

Read-only SQL verification passed:
- `staging_member` CP row exists with `cp_value = 1234567`.
- CP audit log row exists with `member_cp_updated` metadata.
- GvG event exists and is closed.
- Exactly one `gvg_votes` row exists for `staging_member` and the event.
- Final vote status is `present`.
- Final absence reason is `null`.
- `staging_wrongguild` remains active in `anteiku-rose`.
- Permission matrix remains expected.
- Active Owner count remains `1`.

Deferred production tests now covered in staging:
- Full GvG smoke test.
- CP audit redaction browser scenario.
- Permission denial flows.
- Wrong-guild access.
- Pending-user lockout.

Network validation caveat:
- Literal DevTools request capture was not available through browser automation.
- Source-path inspection confirmed Audit uses `get_audit_logs`.
- Source-path inspection confirmed CP uses `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- Source-path inspection confirmed GvG writes use approved RPCs, with the own-vote `gvg_votes` read expected and safe.
- This caveat is non-blocking for Milestone 14H completion.

Scope confirmation:
- Production was not touched.
- Vercel Preview was not configured.
- No deployment was performed.
- No source files or SQL migrations were changed.
- Test data remains in staging intentionally.
- `.env.local` was restored to local Supabase settings after validation.

## Milestone 14F Staging Owner Bootstrap Verification Passed

Milestone 14F staging Owner bootstrap is complete.

Staging Owner verification:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Profile approval status: `approved`.
- Membership role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_count = 1`.
- `owner_bootstrapped` audit log count: `1`.

Scope confirmation:
- No production project was touched.
- No Vercel env vars were changed.
- No deployment was performed.
- No source files or SQL migrations were changed.
- No controlled staging test users were created during 14F; they were created later in Milestone 14G.

Recommended next validation planning:
- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution.

## Milestone 14E Staging Supabase Verification Passed

Milestone 14E staging Supabase migration/apply/verification is complete.

Staging project:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Project URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.

Validation completed:
- Same 9 migrations as production were applied to staging.
- Migration history matched after apply.
- Core schema/RLS/policies/RPCs/private helpers/grants/indexes/constraints were verified.
- Core guild seed data exists.
- Permission catalog count is 10.
- Permission catalog exactly matches `20260514000400_seed_core_data.sql`.
- Earlier "7 permissions" report was a partial summary mistake.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.

Scope confirmation:
- No production project was touched.
- No Vercel env vars were changed.
- No deployment was performed.
- No source files or SQL migrations were changed.
- Staging Owner was not created during 14E; it was bootstrapped later in Milestone 14F.

Recommended next validation planning:
- Milestone 14F: staging Owner bootstrap planning. Completed later.

## Milestone 14D Staging And Preview Planning Docs

Milestone 14D is documentation-only.

Validation expectations for this pass:
- `ai_agents/INDEX.json` parses as valid JSON after update.
- No source logic files changed.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No Supabase commands were run.
- No staging Supabase project was created.
- No Supabase CLI link was changed.
- No Vercel env vars were changed.
- No deployment or commit was performed.

Staging validation targets documented for future milestones:
- Full GvG smoke test.
- CP audit redaction browser scenario with an Admin who has `view_audit_logs` but not `view_cp`.
- Permission denial flows.
- Wrong-guild access checks.
- Cleanup/archive experiments.

Future staging test accounts documented:
- Owner.
- Approved Member.
- Admin with `view_audit_logs` but without `view_cp`.
- Admin with both `view_audit_logs` and `view_cp`.
- Wrong-guild Member.
- Pending user.

## Milestone 14C AdminPanel Tabs Validation Passed

Milestone 14C is frontend-only and complete in production.

Build:
- `npm.cmd run build` passed.

Source/security-path validation:
- No SQL migration files changed.
- No source service behavior changes were made.
- New `src/components/admin/*` section components do not import services, call Supabase, or own sensitive data access.
- Static source checks found no frontend direct `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('audit_logs')` calls.
- Audit reads remain isolated through `src/services/adminAuditService.js` and `get_audit_logs`.
- CP reads/writes remain isolated through `src/services/adminCpService.js` and approved CP RPCs.
- GvG management still uses existing `src/services/gvgService.js` safe reads/RPCs; no new GvG service paths were added.
- Inactive AdminPanel sections are not mounted by the coordinator; CP, Audit Logs, and GvG data loaders run only when their tabs are opened or explicitly refreshed.

Local browser/source-path validation:
- Owner and admin tab switching passed.
- Mobile `390px` tab UX passed.
- Lazy-load/network validation passed through local Kong logs.
- CP tab used only `get_current_cp_roster` and `get_cp_leaderboard`.
- Audit Logs tab used only `get_audit_logs`.
- GvG tab used safe `gvg_events` read only.
- No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- No major console errors or tab-refactor bugs were found.

Production smoke validation passed after Vercel deployment:
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Owner can log in.
- AdminPanel opens.
- Admin tabs are visible.
- Owner can switch Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Audit Logs tab loads.
- CP tab loads.
- Mobile tab layout is usable.
- Member cannot access AdminPanel.

## Milestone 14A Production Hardening Docs Validation

Milestone 14A is documentation-only.

Validation expectations for this pass:
- `ai_agents/INDEX.json` parses as valid JSON after update.
- No source logic files changed.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No production commands were run.
- No Vercel settings were changed.
- No GitHub App settings were changed.
- No users were disabled, deleted, or suspended.
- No deployment or commit was performed.

Production hardening policies documented:
- Manual Vercel GitHub App restriction checklist.
- Controlled production test member retention policy.
- Preview/Staging separation policy.
- Deferred GvG production smoke and CP redaction browser-test strategy.
- Launch operations checklist for approvals, audit monitoring, CP updates, GvG events, admin permissions, and production SQL safety.

## Milestone 13B Production Deployment Smoke Validation Passed

Milestone 13B is complete.

Production deployment:
- Production app URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel deployment from `Ultimate99/anteiku-guild-manager` on `main` passed.
- Vercel framework preset: Vite.
- Build command: `npm run build`.
- Output directory: `dist`.
- Production env contains only browser-safe frontend variables:
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY`
- No service-role key, database password/URL, JWT secret, SMTP/OAuth/provider secret, or `sb_secret_*` key was added to frontend/Vercel env.

Supabase Auth URL configuration:
- Site URL: `https://anteiku-guild-manager.vercel.app`.
- Redirect URL allow-list includes `https://anteiku-guild-manager.vercel.app`.

Production smoke/security validation passed:
- Production app loads.
- Owner login passed.
- Owner can access AdminPanel.
- Owner sees expected admin sections.
- Owner mobile AdminPanel validation passed.
- Audit Logs are readable/usable on desktop and mobile.
- CP Management is readable/usable on desktop and mobile.
- GvG/Admin sections did not break mobile layout.
- Controlled signup created a pending production user after email confirmation.
- Pending user could not access member/admin areas.
- Owner approved the controlled user as Member.
- Approved Member login passed.
- Approved Member cannot access AdminPanel.
- Approved Member sees no CP values.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls in manual Network validation.

Manual DevTools Network validation passed:
- Audit Logs refresh/load observed `rpc/get_audit_logs`.
- No direct `/rest/v1/audit_logs` calls were observed during Audit Logs actions.
- No CP RPC/table calls occurred during Audit Logs actions.
- No audit write/update/delete/export calls occurred during Audit Logs actions.
- CP Management load/refresh observed only approved CP RPCs.
- No direct `/rest/v1/member_cp` calls were observed.
- No direct `/rest/v1/cp_snapshots` calls were observed.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls after clearing Network.

Controlled production test member:
- Email: `krsticmiroslav99+m13b21144225@gmail.com`.
- Username/profile slug: `m13bmember21056302`.
- IGN: `M13B Member 21056302`.
- Status: approved Member.
- This controlled test member remains in production unless later cleanup/member management is explicitly approved.

Deferred / intentionally not tested in production:
- GvG production smoke was not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- GvG was fully live-browser validated locally in Milestone 10.
- Production source/static path validation confirmed GvG uses approved RPCs/safe reads.
- CP redaction browser test was not tested because there is no current production staff user/data combination with `view_audit_logs` but without `view_cp` and a fresh CP-sensitive audit entry.
- Backend CP metadata redaction was validated in Milestone 11A.
- Audit viewer source validation confirms `get_audit_logs` is the only audit read path.

Bugs found:
- None.

Remaining recommendation:
- Restrict the Vercel GitHub App installation to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.

## Milestone 13A Production Supabase Verification And Owner Bootstrap

Milestone 13A production database work is complete through migration apply, catalog verification, and manual Owner bootstrap.

Production project:
- Project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.

Migration apply:
- `npx.cmd supabase db push` completed successfully before this documentation checkpoint.
- `npx.cmd supabase migration list` showed all 9 migrations applied remotely.
- No `db reset` was run.
- No `--include-seed` was used.
- `supabase/tests/local_validation_anteiku.sql` was not run against production.

Remote migrations applied:
- `20260514000100`
- `20260514000200`
- `20260514000300`
- `20260514000400`
- `20260514000500`
- `20260514000600`
- `20260515000100`
- `20260515000200`
- `20260515000300`

Production schema/RLS/seed verification passed:
- Core tables exist.
- Core guild seed rows exist: `Anteiku`, `Anteiku:Re`, `Anteiku:Rose`, `Anteiku:Goat`.
- Permission catalog exists.
- `view_cp` and `update_cp` are marked sensitive.
- RLS is enabled on protected tables.
- Expected RLS policies exist.
- Expected public RPCs exist.
- Expected private helper functions exist.
- `private.write_audit_log` is not executable by normal authenticated users.
- `public.get_audit_logs(...)` is executable by authenticated users.
- Expected constraints and indexes exist, including `gvg_votes_event_profile_uidx`.
- Direct `member_cp` and `cp_snapshots` remain protected by RLS with no direct policies.
- Direct `audit_logs` SELECT is Owner-only.
- Direct `gvg_votes` writes remain unavailable through direct table policies.

Owner bootstrap verification passed:
- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Owner profile `approval_status = approved`.
- Owner membership `role = owner`.
- Owner membership `membership_status = active`.
- Owner membership `is_primary = true`.
- `active_owner_membership_count = 1`.
- `owner_active_primary_membership_count = 1`.
- `owner_bootstrap_audit_count = 1`.

Milestone 13B later completed:
- Vercel configuration.
- Production Auth Site URL and Redirect URL setup.
- Production deployment.
- Production browser/network smoke validation.
- Pending/member/admin security-flow validation against deployed app.

Documentation checkpoint validation:
- No Supabase commands were run during this documentation checkpoint.
- No source logic files were edited.
- No SQL migrations were edited or created.
- `ai_agents/INDEX.json` must parse after update.

## Milestone 12 Production Readiness Documentation

Milestone 12 was documentation-only.

Validation performed:
- Required docs/source context was inspected.
- `docs/PRODUCTION_CHECKLIST.md` was created.
- Production migration order was documented.
- Production forbidden commands were documented.
- Environment variable safety was documented.
- Owner bootstrap safety was documented.
- Local-only validation script warning was documented.
- `ai_agents/INDEX.json` was validated as JSON after update.

Build:
- `npm.cmd run build` was not run because Milestone 12 changed documentation only.

No source/SQL changes:
- No React/source logic files changed.
- No Supabase migrations changed.
- No SQL migrations were created.
- No deployment commands were run.

Future Milestone 13 validation must include:
- Production Supabase migration dry-run and apply verification.
- Guild seed and permission catalog verification.
- RLS/policies/functions/grants verification.
- Manual Owner bootstrap verification.
- Pending/member/admin/staff/Owner browser validation.
- CP denial and scoped CP access validation.
- GvG one-row vote switching validation.
- Audit redaction and `get_audit_logs` network validation.
- Vercel smoke test.

## Milestone 11B Frontend Audit Log Viewer Validation Passed

Build:
- `npm.cmd run build` passed.

Source/security-path validation:
- AdminPanel audit viewer imports and calls `src/services/adminAuditService.js` for audit reads.
- `src/services/adminAuditService.js` calls only `supabase.rpc('get_audit_logs', ...)`.
- No frontend `supabase.from('audit_logs')` calls were found.
- No CP table/RPC calls were found in the audit viewer path.
- No audit write/update/delete/export UI was found in the audit viewer path.
- No SQL migrations were changed.
- `public.get_audit_logs(...)` was not changed.

Manual live browser validation passed:
- Status precheck passed.
- Owner loaded Audit Logs successfully.
- Owner filters worked without errors.
- Load Older pagination worked correctly.
- Leader/Vice saw assigned guild-scope logs only, with no out-of-scope logs visible.
- Admin with `view_audit_logs` loaded scoped logs.
- Admin without `view_audit_logs` had Audit Logs hidden or saw a clean not-authorized state.
- Normal approved Member had no audit log access.
- Pending user was blocked from audit access.
- CP-sensitive metadata was hidden for users without `view_cp`; `cp_old` and `cp_new` were not visible.
- CP metadata appeared only for an authorized `view_cp` user when the backend returned it.
- Metadata rendered compactly and safely.
- Action, guild, date, and limit filters worked.
- Guild filter did not bypass scope.
- Empty results displayed a clean empty state.
- Permission/error state displayed a clean message.
- Mobile viewport was usable and readable.

Network validation passed after clearing Network and performing only Audit Logs actions:
- `get_audit_logs`: observed.
- Direct `audit_logs` table call: none.
- CP calls: none.
- Audit write/update/delete/export calls: none.

Bugs found:
- None.

Incomplete tests:
- None.

## Milestone 11A Audit Log Read Hardening Validation Passed

Local validation passed:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.

Milestone 11A results:
- Total PASS: 14
- Total FAIL: 0
- Total SKIP: 0

Validated behavior:
- Owner can read global audit logs through `get_audit_logs`.
- Leader can read only assigned guild audit logs.
- Vice can read assigned guild audit logs.
- Admin with `view_audit_logs` can read scoped audit logs.
- Admin without `view_audit_logs` cannot read audit logs.
- Member cannot read audit logs.
- Pending user cannot read audit logs.
- Admin with `view_audit_logs` but without `view_cp` receives redacted CP metadata.
- Admin with both `view_audit_logs` and `view_cp` receives scoped CP metadata.
- Direct `audit_logs` SELECT returns no rows for non-Owner.
- `authenticated` has no EXECUTE privilege on `private.write_audit_log`.
- Audit spoof insert remains blocked.

Validation implementation note:
- Directly executing `private.write_audit_log` as `authenticated` caused a local Postgres container segfault instead of a normal permission error.
- The script now validates the revoked grant using `has_function_privilege`, avoiding the crash while still proving normal authenticated users cannot execute the helper.

## Milestone 10 GvG Browser Validation Passed

Inspection result:
- GvG RPC/RLS support was confirmed before frontend implementation.
- One vote per event/profile is enforced by `gvg_votes_event_profile_uidx`.
- Voting writes use `submit_gvg_vote`.
- Event management writes use `create_gvg_event` and `set_gvg_event_status`.
- Staff result/reason reads use `get_gvg_results`.

Build:
- `npm.cmd run build` passed.

Corrected live browser validation passed:
- Owner signed in, opened AdminPanel, created a draft GvG event, and opened voting.
- The event appeared active in AdminPanel.
- Same-guild approved Member signed in, saw the active event on the GvG page, and had no admin controls.
- Awaiting-event state appeared when no active event existed.
- Member voted Present, refreshed, and Present persisted.
- Member switched to Absent with a reason, refreshed, and Absent plus own reason persisted.
- Member switched back to Present, refreshed, and Present persisted.
- Read-only SQL confirmed `vote_rows = 1`, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff saw present/absent counts and absence reasons.
- Normal Member could not see other users' absence reasons or staff absence logs.
- Admin without `manage_gvg` could not manage events.
- Wrong-guild Member could not see/vote for the guild-specific event.
- Out-of-scope Leader/Vice/Admin could not manage the event.
- Owner/staff closed the event, and closed-event vote changes were rejected.
- After clearing Network following initial AdminPanel load, GvG actions used only GvG RPCs/safe reads.
- No CP RPC/table calls were triggered by GvG actions after Network was cleared.
- No direct frontend insert/update/upsert/delete calls to `gvg_votes` or `gvg_events` were observed.

Read-only SQL summary:
- Event found: yes.
- Event title: `M10 Live Test GvG`.
- Event scope: guild.
- Event guild matched the member guild.
- Event status after open: `active`.
- Event status after close: `closed`.
- Member found: yes.
- Member approval status: `approved`.
- Member membership status: `active`.
- Final vote rows: `1`.
- Final vote status: `present`.
- Final absence reason: `null`.

Network summary:
- Allowed GvG calls observed: `create_gvg_event`, `set_gvg_event_status`, `submit_gvg_vote`, `get_gvg_results`, safe `gvg_events` reads, and safe own-vote `gvg_votes` reads.
- Forbidden CP calls observed after Network clear: none.
- Direct `gvg_votes` / `gvg_events` writes observed from frontend: none.

## Milestone 9 Permission Management Browser Validation Passed

Manual browser validation passed:
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

## Milestone 9 Permission Management Build Validation

Inspection result:
- `grant_admin_permission` and `revoke_admin_permission` exist and are RPC-based.
- Permission catalog reads are supported.
- Scoped active Admin membership reads are supported.
- Scoped current `admin_permissions` reads are supported.
- Writes remain RPC-only.

Build:
- `npm.cmd run build` passed.

Manual browser validation pending:
- Owner can grant/revoke `approve_members`.
- Owner can grant/revoke `view_cp` and `update_cp`.
- Leader/Vice can grant/revoke non-CP permissions inside scope.
- Leader/Vice cannot toggle `view_cp` or `update_cp`.
- Admin cannot see Permission Management UI.
- Member cannot see Admin tab.
- Network writes use only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes occur.
- No CP data/RPC calls occur from permission management.

## Milestone 8 Frontend CP Browser Validation Passed

Manual browser validation passed:
- Owner could see CP Management section.
- Owner could load CP roster.
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

Local stale-session note:
- After local DB reset, stale browser auth can cause a `profiles_id_fkey` registration error.
- Clear localStorage/sessionStorage after local DB resets before retesting auth/registration.
- This is a local browser/session issue, not a database migration/security failure.

## Milestone 8 Frontend CP Build Validation

Build:
- `npm.cmd run build` passed.

Implemented behavior awaiting manual browser validation:
- CP section visible only to Owner/Leader/Vice/Admin with `view_cp`.
- CP update controls visible only to Owner/Leader/Vice/Admin with `update_cp`.
- CP roster uses `get_current_cp_roster`.
- CP leaderboard uses `get_cp_leaderboard`.
- CP writes use `update_member_cp`.
- Missing CP displays as `Not entered`.

Security checks for manual validation:
- Member cannot see CP UI.
- Member Network tab shows no CP calls.
- No direct `member_cp` or `cp_snapshots` calls appear.
- CP does not appear on Dashboard, Profile, member-facing pages, or normal member roster cards.

## Milestone 8 Backend CP Hardening Validation Passed

Local validation passed:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.

Validated behavior:
- CP update for pending/rejected/suspended profiles is blocked.
- CP update for approved active profile works.
- Admin with `update_cp` cannot update CP for non-approved profiles.
- `get_current_cp_roster` includes approved active members with missing CP as `null`.
- Members still cannot read CP.
- Admin without `view_cp` still cannot read CP.
- Direct `member_cp` / `cp_snapshots` access remains blocked.
- CP update audit log works.
- No GvG logic changed.

## Milestone 8 Backend CP Hardening Validation Pending

Validation script updated with CP hardening checks:
- Owner cannot update CP for pending profile.
- Owner cannot update CP for rejected profile.
- Owner cannot update CP for suspended/non-approved profile.
- Owner can update CP for approved active profile.
- Admin with `update_cp` cannot update CP for non-approved profile.
- Admin with `update_cp` can update scoped approved active profile.
- `get_current_cp_roster` includes active approved member with missing CP row.
- Missing CP row returns `cp_value is null`.
- Member still cannot read CP roster.
- Admin without `view_cp` still cannot read CP roster.
- Direct `member_cp` access remains blocked.
- Direct `cp_snapshots` access remains blocked.
- CP update audit log is written.

Local validation is pending.

## Milestone 7 Frontend Browser Validation Passed

Manual browser validation passed:
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
- Network writes used only `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were found.

## Milestone 7 Frontend Build Validation

Build:
- `npm.cmd run build` passed.

Implemented frontend behavior awaiting manual browser validation:
- Owner can change member roles among `member`, `admin`, `vice`, and `leader`.
- `owner` is not exposed as a role option.
- Leader/Vice role-change options are limited to `member` and `admin`.
- Admin with `manage_roles` role-change options are limited to `member` and `admin`.
- Admin without `manage_roles` gets no role-change UI.
- Owner-only guild transfer UI is available.
- Transfer warning states that moving guild resets the member's role to Member.
- Successful role/guild actions refresh the roster.

Security checks for manual validation:
- Network writes should use only `assign_member_role` and `transfer_member_guild`.
- No direct `profiles`, `guild_memberships`, or `admin_permissions` writes should appear.
- No CP/GvG table or RPC calls should appear.

## Milestone 7 Backend Validation Passed

Local validation passed:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.

Validated behavior:
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

## Milestone 7 Backend Role/Guild Management Validation

Implementation status:
- SQL migration file created for backend role hardening and Owner-only member guild transfer.
- Local validation script updated with Milestone 7 role assignment and guild transfer checks.
- Validation has not been run yet.

Expected local validation:
- Apply migrations in local Supabase with a local database reset.
- Run `supabase/tests/local_validation_anteiku.sql`.
- Confirm role assignment checks pass:
  - Owner can assign `member`, `admin`, `vice`, and `leader`.
  - Owner cannot assign `owner` through normal app RPC.
  - Leader/Vice can assign only `member` and `admin` inside scope.
  - Admin with `manage_roles` can assign only `member` and `admin` inside scope.
  - Admin without `manage_roles` and Member cannot assign roles.
- Confirm guild transfer checks pass:
  - Owner can transfer an approved active member between guilds.
  - Old membership becomes `left` and non-primary.
  - New membership becomes active primary with role reset to `member`.
  - Exactly one active primary membership remains.
  - Leader/Vice/Admin/Member transfer attempts are blocked.
  - Role-change and transfer audit logs are written.

Security validation expectations:
- No CP table or CP RPC access is added.
- No GvG logic changes are added.
- Normal app RPCs cannot assign `owner`.
- Guild transfer is Owner-only in v1.

Milestone 1 validation commands:

```powershell
npm.cmd install
npm.cmd run build
npm.cmd audit
```

## 2026-05-14 Validation Result

- Initial Codex shell attempts using `npm install` and `npm run build` failed because `npm` was not available in that shell PATH.
- User local validation with `npm.cmd install`: passed.
- User local validation with `npm.cmd run build`: passed.
- `package-lock.json` was generated.
- `dist/` was generated.
- User local `npm.cmd audit`: completed with 2 moderate vulnerabilities.

## Audit Note

- Audit finding: `esbuild <=0.24.2` via `vite <=6.4.1`.
- Scope: Vite development server behavior.
- Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade.
- Do not upgrade Vite in Milestone 1.
- Track as a known development-only audit issue for now.

Manual QA targets:

- App renders on mobile-width layout.
- Navigation changes placeholder pages.
- No CP values appear anywhere.
- Pages clearly mark sensitive features as planned or placeholder.
- Supabase client does not query data.

Future QA must include RLS and direct Supabase API abuse checks.

## Milestone 2 Local Supabase Validation

Completed on 2026-05-14.

Result:

- Total PASS: 29
- Total FAIL: 0
- Total SKIP: 0
- Setup failures: 0
- Security failures: 0

Validated:

- Migrations apply locally with `npx.cmd supabase db reset`.
- Seeded guilds exist.
- `permission_catalog` exists.
- `view_cp` and `update_cp` are marked sensitive.
- RLS is enabled.
- Direct member table access to `member_cp` and `cp_snapshots` is blocked.
- Member CP RPC access is blocked.
- Admin without `view_cp` is blocked.
- Admin with `view_cp` can read scoped CP.
- Leader can read CP only in assigned guild.
- Leader wrong-guild CP is blocked.
- Admin with `approve_members` cannot approve Admin role.
- Admin with `approve_members` can approve Member role.
- GvG vote submit/switch keeps one row.
- Direct `gvg_votes` insert/update is blocked.
- Audit spoof insert is blocked.
- Approval/reapply audit flow works.
- Validation script rolls back local test data.

Security issue found and fixed during validation:

- Private helper parameter shadowing caused CP/RPC permission leakage.
- Example risk: ambiguous comparisons could make helpers like `is_owner`, `has_role`, or `has_permission` overly broad.
- Fixed by renaming helper parameters to prefixed `p_*` names and reviewing comparisons.
- Re-validation passed with 29 PASS / 0 FAIL / 0 SKIP.

## Milestone 3 Frontend Auth Browser Validation

Completed on 2026-05-14 against local Supabase.

Build:

- `npm.cmd run build`: passed after the AuthContext loading fix.

Manual browser result:

- Local Supabase badge shows correctly.
- Register flow worked.
- Created user is pending.
- Sign in works.
- Pending user is locked to the Pending page.
- Refresh status works.
- Sign out works.
- Hard refresh restores the session and returns the pending user to the Pending page.
- Signed-out refresh shows the Auth page.
- Stuck Loading state no longer reproduces.

Network/CP privacy check:

- No protected CP table or RPC calls were observed from the frontend.
- No `member_cp` calls.
- No `cp_snapshots` calls.
- No `get_current_cp_roster` calls.
- No `get_cp_leaderboard` calls.
- No `get_cp_growth_report` calls.

Resolved frontend bug:

- Cause: async `onAuthStateChange` callback could wedge session restore/loading state.
- Fix: keep auth callback synchronous, ignore duplicate `INITIAL_SESSION`, defer profile loading safely, and always clear state/loading on `signOut`.

## Milestone 4 Frontend Approval Workflow Validation

Implementation completed on 2026-05-14.

Build:

- `npm.cmd run build`: passed.

Implemented validation guardrails:

- No SQL migrations were edited.
- No Owner bootstrap was executed.
- No package files or dependencies were changed.
- Approval/rejection writes use only `approve_registration` and `reject_registration`.
- The frontend approval UI does not expose an Owner approval option.
- Source check found no protected CP table/RPC identifiers in `src`.

Manual browser validation passed:

- Local Owner bootstrap was applied manually outside migrations.
- Owner account `test1@local.dev` became approved Owner in Anteiku.
- Owner could access the app shell and Admin tab.
- Sign out button is visible in the approved app shell and works.
- Approval queue loaded pending users.
- Owner approved `test2` as Member.
- `test2` could sign in and access the app shell as member.
- `test2` had role `member` and guild `Anteiku:Re`.
- Admin tab was hidden for normal member.
- Owner rejected `test3` with reason.
- `test3` could sign in but was locked to `RejectedStatus`.
- Rejected user did not see app shell/member/admin screens.
- No CP UI or CP data was exposed during testing.

Resolved frontend bug:

- Approved app shell was missing a visible Sign out button.
- Fixed by adding Sign out to the `AppShell` header.
- `npm.cmd run build` passed after the fix.

## Milestone 5 Member Profile Editing Validation

Implementation completed on 2026-05-14.

Backend/RPC support confirmed:

- Existing RPC: `public.update_my_profile(p_ign text, p_avatar_key text default null)`.
- The RPC requires authentication through `auth.uid()`.
- The RPC updates only the authenticated user's `ign`, `avatar_key`, and `updated_at`.
- It does not update username, profile slug, guild membership, role, or approval status.

Build:

- `npm.cmd run build`: passed.

Implemented validation guardrails:

- Profile edit mode updates IGN only.
- Avatar editing was not implemented; the current `avatar_key` is passed through to the RPC.
- Username, profile slug, guild, role, approval status, and avatar/profile icon are display-only.
- No direct `profiles` or `guild_memberships` table updates were added.
- Source check found no protected CP table/RPC identifiers in `src`.

Manual browser validation passed:

- Owner can edit own IGN.
- Member can edit own IGN.
- Changed IGN displays correctly after save.
- Empty/invalid IGN validation works or was checked as implemented.
- Cancel keeps/restores original IGN.
- Username/profile slug remained locked and not editable.
- Guild, role, and approval status remained display-only.
- Avatar editing was not implemented.
- Profile update used `update_my_profile` RPC only.
- No direct `profiles` or `guild_memberships` updates were added.
- No protected CP table/RPC calls were added or observed.

## Milestone 6 Admin Member Management Validation

Implementation completed on 2026-05-14.

Backend/RPC support confirmed:

- Existing RPC: `public.admin_update_member_ign(p_profile_id uuid, p_ign text)`.
- Existing RPC: `public.admin_reset_profile_slug(p_profile_id uuid, p_new_slug text)`.
- `admin_update_member_ign` requires `auth.uid()`, validates non-empty IGN, checks `private.can_edit_member_ign`, updates target `ign`, and writes audit metadata.
- `admin_reset_profile_slug` requires `auth.uid()`, normalizes lowercase slug, validates slug format, checks `private.can_reset_profile_slug`, updates `username` and `profile_slug` together, and writes audit metadata.

Build:

- `npm.cmd run build`: passed.

Implemented validation guardrails:

- Roster shows active memberships with approved profiles only.
- Pending, rejected, left, and suspended memberships are excluded.
- Owner/Leader/Vice can see member management by role.
- Admin can see member management only with `manage_members`, `edit_member_ign`, or `reset_profile_slug`.
- Member-management writes use only `admin_update_member_ign` and `admin_reset_profile_slug`.
- No direct `profiles`, `guild_memberships`, or `admin_permissions` writes were added.
- Source check found no protected CP table/RPC identifiers in `src`.

Manual browser validation passed:

- Owner can view active approved roster across returned guilds.
- Owner can filter by guild.
- Owner can edit another member's IGN.
- Owner can reset another member's username/profile slug.
- Roster excludes pending/rejected/left/suspended users.
- Owner edited `test2` member IGN successfully.
- `test2` saw updated IGN after sign in.
- Owner reset `test2` username/profile_slug successfully.
- `username` and `profile_slug` stayed equal and lowercase.
- `test2` could still sign in by email.
- `test2` remained Member in Anteiku:Re.
- Admin tab remained hidden for normal member.
- No CP table/RPC calls were found in Network tab.

New product requirement for future milestone:

- Admins/staff should be able to change a member's guild and role.
- This requires separate Milestone 7 planning/security review and must not be added as an unsafe quick patch.

## Milestone 7 Backend Role/Guild Validation

Implementation files were updated on 2026-05-15. Local validation is pending.

Migration to validate:

- `supabase/migrations/20260515000100_member_guild_role_management.sql`

Validation script updated:

- `supabase/tests/local_validation_anteiku.sql`

Planned validation coverage:

- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner`.
- Leader/Vice can assign `member` and `admin` in scope.
- Leader/Vice cannot assign `vice`, `leader`, or `owner`.
- Admin with `manage_roles` can assign `member` and `admin`.
- Admin cannot assign `vice`, `leader`, or `owner`.
- Admin without `manage_roles` cannot assign roles.
- Member cannot assign roles.
- Owner can transfer member guild.
- Transfer resets role to `member`.
- Old membership becomes `left`.
- New membership is active primary.
- Exactly one active primary membership remains.
- Leader/Vice/Admin/Member transfer is blocked.
- Audit logs are written.
- No CP access is added.

Recommended validation commands are documented in `docs/TESTING.md`.
## Milestone 18D/18E AdminPanel Translation Validation

Implementation/build validation completed locally:

- `npm.cmd run build`: passed.
- No `supabase/` files changed.
- No `src/services/` files changed.
- Static protected-table source check found no new direct frontend calls to `member_cp`, `cp_snapshots`, `audit_logs`, `member_status_history`, `gvg_votes`, or `guild_memberships`.
- AdminPanel translations are display-only. Permission keys, roster status values, audit action values, membership status values, GvG status values, usernames, IGN, guild names, CP values, GvG event titles, absence reasons, and user-generated notes remain logic/raw values.

Authenticated staging validation:

- Milestone 18E passed against staging through the local frontend.
- `staging_owner` validated AdminPanel EN/FR/DE translations across Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- `staging_admin_noperms` validated restricted-admin state.
- Member/pending sanity checks were intentionally skipped by user direction in 18E because they were already covered in Milestone 18C.
- No missing-key strings were visible.
- No console errors were captured.
- Mobile FR/DE layout remained usable.
- CP privacy, audit access, GvG behavior, permissions, and member-status behavior remained unchanged.
