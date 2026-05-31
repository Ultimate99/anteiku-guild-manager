# Testing And Validation

## Milestone 29E.8C Active Admin Shell Context Validation

Active Admin Shell Context passed build/source validation and limited authenticated production smoke.

Commands/gates:
- `npm.cmd run build`
- `git push origin main`
- Production bundle/content verification
- Authenticated production browser smoke

Results:
- Commit `4689b64 feat: use active admin context for admin shell` is pushed to `main`.
- Production serves a bundle containing `get_my_active_admin_context` and the new active-context copy.
- Build passed with the existing Vite chunk-size warning only.
- No SQL, migrations, Supabase/RLS/RPC, service-worker/PWA, package, or environment files changed.

Validated behavior:
- AppShell/Admin nav now uses active admin context from `get_my_active_admin_context()`.
- AdminPanel shell guard shows active-context loading/denied states.
- Active Owner production smoke passed: app loaded, Admin nav appeared, AdminPanel opened, and the shell displayed `Active profile admin access: owner`.
- Profile Settings Account Switcher showed only one linked profile in the smoke session, so active normal-member switch/hide-Admin behavior could not be production-browser tested from that account.

Security/source validation:
- `src/services/adminContextService.js` uses only the `get_my_active_admin_context` RPC and has no direct `.from(...)` table access.
- Source checks found no `member_cp`, `cp_snapshots`, service-role path, localStorage authority, Admin CP roster/ranking RPCs, or direct admin permission/guild-membership table paths in the new shell path.
- Existing Admin section internals and admin action services remain legacy and backend-enforced; no Admin CP, Analytics, Audit Logs, Permissions, Member Management, GvG admin, Owner Tools, or CP visibility behavior changed.
- Browser console captured one existing Supabase stale refresh-token error in the session while the app still rendered signed in; no functional Admin shell blocker was found.

## Milestone 29E.8B Active Admin Context Foundation Validation

Active Admin Context foundation passed local backend validation, production migration gates, and production DB verification.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- Production read-only/RLS-probe DB verification

Results:
- Local reset applied through `20260531000900_active_admin_context_foundation.sql`.
- Full local validation passed.
- Active Admin Context validation block passed `13 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` was skipped because no frontend/runtime source changed.
- Production dry-run showed exactly one pending migration: `20260531000900_active_admin_context_foundation.sql`.
- Production migration is applied and remote migration list shows `20260531000900` applied.

Validated behavior:
- `get_my_active_admin_context()` exists and is executable by authenticated users.
- `private.get_active_admin_context()` exists, resolves identity through `private.get_active_profile_id()`, and is not directly executable by authenticated users.
- Owner active context reports global admin access.
- Linked Owner-auth switched to Member active profile reports no admin access and no inherited Owner permissions in local validation.
- Scoped Leader/Admin contexts return scoped/actual permission information.
- Restricted active profile returns no admin access.
- Existing Admin CP RPC behavior remains legacy and unchanged.

Security/source validation:
- New migration has no `member_cp`, `cp_snapshots`, normal CP value reads, service-role, frontend, or localStorage path.
- RPC payload excludes email/auth data, CP table fields, audit contents, private metadata, and admin target data.
- Production verification confirmed active Owner count `1` and simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows.
- AdminPanel frontend, Admin actions, Admin CP, Analytics, Audit Logs, Permissions, Member Management, GvG admin, and Owner Tools were not migrated.

## Milestone 29E.7 Audit Actor Active-Profile Alignment Validation

Audit actor alignment for active-profile member GvG vote submit/update passed local backend validation, production migration gates, and DB verification.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- Production read-only/RLS-probe DB verification
- `git push origin main`

Results:
- Local reset applied through `20260531000800_active_profile_audit_actor_alignment.sql`.
- Full local validation passed.
- Active-profile GvG validation block passed `17 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` was skipped because no frontend/runtime source changed.
- Production dry-run showed exactly one pending migration: `20260531000800_active_profile_audit_actor_alignment.sql`.
- Production migration is applied and remote migration list shows `20260531000800` applied.
- Commit `c48a3e9 feat: align active profile audit actor` is pushed to `main`.

Validated behavior:
- `submit_gvg_vote(...)` still resolves selected-profile identity through `private.get_active_profile_id()`.
- GvG vote submit/update writes `gvg_vote_submitted` audit rows with selected active profile as actor/target.
- Audit metadata includes event id/scope, old/new vote status, and absence-reason-present booleans.
- Audit metadata does not include absence reason text.
- Legacy Admin GvG event status audit remains `auth.uid()`/legacy-attributed until Admin migration.
- No old audit rows were backfilled.

Security/source validation:
- New migration has no `member_cp`, `cp_snapshots`, normal CP RPC, service-role, or localStorage references.
- Production verification confirmed authenticated execute on `submit_gvg_vote`, active Owner count `1`, and rollback-wrapped direct access probes for `member_cp`, `cp_snapshots`, `gvg_votes`, and `audit_logs` stayed protected.
- Production mutation smoke was not performed by design.

## Milestone 29E.6 GvG Voting Active Profile Validation

GvG member-facing vote/current-user behavior passed local backend validation, frontend build/source validation, production migration gates, DB verification, and authenticated production GvG smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- `git push origin main`
- Authenticated production GvG smoke

Results:
- Local reset applied through `20260531000700_active_profile_gvg_voting.sql`.
- Full local validation passed.
- Milestone 29E.6 active-profile GvG block passed `14 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000700_active_profile_gvg_voting.sql`.
- Production migration is applied and remote migration list shows `20260531000700` applied.
- Commit `a9e5c2c feat: migrate gvg voting to active profile` is pushed to `main`.

Validated behavior:
- `get_my_active_gvg_events`, `get_my_gvg_vote`, and `submit_gvg_vote` resolve selected-profile identity through `private.get_active_profile_id()`.
- Single-profile fallback GvG behavior is unchanged.
- Linked active profile A/B local tests confirmed active-profile-specific event visibility and own vote state.
- Active profile A voted Present; active profile B did not inherit A's vote state.
- Active profile B voted Absent with a reason; A remained Present.
- Switching B Absent to Present updated B's existing row and cleared the absence reason without creating a duplicate.
- Pending, restricted, disabled, and unlinked active profiles were denied.
- `get_gvg_results` remains member-denied and permission-gated.
- Production GvG smoke confirmed the signed-in single-profile account loaded `GvG Week II`, displayed current vote state as `Present`, and did not perform a vote mutation.

Security/source validation:
- Member GvG frontend does not send arbitrary `profile_id` and no longer direct-reads `gvg_votes` for own vote state.
- No direct frontend `member_cp` or `cp_snapshots` table reads were added.
- No CP RPCs, normal CP fields, service-role frontend path, or localStorage authority were added.
- Simulated normal-member direct reads of `gvg_votes`, `member_cp`, and `cp_snapshots` returned zero visible rows in production verification.
- Admin GvG management/results, Analytics, Admin permissions/actions, rank badge, own Ghoul Rep, and unrelated audit actor behavior were not migrated or changed.
- No production GvG vote mutation was performed during browser smoke.

## Milestone 29E.5 Own CP Active Profile Validation

Own CP active-profile migration passed local backend validation, frontend build/source validation, production migration gates, DB verification, and authenticated production Profile smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- `git push origin main`
- Authenticated production Profile smoke

Results:
- Local reset applied through `20260531000600_active_profile_own_cp.sql`.
- Full local validation passed.
- Milestone 29E.5 active-profile Own CP block passed `13 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000600_active_profile_own_cp.sql`.
- Production migration is applied and remote migration list shows `20260531000600` applied.
- Commit `9e13864 feat: migrate own cp to active profile` is pushed to `main`.

Validated behavior:
- `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` resolve selected-profile identity through `private.get_active_profile_id()`.
- Single-profile fallback `get_my_cp` behavior is unchanged.
- Linked active profile A/B local tests returned each selected profile's own CP and selected-guild CP update window.
- Submitting CP as active profile B updated B only; A remained unchanged and audit used B as actor/target.
- Pending and restricted active profiles were denied.
- Disabled/unlinked active profile use was denied.
- Existing Admin CP update/roster read still works.
- Production Profile smoke confirmed `Your CP` loads, the CP update window state displays, and Settings showed only one linked profile in the logged-in session.

Security/source validation:
- No arbitrary frontend `profile_id` was added to the own CP path.
- No direct frontend `member_cp` or `cp_snapshots` table reads were added.
- No CP fields were added to Public Profile, Ranking rows, Guild Wall, or 3v3.
- Simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows in production verification.
- Admin CP, CP Analytics, Weekly Growth, GvG voting, member Ranking CP-hidden behavior, and Admin permissions/actions were not migrated or changed.
- No CP submit mutation was performed during production browser smoke.

## Milestone 29E.4 Push Notifications Active Profile Validation

Push Notifications active-profile migration passed local backend validation, frontend build/source validation, production migration gates, DB verification, Edge Function redeploy, and limited production smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- Production `npx.cmd supabase functions deploy send-push-notifications --project-ref mzflfyxxkascrfpteexz`
- `git push origin main`
- Authenticated production app/Profile smoke

Results:
- Local reset applied through `20260531000500_active_profile_push_notifications.sql`.
- Full local validation passed.
- Milestone 29E.4 active-profile Push block passed `12 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000500_active_profile_push_notifications.sql`.
- Production migration is applied and remote migration list shows `20260531000500` applied.
- Edge Function `send-push-notifications` was redeployed on production.
- Commit `5a3302b feat: migrate push settings to active profile` is pushed to `main`.

Validated behavior:
- Browser subscriptions are owned by `auth_user_id`.
- Preferences and self-test notifications use the selected active profile.
- Disabling a subscription uses the current auth/browser endpoint and is not bound to the selected profile.
- Edge Function can find subscriptions for auth accounts linked to the recipient profile.
- Production app and Profile loaded from the deployed bundle.
- Production bundle contains the new active-profile Push Settings labels.

Security/source validation:
- No CP get/submit, GvG, Admin, Analytics, or audit actor behavior was migrated.
- No normal CP, `member_cp`, `cp_snapshots`, CP RPCs, email/auth/admin/private metadata, service-role path in frontend, localStorage authority, Supabase RPC/API caching, uploads, Storage, or direct frontend table paths were added.
- Simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows in production verification.
- In-app browser Web Notification support is unavailable, so native permission/subscription/test notification smoke should be repeated manually in a supported browser if needed.

## Milestone 29E.3 3v3 Team Finder Active Profile Validation

3v3 Team Finder active-profile migration passed local backend validation, frontend build/source validation, production migration gates, DB verification, and authenticated production smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production migration list/apply verification
- `git push origin main`
- Authenticated production browser smoke
- Focused production RPC smoke through authenticated-role test queries

