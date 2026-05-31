# Testing

## Milestone 29C Account Switcher UI

Account Switcher UI passed frontend build/source validation and production smoke.

Commands:
- `npm.cmd run build`
- `git push origin main`

Results:
- Build passed with the existing Vite chunk-size warning only.
- Commit deployed: `b8f6162 feat: add account switcher UI`.
- Vercel production deployment is ready and aliases the production domain.

Validated:
- Production app loads while signed in.
- Profile Settings opens.
- Account Switcher card renders above Push Notifications.
- Current active profile is displayed.
- Single-profile state displays cleanly for the smoke account.
- Push Notification settings remain visible.
- No captured console errors.

Security/source checks:
- No SQL/migration/Supabase/RLS/RPC changes.
- Account Switcher frontend uses RPCs only.
- No direct account-link table reads/writes.
- No localStorage authority.
- No normal CP RPCs.
- No `member_cp` / `cp_snapshots` usage except defensive deny-list strings.
- Existing CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin/auth behavior was not switched to active-profile identity.

## Milestone 29B Account Switcher Backend Foundation

Account Switcher backend foundation passed local validation, production dry-run, production migration apply, and read-only production DB verification.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`
- `npx.cmd supabase db query --linked`

Results:
- Local reset applied through `20260531000100_account_switcher_foundation.sql`.
- Full local validation passed.
- Account Switcher validation block: `19 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000100_account_switcher_foundation.sql`.
- Production migration apply passed.
- Production migration list shows `20260531000100` applied.

Validated:
- `user_profile_links` and `user_active_profiles` exist with RLS enabled.
- No direct anon/authenticated grants exist on the new account-link tables.
- Existing one-profile users are self-linked.
- Switchable/active profile RPCs return safe linked profile summaries and no CP/private tokens.
- Active profile selection works for linked profiles and denies unlinked/disabled profiles.
- Owner link/unlink works; non-Owner link is denied.
- Unlinking an active profile clears the active selection safely.
- The only active Owner profile cannot be unlinked.
- Active Owner count remains `1`.
- Production member-context direct reads of `member_cp` and `cp_snapshots` returned `0` visible rows.

Build:
- `npm.cmd run build` was skipped because no frontend/runtime source changed.

## Milestone 28 Push Notifications Production

Push Notifications passed production rollout and manual production smoke.

Production rollout:
- Production dry-run showed only `20260530000800_push_notifications_foundation.sql`.
- Production migration apply passed.
- Production DB verification passed for push tables, RLS, no broad direct grants, push RPC grants, active Owner count `1`, and normal CP table protection.
- `send-push-notifications` Edge Function deployed and listed active.
- Frontend commit deployed: `c761d38 feat: add push notification settings UI`.

Manual production smoke:
- Browser notification permission was allowed/granted.
- Enable Notifications worked.
- Push subscription registered.
- Preferences saved.
- Test notification was received.
- Clicking the notification opened the app.
- Disable flow worked or is available.
- No CP/private/admin data appeared in the notification.
- No console/service-worker blocker found.

Security checks:
- Frontend uses push RPCs only.
- No direct push table reads/writes were added.
- No Supabase RPC/API/Auth response caching was added.
- No frontend service-role key or VAPID private key was added.
- No normal CP paths were added.

## Milestone 28C Push Notification Frontend

Push Notification frontend/settings and service worker handling passed local build/source validation and production smoke.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Validated:
- Profile Settings modal contains Push Notifications controls.
- Push service uses RPCs only.
- Service worker has safe `push` and `notificationclick` handling.
- No direct push table reads/writes were added.
- No Supabase RPC/API/Auth response caching was added.
- No frontend service-role key or VAPID private key was added.
- No normal CP paths were added.

Production status:
- Production Vercel `VITE_VAPID_PUBLIC_KEY` is configured.
- Supabase Edge Function secret names are configured: `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT`; values are not documented.
- Production DB has `20260530000800_push_notifications_foundation.sql` applied.

## Milestone 28B Push Notifications Foundation

Push Notifications backend/RPC and Edge Function foundation passed local validation only.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Results:
- Local reset applied through `20260530000800_push_notifications_foundation.sql`.
- Full local validation passed.
- Push notification validation block: `13 PASS / 0 FAIL / 0 SKIP`.

Validated:
- Push tables exist and RLS is enabled.
- No direct anon/authenticated grants exist on push tables.
- Eligible member can register a subscription and update preferences.
- Pending user is denied push subscription/preferences.
- Another user cannot disable a member's subscription.
- Own disable works.
- Self-test notification queues only for the caller.
- Outbox payload has no private field tokens.
- Direct outbox insert is denied.
- Active Owner count remains `1`.

Source checks:
- New push migration and Edge Function contain no `member_cp`, `cp_snapshots`, normal CP RPCs, or CP value paths.
- No frontend/service-worker/package files changed; `npm.cmd run build` was skipped as not applicable.

Production status:
- Production migration and Edge Function deploy are complete.
- Manual production push smoke passed.

## Social Profile Surfaces Polish

Social Profile Surfaces polish passed build/source validation, deployment, and production smoke.

Build/source:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found only `src/pages/PublicMemberProfile.jsx`, `src/pages/GuildWall.jsx`, and `src/styles/app.css` changed.
- No SQL/migration, Supabase/RLS/RPC, service, auth, CP, GvG, Analytics, 3v3, cosmetics, member-status, PWA/service-worker, package, upload, or Storage files changed.
- Guard search found no `member_cp`, `cp_snapshots`, CP RPCs, direct `.from(...)`, uploads, Storage, or service-role paths in the touched frontend files.

Production:
- Commit deployed: `c92246c style: polish social profile surfaces`.
- Production serves the updated Public Profile and Guild Wall social styling.

Production smoke:
- Signed-in Owner opened `/members/toji`; profile identity, avatar/frame, safe chips, compact Ghoul Rep, public 3v3 CP label, reactions, and normal-CP privacy copy rendered.
- Public profile reaction details opened and showed safe fields/empty state only.
- Guild Wall opened; `Global` and `My Org` scopes loaded, emoji reactions rendered, Ghoul Rep chips remained visible, and no protected CP/email/private tokens appeared.
- No horizontal overflow was detected in the in-app browser viewport.
- No captured console errors.
- Ghoul Rep leaderboard was not implemented because no safe public leaderboard RPC exists yet.

## Ranking Public Profile Links

Ranking to Public Member Profile links passed local DB validation, build/source validation, deployment, and production smoke.

Build/source:
- `npx.cmd supabase db reset` applied through `20260530000700_ranking_public_profile_links.sql`.
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no direct `.from(...)` table access, no normal CP RPC additions, and no protected `member_cp` / `cp_snapshots` frontend usage in the Ranking path.

Production:
- Production DB received `20260530000700_ranking_public_profile_links.sql`.
- Commit deployed: `d806974 feat: link rankings to public profiles`.
- My Guild and Global Ranking rows/cards expose safe `/members/:profileSlug` navigation.

Production smoke:
- Signed-in Owner opened Ranking.
- My Guild Ranking had tappable profile targets.
- Global Ranking had tappable profile targets.
- Tapping Toji opened `/members/toji`.
- Direct `/members/toji` refresh rendered the public profile route.
- Member Ranking still hid protected normal CP values.
- Admin CP Ranking still loaded for Owner in the existing authorized admin-only surface.
- No captured console errors.

## Public Member Profiles

Public Member Profiles/Profile Reactions passed production DB verification, build/source validation, deployment, and production smoke.

Build/source:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no direct `.from(...)` calls in the public profile path.
- Source validation found no `member_cp` / `cp_snapshots` usage except the defensive deny-list guard in `src/services/publicProfileService.js`.
- No CP RPCs, uploads, Storage, direct profile reaction table access, or public unauthenticated profile route were added.

Production:
- Production DB had `20260530000600_public_member_profiles.sql` applied and verified before frontend rollout.
- Commits deployed:
  - `3f55f76 feat: add public member profiles`
  - `ffc36e1 fix: support public profile route refresh`
- Production `/members/:profileSlug` direct route resolves to the React app through the Vercel SPA rewrite.

Production smoke:
- Signed-in Owner opened `/members/ultimatesrb`.
- Public profile rendered avatar/frame, IGN, username/profile slug, guild, safe role label, roster status, Ghoul Rep, public 3v3 Combined CP, and profile reactions.
- Normal CP, email, auth IDs, admin permissions, audit/private metadata were not visible.
- Controlled profile reaction add/remove on `@holder` succeeded and was removed back to zero.
- Reaction details opened and showed only safe public fields/empty state.
- Guild Wall author and comment-author links opened public profiles.
- 3v3 team slot links opened public profiles.
- Pending/restricted browser smoke was not repeated in this frontend rollout.
- No captured console errors.

## Ghoul Rep Profile Polish

Ghoul Rep Profile display and Wall chip polish passed validation and production smoke.

Build/source:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Local `npx.cmd supabase db reset` applied through `20260530000500_my_ghoul_rep_profile.sql`.
- Existing local validation passed through Docker `psql`; Guild Wall/Ghoul Rep remained `47 PASS / 0 FAIL / 0 SKIP`.
- Focused local RPC validation confirmed `get_my_ghoul_rep()` returns the caller's own Ghoul Rep and denies pending users.
- Source checks found no `member_cp`, no `cp_snapshots`, no normal CP RPCs, no uploads/Storage/service-role paths, and no direct Wall table reads/writes in the touched Profile/Wall path.

Production:
- Production dry-run showed only `20260530000500_my_ghoul_rep_profile.sql`.
- Production migration apply succeeded and remote migration list shows `20260530000500` applied.
- Production serves the updated bundle with `get_my_ghoul_rep` and `profile-ghoul-rep-chip`.

Production smoke:
- Signed-in Owner opened Profile and saw a compact own `Ghoul Rep` chip.
- Signed-in Owner opened Wall and saw softened compact Ghoul Rep chips with emoji reactions.
- Wall showed no CP/private data; Profile still shows only the user's existing own CP section.
- No captured console errors.

## Ghoul Rep Wall Frontend

Ghoul Rep frontend UI passed build/source validation and production smoke.

Build/source:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Guild Wall page/service still use RPC-only access.
- Source checks found no direct `.from(...)` wall table access in the Guild Wall page/service.
- Source checks found no `member_cp`, `cp_snapshots`, CP RPCs, uploads, Storage, or service-role paths in the touched Guild Wall page/service/styles.

Production smoke:
- Production serves the updated bundle with `Ghoul Rep`, `author_ghoul_rep`, and `get_wall_reaction_details`.
- Signed-in Owner opened Guild Wall.
- `My Guild` feed showed Ghoul Rep chips on post/comment authors.
- `Global` feed showed Ghoul Rep chips.
- Reaction detail panel opened from a reaction and showed safe public user details.
- Wall scope switching cleared the reaction detail panel.
- No CP/email text appeared in the Wall smoke snapshot.
- No captured console errors.

## Ghoul Rep Wall Reaction Backend

Ghoul Rep backend support passed local validation and production migration/read-only verification.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`

