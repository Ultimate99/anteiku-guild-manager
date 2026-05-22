# Project State

## Milestone 14C AdminPanel Tabs Complete In Production

Milestone 14C is complete. The frontend-only AdminPanel organization refactor was implemented, build/source validated, committed/pushed to GitHub `main`, deployed by Vercel, and manually production-smoke validated at `https://anteiku-guild-manager.vercel.app`.

Implemented:
- Split the large AdminPanel into section components:
  - `src/components/admin/AdminTabs.jsx`
  - `src/components/admin/AdminApprovalsSection.jsx`
  - `src/components/admin/AdminMembersSection.jsx`
  - `src/components/admin/AdminCpSection.jsx`
  - `src/components/admin/AdminGvgSection.jsx`
  - `src/components/admin/AdminAuditSection.jsx`
  - `src/components/admin/AdminPermissionsSection.jsx`
  - `src/components/admin/AdminToolsSection.jsx`
- Kept `src/pages/AdminPanel.jsx` as the coordinator for auth/session context, current membership, permission-key loading, visible-tab calculation, active tab state, and action handlers.
- Added mobile-first horizontal admin tabs:
  - Approvals
  - Members
  - CP
  - GvG
  - Audit Logs
  - Permissions
  - Tools
- Added sticky dark/crimson tab styling in `src/styles/app.css`.
- Rendered only the active AdminPanel section.
- Lazy-loaded CP, Audit Logs, and GvG management sections when their tabs are opened instead of on initial AdminPanel render.

Build/source validation:
- `npm.cmd run build` passed.
- No SQL migration files changed.
- No source service behavior changes were made.
- New admin section components do not import services or call Supabase directly.
- Static source checks found no frontend direct `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('audit_logs')` calls.
- Audit reads remain isolated through `src/services/adminAuditService.js` and `get_audit_logs`.
- CP reads/writes remain isolated through approved CP RPCs in `src/services/adminCpService.js`.
- GvG paths remain through existing `src/services/gvgService.js` safe reads/RPCs; no new GvG service calls were added.

Local browser/source-path validation:
- Owner and admin tab switching passed.
- Mobile `390px` tab UX passed.
- Lazy-load/network validation passed through local Kong logs:
  - CP tab used only `get_current_cp_roster` and `get_cp_leaderboard`.
  - Audit tab used only `get_audit_logs`.
  - GvG tab used safe `gvg_events` read only.
  - No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- No major console errors or tab-refactor bugs were found.

Production rollout validation:
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Owner login passed.
- AdminPanel opened.
- Admin tabs were visible.
- Owner switched Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Audit Logs tab loaded.
- CP tab loaded.
- Mobile tab layout was usable.
- Member could not access AdminPanel.

Scope confirmation:
- No SQL migrations changed.
- No Supabase schema/RLS/RPC logic changed.
- No CP, GvG, audit, role/guild, or permission behavior changed.
- No source, SQL, Supabase, Vercel env, deployment, or commit action was performed during the final documentation checkpoint.

## Milestone 14B Vercel GitHub App Restriction Checkpoint Complete

Milestone 14B is complete as a verification and documentation checkpoint.

Completed:
- Recorded user-confirmed manual Vercel GitHub App restriction.
- Vercel GitHub App installation is limited to `Ultimate99/anteiku-guild-manager`.
- Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Production URL remains `https://anteiku-guild-manager.vercel.app`.
- Production app health was checked in the browser.
- Browser check loaded title `Anteiku Guild Manager`.
- No captured browser console errors were observed during this checkpoint.
- No Vercel env vars were changed.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No Supabase schema/RLS/RPC changes were made.
- No production commands were run.
- No deployment was performed.
- No commit was made.

Recommended next milestone:
- Milestone 14C planning: staging Supabase + Vercel Preview environment setup, or controlled production test-member cleanup planning.

## Milestone 14A Production Hardening Policy Docs Complete

Milestone 14A is complete as a documentation-only production hardening and cleanup policy pass.

Completed:
- Documented manual Vercel GitHub App restriction checklist.
- Recorded that Vercel GitHub App restriction is recommended but was not executed.
- Documented controlled production test member policy.
- Recorded controlled test member remains in production:
  - Email: `krsticmiroslav99+m13b21144225@gmail.com`.
  - Username/profile slug: `m13bmember21056302`.
  - IGN: `M13B Member 21056302`.
  - Status: approved Member.