Results:
- Local reset applied through `20260531000400_active_profile_three_v_three.sql`.
- Full local validation passed.
- Milestone 29E.3 active-profile 3v3 block passed `17 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000400_active_profile_three_v_three.sql`.
- Production migration is applied and remote migration list shows `20260531000400` applied.
- Commit `a5eb9e6 feat: migrate 3v3 to active profile` is pushed to `main`; Vercel reported deployment success.

Validated behavior:
- All 13 public 3v3 RPCs use `private.get_active_profile_id()` and no longer use `auth.uid()` for actor identity.
- Migrated actions include Discord username update, public 3v3 Combined CP update, team create, team/status reads, join request, cancel, approve/decline, remove, close/reopen, and disband.
- Production signed-in 3v3 page loaded for the active profile.
- Find Team, Create Team, and My Requests rendered.
- Active-profile setup displayed Discord username and public 3v3 Combined CP.
- Team cards rendered existing slots and request actions.
- No production 3v3 create/request/approve mutation was performed during smoke.
- Active Owner count remained `1`.

Security/source validation:
- No CP get/submit, GvG, Push, Admin, Analytics, or audit actor behavior was migrated.
- No normal CP, `member_cp`, `cp_snapshots`, CP RPCs, email/auth/admin/private metadata, service-role paths, uploads, Storage, localStorage authority, or frontend direct table paths were added.
- Simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows in production verification.
- Focused production RPC smoke loaded `get_my_3v3_status()` and `get_3v3_teams()` and confirmed the payload guard had no normal CP/private tokens.

## Milestone 29E.2 Guild Wall + Profile Reactions Active Profile Validation

Guild Wall / Global Wall actions and Public Profile reactions active-profile migration passed local backend validation, frontend build/source validation, production migration gates, DB verification, and production smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- `git push origin main`
- Authenticated production browser smoke
- Focused production RPC smoke through authenticated-role test queries

Results:
- Local reset applied through `20260531000300_active_profile_wall_reactions.sql`.
- Full local validation passed.
- Milestone 29E.2 active-profile Wall/Profile Reactions block passed `16 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000300_active_profile_wall_reactions.sql`.
- Production migration apply passed and remote migration list shows `20260531000300` applied.
- Commit `db2b9e5 feat: migrate wall reactions to active profile` is pushed to `main`.

Validated behavior:
- Migrated Wall/Profile Reaction RPCs use `private.get_active_profile_id()`.
- Global Wall loaded and stayed global-only.
- My Org loaded through the selected active profile's guild context.
- A production Global Wall post was created, reacted to, and deleted through the UI as the active profile.
- Public Profile `/members/toji` rendered safe public identity, Ghoul Rep, 3v3 public CP, and profile reaction surfaces with no normal CP.
- Reaction detail UI opened and showed safe empty/details state with no private fields.
- Controlled production RPC smoke covered comment create/react/delete and profile reaction add/remove cleanup.
- Active Owner count remained `1`.

Security/source validation:
- No CP get/submit, GvG, 3v3, Push, Admin, Analytics, or audit actor behavior was migrated.
- No normal CP, `member_cp`, `cp_snapshots`, CP RPCs, email/auth/admin/private metadata, service-role paths, uploads, Storage, or frontend direct table paths were added.
- Simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows in production verification.

## Milestone 29E.1 Own Profile + Cosmetics Active Profile Validation

Own Profile identity/edit and Cosmetics read/equip active-profile migration passed local backend validation, frontend build/source validation, production migration gates, and production smoke.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content -Raw -LiteralPath supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres -v ON_ERROR_STOP=1`
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production `npx.cmd supabase migration list`
- `git push origin main`
- Authenticated production browser smoke

Results:
- Local reset applied through `20260531000200_active_profile_profile_cosmetics.sql`.
- Full local validation passed.
- Milestone 29E.1 active-profile Profile/Cosmetics block passed `10 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed exactly one pending migration: `20260531000200_active_profile_profile_cosmetics.sql`.
- Production migration apply passed and remote migration list shows `20260531000200` applied.
- Commit `401e67e feat: migrate profile cosmetics to active profile` is pushed to `main`.

Validated behavior:
- `get_my_active_profile_details()` returns safe active-profile identity/details and no CP/private fields.
- `update_my_active_profile(...)` updates only the selected active profile IGN.
- `get_my_active_cosmetics()` returns active-profile avatar/frame catalog state with no CP/private fields.
- `equip_my_active_avatar(...)` and `equip_my_active_frame(...)` apply only to the selected active profile and enforce unlock checks.
- Pending/disabled active-profile contexts are denied for active cosmetics.
- Production Profile opened for a signed-in approved single-profile user.
- Active-profile identity/details rendered.
- Single-profile own `Your CP` card remained unchanged.
- Customize opened through active-profile cosmetics.
- A production frame equip-and-restore smoke passed.
- No captured console errors.

Security/source validation:
- New RPCs use `private.get_active_profile_id()` and accept no arbitrary frontend profile id.
- No SQL/RLS/RPC outside the focused active-profile Profile/Cosmetics migration was changed.
- Frontend active Profile/Cosmetics path uses RPC wrappers only.
- No direct `profile_equipped_cosmetics`, `profile_cosmetic_unlocks`, or `cosmetic_catalog` table paths were added.
- Guard search found no `member_cp`, `cp_snapshots`, normal CP RPCs, service-role paths, or localStorage authority in the touched Profile/Cosmetics path except defensive deny-list strings.
- CP get/submit remains unmigrated; switched active profiles show a locked CP-not-enabled state instead of legacy own CP.

## Milestone 29D Active Profile Viewer State Validation

Active Profile Viewer State / low-risk reads passed frontend build/source validation and production smoke.

Commands/gates:
- `npm.cmd run build`
- `git push origin main`
- Vercel production deployment inspection
- Authenticated production browser smoke

Results:
- Build passed with the existing Vite chunk-size warning only.
- Commit `14c3837 feat: add active profile viewer state` is pushed to `main`.
- Vercel production deployment is ready and aliases `https://anteiku-guild-manager.vercel.app`.

Validated behavior:
- Production app loads for a signed-in approved user.
- Topbar shows `Viewing as` active-profile display.
- Dashboard/Home loads and keeps safe identity display.
- Profile Settings opens.
- Account Switcher active-profile card renders with clearer active/reload copy.
- Single-profile state still works for the smoke account.
- Push Notification settings remain visible in the same settings modal.
- No captured console errors.

Security/source validation:
- No SQL/migration/Supabase/RLS/RPC changes.
- No direct `user_profile_links` / `user_active_profiles` table reads/writes.
- No localStorage security authority.
- No `member_cp`, `cp_snapshots`, normal CP RPC additions, or private metadata display.
- No CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin action RPC behavior changed.
- Existing high-risk action systems are not migrated to active-profile identity in 29D.

## Milestone 29C Account Switcher UI Validation

Profile Settings Account Switcher UI passed build/source validation and production smoke.

Commands/gates:
- `npm.cmd run build`
- `git push origin main`
- Vercel production deployment inspection
- Authenticated production browser smoke

Results:
- Build passed with the existing Vite chunk-size warning only.
- Commit `b8f6162 feat: add account switcher UI` is pushed to `main`.
- Vercel production deployment is ready and aliases `https://anteiku-guild-manager.vercel.app`.

Validated behavior:
- Production app loads for a signed-in approved user.
- Profile page opens.
- Profile Settings modal opens.
- Account Switcher card renders above Push Notifications.
- Current active profile is shown.
- Single-profile state renders as `Only one profile linked.` for the smoke account.
- Push Notification settings remain visible in the same settings modal.
- No captured console errors.

Security/source validation:
- No SQL/migration/Supabase/RLS/RPC changes.
- `src/services/accountSwitcherService.js` uses only the three Account Switcher RPCs.
- No direct `.from(...)` account-link table reads/writes.
- No localStorage authority.
- No normal CP RPC usage.
- Guard search found no protected CP paths except defensive `member_cp` / `cp_snapshots` deny-list strings in the switcher service.
- Existing CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin/auth behavior was not migrated to active-profile identity.

## Milestone 29B Account Switcher Backend Validation

Account Switcher backend foundation passed local validation and production rollout gates.

Commands/gates:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- Production read-only DB verification through `npx.cmd supabase db query --linked`

Results:
- Local reset applied through `20260531000100_account_switcher_foundation.sql`.
- Full local validation passed.
- Milestone 29B account switcher block passed `19 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed exactly one pending migration: `20260531000100_account_switcher_foundation.sql`.
- Production migration apply passed and remote migration list shows `20260531000100` applied.

Validated behavior:
- Account-link tables exist and have RLS enabled.
- No direct anon/authenticated grants exist on `user_profile_links` or `user_active_profiles`.
- Existing one-profile users are self-linked.
- `get_my_switchable_profiles()` returns only linked profiles and no CP tokens.
- `get_my_active_profile()` falls back to the legacy self profile when no active row exists.
- `set_my_active_profile(...)` allows linked profiles and denies unlinked/disabled profiles.
- Owner can link/unlink profiles; non-Owner cannot.
- Unlinking an active profile clears/replaces the active selection safely.
- The only active Owner profile cannot be unlinked.
- Active Owner count remains `1`.
- Production member-context direct reads of `member_cp` and `cp_snapshots` returned `0` visible rows.

Build:
- `npm.cmd run build` was skipped because 29B changed backend SQL/tests/docs only and no frontend/runtime source changed.

## Milestone 28 Push Notifications Production Validation

Push Notifications passed local validation, production rollout gates, and manual production smoke.

Commands/gates:
- `npm.cmd run build`
- Production `npx.cmd supabase db push --dry-run`
- Production `npx.cmd supabase db push`
- `npx.cmd supabase functions deploy send-push-notifications --project-ref mzflfyxxkascrfpteexz`

Results:
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260530000800_push_notifications_foundation.sql`.
- Production migration apply passed.
- Production DB verification passed for push tables, RLS, no broad direct grants, push RPC grants, active Owner count `1`, and normal CP table protection.
- Supabase Edge Function secret names were verified without exposing values: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT`.
- `send-push-notifications` deployed and listed active.
- Frontend commit `c761d38 feat: add push notification settings UI` is pushed to `main`.

Manual production smoke:
- Browser notification permission was allowed/granted.
- Enable Notifications worked.
- Push subscription registered.
- Preferences saved.
- Test notification was received.
- Clicking the notification opened the app.
- Disable flow worked or is available.
- No CP/private/admin data appeared in the notification.
- No console/service-worker blocker was found.

Security/source validation:
- Push frontend path uses RPC wrappers only.
- No direct push table reads/writes were added.
- No `member_cp`, `cp_snapshots`, normal CP RPCs, service-role key, VAPID private key, or direct table access paths were found in the new push service/service-worker/env path.
- Existing service worker app-shell/static caching remained in place; no Supabase RPC/API/Auth response caching was added.
- No CP/GvG/Analytics/3v3/Guild Wall/cosmetics/member-status/auth/role/permission behavior changed.

## Milestone 28C Push Notification Frontend Validation

Push Notification frontend/settings and service worker handling passed local build/source validation and is now production deployed through the Milestone 28 production validation above.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Source validation:
- New push frontend path uses RPC wrappers only.
- No direct push table reads/writes were added.
- No `member_cp`, `cp_snapshots`, normal CP RPCs, service-role key, VAPID private key, or direct table access paths were found in the new push service/service-worker/env path.
- Existing service worker app-shell/static caching remained in place; no Supabase RPC/API/Auth response caching was added.
- No CP/GvG/Analytics/3v3/Guild Wall/cosmetics/member-status/auth/role/permission behavior changed.

Configuration/rollout status:
- `.env.example` documents `VITE_VAPID_PUBLIC_KEY`.
- Production Vercel `VITE_VAPID_PUBLIC_KEY` is configured.
- Supabase production Edge Function secret names are configured: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT`.
- Production DB migration, Edge Function deploy, frontend deploy, and controlled push smoke passed.

