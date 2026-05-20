# Session Log

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
- Recommended next milestone: Milestone 14C staging Supabase + Vercel Preview environment planning, or controlled production test-member cleanup planning.

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
  - GvG production smoke remains deferred to avoid persistent production GvG test data.
  - CP redaction browser scenario remains deferred due missing production staff/data combination.
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