- Documented Preview/Staging policy:
  - Production env only on Production deployments.
  - Preview env should have no Supabase env vars until staging exists.
  - Future staging Supabase must be separate from production.
  - Preview deployments must not mutate production by default.
- Recorded deferred production smoke tests:
  - GvG production smoke remains deferred to avoid persistent production GvG test data.
  - CP redaction browser scenario remains deferred due missing production staff/data combination.
- Added launch operations guidance for approvals, audit monitoring, CP updates, GvG events, admin permissions, and production SQL safety.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No production commands were run.
- No Vercel settings were changed.
- No GitHub App settings were changed.
- No users were disabled, deleted, or suspended.
- No deployment was performed.
- No commit was made.

Recommended next milestone:
- Milestone 14B: manual Vercel GitHub App restriction, controlled test-member cleanup planning, or staging/preview setup planning only after explicit approval.

## Milestone 13B Production Deployment Complete

Milestone 13B Vercel setup, Supabase Auth URL configuration, and production smoke/security validation are complete.

Completed:
- Vercel project deployed from `Ultimate99/anteiku-guild-manager` on production branch `main`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel framework preset: Vite.
- Vercel build command: `npm run build`.
- Vercel output directory: `dist`.
- Production Vercel env uses only browser-safe frontend variables:
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY`
- No service role key, database password/URL, JWT secret, SMTP/OAuth secret, provider secret, or `sb_secret_*` key was configured in frontend/Vercel env.
- Supabase Auth Site URL is set to `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Redirect URL allow-list includes `https://anteiku-guild-manager.vercel.app`.
- Production app loads successfully.
- Owner login and AdminPanel access passed.
- Owner mobile AdminPanel validation passed.
- Audit Logs are readable/usable on desktop and mobile.
- CP Management is readable/usable on desktop and mobile.
- Controlled signup created a pending production user after email confirmation.
- Pending user was locked out of member/admin areas.
- Owner approved the controlled user as Member.
- Approved Member login passed.
- Approved Member cannot access AdminPanel.
- Approved Member does not see CP values.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls in manual Network validation.
- Audit Logs Network validation observed `rpc/get_audit_logs` only for audit viewer reads.
- No direct `/rest/v1/audit_logs` calls were observed from Audit Logs actions.
- No CP RPC/table calls or audit write/update/delete/export calls were observed from Audit Logs actions.
- CP Management Network validation observed approved CP RPCs only.
- No direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- No bugs were found.

Production controlled test member:
- Email: `krsticmiroslav99+m13b21144225@gmail.com`.
- Username/profile slug: `m13bmember21056302`.
- IGN: `M13B Member 21056302`.
- Status: approved Member.
- Note: this controlled test member remains in production unless a later cleanup/member-management action is explicitly approved.

Deferred / intentionally not tested in production:
- GvG production smoke was not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- GvG was fully live-browser validated locally in Milestone 10, and production source/static path validation confirms approved RPCs/safe reads.
- CP redaction browser test was not tested in production because there is no current staff user/data combination with `view_audit_logs` but without `view_cp` and a fresh CP-sensitive audit entry.
- Backend CP metadata redaction was validated in Milestone 11A, and the audit viewer source uses only `get_audit_logs`.

Security note:
- Restrict the Vercel GitHub App installation to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No Supabase schema/RLS/RPC changes were made.
- No Vercel env changes were made after final validation.
- No deployment rerun was performed during final validation review.
- No commit was made.

Recommended next milestone:
- Milestone 14 planning: choose the next production-safe feature or operational cleanup task, such as production test-member cleanup policy, staging/preview environment setup, reapply flow, suspended/left/rejected member management, weekly CP snapshot/growth report UI, or guild/subguild management.

## Milestone 13A Production Supabase Checkpoint

Milestone 13A production Supabase setup completed the database-side production checkpoint.

Completed:
- Fresh production Supabase project exists.
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations were applied remotely.
- `npx.cmd supabase migration list` showed local and remote migration history matched.
- Production schema/RLS/seed verification passed.
- Protected tables, RLS, policies, RPCs, grants, indexes, and seed data were verified.
- Owner bootstrap was run manually using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.
- Exactly one active Owner membership exists.
- Owner profile is approved.
- `owner_bootstrapped` audit log exists.