## Milestone 28B Push Notifications Foundation Validation

Push Notifications backend/RPC and Edge Function foundation passed local validation only.

Commands run:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Results:
- Local reset applied all migrations through `20260530000800_push_notifications_foundation.sql`.
- Full validation completed with no push-block failures.
- Milestone 28B push validation: `13 PASS / 0 FAIL / 0 SKIP`.

Validated push behavior:
- Push tables exist and RLS is enabled.
- No direct anon/authenticated table grants exist on push tables.
- Eligible member can register a push subscription.
- Pending user is denied subscription/preference access.
- Member can update own push preferences.
- Other users cannot disable another member's subscription.
- Member can disable own subscription.
- Self-test enqueue queues only for the authenticated member.
- Outbox payloads contain no private field tokens.
- Direct outbox insert is denied.
- Active approved Owner count remains `1`.

Source validation:
- New migration and Edge Function contain no `member_cp`, `cp_snapshots`, normal CP RPCs, or CP value paths.
- No frontend/service-worker/package/app build files changed.
- `npm.cmd run build` was skipped because this milestone changed backend SQL, validation SQL, and an Edge Function only.

Rollout status:
- Production migration is applied.
- Edge Function is deployed.
- Manual production push smoke passed.

## Social Profile Surfaces Polish Validation

Social Profile Surfaces polish passed build/source validation, production deployment, and production smoke.

Commands:
- `npm.cmd run build`
- `git diff --name-only`
- `rg -n "member_cp|cp_snapshots|get_my_cp|get_current_cp_roster|get_cp_leaderboard|get_admin_cp|get_my_cp|cp_value|storage|upload|service_role|service-role|\\.from\\(" src\\pages\\PublicMemberProfile.jsx src\\pages\\GuildWall.jsx src\\styles\\app.css`

Result:
- Build passed with the existing Vite chunk-size warning only.
- Source validation found only `src/pages/PublicMemberProfile.jsx`, `src/pages/GuildWall.jsx`, and `src/styles/app.css` changed.
- No SQL/migration, Supabase/RLS/RPC, service, auth, role/permission, CP, GvG, Analytics, 3v3, cosmetics, member-status, PWA/service-worker, package, upload, or Storage files changed.
- Guard search found no protected CP/storage/direct-table patterns in the touched files.

Production smoke:
- Production serves commit `c92246c style: polish social profile surfaces`.
- Signed-in Owner opened `/members/toji`; the authenticated Public Member Profile rendered with avatar/frame, identity, safe status chips, compact Ghoul Rep, public 3v3 CP label, profile reactions, and the normal-CP privacy notice.
- Profile reaction details opened and showed safe empty/detail state without email, CP, auth, admin, audit, or private metadata.
- Guild Wall opened; `Global` and `My Org` scopes loaded, emoji reaction buttons rendered, Ghoul Rep chips remained visible, and no protected CP/email/private tokens appeared in the smoke snapshot.
- No horizontal overflow was detected in the in-app browser viewport and no console errors were captured.
- Ghoul Rep leaderboard was not implemented because there is no safe public leaderboard RPC yet.

## Ranking Public Profile Links Validation

Ranking to Public Member Profile links passed local DB validation, build/source validation, production migration rollout, frontend deployment, and production smoke.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `npm.cmd run build`
- `rg -n "\.from\(|member_cp|cp_snapshots|get_my_cp|get_current_cp_roster|get_cp_leaderboard|get_admin_cp_rankings|get_admin_cp|cp_value|email|auth\.users|audit|permissions|private" src\pages\Leaderboard.jsx src\services\cpLeaderboardService.js`

Result:
- Local migrations applied cleanly through `20260530000700_ranking_public_profile_links.sql`.
- Full local validation passed through Docker `psql`.
- Build passed with the existing Vite chunk-size warning only.
- Source validation found no direct table reads/writes, no normal CP RPC additions, and no protected CP table usage in the Ranking frontend path.

Production smoke:
- Production serves commit `d806974 feat: link rankings to public profiles`.
- My Guild Ranking showed tappable profile targets.
- Global Ranking showed tappable profile targets.
- Tapping the Toji row opened `/members/toji`.
- Direct refresh of `/members/toji` rendered the authenticated public profile route.
- Member Ranking still displayed `CP values are hidden.` and showed no protected normal CP values.
- Admin CP Ranking still loaded for Owner with authorized CP values in the existing admin-only surface.
- No captured console errors.

## Public Member Profiles Validation

Public Member Profiles/Profile Reactions passed production DB verification, build/source validation, frontend deploy, route fallback validation, and production smoke.

Commands:
- `npm.cmd run build`
- `rg -n "from\\(|member_cp|cp_snapshots|get_my_cp|get_current_cp_roster|get_cp_leaderboard|get_admin_cp|cp_value|email|auth|admin_permissions|audit|private" src/pages/PublicMemberProfile.jsx src/services/publicProfileService.js src/pages/GuildWall.jsx src/pages/ThreeVThree.jsx src/App.jsx`
- Production bundle/route checks against `https://anteiku-guild-manager.vercel.app/`

Result:
- Production DB verification passed before frontend rollout for `20260530000600_public_member_profiles.sql`.
- `profile_reactions` exists with RLS enabled.
- RPCs exist: `get_public_member_profile`, `react_to_public_profile`, `remove_public_profile_reaction`, `get_public_profile_reaction_details`.
- Direct unsafe `profile_reactions` insert was denied.
- Safe public profile payload contained no normal CP, email, auth, admin, audit, or private metadata.
- Active Owner count remained `1`.
- Direct normal authenticated reads of `member_cp` and `cp_snapshots` returned no visible rows.
- Build passed with the existing Vite chunk-size warning only.
- Source validation found no direct `.from(...)` calls in the public profile path and no `member_cp` / `cp_snapshots` usage except the defensive deny-list guard.

Production smoke:
- Production serves the public profile frontend bundle.
- Direct `/members/ultimatesrb` route renders through the app after `ffc36e1` added the Vercel SPA rewrite.
- Signed-in Owner saw avatar/frame, IGN, `@ultimatesrb`, guild, safe role label, roster status, Ghoul Rep, public 3v3 Combined CP, and profile reactions.
- Normal CP, email, auth IDs, admin permissions, audit/private metadata were not visible.
- Controlled profile reaction add/remove on `@holder` succeeded and was removed back to zero.
- Profile reaction details opened and showed safe public fields/empty state only.
- Guild Wall author links and comment-author links open public profiles.
- 3v3 team slot links open public profiles.
- Pending/restricted denial was not re-tested in browser during this rollout; DB/RPC gates were verified before rollout.
- No captured console errors.

## Ghoul Rep Profile Polish Validation

Ghoul Rep Profile display and Wall chip polish passed local validation, build/source validation, production migration rollout, and production smoke.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- Focused local Docker `psql` check for `get_my_ghoul_rep()`
- `npm.cmd run build`
- `rg -n "member_cp|cp_snapshots|get_current_cp_roster|get_cp_leaderboard|get_admin_cp_rankings|update_member_cp|submit_my_cp_update|get_my_cp|service_role|service-role|storage|upload" src\pages\Profile.jsx src\services\profileService.js src\pages\GuildWall.jsx src\services\guildWallService.js supabase\migrations\20260530000500_my_ghoul_rep_profile.sql`
- `rg -n "\.from\(|wall_posts|wall_comments|wall_post_reactions|wall_comment_reactions" src\pages\Profile.jsx src\services\profileService.js src\pages\GuildWall.jsx src\services\guildWallService.js`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`

Result:
- Local DB reset applied through `20260530000500_my_ghoul_rep_profile.sql`.
- Existing local validation script passed; the Guild Wall/Ghoul Rep block remained `47 PASS / 0 FAIL / 0 SKIP`.
- Focused local RPC validation returned `1` Ghoul Rep for an approved author and denied a pending user with `Approved profile required.`.
- Build passed with the existing Vite chunk-size warning only.
- Source validation found no protected CP references, no uploads/Storage/service-role paths, no direct Wall table reads/writes in the touched Wall/Profile path, and no public profile/profile-reaction/leaderboard implementation.
- Production dry-run showed only `20260530000500_my_ghoul_rep_profile.sql` pending.
- Production migration apply succeeded and remote migration list shows `20260530000500` applied.

Production smoke:
- Production serves the updated bundle with `get_my_ghoul_rep` and `profile-ghoul-rep-chip`.
- Signed-in Owner opened Profile and saw a compact `2 Ghoul Rep` chip near rank/customize.
- Signed-in Owner opened Wall and saw softened compact Ghoul Rep chips plus emoji reaction buttons.
- No CP/private data appeared on Wall; Profile still shows only the user's existing own CP section.
- No captured console errors.

## Ghoul Rep Wall Frontend Validation

Ghoul Rep frontend UI passed build/source validation and production smoke.

Commands:
- `npm.cmd run build`
- `rg -n 'member_cp|cp_snapshots|get_current_cp_roster|get_cp_leaderboard|get_admin_cp_rankings|update_member_cp|submit_my_cp_update|get_my_cp|storage|upload|service_role|service-role' src\pages\GuildWall.jsx src\services\guildWallService.js src\styles\app.css`
- `rg -n "\.from\(" src\pages\GuildWall.jsx src\services\guildWallService.js`

Result:
- Build passed with the existing Vite chunk-size warning only.
- Source validation found no direct `.from(...)` calls in the Guild Wall page/service.
- Source validation found no protected CP/storage/service-role references in the touched Guild Wall page/service/styles.
- Production serves a bundle containing `Ghoul Rep`, `author_ghoul_rep`, and `get_wall_reaction_details`.

Production smoke:
- Signed-in Owner opened Guild Wall.
- `My Guild` feed showed Ghoul Rep chips on post and comment authors.
- `Global` feed showed Ghoul Rep chips.
- Reaction details panel opened from a reaction and showed safe public fields only.
- Scope switch from `My Guild` to `Global` cleared the open reaction details panel.
- No CP or email text appeared in the Wall smoke snapshot.
- No captured console errors.

## Ghoul Rep Wall Reaction Backend Validation

Ghoul Rep backend support passed local validation and production migration/read-only verification.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `rg -n "member_cp|cp_snapshots|get_current_cp_roster|get_cp_leaderboard|get_admin_cp_rankings|update_member_cp|submit_my_cp_update|get_my_cp|service_role|service-role|storage|upload" supabase\migrations\20260530000400_ghoul_rep_wall_reactions.sql`
- `npx.cmd supabase link --project-ref mzflfyxxkascrfpteexz`
- `npx.cmd supabase migration list`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`