Results:
- Local Guild Wall/Ghoul Rep validation passed `47 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260530000400_ghoul_rep_wall_reactions.sql`.
- Production migration apply succeeded and remote migration list shows `20260530000400` applied.
- Production DB verification passed for `author_ghoul_rep` in the feed function, `get_wall_reaction_details(...)` presence/authenticated execute, private helper denial for authenticated clients, Wall RLS/no direct client grants, no CP/email references in installed Ghoul Rep functions, Owner Global feed read, and active Owner count `1`.

Security/source validation:
- The Ghoul Rep migration references no `member_cp`, `cp_snapshots`, normal CP RPCs, service-role paths, uploads, or Storage.
- Ghoul Rep counts distinct non-self reactors per post/comment target and includes comment reactions.
- Frontend Ghoul Rep chip/reaction-detail UI and own Profile Ghoul Rep display are live.

## Global Wall Scope

Global Wall scope passed local validation, build/source validation, production migration rollout, and production read-only smoke.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase\tests\local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`
- `npm.cmd run build`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`

Results:
- Local Guild Wall validation passed `33 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260530000300_global_wall_scope.sql`.
- Production migration apply succeeded and remote migration list shows `20260530000300` applied.
- Production DB verification passed for nullable wall scope columns, RLS enabled, zero broad direct wall table grants, wall RPC presence, active Owner count `1`, and Owner Global feed read.
- Production bundle contains the Global Wall frontend strings and the app loads with no captured console errors.

Security/source validation:
- Guild Wall frontend uses RPC-only service calls.
- Source checks found no direct `.from(...)` wall table access, no `member_cp`, no `cp_snapshots`, no CP RPCs, no uploads, no Storage paths, and no service-role references.
- No CP/GvG/Analytics/3v3/cosmetics/member-status/auth/role/permission behavior changed.

Manual verification still needed:
- Authenticated controlled production smoke for Global post create/comment/react/delete and Owner/scoped-staff moderation checks.

## Admin Mobile Section Redesign

Admin mobile section redesign passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Production validation:
- Commit `79b15fa style: redesign admin mobile sections` is deployed.
- Vercel commit status reported success.
- Production app returned HTTP 200.
- Production CSS asset `assets/index-D0rC3ZAv.css` contains the new admin mobile section styles.

Behavior:
- Analytics, Members, CP, GvG, Audit Logs, Permissions, and Tools received CSS-only mobile hierarchy/density polish.
- Admin Overview and CP Ranking were kept largely unchanged.
- Weekly Growth rows, audit metadata, permission toggles, CP cards, member manage panels, and Owner Tools are more compact/mobile-safe.

Security/source validation:
- Only `src/styles/app.css` changed.
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, services, package files, PWA/service-worker files, Vercel env changes, or production data mutations.
- No Admin permission logic, CP privacy, Analytics calculations, GvG, 3v3, or member-status behavior changed.
- Source checks found no protected CP/table/RPC/service-role references in the touched CSS.

Manual test checklist:
- At 360/390/430 widths, sign in as an authorized admin/owner.
- Check Admin Analytics, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Confirm Overview and CP Ranking still look good.
- Confirm no horizontal overflow, no bottom-nav overlap, no raw translation keys, no console errors, and no CP values outside existing authorized admin surfaces.

## Admin Mobile UX Polish

Admin mobile UX polish passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Production validation:
- Commit `0dc9eb5 style: polish admin mobile experience` is deployed.
- Production app returned HTTP 200.
- Production JS/CSS assets contain the new Admin mobile section selector and mobile AdminPanel styles.

Behavior:
- AdminPanel uses a compact mobile section selector instead of the heavy horizontal desktop toolbar.
- Desktop AdminPanel tab bar remains unchanged for wider layouts.
- Admin Overview command cards are denser on mobile.
- Analytics scope/sub-tabs/stat cards and Weekly Growth rows are more mobile-safe.
- Members, CP, GvG, Audit Logs, Permissions, and Owner Tools have tighter mobile spacing.
- Admin content has extra bottom padding for bottom navigation clearance.

Security/source validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, services, package files, PWA/service-worker files, Vercel env changes, or production data mutations.
- No Admin permission logic, CP privacy, Analytics calculations, GvG, 3v3, or member-status behavior changed.
- Source checks found no new `member_cp`, `cp_snapshots`, service-role, direct Supabase table access, or admin CP RPC additions in the touched files.

Manual test checklist:
- At 360/390/430 widths, sign in as an authorized admin/owner.
- Open AdminPanel and confirm the section selector is usable.
- Check Admin Overview, Analytics sub-tabs, Approvals, Members manage card, CP roster/window, CP Ranking, GvG admin, Audit Logs, Permissions, and Tools.
- Confirm no horizontal overflow, no bottom-nav overlap, no raw translation keys, no console errors, and no CP values outside existing authorized admin surfaces.

## Offline Notice Banner

Offline Notice Banner passed build, source, and production app-load validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Production validation:
- Commit `2bbd24a feat: add offline notice banner` is deployed.
- Production app loaded after deployment.

