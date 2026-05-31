# Session Log

## 2026-05-31 - Member Ranking Active-Profile Fix

- Investigated the production linked-account Ranking bug where switching from Account A to Account B still highlighted Account A.
- Confirmed root cause: `get_member_cp_rankings(p_scope)` still resolved actor identity with legacy `auth.uid()` for My Guild scope and `is_current_user`.
- Added migration `supabase/migrations/20260531001300_active_profile_member_ranking.sql`.
- Redefined only `get_member_cp_rankings(p_scope)` to use `private.get_active_profile_id()` for selected active profile identity and guild scope.
- Updated `src/pages/Leaderboard.jsx` to refetch when the active profile summary changes and defensively align visible `You` highlighting to safe `profile_slug`.
- Local `npx.cmd supabase db reset` passed through the new migration.
- Full local validation passed through Docker `psql`.
- Focused local linked-profile Ranking validation passed `9 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260531001300_active_profile_member_ranking.sql`.
- Production migration apply/list verification passed.
- Production DB verification confirmed the RPC uses `private.get_active_profile_id()`, active Owner count remains `1`, return columns remain CP-hidden, and simulated authenticated direct `member_cp`/`cp_snapshots` reads returned zero rows.
- Commit `d23d5eb fix: use active profile for member ranking` was pushed to `main`.
- Vercel deployed a new production bundle after the push.
- Production linked-account smoke passed: `安定区×Ulti` highlighted before switching; after switching to `安定区xWata`, My Guild Ranking scoped to Anteiku:Re, `安定区xWata` was marked `You`, Global Ranking also highlighted `安定区xWata`, and the original `安定区×Ulti` row was no longer marked current.
- Restored the browser active profile back to `安定区×Ulti` after smoke.

## 2026-05-31 - Milestone 29F Full Active-Profile Regression

- Ran final active-profile regression validation after the 29E.8E CP/Admin/Analytics/Audit rollout.
- Found stale Account Switcher copy in Profile Settings saying some actions still use the original profile.
- Applied an i18n-only fix in `src/i18n/en.js`, `src/i18n/fr.js`, and `src/i18n/de.js`.
- New EN Account Switcher copy says `Switching profiles reloads your active profile context across the app.`
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration, Supabase/RLS/RPC, service/logic, CP/privacy, service-role, protected table, or localStorage authority changes.
- Commit `eaf16b5 fix: update account switcher rollout copy` was pushed to `main`.
- Production served updated bundle `assets/index-CWFJowQv.js`.
- Profile Settings / Account Switcher opened and the stale warning no longer appeared.
- Read-only production smoke passed for Home, Profile, Ranking, GvG, 3v3, Wall, Admin Overview, Admin CP, Admin CP Ranking, Analytics, Audit Logs, Members, Permissions, and Tools.
- Member Ranking remained CP-hidden; Profile showed own CP only; Wall/GvG exposed no normal CP; 3v3 showed public self-entered Combined CP only.
- The only captured console error was an old stale Supabase refresh-token entry tied to older bundle `index-KpKW2qdU.js`; no current-bundle console blocker or visible UI blocker was found.
- Account Switcher active-profile migration can be marked complete for the planned 29B-29F scope.

## 2026-05-31 - Milestone 29E.8E CP Admin + Analytics + Audit Logs Active-Profile Migration

- Implemented a focused CP-heavy Admin active-profile migration.
- Added migration `supabase/migrations/20260531001100_active_profile_cp_analytics_audit_admin.sql`.
- Redefined Admin CP roster/window/update RPCs to use selected active admin authority.
- Redefined `get_admin_cp_rankings` to use selected active admin authority and preserve CP `view_cp` gates.
- Redefined Analytics/Weekly Growth RPCs, including snapshot history, growth report, live growth, and start/capture CP period behavior, to use selected active admin authority.
- Redefined `get_audit_logs` so Audit Logs scope and CP metadata redaction use the selected active profile's scoped `view_cp`.
- Updated `src/pages/AdminPanel.jsx` to clear stale Admin CP/Analytics/Audit state when active admin profile/guild context changes.
- Local DB reset passed through the new migration.
- Full local validation passed; the CP/Analytics/Audit active-admin block reported `18 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found touched Admin CP/Analytics/Audit services remain RPC-only, with no direct `member_cp`, `cp_snapshots`, or `audit_logs` frontend table access.
- Production dry-run showed only `20260531001100_active_profile_cp_analytics_audit_admin.sql`.
- Production migration apply passed and remote migration list shows `20260531001100` applied.
- Production DB verification confirmed in-scope RPC body guards, no migrated `auth.uid()` references, active Owner count `1`, and direct CP/audit table protection through RLS probes.
- Commit `9dbf374 feat: migrate cp analytics audit admin to active profile` was pushed to `main`.
- Authenticated Owner production smoke loaded Admin CP, CP Ranking, Analytics, and Audit Logs from the deployed bundle without data-changing clicks.
- Browser console still contained one old stale Supabase refresh-token entry from an older bundle URL; no functional Admin blocker was found.

## 2026-05-31 - Milestone 29E.8D Non-CP Admin Active-Profile Migration

- Implemented a focused non-CP Admin active-profile migration.
- Added migration `supabase/migrations/20260531001000_active_profile_non_cp_admin.sql`.
- Added private helper `private.active_admin_profile_id()`.
- Added active-admin read RPCs for approval queue, member roster, permission management, and manageable GvG events.
- Redefined non-CP Admin action RPCs for Approvals, Members management, Permissions, GvG Admin, and Owner Tools / Owner Cosmetics to use active admin actor identity.
- Updated `src/services/adminApprovalService.js`, `src/services/adminMemberService.js`, `src/services/adminPermissionService.js`, and `src/services/gvgService.js` so migrated Admin reads use RPC-only paths instead of direct admin table reads.
- Updated `src/pages/AdminPanel.jsx` so permission keys/non-CP section context come from the active admin context.
- Preserved Admin CP roster/update/window, CP Ranking, Analytics/Weekly Growth, Audit Logs, CP metadata redaction, and CP privacy behavior.
- Local DB reset passed through the new migration.
- Full local validation passed; the non-CP active-admin block reported `20 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no `member_cp`, `cp_snapshots`, CP RPC, service-role, localStorage authority, or direct migrated admin table reads in the touched paths.
- Production dry-run showed only `20260531001000_active_profile_non_cp_admin.sql`.
- Production migration apply passed and remote migration list shows `20260531001000` applied.
- Production DB verification confirmed expected RPCs, 14/14 active-helper action RPCs with no CP refs, private helper non-execute, CP-heavy Admin RPCs unmigrated, active Owner count `1`, and direct CP table protection.
- Commit `6db48ea feat: migrate non-cp admin actions to active profile` was pushed to `main`.
- Production bundle verification confirmed the deployed app contains the new Admin RPC wrappers.
- Authenticated Owner production smoke loaded Approvals, Members, Permissions, GvG Admin, and Owner Tools without data-changing clicks.
- Browser console still contained one old stale Supabase refresh-token entry from an older bundle URL; no functional Admin blocker was found.

## 2026-05-31 - Milestone 29E.8C Active Admin Shell Context

- Implemented frontend-only AdminPanel shell visibility using the live active admin context RPC.
- Added `src/services/adminContextService.js` with RPC-only `loadMyActiveAdminContext()` for `get_my_active_admin_context`.
- Added `src/hooks/useActiveAdminContext.js` for active-context loading, error state, and `canAccessAdminPanel`.
- Updated AppShell/Admin navigation to use `can_access_admin_panel` from the backend-resolved active profile context.
- Updated AdminPanel shell guard to show active-context loading/denied states and active-profile admin access copy.
- Added EN/FR/DE copy for active admin context loading, denial, description, and active access role line.
- Preserved all Admin action/service internals, Admin CP, Analytics, Audit Logs, Permissions, Member Management, GvG admin, Owner Tools, CP visibility, and CP privacy.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration/Supabase/RLS/RPC changes, no direct table path in the new service, no service-role/localStorage authority, and no `member_cp`/`cp_snapshots` path.
- Commit `4689b64 feat: use active admin context for admin shell` was pushed to `main`.
- Production bundle verification confirmed the deployed app contains `get_my_active_admin_context` and the new active-context copy.
- Authenticated production smoke passed for the available active Owner account: app loaded, Admin nav appeared, AdminPanel opened, and the shell displayed `Active profile admin access: owner`.
- Account Switcher showed only one linked profile, so active normal-member switch/hide-Admin production smoke was not available from this session.
- Browser console captured one existing Supabase stale refresh-token error while the app still rendered signed in; no functional Admin shell blocker was found.

## 2026-05-31 - Milestone 29E.8B Active Admin Context Foundation

- Implemented backend-only Active Admin Context foundation.
- Added migration `supabase/migrations/20260531000900_active_admin_context_foundation.sql`.
- Added private helper `private.get_active_admin_context()`.
- Added public RPC `get_my_active_admin_context()`.
- The new RPC resolves selected active profile identity through `private.get_active_profile_id()`.
- The returned payload is safe admin context only: active profile id, profile slug/username, IGN, guild id/name/slug, role flags, staff/admin booleans, permission keys, scoped guild ids, status fields, and `can_access_admin_panel`.
- Preserved existing AdminPanel frontend behavior and all existing Admin RPC/action behavior.
- Preserved Admin CP, Analytics, Audit Logs, Permissions, Member Management, GvG admin, Owner Tools, and CP visibility behavior.
- Local DB reset passed through the new migration.
- Full local validation passed; the Active Admin Context block reported `13 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` was skipped because no frontend/runtime source changed.
- Production dry-run showed only `20260531000900_active_admin_context_foundation.sql`.
- Production migration apply passed and remote migration list shows `20260531000900` applied.
- Production DB verification confirmed RPC/helper presence, authenticated public RPC execute, private helper non-execute, Owner global context, active Owner count `1`, and simulated normal-member direct `member_cp`/`cp_snapshots` reads returned zero rows.
- No frontend deploy was needed.