Result:
- Local reset applied through `20260530000400_ghoul_rep_wall_reactions.sql`.
- Guild Wall/Ghoul Rep validation block passed `47 PASS / 0 FAIL / 0 SKIP`.
- Migration source scan found no normal CP, CP snapshots, service-role, upload, or Storage references in the Ghoul Rep migration.
- Production dry-run showed only `20260530000400_ghoul_rep_wall_reactions.sql` pending.
- Production migration apply succeeded and remote migration list shows `20260530000400` applied.

Production DB verification:
- `get_guild_wall_feed(...)` returns `author_ghoul_rep`.
- `get_wall_reaction_details(...)` exists and is executable by authenticated users.
- `private.get_profile_ghoul_rep(...)` exists but is not executable by authenticated users.
- Wall tables retain RLS and no direct anon/authenticated table grants.
- Installed Ghoul Rep functions do not reference `member_cp`, `cp_snapshots`, or email.
- Owner Global feed read returned a safe viewer payload.
- Active approved Owner count remains `1`.

Build note:
- `npm.cmd run build` was skipped because no frontend runtime code changed for this backend-only checkpoint.

Manual/frontend verification still needed:
- Frontend Ghoul Rep chip and reaction-detail hover/tap UI are not implemented yet.

## Global Wall Scope Validation

Global Wall scope passed local backend validation, build/source validation, production dry-run/apply, and production read-only verification.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `npm.cmd run build`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`

Result:
- Local reset applied through `20260530000300_global_wall_scope.sql`.
- Guild Wall validation block passed `33 PASS / 0 FAIL / 0 SKIP`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260530000300_global_wall_scope.sql` pending.
- Production migration apply succeeded and remote migration list shows `20260530000300` applied.

Production DB verification:
- `wall_posts.guild_id` and `wall_comments.guild_id` are nullable for Global scope.
- RLS remains enabled on `wall_posts`, `wall_comments`, `wall_post_reactions`, and `wall_comment_reactions`.
- Direct anon/authenticated/public wall table grants remain `0`.
- Wall RPC set count is `13`.
- Active approved Owner count remains `1`.
- Owner Global feed read through `get_guild_wall_feed(null, 1, null)` returned `is_global = true`, `can_post = true`, and `can_moderate = true`.

Production frontend smoke:
- Commit `feaf2ff feat: add global wall scope` was pushed to `main`.
- Production bundle contains the Global Wall frontend strings.
- Production app loads in a clean browser session with no captured console errors.

Source/security validation:
- `src/services/guildWallService.js` uses RPCs only.
- Source checks found no direct `.from(...)` wall table access, no `member_cp`, no `cp_snapshots`, no CP RPCs, no uploads, no Storage paths, and no service-role references in the Guild Wall path.

Manual verification still needed:
- Authenticated controlled production smoke for creating a Global post, comment, reaction, optional delete/moderation, and cross-guild visibility.

## Admin Mobile Section Redesign Validation

Admin mobile section redesign passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented:
- Added CSS-only mobile refinements for Analytics, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Kept Admin Overview and CP Ranking largely unchanged because those were the approved visual direction.
- Improved mobile Analytics scope/sub-tabs/stat cards and Weekly Growth rows.
- Tightened member cards, expanded Manage panels, CP roster/window cards, GvG admin panels, audit cards, permission rows, and Owner Tools form surfaces.

Production validation:
- Commit `79b15fa style: redesign admin mobile sections` is deployed.
- Vercel commit status reported success.
- Production app returned HTTP 200.
- Production CSS asset `assets/index-D0rC3ZAv.css` contains the new admin mobile rules.

Security/source validation:
- Only `src/styles/app.css` changed.
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, services, package files, PWA/service-worker files, or Vercel env changes.
- No Admin permission logic, CP privacy behavior, Analytics calculations, GvG logic, 3v3 logic, or member-status behavior changed.
- Source checks found no protected CP/table/RPC/service-role references in the touched CSS.

Manual verification still needed:
- Authenticated AdminPanel mobile smoke at 360/390/430 widths.
- Confirm Analytics, Members, CP, GvG, Audit Logs, Permissions, and Tools are denser/readable, with no horizontal overflow, bottom-nav overlap, raw translation keys, console errors, or CP values outside existing authorized admin surfaces.

## Admin Mobile UX Polish Validation

Admin mobile UX polish passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented:
- Added a mobile-only AdminPanel section selector in `AdminTabs`.
- Kept the existing desktop AdminPanel tab bar for wider layouts.
- Tightened mobile Admin Overview command cards.
- Tightened mobile Analytics scope selector, sub-tabs, stat cards, and Weekly Growth rows.
- Tightened mobile spacing for Members, CP, GvG, Audit Logs, Permissions, and Owner Tools panels/cards/buttons.
- Added extra Admin tab content bottom padding for bottom-nav clearance.

Production validation:
- Commit `0dc9eb5 style: polish admin mobile experience` is deployed.
- Production app returned HTTP 200.
- Production JS/CSS assets contain `admin-tab-select`, `admin-tab-shell`, and the new admin mobile styles.

Security/source validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, services, package files, PWA/service-worker files, or Vercel env changes.
- No Admin permission logic, CP privacy behavior, Analytics calculations, GvG logic, 3v3 logic, or member-status behavior changed.
- Source checks found no new `member_cp`, `cp_snapshots`, admin CP RPC, service-role, or direct Supabase table access in the touched files.

Manual verification still needed:
- Authenticated AdminPanel mobile smoke at 360/390/430 widths.
- Confirm Admin section navigation, Analytics, CP, Audit, Permissions, Tools, and final actions are usable with no horizontal overflow, bottom-nav overlap, raw translation keys, or console errors.

## Offline Notice Banner Validation

Offline Notice Banner passed build, source, and production app-load validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented:
- Detects initial state from `navigator.onLine`.
- Listens to browser `online` and `offline` events.
- Shows a non-blocking offline banner only while offline.
- Automatically hides when the browser comes back online.
- Uses existing dark/crimson styling and is positioned above mobile bottom navigation.

Production validation:
- Commit `2bbd24a feat: add offline notice banner` is deployed.
- Production app loaded after deployment.

Security/cache validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, package/dependency changes, or Vercel env changes.
- No service worker/cache behavior changed.
- No Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data caching was added.
- PWA update-banner behavior remains unchanged.

Manual verification still needed:
- In Chrome DevTools, switch Network to Offline and confirm the banner appears.
- Switch back Online and confirm the banner hides.
- Check narrow/mobile viewport to confirm the banner does not cover bottom navigation.

## PWA Update Available Banner Validation

PWA update-available banner passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented:
- Detects a waiting service worker.
- Shows a non-blocking update banner with:
  - `New version available`
  - `Update now to get the latest app changes.`
  - `Update App`
  - `Later`
- `Update App` posts `{ type: "SKIP_WAITING" }` to the waiting worker and reloads after `controllerchange`.
- `Later` dismisses the banner for the current session using `sessionStorage`.
- No forced auto-reload without user action.
- Production-only guard remains `import.meta.env.PROD`.
- Service worker no longer auto-runs `skipWaiting()` during install.

Production validation:
- Commit `bb570a6 feat: add PWA update available banner` is deployed.
- Production app returned HTTP 200.
- Production `/sw.js` returned HTTP 200.
- Production `/sw.js` contains `SKIP_WAITING`, `anteiku-static-v2`, and the same-origin guard.
- Production JS bundle contains the update-banner flow.

Security/cache validation:
- No package changes.
- No SQL migrations, Supabase/RLS/RPC changes, or Supabase commands.
- Supabase/API/Auth/RPC/CP/GvG/3v3/admin/analytics data is still not cached.
- Existing conservative service-worker caching remains same-origin static/app-shell only.

Manual verification still needed:
- With an installed/open app, deploy a newer app shell and confirm the banner appears.
- Confirm `Later` dismisses for the current session.
- Confirm `Update App` activates the waiting worker and reloads once.
- Check no console/service-worker errors in target browsers/devices.

## Milestone 26A/26B PWA Install Support Validation

PWA install support passed build, source, local preview, and production asset smoke validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented:
- Added `public/manifest.webmanifest`.
- Added icons under `public/icons/`.
- Added `public/sw.js`.
- Added production-only service worker registration through `src/registerServiceWorker.js`.
- Added manifest, favicon, Apple mobile, and theme-color tags to `index.html`.

Local preview validation:
- Vite preview served `/`, `/manifest.webmanifest`, `/sw.js`, and `/icons/icon-192.png` with HTTP 200.
- Preview index contained manifest and Apple mobile metadata.
- Preview service worker contained the expected static cache name.

Production validation:
- Production app returned HTTP 200.
- Production index contains `/manifest.webmanifest` and Apple mobile metadata.
- Production bundle contains service worker registration.
- Production `/manifest.webmanifest` returned HTTP 200 and includes `Anteiku Guild Manager`, `Anteiku`, and `standalone`.
- Production `/sw.js` returned HTTP 200 and includes the same-origin guard.
- Production `/icons/icon-192.png` returned HTTP 200.

Source/security validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, package/dependency changes, or Vercel env changes were made.
- No auth logic or feature behavior changed.
- Service worker ignores cross-origin requests and does not cache Supabase Auth/RPC/API responses.
- Service worker caches same-origin app shell/static build assets/icons/manifest/approved mark only.
- No CP/GvG/audit/role/permission/member-status/analytics/3v3/cosmetics behavior changed.