Owner bootstrap record:
- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_membership_count = 1`.
- `owner_active_primary_membership_count = 1`.
- `owner_bootstrap_audit_count = 1`.

Scope confirmation at the time of the 13A checkpoint:
- No source logic changed during the checkpoint documentation pass.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No Supabase commands were run during this documentation checkpoint.
- Owner bootstrap was not rerun.
- Vercel had not been configured yet.
- Production deployment had not happened yet.
- No commit was made.

Local tooling note:
- Supabase CLI was installed locally as dev tooling during Milestone 13A.
- The CLI tooling/package changes were committed before Milestone 13B planning/execution.

Historical next milestone:
- Milestone 13B: Vercel setup + Supabase Auth URL configuration + production smoke/security validation. This was completed later.

## Milestone 12 Production Readiness Docs Complete

Milestone 12 was implemented as a documentation-only production readiness pass.

Created/updated:
- `docs/PRODUCTION_CHECKLIST.md`
- `docs/DEPLOYMENT.md`
- `docs/SETUP.md`
- `.env.example`
- `README.md`
- `docs/TESTING.md`
- `docs/CHANGELOG.md`
- supporting stale-doc refreshes for database/RLS/roles docs
- ai_agents handoff files

Scope confirmation:
- No source logic changed.
- No React files changed.
- No Supabase migrations changed.
- No SQL migrations were created.
- No production Supabase project was linked.
- No production commands were run.
- No deployment was performed.
- No dependencies were added.
- No commit was made.

Milestone 12 documents:
- Fresh production Supabase project required.
- Production Auth Site URL and redirect URLs must be configured.
- Vercel env must include only browser-safe Vite variables: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- Owner bootstrap remains manual-only using a real production Auth user id.
- Production migration order is documented.
- `supabase db reset` is forbidden on production.
- `supabase/tests/local_validation_anteiku.sql` is local/disposable only and must not run on production because it inserts fake auth users and test data.
- `supabase/config.toml` references missing `./seed.sql`; core seed data currently comes from migration `20260514000400_seed_core_data.sql`, so `db push --include-seed` must not be used until that hazard is resolved.

Recommended next milestone:
- Milestone 13 should be production Supabase + Vercel setup only after explicit user approval.

## Milestone 11B Frontend Audit Log Viewer Complete

Milestone 11B frontend audit log viewer has been implemented, build-validated, source/security-path validated, and manually live-browser validated.

Implemented:
- New isolated audit service `src/services/adminAuditService.js`.
- Read-only AdminPanel Audit Logs section.
- Audit reads use only `public.get_audit_logs(...)`.
- Filters for action, safe/simple guild scope, date from/to, and limit.
- Default limit is 50 and UI max is 100.
- Load older uses `p_before` from the oldest loaded row.
- Loading, error, empty, and not-authorized states are present.
- Audit cards show action label, timestamp, actor, optional target, guild/global display, entity table/id, safe metadata summary, and CP redaction notice.
- Metadata rendering is whitelist-based and does not dump raw metadata JSON.

Security:
- No SQL migrations were changed.
- `get_audit_logs` was not changed.
- No direct frontend `audit_logs` table read was added.
- No audit write/update/delete/export UI was added.
- No CP table/RPC calls were added by audit viewing.
- No CP unredaction or CP value reconstruction was added.
- CP-sensitive redacted rows show `Sensitive CP metadata hidden.`
- Member and pending users do not get audit logs through the UI; Admins without `view_audit_logs` get a clean not-authorized state.

Validation:
- `npm.cmd run build` passed.
- Source check confirmed `src/services/adminAuditService.js` calls only `get_audit_logs`.
- Source check found no frontend `supabase.from('audit_logs')`.
- Source check found no CP RPC/table calls in the audit viewer path.
- Source check found no audit write/update/delete UI in the audit viewer path.
- Manual live browser validation passed with 23 PASS / 0 FAIL / 0 incomplete.
- Owner loaded audit logs, used filters, and used Load Older successfully.
- Leader/Vice and Admin with `view_audit_logs` saw scoped logs only.
- Admin without `view_audit_logs`, normal Member, and pending user could not access audit logs.
- CP-sensitive metadata was hidden for users without `view_cp` and shown only when the backend returned it for authorized `view_cp` users.
- Network validation after clearing initial AdminPanel load showed only `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- Mobile viewport validation passed.

## Milestone 11A Audit Log Read Hardening Validated

Backend audit-log read hardening has been implemented and locally validated. Milestone 11B frontend work has since been implemented and manually live-browser validated.