Behavior:
- Initial offline state uses `navigator.onLine`.
- Live updates use browser `online` and `offline` events.
- Banner appears only while offline.
- Banner text is `You are offline` and `Live guild data requires an internet connection.`
- Banner hides automatically when connection returns.

Security/cache validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, package/dependency changes, or Vercel env changes.
- No service worker/cache behavior changed.
- Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data is not cached.
- PWA update-banner behavior is unchanged.

Manual test steps:
- Open production in Chrome.
- DevTools -> Network -> Offline.
- Confirm the offline banner appears and does not block bottom navigation.
- Switch Network back Online.
- Confirm the banner disappears.

## PWA Update Available Banner

PWA update-available banner passed build, source, and production asset validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Production validation:
- Commit `bb570a6 feat: add PWA update available banner` is deployed.
- Production app returned HTTP 200.
- Production `/sw.js` returned HTTP 200.
- Production `/sw.js` includes `SKIP_WAITING`, `anteiku-static-v2`, and the same-origin guard.
- Production JS bundle contains the update-banner flow.

Behavior:
- Detects a waiting service worker.
- Shows `New version available` and `Update now to get the latest app changes.`
- `Update App` sends `{ type: "SKIP_WAITING" }` and reloads after `controllerchange`.
- `Later` dismisses for the current session through `sessionStorage`.
- No forced auto-reload without user action.

Security/cache validation:
- No package changes, SQL migrations, Supabase/RLS/RPC changes, or Supabase commands.
- Supabase/API/Auth/RPC/CP/GvG/3v3/admin/analytics data is still not cached.
- Service worker remains same-origin static/app-shell only.

Manual verification still needed:
- Keep an installed/open app session on an old deployment, deploy a newer app shell, and confirm the banner appears.
- Verify `Later` and `Update App` behavior in target browsers/devices.

## Milestone 26A/26B PWA Install Support

PWA install support passed build, source, local preview, and production asset smoke validation.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Local preview:
- `/` returned HTTP 200.
- `/manifest.webmanifest` returned HTTP 200.
- `/sw.js` returned HTTP 200.
- `/icons/icon-192.png` returned HTTP 200.
- Preview index contained manifest and Apple mobile metadata.

Production smoke:
- Production app returned HTTP 200.
- Production index contains manifest and Apple mobile metadata.
- Production JS bundle contains service worker registration.
- Production manifest is served and includes `Anteiku Guild Manager`, `Anteiku`, and `standalone`.
- Production service worker is served and includes the same-origin guard.
- Production icon is served.

Security/cache validation:
- No SQL migrations, Supabase/RLS/RPC changes, Supabase commands, package/dependency changes, auth changes, Vercel env changes, or production data changes were made.
- Service worker ignores cross-origin requests and does not cache Supabase Auth/RPC/API responses.
- Service worker caches same-origin app shell/static assets/icons/manifest only.
- Browser install prompt and standalone launch need a manual device/browser check if install UX confirmation is required.

## Milestone 25D 3v3 Production Rollout

3v3 Team Finder production rollout and controlled production smoke passed.

Production rollout:
- Production dry-run showed exactly one pending migration: `20260528000100_three_v_three_team_finder.sql`.
- Production migration push applied that migration.
- Production DB verification passed for 3v3 table existence, RLS enabled, no broad direct client grants, RPC existence, direct normal-CP read protection, and active Owner count `1`.
- Commit `4c9da98 feat: add 3v3 team finder UI` was pushed to `main` and deployed.

Manual controlled production smoke:
- Member A created a 3v3 team.
- Discord username and public 3v3 Combined CP were required/displayed.
- Team card rendered three slots.
- Member B requested to join.
- Member A saw and approved the incoming request.
- Member B filled the first empty slot.
- Normal protected CP was not visible.
- Normal Member had no AdminPanel access.
- No console/UI blocker was found.
- Test team cleanup status was not specified in the smoke note.

Security validation:
- 3v3 frontend uses the 3v3 RPC service path only.
- No normal CP, `member_cp`, `cp_snapshots`, or direct 3v3 table writes are used by the 3v3 UI/service.

## Milestone 25C 3v3 Frontend UI

Frontend-only 3v3 Team Finder build/source validation passed locally.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Source validation:
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel, deploy, or production data action was included.
- `threeVThreeService` uses only the 25B 3v3 RPCs.
- Source checks found no `member_cp`, `cp_snapshots`, own/admin CP RPC calls, or `.from(...)` table access in the 3v3 page/service.
- Normal CP privacy remains unchanged.

Browser validation:
- Local Vite is serving at `127.0.0.1:5173`.
- Full authenticated create/request/approve validation is pending for staging because it needs multiple real accounts.

Rollout gate:
- Do not deploy the 3v3 frontend until `20260528000100_three_v_three_team_finder.sql` is applied and verified in the target database.

## Milestone 25B 3v3 Team Finder Backend

Backend/RLS/RPC-only local validation passed.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Result:
- Full local validation passed.
- Milestone 25B focused result: 45 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend/runtime source files changed.

Validated:
- 3v3 tables exist and have RLS enabled.
- Direct anon/authenticated table grants are absent.
- Direct authenticated table reads/writes are denied.
- Approved members can update Discord username and public 3v3 Combined CP.
- Missing Discord blocks team creation and join requests.
- Team creation fills owner slot 1.
- One active owned team and one active team membership are enforced.
- Team name immutability is enforced.
- Team list returns slots without normal CP.
- Request create/cancel/decline/approve flows work.
- Duplicate pending requests are blocked.
- Declined retry cooldown and max two attempts are enforced.
- Accepted request fills the first empty slot and cancels other pending requests from that requester.
- Owner remove/disband/close/reopen flows work.
- Non-owner team management attempts are blocked.
- `inactive`/`on_break` action restrictions work.
- Active Owner count remains one in the validation fixture.

Scope:
- No frontend UI, staging, production, Vercel, deploy, or commit action was included.
- Normal protected CP (`member_cp`, `cp_snapshots`) was not used for 3v3 Combined CP.

## Analytics UI Polish

Production validation passed for frontend-only AdminPanel Analytics UI polish.

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Commit `1db36d3 style: polish admin analytics UI` was pushed to `main`.
- Production served the updated Analytics UI bundle.
- Owner production smoke passed:
  - AdminPanel opened.
  - Analytics opened.
  - Global and guild scope chips loaded.
  - Overview, Members, CP, GvG, Weekly Growth, and Attention rendered.
  - Weekly Growth live growth still rendered.
  - Baseline preservation behavior remained intact.
  - Start New CP Week was not clicked.
  - no captured console errors
- Source validation confirmed no SQL/migration changes, no Supabase/RLS/RPC changes, no analytics service behavior changes, no direct protected CP/snapshot table reads, no unsafe `gvg_votes` writes, and no CP/GvG/audit/role/permission/member-status behavior changes.
- Mobile layout source validation confirmed scroll-safe scope chips/sub-tabs and labeled card-style Weekly Growth rows.

## Weekly Growth Baseline Scope Fix

Production validation passed for the Weekly Growth baseline scope fix.