## 2026-05-31 - Milestone 29E.7 Audit Actor Active-Profile Alignment

- Implemented a focused audit actor alignment migration for active-profile member GvG vote submit/update only.
- Added migration `supabase/migrations/20260531000800_active_profile_audit_actor_alignment.sql`.
- Redefined `submit_gvg_vote(...)` so it preserves active-profile vote behavior and writes `gvg_vote_submitted` with selected active profile as actor/target.
- Audit metadata records event id/scope, old/new vote status, and absence-reason-present booleans; absence reason text is intentionally excluded.
- Preserved legacy Admin GvG event management/results and Admin/Analytics audit attribution for a future approved Admin migration.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile GvG block reported `17 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` was skipped because no frontend/runtime source changed.
- Source validation found no normal CP, `member_cp`, `cp_snapshots`, CP RPC, service-role, or localStorage references in the new migration.
- Production dry-run showed only `20260531000800_active_profile_audit_actor_alignment.sql`.
- Production migration apply passed and remote migration list shows `20260531000800` applied.
- Production DB verification confirmed the RPC body/grant, active Owner count `1`, and rollback-wrapped direct access probes for `member_cp`, `cp_snapshots`, `gvg_votes`, and `audit_logs`.
- Commit `c48a3e9 feat: align active profile audit actor` was pushed to `main`.
- Production vote mutation smoke was not performed by design.

## 2026-05-31 - Milestone 29E.6 GvG Voting Active Profile Migration

- Implemented active-profile migration for member-facing GvG event visibility, own-vote lookup, and vote submit/update only.
- Added migration `supabase/migrations/20260531000700_active_profile_gvg_voting.sql`.
- Added member-safe RPCs `get_my_active_gvg_events()` and `get_my_gvg_vote(p_event_id uuid)`.
- Updated `submit_gvg_vote` so acting identity resolves through `private.get_active_profile_id()`.
- Updated `src/services/gvgService.js` so member-facing active events and own vote use RPCs only; Admin GvG service paths remain unchanged.
- Updated `src/pages/Gvg.jsx` to refetch and clear stale vote/message state when the selected active profile changes.
- Preserved Admin GvG event management/results, Analytics, Admin permissions/actions, rank badge, own Ghoul Rep, unrelated audit behavior, and CP privacy.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile GvG block reported `14 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no arbitrary frontend `profile_id`, no direct `gvg_votes` own-vote read, no `member_cp`/`cp_snapshots` usage, no CP RPCs, no service-role path, and no localStorage authority in the touched GvG path.
- Production dry-run showed only `20260531000700_active_profile_gvg_voting.sql`.
- Production migration apply passed and remote migration list shows `20260531000700` applied.
- Production DB verification confirmed active-profile GvG RPC grants/policies, active Owner count remains `1`, and simulated normal-member direct reads of `gvg_votes`, `member_cp`, and `cp_snapshots` returned zero rows.
- Commit `a9e5c2c feat: migrate gvg voting to active profile` was pushed to `main`.
- Production GvG smoke passed for the logged-in single-profile account: GvG opened, active event/current vote state loaded, and no vote mutation was performed.
- Multi-profile production switch smoke was not available in the logged-in session.

## 2026-05-31 - Milestone 29E.5 Own CP Active Profile Migration

- Implemented active-profile migration for member-own CP read, CP update-window lookup, and CP self-submit only.
- Added migration `supabase/migrations/20260531000600_active_profile_own_cp.sql`.
- Updated `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` so acting identity resolves through `private.get_active_profile_id()`.
- Updated `src/pages/Profile.jsx` so Profile `Your CP` uses active-profile readiness instead of the temporary legacy-profile-only CP disabled state.
- Preserved Admin CP roster/update/ranking, Analytics/Weekly Growth, GvG voting, Ranking CP-hidden behavior, Admin permissions/actions, rank badge, Ghoul Rep, and unrelated audit behavior.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile Own CP block reported `13 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no arbitrary frontend `profile_id`, no direct `member_cp`/`cp_snapshots` reads, no CP fields added to Public Profile/Ranking/Guild Wall/3v3, and no localStorage authority in the touched own-CP path.
- Production dry-run showed only `20260531000600_active_profile_own_cp.sql`.
- Production migration apply passed and remote migration list shows `20260531000600` applied.
- Production DB verification confirmed all three own-CP RPCs use `private.get_active_profile_id()`, authenticated execute grants exist, active Owner count remains `1`, and simulated normal-member direct reads of `member_cp`/`cp_snapshots` returned zero rows.
- Commit `9e13864 feat: migrate own cp to active profile` was pushed to `main`.
- Production Profile smoke passed for the logged-in single-profile account: own CP loaded, CP update-window state displayed Open, Settings showed only one linked profile, and no CP submit mutation was performed.
- Multi-profile production switch smoke was not available in the logged-in session.

## 2026-05-31 - Milestone 29E.4 Push Notifications Active Profile Migration

- Implemented active-profile migration for Push Notification settings/preferences/self-test while keeping the browser subscription owned by the signed-in auth account.
- Added migration `supabase/migrations/20260531000500_active_profile_push_notifications.sql`.
- Added `push_subscriptions.auth_user_id`, backfilled existing subscriptions through active profile links where possible, added FK/index, and preserved RLS/RPC-only access.
- Updated public push RPCs so selected-profile behavior resolves through `private.get_active_profile_id()`.
- Added preference-gated internal enqueue behavior for supported notification types while keeping `self_test` always allowed.
- Updated `supabase/functions/send-push-notifications/index.ts` so queued profile-recipient notifications are delivered to active subscriptions owned by linked auth accounts.
- Updated `src/pages/Profile.jsx` so Push Settings refresh when the active profile changes, show `Notifications for ...`, and label disable as browser-scoped.
- Added EN/FR/DE labels and compact styling for the active-profile/browser push context.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile Push block reported `12 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no normal CP RPC/table usage, frontend service-role path, localStorage authority, direct table path, Supabase response caching, or private notification payload content in the touched push path.
- Production dry-run showed only `20260531000500_active_profile_push_notifications.sql`.
- Production migration apply passed and remote migration list shows `20260531000500` applied.
- Production DB verification confirmed `push_subscriptions.auth_user_id` and FK, push RLS/no broad direct grants, five authenticated public push RPC grants, active Owner count `1`, and simulated normal-member direct CP table reads returned zero visible rows.
- Edge Function `send-push-notifications` was redeployed on production without exposing VAPID secrets.
- Commit `5a3302b feat: migrate push settings to active profile` was pushed to `main`.
- Production app/Profile loaded and the deployed bundle contains the new Push Settings labels; in-app browser notifications are unsupported, so native notification smoke remains a manual supported-browser check.
- CP get/submit, GvG vote, Admin permissions/actions, Analytics, and audit actor behavior remain future subsystem migrations.

## 2026-05-31 - Milestone 29E.3 3v3 Team Finder Active Profile Migration

- Implemented active-profile migration for 3v3 Team Finder actions only.
- Added migration `supabase/migrations/20260531000400_active_profile_three_v_three.sql`.
- Updated all public 3v3 RPCs so actor/viewer identity resolves through `private.get_active_profile_id()`.
- Covered Discord username update, public 3v3 Combined CP update, team create, team/status reads, join request, cancel request, approve/decline, remove member, close/reopen, and disband.
- Updated `src/pages/ThreeVThree.jsx` to refetch 3v3 state when the selected active profile changes and clear stale request/setup/message state.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile 3v3 block reported `17 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no normal CP RPC/table usage, no direct 3v3 table calls from frontend, no service-role path, and no localStorage authority in the touched path.
- Production dry-run showed only `20260531000400_active_profile_three_v_three.sql`.
- Production migration is applied and remote migration list shows `20260531000400` applied.
- Production DB verification confirmed all 13 public 3v3 RPCs use `private.get_active_profile_id()`, 3v3 tables retain RLS and no broad direct grants, active Owner count remains `1`, and simulated normal-member direct CP table reads returned zero visible rows.
- Commit `a5eb9e6 feat: migrate 3v3 to active profile` was pushed to `main`; Vercel reported deployment success.
- Authenticated production smoke passed for 3v3 Find Team, Create Team, My Requests, active-profile setup display, team cards, no normal CP/private data, and no new captured console errors.
- No production 3v3 mutation was performed during smoke.
- CP get/submit, GvG vote, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain future subsystem migrations.

## 2026-05-31 - Milestone 29E.2 Guild Wall + Profile Reactions Active Profile Migration