Implemented:
- New migration `supabase/migrations/20260515000300_audit_log_read_hardening.sql`.
- New safe audit reader RPC `public.get_audit_logs(...)`.
- Direct non-Owner `audit_logs` SELECT is restricted so scoped staff cannot bypass SQL-side redaction.
- CP-sensitive audit metadata is redacted for audit viewers who do not also have scoped `view_cp`.
- Owner can still read global audit logs through the RPC.
- Leader/Vice can read scoped guild audit logs through the RPC.
- Admin can read scoped audit logs only with `view_audit_logs`.

Validation:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 11A audit hardening checks passed: 14 PASS / 0 FAIL / 0 SKIP.
- Admin with `view_audit_logs` but without `view_cp` receives redacted CP metadata.
- Admin with `view_audit_logs` and `view_cp` receives scoped CP metadata.
- Member, pending user, and Admin without `view_audit_logs` are blocked.
- Direct `audit_logs` SELECT as non-Owner returns no rows.
- `authenticated` has no EXECUTE privilege on `private.write_audit_log`.
- Audit spoof insert remains blocked.

Validation note:
- A direct attempted execution of `private.write_audit_log` as `authenticated` caused a local Postgres container segfault instead of a clean permission error. The validation was adjusted to verify the revoked EXECUTE grant with `has_function_privilege`, which proves the direct call is not granted without crashing local Postgres.

## Milestone 10 GvG Browser Validation Passed

GvG event management and member voting persistence have been implemented, build-validated, and live browser validated.

Backend/RLS inspection passed before frontend work:
- `create_gvg_event` exists and enforces Owner/global or scoped `manage_gvg`.
- `set_gvg_event_status` exists and enforces scoped event management.
- `submit_gvg_vote` exists, validates active event scope, and upserts votes.
- `get_gvg_results` exists and restricts absence reasons to authorized staff.
- `gvg_votes_event_profile_uidx` enforces one vote row per event/profile.
- Member own-vote reads are RLS-protected.
- Staff result/reason access is RLS/RPC-protected.

Implemented:
- New isolated GvG service: `src/services/gvgService.js`.
- Member GvG voting UI in `src/pages/Gvg.jsx`.
- AdminPanel GvG management/results section.
- Event creation, open voting, close voting, present/absent counts, and absence reason review.

Security:
- Member votes use only `submit_gvg_vote`.
- Admin event writes use `create_gvg_event` and `set_gvg_event_status`.
- Staff result reads use `get_gvg_results`.
- No CP logic was changed.
- No direct `gvg_votes` writes were added.

Validation:
- `npm.cmd run build` passed.
- Corrected live browser validation passed.
- Owner created a draft GvG event, opened voting, verified active status, and closed voting after member/staff checks.
- Same-guild approved Member saw the active event, voted Present, refreshed successfully, switched to Absent with reason, refreshed successfully, then switched back to Present.
- Read-only SQL confirmed `vote_rows = 1`, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff saw present/absent counts and absence reasons.
- Normal Member could not see other users' absence reasons.
- Admin without `manage_gvg` could not manage events.
- Wrong-guild Member could not see/vote for the guild-specific event.
- Out-of-scope Leader/Vice/Admin could not manage the event.
- Closed event rejected vote changes.
- After clearing Network following initial AdminPanel load, GvG actions used only GvG RPCs/safe reads.
- No CP RPC/table calls were triggered by GvG actions.
- No direct frontend insert/update/upsert/delete calls to `gvg_votes` or `gvg_events` were observed.

## Milestone 9 Permission Management Validation Passed

Manual browser validation passed for Admin permission checkbox management.

Validated:
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

## Milestone 9 Permission Management Implementation Complete

Admin permission checkbox management has been implemented and build-validated.

Implemented:
- New isolated permission service: `src/services/adminPermissionService.js`.
- Permission Management section in AdminPanel.
- Permission targets are active approved Admin memberships only.
- Permission catalog is used as the source of permission labels/descriptions.
- Writes use only `grant_admin_permission` and `revoke_admin_permission`.
- Owner can manage all Admin permissions.
- Leader/Vice can manage non-CP Admin permissions inside assigned guild scope.
- CP permission checkboxes are disabled for Leader/Vice with Owner-only messaging.
- Admin users cannot see Permission Management UI in v1.