Not fully validated:
- Browser-native install prompt visibility and installed standalone launch were not manually verified in this terminal-only pass.

## Milestone 25D 3v3 Production Rollout And Smoke

3v3 Team Finder production rollout and controlled production smoke passed.

Commands/results:
- Production dry-run showed exactly one pending migration: `20260528000100_three_v_three_team_finder.sql`.
- Production migration push applied `20260528000100_three_v_three_team_finder.sql`.
- Remote migration list confirmed `20260528000100` applied.
- Commit `4c9da98 feat: add 3v3 team finder UI` was pushed to `main`.
- Production served a bundle containing the 3v3 UI/RPC wrappers.

Production DB verification:
- `three_v_three_player_profiles`, `three_v_three_teams`, `three_v_three_team_members`, and `three_v_three_join_requests` exist.
- RLS is enabled on all four tables.
- No broad direct anon/authenticated grants exist for the 3v3 tables.
- All 13 3v3 RPCs exist with authenticated execute grants and internal checks.
- Active Owner count remains `1`.
- Simulated normal authenticated direct reads of `member_cp` and `cp_snapshots` returned no visible rows.

Manual controlled production smoke:
- Member A created a 3v3 team.
- Discord username and public 3v3 Combined CP were required/displayed.
- Team card rendered three slots.
- Member B requested to join.
- Member A saw the incoming request and approved it.
- Member B filled the first empty slot.
- Normal protected CP was not visible.
- Normal Member had no AdminPanel access.
- No console/UI blocker was found.
- Test team cleanup status was not specified in the smoke note; verify before assuming retained or disbanded state.

Security/source validation:
- `src/services/threeVThreeService.js` uses only 3v3 RPCs.
- Source checks found no direct `.from('three_v_three_*')` writes, no `member_cp`, no `cp_snapshots`, and no normal CP RPC usage in the 3v3 UI/service.
- No CP/GvG/audit/role/permission/member-status behavior changed.

## Milestone 25C 3v3 Frontend Build And Source Validation

Frontend-only 3v3 Team Finder UI implementation passed local build and source validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented validation target:
- Approved member navigation now includes `3v3`.
- 3v3 page has Find Team, Create Team, and My Requests sub-tabs.
- Team cards render three slots with avatar/frame, IGN, Discord username, and public 3v3 Combined CP.
- Create Team and request flows use public 3v3 Combined CP input.
- My Requests includes current/owned team, outgoing requests, incoming owner queue, and owner actions.

Source/scope result:
- No SQL migrations were edited after 25B.
- No Supabase/RLS/RPC logic changed.
- No staging, production, Vercel env, deploy, or production data action was performed.
- `src/services/threeVThreeService.js` uses only 3v3 RPCs.
- Source checks found no `member_cp`, `cp_snapshots`, own/admin CP RPC calls, or `.from(...)` table access in the 3v3 page/service.
- No AdminPanel, CP/GvG/audit/role/permission/member-status behavior was changed.

Browser validation:
- Local Vite is serving at `127.0.0.1:5173`.
- Authenticated multi-account validation is pending for Milestone 25D staging because request/approve flows need multiple real accounts.

Rollout gate:
- Do not deploy the 3v3 frontend until the target database has `20260528000100_three_v_three_team_finder.sql` applied and verified.

## Milestone 25B 3v3 Team Finder Backend Validation

Backend/RLS/RPC-only local validation passed for 3v3 Team Finder.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Result:
- Local migration stack applied from scratch.
- Full local validation script passed.
- Milestone 25B focused result: 45 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend/runtime source files changed.

Validated:
- New 3v3 tables exist and have RLS enabled.
- No direct anon/authenticated grants exist for 3v3 tables.
- Direct authenticated read/write attempts on 3v3 tables are denied.
- Approved members can update Discord username and public 3v3 Combined CP.
- Pending users are denied.
- Missing Discord is denied for create/request.
- Creator creates a team and occupies slot 1.
- One owned active team and one active team membership are enforced.
- Team name immutability is enforced.
- Team list returns slot payloads and does not expose normal CP.
- Requests to open teams work.
- Duplicate pending request is blocked.
- Declined retry is blocked before the six-hour cooldown and allowed after cooldown when under max attempts.
- Max two attempts per requester/team is enforced.
- Cancelled request can be retried while under the max attempt limit.
- Owner approve fills the first empty slot and cancels other pending requests by that requester.
- Owner decline, remove member, close/reopen, and disband flows work.
- Disbanded teams are hidden from the team finder.
- Max three members/full-team behavior is enforced.
- Non-owner approve/decline/remove/disband attempts are blocked.
- `inactive` users can view but cannot create; `on_break` users cannot request.
- Active Owner count remains one in the validation fixture.

Source/security validation:
- The new migration does not query protected `member_cp` or `cp_snapshots`.
- No frontend UI, service, SQL rollout, staging action, production action, deploy, Vercel env change, or commit was included.

## Analytics UI Polish Production Validation

Frontend-only AdminPanel Analytics UI polish passed build, source validation, and production Owner smoke.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.
- Commit `1db36d3 style: polish admin analytics UI` was pushed to `main`.
- Production served a new Analytics UI bundle.

Source/security validation:
- No SQL migrations were changed.
- No Supabase/RLS/RPC code was changed.
- No analytics service behavior was changed.
- No direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries` reads were added.
- No unsafe `gvg_votes` writes were added.
- No CP values were added outside existing authorized Analytics/Admin surfaces.
- No CP/GvG/audit/role/permission/member-status behavior changed.

Production browser smoke:
- Owner opened AdminPanel -> Analytics.
- Global and individual guild scope chips loaded.
- Overview, Members, CP, GvG, Weekly Growth, and Attention rendered.
- Weekly Growth preserved the baseline behavior from the previous fix.
- Global and Anteiku still showed the expected live growth from the same baseline.
- Start New CP Week was not clicked.
- No captured console errors were observed.

Mobile/layout validation:
- Responsive CSS now keeps scope chips and sub-tabs scrollable.
- Weekly Growth rows collapse into labeled mobile cards.
- No source-level horizontal overflow path was introduced in the Analytics layout.

## Weekly Growth Baseline Scope Fix Production Validation

Weekly Growth baseline scope fix is live and production-smoke validated.

Result:
- Commit `0130ac6 fix: preserve analytics baseline across guild scope` was deployed.
- Production migration `20260526000300_live_cp_growth_baseline_scope.sql` was applied after a clean dry-run showing only that migration pending.
- Production DB verification confirmed both `get_admin_live_cp_growth` overloads exist, authenticated execute is granted, anon execute is denied, and active Owner count remains `1`.
- Local validation passed with Milestone 24B/Live Growth result `36 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production browser smoke:
- Owner opened AdminPanel -> Analytics -> Weekly Growth.
- Global Weekly Growth used baseline `Global weekly snapshot 2026-05-25` and showed `安定区×Ulti` growth `+5,002`.
- Switching scope to Anteiku preserved the same Global baseline and showed `安定区×Ulti` growth `+5,002` filtered to Anteiku.
- Start New CP Week was not clicked.
- No new production snapshot/baseline was created.
- No captured console errors were observed.

Security/source validation:
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- Members and non-authorized users cannot access CP/growth data.
- Frontend Analytics uses RPCs only.
- No direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries` reads were added.
- No CP Update Window, CP Ranking privacy, GvG, audit, role, permission, cosmetics, or member-status behavior changed.

## Live CP Growth Production Validation

Live CP Growth production rollout passed local, production DB, source, build, and Owner read-only browser smoke validation.

Commands:
- Applied the migration locally through Docker `psql`.
- Ran `supabase/tests/local_validation_anteiku.sql` through local Docker `psql`.
- `npm.cmd run build`
- `npx.cmd supabase link --project-ref mzflfyxxkascrfpteexz`
- `npx.cmd supabase migration list`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `git push origin main`

Result:
- Local validation passed with Milestone 24B/Live Growth result `31 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed exactly one pending migration: `20260526000200_live_cp_growth.sql`.
- Production migration push applied `20260526000200_live_cp_growth.sql`.
- Commit `426a720 feat: add live cp growth analytics` was pushed to `main`.
- Production serves the Live CP Growth UI bundle.

Production DB verification:
- Migration `20260526000200` is applied.
- `get_admin_live_cp_growth(p_guild_id uuid default null)` exists.
- `start_new_cp_growth_period(p_guild_id uuid default null, p_label text default null)` exists.
- New RPCs grant execute to `authenticated` and deny `anon`.
- `cp_snapshot_batches` and `cp_snapshot_entries` remain RLS-enabled.
- No direct anon/authenticated table grants exist for `cp_snapshot_batches` or `cp_snapshot_entries`.
- Active Owner count remains `1`.

Production browser smoke:
- Owner opened AdminPanel -> Analytics -> Weekly Growth.
- Global Weekly Growth rendered Reset day Sunday, baseline date, selected scope, and live growth table columns: Baseline CP, Current CP, Growth, Growth %.
- Anteiku guild-scoped Weekly Growth loaded and showed scoped rows.
- No captured console errors were observed.
- Start New CP Week was NOT clicked; production baseline mutation smoke was not performed by design.

Security/source validation:
- Analytics UI/service paths use RPCs only.
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths in the Analytics UI/service paths.
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- No CP Update Window, CP Ranking, GvG, audit, role, permission, cosmetics, or member-status behavior changed.

## Milestone 24E Admin Analytics Production Validation

AdminPanel Analytics production rollout passed migration, DB, source, and Owner browser smoke validation.