- Implemented active-profile migration for Guild Wall / Global Wall actions and Public Profile reactions.
- Added migration `supabase/migrations/20260531000300_active_profile_wall_reactions.sql`.
- Updated Wall/Profile Reaction RPCs so migrated actor/viewer state resolves through `private.get_active_profile_id()`.
- Covered Wall feed viewer flags, post/comment create, own delete, post/comment reactions, reaction details, moderation flags/RPCs, and Public Profile reaction add/remove/viewer state.
- Updated `src/pages/GuildWall.jsx` so My Org scope uses active profile guild context while Global remains null/global-only.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile Wall/Profile Reactions block reported `16 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no normal CP RPC/table usage, no direct Wall/Profile Reaction table calls from frontend, no service-role path, and no localStorage authority in the touched path except existing defensive deny-list strings.
- Production dry-run showed only `20260531000300_active_profile_wall_reactions.sql`.
- Production migration apply passed and remote migration list shows `20260531000300` applied.
- Production DB verification confirmed migrated Wall/Profile Reaction RPCs use `private.get_active_profile_id()`, active Owner count remains `1`, and simulated normal-member direct CP table reads returned zero visible rows.
- Commit `db2b9e5 feat: migrate wall reactions to active profile` was pushed to `main`.
- Production smoke passed for Guild Wall load, Global/My Org scopes, active-profile Wall post create/reaction/delete, Public Profile safe render/reaction detail, and no captured console errors.
- Controlled production RPC smoke passed for comment create/react/delete and profile reaction add/remove cleanup.
- CP get/submit, GvG vote, 3v3 actions, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain future subsystem migrations.

## 2026-05-31 - Milestone 29E.1 Own Profile + Cosmetics Active Profile Migration

- Implemented active-profile migration for own Profile identity/edit and Cosmetics read/equip only.
- Added migration `supabase/migrations/20260531000200_active_profile_profile_cosmetics.sql`.
- Added active-profile RPCs:
  - `get_my_active_profile_details()`
  - `update_my_active_profile(p_ign text)`
  - `get_my_active_cosmetics()`
  - `equip_my_active_avatar(p_avatar_key text)`
  - `equip_my_active_frame(p_frame_key text)`
- Updated `src/services/profileService.js` with active-profile detail/update wrappers and defensive private-field mapping.
- Updated `src/services/cosmeticsService.js` with active-profile cosmetics load/equip wrappers.
- Updated `src/pages/Profile.jsx` so own Profile identity/details and inline IGN edit use active-profile RPCs.
- Updated Profile Customize to load/equip cosmetics for the selected active profile.
- Added EN/FR/DE labels for active-profile cosmetics and the CP migration boundary.
- Added a Profile CP locked note for switched active profiles because CP get/submit is not migrated in this milestone.
- Local DB reset passed through the new migration.
- Full local validation passed; the active-profile Profile/Cosmetics block reported `10 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no normal CP RPC/table usage, no direct cosmetics table calls, no service-role path, and no localStorage authority in the touched active Profile/Cosmetics path except defensive deny-list strings.
- Production dry-run showed only `20260531000200_active_profile_profile_cosmetics.sql`.
- Production migration apply passed and remote migration list shows `20260531000200` applied.
- Commit `401e67e feat: migrate profile cosmetics to active profile` was pushed to `main`.
- Production smoke passed for Profile load, active-profile identity/details, single-profile own CP card unchanged, Customize load, active frame equip-and-restore, and no captured console errors.
- CP get/submit, GvG vote, 3v3 actions, Wall actions, Profile reactions, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain future subsystem migrations.

## 2026-05-31 - Milestone 29D Active Profile Viewer State

- Implemented frontend-only Active Profile Viewer State / low-risk reads.
- Added `src/hooks/useActiveProfileSummary.js`, a read-only hook that loads `get_my_active_profile()` and exposes active-profile display state.
- Updated `src/layouts/AppShell.jsx` with a compact topbar `Viewing as` chip using safe active-profile summary fields.
- Updated `src/pages/Dashboard.jsx` so Home identity can display active-profile avatar/frame/IGN/profile slug/guild/role/status where safe.
- Added a subtle Dashboard note when active profile differs from the legacy auth profile.
- Updated `src/pages/Profile.jsx` Account Switcher copy to clarify active profile and reload behavior.
- Added EN/FR/DE viewer-state labels and dark/crimson CSS for the topbar chip and Dashboard note.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migrations, Supabase/RLS/RPC, direct account-link table access, localStorage authority, normal CP RPC additions, or high-risk action RPC changes.
- Commit `14c3837 feat: add active profile viewer state` was pushed to `main`.
- Vercel production deployment is ready and aliases the production domain.
- Production smoke passed for app load, topbar `Viewing as`, Dashboard/Home load, Profile Settings active-profile card, single-profile state, Push Settings still present, and no captured console errors.
- CP get/submit, GvG vote, 3v3 actions, Wall actions, Profile reactions, cosmetics equip, push preferences/subscriptions, Admin actions/permissions, and audit actor behavior remain unmigrated by design.

## 2026-05-31 - Milestone 29C Account Switcher UI

- Implemented frontend-only Profile Settings Account Switcher UI.
- Added `src/services/accountSwitcherService.js` with RPC-only wrappers for:
  - `get_my_switchable_profiles`
  - `get_my_active_profile`
  - `set_my_active_profile`
- Updated `src/pages/Profile.jsx` so Settings loads account switcher data alongside Push Notifications.
- Added Account Switcher card with current active profile summary, linked profile cards, active/primary/status chips, switch confirmation, and success reload.
- Added EN/FR/DE `accountSwitcher.*` labels and shared Profile Settings copy.
- Added dark/crimson Account Switcher styling in `src/styles/app.css`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration/Supabase changes, no direct account-link table reads, no localStorage authority, no normal CP RPC usage, and no protected CP paths except defensive deny-list tokens in the switcher service.
- Commit `b8f6162 feat: add account switcher UI` was pushed to `main`.
- Vercel production deployment is ready and aliases the production domain.
- Production smoke passed for app load, Profile Settings modal, Account Switcher render, current active profile display, single-profile state, Push Settings still present, and no captured console errors.
- Full active-profile identity migration for CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin/auth remains deferred.

## 2026-05-31 - Milestone 29B Account Switcher Backend Foundation

- Implemented backend-only Account Switcher foundation.
- Added migration:
  - `20260531000100_account_switcher_foundation.sql`
- Added RPC-only account link tables:
  - `user_profile_links`
  - `user_active_profiles`
- Added private helper:
  - `private.get_active_profile_id()`
- Added public switcher RPCs:
  - `get_my_switchable_profiles()`
  - `get_my_active_profile()`
  - `set_my_active_profile(p_profile_id uuid)`
- Added Owner-only link management RPCs:
  - `owner_link_profile_to_auth_user(p_auth_email text, p_profile_slug text, p_link_type text default 'owner')`
  - `owner_unlink_profile_from_auth_user(p_auth_email text, p_profile_slug text)`
- Existing behavior was intentionally not switched over; CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin RPCs still use existing identity assumptions pending later milestones.
- Local `npx.cmd supabase db reset` passed.
- Full local validation passed through Docker `psql`; Account Switcher block reported `19 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000100_account_switcher_foundation.sql`.
- Production migration apply passed and remote migration list shows `20260531000100` applied.
- Production DB verification passed for table/RLS/RPC presence, no direct account-link grants, self-links for all current profiles, active Owner count `1`, switcher payload no-CP tokens, and member-context direct CP table reads returning no visible rows.
- `npm.cmd run build` was skipped because there were no frontend/runtime source changes.

## 2026-05-30 - Push Notifications Production Rollout

- Production rollout completed for Push Notifications.
- Production dry-run showed exactly one pending migration:
  - `20260530000800_push_notifications_foundation.sql`
- Production migration apply passed.
- Production DB verification passed for push table existence, RLS enabled, no broad direct grants, push RPC authenticated grants, active Owner count `1`, and normal CP table protection.
- Supabase Edge Function secret names are configured without recording values:
  - `VAPID_PUBLIC_KEY`
  - `VAPID_PRIVATE_KEY`
  - `VAPID_SUBJECT`
- Deployed `send-push-notifications` to production project `mzflfyxxkascrfpteexz`; function listed active.
- Frontend commit pushed:
  - `c761d38 feat: add push notification settings UI`
- Manual production push smoke passed:
  - browser notification permission was allowed/granted
  - Enable Notifications worked
  - push subscription registered
  - preferences saved
  - test notification was received
  - notification click opened the app
  - disable flow worked or is available
  - no CP/private/admin data appeared
  - no console/service-worker blocker found
- No CP/GvG/Analytics/3v3/Guild Wall/cosmetics/member-status/auth/role/permission behavior changed.

## 2026-05-30 - Milestone 28C Push Notification Frontend

- Implemented local Push Notification frontend/settings and service worker handling.
- Added `src/services/pushNotificationService.js` with RPC-only wrappers for:
  - push support/permission helpers
  - browser subscription registration
  - `register_push_subscription`
  - `disable_push_subscription`
  - `get_my_push_preferences`
  - `update_my_push_preferences`
  - `create_my_test_push_notification`
- Added a Profile Settings modal from the Profile identity header.
- Added Push Notifications status, enable/disable/test controls, and GvG/CP window/3v3/Wall/Profile reaction preference toggles.
- Updated `public/sw.js` with safe `push` and `notificationclick` handlers.
- Added `VITE_VAPID_PUBLIC_KEY` placeholder to `.env.example`; no private VAPID key was added.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks found no `member_cp`, `cp_snapshots`, normal CP RPCs, service-role key, VAPID private key, or direct table access in the new push frontend path.
- No production DB migration, Edge Function deploy, frontend deploy, Vercel env change, or controlled push smoke was performed.
- Production rollout is blocked until `VITE_VAPID_PUBLIC_KEY`, `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` are configured and the production DB dry-run is clean.

## 2026-05-30 - Milestone 28B Push Notifications Foundation

- Implemented local backend/RPC foundation for Push Notifications.
- Added migration `supabase/migrations/20260530000800_push_notifications_foundation.sql`.
- Added RPC-only tables:
  - `push_subscriptions`
  - `push_notification_preferences`
  - `push_notification_outbox`
- Added public RPCs:
  - `register_push_subscription`
  - `disable_push_subscription`
  - `get_my_push_preferences`
  - `update_my_push_preferences`
  - `create_my_test_push_notification`
- Added private helpers for approved-recipient eligibility, preference initialization, safe fixed payload generation, and internal notification enqueue.
- Added Supabase Edge Function foundation `supabase/functions/send-push-notifications/index.ts`.
- Local reset applied the migration cleanly with `npx.cmd supabase db reset`.
- Full local validation passed through Docker `psql`; Milestone 28B push block reported `13 PASS / 0 FAIL / 0 SKIP`.
- Source sweep of the new migration and Edge Function found no `member_cp`, `cp_snapshots`, normal CP RPCs, or CP value paths.
- No frontend/service-worker/package/app build files changed; `npm.cmd run build` was skipped as not applicable.
- No staging/production migration, Edge Function deploy, frontend deploy, Vercel env change, or production notification send was performed.
- Remote rollout remains blocked until `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` are configured for the Supabase Edge Function.

## 2026-05-30 - Social Profile Surfaces Polish

- Implemented and deployed a frontend-only polish pass for Public Member Profile and Guild Wall social surfaces.
- Commit deployed:
  - `c92246c style: polish social profile surfaces`