Security:
- No direct `admin_permissions`, `guild_memberships`, or `profiles` writes were added.
- No CP data or CP RPC calls were added by permission management.
- No GvG logic was changed.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## Milestone 8 Frontend CP Validation Passed

Manual browser validation passed for Admin-only CP management and leaderboard.

Validated:
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

Local testing note:
- After local DB reset, stale browser auth caused a `profiles_id_fkey` registration error.
- Clearing localStorage/sessionStorage fixed it.
- This was local stale session state, not a migration/security issue.

## Milestone 8 Frontend CP Implementation Complete

Admin-only CP management and CP leaderboard UI has been implemented and build-validated.

Implemented:
- New isolated CP service: `src/services/adminCpService.js`.
- AdminPanel CP section visible only to CP-view-authorized users.
- CP roster loads through `get_current_cp_roster`.
- CP leaderboard loads through `get_cp_leaderboard`.
- CP updates use `update_member_cp`.
- Missing CP displays as `Not entered`.
- CP input starts empty when CP is missing.
- CP update controls are visible only to Owner/Leader/Vice/Admin with `update_cp`.

Security:
- CP state is local to AdminPanel CP section and `adminCpService.js`.
- No direct `member_cp` or `cp_snapshots` reads/writes were added.
- CP is not shown on Dashboard, Profile, member-facing pages, or normal member roster cards.
- No GvG logic was changed.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## Milestone 8 Backend CP Hardening Validation Passed

Local validation passed for Milestone 8 backend CP hardening.

Validated:
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

## Milestone 8 Backend CP Hardening Implemented

Backend CP hardening has been implemented and is pending local validation.

Implemented:
- New migration `supabase/migrations/20260515000200_cp_rpc_hardening.sql`.
- `update_member_cp` now explicitly requires the target profile to exist and have `approval_status = 'approved'`.
- `update_member_cp` still requires an active primary membership and `private.can_update_cp`.
- `get_current_cp_roster` now starts from active approved memberships/profiles.
- CP roster now includes active approved members with no CP row.
- Missing CP returns `null`, not `0`.
- CP roster joins `member_cp` by both `profile_id` and `guild_id`.

Unchanged:
- No frontend CP UI was implemented.
- No GvG logic was changed.
- No direct CP table policies were added.
- CP access remains RPC-only.

Validation:
- Local Supabase reset and validation script rerun are pending.

## Milestone 7 Frontend Validation Passed

Manual browser validation passed for Admin member guild + role management UI.

Validated:
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

## Milestone 7 Frontend Implementation Complete

Admin member guild + role management UI has been implemented on top of the locally validated backend RPCs.

Implemented:
- Member role-change controls in Admin member cards.
- Owner role assignment is not exposed.
- Owner can choose only `member`, `admin`, `vice`, and `leader`.
- Leader/Vice can choose only `member` and `admin`.
- Admin with `manage_roles` can choose only `member` and `admin`.
- Admin without `manage_roles` has no role-change UI.
- Owner-only member guild transfer UI.
- Transfer target comes from a safe active guild options read.
- Transfer UI warns: "Moving guild resets this member's role to Member."
- Roster refresh runs after successful role or guild changes.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

Security:
- Writes use only `assign_member_role` and `transfer_member_guild`.
- No direct `profiles`, `guild_memberships`, or `admin_permissions` writes were added.
- No CP/GvG access was added.

## Milestone 7 Backend Validation Passed

Milestone 7 backend SQL/RPC support for role hardening and Owner-only guild transfer is implemented and locally validated.

Validated results:
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

## Current Milestone

Milestone 14C AdminPanel tabs + section organization is complete in production.

## Current Status

The app is a React + Vite frontend backed by local Supabase migrations/RLS/RPCs. Milestones 10, 11A, and 11B are complete and validated. Milestone 12 is complete as a documentation-only production readiness pass.

Current capabilities include local Supabase auth/session restore, registration through `register_profile`, pending/rejected/suspended gates, approval/rejection queue, own IGN editing, admin member profile management, role/guild management through RPCs, Admin permission checkbox management, protected CP management/leaderboard, GvG event management and voting, and read-only audit log viewing through `get_audit_logs`.

Production Supabase is set up through migrations and Owner bootstrap. Vercel deployment is live at `https://anteiku-guild-manager.vercel.app`, production Auth Site URL/redirect URL setup is complete, and production browser/network smoke validation has passed with documented deferred items for production GvG data creation and CP redaction browser coverage.