- Migration `20260526000300_live_cp_growth_baseline_scope.sql` was applied to production after a clean dry-run showing exactly that one pending migration.
- Commit `0130ac6 fix: preserve analytics baseline across guild scope` is deployed.
- Local validation passed with Milestone 24B/Live Growth result `36 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production DB verification confirmed:
  - both `get_admin_live_cp_growth` overloads exist
  - authenticated execute is granted
  - anon execute is denied
  - active Owner count remains `1`
- Production smoke confirmed:
  - Global Weekly Growth shows `安定区×Ulti` growth `+5,002`
  - Anteiku Weekly Growth preserves the same Global baseline and also shows `安定区×Ulti` growth `+5,002`
  - Start New CP Week was not clicked
  - no new production snapshot/baseline was created
  - no captured console errors
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- Members and non-authorized users cannot access CP/growth data.

## Live CP Growth Production Validation

Production Live CP Growth validation passed.

- Migration `20260526000200_live_cp_growth.sql` was applied to production after a clean dry-run showing exactly that one pending migration.
- Local validation passed with Milestone 24B/Live Growth result `31 PASS / 0 FAIL / 0 SKIP`.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production DB verification confirmed:
  - migration `20260526000200` is applied
  - `get_admin_live_cp_growth` exists
  - `start_new_cp_growth_period` exists
  - new RPCs allow authenticated execute and deny anon execute
  - `cp_snapshot_batches` and `cp_snapshot_entries` remain RLS-enabled
  - no direct anon/authenticated grants exist for snapshot tables
  - active Owner count remains `1`
- Owner production read-only smoke passed:
  - AdminPanel -> Analytics -> Weekly Growth opens
  - Reset day Sunday is shown
  - baseline date is shown
  - Global scope live growth table renders
  - Anteiku scope live growth table renders
  - no captured console errors
- Production Start New CP Week mutation smoke was not performed by design.
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths in Analytics UI/service paths.

## Milestone 24E Admin Analytics Production Validation

Production rollout validation passed for AdminPanel Analytics.

Commands:
- `npx.cmd supabase migration list`
- `npx.cmd supabase db push --dry-run`
- `npx.cmd supabase db push`
- `npx.cmd supabase migration list`
- Read-only production verification queries through `npx.cmd supabase db query --linked --output json ...`
- `git push origin main`

Result:
- Dry-run showed exactly `20260526000100_admin_analytics_foundation.sql` pending.
- Production migration push applied exactly `20260526000100_admin_analytics_foundation.sql`.
- Remote migration list confirmed `20260526000100` applied.
- Production DB verification passed for snapshot tables, RLS, no direct client grants, Analytics RPC existence/grants, active Owner count `1`, and direct protected-read denial.
- Production bundle contains AdminPanel Analytics UI and analytics RPC wrappers.
- Owner authenticated smoke passed for AdminPanel -> Analytics: Overview, Members, CP, GvG, Weekly Growth, and Attention rendered with no captured console errors.
- Weekly Growth displayed snapshot history controls and safe empty/no-previous state.
- Production snapshot capture mutation smoke was not performed by design.

Security result:
- Analytics frontend uses only Analytics RPCs.
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths.
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.

## Milestone 24C Admin Analytics UI

Frontend-only AdminPanel Analytics UI build/source validation passed locally.

Command:
- `npm.cmd run build`

Result:
- Build passed with the existing Vite chunk-size warning only.

Validated source/scope:
- No SQL migrations, Supabase/RLS/RPC behavior, Supabase commands, staging action, production action, Vercel env change, package/dependency change, deployment, or commit was included.
- Analytics service uses only the 24B RPCs:
  - `get_admin_member_analytics`
  - `get_admin_cp_analytics`
  - `get_admin_gvg_analytics`
  - `capture_weekly_cp_snapshot`
  - `get_admin_cp_snapshot_history`
  - `get_admin_cp_growth_report`
- Source checks found no direct `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths in the Analytics service/component.
- CP Analytics and Weekly Growth use backend permission enforcement and display locked states when denied.

Browser validation:
- Pending.
- Local Vite was not running on `127.0.0.1:5173` during this checkpoint, so authenticated browser validation was not completed.

Rollout gate:
- Do not deploy the Analytics frontend until the target database has `20260526000100_admin_analytics_foundation.sql` applied and verified.
- Next gate is Milestone 24D staging migration plus authenticated browser/network validation.

## Milestone 24B Admin Analytics Backend

Backend/RPC-only local validation passed for Admin Analytics.

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Result:
- Local migration stack applied from scratch.
- Full local validation script passed.
- Milestone 24B focused result: 23 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend source files changed.

Validated:
- `cp_snapshot_batches` and `cp_snapshot_entries` exist, have RLS enabled, and have no direct anon/authenticated grants.
- Owner global member analytics, Leader scoped member analytics, Admin scoped CP analytics, and authorized GvG analytics pass.
- Members, pending users, wrong-guild staff, and admins without `view_cp` are denied where appropriate.
- Snapshot capture creates batch/entry rows only through RPC.
- Snapshot capture is denied without `view_cp`.
- Growth report calculates latest-vs-previous snapshot growth.
- Direct member reads of snapshot tables are denied.
- Active Owner count remains one in the 24B validation fixture.

## Profile Mobile + Inline Edit Polish

Frontend-only Profile mobile + inline edit polish build, source checks, and local browser validation passed.

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Profile keeps the approved identity header with avatar/frame, rank badge, status badges, and Customize.
- Separate `Your CP`, Member profile, and Profile details panels were replaced by one compact Member Profile card.
- The unified card contains own CP, account/details, and inline IGN edit sections.
- Edit converts the existing IGN detail row into an inline input with compact Save IGN / Cancel controls.
- The old separate edit form was removed so desktop CP/Profile Details columns remain balanced.
- Cosmetic modal active tabs and Admin active tabs use flatter crimson styling.

Source/security checks:
- Profile still uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` for own CP.
- Profile does not call `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, or `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found in the Profile own-CP path.
- No public profile route, other-player profile service, uploads, Supabase Storage, or direct table query was added.

Local browser validation:
- Own Profile loaded.
- Unified Member Profile card rendered.
- `Your CP` showed own CP/update-window state with short private self-CP copy.
- Inline IGN edit controls appeared in the IGN detail row after clicking Edit.
- Save IGN worked against local Supabase and exited edit mode.
- Customize modal opened.
- Mobile 390px viewport had no horizontal overflow and bottom-nav clearance was verified at page bottom.
- No captured console errors were found.

Production smoke:
- Commit `160c6e9 style: move profile edit action inline` was pushed and Vercel served the updated bundle.
- Authenticated production Profile smoke passed.
- Signed-in Profile opened.
- IGN row Edit worked inline.
- Save IGN worked.
- Cancel worked.
- Customize opened.
- `Your CP` still showed only the signed-in user's own CP.
- No visible UI blocker was found.

## Own Profile Polish

Frontend-only Own Profile polish build, source checks, and local browser validation passed.

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Profile was reorganized into identity, private own-CP, member profile edit, and account/details sections.
- The `Your CP` card is clearly labeled as private/self CP.
- No backend, SQL, Supabase/RLS/RPC, service behavior, public profile routing, or other-player profile viewing was added.

Source/security checks:
- Profile still uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` for own CP.
- Profile does not call `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, or `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found in the Profile own-CP path.
- Dashboard still does not show CP values.

Local browser validation:
- Own Profile loaded.
- Avatar/frame and rank identity card rendered.
- Customize opened and closed.
- Private `Your CP` card rendered current own CP and update-window status.
- Member profile edit and account/details sections rendered.
- No captured console errors were found.

Not fully tested:
- Narrow/mobile viewport was not resized through browser automation in this pass; manual mobile review is recommended before production rollout.

## Frontend Command Center Polish

Build, manual browser validation, and production smoke passed for the frontend-only Command Center polish.

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Member Dashboard was updated with safe identity/status cards and quick actions; no CP values were added.
- AdminPanel Overview was added as a command-center tab that switches to existing allowed sections only.
- No new Supabase/RPC/table calls were added.
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency files, service behavior, deployment config, or production data changed.
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
- Profile and GvG quick actions worked.
- Member had no AdminPanel access.
- Owner/Admin opened AdminPanel on Overview.
- Overview cards switched to existing allowed tabs.
- CP/Audit/GvG did not load until their tabs were opened.
- Owner saw Owner Tools shortcut; non-owner Admin did not.
- Existing AdminPanel tabs still worked.
- Mobile nav/header were readable and tappable.
- EN/FR/DE copy rendered without raw keys.
- No console errors, unexpected network calls, or backend/RPC/SQL/security regressions were found.

## Owner Cosmetics Grant Tool

Frontend validation passed locally, production app-load smoke passed after deployment, and authenticated production smoke passed after the dropdown hotfix.

- `npm.cmd run build` passed.
- Local Owner browser validation:
  - AdminPanel opened.
  - Tools tab opened.
  - Owner Cosmetics section was visible.
  - Cosmetic dropdown rendered.
  - Empty username/profile slug validation worked.
  - Empty cosmetic validation worked.
- Local non-owner Admin browser validation:
  - Tools tab opened.
  - Owner Cosmetics section was hidden.