- Updated `src/pages/PublicMemberProfile.jsx` so the public profile hero presents avatar/frame, identity, safe chips, and Ghoul Rep as a compact identity surface.
- Updated `src/pages/GuildWall.jsx` with cleaner post/comment author rows and safer ASCII scope/date separation.
- Updated `src/styles/app.css` for tighter Public Profile, Guild Wall, reaction, comment, scope, composer, and Ghoul Rep chip styling.
- Investigated Ghoul Rep leaderboard feasibility only; no safe public leaderboard RPC exists, so no leaderboard UI was added.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migrations, Supabase/RLS/RPC, services, package/PWA/service-worker, auth, CP, GvG, Analytics, 3v3, cosmetics, member-status, uploads, or Storage changes.
- Guard search found no `member_cp`, `cp_snapshots`, CP RPC, direct `.from(...)`, upload, Storage, or service-role paths in the touched files.
- Production smoke passed for `/members/toji`, profile reaction details, Guild Wall `Global` / `My Org`, emoji reaction buttons, Ghoul Rep chips, no CP/email/private tokens, no in-app viewport overflow, and no captured console errors.

## 2026-05-30 - Ranking Public Profile Links

- Implemented and deployed Ranking to Public Member Profile links.
- Migration applied:
  - `supabase/migrations/20260530000700_ranking_public_profile_links.sql`
- Commit deployed:
  - `d806974 feat: link rankings to public profiles`
- Updated `get_member_cp_rankings(p_scope)` to add only safe `profile_slug` for authenticated `/members/:profileSlug` navigation.
- Updated member Ranking cards/rows to be tappable/keyboard-accessible profile links.
- Added EN/FR/DE `leaderboard.viewProfile` labels and dark/crimson focus/hover affordance.
- Local `npx.cmd supabase db reset` passed.
- Full local validation passed through Docker `psql`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production smoke passed for My Guild/Global Ranking links, `/members/toji` direct refresh, no protected normal CP values in member Ranking, Admin CP Ranking still loading, and no captured console errors.
- No ranking order/math change, Admin CP Ranking permission change, normal CP exposure, direct `member_cp`/`cp_snapshots` frontend use, public unauthenticated profile route, or unrelated CP/GvG/Analytics/3v3/Guild Wall/cosmetics/member-status behavior change was included.

## 2026-05-30 - Public Member Profiles Frontend Rollout

- Verified production DB readiness for Public Member Profiles/Profile Reactions after `20260530000600_public_member_profiles.sql` was applied.
- Implemented and deployed public member profile frontend.
- Commit `3f55f76 feat: add public member profiles` changed:
  - `src/App.jsx`
  - `src/pages/PublicMemberProfile.jsx`
  - `src/services/publicProfileService.js`
  - `src/pages/GuildWall.jsx`
  - `src/pages/ThreeVThree.jsx`
  - `src/styles/app.css`
  - `src/i18n/en.js`
  - `src/i18n/fr.js`
  - `src/i18n/de.js`
- Follow-up commit `ffc36e1 fix: support public profile route refresh` added:
  - `vercel.json`
- Added authenticated `/members/:profileSlug` app route with Vercel SPA fallback.
- Added RPC-only public profile service wrappers for profile load, reaction add/remove, and reaction details.
- Linked Guild Wall post/comment authors and reaction details users to public profiles where safe `profileSlug` is returned.
- Linked 3v3 team slots and incoming request users to public profiles where safe `profileSlug` is returned.
- Ranking rows were linked later by `d806974 feat: link rankings to public profiles` after `20260530000700_ranking_public_profile_links.sql` added safe `profile_slug`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production smoke passed for direct route render, safe profile fields, controlled profile reaction add/remove, reaction details, Wall links, 3v3 links, no normal CP/email/private/admin/audit metadata, and no console errors.

## 2026-05-30 - Ghoul Rep Profile Polish

- Implemented and deployed own Profile Ghoul Rep display plus softened Wall Ghoul Rep chip styling.
- Commit `bc9e30a feat: show ghoul rep on profile` changed:
  - `supabase/migrations/20260530000500_my_ghoul_rep_profile.sql`
  - `src/pages/Profile.jsx`
  - `src/services/profileService.js`
  - `src/styles/app.css`
  - `src/i18n/en.js`
  - `src/i18n/fr.js`
  - `src/i18n/de.js`
- Added `get_my_ghoul_rep()` as a focused own-user RPC that uses `auth.uid()`, requires an approved profile, and returns only the caller's live Ghoul Rep number.
- Profile now shows a compact `Ghoul Rep` chip near the rank/customize area.
- Guild Wall and Global Wall Ghoul Rep chips were softened to be smaller, lower-contrast social stats.
- Local DB reset passed and existing local validation passed; focused local RPC validation confirmed own rep value and pending denial.
- Production dry-run showed only `20260530000500_my_ghoul_rep_profile.sql`; migration apply and remote migration verification passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production smoke passed for Profile Ghoul Rep chip, softened Wall chip, Wall emoji reactions, no console errors, and no CP/privacy regression.
- No public profiles, profile reactions, Ghoul Rep leaderboard, normal CP exposure, `member_cp`, `cp_snapshots`, uploads, Storage, CP/GvG/Analytics/3v3/cosmetics/member-status/auth/role/permission behavior changes were added.

## 2026-05-30 - Ghoul Rep Wall Frontend

- Implemented and deployed frontend Ghoul Rep chips and reaction details UI.
- Commit `cc2a82b feat: show ghoul rep on guild wall` changed:
  - `src/pages/GuildWall.jsx`
  - `src/services/guildWallService.js`
  - `src/styles/app.css`
  - `src/i18n/en.js`
  - `src/i18n/fr.js`
  - `src/i18n/de.js`
- Follow-up commit `3c0ba0b fix: clear wall reaction details on scope change` clears stale reaction details when switching Wall scope.
- Post/comment author surfaces now show compact `Ghoul Rep` chips from `author_ghoul_rep`.
- Reaction details use RPC-only `get_wall_reaction_details(...)`.
- Reaction detail UI shows safe public reaction user fields: avatar/frame preview, IGN, guild, reaction icon/type, and timestamp.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no direct wall table reads/writes, no protected CP references in the touched Wall path, no uploads/Storage, and no service-role paths.
- Production smoke passed for My Guild, Global, reaction details, scope-change clearing, no CP/email visible, and no console errors.
- No SQL migrations, Supabase/RLS/RPC changes, CP/GvG/Analytics/3v3/cosmetics/member-status/auth/role/permission behavior changes, profile reactions, public profiles, or Ghoul Rep leaderboard were added.

## 2026-05-30 - Ghoul Rep Wall Reaction Backend

- Implemented backend/RPC support for Ghoul Rep on Guild Wall and Global Wall reactions.
- Added migration:
  - `supabase/migrations/20260530000400_ghoul_rep_wall_reactions.sql`
- Updated validation:
  - `supabase/tests/local_validation_anteiku.sql`
- Added `private.get_profile_ghoul_rep(p_profile_id uuid)` as a private live-calculation helper.
- Replaced `get_guild_wall_feed(...)` to include `author_ghoul_rep` on post and comment author payloads.
- Added `get_wall_reaction_details(p_target_type, p_target_id, p_reaction_type)` for safe future reaction hover/tap details.
- Ghoul Rep counts distinct non-self reactors per post/comment target, includes comment reactions, ignores deleted content and removed reactions, and avoids double-counting multiple reaction types from one user on one target.
- Local DB reset passed and local validation passed `47 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260530000400_ghoul_rep_wall_reactions.sql`; migration apply and read-only DB verification passed.
- `npm.cmd run build` was skipped because this checkpoint changed SQL/tests/docs only and no frontend runtime code.
- No normal CP, `member_cp`, `cp_snapshots`, CP RPCs, uploads, Storage, CP/GvG/Analytics/3v3/cosmetics/member-status/auth/role/permission behavior changed.
- Frontend Ghoul Rep chip and reaction detail popover/sheet remain the next step.

## 2026-05-30 - Global Wall Scope

- Implemented and deployed Global Wall as a separate Guild Wall scope.
- Commit `feaf2ff feat: add global wall scope` changed:
  - `supabase/migrations/20260530000300_global_wall_scope.sql`
  - `supabase/tests/local_validation_anteiku.sql`
  - `src/pages/GuildWall.jsx`
  - `src/services/guildWallService.js`
  - `src/styles/app.css`
  - `src/i18n/en.js`
  - `src/i18n/fr.js`
  - `src/i18n/de.js`
- Added nullable wall `guild_id` support where null means Global Wall.
- Updated Guild Wall feed/create RPCs so Global returns only Global posts and My Guild uses explicit guild scope.
- Kept Global moderation Owner-only; scoped staff cannot moderate Global posts.
- Updated frontend to show `My Guild` / `Global` scope chips and fixed reaction display through stable emoji icons while keeping backend reaction values unchanged.
- Local DB reset passed and local Guild Wall validation passed `33 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260530000300_global_wall_scope.sql`; migration apply and DB verification passed.
- Pushed `main`; production bundle contains Global Wall strings and the app loads with no captured console errors.
- Controlled production Global post/comment/reaction smoke was not performed by Codex because no authenticated controlled production session was available.
- No normal CP, `member_cp`, `cp_snapshots`, uploads, Storage, CP/GvG/Analytics/3v3/cosmetics/member-status/auth/role/permission behavior changed.

## 2026-05-28 - Admin Mobile Section Redesign

- Implemented and deployed a CSS-only AdminPanel mobile redesign pass for the remaining admin sections.
- Commit `79b15fa style: redesign admin mobile sections` changed only:
  - `src/styles/app.css`
- Used the already-approved Admin Overview and Admin CP Ranking as the visual direction.
- Tightened Analytics mobile scope chips, sub-tabs, stat cards, and Weekly Growth rows.
- Tightened Members cards and expanded Manage panels.
- Tightened Admin CP roster/window cards, GvG admin cards, Audit Logs, Permissions, and Owner Tools.
- Admin Overview and CP Ranking were not significantly changed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration, Supabase/RLS/RPC, service/data, package, PWA/service-worker, Admin permission logic, CP privacy, Analytics calculation, GvG, 3v3, or member-status changes.
- Production deployment completed successfully; Vercel reported success and production serves the new CSS asset.
- Manual authenticated mobile AdminPanel screenshot/console validation remains recommended.