Commands:
- `npx.cmd supabase projects list`
- `npx.cmd supabase link --project-ref mzflfyxxkascrfpteexz`
- `npx.cmd supabase migration list`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`
- Read-only `npx.cmd supabase db query --linked --output json ...` verification queries
- `git push origin main`

Result:
- Dry-run showed exactly one pending production migration: `20260526000100_admin_analytics_foundation.sql`.
- Migration push applied `20260526000100_admin_analytics_foundation.sql`.
- Remote migration list shows `20260526000100` applied.
- Production app loads and serves an Analytics-capable bundle.

Production DB verification:
- `cp_snapshot_batches` exists with RLS enabled.
- `cp_snapshot_entries` exists with RLS enabled.
- No direct anon/authenticated table grants exist for the new snapshot tables.
- Analytics RPCs exist and authenticated execute grants are present where expected:
  - `get_admin_member_analytics`
  - `get_admin_cp_analytics`
  - `get_admin_gvg_analytics`
  - `capture_weekly_cp_snapshot`
  - `get_admin_cp_snapshot_history`
  - `get_admin_cp_growth_report`
- Active Owner count remains `1`.
- Simulated authenticated non-member read of `member_cp` and `cp_snapshots` returned zero visible rows.
- Direct authenticated read of `cp_snapshot_batches` was permission denied.

Production browser smoke:
- Owner opened AdminPanel -> Analytics.
- Analytics tab was visible.
- Overview, Members, CP, GvG, Weekly Growth, and Attention rendered with no captured console errors.
- CP Analytics rendered CP stats for Owner.
- Weekly Growth rendered snapshot history controls and the safe `No previous snapshot yet` state.
- Snapshot capture mutation smoke was not performed by design; no production snapshot was created.

Source/security validation:
- `src/services/adminAnalyticsService.js` uses only the six analytics RPCs.
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths in Analytics UI/service paths.
- Existing CP/GvG/member-status behavior was not changed during rollout.

## Milestone 24C Admin Analytics UI Build And Source Validation

Frontend-only AdminPanel Analytics UI implementation passed build and source validation locally.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Implemented validation target:
- AdminPanel now has an `Analytics` tab.
- Analytics sub-tabs are Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Analytics UI is local-only and depends on the Milestone 24B RPC foundation.

Source/scope result:
- No SQL migrations, Supabase/RLS/RPC logic, Supabase commands, package/dependency files, staging actions, production actions, Vercel env changes, deployment, or commits were included.
- `src/services/adminAnalyticsService.js` uses RPC calls only.
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths in the Analytics service/component.
- Profile/Dashboard/member-facing CP behavior was unchanged.
- CP Analytics and Weekly Growth surfaces rely on backend permission enforcement and show compact locked states on permission denial.

Browser validation:
- Local authenticated browser validation is pending.
- `127.0.0.1:5173` was not serving Vite during this checkpoint, so no in-browser Analytics validation was completed.

Rollout warning:
- Do not deploy the 24C Analytics frontend to staging or production until `20260526000100_admin_analytics_foundation.sql` is applied and verified in the target database.

Next validation gate:
- Milestone 24D staging migration + authenticated browser/network validation for Owner, CP-authorized staff, CP-denied staff, and Member AdminPanel denial.

## Milestone 24B Admin Analytics Backend Validation

Backend/RPC-only Admin Analytics foundation validation passed locally.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Result:
- Migrations applied locally from scratch.
- Full local validation script passed.
- Milestone 24B focused result: 23 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend source changed.

Coverage:
- New snapshot tables exist and have RLS enabled.
- No direct anon/authenticated grants exist for `cp_snapshot_batches` or `cp_snapshot_entries`.
- Owner can fetch global member analytics.
- Leader can fetch scoped member analytics.
- Members, pending users, and wrong-guild staff are denied.
- Admin without `view_cp` is denied CP Analytics and snapshot capture.
- Admin with scoped `view_cp` can fetch scoped CP Analytics, capture snapshots, read snapshot history, and get latest-vs-previous growth.
- GvG analytics permission gates passed for authorized and unauthorized users.
- Direct member reads of new snapshot tables are denied.
- Active Owner count remains one after the 24B validation fixture normalization.

## Profile Mobile + Inline Edit Polish Validation

Frontend-only Profile mobile + inline edit polish build, source checks, and local browser validation passed.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Source/scope result:
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency files, deployment config, or backend service behavior were changed.
- Profile still uses only the existing own-CP service wrappers: `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.
- Source checks found no Profile calls to `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, `update_member_cp`, direct `member_cp`, or direct `cp_snapshots`.
- No public profile route, other-player profile service, direct table query, uploads, or Supabase Storage path was added.

Local browser validation:
- Own Profile loaded.
- Approved identity header still rendered with avatar/frame, rank badge, status badges, and Customize.
- Unified Member Profile card rendered with compact own-CP block and account/details block.
- `Your CP` displayed own CP/update-window state with short private self-CP copy.
- Edit converted the existing IGN detail row into an inline input with compact Save IGN / Cancel controls.
- The old separate edit form was removed.
- Desktop CP and Profile Details columns stayed equal height in edit mode.
- Save IGN worked against local Supabase and exited edit mode.
- Customize modal opened.
- Mobile 390px viewport had no horizontal overflow and bottom-nav clearance was verified at page bottom.
- No captured console errors were found.

Production smoke:
- Commit `160c6e9 style: move profile edit action inline` was pushed to `main` and Vercel served the updated production bundle.
- Authenticated production Profile smoke passed.
- Signed-in Profile opened.
- IGN row Edit worked inline.
- Save IGN worked.
- Cancel worked.
- Customize opened.
- `Your CP` still showed only the signed-in user's own CP.
- No visible UI blocker was found.

## Own Profile Polish Validation

Frontend-only Own Profile polish build, source checks, and local browser validation passed.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Source/scope result:
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency files, deployment config, or backend service behavior were changed.
- Profile still uses only the existing own-CP service wrappers: `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.
- Source checks found no Profile calls to `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, `update_member_cp`, direct `member_cp`, or direct `cp_snapshots`.
- No public profile route, other-player profile service, or direct table query was added.
- Dashboard still does not show CP values.

Local browser validation:
- Own Profile loaded on the local app.
- Avatar/frame identity card and Customize action remained visible.
- Customize modal opened and closed.
- `Your CP` rendered as a private self-CP card with current own CP and update-window status.
- Member profile edit and account/details sections rendered.
- No captured console errors were found.

Not fully tested:
- Narrow/mobile viewport was not resized through browser automation in this pass; responsive CSS was preserved and should still receive manual mobile review before production rollout.

## Frontend Command Center Polish Validation

Frontend-only Command Center polish build, manual browser validation, and production smoke passed.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Source/scope result:
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency files, deployment config, or backend service behavior were changed.
- No new Supabase/RPC/table calls were added.
- AdminPanel Overview shortcut cards switch to existing allowed tabs only.
- Member Dashboard shows safe username/IGN/guild/role/status information and no CP values.
- CP/GvG/audit/ranking/role/permission/member-status and cosmetics backend behavior were unchanged.

Manual validation:
- Member Dashboard loaded and showed no CP values.
- Profile quick action opened Profile.
- GvG quick action opened GvG.
- Member had no AdminPanel access.
- AdminPanel opened on Overview.
- Overview cards switched to existing allowed tabs.
- CP/Audit/GvG did not load until their tabs were opened.
- Owner saw Owner Tools shortcut.
- Non-owner Admin did not see Owner Tools shortcut.
- Existing AdminPanel tabs still worked.
- Mobile nav/header were readable and tappable.
- EN/FR/DE copy rendered without raw keys.
- No console errors or unexpected network calls were found.
- No backend/RPC/SQL/package/security behavior changed.

Production smoke:
- Commit `7f7227a feat: polish command center frontend` was deployed.
- Member Dashboard loaded and showed no CP values.
- Profile quick action opened Profile.
- GvG quick action opened GvG.
- Member had no AdminPanel access.
- Owner/Admin opened AdminPanel on Overview.
- Overview cards switched to existing allowed tabs.
- CP/Audit/GvG did not load until their tabs were opened.
- Owner saw Owner Tools shortcut.
- Non-owner Admin did not see Owner Tools shortcut.
- Existing AdminPanel tabs still worked.
- Mobile nav/header were readable and tappable.
- EN/FR/DE copy rendered without raw keys.
- No console errors, unexpected network calls, or backend/RPC/SQL/security regressions were found.

## Owner Cosmetics Grant Tool Validation

Owner Cosmetics frontend validation passed locally, production app-load smoke passed after deployment, and authenticated production smoke passed after the dropdown hotfix.

Commands:
- `npm.cmd run build`
- Local Vite browser validation against local Supabase
- Production bundle/app load smoke at `https://anteiku-guild-manager.vercel.app`

Results:
- Build passed with the existing Vite chunk-size warning only.
- Owner local browser validation:
  - AdminPanel opened.
  - Tools tab opened.
  - Owner Cosmetics section was visible.
  - Cosmetic dropdown rendered from the existing `get_my_cosmetics()` path.
  - Empty username/profile slug validation displayed.
  - Empty cosmetic validation displayed.
- Non-owner Admin local browser validation:
  - Tools tab opened.
  - Owner Cosmetics section was hidden.
- Member local browser validation:
  - Member had no Admin navigation.
  - Owner Cosmetics section was not present.
- Production deployment:
  - Commit `d97fc9f feat: add owner cosmetics grant tool` was pushed.
  - Commit `24287cb fix: hide free cosmetics from owner grant dropdown` was pushed.
  - Vercel production bundle deployed.
  - Production app loaded with no captured console errors.
- Authenticated production smoke:
  - Owner saw AdminPanel -> Tools -> Owner Cosmetics.
  - Dropdown showed only `manual` / `admin_grant` cosmetics.
  - Free/default cosmetics were absent.
  - Empty username/profile slug validation worked.
  - Empty cosmetic validation worked.
  - Non-owner Admin did not see Owner Cosmetics.
  - Member had no AdminPanel access.
  - No console errors, unexpected network calls, or CP/GvG/audit/ranking/member-status regressions were found.
  - Controlled locked avatar/frame grant by exact profile slug / username passed after explicit approval.
  - Granted member could equip the cosmetic after the grant.

Security/source result:
- Source checks found no SQL/migration changes, no direct cosmetic table writes, no upload/Storage/arbitrary URL path, and no CP/GvG/audit/ranking/member-status behavior changes.
- Grant UI uses only `admin_grant_cosmetic_by_slug(...)` for writes.

## Cosmetics Frame Unlock Hotfix Validation

Production rollout/verification passed for the database hotfix.