- Local Member browser validation:
  - Member had no Admin navigation.
  - Owner Cosmetics section was not present.
- Commit `d97fc9f feat: add owner cosmetics grant tool` was pushed to `main`.
- Commit `24287cb fix: hide free cosmetics from owner grant dropdown` was pushed to `main`.
- Vercel production bundle deployed and production app loaded with no captured console errors.
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
- No SQL/migration changes.
- No Supabase/RLS/RPC changes.
- No direct cosmetic table writes.
- No upload, Supabase Storage, or arbitrary URL behavior.
- Grant writes use only existing `admin_grant_cosmetic_by_slug(...)`.

## Cosmetics Frame Unlock Hotfix

Production database hotfix validation passed.

- `node --check scripts\sync-cosmetics-catalog.mjs` passed.
- `npm.cmd run cosmetics:sync -- --dry-run` showed premium avatars remain manual, `TXK_Arena*` / `TXK_KOF*` frames are manual, and C-series/free frames are free.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production dry-run showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Production migration push applied `20260525220522`.
- Remote migration list confirmed `20260525220522` applied.
- Read-only production verification found 20 frame rows: 7 Arena manual, 3 KOF manual, 10 other free, and 0 other locked.
- Active Owner count remains `1`.
- Production app load smoke passed with no captured console errors.
- Authenticated Profile -> Customize -> Frames smoke is pending until a production browser session is available.

Security result:
- The hotfix updates only catalog frame `unlock_type` values.
- No profile equipment rows, frontend runtime behavior, RLS/RPC/function behavior, uploads, Supabase Storage, arbitrary URLs, CP/GvG/audit/role/permission/member-status behavior, or Vercel env changed.

## Leaderboard Podium Polish Production Checkpoint

Leaderboard podium polish is live in production.

Validation:
- Commit deployed: `3f65052 style: tune leaderboard podium layout`.
- `npm.cmd run build` passed before deployment.
- Production app loaded at `https://anteiku-guild-manager.vercel.app`.
- No captured production console errors were found on load.

Confirmed:
- Desktop podium visual order is `#2 | #1 | #3`.
- Mobile podium order stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger gold center-card styling and a larger avatar/frame.
- Rank #2 has silver styling.
- Rank #3 has bronze styling.

Security/scope:
- Frontend/style-only change.
- No SQL migrations, Supabase/RLS/RPC changes, ranking logic changes, Vercel env changes, or production data mutations were included.
- Member leaderboard still hides CP values.
- Admin CP Ranking remains permission-protected.

## Milestone 23D Premium Cosmetics Production Validation

Milestone 23D production rollout passed.

Migration:
- Production dry-run showed only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Applied only `20260525000300_premium_cosmetics_grant_helper.sql` to production project `mzflfyxxkascrfpteexz`.
- Remote migration list confirmed `20260525000300` applied.

Production verification:
- `admin_grant_cosmetic_by_slug(...)` exists.
- `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(...)` and `update_my_profile(...)` include free-or-unlocked/manual-lock enforcement.
- All current frame rows are free.
- Normal Member grant attempt was denied.
- Direct authenticated write grants to cosmetics unlock/equipped tables remain absent.
- Active Owner count remains `1`.

Production smoke:
- Production app loaded at `https://anteiku-guild-manager.vercel.app` with title `Anteiku Guild Manager`.
- No captured console errors were found on load.
- Authenticated Owner/Member browser smoke and production locked/manual mutation smoke were not run because no credentials/session were available and production mutation was out of scope.
- Staging Milestone 23C covered locked/manual grant/equip runtime behavior.

## Milestone 23C Premium Cosmetics Staging Validation

Milestone 23C staging rollout and validation passed.

- Staging received `20260525000200_cp_rankings_cosmetics.sql` and `20260525000300_premium_cosmetics_grant_helper.sql` in order.
- Current frames are free on staging.
- `get_my_cosmetics()` reports avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `staging_member` could equip free avatar/frame and could not equip locked manual avatar/frame before grant.
- `staging_owner` granted manual test cosmetics to `staging_member` by profile slug.
- `staging_member` could equip granted manual avatar/frame.
- `staging_admin_noperms` and normal member grant attempts were denied.
- Cosmetic grant audit rows were written.
- Staging-only manual test rows remain: `staging_premium_avatar_23c`, `staging_premium_frame_23c`.

## Milestone 23B Premium Cosmetics Backend Local Validation

Milestone 23B backend/database validation passed locally.

Migration:
- Added `20260525000300_premium_cosmetics_grant_helper.sql`.
- Existing deployed migration `20260525000100_cosmetics_catalog_unlocks.sql` was not edited.
- Staging and production were not touched.

Validation:
- `npx.cmd supabase db reset` passed locally.
- Full local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend source changed.

Focused checks:
- Current frames become free.
- Current avatars remain free.
- Manual premium avatar/frame rows are locked before grant.
- Manual avatar/frame equip is denied without unlock.
- Grant-by-slug unlocks premium cosmetics for an approved member.
- Member can equip granted premium avatar and frame.
- `update_my_profile(...)` rejects invalid and locked manual avatar keys and accepts unlocked manual avatar keys.
- Invalid slug/cosmetic key, member grant attempts, and admin-without-authority attempts are denied.
- Existing `admin_grant_cosmetic(...)` and `equip_my_frame(...)` remain compatible.
- Cosmetic grant audit rows are written.

## Milestone 22E Cosmetics Production Rollout Validation

Milestone 22E production rollout and smoke validation passed.

Migration:
- Production dry-run showed only `20260525000100_cosmetics_catalog_unlocks.sql` after a retry from a temporary Supabase CLI login/circuit-breaker issue.
- Applied only `20260525000100_cosmetics_catalog_unlocks.sql` to production project `mzflfyxxkascrfpteexz`.
- Remote migration list confirmed `20260525000100` applied.
- No `db reset`, `--include-seed`, local fake-user validation SQL, Owner bootstrap, service role key, staging command, or Vercel env change was used.

Production DB verification:
- Cosmetics tables exist and RLS is enabled.
- Catalog contains 54 avatars and 10 frames.
- Production catalog asset paths exactly matched the 64 repo files under `public/cosmetics/`.
- Cosmetics RPCs exist and grants are safe.
- Direct unsafe anon/authenticated writes to cosmetics tables are not granted.
- Active Owner count remains `1`.
- `update_my_profile(...)` avatar key hardening is active.

Production smoke:
- Vercel deployed the cosmetics frontend/assets.
- User-confirmed production cosmetics UI smoke passed.
- Owner `ultimatesrb` equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` remains approved/active but did not receive an equipped cosmetics row during this smoke.

Security:
- Cosmetics frontend uses only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No direct cosmetics table writes, arbitrary URLs, uploads, Supabase Storage, or CP/GvG/audit/member-status regressions were introduced.

## Milestone 22C Frontend Cosmetics Picker Validation

Milestone 22C was implemented locally, validated through staging in Milestone 22D, polished in Milestones 22D.1-22D.3, and rolled out to production in Milestone 22E.

Build/source validation:
- `npm.cmd run build` passed.
- Cosmetics service uses only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No direct frontend cosmetics table calls were added.
- No admin cosmetic grant UI was added.
- No new direct CP/audit/GvG protected table paths were added by the cosmetics picker.

Browser validation:
- Staging browser validation passed in Milestone 22D.
- Compact Customize modal, Avatars/Frames tabs, profile header/rank placement, and avatar/frame alignment polish passed in Milestones 22D.1-22D.3.
- Production smoke passed in Milestone 22E.

Network checklist:
- Initial/Profile cosmetics load uses `get_my_cosmetics`.
- Avatar equip uses `equip_my_avatar`.
- Frame equip uses `equip_my_frame`.
- No direct `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics` calls.
- No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` calls.

Rollout:
- Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified.
- Cosmetics picker/assets are live in production as of Milestone 22E.

## Milestone 22B Cosmetics Backend Local Validation

Milestone 22B backend/database validation passed locally.

Migration:
- Local migration `20260525000100_cosmetics_catalog_unlocks.sql` adds cosmetics catalog/unlock/equipped tables and RPCs.
- No frontend UI was implemented.
- Staging and production were not touched.