## 2026-05-28 - Admin Mobile UX Polish

- Implemented and deployed frontend-only AdminPanel mobile UX polish.
- Commit `0dc9eb5 style: polish admin mobile experience` changed only:
  - `src/components/admin/AdminTabs.jsx`
  - `src/styles/app.css`
- Added a mobile-only AdminPanel section selector while preserving the desktop tab bar.
- Tightened Admin Overview command cards for mobile.
- Tightened Analytics mobile scope chips, sub-tabs, stat cards, and Weekly Growth rows.
- Tightened mobile spacing for Members, CP, GvG, Audit Logs, Permissions, and Owner Tools surfaces.
- Added Admin tab content bottom padding so final actions can scroll above bottom navigation.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration, Supabase/RLS/RPC, service/data, package, PWA/service-worker, Admin permission logic, CP privacy, Analytics calculation, GvG, 3v3, or member-status changes.
- Production deployment completed successfully and production assets contain the new Admin mobile selector/styles.
- Manual authenticated mobile AdminPanel screenshot/console validation remains recommended.

## 2026-05-28 - Offline Notice Banner

- Implemented and deployed the global Offline Notice Banner.
- Commit `2bbd24a feat: add offline notice banner` changed only:
  - `src/App.jsx`
  - `src/styles/app.css`
- Added a global offline detector using `navigator.onLine` plus browser `online` and `offline` events.
- Shows a non-blocking dark/crimson banner only while offline.
- Banner copy is `You are offline` and `Live guild data requires an internet connection.`
- The banner hides automatically when connection returns.
- The notice is positioned above bottom navigation so it should not cover mobile nav.
- This is UI-only; it does not queue actions or add full offline mode.
- No service worker/cache behavior changed.
- PWA update-banner behavior is unchanged.
- Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data remains uncached.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production app loaded after deployment.
- Manual offline/online browser toggle verification remains pending on target devices.

## 2026-05-28 - PWA Update Available Banner

- Implemented and deployed the PWA update-available banner.
- Commit `bb570a6 feat: add PWA update available banner` changed only:
  - `public/sw.js`
  - `src/registerServiceWorker.js`
  - `src/styles/app.css`
- Added waiting-service-worker detection in the existing service worker registration flow.
- Added a non-blocking dark/crimson banner with `New version available`, `Update now to get the latest app changes.`, `Update App`, and `Later`.
- `Update App` sends `{ type: "SKIP_WAITING" }` to the waiting worker and reloads only after `controllerchange`.
- `Later` dismisses the banner for the current browser session via `sessionStorage`.
- Removed automatic `skipWaiting()` during service-worker install so updates wait for user action.
- Kept update banner registration production-only through `import.meta.env.PROD`.
- Kept the existing conservative same-origin static/app-shell caching strategy.
- Supabase/API/Auth/RPC/CP/GvG/3v3/admin/analytics data remains uncached.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production app and `/sw.js` returned HTTP 200; production `/sw.js` contains `SKIP_WAITING`, `anteiku-static-v2`, and the same-origin guard.
- Manual browser update-cycle verification remains pending.

## 2026-05-28 - Milestone 26A/26B PWA Install Support

- Inspected current setup and found no existing PWA manifest, service worker, or Vite PWA plugin setup.
- Kept the implementation dependency-free rather than adding a PWA plugin.
- Added `public/manifest.webmanifest` with app name `Anteiku Guild Manager`, short name `Anteiku`, standalone display, root start/scope, dark background, crimson theme color, portrait-primary orientation, and required icons.
- Generated PWA PNG icons from the existing approved `public/anteiku-mark.svg` project mark.
- Added `public/sw.js` with same-origin app-shell/static-asset caching only.
- Added `src/registerServiceWorker.js` and registered the service worker only in production builds.
- Added manifest, favicon, iOS mobile, Apple touch icon, and theme-color tags to `index.html`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration changes, no Supabase/RLS/RPC changes, no package/dependency changes, no service behavior changes, and no direct Supabase/API response caching.
- Local Vite preview smoke passed for `/`, `/manifest.webmanifest`, `/sw.js`, and `/icons/icon-192.png`.
- Pushed commit `1d8b5a5 feat: add PWA install support` to `main`.
- Production smoke confirmed the app, manifest, service worker, icon, and service worker registration bundle are served.
- Browser-native install prompt and installed standalone launch were not manually verified from the terminal.

## 2026-05-28 - Milestone 25D 3v3 Production Rollout

- Production project `mzflfyxxkascrfpteexz` was deliberately linked for the 3v3 rollout.
- Production migration dry-run showed exactly one pending migration: `20260528000100_three_v_three_team_finder.sql`.
- Applied `20260528000100_three_v_three_team_finder.sql` to production.
- Verified `three_v_three_player_profiles`, `three_v_three_teams`, `three_v_three_team_members`, and `three_v_three_join_requests` exist with RLS enabled.
- Verified no broad direct anon/authenticated 3v3 table grants.
- Verified all 13 3v3 RPCs exist with authenticated execute grants and internal checks.
- Verified active Owner count remains `1`.
- Verified simulated normal authenticated direct reads of `member_cp` and `cp_snapshots` returned no visible rows.
- Pushed commit `4c9da98 feat: add 3v3 team finder UI` to `main`.
- Production served the 3v3 UI bundle.
- Manual controlled production smoke passed: Member A created a team, Member B requested to join, Member A approved, and Member B filled the first empty slot.
- Discord username and public 3v3 Combined CP were required/displayed.
- Normal protected CP was not visible.
- Normal Member had no AdminPanel access.
- No console/UI blocker was found.
- Test team cleanup status was not specified in the manual smoke note.
- Docs/handoff checkpoint recorded the production status; no source, SQL, migration, Supabase command, deployment, or production data mutation was performed during the docs checkpoint.

## 2026-05-28 - Milestone 25C 3v3 Frontend UI

- Committed Milestone 25B backend locally as `0dad508 feat: add 3v3 team finder backend`; no push was performed.
- Implemented frontend-only 3v3 Team Finder UI locally.
- Added `src/services/threeVThreeService.js` with RPC-only wrappers for the 25B 3v3 functions.
- Added `src/pages/ThreeVThree.jsx` with Find Team, Create Team, and My Requests sub-tabs.
- Added approved-member `3v3` navigation wiring in `App.jsx` and `navigation.js`.
- Added EN/FR/DE `threeVThree.*` labels and `nav.threeVThree`.
- Added mobile-first dark/crimson 3v3 styles for team cards, player slots, request panels, owner actions, and sub-tabs.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no normal CP identifiers, no direct `.from(...)` table calls, and only 3v3 RPCs in `threeVThreeService`.
- No SQL migrations, Supabase/RLS/RPC changes, staging action, production action, Vercel env change, deploy, or production data mutation was performed.
- Authenticated multi-account browser validation remains pending for Milestone 25D staging.

## 2026-05-28 - Milestone 25B 3v3 Team Finder Backend

- Implemented backend/RLS/RPC-only 3v3 Team Finder foundation.
- Added migration `20260528000100_three_v_three_team_finder.sql`.
- Added `three_v_three_player_profiles` for player-entered Discord username and public 3v3 Combined CP.
- Added `three_v_three_teams`, `three_v_three_team_members`, and `three_v_three_join_requests`.
- Added RPCs for updating own Discord username, updating own 3v3 Combined CP, creating teams, listing teams, reading own 3v3 status, requesting to join, cancelling requests, approving/declining requests, removing members, disbanding teams, and closing/reopening teams.
- Enforced one active owned team and one active team membership per player.
- Enforced one pending request per requester/team, max two attempts, and a six-hour cooldown after declined requests.
- Enforced owner-only approve/decline/remove/disband/close/reopen.
- Kept 3v3 Combined CP separate from protected normal CP; the migration does not read `member_cp` or `cp_snapshots`.
- Enabled RLS on all new 3v3 tables and revoked direct anon/authenticated table grants.
- Added Milestone 25B local validation coverage to `supabase/tests/local_validation_anteiku.sql`.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 25B result was 45 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend/runtime source files changed.
- No frontend UI, React source edit, staging action, production action, Vercel env change, deploy, or commit was performed.

## 2026-05-26 - Analytics UI Polish

- Implemented frontend-only AdminPanel Analytics UI polish.
- Tightened Analytics scope selector spacing and flat crimson active chip styling.
- Tightened Analytics sub-tabs and kept them horizontally scrollable for mobile.
- Added grouped Members stats for ready/watch/restricted/approval sections.
- Tightened Overview, CP, GvG, Weekly Growth, and Attention stat cards.
- Added visual growth states for Weekly Growth rows: positive, zero, missing, and negative.
- Updated mobile Weekly Growth rows to render as labeled cards instead of squeezed table columns.
- Added EN/FR/DE labels for the Members grouping headings.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration changes, no Supabase/RLS/RPC changes, no analytics service behavior changes, no direct protected CP/snapshot table reads, and no unsafe GvG writes.
- Pushed commit `1db36d3 style: polish admin analytics UI` to `main`.
- Production smoke passed for Owner AdminPanel -> Analytics, scope chips, all sub-tabs, Weekly Growth live growth, and preserved Global baseline behavior.
- Start New CP Week was not clicked.
- No captured browser console errors were observed.

## 2026-05-26 - Weekly Growth Baseline Scope Fix

