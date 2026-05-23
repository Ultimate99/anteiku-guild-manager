# Testing

## Milestone 14H Staging CP Redaction And GvG Smoke Validation

Milestone 14H is complete against staging `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.

Passed:
- CP audit redaction browser scenario.
- CP metadata visibility for a scoped `view_cp` user.
- Full GvG smoke test.
- Permission denial checks.
- Wrong-guild access denial.
- Pending-user lockout.
- Read-only SQL verification.

Key validation details:
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` saw `Sensitive CP metadata hidden.` and did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke`.
- `staging_member` voted Present, switched to Absent with reason, then switched back to Present.
- Owner closed the event.
- SQL confirmed exactly one `gvg_votes` row for `staging_member` and the event, final vote status `present`, and `absence_reason = null`.
- `staging_wrongguild` could not see or vote on the Anteiku event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.
- Active Owner count remained `1`.

Deferred production tests now covered in staging:
- Full GvG smoke test.
- CP audit redaction browser scenario.
- Permission denial flows.
- Wrong-guild access.
- Pending-user lockout.

Network caveat:
- Literal DevTools request capture was not available through browser automation.
- Source-path inspection confirmed Audit uses `get_audit_logs`.
- Source-path inspection confirmed CP uses `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- Source-path inspection confirmed GvG writes use approved RPCs, with the own-vote `gvg_votes` read expected and safe.
- This is a recorded caveat, not a 14H blocker.

Scope:
- Production was not touched.
- Vercel Preview was not configured.
- No deployment was performed.
- No source files or SQL migrations were changed.
- Test data remains in staging intentionally.

## Future CP Update Window / Member CP Self-Submit Validation

Future feature candidate only. Do not treat this as implemented.

Corrected CP privacy rule:
- Members can see their own CP through an approved backend/RPC flow.
- Members can submit/update only their own CP through an approved backend/RPC flow.
- Members cannot see other members' CP.
- Members cannot see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Members cannot directly query `member_cp` or `cp_snapshots`.

Future validation requirements:
- Member can see own CP.
- Member cannot see other members' CP.
- Member cannot access CP roster/leaderboard/snapshots.
- Member can submit own CP while a CP Update Window is open.
- Member cannot submit CP while the window is closed.
- Member cannot submit CP for another profile.
- Wrong-guild member cannot use another guild's CP window.
- Admin can open/close CP window in scope.
- CP submission writes audit log.
- Audit metadata redacts correctly for users without `view_cp`.
- Network validation shows only safe RPCs such as `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.
- No direct `member_cp` or `cp_snapshots` frontend table calls occur.

## Milestone 14F Staging Owner Bootstrap Verification

Milestone 14F is complete for staging Owner bootstrap.

Verified:
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Staging Owner Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild: `Anteiku`.
- Role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_count = 1`.
- `owner_bootstrapped` audit log count: `1`.

Not done yet:
- No controlled staging test users existed at the 14F checkpoint; they were created later in 14G.
- Vercel Preview env is not configured.
- No staging browser validation with controlled users has been run.

Recommended next test planning:
- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution.

## Milestone 14E Staging Supabase Verification

Milestone 14E is complete for staging Supabase migration/apply/verification.

Staging project:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Project URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.

Verified:
- Same 9 migrations as production were applied to staging.
- Migration history matched after apply.
- Schema/RLS/seed verification passed.
- Permission catalog count is 10.
- Permission catalog exactly matches `20260514000400_seed_core_data.sql`.
- Earlier "7 permissions" report was a partial summary mistake.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.

Not done yet:
- Staging Owner was not created during 14E; it was bootstrapped later in Milestone 14F.
- No staging test users exist.
- Vercel Preview env is not configured.
- No staging browser validation with controlled users has been run.

Recommended next test planning:
- Milestone 14F: staging Owner bootstrap planning. Completed later.

## Milestone 14D Staging And Preview Test Plan