Production hardening policy now documents Vercel GitHub App restriction, controlled test-member retention, Preview/Staging separation, deferred production smoke-test strategy, and launch operations safety. The Vercel GitHub App restriction has since been manually completed and recorded.

Milestone 14C reorganized AdminPanel into mobile-friendly tabs and section components. The refactor is frontend-only and behavior-preserving; CP, Audit Logs, and GvG management sections lazy-load when their tabs are opened. Production rollout validation passed after the Vercel deployment.

## Implemented

- Mobile-first frontend shell.
- Placeholder auth, pending, dashboard, profile, GvG, and admin pages.
- Documentation structure.
- Original abstract guild mark.
- Supabase migrations for profiles, guilds, memberships, permissions, protected CP, GvG, audit logs, helper functions, RLS, RPCs, and seed data.
- Local validation script for CP privacy, role scoping, GvG vote integrity, approval/reapply behavior, and audit spoof denial.
- Local Supabase auth/session provider.
- Signup/signin/signout UI.
- Registration flow through `register_profile` RPC.
- Pending/rejected/suspended/approved frontend gating.
- Manual pending status refresh.
- Local Supabase environment badge.
- Manual Milestone 3 local browser auth validation.
- Manual local Owner bootstrap validation for `test1@local.dev`.
- Frontend approval queue for pending/reapply registration requests.
- Approval/rejection service using existing RPCs only.
- Frontend role option limits: Admin with `approve_members` can approve Member only; Leader/Vice can approve Member/Admin; Owner can approve Member/Admin/Vice/Leader. No frontend Owner option.
- Manual Milestone 4 browser approval/rejection validation.
- Member profile edit mode for own IGN only.
- `update_my_profile` service wrapper for safe own-profile RPC updates.
- Manual Milestone 5 browser profile-edit validation.
- Admin active approved member roster.
- Admin member IGN edit using `admin_update_member_ign`.
- Admin username/profile slug reset using `admin_reset_profile_slug`.
- Guild filter and search for safe member roster data.
- Manual Milestone 6 browser member-management validation.
- Hardened normal app role assignment to block assigning `owner`.
- Owner-only member guild transfer RPC.
- Local validation script section for Milestone 7 role/guild backend behavior.
- Admin permission checkbox management.
- Admin-only CP management and leaderboard.
- GvG event management and member voting persistence.
- Manual Milestone 10 browser GvG validation.
- Safe audit log reader RPC with CP metadata redaction.
- Read-only AdminPanel audit log viewer using `get_audit_logs`.
- Mobile-friendly AdminPanel tabs and section components.

## Not Implemented

- Suspended/left/rejected member management
- Avatar editing
- Username/profile slug editing for normal users
- Reapply UI
- Weekly CP snapshot/growth report UI
- Guild/subguild management UI

## Validation Status

Milestone 11B frontend audit log viewer validation passed:

- `npm.cmd run build` passed.
- Source/security-path validation passed.
- Manual live browser validation passed.
- Network validation after clearing initial AdminPanel load showed `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- No bugs or incomplete tests were reported.

Local validation completed on 2026-05-14:

- `npm.cmd install`: passed.
- `npm.cmd run build`: passed.
- `package-lock.json` was generated.
- `dist/` was generated.
- `npm.cmd audit`: completed with 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`.

Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade. Keep this as a known development-only Vite dev-server audit issue for now.

Milestone 2 local Supabase validation passed:

- `npx.cmd supabase db reset`: migrations apply locally.
- Local validation script result: 29 PASS / 0 FAIL / 0 SKIP.
- Setup failures: 0.
- Security failures: 0.

Validated behavior includes CP direct table denial, CP RPC permission checks, leader/admin/member scope rules, GvG vote upsert behavior, direct GvG write denial, approval/reapply audit flow, and audit spoof denial.

Important security lesson: validation caught private helper parameter shadowing that caused CP/RPC permission leakage. The helper migration was fixed by renaming helper parameters to `p_*` names and validation now confirms CP privacy and role-scoped access.

Milestone 3 local browser validation passed after the `AuthContext` loading fix:

- Local Supabase badge displays correctly.
- Register flow works and creates a pending user.
- Sign in and sign out work.
- Pending users are locked to the Pending page.
- Pending status refresh works.
- Hard refresh restores the session and returns the pending user to the Pending page.
- Signed-out refresh shows the Auth page.
- The stuck Loading state no longer reproduces.
- DevTools Network inspection found no protected CP table/RPC calls: no `member_cp`, no `cp_snapshots`, no `get_current_cp_roster`, no `get_cp_leaderboard`, and no `get_cp_growth_report`.