- Investigated production Weekly Growth mismatch where Global showed `安定区×Ulti` growth `+5,002` but Anteiku showed `0`.
- Confirmed root cause: switching Analytics scope auto-selected the latest baseline for that scope, so Anteiku used a later guild-only baseline instead of the selected Global baseline.
- Added migration `20260526000300_live_cp_growth_baseline_scope.sql`.
- Added safe RPC overload `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)`.
- Preserved selected baseline id in `AdminAnalyticsSection` across scope changes when applicable.
- Updated `adminAnalyticsService.loadLiveCpGrowth(...)` to pass `p_baseline_batch_id`.
- Added local validation coverage for Owner global baseline reuse filtered to guild, later guild baseline not overriding explicit global baseline, scoped admin denial for global baseline, and scoped admin same-guild baseline access.
- Local validation passed with Milestone 24B/Live Growth result `36 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260526000300_live_cp_growth_baseline_scope.sql` pending.
- Applied the production migration and confirmed remote migration list includes `20260526000300`.
- Production DB verification confirmed both `get_admin_live_cp_growth` overloads exist, authenticated execute is granted, anon execute is denied, and active Owner count remains `1`.
- Pushed commit `0130ac6 fix: preserve analytics baseline across guild scope` to `main`.
- Production smoke confirmed Global and Anteiku both show `安定区×Ulti` growth `+5,002` from the same Global baseline.
- Start New CP Week was not clicked and no new production snapshot/baseline was created.
- No captured browser console errors were observed.

## 2026-05-26 - Live CP Growth Production Rollout

- Implemented Live CP Growth on top of the existing Analytics snapshot foundation.
- Added migration `20260526000200_live_cp_growth.sql`.
- Added `start_new_cp_growth_period(...)` for manual Sunday-baseline capture.
- Added `get_admin_live_cp_growth(...)` for current CP minus latest baseline reporting.
- Updated `capture_weekly_cp_snapshot(...)` to delegate to the new start-period RPC for compatibility.
- Updated AdminPanel -> Analytics -> Weekly Growth to show Reset day Sunday, baseline state, selected scope, Start New CP Week confirmation, and live growth rows.
- Added EN/FR/DE i18n keys and compact styling for Live CP Growth.
- Local Docker migration apply succeeded.
- Local validation passed with Milestone 24B/Live Growth result `31 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260526000200_live_cp_growth.sql`.
- Applied the production migration and confirmed remote migration list includes `20260526000200`.
- Production DB verification confirmed new RPCs exist with authenticated execute and anon denied, snapshot tables remain RLS-enabled, no direct anon/authenticated snapshot table grants exist, and active Owner count remains `1`.
- Pushed commit `426a720 feat: add live cp growth analytics` to `main`.
- Production Owner read-only smoke passed for Weekly Growth Global and Anteiku scope views.
- Production Start New CP Week mutation smoke was not performed by design.
- No captured browser console errors were observed.
- Supabase CLI remains linked to production; relink deliberately before future staging/local Supabase commands.

## 2026-05-26 - Milestone 24E Admin Analytics Production Rollout

- Deliberately linked Supabase CLI to production project `mzflfyxxkascrfpteexz`.
- Production migration list showed only `20260526000100_admin_analytics_foundation.sql` pending.
- Production dry-run showed exactly one migration would be pushed: `20260526000100_admin_analytics_foundation.sql`.
- Applied the production migration and confirmed remote migration list now includes `20260526000100`.
- Verified `cp_snapshot_batches` and `cp_snapshot_entries` exist with RLS enabled.
- Verified no direct anon/authenticated grants exist for the new snapshot tables.
- Verified Analytics RPCs exist and authenticated execute grants are present.
- Verified active Owner count remains `1`.
- Verified simulated authenticated non-member reads of `member_cp` and `cp_snapshots` return zero rows.
- Verified direct authenticated read of `cp_snapshot_batches` is permission denied.
- Pushed commit `cc2a32b feat: add admin analytics UI` to `main`.
- Confirmed production serves a bundle containing Analytics UI and RPC wrapper strings.
- Owner production browser smoke passed for AdminPanel -> Analytics and sub-tabs Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Weekly Growth showed snapshot history controls and safe `No previous snapshot yet` state.
- Production snapshot capture mutation smoke was not performed by design.
- No captured browser console errors were observed during Analytics smoke.
- Source checks found Analytics paths use only the six analytics RPCs and contain no direct CP/snapshot table reads, unsafe `gvg_votes`, Storage/upload, service-role, or arbitrary URL paths.
- Supabase CLI remains linked to production; relink deliberately before future staging/local Supabase commands.

## 2026-05-26 - Milestone 24C Admin Analytics UI

- Implemented frontend-only AdminPanel Analytics UI locally.
- Added `src/services/adminAnalyticsService.js` with RPC-only wrappers for `get_admin_member_analytics`, `get_admin_cp_analytics`, `get_admin_gvg_analytics`, `capture_weekly_cp_snapshot`, `get_admin_cp_snapshot_history`, and `get_admin_cp_growth_report`.
- Added `src/components/admin/AdminAnalyticsSection.jsx`.
- Added AdminPanel `Analytics` tab and Overview, Members, CP, GvG, Weekly Growth, and Attention sub-tabs.
- Analytics tab is lazy-rendered like other AdminPanel sections and does not load CP/GvG analytics until the Analytics UI requests those sub-tabs.
- Added compact locked states for CP Analytics and Weekly Growth permission denial.
- Added manual snapshot capture UI using the existing 24B snapshot RPC.
- Added EN/FR/DE Analytics i18n keys and dark/crimson compact Analytics styles.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL/migration/RLS/RPC changes, no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths.
- Local authenticated browser validation is pending because Vite was not running on `127.0.0.1:5173` during the checkpoint.
- No staging, production, Vercel, deployment, commit, Supabase command, production data mutation, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Rollout warning: do not deploy this frontend until `20260526000100_admin_analytics_foundation.sql` is applied and verified in the target DB.

## 2026-05-26 - Milestone 24B Admin Analytics Backend

- Implemented backend/RPC-only Admin Analytics foundation.
- Added migration `20260526000100_admin_analytics_foundation.sql`.
- Added RPC-only `cp_snapshot_batches` and `cp_snapshot_entries` with RLS enabled and no direct client grants.
- Added member, CP, GvG, snapshot capture, snapshot history, and CP growth report analytics RPCs.
- Preserved existing legacy `cp_snapshots` and older CP snapshot/growth RPCs.
- Added Milestone 24B coverage to `supabase/tests/local_validation_anteiku.sql`.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 24B result was 23 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend source changed.
- No AdminPanel frontend UI, React source edit, staging action, production action, Vercel env change, deployment, service-role path, or commit was performed.

## 2026-05-26 - Profile Redesign / Compact Member Profile Card

- Implemented frontend-only Profile redesign.
- Kept the approved identity header with avatar/frame, IGN, username, status badges, rank badge, and Customize action.
- Merged the separate `Your CP`, Member profile, and Profile details panels into one compact Member Profile card.
- Added compact own-CP, account/details, and inline IGN edit sections inside the unified card.
- Edit now reveals only an inline IGN input with Save IGN / Cancel controls.
- Flattened cosmetic modal active tab styling and Admin tab active styling back toward the crimson Anteiku look.
- Added EN/FR/DE labels for Save IGN, Cancel, short private-own-CP copy, and update-window label.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed Profile uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` for own CP.
- Source checks found no Profile admin CP RPCs, direct `member_cp`, direct `cp_snapshots`, public profile route, or other-player profile service.
- Local browser validation confirmed Profile loads, unified card renders, inline edit appears, Customize opens, mobile 390px has no horizontal overflow, and no console errors were captured.
- No SQL migrations, Supabase/RLS/RPC logic, service behavior, auth behavior, production data, Vercel env, uploads, Supabase Storage, public profile viewing, or CP/GvG/audit/role/permission/member-status behavior changed.

## 2026-05-26 - Own Profile Polish Implemented

- Implemented frontend-only Own Profile polish.
- Reordered Profile into identity, private own-CP, member profile edit, and account/details sections.
- Kept avatar/frame, rank badge, approval/status badges, and Customize in the identity card.
- Clarified the `Your CP` card as private self CP and kept the existing own-CP RPC flow unchanged.
- Added compact profile/account status rows and EN/FR/DE labels for the new copy.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed Profile uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` for own CP.
- Source checks found no Profile calls to admin CP RPCs, direct `member_cp`, or direct `cp_snapshots`.
- Local browser validation confirmed Profile loads, Customize opens/closes, the private `Your CP` card renders, and no console errors were captured.
- No SQL migrations, Supabase/RLS/RPC logic, service behavior, auth behavior, public profile routing, other-player profile viewing, deployment, production data, or CP/GvG/audit/role/permission/member-status behavior changed.

## 2026-05-25 - Frontend Command Center Polish Implemented

- Implemented frontend-only Command Center polish.
- Updated Member Dashboard with a compact guild command identity panel, safe status badges, Profile/GvG quick action cards, and a guild status card.
- Added AdminPanel Overview command center tab with permission-aware shortcut cards to existing sections.
- Admin Overview cards switch tabs only and do not introduce new backend calls or eager sensitive data loading.
- Tightened AppShell/AppNav mobile header and bottom navigation styling.
- Improved compact empty/loading/error state styling.
- Added EN/FR/DE labels for Dashboard quick actions and Admin Overview copy.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Manual browser validation passed for Member Dashboard, Profile/GvG quick actions, Member AdminPanel denial, AdminPanel Overview shortcut switching, CP/Audit/GvG lazy-loading behavior, Owner/non-owner Admin shortcut visibility, existing AdminPanel tabs, mobile nav/header, EN/FR/DE copy, console checks, and network checks.
- Commit `7f7227a feat: polish command center frontend` was pushed to `main`, Vercel deployed it, and production smoke passed with no console errors, unexpected network calls, CP exposure, or backend/RPC/SQL/security regressions.
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency files, service behavior, CP/GvG/audit/ranking/role/permission/member-status behavior, cosmetics backend behavior, Vercel/deployment, or production data were changed.

## 2026-05-25 - Owner Cosmetics Grant Tool