Milestone 14D was documentation-only. No staging Supabase project was created during 14D, no Supabase commands were run, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were edited.

Milestone 14E later created/linked staging and applied/verified the same 9 migrations as production. Future staging browser validation should use separate Auth users/test data.

Required staging-only test users:
- Owner.
- Approved Member.
- Admin with `view_audit_logs` but without `view_cp`.
- Admin with both `view_audit_logs` and `view_cp`.
- Wrong-guild Member.
- Pending user.

Move these deferred production tests to staging:
- Full GvG smoke test: create event, open voting, Member votes Present, switches Absent with reason, switches back Present, and one vote row remains.
- CP audit redaction browser scenario: staff with `view_audit_logs` but no `view_cp` sees redaction notice; staff with both permissions sees only backend-returned metadata.
- Permission denial flows for Admin without needed permissions, Member, and pending users.
- Wrong-guild access checks.
- Cleanup/archive experiments.

Network checks in staging should confirm:
- Audit viewer uses `get_audit_logs` only.
- CP UI uses approved CP RPCs only.
- GvG uses approved GvG RPCs/safe reads only.
- Member pages make no CP calls.
- No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes.

## Milestone 14A Production Hardening Test Policy

Milestone 14A is documentation-only. No production commands, source changes, SQL changes, Vercel changes, GitHub App changes, user disable/delete actions, deployment, or commit were performed.

Current production validation status:
- Milestone 13B production smoke/security validation passed.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Owner login, AdminPanel, Audit Logs, CP Management, pending lockout, Member approval, Member CP denial, Network checks, and mobile checks passed.
- Controlled test member remains in production: `krsticmiroslav99+m13b21144225@gmail.com`.

Deferred production tests:
- GvG production smoke remains intentionally not tested to avoid persistent production GvG test data without a cleanup/delete flow.
- CP redaction browser scenario remains intentionally not tested because the needed production staff/data combination does not exist.
- GvG has Milestone 10 local live-browser validation coverage.
- Audit CP metadata redaction has Milestone 11A backend validation and Milestone 11B audit-viewer source/browser validation coverage.

Future safe testing strategy:
- Prefer a separate staging Supabase project for production-like GvG and CP-redaction browser tests.
- Keep Vercel Preview env unconfigured until staging exists.
- Never point Preview deployments at production by default.
- Run production tests that create persistent data only after explicit approval and a cleanup/data-retention plan.
- Continue clearing DevTools Network before each targeted CP, audit, GvG, member, or admin validation action.

## Milestone 12 Production Readiness Documentation

Milestone 12 is a documentation-only production readiness pass.

Updated production testing guidance:
- Use [DEPLOYMENT.md](DEPLOYMENT.md) for the future production Supabase and Vercel deployment runbook.
- Use [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) for the future launch checklist.
- Do not run `supabase/tests/local_validation_anteiku.sql` against production; it is local/disposable only and inserts fake auth users/test data before rollback.
- Do not run `supabase db reset` against production.
- Production validation must use controlled real test users, browser checks, network inspection, and read-only SQL checks where useful.

Future production validation must include:
- Guild seed rows exist.
- Permission catalog exists and CP permissions are sensitive.
- RLS is enabled on protected tables.
- Functions and grants exist.
- Owner bootstrap is verified.
- Pending users are blocked.
- Members cannot see CP.
- Scoped staff CP access works only in scope.
- Admin without permissions is denied.
- Wrong-guild access is denied.
- GvG vote switching keeps one row per event/profile.
- Audit viewer uses `get_audit_logs`.
- CP-sensitive audit metadata redacts without scoped `view_cp`.
- Vercel smoke test passes.
- Network checks confirm no unsafe CP/audit/GvG calls.

## Milestone 11B Frontend Audit Log Viewer Validation Passed

Build:
- `npm.cmd run build` passed.