Validation:
- `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.

Focused checks:
- Cosmetics tables and RPCs exist.
- RLS is enabled on all cosmetics tables.
- Catalog seed rows match actual local assets: 54 avatars and 10 frames.
- Default avatar `1079_head` and default frame `TXK_frame_reOpen_EN_FREE` exist.
- `_FREE` catalog keys map to `unlock_type = 'free'`, and non-`_FREE` frames map to `unlock_type = 'manual'`.
- Catalog asset paths match local files: 64 rows checked, 0 missing files.
- Member can read active available avatars and own cosmetics.
- Member can equip valid avatar and default frame.
- Invalid avatar and locked frame without unlock are denied.
- Owner can grant locked frame.
- Member can equip granted frame.
- Member cannot grant self cosmetics.
- Equip RPCs have no target profile argument.
- `update_my_profile(...)` rejects arbitrary avatar keys.
- Existing IGN update still works with a valid catalog avatar.
- Direct unlock writes are denied.
- Other-member unlocks remain hidden.
- Cosmetic audit rows are written.

Build:
- `npm.cmd run build` was not run because 22B changed only database migrations/tests/docs and no frontend code.

Rollout:
- Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified.

## Milestone 21E Rank Badge Production Validation

Milestone 21E production rollout and smoke validation passed.

Migration:
- Production dry-run showed only `20260524000400_cp_rank_badge_summary.sql`.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to production project `mzflfyxxkascrfpteexz`.
- Remote migration list confirmed `20260524000400` applied.

Validation:
- `get_my_cp_rank_summary()` exists and authenticated execute grant is present.
- Return shape is limited to `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Authenticated member-context response contained no CP values, growth/history/snapshot fields, updated timestamps, updated-by metadata, profile ids, usernames, or private metadata.
- Direct authenticated member-context reads of `member_cp` and `cp_snapshots` returned zero rows.
- Active Owner count remains `1`.

Production smoke:
- Owner Dashboard rank badge rendered.
- Owner AdminPanel opened.
- Existing `CP` tab still rendered roster and CP Update Window controls.
- `CP Ranking` still rendered for Owner.
- Controlled production Member Dashboard/Profile showed a safe no-rank/default badge state.
- Controlled production Member had no Admin navigation.
- EN/FR/DE rank badge labels worked.
- No console errors were captured on checked paths.

## Milestone 21D Rank Badge Staging Validation

Milestone 21D staging rollout and browser validation passed.

- Staging project `ckyihuxkioeibzpgwenc` received only `20260524000400_cp_rank_badge_summary.sql`.
- Staging DB verification passed for safe RPC shape, execute grants, direct CP table denial, and active Owner count `1`.
- `staging_member` showed `Global Rank #1` / `Rank 1`.
- `staging_wrongguild` showed a safe unranked/default state.
- `staging_pending` remained locked.
- EN/FR/DE labels and mobile layout passed.
- `.env.local` was restored to local Supabase.

## Milestone 21C Profile/Dashboard Rank Badge Frontend Validation

Milestone 21C frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.
- Vite reported the existing large chunk warning only.

Static/source checks:
- Rank badge service calls only `get_my_cp_rank_summary()`.
- Profile/Dashboard badge paths do not call member/admin leaderboard RPCs, CP roster/leaderboard RPCs, or direct CP tables.
- Badge UI does not render CP values, growth/history/snapshot data, profile ids, usernames from the rank RPC, updated-by metadata, or other-member data.
- No SQL migrations were edited or created.
- Existing CP Leaderboard, CP Update Window, GvG, audit, role, permission, and member-status behavior was unchanged.

Validation boundary:
- Authenticated staging browser validation passed in Milestone 21D.
- Production smoke validation passed in Milestone 21E.

## Milestone 21B Rank Badge Summary Local Validation

Milestone 21B backend/database validation passed locally.

Migration:
- Local migration `20260524000400_cp_rank_badge_summary.sql` adds `get_my_cp_rank_summary()`.
- No frontend UI was implemented.
- Staging and production received this migration in Milestones 21D and 21E.

Validation:
- `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.
- Existing CP Ranking and CP Update Window validation blocks still passed.

Focused checks:
- Rank 1/2/3, Elite Five, Top Ten, High Rank, and Ranked Member tier mappings passed.
- Unranked/no-CP users return `is_ranked = false` and `unranked` keys.
- `inactive` users return the unranked/default state.
- Hard-blocked users are denied.
- Response shape contains no CP values or private fields.
- No other-user rank lookup parameter exists.
- Direct `member_cp` and `cp_snapshots` access remains blocked.

Build:
- `npm.cmd run build` was not run because 21B changed only database migration/tests/docs and no frontend code.

## Milestone 20F CP Leaderboard Production Validation

Milestone 20F production rollout and smoke validation passed.

Migration:
- Production dry-run initially hit a transient Supabase temp-db auth/circuit-breaker error, then retry succeeded.
- Successful dry-run showed only `20260524000300_cp_rankings.sql`.
- Applied only `20260524000300_cp_rankings.sql` to production project `mzflfyxxkascrfpteexz`.
- Remote migration list confirmed `20260524000300` applied.

Validation:
- Ranking RPCs exist and authenticated execute grants are present.
- Member ranking response shape has no CP fields.
- Owner admin rankings return CP values.
- Non-Owner global admin ranking is denied.
- Direct `member_cp` and `cp_snapshots` reads remain blocked for normal authenticated users.
- Active Owner count remains 1.

Production smoke:
- Member `Ranking` page loaded My Guild and Global tabs.
- Member UI showed rank + IGN only, with guild labels on Global.
- No CP values, growth/history/snapshot data, profile ids, usernames, updated timestamps, or private metadata were visible to Member.
- Member had no Admin navigation.
- Owner AdminPanel opened.
- Existing `CP` tab still rendered roster and CP Update Window controls.
- Separate `CP Ranking` tab rendered Guild and Global rankings with CP values for Owner.
- No console errors were captured on checked paths.

Source/security checks:
- Member leaderboard uses `get_member_cp_rankings` only.
- Member leaderboard does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- Admin CP Ranking uses `get_admin_cp_rankings`.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were found.

## Milestone 20E CP Leaderboard Staging Validation

Milestone 20E staging rollout and validation passed.

Migration:
- Staging dry-run showed only `20260524000300_cp_rankings.sql`.
- Applied only `20260524000300_cp_rankings.sql` to staging project `ckyihuxkioeibzpgwenc`.
- Remote migration list confirmed `20260524000300` applied.
- Production was not touched.

Validation:
- Ranking RPCs exist and authenticated execute grants are present.
- Member ranking responses include only rank, IGN, guild labels, and current-user flag.
- Owner admin rankings return CP values.
- Non-Owner global admin rankings are denied.
- Pending and Admin-without-CP access are denied.
- Member My Guild and Global ranking UI showed no CP values.
- Owner AdminPanel CP tab kept roster/window controls.
- Owner separate `CP Ranking` tab showed Guild/Global admin rankings with CP values.
- Restricted Admin saw no CP or CP Ranking access.
- No console warnings/errors were captured on validated browser paths.
- `.env.local` was restored to local Supabase.

## Milestone 20D AdminPanel CP Leaderboard Frontend Validation

Milestone 20D frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.

Static/source checks:
- AdminPanel CP leaderboard uses `get_admin_cp_rankings`.
- Member leaderboard service still uses only `get_member_cp_rankings`.
- Member leaderboard does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were added.
- Existing AdminPanel CP roster, manual CP update, and CP Update Window behavior was not changed.
- Existing CP Update Window, member CP Ranking, GvG, audit, role, permission, and member-status behavior was not changed.

Validation boundary:
- Authenticated browser validation is pending until staging receives `20260524000300_cp_rankings.sql`.
- Do not deploy this frontend to staging or production until that target DB has the CP Ranking migration applied and verified.

## Milestone 20C Member CP Leaderboard Frontend Validation

Milestone 20C frontend implementation passed build and source/security-path validation.

Build:
- `npm.cmd run build` passed.

Browser smoke:
- Local app loaded at `http://127.0.0.1:5173/`.
- Unauthenticated shell/auth screen rendered after the change.