- Implemented AdminPanel -> Tools -> Owner Cosmetics as a frontend-only Owner surface.
- Added `loadGrantableCosmetics()` and `grantCosmeticBySlug(...)` wrappers in `cosmeticsService`.
- Catalog options load through existing `get_my_cosmetics()`.
- Grant action uses only `admin_grant_cosmetic_by_slug(...)`.
- Added EN/FR/DE `ownerCosmetics` i18n keys.
- Added compact dark/crimson Tools form styling.
- `npm.cmd run build` passed.
- Source validation found no SQL/migration changes, direct cosmetic table writes, uploads, Supabase Storage, arbitrary URLs, or CP/GvG/audit/ranking/member-status behavior changes.
- Local browser validation passed for Owner visibility/dropdown/required-field errors, non-owner Admin hidden state, and Member AdminPanel denial.
- Commit `d97fc9f feat: add owner cosmetics grant tool` was pushed to `main`.
- Commit `24287cb fix: hide free cosmetics from owner grant dropdown` was pushed to `main`.
- Vercel production bundle deployed and production app load smoke passed with no captured console errors.
- Authenticated production smoke passed: Owner sees AdminPanel -> Tools -> Owner Cosmetics; dropdown shows only `manual` / `admin_grant` cosmetics; free/default cosmetics are absent; empty username/profile slug and empty cosmetic validation work; non-owner Admin does not see Owner Cosmetics; Member has no AdminPanel access.
- No console errors, unexpected network calls, or CP/GvG/audit/ranking/member-status regressions were found.
- Controlled production grant smoke passed after explicit approval: a locked avatar/frame grant by exact profile slug / username succeeded, and the granted member could equip it.

## 2026-05-25 - Cosmetics Frame Unlock Hotfix Production Rollout

- Updated `scripts/sync-cosmetics-catalog.mjs` frame defaults so only `TXK_Arena*` and `TXK_KOF*` frames are generated as `manual`; all other frames are generated as `free`.
- Kept `_FREE` keys free and preserved premium avatar intent by keeping `premium` avatar keys manual.
- Added migration `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- `node --check scripts\sync-cosmetics-catalog.mjs` passed.
- `npm.cmd run cosmetics:sync -- --dry-run` passed and showed premium avatars manual, Arena/KOF frames manual, and C-series frames free.
- `npm.cmd run build` passed.
- Relinked Supabase CLI to production project `mzflfyxxkascrfpteexz`.
- Production migration list showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql` pending.
- Production dry-run showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Applied only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Remote migration list confirmed `20260525220522` applied.
- Read-only production verification confirmed 7 Arena manual frames, 3 KOF manual frames, 10 other free frames, and 0 other locked frames.
- Active Owner count remains `1`.
- Production app load smoke passed with no captured console errors.
- Authenticated Profile cosmetics browser smoke remains pending because the browser was signed out and no passwords were requested.
- No profile equipment rows, Vercel env, upload path, Supabase Storage, arbitrary URL path, CP/GvG/audit/role/permission/member-status behavior, or service-role path changed.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`.

## 2026-05-25 - Milestone 22F Cosmetics Catalog Sync Script Implemented

- Implemented local developer tooling for cosmetics catalog sync.
- Added `scripts/sync-cosmetics-catalog.mjs`.
- Added `npm.cmd run cosmetics:sync`.
- Dry-run validated: detected 54 avatars, 10 frames, 64 total cosmetics, and printed SQL preview without writing.
- Normal generation validated: created `supabase/migrations/20260525193210_cosmetics_catalog_sync.sql`.
- Generated migration upserts `public.cosmetic_catalog` rows using repo-backed assets only and does not delete/deactivate missing rows.
- Generated migration follows the then-current sync defaults: `_FREE` keys are free, v1 avatars without `_FREE` are free, and frames without `_FREE` are manual.
- `npm.cmd run build` passed.
- No Supabase commands, staging, production, deployment, runtime app behavior, Supabase/RLS/RPC behavior, uploads, Supabase Storage, arbitrary URLs, CP/GvG/audit/role/permission/member-status behavior, or production data were touched.
- Generated migration was not applied anywhere and must be reviewed before normal staging/production migration gates.

## 2026-05-25 - Leaderboard Podium Polish Production Checkpoint

- Recorded production leaderboard podium polish.
- Commit deployed: `3f65052 style: tune leaderboard podium layout`.
- Desktop podium visually orders `#2 | #1 | #3`.
- Mobile podium stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger centered gold styling and a larger avatar/frame.
- Rank #2 has silver styling.
- Rank #3 has bronze styling.
- `npm.cmd run build` passed before deployment.
- Production app load smoke passed with no captured console errors.
- No ranking logic, backend/RPC, SQL, Supabase/RLS, Vercel env, production data, or CP privacy behavior changed.

## 2026-05-25 - Milestone 23D Premium Cosmetics Production Rollout Complete

- Completed production rollout for premium cosmetics backend/grant helper.
- Confirmed clean working tree and latest commit `63a70fa feat: add premium cosmetics grant helper`.
- Relinked Supabase CLI from staging to production project `mzflfyxxkascrfpteexz`.
- Production migration list showed only `20260525000300_premium_cosmetics_grant_helper.sql` pending.
- Production dry-run showed only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Applied only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Remote migration list confirmed `20260525000300` applied.
- Verified production `admin_grant_cosmetic_by_slug(...)`, avatar unlock fields in `get_my_cosmetics()`, current frames free, direct cosmetic write grants blocked, Member grant denial, Owner/member-management authority path, and active Owner count `1`.
- Production app load smoke passed with title `Anteiku Guild Manager` and no captured console errors.
- Authenticated browser login/equip smoke was not automated because no credentials/session were available and passwords were not requested.
- Production locked/manual mutation smoke was not performed; staging Milestone 23C already validated the manual grant/equip runtime path.
- No frontend deploy, Vercel env change, source edit, SQL edit, new migration, `db reset`, `--include-seed`, service-role key, Storage, upload, arbitrary URL, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`.

## 2026-05-25 - Milestone 23C Premium Cosmetics Staging Rollout Complete

- Applied staging catch-up migrations `20260525000200_cp_rankings_cosmetics.sql` and `20260525000300_premium_cosmetics_grant_helper.sql` to staging project `ckyihuxkioeibzpgwenc`.
- Dry-run showed exactly those two migrations before push.
- Verified staging current frames free, avatar unlock fields, locked manual denial before grant, owner grant by slug, normal member/admin denial, granted manual equip, grant audit rows, direct write denial, and active Owner count `1`.
- Added staging-only manual test catalog rows `staging_premium_avatar_23c` and `staging_premium_frame_23c`.
- Production was not touched during 23C.

## 2026-05-25 - Milestone 23B Premium Cosmetics Backend Implemented Locally

- Implemented backend/database-only premium cosmetics support.
- Created new migration `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`.
- Did not edit deployed migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Updated all current frame catalog rows to `unlock_type = 'free'`.
- Hardened `equip_my_avatar(...)` so manual avatars require caller-owned unlock rows.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so manual avatars cannot be set through profile edit unless unlocked.
- Updated `get_my_cosmetics()` so avatar rows include `unlock_type`, `is_unlocked`, and `is_equipped`.
- Added `admin_grant_cosmetic_by_slug(...)` for exact username/profile-slug grants using the existing grant authority/audit path.
- Updated local validation SQL with premium avatar/frame, grant-by-slug, denial, unlocked equip, and audit coverage.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 23B result was 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend/source UI code changed.
- No staging, production, Vercel, deployment, frontend UI, Supabase Storage, upload path, arbitrary URL path, service role key, `db push`, commit, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local remote Supabase work.

## 2026-05-25 - Milestone 22E Cosmetics Production Rollout Complete

- Completed production rollout for cosmetics.
- Confirmed rollout branch `wip/cosmetics-backend-assets` carried cosmetics backend/assets/frontend work.
- Relinked Supabase CLI to production project `mzflfyxxkascrfpteexz`.
- Production dry-run initially hit a temporary Supabase CLI login/circuit-breaker error, then retry passed.
- Clean dry-run showed exactly one pending migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Applied only `20260525000100_cosmetics_catalog_unlocks.sql` to production.
- Remote migration list confirmed `20260525000100` applied.
- Verified production cosmetics tables, RLS, catalog counts, exact repo asset-path match, RPC existence/grants, direct-write denial, active Owner count `1`, and `update_my_profile(...)` avatar hardening.
- Merged `wip/cosmetics-backend-assets` into `main` and pushed.
- Vercel deployed the production cosmetics frontend/assets.
- Production assets and bundle markers for cosmetics were verified.
- User-confirmed production cosmetics UI smoke passed.
- Owner `ultimatesrb` equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` / `krsticmiroslav99+m13b21144225@gmail.com` remains approved/active but did not receive an equipped cosmetics row during this smoke.
- No `db reset`, `--include-seed`, local fake-user validation SQL, Owner bootstrap, staging command, service role key, Vercel env change, SQL edit, source edit, Supabase Storage, upload path, arbitrary URL path, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## 2026-05-25 - Milestone 22C Frontend Cosmetics Picker Implemented