Static/source validation passed:
- AdminPanel audit viewer uses `src/services/adminAuditService.js`.
- `adminAuditService.js` calls only `get_audit_logs` for audit reads.
- No frontend `supabase.from('audit_logs')` calls were found.
- No CP RPC/table calls were found in the audit viewer path.
- No audit write/update/delete/export UI was added.
- No SQL migrations were changed.
- `public.get_audit_logs(...)` was not changed.

Manual browser validation passed:
- Owner loaded Audit Logs successfully.
- Owner filters worked safely.
- Load Older pagination worked correctly.
- Leader/Vice saw assigned guild logs only.
- Admin with `view_audit_logs` loaded scoped logs.
- Admin without `view_audit_logs` could not view logs.
- Normal approved Member could not access audit logs.
- Pending user could not access audit logs.
- CP metadata was hidden/redacted for users without `view_cp`.
- CP metadata appeared only for an authorized `view_cp` user when the backend returned it.
- Metadata rendered compactly and safely.
- Action, guild, date, and limit filters worked.
- Empty and permission/error states were clean.
- Audit viewer was readable and usable on mobile viewport.

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

Local validation:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.

Milestone 11A result:
- 14 PASS
- 0 FAIL
- 0 SKIP

Validated:
- Owner can read global audit logs through `get_audit_logs`.
- Leader/Vice can read scoped guild audit logs.
- Admin with `view_audit_logs` can read scoped audit logs.
- Admin without `view_audit_logs`, Member, and pending users cannot read audit logs.
- Admin with `view_audit_logs` but without `view_cp` receives redacted CP metadata.
- Admin with both `view_audit_logs` and `view_cp` receives scoped CP metadata.
- Direct `audit_logs` SELECT returns no rows for non-Owner.
- `authenticated` has no EXECUTE privilege on `private.write_audit_log`.
- Audit spoof insert remains blocked.

Validation note:
- Directly executing `private.write_audit_log` as `authenticated` caused a local Postgres container segfault, so validation checks the revoked EXECUTE privilege with `has_function_privilege` instead.

## Milestone 10 GvG Browser Validation Passed

Build:
- `npm.cmd run build` passed.

Manual browser validation passed:
- Owner logged in and accessed AdminPanel.
- Owner created a draft GvG event and opened voting.
- Active event appeared in AdminPanel.
- Same-guild approved Member logged in and saw the active event on the GvG page.
- Awaiting-event state appeared when no active event existed.
- Member voted Present and the vote persisted after refresh.
- Member switched to Absent with a reason and the Absent state plus own reason persisted after refresh.
- Member switched back to Present and the vote persisted after refresh.
- Read-only SQL confirmed `count(*) = 1` for the event/profile vote row.
- Read-only SQL confirmed final `vote_status = present` and `absence_reason = null`.
- Authorized staff saw present/absent counts and absence reasons.
- Normal Member could not see other users' absence reasons.
- Admin without `manage_gvg` could not manage events.
- Wrong-guild Member could not see/vote for the guild-specific event.
- Out-of-scope Leader/Vice/Admin could not manage the event.
- Owner/staff closed voting successfully.
- Closed event rejected vote changes.
- After clearing Network following initial AdminPanel load, GvG actions used only GvG RPCs/safe reads.
- No CP RPC/table calls were triggered by GvG actions after Network was cleared.
- No direct frontend insert/update/upsert/delete calls to `gvg_votes` or `gvg_events` were observed.

Read-only SQL validation summary:
- Event found: yes.
- Event title: `M10 Live Test GvG`.
- Event status after open: `active`.
- Event status after close: `closed`.
- Event scope: guild.
- Event guild matched the tested member's guild.
- Member found: yes.
- Member approval status: `approved`.
- Member membership status: `active`.
- Member role: `member`.
- Final vote rows: `1`.
- Final vote status: `present`.
- Final absence reason: `null`.