Static/source checks:
- Member leaderboard service uses only `get_member_cp_rankings`.
- Member leaderboard does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were added.
- Leaderboard UI does not render or expect CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, or private metadata.
- Existing AdminPanel CP roster/update/window behavior was not changed.

Validation boundary:
- Authenticated browser validation is pending until staging receives `20260524000300_cp_rankings.sql`.
- Do not deploy this frontend to staging or production until that target DB has the CP Ranking migration applied and verified.

## Milestone 20B CP Leaderboard Backend Validation

Milestone 20B backend/database validation passed locally.

Migration:
- `20260524000300_cp_rankings.sql`

Commands:
- `npx.cmd supabase db reset`
- `Get-Content supabase/tests/local_validation_anteiku.sql | docker exec -i supabase_db_Project_Anteiku psql -U postgres -d postgres`

Tooling note:
- The Supabase CLI `db query --local --file` path could not execute the multi-statement validation script, so the same validation SQL was run through Docker `psql`.

Focused 20B result:
- 14 PASS / 0 FAIL / 0 SKIP.

Validated:
- Member guild/global rankings return rank order and IGN/guild labels only.
- Member ranking response shape has no CP fields, profile id, username, timestamps, snapshots, growth, history, or audit metadata.
- Current user row marks `is_current_user`.
- Rank ordering is deterministic by CP descending and tie-breakers.
- Trial and pending-transfer rows are included.
- Inactive, on_break, suspended, left, and kicked rows are excluded.
- Inactive active-membership users can still view rankings.
- Hard-blocked users are denied.
- Member cannot call admin ranking RPC.
- Admin with scoped `view_cp` can see guild CP values.
- Admin without scoped `view_cp` is denied.
- Non-Owner Admin is denied global admin rankings.
- Owner can see global admin CP values.
- Direct `member_cp` and `cp_snapshots` reads remain denied for normal members.

Not run:
- `npm.cmd run build` was not needed because no frontend code changed.
- Staging/production migration rollout and frontend browser validation are pending future milestones.

## Milestone 19E CP Update Window Production Smoke

Milestone 19E production rollout passed after applying both CP Update Window migrations and deploying commit `6a3a181 feat: add CP update window self-submit`.

Migration validation:
- Production dry-run showed only `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.
- Both migrations were applied to production.
- Production DB verification passed for `cp_update_windows`, RLS, one-open-window unique index, safe RPCs/grants, direct client grant absence, audit redaction support, and active Owner count.

Production smoke:
- App loaded at `https://anteiku-guild-manager.vercel.app`.
- Owner could sign in and open AdminPanel CP.
- CP Update Window block rendered and selected-guild status loaded as `Closed`.
- Member could sign in and open Profile.
- `Your CP` card rendered and showed only the signed-in member's own CP.
- With no CP window open, member submit controls were not exposed and the closed-window message rendered.
- Member had no Admin navigation and no CP roster/leaderboard access.
- No captured console errors were observed on the checked paths.

Not performed:
- Controlled production CP mutation smoke was not performed by design.
- Future mutation smoke requires explicit approval and a controlled production test member.

## Milestone 19C CP Update Window Frontend Validation

Milestone 19C frontend implementation passed build and source/security-path validation locally.

Build:
- `npm.cmd run build` passed.

Local smoke:
- Local app loaded at `http://127.0.0.1:5173/`.
- Auth page rendered and no captured console errors were observed.

Static/source checks:
- No Supabase migration files changed.
- No Supabase test files changed.
- `src/services/cpWindowService.js` uses RPCs only.
- No direct frontend `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('cp_update_windows')` calls were found.
- Profile and `cpWindowService` do not call `get_current_cp_roster` or `get_cp_leaderboard`.
- Member Profile CP self-submit uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.
- AdminPanel CP Update Window controls use only `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.

Not yet run:
- Authenticated CP-window browser validation is pending because staging and production do not have migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.
- Do not deploy this frontend to an environment until those migrations are applied and verified there.

Next validation:
- Apply both CP Update Window migrations to staging only after dry-run review.
- Validate Profile `Your CP` self-submit and AdminPanel CP Update Window controls against controlled staging users.

## Milestone 19B.1 CP Update Window Staff Read Validation

Milestone 19B.1 backend/database validation passed locally.

Commands:
- `npx.cmd supabase db reset`
- `supabase/tests/local_validation_anteiku.sql`

Focused 19B.1 result:
- 13 PASS / 0 FAIL / 0 SKIP.

Validated:
- `get_cp_update_window_for_guild(uuid)` exists.
- Normal authenticated users still cannot directly read `cp_update_windows`.
- Owner can read selected-guild open window status.
- Leader/Vice can read scoped guild window status.
- Leader wrong-guild read is denied.
- Admin with CP permission can read scoped guild window status.
- Admin with `view_cp` can read scoped guild window status.
- Admin without CP permission is denied.
- Member is denied.
- Wrong-guild user is denied.
- Open window is returned first.
- Latest closed window is returned when no open window exists.
- No row is returned for a guild with no CP windows.

## Milestone 19B CP Update Window Backend Validation

Milestone 19B backend/database validation passed locally.

Commands:
- `npx.cmd supabase db reset`
- `supabase/tests/local_validation_anteiku.sql`

Focused 19B result:
- 32 PASS / 0 FAIL / 0 SKIP.

Validated:
- `cp_update_windows` table exists with RLS enabled.
- Direct client grants are absent.
- One open CP Update Window per guild is enforced.
- Owner and authorized CP staff can open/close windows.
- Member and Admin without `update_cp` cannot open/close windows.
- Member can read safe active-window info only for own guild.
- Member can read only own CP through `get_my_cp()`.
- Member cannot directly read `member_cp`, `cp_snapshots`, or `cp_update_windows`.
- Member can submit own CP while the applicable guild window is open.
- Submit is denied for closed, future, expired, wrong-guild, and missing-window cases.
- Negative CP is rejected.
- `inactive`, `on_break`, `suspended`, `left`, and `kicked` submit attempts are denied.
- Multiple submissions update latest CP and create audit history.
- `member_cp_self_submitted` audit rows are created.
- CP old/new metadata is redacted for audit users without `view_cp` and visible for scoped users with `view_cp`.
- Existing admin CP RPC behavior still passes.

Not run:
- `npm.cmd run build` was not needed because no frontend source changed.
- Staging/production rollout and browser validation are pending future milestones.

## Milestone 16H Member-Facing UI Production Smoke

Milestone 16H production smoke passed after deploying commit `53c7907 style: clean up member-facing UI`.

Validated:
- Production app loads at `https://anteiku-guild-manager.vercel.app`.
- Language switcher works and persists after reload.
- Login/Register panels are compact and translated.
- Forgot Password remains visible.
- Production Owner can sign in and open AdminPanel.
- Controlled production Member can sign in.
- Member Dashboard/Profile/GvG are compact and translated.
- Member cannot access AdminPanel.
- No other-member CP exposure was found.
- No raw translation keys are visible.
- No console errors were captured.
- Narrow/mobile viewport had no horizontal overflow.

Security notes:
- CP privacy, GvG behavior, Audit access, role/permission behavior, and Member Status behavior were unchanged.
- No SQL, Supabase/RLS/RPC, Vercel env, or production data changes were made.

## Milestone 18F Language Pack Production Smoke

Milestone 18F production smoke passed after deploying commit `1f5b956 feat: add English French German language pack`.

Validated:
- Production app loads at `https://anteiku-guild-manager.vercel.app`.
- Language switcher is visible logged out and logged in.
- EN/FR/DE switching works and persists after reload.
- Login/register/forgot-password copy translates.
- Production Owner can sign in and open AdminPanel.
- AdminPanel tabs translate in EN/FR/DE.
- Members, CP, GvG, Audit Logs, Permissions, and Tools tabs render.
- No raw translation keys are visible.
- No console errors were captured.
- Narrow/mobile viewport had no horizontal overflow.
- Existing production Member cannot access AdminPanel.