Resolved frontend validation bug: an async `onAuthStateChange` callback could wedge session restore/loading state. The fix keeps the auth callback synchronous, ignores duplicate `INITIAL_SESSION`, defers profile loading safely, and always clears state/loading on sign out.

Milestone 4 frontend build validation:

- `npm.cmd run build`: passed.
- No SQL migrations, Owner bootstrap files, Supabase commands, package files, or dependencies were changed.
- No frontend references to protected CP table/RPC identifiers were added.
- Approval writes are limited to `approve_registration` and `reject_registration`.
- Approved app shell initially had no visible Sign out button; fixed by adding a Sign out control to the `AppShell` header.
- `npm.cmd run build` passed after the Sign out fix.

Milestone 4 manual browser validation passed:

- Local Owner bootstrap was applied manually outside migrations.
- Owner account `test1@local.dev` became approved Owner in Anteiku.
- Owner could access the app shell and Admin tab.
- Sign out button is visible in the approved app shell and works.
- Approval queue loaded pending users.
- Owner approved `test2` as Member.
- `test2` could sign in and access the app shell as a member.
- `test2` had role `member` and guild `Anteiku:Re`.
- Admin tab was hidden for normal member.
- Owner rejected `test3` with reason.
- `test3` could sign in but was locked to `RejectedStatus`.
- Rejected user did not see app shell/member/admin screens.
- No CP UI or CP data was exposed during testing.

Milestone 5 frontend build validation:

- Existing RPC confirmed: `public.update_my_profile(p_ign text, p_avatar_key text default null)`.
- RPC uses `auth.uid()` and updates only the authenticated user's `ign`, `avatar_key`, and `updated_at`.
- Profile page edit mode updates IGN only.
- Username, profile slug, guild, role, approval status, and avatar/profile icon remain display-only.
- No direct profile or membership table update was added.
- No frontend references to protected CP table/RPC identifiers were added.
- `npm.cmd run build`: passed.

Milestone 5 manual browser validation passed:

- Owner could edit own IGN successfully.
- Member could edit own IGN successfully.
- Changed IGN displayed correctly after save.
- Empty/invalid IGN validation works or was checked as implemented.
- Cancel keeps/restores original IGN.
- Username/profile slug remained locked and not editable.
- Guild, role, and approval status remained display-only.
- Avatar editing was not implemented.
- Profile update used `update_my_profile` RPC only.
- No direct `profiles` or `guild_memberships` updates were added.
- No protected CP table/RPC calls were added or observed.
- `npm.cmd run build`: passed.

Milestone 6 frontend build validation:

- Existing RPC confirmed: `public.admin_update_member_ign(p_profile_id uuid, p_ign text)`.
- Existing RPC confirmed: `public.admin_reset_profile_slug(p_profile_id uuid, p_new_slug text)`.
- `admin_update_member_ign` uses `auth.uid()`, checks `private.can_edit_member_ign`, updates target IGN, and writes audit metadata.
- `admin_reset_profile_slug` uses `auth.uid()`, normalizes and validates slug format, checks `private.can_reset_profile_slug`, updates `username` and `profile_slug` together, and writes audit metadata.
- Member roster reads only active memberships with approved profiles.
- Member-management writes use only the two admin profile RPCs.
- No direct profile, membership, or permission table writes were added.
- No frontend references to protected CP table/RPC identifiers were added.
- `npm.cmd run build`: passed.

Milestone 6 manual browser validation passed:

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

New product requirement recorded for future planning: admins/staff should be able to change a member's guild and role, but this must not be added as an unsafe quick patch.

Milestone 7 backend implementation status:

- Created migration `supabase/migrations/20260515000100_member_guild_role_management.sql`.
- Updated `private.can_assign_role` behavior in the new migration.
- Updated `public.assign_member_role` behavior in the new migration.
- Added `private.can_transfer_member_guild`.
- Added `public.transfer_member_guild`.
- Added local validation-script checks for role assignment hardening and Owner-only transfer behavior.
- No CP table, CP RPC, GvG table, or GvG RPC changes were made.
- No frontend files were changed.
- Local database reset/validation has not been run yet.