Commands:
- `node --check scripts\sync-cosmetics-catalog.mjs`
- `npm.cmd run cosmetics:sync -- --dry-run`
- `npm.cmd run build`
- `npx.cmd supabase link --project-ref mzflfyxxkascrfpteexz`
- `npx.cmd supabase migration list`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`

Results:
- Sync script dry-run detected 56 avatars and 20 frames.
- Premium avatar test keys remained `unlock_type = 'manual'`.
- `TXK_Arena*` and `TXK_KOF*` frame rows generated as `manual`.
- C-series/free frame rows generated as `free`.
- Build passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Production migration push applied `20260525220522` and remote migration list confirmed it.
- Read-only production verification found 20 frame rows: 7 Arena manual, 3 KOF manual, 10 other free, 0 other locked.
- Active Owner count remains `1`.
- Production app load smoke passed and no captured console errors were found.
- Authenticated Profile -> Customize -> Frames browser smoke is pending because the browser was signed out and no passwords were requested.

Security/source result:
- No frontend source, RLS/RPC/function behavior, profile equipment rows, uploads, Supabase Storage, arbitrary URLs, CP/GvG/audit/role/permission/member-status behavior, or Vercel env changed.
- The migration updates only `public.cosmetic_catalog.unlock_type` for frame rows.

## Milestone 22F Cosmetics Catalog Sync Script Validation

Milestone 22F local tooling validation passed.

Commands:
- `npm.cmd run cosmetics:sync -- --dry-run`
- `npm.cmd run cosmetics:sync`
- `npm.cmd run build`

Results:
- Dry-run detected 54 avatars and 10 frames.
- Dry-run printed SQL preview and did not write a file.
- Normal run generated `supabase/migrations/20260525193210_cosmetics_catalog_sync.sql`.
- Generated migration contains 64 `public.cosmetic_catalog` upsert rows: 54 avatars and 10 frames.
- Generated migration uses `ON CONFLICT (key) DO UPDATE`.
- Generated migration does not delete or deactivate missing catalog rows.
- Build passed with the existing Vite chunk-size warning only.

Scope/security:
- No Supabase commands were run.
- No staging or production project was touched.
- No migration was applied.
- No runtime frontend behavior, Supabase/RLS/RPC behavior, uploads, Supabase Storage, arbitrary URLs, CP/GvG/audit/role/permission/member-status behavior, Vercel env, deployment, or production data changed.
- Review generated migrations before applying because `unlock_type` is the runtime source of truth.

## Leaderboard Podium Polish Production Checkpoint

Leaderboard podium polish is live in production.

Validation:
- Commit deployed: `3f65052 style: tune leaderboard podium layout`.
- `npm.cmd run build` passed before deployment.
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- No captured production console errors were found on load.

Confirmed UI result:
- Desktop podium visual order is `#2 | #1 | #3`.
- Mobile podium order stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger gold center-card styling and a larger avatar/frame.
- Rank #2 has silver styling.
- Rank #3 has bronze styling.

Security/source result:
- CSS/style-only production polish.
- No SQL migrations, Supabase commands, backend/RPC changes, ranking logic changes, Vercel env changes, or production data mutations were included.
- Member leaderboard CP privacy is unchanged: no member-facing CP values.
- Admin CP Ranking remains permission-protected.

## Milestone 23D Premium Cosmetics Production Rollout Validation

Milestone 23D production rollout passed.

Migration:
- Production project `mzflfyxxkascrfpteexz` was explicitly linked.
- Production migration list showed only `20260525000300_premium_cosmetics_grant_helper.sql` pending.
- Production dry-run showed only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Applied only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Remote migration list confirmed `20260525000300` applied.

Production DB/RPC verification:
- `admin_grant_cosmetic_by_slug(...)` exists.
- `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(...)` has free-or-unlocked enforcement.
- `update_my_profile(...)` rejects locked/manual avatars.
- All 10 current frame rows are free.
- Normal Member grant attempt was denied.
- Owner can manage the controlled member's guild; a production Admin without `manage_members` cannot.
- Direct authenticated insert/write grants to cosmetics unlock/equipped tables remain absent.
- Active Owner count remains `1`.

Production smoke:
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- Page title was `Anteiku Guild Manager`.
- App shell rendered and no captured console errors were found.
- Authenticated Owner/Member UI smoke was not automated because no credentials/session were available and passwords were not requested.
- Free equip and locked/manual mutation smoke were not repeated in production because production mutation was out of scope; staging covered these paths in Milestone 23C.

Security/source validation:
- No frontend source changed.
- Source check found no frontend Storage/upload/direct cosmetics-table write path.
- No Vercel env, deployment, service-role key, `db reset`, `--include-seed`, source edit, SQL edit, new migration, CP/GvG/audit/role/permission/member-status behavior change, upload path, or arbitrary URL path was used.

## Milestone 23C Premium Cosmetics Staging Rollout Validation

Milestone 23C staging rollout and validation passed.

- Staging project `ckyihuxkioeibzpgwenc` received `20260525000200_cp_rankings_cosmetics.sql` and `20260525000300_premium_cosmetics_grant_helper.sql` in order after a clean revised dry-run gate.
- Staging validation passed for current frames free, avatar unlock fields in `get_my_cosmetics()`, locked manual avatar/frame denial before grant, Owner grant by profile slug, member/admin grant denial, granted manual avatar/frame equip, grant audit rows, direct cosmetic write denial, and active Owner count `1`.
- Added staging-only manual test catalog rows `staging_premium_avatar_23c` and `staging_premium_frame_23c` using existing approved repo asset paths.
- Production was not touched during 23C.

## Milestone 23B Premium Cosmetics Backend Local Validation

Milestone 23B backend/database validation passed locally.

Migration:
- Added `20260525000300_premium_cosmetics_grant_helper.sql`.
- Did not edit deployed migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- No frontend UI was implemented.
- Staging and production were not touched.

Validation:
- `npx.cmd supabase db reset` passed locally.
- Full local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend source changed.

Focused checks:
- All current frame rows are free.
- Current avatar rows remain free.
- Manual premium avatar/frame test rows are locked before grant.
- `get_my_cosmetics()` reports manual avatar/frame locked before grant.
- Manual avatar equip is denied without unlock.
- Manual frame equip is denied without unlock.
- `update_my_profile(...)` rejects locked manual avatar keys.
- Invalid slug and invalid cosmetic key are denied.
- Member cannot call grant helper.
- Admin without member-management authority is denied.
- Owner can grant by slug.
- Existing `admin_grant_cosmetic(...)` remains compatible.
- Member can equip granted premium avatar and premium frame.
- `update_my_profile(...)` accepts unlocked manual avatar keys.
- Existing current-frame equip still works after frames become free.
- Cosmetic grant audit rows are written.

## Milestone 22E Cosmetics Production Rollout Validation

Milestone 22E production rollout passed.

Preflight:
- Started from `wip/cosmetics-backend-assets` with the cosmetics backend/assets/frontend commit.
- Production target was `mzflfyxxkascrfpteexz`; staging project `ckyihuxkioeibzpgwenc` was not used for production commands.
- `.env.local` remained restored to local Supabase.

Migration:
- Production dry-run first hit a temporary Supabase CLI login/circuit-breaker error; retry passed.
- Clean dry-run showed exactly one pending migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Applied only `20260525000100_cosmetics_catalog_unlocks.sql` to production.
- Post-push migration list confirmed `20260525000100` applied remotely.
- `db reset`, `--include-seed`, local validation SQL, Owner bootstrap, service role keys, staging commands, and Vercel env changes were not used.

Production DB verification:
- `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics` exist.
- RLS is enabled on all cosmetics tables.
- Catalog contains 54 avatars and 10 frames.
- Production catalog asset paths exactly matched the 64 repo files under `public/cosmetics/`.
- `get_available_avatars`, `get_my_cosmetics`, `equip_my_avatar`, `equip_my_frame`, and `admin_grant_cosmetic` exist.
- Authenticated execute grants are present where expected; anon execute grants are absent.
- Direct unsafe anon/authenticated writes to cosmetics tables are not granted.
- Active Owner count remains `1`.
- `update_my_profile(...)` rejects arbitrary avatar keys.

Deploy/smoke:
- `wip/cosmetics-backend-assets` was merged into `main` and pushed.
- Vercel deployed the production build; production assets and bundle markers for cosmetics were verified.
- User-confirmed production cosmetics UI smoke passed.
- Owner `ultimatesrb` equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` / `krsticmiroslav99+m13b21144225@gmail.com` remains approved/active but did not receive an equipped cosmetics row during this smoke.

Security/source validation:
- Frontend cosmetics path uses only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No direct `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics` writes are used by the frontend.
- No arbitrary URL, upload, or Supabase Storage path exists for cosmetics v1.
- No CP/GvG/audit/member-status regression was found or introduced.

## Milestone 22C Frontend Cosmetics Picker Build And Source Validation

Milestone 22C frontend cosmetics picker was implemented locally, then staging/browser validated through Milestone 22D and production rolled out through Milestone 22E.

Build:
- `npm.cmd run build` passed.
- Vite emitted the existing large chunk warning; build completed successfully.

Local dev server:
- Vite dev server was started and reached at `http://127.0.0.1:5173`.

Source/security-path validation:
- `src/services/cosmeticsService.js` calls only:
  - `get_my_cosmetics`
  - `equip_my_avatar`
  - `equip_my_frame`
- No direct frontend references to `cosmetic_catalog`, `profile_cosmetic_unlocks`, `profile_equipped_cosmetics`, or `admin_grant_cosmetic` were found in `src`.
- No direct frontend `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` paths were added by the Profile/cosmetics picker path.
- No SQL migrations changed.
- No Supabase/RLS/RPC logic changed.
- No production or staging commands were run.

Browser validation:
- Staging validation passed in Milestone 22D.
- Production rollout smoke passed in Milestone 22E.
- Profile cosmetics are compact behind Customize, avatar/frame alignment was visually approved, and equip persistence was verified.

## Milestone 22B Cosmetics Backend Local Validation

Milestone 22B backend/database validation passed locally.

Migration:
- Added local migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Added `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Added cosmetics RPCs and hardened `update_my_profile(p_ign, p_avatar_key)`.
- No frontend UI was implemented.
- Staging and production were not touched.

Local validation:
- `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.

Focused checks:
- Catalog tables and RPCs exist.
- RLS is enabled on cosmetics tables.
- Seeded 54 actual avatar assets and 10 actual frame assets.
- Default avatar `1079_head` and default frame `TXK_frame_reOpen_EN_FREE` exist.
- `_FREE` catalog keys map to `unlock_type = 'free'`, and non-`_FREE` frames map to `unlock_type = 'manual'`.
- Catalog asset paths match local files: 64 rows checked, 0 missing files.
- Member can read active available avatars.
- Member can read own equipped cosmetics and frame unlock status.
- Member can equip a valid avatar.
- Invalid avatar keys are denied.
- Member can equip default frame.
- Locked frame is denied without unlock.
- Owner can grant locked frame.
- Member can equip granted locked frame.
- Member cannot grant self cosmetics.
- Equip RPCs have no target profile argument.
- `update_my_profile(...)` rejects arbitrary avatar keys.
- Existing IGN update still works with a valid catalog avatar key.
- Direct unlock writes are denied.
- Members cannot read another user's unlocks.
- Cosmetic audit rows are written.

Build:
- `npm.cmd run build` was not run because 22B changed only database migrations/tests/docs and no frontend code.

Rollout:
- Staging and production both received `20260525000100_cosmetics_catalog_unlocks.sql` in later rollout milestones.
- Cosmetics picker/assets are live in production as of Milestone 22E.

## Milestone 21E Rank Badge Production Rollout Validation

Milestone 21E production rollout and smoke validation passed.

Preflight:
- Working tree was clean before production rollout.
- Latest commit was `e99bec0 feat: add rank badge UI`.
- Supabase CLI was relinked to production project `mzflfyxxkascrfpteexz`.
- Staging project `ckyihuxkioeibzpgwenc` was not used for production commands.