Security notes:
- CP privacy, Audit access, GvG behavior, role/permission behavior, and Member Status behavior were unchanged.
- No SQL, Supabase/RLS/RPC, Vercel env, or production data changes were made.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.

## Milestone 17D Registration Copy And Onboarding Prep

Milestone 17D prepares the frontend copy for controlled guild onboarding without assuming email confirmation.

Build/source validation:
- `npm.cmd run build` passed.
- No SQL migrations changed.
- No Supabase/RLS/RPC behavior changed.
- No Supabase Auth settings changed during this copy pass.
- No service files changed.
- No CP, GvG, audit, role/guild/permission, member-status, approval, or membership behavior changed.

Staging validation plan:
- Disable email confirmation in staging Supabase project `ckyihuxkioeibzpgwenc` only.
- Keep production email confirmation enabled.
- Register a new controlled staging user.
- Confirm the user lands pending without email confirmation.
- Confirm pending user cannot access member/admin areas.
- Confirm Owner sees the approval request.
- Confirm Owner can approve the user.
- Confirm approved user can access member area.
- Confirm forgot password still sends recovery email.
- Confirm recovery link still forces `Set new password`.

## Milestone 17C Password Recovery Production Validation

Milestone 17C production rollout validation passed.

Deployment:
- Commit deployed: `23dd956 fix: require password reset after recovery link`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.

Smoke validation:
- Production app loads.
- Login/register screen works.
- Forgot-password UI is visible.
- Controlled member access remains member-only.
- No AdminPanel exposure for the controlled member.
- No captured console warnings/errors were observed.

Recovery validation:
- Controlled production test member `krsticmiroslav99+m13b21144225@gmail.com` was used.
- Reset request was sent from production.
- Recovery email link opened production.
- `Set new password` appeared before normal navigation.
- Normal navigation was blocked until password update.
- Password update succeeded.
- New password login worked.
- Role/access remained unchanged.

Security notes:
- No passwords, recovery tokens, or secrets were stored in docs/source.
- No SQL, Supabase/RLS/RPC, Supabase Auth settings, Vercel env, CP, GvG, audit, role, permission, member-status, approval, or membership behavior changed.

## Milestone 17A Password Recovery Required Reset Flow

Milestone 17A local implementation passed build/source validation and limited local browser smoke.

Build:
- `npm.cmd run build` passed.

Source/security-path validation:
- No SQL migrations changed.
- No Supabase/RLS/RPC behavior changed.
- No profile approval, membership status, roster status, role/guild/permission, CP, GvG, or audit behavior changed.
- Password reset email requests use Supabase Auth through `resetPasswordForEmail`.
- Password recovery updates use Supabase Auth through `updateUser({ password })`.
- No new direct protected table paths were added.

Local browser smoke:
- Auth screen shows `Forgot password?`.
- Forgot-password mode shows `Send reset link` and neutral success behavior.
- A recovery URL marker forces the `Set new password` screen.
- Normal navigation is hidden during recovery mode.
- Sign out clears recovery mode and returns to the auth screen.
- No console warnings/errors were captured for this smoke path.

Remaining staging validation:
- Trigger a real reset email for a controlled staging account.
- Click the Supabase recovery link.
- Confirm `Set new password` is required before normal navigation.
- Validate mismatch and too-short password errors.
- Submit a valid new password.
- Confirm the new password works and the old password no longer works, if safely testable.
- Confirm pending/member/admin/suspended gates remain unchanged after reset.

## Milestone 15E Member Status Production Rollout Validation

Milestone 15E production rollout validation passed against `mzflfyxxkascrfpteexz` / `Anteiku Guild Manager Production`.

Migration:
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- The migration was applied to production.
- Production migration history showed `20260523000100` applied remotely.

Production DB verification:
- `guild_memberships.roster_status` exists with default `active` and `NOT NULL`.
- Allowed status check constraint and roster-status index exist.
- `member_status_history` exists with RLS enabled.
- No public/client write policies exist for `member_status_history`.
- `update_member_roster_status(...)` exists with authenticated execute grant.
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.

Production smoke:
- Production app loads.
- Owner can sign in.
- Owner can open AdminPanel.
- Members tab loads with roster status badges, filter, and controls.
- CP tab still loads for authorized Owner.
- Audit Logs still load for Owner.
- GvG page still loads.
- Member can sign in.
- Member cannot access AdminPanel.
- Member sees own roster status safely on Profile.
- Member sees no CP roster, leaderboard, snapshots, or other-member CP exposure.
- No captured console errors were observed.

Not performed:
- No production roster-status mutation smoke was performed.
- If mutation smoke is approved later, use the controlled production test member only and restore to `active`.

Operational note:
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink before future staging/local Supabase commands.

## Milestone 15D Member Status Staging Validation

Milestone 15D staging validation passed against `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.

Migration:
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- The migration was applied to staging only.
- Staging schema/RLS verification passed for `roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, default/backfilled memberships, and active Owner count.

Browser validation:
- `staging_owner` saw roster status badges, filter, and controls in Admin Members.
- `staging_member` transitions passed: `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, restored `active`.
- `suspended` showed restricted notice and blocked member/admin areas.
- `on_break` allowed Home/Profile and showed not expected for GvG with no vote controls.
- `staging_admin_noperms` had no Members/status/CP/Audit/GvG management controls.
- Final `staging_member` state was `membership_status = active` and `roster_status = active`.
- Status changes created 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows.

Source/security-path validation:
- Status changes use only `update_member_roster_status(...)`.
- No direct frontend `guild_memberships` writes.
- No frontend `member_status_history` calls or writes.
- No new direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- CP privacy unchanged.

Production gate:
- Production rollout passed in Milestone 15E.

## Milestone 15B Member Status Frontend Build/Source Validation

Milestone 15B frontend implementation is complete locally and browser-validated through staging in Milestone 15D.

Build:
- `npm.cmd run build` passed.

Source/security-path validation:
- `roster_status` is included in safe profile/member reads.
- Roster status writes use only `update_member_roster_status` through `adminMemberService.js`.
- No direct frontend `guild_memberships` updates were found.
- No direct frontend `member_status_history` calls/writes were found.
- No direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls were added.
- No SQL migration or Supabase validation files changed during Milestone 15B.

Browser validation:
- Staging browser validation passed in Milestone 15D after the 15A migration was applied to staging.
- Production validation passed in Milestone 15E after the production database migration was applied and verified.

Milestone 15D browser validation confirmed:
- Owner sees roster status badges, filter, and controls in Admin Members.
- Owner can set all statuses where backend allows.
- Admin without `manage_members` cannot change roster status.
- `suspended` shows restricted notice and no member/admin areas.
- `on_break` can log in/view profile but is not expected in GvG and gets no vote controls.
- Status changes produce backend audit/history through `update_member_roster_status`.
- Dashboard/Profile/GvG do not leak CP data or call CP roster/leaderboard/snapshot paths.

Not tested in 15D because no matching staging account exists:
- Admin with `manage_members` limited to non-terminal statuses.
- `left` and `kicked` browser notices; backend behavior was covered in 15A validation.

## Milestone 15A Member Status Backend Validation

Milestone 15A backend/database validation passed locally.

Commands run:
- `npx.cmd supabase db reset`
- `supabase/tests/local_validation_anteiku.sql` through local Postgres in the Supabase DB container

Milestone 15A result:
- 22 PASS
- 0 FAIL
- 0 SKIP

Validated:
- Migration applies cleanly.
- `roster_status` defaults to `active`.
- Invalid roster status values are rejected.
- Owner, Leader/Vice, Admin with `manage_members`, Admin without permission, and Member status-change rules pass.
- Admin cannot set hard-block statuses, affect Owners, or change self.
- Last active Owner protection works.
- `suspended`, `left`, and `kicked` remove active membership access.
- `inactive` and `on_break` keep active membership but are blocked from active GvG event visibility/voting.
- `trial` keeps normal GvG voting access.
- Private status history rows are inserted.
- Members cannot read private status history.
- Scoped staff can read status history.
- Status-change audit logs are written without private reason text.

Build:
- `npm.cmd run build` was not run because no frontend/source files were changed.

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