Network validation summary:
- Initial AdminPanel CP calls before clearing Network were ignored as outside the GvG action window.
- After clearing Network, observed GvG calls were limited to `create_gvg_event`, `set_gvg_event_status`, `submit_gvg_vote`, `get_gvg_results`, safe `gvg_events` reads, and safe own-vote `gvg_votes` reads.
- No `get_current_cp_roster`, `get_cp_leaderboard`, `update_member_cp`, `get_cp_growth_report`, `member_cp`, or `cp_snapshots` calls occurred during GvG actions.
- No direct frontend writes to `gvg_votes` or `gvg_events` occurred.

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

Build:
- `npm.cmd run build` passed.

Manual browser validation still needed:
- Owner can view Permission Management.
- Owner can grant/revoke `approve_members`.
- Owner can grant/revoke `view_cp` and `update_cp`.
- Admin gains/loses frontend access after permission changes.
- Leader/Vice can manage non-CP Admin permissions only inside assigned guild scope.
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

Local reset note:
- After local DB reset, stale browser auth can cause a `profiles_id_fkey` registration error.
- Clear localStorage/sessionStorage before retesting auth/registration after local DB resets.
- This is local stale session state, not a migration/security issue.

## Milestone 8 Frontend CP Build Validation

Build:
- `npm.cmd run build` passed.

Manual browser validation still needed:
- Owner sees CP section.
- Owner updates member CP.
- Owner sees leaderboard.
- Leader sees scoped CP only.
- Admin without `view_cp` cannot see CP section.
- Admin with `view_cp` can view but not update.
- Admin with `update_cp` can update.
- Member cannot see CP UI.
- Member Network tab shows no CP calls.
- Network tab shows no direct `member_cp` / `cp_snapshots` calls.
- CP reads use `get_current_cp_roster` / `get_cp_leaderboard`.
- CP writes use `update_member_cp`.
- CP does not appear on Dashboard/Profile/member pages.

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

Local validation should confirm:
- Owner cannot update CP for pending/rejected/suspended profiles.
- Owner can update CP for approved active profile.
- Admin with `update_cp` cannot update CP for non-approved profile.
- Admin with `update_cp` can update scoped approved active profile.
- CP roster includes active approved members with missing CP.
- Missing CP returns `null`.
- Member cannot read CP roster.
- Admin without `view_cp` cannot read CP roster.
- Direct `member_cp` and `cp_snapshots` access remains blocked.
- CP update audit log is written.

Suggested commands:
```powershell
npx.cmd supabase db reset
```

Then run:
```txt
supabase/tests/local_validation_anteiku.sql
```

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
- Network writes used `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were found.

## Milestone 7 Frontend Build Validation

Build:
- `npm.cmd run build` passed.

Manual browser validation still needed:
- Owner changes `test2` role `member -> admin -> member`.
- Owner cannot select `owner`.
- Owner transfers `test2` from `Anteiku:Re` to `Anteiku`.
- Transfer warning appears before confirm.
- Transfer resets `test2` role to `member`.
- `test2` can sign in after transfer.
- `test2` sees the new guild and member role.
- Normal Member still cannot see Admin tab.
- Network writes only use `assign_member_role` and `transfer_member_guild`.
- Network tab shows no CP/GvG calls.

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

## Milestone 7 Backend Role/Guild Management

Implementation status:
- Backend SQL/RPC migration has been created.
- Local validation script has been updated.
- Local validation has not been run yet.

Required local validation:
- Reset the local Supabase database so the new migration applies.
- Run the local validation SQL script.
- Confirm all Milestone 7 role assignment and guild transfer checks pass.

Expected checks:
- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner` through normal app RPC.
- Leader/Vice can assign only `member` and `admin` inside guild scope.
- Admin with `manage_roles` can assign only `member` and `admin` inside guild scope.
- Admin without `manage_roles` and Member cannot assign roles.
- Owner can transfer an approved active member between guilds.
- Transfer resets role to `member`.
- Old membership becomes `left` and remains preserved.
- New membership is active primary.
- Exactly one active primary membership remains.
- Leader/Vice/Admin/Member transfer attempts are blocked.
- Audit logs are written.
- No CP table/RPC access is added.