- Continued work on branch `wip/cosmetics-backend-assets`.
- Implemented frontend-only member cosmetics picker on Profile.
- Added `src/services/cosmeticsService.js` using only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- Added `src/components/CosmeticPreview.jsx` for static avatar/frame rendering.
- Updated `src/pages/Profile.jsx` to load own cosmetics, render current avatar/frame preview, equip avatars, equip free/unlocked frames, and show locked frames as disabled.
- Updated Profile header to show equipped cosmetics when the cosmetics state is loaded.
- Added mobile-first dark/crimson cosmetics picker styles to `src/styles/app.css`.
- Added EN/FR/DE cosmetics labels.
- `npm.cmd run build` passed.
- Local Vite dev server was started and reached at `http://127.0.0.1:5173`.
- Static/source validation found no direct frontend cosmetics table calls and no admin grant UI.
- Static/source validation found no new direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` paths in the cosmetics/Profile picker path.
- No SQL migrations, Supabase/RLS/RPC logic, CP logic, GvG logic, audit logic, role/guild management, permission logic, production, Vercel env, deploy, push, or commit action was performed.
- Browser validation later passed through staging in Milestone 22D, UI polish passed in Milestones 22D.1-22D.3, and production rollout completed in Milestone 22E.

## 2026-05-25 - Milestone 22B.1 Cosmetics Catalog Asset Alignment

- Aligned `cosmetic_catalog` seed data with actual files in `public/cosmetics/avatars/` and `public/cosmetics/frames/`.
- Seeded 54 avatar rows; all avatars use `unlock_type = 'free'`.
- Seeded 10 frame rows; `_FREE` frames use `unlock_type = 'free'` and non-`_FREE` frames use `unlock_type = 'manual'`.
- Selected `1079_head` as the default avatar because no `default_avatar_FREE.png` file exists.
- Selected `TXK_frame_reOpen_EN_FREE` as the default frame because no `default_frame_FREE.png` file exists.
- Verified 64 catalog asset paths against local files: 0 missing files, 0 unlock mapping problems.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 22B result remained 19 PASS / 0 FAIL / 0 SKIP.
- Staging and production were not touched.

## 2026-05-25 - Milestone 22B Cosmetics Backend Implemented

- Implemented backend/database-only cosmetics support.
- Created migration `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`.
- Added `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Seeded cosmetics from Git/Vercel static asset paths under `public/cosmetics/`.
- Applied the `_FREE` naming convention so free/default cosmetic keys map to `unlock_type = 'free'`, while catalog `unlock_type` remains the runtime source of truth.
- Added RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so arbitrary avatar keys are rejected and active catalog avatars remain valid.
- `equip_my_avatar(...)` syncs `profiles.avatar_key` for backward compatibility.
- RLS is enabled on all cosmetics tables; direct client writes are not granted.
- Member equip RPCs use `auth.uid()` only and accept no target profile id.
- Admin grants require existing scoped member-management authority.
- Added Milestone 22B validation coverage to `supabase/tests/local_validation_anteiku.sql`.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 22B result was 19 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend/source UI code changed.
- Staging and production were not touched.
- A pre-existing untracked `public/cosmetics/` folder was left untouched because 22B is backend-only.
- Supabase CLI was linked to production before this local-only milestone; relink deliberately before future remote Supabase work.

## 2026-05-24 - Milestone 21E Rank Badge Production Rollout Complete

- Completed production rollout for Rank Badge / Profile Border.
- Confirmed clean working tree and latest commit `e99bec0 feat: add rank badge UI`.
- Relinked Supabase CLI to production project `mzflfyxxkascrfpteexz`; staging project `ckyihuxkioeibzpgwenc` was not used.
- Production dry-run showed only `20260524000400_cp_rank_badge_summary.sql`.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to production.
- Remote migration list confirmed `20260524000400` applied.
- Verified `get_my_cp_rank_summary()` exists, is security definer, grants execute to `authenticated`, does not grant execute to `anon`, and returns only safe rank summary fields.
- Verified authenticated member-context RPC response contained no CP values, growth/history/snapshot data, timestamps, updated-by metadata, profile ids, usernames, or private metadata.
- Verified direct authenticated member-context reads of `member_cp` and `cp_snapshots` returned zero rows.
- Verified active Owner count remains `1`.
- Pushed `main`; Vercel deployed commit `e99bec0`.
- Production Owner smoke passed for Dashboard rank badge, AdminPanel access, existing CP tab, and `CP Ranking` tab.
- Controlled production Member smoke passed for Dashboard/Profile safe no-rank/default badge state, no Admin nav, EN/FR/DE rank labels, and no captured console errors.
- Static source checks confirmed Profile/Dashboard badge path calls only `get_my_cp_rank_summary()` and does not use direct CP tables or member/admin leaderboard RPCs.
- No production CP/member data, Vercel env vars, source edits, SQL edits, service role keys, staging project, `db reset`, or `--include-seed` action was used.
- Supabase CLI remains linked to production and must be relinked before future staging/local Supabase commands.

## 2026-05-24 - Milestone 21D Rank Badge Staging Rollout and Validation

- Completed staging-only Rank Badge rollout and validation.
- Relinked Supabase CLI from production to staging project `ckyihuxkioeibzpgwenc`.
- Staging dry-run showed only `20260524000400_cp_rank_badge_summary.sql`.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to staging.
- Remote migration list confirmed `20260524000400` applied.
- Verified staging RPC safe return shape, authenticated execute grant, no anon execute grant, direct CP table denial, and active Owner count `1`.
- Browser-validated `staging_member` Dashboard/Profile rank badge with `Global Rank #1` / `Rank 1`.
- Browser-validated `staging_wrongguild` safe unranked/default badge state.
- Browser-validated `staging_pending` pending lockout.
- EN/FR/DE labels, mobile layout, and console checks passed.
- Restored `.env.local` to local Supabase and restarted local Vite.
- Production was not touched.

## 2026-05-24 - Milestone 21C Profile/Dashboard Rank Badge UI Implemented

- Implemented frontend-only Profile/Dashboard Rank Badge UI.
- Added `src/services/cpRankBadgeService.js` with a wrapper for `get_my_cp_rank_summary()`.
- Added `src/components/RankBadge.jsx`.
- Updated Profile to show a rank-based profile border and rank badge in the profile header.
- Updated Dashboard to show a compact rank badge in the member summary.
- Added EN/FR/DE `rankBadge` labels.
- Added dark/crimson rank badge, profile border, marker, and compact dashboard styles.
- The rank badge path does not call member/admin leaderboard RPCs, CP roster/leaderboard RPCs, or direct CP tables.
- Badge UI does not render CP values, CP growth/history, snapshots, profile ids, updated-by metadata, or other-member data.
- `npm.cmd run build` passed with the existing chunk-size warning.
- Static/source validation passed for protected CP paths.
- Authenticated browser validation remains pending until staging receives `20260524000400_cp_rank_badge_summary.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 21B Rank Badge Summary Backend Implemented

- Implemented backend/database-only Rank Badge / Profile Border support.
- Created migration `supabase/migrations/20260524000400_cp_rank_badge_summary.sql`.
- Added `get_my_cp_rank_summary()`.
- RPC returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- RPC does not return CP values, updated timestamps, growth/history/snapshot data, updated-by metadata, usernames, profile ids, other-member data, or private metadata.
- Tier keys: `rank_one`, `rank_two`, `rank_three`, `elite_five`, `top_ten`, `high_rank`, `ranked_member`, and `unranked`.
- Visual keys: `rank_1`, `rank_2`, `rank_3`, `elite_5`, `top_10`, `high_rank`, `ranked_member`, and `unranked`.
- Uses `auth.uid()` only and accepts no target profile id parameter.
- Uses the same eligible row set as member-safe rankings: approved active primary memberships with roster status `active`, `trial`, or `pending_transfer`.
- `inactive` and `on_break` return the unranked/default state; hard-blocked users remain denied by existing access gates.
- Updated local validation SQL with Milestone 21B checks for tiers, unranked state, private-field absence, no other-user parameter, and direct CP table denial.
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`; Milestone 21B result was 15 PASS / 0 FAIL / 0 SKIP.
- Existing Milestone 20B, 19B, and 19B.1 CP validation blocks still passed.
- `npm.cmd run build` was not run because no frontend/source UI code changed.
- No React components, source services, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 20F CP Leaderboard Production Rollout Complete

- Completed production rollout for CP Leaderboard / CP Ranking.
- Confirmed clean working tree and latest commit `7ccf8c9 feat: add CP ranking UI`.
- Relinked Supabase CLI to production project `mzflfyxxkascrfpteexz`; staging project `ckyihuxkioeibzpgwenc` was not used.
- Production dry-run initially hit a transient Supabase temp-db auth/circuit-breaker error; retry succeeded and showed only `20260524000300_cp_rankings.sql`.
- Applied only `20260524000300_cp_rankings.sql` to production.
- Verified production ranking RPC existence, authenticated execute grants, member-safe return shape, Owner admin CP fields, non-Owner global admin denial, direct CP table denial, and active Owner count `1`.
- Pushed `main`; Vercel deployed commit `7ccf8c9`.
- Production Member smoke passed for the `Ranking` page, My Guild and Global tabs, rank + IGN only, Global guild labels, no CP values/private CP fields, and no Admin navigation.
- Production Owner smoke passed for AdminPanel, existing `CP` tab roster/window controls, separate `CP Ranking` tab, Guild and Global admin rankings with CP values, and rank decoration.
- Captured console errors were empty for checked member/admin paths.
- Static source checks found member leaderboard uses only `get_member_cp_rankings`, Admin CP Ranking uses `get_admin_cp_rankings`, and no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls exist.
- No production CP/member data, Vercel env vars, source files, SQL migrations, service role keys, staging project, `db reset`, or `--include-seed` action was used.
- Supabase CLI remains linked to production and must be relinked before future staging/local Supabase commands.

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

## 2026-05-26 - Profile Mobile + Inline Edit Polish Implemented

- Implemented frontend-only Profile mobile + inline edit polish.
- Replaced the separate IGN edit form with an inline edit row inside Profile Details.
- Edit mode now converts the existing IGN detail row into an input with compact Save IGN / Cancel controls.
- Tightened mobile Member Profile spacing and compact account/detail rows.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed Profile still uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` for own CP.
- Source checks found no Profile calls to admin CP RPCs, direct `member_cp`, or direct `cp_snapshots`.
- Local browser validation passed for desktop column balance, 390px mobile no-overflow layout, bottom-nav clearance, inline edit behavior, local Save IGN, and no captured console errors.
- Follow-up placement polish moved the Edit action into the IGN row itself and removed the header Edit button.
- Commit `160c6e9 style: move profile edit action inline` was pushed to `main` and deployed by Vercel.
- Authenticated production Profile smoke passed: signed-in Profile opened, IGN row Edit worked inline, Save IGN worked, Cancel worked, Customize opened, `Your CP` showed only own CP, and no visible UI blocker was found.
- No SQL migrations, Supabase/RLS/RPC changes, service behavior changes, public/other-player profile viewing, uploads, Storage, production data mutation, or CP/GvG/audit/role/permission/member-status behavior changes were included.