Migration:
- Production dry-run showed only `20260524000400_cp_rank_badge_summary.sql`.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to production.
- Post-push migration list confirmed `20260524000400` applied remotely.

Production DB/API validation:
- `get_my_cp_rank_summary()` exists and is security definer.
- Authenticated execute grant exists; anon execute grant is absent.
- Return shape is `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Authenticated member-context response contained no CP values, growth/history/snapshot fields, updated timestamps, updated-by metadata, profile ids, usernames, or private metadata.
- Direct authenticated member-context reads of `member_cp` and `cp_snapshots` returned zero rows.
- Active Owner count remains `1`.

Production smoke:
- Owner Dashboard rendered a rank badge/profile visual state.
- Owner AdminPanel opened.
- Existing AdminPanel `CP` tab rendered CP roster and CP Update Window controls.
- AdminPanel `CP Ranking` rendered for Owner.
- Controlled production Member Dashboard/Profile rendered a safe no-rank/default badge state.
- Controlled production Member had no Admin navigation.
- EN/FR/DE rank badge labels worked.
- No console errors were captured on checked production paths.

Source/security checks:
- Profile/Dashboard badge path uses only `get_my_cp_rank_summary()`.
- Profile/Dashboard badge path does not call `get_member_cp_rankings`, `get_admin_cp_rankings`, `get_cp_leaderboard`, `get_current_cp_roster`, or direct CP tables.
- No production CP/member data was mutated.

## Milestone 21D Rank Badge Staging Validation

Milestone 21D staging rollout and authenticated browser validation passed.

Migration:
- Staging dry-run showed only `20260524000400_cp_rank_badge_summary.sql`.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to staging project `ckyihuxkioeibzpgwenc`.
- Remote migration list confirmed `20260524000400` applied.

Validation:
- Staging DB verification passed for RPC existence, safe return shape, authenticated execute grant, no anon execute grant, direct CP table denial, and active Owner count `1`.
- `staging_member` Dashboard/Profile showed `Global Rank #1` / `Rank 1`.
- `staging_wrongguild` showed a safe unranked/default state.
- `staging_pending` stayed locked to Pending.
- EN/FR/DE labels worked.
- Mobile/narrow layout had no horizontal overflow.
- Browser console errors were empty.
- `.env.local` was restored to local Supabase after validation.

## Milestone 21C Profile/Dashboard Rank Badge Frontend Validation

Milestone 21C frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.
- Vite reported the existing large chunk warning only.

Static/source checks:
- `src/services/cpRankBadgeService.js` calls only `get_my_cp_rank_summary()`.
- Profile/Dashboard rank badge paths do not call `get_member_cp_rankings`, `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- No direct frontend `.from('member_cp')` or `.from('cp_snapshots')` calls were added.
- Badge UI does not render or expect CP values, growth/history/snapshot data, profile ids, updated-by metadata, or other-member data.
- Existing CP Leaderboard, CP Update Window, GvG, audit, role, permission, and member-status behavior was not changed.

Validation boundary:
- Authenticated staging browser validation passed in Milestone 21D.
- Production smoke validation passed in Milestone 21E.

Pending validation:
- None for staging/production. Future new target environments must apply and verify `20260524000400_cp_rank_badge_summary.sql` before deploying the rank badge frontend.

## Milestone 21B Rank Badge Summary Backend Validation

Milestone 21B backend/database validation passed locally.

Migration:
- Added local migration `20260524000400_cp_rank_badge_summary.sql`.
- Added `get_my_cp_rank_summary()`.
- No frontend/source UI files were changed.
- No staging or production migration was applied.

Local validation:
- `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.
- Earlier CP validation blocks still passed, including Milestone 20B CP Ranking, Milestone 19B CP Update Window, and Milestone 19B.1 staff window read checks.

Focused checks:
- Ranked members receive own `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Rank 1, 2, 3, 4-5, 6-10, 11-25, and 26+ tier mappings were covered.
- Unranked/no-CP users receive `is_ranked = false` with `unranked` keys.
- `inactive` users are excluded from rank tiers and receive the unranked default state.
- Hard-blocked users are denied by the active approved membership gate.
- Response shape contains no CP values or private fields.
- There is no target profile id parameter, so members cannot request another user's rank summary.
- Direct `member_cp` and `cp_snapshots` reads remain blocked.

Build:
- `npm.cmd run build` was not run because 21B changed only database migration/tests/docs and no frontend code.

Rollout boundary:
- Resolved for staging and production through Milestones 21D and 21E.

## Milestone 20F CP Leaderboard Production Rollout

Milestone 20F production rollout and smoke validation passed.

Preflight:
- Working tree was clean before production rollout.
- Latest commit was `7ccf8c9 feat: add CP ranking UI`.
- Supabase CLI was relinked to production project `mzflfyxxkascrfpteexz`.
- Staging project `ckyihuxkioeibzpgwenc` was not used.

Migration:
- Production dry-run initially hit a transient Supabase temp-db auth/circuit-breaker error, then retry succeeded.
- Successful dry-run showed only `20260524000300_cp_rankings.sql`.
- Applied only `20260524000300_cp_rankings.sql` to production.
- Post-push migration list confirmed `20260524000300` applied remotely.

Production DB/API validation:
- `get_member_cp_rankings(text)` exists and returns no CP fields.
- `get_admin_cp_rankings(uuid,text)` exists and returns CP fields only on authorized admin paths.
- Authenticated execute grants exist for both ranking RPCs.
- Member response shape is `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Owner global admin ranking returned CP fields.
- Non-Owner global admin ranking was denied.
- Direct `member_cp` and `cp_snapshots` reads under authenticated member context returned no rows.
- Active Owner count remained 1.
- Pending ranking denial was not safely testable because no pending production user was available.

Frontend deployment:
- `git push origin main` deployed commit `7ccf8c9 feat: add CP ranking UI`.
- Production bundle contained the expected CP ranking frontend RPC paths after Vercel deployment.

Production browser smoke:
- Controlled production Member loaded the `Ranking` page.
- My Guild and Global tabs loaded.
- Member rows showed rank + IGN only.
- Global rows showed guild labels.
- No CP values, CP growth/history/snapshot data, profile ids, usernames, updated timestamps, or private metadata were visible to Member.
- Member had no Admin navigation.
- Owner opened AdminPanel.
- Existing `CP` tab still rendered CP roster and CP Update Window controls.
- Separate `CP Ranking` tab rendered Guild and Global rankings with CP values for Owner.
- Rank decorations rendered on member and admin rankings.
- No console errors were captured on checked paths.

Source/security validation:
- Member leaderboard uses `get_member_cp_rankings` only.
- Member leaderboard does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- Admin CP Ranking uses `get_admin_cp_rankings`.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were found.
- Existing CP roster/update/window behavior was unchanged.

## Milestone 20E CP Leaderboard Staging Validation

Milestone 20E staging rollout and validation passed.

Migration:
- Staging was linked to project `ckyihuxkioeibzpgwenc`.
- Dry-run showed only `20260524000300_cp_rankings.sql` pending.
- Applied only `20260524000300_cp_rankings.sql`.
- Remote migration list confirmed `20260524000300` applied.
- Production project `mzflfyxxkascrfpteexz` was not used.

Staging DB/API validation:
- `get_member_cp_rankings(text)` exists and returns no CP fields.
- `get_admin_cp_rankings(uuid,text)` exists and returns CP fields only on authorized admin paths.
- Authenticated execute grants exist for both ranking RPCs.
- Member response shape was `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member calls to admin ranking RPC were denied.
- Pending user ranking access was denied.
- Admin without CP permission was denied.
- Owner global admin ranking returned CP fields.
- Non-Owner global admin ranking was denied.
- Active Owner count remained 1.

Browser validation:
- `staging_member` validated My Guild and Global member ranking tabs with no CP values/private CP fields.
- Owner validated AdminPanel CP roster/window controls after the leaderboard was split out.
- Owner validated the separate AdminPanel `CP Ranking` tab with Guild and Global rankings, CP values, and rank decoration.
- `staging_admin_noperms` saw only Tools and no CP/CP Ranking access.
- No console warnings/errors were captured on validated paths.
- Mobile/narrow layout had no horizontal overflow.

Cleanup:
- `.env.local` was restored to local Supabase after validation.

## Milestone 20D AdminPanel CP Leaderboard Frontend Validation

Milestone 20D frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.

Static/source validation:
- AdminPanel CP leaderboard uses `get_admin_cp_rankings`.
- Member Leaderboard still calls only `get_member_cp_rankings`.
- No frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were added.
- The member Leaderboard page does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- Existing AdminPanel CP roster/update/window behavior was preserved.
- Existing CP Update Window, GvG, audit, role, permission, and member-status behavior was not changed.

Validation boundary:
- Authenticated AdminPanel leaderboard browser validation is pending because staging and production do not yet have `20260524000300_cp_rankings.sql`.
- Do not deploy this frontend to a remote target until that migration is applied and verified there.

Pending validation:
- Apply `20260524000300_cp_rankings.sql` to staging after dry-run review.
- Validate Owner AdminPanel CP Guild and Global leaderboard tabs.
- Validate CP values are visible only to authorized staff through `get_admin_cp_rankings`.
- Validate Admin without `view_cp` is denied or sees no CP values.
- Validate Member Leaderboard still shows no CP values.
- Validate EN/FR/DE and mobile layout.

## Milestone 20C Member CP Leaderboard Frontend Validation

Milestone 20C frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.

Browser smoke:
- Local app loaded at `http://127.0.0.1:5173/`.
- Unauthenticated shell/auth screen rendered after the change.

Static/source validation:
- `src/services/cpLeaderboardService.js` calls only `get_member_cp_rankings`.
- The member Leaderboard page does not call `get_admin_cp_rankings`.
- The member Leaderboard page does not call `get_cp_leaderboard`.
- The member Leaderboard page does not call `get_current_cp_roster`.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were added.
- The Leaderboard UI does not render or expect CP values, profile ids, usernames, updated timestamps, growth, snapshots, history, or audit/private metadata.
- AdminPanel CP roster/update/window code paths were not changed.

Validation boundary:
- Authenticated leaderboard browser validation is pending because staging and production do not yet have `20260524000300_cp_rankings.sql`.
- Do not deploy this frontend to a remote target until that migration is applied and verified there.

Pending validation:
- Apply `20260524000300_cp_rankings.sql` to staging after dry-run review.
- Validate My Guild and Global tabs against staging users.
- Confirm Network responses for member leaderboard contain no CP values.
- Confirm member cannot access AdminPanel and CP privacy remains unchanged.

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