Suggested commands:
```powershell
npx.cmd supabase db reset
```

Then run:
```txt
supabase/tests/local_validation_anteiku.sql
```

Use the local Supabase SQL editor or a local database client for the validation script if the CLI SQL execution command is unavailable.

Milestone 1 validation:

```powershell
npm.cmd install
npm.cmd run build
npm.cmd audit
```

## Current Result

On 2026-05-14, local validation completed:

- `npm.cmd install`: passed.
- `npm.cmd run build`: passed.
- `package-lock.json` was generated.
- `dist/` was generated.
- `npm.cmd audit`: completed with 2 moderate vulnerabilities.

Audit finding: `esbuild <=0.24.2` via `vite <=6.4.1`. This affects Vite dev-server behavior. Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade. Do not upgrade Vite in Milestone 1.

Future critical QA:

- Pending users cannot access member or admin data.
- Members cannot query CP directly.
- Admin CP visibility works only for approved roles and guild permissions.
- Wrong-guild access is rejected.
- GvG duplicate votes are prevented by database constraint.
- Vote switching updates one row.
- Absence reasons are visible to authorized admins.
- Mobile layout works on small screens.

## Supabase Local Validation

Milestone 2 local Supabase validation passed on 2026-05-14.

Result:

- Total PASS: 29
- Total FAIL: 0
- Total SKIP: 0
- Setup failures: 0
- Security failures: 0

Validated:

- Migrations apply with `npx.cmd supabase db reset`.
- Seeded guilds and permission catalog exist.
- `view_cp` and `update_cp` are marked sensitive.
- RLS is enabled.
- Members cannot directly read CP tables.
- Members cannot access CP through RPC.
- Admin without `view_cp` is blocked.
- Admin with `view_cp` can read scoped CP.
- Leader can read CP only in assigned guild.
- Wrong-guild CP access is blocked.
- GvG vote submit/switch keeps one row.
- Direct `gvg_votes` insert/update is blocked.
- Admin with `approve_members` cannot approve Admin role.
- Admin with `approve_members` can approve Member role.
- Audit spoof insert is blocked.
- Approval/reapply audit flow works.
- Validation script rolls back local test data.

Validation caught and fixed a real security issue: private helper parameter shadowing caused CP/RPC permission leakage. Helper parameters were renamed to `p_*`, and validation then passed cleanly.

## Milestone 3 Frontend Auth Validation

After frontend auth implementation, validate against local Supabase only.

Build:

```powershell
npm.cmd run build
```

Result after Milestone 3 implementation: passed.

Manual browser validation result after AuthContext loading fix: passed.

Manual checks:

- `.env.local` points to local Supabase with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Sign in with invalid credentials shows an error.
- Sign up with valid credentials and an active session calls `register_profile`.
- If email confirmation prevents an active signup session, UI shows a confirm-email message and does not claim registration completed.
- Pending users see only the pending approval page.
- Pending refresh reloads safe profile/membership status.
- Rejected users see only the rejected page.
- Suspended users see only the suspended page.
- Approved users see the app shell.
- Admin panel navigation is hidden for normal members and shown for owner/leader/vice/admin roles.
- Browser/network inspection shows no frontend calls to protected CP tables or CP RPCs.

Validated manual browser behavior:

- Local Supabase badge shows correctly.
- Register flow works.
- Created user is pending.
- Sign in works.
- Pending user is locked to the Pending page.
- Refresh status works.
- Sign out works.
- Hard refresh restores the session and returns the pending user to the Pending page.
- Signed-out refresh shows the Auth page.
- Stuck Loading state no longer reproduces.

Network/CP privacy validation:

- No `member_cp` calls.
- No `cp_snapshots` calls.
- No `get_current_cp_roster` calls.
- No `get_cp_leaderboard` calls.
- No `get_cp_growth_report` calls.

Resolved frontend validation bug:

- Cause: async `onAuthStateChange` callback could wedge session restore/loading state.
- Fix: keep auth callback synchronous, ignore duplicate `INITIAL_SESSION`, defer profile loading safely, and always clear state/loading on `signOut`.

## Milestone 4 Approval Workflow Validation

Build:

```powershell
npm.cmd run build
```

Result after Milestone 4 implementation: passed.

Manual browser validation result: passed.

Validated:

- Local Owner bootstrap was applied manually outside migrations.
- Owner account `test1@local.dev` became approved Owner in Anteiku.
- Owner could access app shell and Admin tab.
- Sign out button is visible in approved app shell and works.
- Approval queue loaded pending users.
- Owner approved `test2` as Member.
- `test2` could sign in and access app shell as member.
- `test2` had role `member` and guild Anteiku:Re.
- Admin tab was hidden for normal member.
- Owner rejected `test3` with reason.
- `test3` could sign in but was locked to RejectedStatus.
- Rejected user did not see app shell/member/admin screens.
- No CP UI or CP data was exposed during testing.

Milestone 4 frontend guardrails:

- Approval writes use `approve_registration` and `reject_registration` only.
- The frontend does not directly update profiles or memberships.
- No Owner assignment option is exposed in the approval UI.
- No SQL migrations, package files, or Owner bootstrap templates were changed.

Resolved Milestone 4 UX bug:

- Approved app shell initially had no visible Sign out button.
- Fixed by adding Sign out to the `AppShell` header.
- `npm.cmd run build` passed after the fix.

## Milestone 5 Member Profile Editing Validation

Build:

```powershell
npm.cmd run build
```

Result after Milestone 5 implementation: passed.

RPC confirmed before implementation:

- `public.update_my_profile(p_ign text, p_avatar_key text default null)`
- Uses `auth.uid()`.
- Updates only own `ign`, `avatar_key`, and `updated_at`.
- Does not update username, profile slug, guild, role, or approval status.

Manual browser validation result: passed.

- Owner can edit own IGN.
- Member can edit own IGN.
- Changed IGN displays correctly after save.
- Empty/invalid IGN validation works or was checked as implemented.
- Cancel keeps/restores original IGN.
- Username/profile slug stayed read-only.
- Guild, role, and approval status stayed display-only.
- Avatar/profile icon stayed display-only; avatar editing was not implemented.
- Profile update used `update_my_profile` RPC only.
- No direct `profiles` or `guild_memberships` updates were added.
- Network tab showed no protected CP table/RPC calls.

Milestone 5 guardrails:

- Profile edit writes use `update_my_profile` only.
- The frontend does not directly update `profiles` or `guild_memberships`.
- No SQL migrations, package files, or dependencies were changed.

## Milestone 6 Admin Member Management Validation

Build:

```powershell
npm.cmd run build
```

Result after Milestone 6 implementation: passed.

RPCs confirmed before implementation:

- `public.admin_update_member_ign(p_profile_id uuid, p_ign text)`
- `public.admin_reset_profile_slug(p_profile_id uuid, p_new_slug text)`

Confirmed RPC behavior:

- Both use `auth.uid()`.
- IGN edit checks `private.can_edit_member_ign`.
- Slug reset normalizes lowercase, validates format, checks `private.can_reset_profile_slug`, and updates `username` and `profile_slug` together.
- Both write audit metadata.

Manual browser validation result: passed.

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
- Network tab shows no protected CP table/RPC calls.

Milestone 6 guardrails:

- No direct `profiles`, `guild_memberships`, or `admin_permissions` writes.
- No CP UI, CP editing, CP leaderboard, GvG UI, role promotion/demotion UI, permission checkbox UI, audit log UI, hard deletes, or suspended/left/rejected member management.
- No SQL migrations, package files, or dependencies were changed.

New requirement for later testing:

- Admin/staff member guild and role changes are needed, but must be planned separately in Milestone 7 with security review.
