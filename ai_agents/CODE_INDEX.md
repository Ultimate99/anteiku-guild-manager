# Code Index

## Milestone 29E.7 Audit Actor Active-Profile Alignment

- `supabase/migrations/20260531000800_active_profile_audit_actor_alignment.sql`: Redefines only `submit_gvg_vote(...)` to keep active-profile GvG vote behavior and add sanitized `gvg_vote_submitted` audit rows with selected active profile as actor/target.
- `supabase/tests/local_validation_anteiku.sql`: Extends the active-profile GvG validation block to confirm GvG vote audit actor attribution, sanitized metadata without absence reason text/CP refs, legacy Admin GvG status audit attribution unchanged, and active Owner count.
- Production status: migration `20260531000800_active_profile_audit_actor_alignment.sql` is applied, commit `c48a3e9 feat: align active profile audit actor` is pushed to `main`, local validation passed with the active-profile GvG block at `17 PASS / 0 FAIL / 0 SKIP`, production dry-run/apply/DB verification passed, and no production vote mutation smoke was performed.

## Milestone 29E.6 GvG Voting Active Profile Migration

- `supabase/migrations/20260531000700_active_profile_gvg_voting.sql`: Migrates member-facing GvG active-event visibility, own-vote lookup, and `submit_gvg_vote(...)` to `private.get_active_profile_id()`. Adds `get_my_active_gvg_events()` and `get_my_gvg_vote(p_event_id uuid)`, and updates member active-event/own-vote RLS policies.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.6 validation for active-profile GvG event scope, separate A/B vote state, Present/Absent switching on one row, pending/restricted/unlinked denial, `get_gvg_results` permission preservation, direct vote/CP table protection, and active Owner count.
- `src/services/gvgService.js`: Member-facing active event and own-vote loaders now call the active-profile GvG RPCs. Admin GvG event/results methods remain on their existing paths.
- `src/pages/Gvg.jsx`: Uses active profile readiness for member GvG gating, refetches events/current vote when the selected active profile changes, and clears stale vote/reason/message state.
- Production status: migration `20260531000700_active_profile_gvg_voting.sql` is applied, commit `a9e5c2c feat: migrate gvg voting to active profile` is pushed to `main`, local validation passed `14 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, production dry-run/apply/DB verification passed, and production GvG smoke passed for the logged-in single-profile account without vote mutation.

## Milestone 29E.5 Own CP Active Profile Migration

- `supabase/migrations/20260531000600_active_profile_own_cp.sql`: Migrates member-own CP read, CP update-window lookup, and CP self-submit to `private.get_active_profile_id()`. Replaces only `get_my_cp()`, `get_active_cp_update_window_for_me()`, and `submit_my_cp_update(p_cp_value integer)`.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.5 validation for active-profile own CP reads, update-window scope, self-submit updating only the selected profile, pending/restricted/unlinked denial, direct CP table protection, existing Admin CP behavior, and active Owner count.
- `src/pages/Profile.jsx`: Profile `Your CP` now loads when the active profile is ready, so linked accounts can use own CP for the selected active profile. Rank badge and own Ghoul Rep remain legacy-profile scoped until separately migrated.
- Production status: migration `20260531000600_active_profile_own_cp.sql` is applied, commit `9e13864 feat: migrate own cp to active profile` is pushed to `main`, local validation passed `13 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, production dry-run/apply/DB verification passed, and production Profile smoke passed for the logged-in single-profile account without CP submit mutation.

## Milestone 29E.4 Push Notifications Active Profile Migration

- `supabase/migrations/20260531000500_active_profile_push_notifications.sql`: Adds `push_subscriptions.auth_user_id`, migrates push RPCs so preferences/test notification recipients use `private.get_active_profile_id()`, keeps disable browser-auth scoped, and preference-gates supported notification types.
- `supabase/functions/send-push-notifications/index.ts`: Delivers profile-recipient outbox rows to active subscriptions owned by auth users linked to that recipient profile, while preserving fixed safe notification payloads.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.4 validation for active-profile push subscription ownership, preference isolation, selected-profile self-test enqueue, browser-auth disable behavior, inactive/unlinked denial, payload privacy, disabled preference enqueue suppression, and active Owner count.
- `src/pages/Profile.jsx`: Push Settings refresh when the selected active profile changes and labels settings as profile-scoped plus browser-subscription scoped.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add active-profile/browser Push Settings labels.
- `src/styles/app.css`: Adds compact active-profile Push Settings context styling.
- Production status: migration `20260531000500_active_profile_push_notifications.sql` is applied, Edge Function `send-push-notifications` is redeployed, commit `5a3302b feat: migrate push settings to active profile` is pushed to `main`, local validation passed `12 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, and limited production smoke confirmed app/Profile load plus deployed bundle strings.

## Milestone 29E.3 3v3 Team Finder Active Profile Migration

- `supabase/migrations/20260531000400_active_profile_three_v_three.sql`: Migrates public 3v3 RPC actor/viewer identity to `private.get_active_profile_id()`. Covers Discord username update, public 3v3 Combined CP update, team create, team/status reads, join requests, cancel, approve/decline, remove member, close/reopen, and disband.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.3 validation for active-profile 3v3 setup/team/request identity, owner-only actions, active-profile switching, inactive view-only behavior, unlinked profile denial, payload privacy, disband cleanup, and active Owner count.
- `src/pages/ThreeVThree.jsx`: Uses `useActiveProfileSummary()` and refetches 3v3 state when the selected active profile changes, clearing stale request/setup/message state. Existing 3v3 service/RPC-only paths remain unchanged.
- Production status: migration `20260531000400_active_profile_three_v_three.sql` is applied, commit `a5eb9e6 feat: migrate 3v3 to active profile` is deployed, local validation passed `17 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, and authenticated production smoke passed without 3v3 mutation.

## Milestone 29E.2 Guild Wall + Profile Reactions Active Profile Migration

- `supabase/migrations/20260531000300_active_profile_wall_reactions.sql`: Migrates Guild Wall / Global Wall and Public Profile reaction actor/viewer state to `private.get_active_profile_id()`. Covers Wall feed viewer flags, post/comment create, own delete, post/comment reactions, reaction details, moderation flags/RPCs, and Public Profile reaction add/remove/viewer state.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.2 validation for active-profile Wall post/comment/reaction identity, own delete scope, profile reaction add/remove identity, reaction detail safety, self-reaction behavior, My Org/global scope behavior, denied restricted contexts, normal CP protection, and active Owner count.
- `src/pages/GuildWall.jsx`: Uses `useActiveProfileSummary()` for safe active-profile My Org scope selection while preserving Global as null/global-only. Existing Wall service/RPC-only paths remain unchanged.
- Production status: migration `20260531000300_active_profile_wall_reactions.sql` is applied, commit `db2b9e5 feat: migrate wall reactions to active profile` is deployed, local validation passed `16 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, and production smoke passed for Wall/Profile Reaction active-profile behavior.

## Milestone 29E.1 Own Profile + Cosmetics Active Profile Migration

- `supabase/migrations/20260531000200_active_profile_profile_cosmetics.sql`: Adds active-profile-aware own Profile and Cosmetics RPCs. All identity resolution uses `private.get_active_profile_id()`, not frontend-supplied profile ids. Adds `get_my_active_profile_details`, `update_my_active_profile`, `get_my_active_cosmetics`, `equip_my_active_avatar`, and `equip_my_active_frame`.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29E.1 validation for active-profile detail payload privacy, active IGN update scope, active cosmetics payload privacy, active avatar/frame equip scope, locked manual frame denial, pending/disabled active profile denial, and active Owner count.
- `src/services/profileService.js`: Adds RPC-only `loadMyActiveProfileDetails()` and `updateMyActiveProfile(...)` plus defensive private-field deny-list mapping.
- `src/services/cosmeticsService.js`: Adds shared cosmetics RPC mapping and active-profile wrappers `loadMyActiveCosmetics()`, `equipMyActiveAvatar(...)`, and `equipMyActiveFrame(...)`.
- `src/pages/Profile.jsx`: Own Profile identity/details now render from active-profile details. Inline IGN edit uses `update_my_active_profile`. Customize uses active-profile cosmetics RPCs. CP/rank/Ghoul Rep legacy own stats are hidden behind a locked note when selected active profile differs from legacy auth profile.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add active-profile Profile/Cosmetics and CP-boundary labels.
- `src/styles/app.css`: Adds compact locked CP note styling.
- Production status: migration `20260531000200_active_profile_profile_cosmetics.sql` is applied, commit `401e67e feat: migrate profile cosmetics to active profile` is deployed, local validation passed `10 PASS / 0 FAIL / 0 SKIP`, build/source validation passed, and production smoke passed.

## Milestone 29D Active Profile Viewer State

- `src/hooks/useActiveProfileSummary.js`: Read-only active-profile display hook. Calls `get_my_active_profile()` through `accountSwitcherService`, stores active-profile summary/loading/error, and exposes `refreshActiveProfile()`. It does not replace AuthContext, use localStorage authority, direct-read account-link tables, or call CP/high-risk action RPCs.
- `src/layouts/AppShell.jsx`: Adds compact topbar `Viewing as` active-profile chip for approved signed-in users.
- `src/pages/Dashboard.jsx`: Uses active-profile summary for safe Dashboard/Home identity display where available. Shows a subtle display-only note only when the active profile differs from the legacy auth profile. Existing rank/GvG/action behavior is not migrated.
- `src/pages/Profile.jsx`: Clarifies Account Switcher active profile and reload copy. Own Profile CP/IGN/cosmetics behavior remains unchanged.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add `accountSwitcher.*` viewer-state labels.
- `src/styles/app.css`: Adds topbar active-profile chip and Dashboard active-profile viewer note styling.
- Production status: commit `14c3837 feat: add active profile viewer state` is deployed. Build/source validation and production smoke passed. High-risk action systems remain future migrations.

## Milestone 29C Account Switcher UI

- `src/services/accountSwitcherService.js`: RPC-only frontend service for `get_my_switchable_profiles`, `get_my_active_profile`, and `set_my_active_profile`. Maps safe profile/guild/cosmetic/status fields and keeps a defensive private-field deny-list. It does not direct-read account-link tables, use localStorage as authority, or call normal CP RPCs.
- `src/pages/Profile.jsx`: Adds the Profile Settings Account Switcher card above Push Notifications. Loads switchable profiles/current active profile, renders linked profile cards with avatar/frame, safe identity/status metadata, and calls `set_my_active_profile(...)` after confirmation. Reloads after a successful switch so the selected active-profile state is refreshed.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Profile Settings body copy and `accountSwitcher.*` labels.
- `src/styles/app.css`: Adds compact dark/crimson Account Switcher card/list/chip/action styling.
- Production status: commit `b8f6162 feat: add account switcher UI` is deployed. Build/source validation and production smoke passed. Existing CP/GvG/3v3/Wall/Profile Reaction/Cosmetics/Push/Admin/auth systems are not migrated to active-profile identity yet.

## Milestone 29B Account Switcher Foundation

- `supabase/migrations/20260531000100_account_switcher_foundation.sql`: Adds backend-only Account Switcher foundation. New tables are `user_profile_links` and `user_active_profiles`, with RLS enabled and direct anon/authenticated table grants revoked. Adds self-link/backfill trigger for current one-auth-user/one-profile behavior, `private.get_active_profile_id()`, switcher RPCs, and Owner-only link/unlink RPCs. Existing app systems are not switched to active-profile identity yet.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 29B validation for table existence/RLS/no direct grants, self-link/backfill, safe switchable/active profile payloads, linked/unlinked/disabled active selection, Owner-only link/unlink, active-selection clearing on unlink, only-Owner safety, direct table denial, and active Owner count.
- Production status: migration `20260531000100_account_switcher_foundation.sql` is applied to production after a clean dry-run; local Account Switcher validation passed `19 PASS / 0 FAIL / 0 SKIP`; production DB verification passed.

## Milestone 28 Push Notifications Production

- Production migration `20260530000800_push_notifications_foundation.sql` is applied.
- Production Edge Function `send-push-notifications` is deployed and active.
- Production frontend commit `c761d38 feat: add push notification settings UI` is pushed to `main`.
- Manual production push smoke passed for permission grant, subscription registration, preference save, self-test notification receipt, notification click opening the app, and disable flow available/working.
- Notification payloads remain fixed server-generated title/body/route data only and showed no CP/private/admin data in smoke.

## Milestone 28C Push Notification Frontend

- `src/services/pushNotificationService.js`: RPC-only frontend push wrapper. Handles support/permission helpers, browser PushManager subscription, push subscription registration, subscription disable, own preference load/update, and self-test enqueue. It does not use direct table access or service-role keys.
- `src/pages/Profile.jsx`: Adds Profile Settings modal with Push Notifications status, enable/disable/test controls, and preference toggles. Existing Profile CP, cosmetics, Ghoul Rep, and inline IGN behavior remain unchanged.
- `public/sw.js`: Adds `push` and `notificationclick` handlers while preserving the existing static/app-shell cache strategy. Notification clicks focus/open a safe same-origin route.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Push Notifications and Profile Settings labels.
- `src/styles/app.css`: Adds dark/crimson Profile Settings and Push Notifications modal styling.
- `.env.example`: Documents `VITE_VAPID_PUBLIC_KEY` as the only frontend VAPID value.
- Status: build/source validation passed and production smoke passed.

## Milestone 28B Push Notifications Foundation

- `supabase/migrations/20260530000800_push_notifications_foundation.sql`: Adds the push notification backend foundation: `push_subscriptions`, `push_notification_preferences`, `push_notification_outbox`, RLS/no-direct-client grants, fixed server-generated payload helpers, approved-recipient eligibility, and RPCs for own subscription registration, subscription disable, own preferences, preference update, and self-test notification enqueue.
- `supabase/functions/send-push-notifications/index.ts`: Supabase Edge Function foundation for sending queued outbox notifications with Web Push/VAPID. Requires `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` at runtime. Sends only fixed outbox title/body/type/route payloads and disables gone/invalid subscriptions.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 28B validation for table existence, RLS, no direct grants, eligible member registration, pending denial, own preferences, own disable, self-test outbox enqueue, outbox payload privacy, direct outbox write denial, and active Owner count.
- Status: local DB reset and validation passed; production migration/function/frontend rollout and manual smoke passed.

## Social Profile Surfaces Polish

- `src/pages/PublicMemberProfile.jsx`: Frontend-only presentation polish for the authenticated public profile hero. Ghoul Rep now sits in the identity area as a compact social stat chip; safe public 3v3 Combined CP remains separate and labeled.
- `src/pages/GuildWall.jsx`: Frontend-only presentation polish for Wall post/comment author rows and metadata grouping. Existing RPC-only feed/reaction/comment/moderation behavior is unchanged.
- `src/styles/app.css`: Adds tighter mobile-friendly Public Profile and Guild Wall styling for scope chips, composer, post cards, comment cards, reaction buttons/details, and Ghoul Rep chips.
- Ghoul Rep leaderboard investigation: no safe public leaderboard RPC/payload exists yet, so no leaderboard UI was added. Future leaderboard work needs an explicit backend/RPC milestone.
- Production status: commit `c92246c style: polish social profile surfaces` is deployed; production smoke passed.

## Ranking Public Profile Links

- `supabase/migrations/20260530000700_ranking_public_profile_links.sql`: Production-applied focused RPC migration adding safe `profile_slug` to `get_member_cp_rankings(p_scope)` without returning CP values or private CP metadata.
- `supabase/tests/local_validation_anteiku.sql`: Extends CP Ranking validation to assert the current user row carries the expected safe `profile_slug`.
- `src/services/cpLeaderboardService.js`: Maps `profile_slug` to `profileSlug` while keeping the private-field deny-list guard.
- `src/pages/Leaderboard.jsx`: Makes member Ranking cards/rows tappable and keyboard-accessible links to `/members/:profileSlug` through existing `onNavigate('publicProfile', ...)`.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add `leaderboard.viewProfile`.
- `src/styles/app.css`: Adds mobile/desktop-safe hover/focus affordance for linked Ranking cards.
- Production status: commit `d806974 feat: link rankings to public profiles` is deployed; production smoke passed.

## Public Member Profiles

- `supabase/migrations/20260530000600_public_member_profiles.sql`: Production-applied backend/RPC foundation for public member profiles and profile reactions.
- `src/services/publicProfileService.js`: RPC-only frontend wrapper for `get_public_member_profile`, `react_to_public_profile`, `remove_public_profile_reaction`, and `get_public_profile_reaction_details`; includes safe asset mapping and a defensive private-field key guard.
- `src/pages/PublicMemberProfile.jsx`: Authenticated public member profile page showing safe profile identity, avatar/frame, guild, safe role/status, Ghoul Rep, optional public 3v3 Combined CP, profile reactions, and reaction details.
- `src/App.jsx`: Adds internal `publicProfile` page state and `/members/:profileSlug` path handling.
- `vercel.json`: Adds SPA rewrite so `/members/:profileSlug` refresh/direct open resolves to the React app.
- `src/pages/GuildWall.jsx`: Links Wall post/comment authors and reaction detail users to public profiles when a safe slug is present.
- `src/pages/ThreeVThree.jsx`: Links 3v3 team slots and incoming request users to public profiles when a safe slug is present.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add `publicProfile.*` labels.
- `src/styles/app.css`: Adds public profile, profile reaction, reaction detail, and profile-link styles.
- Production status: commits `3f55f76 feat: add public member profiles` and `ffc36e1 fix: support public profile route refresh` are deployed; production smoke passed.

## Ghoul Rep Profile Polish

- `supabase/migrations/20260530000500_my_ghoul_rep_profile.sql`: Adds `get_my_ghoul_rep()` as a minimal own-user RPC that uses `auth.uid()`, requires an approved profile, delegates to the private Ghoul Rep helper, and returns only the caller's live Ghoul Rep number.
- `src/services/profileService.js`: Adds RPC-only `loadMyGhoulRep()` for Profile.
- `src/pages/Profile.jsx`: Loads own Ghoul Rep and renders a compact chip near rank/customize without adding public profiles or profile reactions.
- `src/styles/app.css`: Softens Wall Ghoul Rep chips and adds the shared Profile Ghoul Rep chip styling.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add `profile.ghoulRep`.
- Production status: commit `bc9e30a feat: show ghoul rep on profile` is deployed; production DB has `20260530000500_my_ghoul_rep_profile.sql` applied.

## Ghoul Rep Wall Frontend

- `src/services/guildWallService.js`: Maps `author_ghoul_rep` into author payloads and adds RPC-only `loadReactionDetails({ targetType, targetId, reactionType })` using `get_wall_reaction_details(...)`.
- `src/pages/GuildWall.jsx`: Renders compact Ghoul Rep chips for post/comment authors and adds a dark/crimson reaction details panel opened from reaction hover/focus/tap. Reaction details clear when Wall scope changes.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Wall labels for Ghoul Rep and reaction details.
- `src/styles/app.css`: Adds compact Ghoul Rep chip and mobile-safe reaction detail panel styles.
- Production status: commits `cc2a82b feat: show ghoul rep on guild wall` and `3c0ba0b fix: clear wall reaction details on scope change` are deployed.

## Ghoul Rep Wall Reaction Backend

- `supabase/migrations/20260530000400_ghoul_rep_wall_reactions.sql`: Adds live-calculated Ghoul Rep for Guild Wall and Global Wall by counting distinct non-self reactors per post/comment target, excluding deleted content and removed reactions. Replaces `get_guild_wall_feed(...)` to include `author_ghoul_rep` for post/comment authors and adds `get_wall_reaction_details(p_target_type, p_target_id, p_reaction_type)` for safe reaction-user detail UI.
- `supabase/tests/local_validation_anteiku.sql`: Extends Guild Wall validation for post reactions, comment reactions, multiple reaction types from one user counting once per target, same user across multiple targets counting separately, self-reaction exclusion, removed/deleted reaction effects, safe reaction detail payloads, wrong-guild/pending denial, no CP fields, and active Owner count.
- Production status: production DB has `20260530000400_ghoul_rep_wall_reactions.sql` applied and verified. Frontend Wall Ghoul Rep chip/reaction-detail UI and Profile own Ghoul Rep display are live.

## Global Wall Scope

- `supabase/migrations/20260530000300_global_wall_scope.sql`: Adds Global Wall scope support by allowing null `wall_posts.guild_id` / `wall_comments.guild_id`, updating wall view/action helpers, and replacing `get_guild_wall_feed` / `create_wall_post` so null scope means Global Wall rather than mixed all-guild feed.
- `supabase/tests/local_validation_anteiku.sql`: Extends Guild Wall validation for Global posts, cross-guild Global reads, Global comments/reactions, Owner-only Global moderation, nullable wall scope columns, RLS, no direct grants, and active Owner count.
- `src/services/guildWallService.js`: Maps Global Wall fields (`is_global`, author guild metadata) and keeps RPC-only Guild Wall access.
- `src/pages/GuildWall.jsx`: Adds `My Guild` / `Global` scope chips, Global post badges, scoped composer handling, and emoji reaction display while preserving backend reaction values.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Global Wall scope labels.
- `src/styles/app.css`: Adds a subtle Global post card accent.
- Production status: commit `feaf2ff feat: add global wall scope` is pushed to `main`; production DB has `20260530000300_global_wall_scope.sql` applied and verified. Controlled production mutation smoke remains pending.

## Admin Mobile Section Redesign

- `src/styles/app.css`: Adds CSS-only mobile refinements for the remaining AdminPanel sections after the initial mobile polish. Analytics scope/sub-tabs/stat cards/Weekly Growth rows, Members manage cards, editable CP cards/window controls, GvG admin cards, Audit Logs, Permissions, and Owner Tools now use tighter dark/crimson card styling closer to the approved Admin Overview / CP Ranking direction.
- Production status: commit `79b15fa style: redesign admin mobile sections` is deployed. This is frontend presentation only; no SQL, Supabase/RLS/RPC, service/data fetching, package/PWA/service-worker, permission, CP privacy, Analytics calculation, GvG, 3v3, or member-status behavior changed.

## Admin Mobile UX Polish

- `src/components/admin/AdminTabs.jsx`: Adds a mobile-friendly AdminPanel section selector while preserving the existing desktop tab bar and authorized tab list.
- `src/styles/app.css`: Adds mobile-only AdminPanel density and overflow-safety polish for Admin navigation, Overview command cards, Analytics scope/sub-tabs/stat cards/Weekly Growth rows, Members, CP, GvG, Audit Logs, Permissions, Owner Tools, and bottom-nav clearance.
- Production status: commit `0dc9eb5 style: polish admin mobile experience` is deployed. This is frontend presentation only; no SQL, Supabase/RLS/RPC, service/data fetching, package/PWA/service-worker, permission, CP privacy, Analytics calculation, GvG, 3v3, or member-status behavior changed.

## Offline Notice Banner

- `src/App.jsx`: Contains the global `OfflineNotice` UI and online/offline browser-event state handling.
- `src/styles/app.css`: Adds the dark/crimson offline notice banner styles and mobile-safe positioning above bottom navigation.
- Production status: commit `2bbd24a feat: add offline notice banner` is deployed. The feature is UI-only, does not change service worker/cache behavior, and does not cache Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data.

## PWA Update Available Banner

- `public/sw.js`: Supports `{ type: "SKIP_WAITING" }`, calls `self.skipWaiting()` only after that message, and uses cache name `anteiku-static-v2`. It no longer auto-skips waiting during install.
- `src/registerServiceWorker.js`: Detects waiting service workers, renders the non-blocking update banner, handles `Update App` / `Later`, reloads only after `controllerchange`, and is guarded to production builds.
- `src/styles/app.css`: Adds dark/crimson fixed update-banner styling and mobile stacking.
- Production status: commit `bb570a6 feat: add PWA update available banner` is deployed. Production app and `/sw.js` are served; manual browser update-cycle verification remains pending.

## Milestone 26A/26B PWA Install Support

- `index.html`: Adds manifest link, theme color, favicon, Apple mobile metadata, and Apple touch icon.
- `public/manifest.webmanifest`: Web app manifest for installability with `Anteiku Guild Manager` / `Anteiku`, standalone display, root start/scope, dark/crimson theme colors, portrait-primary orientation, and PNG icons.
- `public/icons/icon-192.png`, `public/icons/icon-512.png`, `public/icons/maskable-512.png`, `public/icons/apple-touch-icon.png`, `public/icons/favicon-32.png`: App icons generated from the existing approved `public/anteiku-mark.svg` project mark.
- `public/sw.js`: Conservative same-origin service worker. It caches app shell/static build assets/icons/manifest/approved mark only and ignores cross-origin requests, including Supabase Auth/RPC/API.
- `src/registerServiceWorker.js`: Production-only service worker registration helper.
- `src/main.jsx`: Calls the registration helper after app render.
- Status: commit `1d8b5a5 feat: add PWA install support` is pushed to `main`; production serves the manifest, service worker, icons, and registration bundle.

## Milestone 25D 3v3 Production Status

- `supabase/migrations/20260528000100_three_v_three_team_finder.sql`: Applied and verified in production. Adds the 3v3 Team Finder backend/RLS/RPC foundation.
- `src/services/threeVThreeService.js`: Production RPC-only frontend wrapper for 3v3 functions. Source validation found no direct table access, no normal CP RPC usage, no `member_cp`, and no `cp_snapshots`.
- `src/pages/ThreeVThree.jsx`: Production member-facing 3v3 page with Find Team, Create Team, and My Requests sub-tabs.
- `src/App.jsx` and `src/data/navigation.js`: Production navigation wiring for approved-member `3v3`.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Production 3v3 navigation and page labels.
- `src/styles/app.css`: Production mobile-first 3v3 card/slot/request styles.
- Production status: migration applied, frontend deployed at commit `4c9da98`, controlled production smoke passed for create/request/approve/slot-fill, and normal protected CP remained hidden.
- Cleanup note: manual smoke did not specify whether the controlled test team was left live or disbanded.

## Milestone 25C 3v3 Frontend UI

- `src/services/threeVThreeService.js`: RPC-only frontend wrapper for the 25B 3v3 functions. Normalizes team/status/request payloads, safe avatar/frame paths, public 3v3 Combined CP values, Discord display, and combined CP input formatting. Does not direct-read or direct-write 3v3 tables and does not call normal CP services.
- `src/pages/ThreeVThree.jsx`: Member-facing 3v3 page with Find Team, Create Team, and My Requests sub-tabs; renders team cards, three-slot layouts, request forms, player setup forms, incoming/outgoing request queues, and owner actions.
- `src/App.jsx`: Wires `threeVThree` page id to `ThreeVThree`.
- `src/data/navigation.js`: Adds the approved member nav item for `3v3`.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Adds `nav.threeVThree`, `app.eyebrow.teams`, and `threeVThree.*` labels.
- `src/styles/app.css`: Adds mobile-first 3v3 page, tab, team-card, slot, plus-slot, request-card, and owner-action styles.
- Status: local frontend build/source validation passed, then production deployed and controlled-smoke validated in Milestone 25D.

## Milestone 25B 3v3 Team Finder Backend

- `supabase/migrations/20260528000100_three_v_three_team_finder.sql`: Adds the local-only 3v3 Team Finder backend/RLS/RPC foundation. Defines `three_v_three_player_profiles`, `three_v_three_teams`, `three_v_three_team_members`, `three_v_three_join_requests`, RLS/no-direct-client-grant posture, eligibility helpers, request spam/cooldown enforcement, team owner actions, and RPC-only 3v3 flows.
- `supabase/tests/local_validation_anteiku.sql`: Adds Milestone 25B local validation covering schema/RLS, approved/pending/inactive/on_break eligibility, Discord/Combined CP requirements, team create/status rules, request spam/cooldown limits, approve/decline/cancel/remove/disband flows, direct table denial, normal CP non-exposure, and active Owner count.
- Status: local backend validation passed with 45 PASS / 0 FAIL / 0 SKIP. Production has the 25B migration applied and verified through Milestone 25D.

## Analytics UI Polish

- `src/components/admin/AdminAnalyticsSection.jsx`: Frontend-only Analytics UI polish. Adds grouped member stat sections, tighter stat-card variants, visual Weekly Growth row states, and labeled mobile row cells while preserving existing analytics loading, scope, baseline, and RPC behavior.
- `src/styles/app.css`: Adds compact Analytics scope/sub-tab/card/group/table styles, flat crimson active states, mobile scroll-safe scope/tabs, and mobile labeled Weekly Growth cards.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Members grouping labels for Analytics.
- Production status: Commit `1db36d3 style: polish admin analytics UI` is deployed. No SQL, Supabase/RLS/RPC, analytics service, or security behavior changed.

## Weekly Growth Baseline Scope Fix

- `supabase/migrations/20260526000300_live_cp_growth_baseline_scope.sql`: Applied and verified in production. Adds `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)` so an Owner-selected Global baseline can be reused while filtering rows to a selected guild scope.
- `src/services/adminAnalyticsService.js`: `loadLiveCpGrowth(...)` accepts `baselineBatchId` and passes it to the RPC.
- `src/components/admin/AdminAnalyticsSection.jsx`: Preserves the selected baseline id across Analytics scope changes and refreshes live growth against that baseline when applicable.
- `supabase/tests/local_validation_anteiku.sql`: Adds validation for Global baseline reuse under guild scope, explicit baseline preservation after a later guild baseline, scoped admin denial for Global baseline reuse, and same-guild baseline access for scoped CP staff.

## Live CP Growth Production Status

- `supabase/migrations/20260526000200_live_cp_growth.sql`: Applied and verified in production. Adds `start_new_cp_growth_period(...)`, `get_admin_live_cp_growth(...)`, and compatibility delegation for `capture_weekly_cp_snapshot(...)`.
- `src/services/adminAnalyticsService.js`: Adds RPC-only wrappers for `get_admin_live_cp_growth` and `start_new_cp_growth_period`.
- `src/components/admin/AdminAnalyticsSection.jsx`: Weekly Growth now renders live current-minus-baseline growth, Reset day Sunday, baseline metadata, selected scope, and a guarded Start New CP Week confirmation.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`: Add Live CP Growth labels.
- `src/styles/app.css`: Adds compact Live CP Growth summary and confirmation styles.
- `supabase/tests/local_validation_anteiku.sql`: Adds Live CP Growth validation coverage for permission denial, no-baseline state, Sunday baseline creation, live growth calculation, and Owner global safe state.

## Milestone 24E Admin Analytics Production Status

- `src/pages/AdminPanel.jsx`: Production AdminPanel exposes the Analytics tab for staff through existing AdminPanel access/permission gates.
- `src/components/admin/AdminAnalyticsSection.jsx`: Production Analytics UI for Overview, Members, CP, GvG, Weekly Growth, and Attention. Weekly Growth now uses live current-minus-baseline growth; production Start New CP Week requires explicit approval before use.
- `src/services/adminAnalyticsService.js`: Production RPC-only Analytics service. Uses only Analytics RPCs for member analytics, CP analytics, GvG analytics, live CP growth, snapshot compatibility, and start-week baseline capture.
- `supabase/migrations/20260526000100_admin_analytics_foundation.sql`: Applied and verified in production. Adds `cp_snapshot_batches`, `cp_snapshot_entries`, and the Analytics/Weekly Growth RPC foundation.

- `src/main.jsx`: React root.
- `src/App.jsx`: Local page state, auth/approval gates, password recovery gate, and roster hard-block gate routing.
- `src/layouts/AppShell.jsx`: Header, content frame, sign-out action, and bottom navigation container.
- `src/components/AppNav.jsx`: Mobile-first page navigation.
- `src/components/StatusBadge.jsx`: Small status label component.
- `src/components/RankBadge.jsx`: Member-safe rank badge component for Profile/Dashboard visuals using safe rank summary fields only.
- `src/components/CosmeticPreview.jsx`: Member avatar/frame preview component using approved static cosmetics asset paths.
- `src/config/supabaseClient.js`: Supabase env check and client placeholder.
- `src/context/AuthContext.jsx`: Local Supabase auth/session provider, password recovery state, and safe viewer state.
- `src/context/LanguageContext.jsx`: Frontend-only language provider, `useLanguage()` hook, `t(key, params?)`, and `agm_language` persistence.
- `src/hooks/useAuth.js`: Hook for reading auth context.
- `src/i18n/index.js`: Lightweight i18n registry, language options, fallback translation lookup, and interpolation helper.
- `src/i18n/en.js`: English UI translation dictionary.
- `src/i18n/fr.js`: French UI translation dictionary.
- `src/i18n/de.js`: German UI translation dictionary.
- `scripts/sync-cosmetics-catalog.mjs`: Local developer script that scans repo-backed cosmetics assets and generates timestamped `cosmetic_catalog` upsert migrations without running Supabase commands.
- `src/services/authService.js`: Supabase auth wrappers for session, signin, signup, password reset/update, and signout.
- `src/services/profileService.js`: Safe own profile/membership/guild loading including `roster_status`, registration RPC call, and own IGN update RPC wrapper.
- `src/services/guildService.js`: Safe core guild loading for registration.
- `src/services/adminApprovalService.js`: RLS-safe approval queue reads, own approval permission lookup, and approval/rejection RPC wrappers.
- `src/services/adminMemberService.js`: RLS-safe approved primary member roster reads, member-management permission helpers, roster status helpers, roster status RPC wrapper, and admin member IGN/slug/role/guild RPC wrappers.
- `src/services/cpWindowService.js`: RPC-only CP Update Window service for own CP, member self-submit, selected-guild staff window status, and staff window open/close.
- `src/services/cpRankBadgeService.js`: RPC-only own CP rank summary wrapper for `get_my_cp_rank_summary`.
- `src/services/cosmeticsService.js`: RPC-only cosmetics wrapper for `get_my_cosmetics`, `equip_my_avatar`, `equip_my_frame`, active grantable cosmetic option loading, and Owner grant-by-slug through `admin_grant_cosmetic_by_slug`; normalizes asset paths to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- `src/services/adminAnalyticsService.js`: RPC-only Admin Analytics service for member analytics, CP analytics, GvG analytics, manual Weekly Growth snapshot capture, snapshot history, and growth report reads.
- `src/data/guilds.js`: Core guild list.
- `src/data/navigation.js`: Navigation items.
- `src/pages/LoginRegister.jsx`: Local Supabase signin/signup, forgot-password, and registration UI.
- `src/pages/SetNewPassword.jsx`: Required password recovery screen shown before normal navigation during recovery sessions.
- `src/pages/PendingApproval.jsx`: Pending approval gate with manual refresh.
- `src/pages/RejectedStatus.jsx`: Rejected account gate; reapply is planned later.
- `src/pages/SuspendedStatus.jsx`: Suspended account gate.
- `src/pages/RosterRestrictedStatus.jsx`: Roster lifecycle hard-block gate for suspended/left/kicked members.
- `src/pages/Dashboard.jsx`: Approved-user safe guild dashboard with roster status display, compact own rank badge, and no CP values.
- `src/pages/Profile.jsx`: Safe polished own-profile display with identity header, own roster status, rank badge/profile border from safe own-rank RPC, own cosmetics picker through safe cosmetics RPCs, and a unified compact Member Profile card containing private own CP through safe RPCs only, inline own IGN row editing, and compact account/details rows for approved users.
- `src/pages/Gvg.jsx`: GvG voting UI with roster-status UX gating for inactive/on_break and hard-blocked statuses.
- `src/pages/AdminPanel.jsx`: Restricted AdminPanel coordinator for admin permission loading, visible tab calculation, active tab state, lazy section loading, Analytics tab wiring, and section action handlers.
- `src/components/admin/AdminTabs.jsx`: Mobile-first AdminPanel tab bar.
- `src/components/admin/AdminApprovalsSection.jsx`: Registration approval/rejection queue section.
- `src/components/admin/AdminMembersSection.jsx`: Approved primary member management section with compact roster rows, roster status badges/filter, and expandable Manage controls for status/IGN/username/role/guild actions.
- `src/components/admin/AdminCpSection.jsx`: Admin-only CP roster/update/leaderboard section plus CP Update Window controls.
- `src/components/admin/AdminGvgSection.jsx`: GvG event management/results section.
- `src/components/admin/AdminAuditSection.jsx`: Read-only audit log viewer section.
- `src/components/admin/AdminPermissionsSection.jsx`: Admin permission checkbox management section.
- `src/components/admin/AdminToolsSection.jsx`: Planned/future admin tools section plus Owner-only cosmetics grant UI.
- `src/components/admin/AdminAnalyticsSection.jsx`: AdminPanel Analytics UI section with Overview, Members, CP, GvG, Weekly Growth, and Attention sub-tabs backed only by the 24B analytics RPCs.
- `src/styles/app.css`: Plain mobile-first dark styling.

## Milestone 24C Admin Analytics UI

- `src/services/adminAnalyticsService.js`
  - Calls only the Milestone 24B analytics RPCs.
  - Does not direct-read `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, or `gvg_votes`.
  - Provides wrappers for member analytics, CP analytics, GvG analytics, snapshot capture, snapshot history, and CP growth reports.
- `src/components/admin/AdminAnalyticsSection.jsx`
  - Renders AdminPanel Analytics sub-tabs: Overview, Members, CP, GvG, Weekly Growth, and Attention.
  - Displays compact stat cards, locked/permission states, snapshot controls, and growth report rows.
  - Depends on backend/RPC permission enforcement for CP Analytics and Weekly Growth.
- `src/pages/AdminPanel.jsx`
  - Adds the `Analytics` tab and lazy-renders `AdminAnalyticsSection` only when active.
  - Passes current membership, permission hints, formatting helpers, and refresh signal to the analytics section.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add `admin.analytics.*` labels.
- `src/styles/app.css`
  - Adds compact Analytics sub-tabs, stat cards, locked panels, action rows, and mobile growth-table styles.

## Milestone 24B Admin Analytics Backend

- `supabase/migrations/20260526000100_admin_analytics_foundation.sql`
  - Adds `cp_snapshot_batches` and `cp_snapshot_entries`.
  - Adds RPC-only Admin Analytics functions for member, CP, GvG, manual snapshot capture, snapshot history, and CP growth reports.
  - Enforces backend permission gates for staff access, scoped `view_cp`, wrong-guild denial, and member/pending denial.
  - Keeps existing legacy `cp_snapshots` and older CP snapshot/growth RPCs intact.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 24B local validation for schema/RLS, permission denials, CP privacy, snapshot capture, growth calculation, GvG analytics gates, direct table denial, and active Owner count.

## Milestone 22F Cosmetics Catalog Sync Script

- `scripts/sync-cosmetics-catalog.mjs`
  - Scans `public/cosmetics/avatars/` and `public/cosmetics/frames/`.
  - Accepts `.png` and `.webp`; ignores hidden files, directories, and unsupported extensions.
  - Generates cosmetic keys from filenames without extensions.
  - Generates repo-backed asset paths and label keys.
  - Defaults `_FREE` keys to `unlock_type = 'free'`.
  - Keeps `premium` avatar keys manual and other v1 avatars free.
  - Defaults only `TXK_Arena*` and `TXK_KOF*` frames to manual; all other frames default to free.
  - Emits deterministic sort orders in increments of `10`.
  - Supports `--dry-run` for SQL preview without writing.
  - Writes timestamped `supabase/migrations/*_cosmetics_catalog_sync.sql` files but does not apply them.
- `package.json`
  - Adds `cosmetics:sync`.
- `supabase/migrations/20260525193210_cosmetics_catalog_sync.sql`
  - Generated locally during validation; not applied to staging or production.
  - Upserts 54 avatar rows and 10 frame rows into `public.cosmetic_catalog`.
  - Does not delete or deactivate missing catalog rows.

## Cosmetics Frame Unlock Hotfix

- `supabase/migrations/20260525220522_cosmetics_frame_unlock_hotfix.sql`
  - Updates only `public.cosmetic_catalog.unlock_type` for frame rows.
  - Sets `TXK_Arena*` and `TXK_KOF*` frames to `manual`.
  - Sets all other frame rows to `free`.
  - Does not delete catalog rows or mutate profile equipment.
- Production status:
  - Applied to production project `mzflfyxxkascrfpteexz`.
  - Read-only verification confirmed 7 Arena manual frames, 3 KOF manual frames, 10 other free frames, and 0 other locked frames.

## Owner Cosmetics Grant Tool

- `src/components/admin/AdminToolsSection.jsx`
  - Renders Owner Cosmetics only for `membership.role === 'owner'`.
  - Uses username/profile slug copy and warns not to use IGN.
  - Loads dropdown options through the existing cosmetics service RPC path.
  - Submits grants through `grantCosmeticBySlug(...)`.
- `src/services/cosmeticsService.js`
  - `loadGrantableCosmetics()` flattens active avatar/frame catalog data returned by `get_my_cosmetics()`.
  - `grantCosmeticBySlug(...)` calls only `admin_grant_cosmetic_by_slug`.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add `ownerCosmetics.*` labels.
- `src/styles/app.css`
  - Adds compact Owner Cosmetics Tools panel/form styles.
- Production validation:
  - Owner Cosmetics is live under AdminPanel -> Tools for Owner only.
  - Controlled locked avatar/frame grant by exact profile slug / username passed, and the granted member could equip afterward.
  - Frontend grants use only the RPC wrapper; no direct cosmetic table writes, uploads, Storage, or arbitrary URLs are part of the flow.

## Milestone 22E Cosmetics Production Rollout

Production status:
- Cosmetics backend/assets/frontend are live in production.
- Production migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Production catalog verification passed: 54 avatars, 10 frames, and 64 exact repo asset-path matches.
- Vercel serves the cosmetics picker and static assets.
- Owner equip persistence was verified in production.

Security:
- Frontend cosmetics paths use only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No frontend admin grant UI exists.
- No direct cosmetics table writes, arbitrary URLs, Supabase Storage, or upload paths are part of v1.
- Free frames can be equipped by players; manual frames require backend unlock state.

## Milestone 23B Premium Cosmetics Backend

Status:
- Backend/database-only implementation complete; staging validated in Milestone 23C and production applied/verified in Milestone 23D.
- New migration `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`.
- Existing deployed migration `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql` was not edited.

- `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`
  - Updates the current 10 frame keys to `unlock_type = 'free'`.
  - Updates `get_my_cosmetics()` so avatar rows include unlock type, unlock state, and equipped state.
  - Updates `equip_my_avatar(text)` to require free-or-unlocked avatar semantics.
  - Updates `update_my_profile(text, text)` so manual avatar keys require an unlock row.
  - Adds `admin_grant_cosmetic_by_slug(text, text, text)` for exact username/profile-slug grants.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 23B coverage for free current frames, premium manual avatar/frame denial, grant-by-slug, unlocked equip, update-profile hardening, invalid input denial, member/admin denial, and audit rows.

## Milestone 22C Frontend Cosmetics Picker

Status:
- Implemented, staging-validated, polished, and deployed through Milestone 22E.

- `src/services/cosmeticsService.js`
  - Calls only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
  - Does not direct-read `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics`.
  - Does not expose `admin_grant_cosmetic`.
  - Filters rendered asset paths to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- `src/components/CosmeticPreview.jsx`
  - Renders equipped avatar and optional frame as static app assets.
- `src/pages/Profile.jsx`
  - Adds member-facing avatar and frame picker.
  - Shows equipped/unlocked/locked states.
  - Disables locked frames.
  - Refreshes profile state after avatar equip for `profiles.avatar_key` compatibility.
- `src/styles/app.css`
  - Adds mobile-first cosmetics picker and preview styles.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add Profile cosmetics labels.

## Milestone 22B Cosmetics Backend

Status:
- Implemented, locally validated, applied to staging in Milestone 22D, and applied to production in Milestone 22E.

- `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`
  - Adds `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
  - Seeds 54 actual avatar asset rows and 10 actual frame asset rows from `public/cosmetics/`.
  - Uses `1079_head` as the default avatar and `TXK_frame_reOpen_EN_FREE` as the default frame.
  - Maps non-`_FREE` frames to `unlock_type = 'manual'`.
  - Enforces the `_FREE` naming convention by requiring `_FREE` catalog keys to use `unlock_type = 'free'`; runtime equip checks still use catalog `unlock_type` as source of truth.
  - Adds RLS policies for active catalog reads and caller-owned unlock/equipped reads.
  - Revokes direct client writes to cosmetics tables.
  - Adds RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
  - Hardens `update_my_profile(p_ign, p_avatar_key)` so non-empty avatar keys must match active catalog avatars.
  - Writes cosmetic audit actions: `cosmetic_avatar_equipped`, `cosmetic_frame_equipped`, and `cosmetic_granted`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 22B validation for seeded catalog, RLS, safe member reads, valid/invalid equips, locked-frame grant/equip flow, self-grant denial, no target profile equip argument, legacy avatar hardening, direct-write denial, other-user unlock privacy, and audit rows.

## Milestone 21B Rank Badge Summary Backend

Production status:
- Applied and verified in staging through Milestone 21D and production through Milestone 21E.
- Production migration: `20260524000400_cp_rank_badge_summary.sql`.
- Production smoke confirmed Profile/Dashboard rank badge visuals and no CP value exposure from the badge.

- `supabase/migrations/20260524000400_cp_rank_badge_summary.sql`
  - Adds member-safe own-rank summary RPC `get_my_cp_rank_summary()`.
  - Returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
  - Uses `auth.uid()` and accepts no target profile id parameter.
  - Does not return CP values, timestamps, growth/history/snapshot data, usernames, profile ids, other-member data, or private metadata.
  - Uses the same eligible row set as member-safe CP rankings and returns `unranked` for excluded active statuses such as `inactive` and `on_break`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 21B validation for rank tiers, unranked/no-CP behavior, inactive exclusion, hard-block denial, private-field absence, no other-user parameter, and direct CP table denial.

## Milestone 21C Profile/Dashboard Rank Badge Frontend

Production status:
- Deployed to production through Milestone 21E with commit `e99bec0 feat: add rank badge UI`.
- Production controlled Member smoke confirmed Dashboard/Profile safe no-rank/default badge state, no Admin navigation, and EN/FR/DE rank badge labels.
- Production Owner smoke confirmed Dashboard badge, AdminPanel access, existing CP tab, and CP Ranking tab.

- `src/services/cpRankBadgeService.js`
  - Adds `loadMyCpRankSummary()` for `get_my_cp_rank_summary`.
  - Guards against unexpected CP/private fields in the rank summary response.
  - Does not call member/admin leaderboard RPCs, CP roster/leaderboard RPCs, or direct CP tables.
- `src/components/RankBadge.jsx`
  - Renders stable rank tier/visual keys as translated badge text and serious compact markers.
  - Shows global rank when ranked, or a no-rank/load-error state without CP values.
- `src/pages/Profile.jsx`
  - Adds rank-based profile border and badge to the profile header.
- `src/pages/Dashboard.jsx`
  - Adds compact rank badge to the member summary.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add `rankBadge` labels.
- `src/styles/app.css`
  - Adds rank badge, dashboard badge, and profile-border visual variants for all 21B visual keys.

## Milestone 20B CP Leaderboard Backend

Production status:
- Applied and verified in staging through Milestone 20E and production through Milestone 20F.
- Production migration: `20260524000300_cp_rankings.sql`.
- Production smoke confirmed member rank-only leaderboard and Owner-only/global admin CP values through the permission-checked RPC.

- `supabase/migrations/20260524000300_cp_rankings.sql`
  - Adds member-safe CP ranking RPC `get_member_cp_rankings(p_scope text default 'guild')`.
  - Adds admin CP ranking RPC `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
  - Adds ranking support indexes on `member_cp`.
  - Member RPC returns rank order only and intentionally omits CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, and audit metadata.
  - Admin guild RPC path requires scoped `view_cp`; admin global scope is Owner-only in v1.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 20B validation for member-safe response shape, rank ordering, roster inclusion/exclusion, current-user highlighting, admin permission checks, Owner-only global admin rankings, and direct CP table denial.

## Milestone 20C Member CP Leaderboard Frontend

Production status:
- Deployed to production through Milestone 20F with commit `7ccf8c9 feat: add CP ranking UI`.
- Production Member smoke confirmed My Guild and Global rankings show rank + IGN only, with guild labels on Global and no CP/private fields.

- `src/services/cpLeaderboardService.js`
  - Adds `loadMemberCpRankings(scope)` for the member-safe `get_member_cp_rankings` RPC.
  - Normalizes scope to `guild` or `global`.
  - Guards against unexpected CP/private fields in member ranking responses.
  - Does not call admin CP ranking, CP roster, CP leaderboard, or direct CP tables.
- `src/pages/Leaderboard.jsx`
  - Adds member-facing CP Ranking page with My Guild and Global tabs.
  - Shows rank, approved avatar/frame display, IGN, optional guild label on Global, current-user highlight, and the production-polished Top 3 podium.
  - Podium presentation is frontend-only: desktop visually orders `#2 | #1 | #3`; mobile stacks `#1`, `#2`, `#3`.
  - Does not render CP values, CP history, growth, snapshots, profile ids, usernames, timestamps, or private metadata.
- `src/data/navigation.js` and `src/App.jsx`
  - Add the member Leaderboard/Ranking navigation item and route.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add member leaderboard labels.
- `src/styles/app.css`
  - Adds compact leaderboard tabs, rows, rank markers, current-user highlight, and top-rank/Elite 5/Top 10 decoration.

## Milestone 20D AdminPanel CP Leaderboard Upgrade

Production status:
- Deployed to production through Milestone 20F with commit `7ccf8c9 feat: add CP ranking UI`.
- Production Owner smoke confirmed the separate AdminPanel `CP Ranking` tab loads Guild and Global rankings with CP values while the existing `CP` tab still renders roster/window controls.

- `src/services/adminCpService.js`
  - Adds normalized `loadAdminCpRankings({ guildId, scope })` mapping for `get_admin_cp_rankings`.
  - Keeps existing CP roster and manual CP update wrappers unchanged.
- `src/pages/AdminPanel.jsx`
  - Loads AdminPanel CP leaderboard data through `get_admin_cp_rankings`.
  - Tracks Guild/Global leaderboard scope and clean leaderboard errors.
  - Keeps Global admin leaderboard frontend visibility Owner-only; backend RPC authorization remains authoritative.
- `src/components/admin/AdminCpLeaderboardSection.jsx`
  - Renders the separate AdminPanel `CP Ranking` tab content.
  - Shows Guild / Global tabs, compact decorated admin ranking rows, avatar/frame display, and the production-polished Top 3 podium with CP values for authorized staff only.
- `src/components/admin/AdminCpSection.jsx`
  - Preserves CP roster, manual CP update, and CP Update Window controls.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add admin CP leaderboard scope, rank, guild, last-updated, empty, and permission/error labels.
- `src/styles/app.css`
  - Adds compact AdminPanel CP ranking layout and mobile wrapping.

## Milestone 18B Language Pack Foundation

- `src/context/LanguageContext.jsx`
  - Adds `LanguageProvider`, `useLanguage()`, and persisted EN/FR/DE language selection.
  - Uses localStorage key `agm_language`; no database storage.
- `src/i18n/*.js`
  - Adds English, French, and German dictionaries for common/auth/nav/status/member-facing surfaces.
  - Keeps guild names, usernames, IGN, database keys, raw audit metadata, and user-generated text out of translation scope.
- `src/layouts/AppShell.jsx`
  - Adds compact topbar language selector visible before and after sign-in.
- `src/App.jsx`, `src/data/navigation.js`
  - Wire translated shell/page/nav labels without changing routing or access gates.
- `src/pages/LoginRegister.jsx`, `src/pages/SetNewPassword.jsx`, `src/pages/PendingApproval.jsx`, `src/pages/RejectedStatus.jsx`, `src/pages/SuspendedStatus.jsx`, `src/pages/RosterRestrictedStatus.jsx`
  - Translate core auth/recovery/status gate copy.
- `src/pages/Dashboard.jsx`, `src/pages/Profile.jsx`, `src/pages/Gvg.jsx`
  - Translate member-facing status labels and core GvG voting copy included in 18B scope.
- `src/pages/AdminPanel.jsx`
  - Translates basic Admin tab labels only; full AdminPanel section translation remains future work.

## Milestone 16F Member-Facing UI Compact Pass

Production status:
- Browser-validated in staging through Milestone 16G and deployed to production through Milestone 16H.
- Production commit: `53c7907 style: clean up member-facing UI`.
- Production smoke passed for compact auth, Dashboard, Profile, GvG, EN/FR/DE layout, member AdminPanel denial, and CP non-leakage.

- `src/pages/LoginRegister.jsx`
  - Uses compact auth panel/form classes while preserving sign-in, registration, forgot-password, and approval-request behavior.
- `src/pages/SetNewPassword.jsx`
  - Uses compact recovery panel/form classes while preserving the recovery gate and password update behavior.
- `src/pages/PendingApproval.jsx`, `src/pages/RejectedStatus.jsx`, `src/pages/SuspendedStatus.jsx`, `src/pages/RosterRestrictedStatus.jsx`
  - Use compact gate panel styling while preserving lockout/sign-out behavior.
- `src/pages/Dashboard.jsx`
  - Shows compact member home summary focused on guild, role, roster status, GvG state, and current member identity.
- `src/pages/Profile.jsx`
  - Uses compact profile/detail panels while preserving own-IGN editing and safe profile display.
- `src/pages/Gvg.jsx`
  - Uses compact GvG hero/empty/vote panels while preserving event loading, eligibility, vote submission, and absence-reason behavior.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Shorten member-facing Dashboard/Profile/GvG/gate copy in all supported languages.
- `src/styles/app.css`
  - Adds compact member-facing panel, metric, profile, detail, recovery, and GvG vote styles.

## Milestone 19C CP Update Window Frontend

Production status:
- Browser-validated in staging through Milestone 19D and deployed to production through Milestone 19E.
- Production commit: `6a3a181 feat: add CP update window self-submit`.
- Production smoke passed for Owner AdminPanel CP tab/window status and Member Profile `Your CP` closed-window state.
- Controlled production CP mutation smoke was not performed by design.

- `src/services/cpWindowService.js`
  - Adds RPC-only wrappers for `get_my_cp`, `get_active_cp_update_window_for_me`, `submit_my_cp_update`, `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.
  - Does not query `member_cp`, `cp_snapshots`, or `cp_update_windows` directly.
  - Does not call admin CP roster or leaderboard RPCs.
- `src/pages/Profile.jsx`
  - Adds compact `Your CP` panel.
  - Loads only the signed-in member's own CP and own active CP Update Window status.
  - Submits own CP only through `submit_my_cp_update(...)`.
- `src/pages/AdminPanel.jsx`
  - Coordinates selected-guild CP Update Window state, note draft, open action, close action, and refresh after CP window changes.
  - Keeps existing CP roster, leaderboard, and admin CP update behavior in place.
- `src/components/admin/AdminCpSection.jsx`
  - Adds compact CP Update Window status/open/close controls above the existing CP roster/leaderboard UI.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Adds Profile CP, Admin CP window, and new audit/window display labels.
- `src/styles/app.css`
  - Adds compact Profile CP panel and Admin CP window block styling.

## Documentation

- `README.md`: Current project overview, milestone status, setup/deployment links, and security summary.
- `.env.example`: Browser-safe Vite Supabase env variable template only.
- `docs/SETUP.md`: Local development setup and local-only Supabase validation warnings.
- `docs/DEPLOYMENT.md`: Future production Supabase + Vercel deployment runbook.
- `docs/PRODUCTION_CHECKLIST.md`: Future production launch checklist and safety gates.
- `docs/TESTING.md`: Validation history plus production validation guidance.
- `docs/CHANGELOG.md`: Human-readable milestone changelog.
## Milestone 7 Frontend Member Role/Guild Management

- `src/services/adminMemberService.js`
  - Adds safe active guild option reads.
  - Adds RPC wrappers for `assign_member_role` and `transfer_member_guild`.
  - Adds role/transfer permission helpers for frontend UX gating.
- `src/pages/AdminPanel.jsx`
  - Adds role-change controls to active approved member cards.
  - Adds Owner-only guild transfer controls with confirmation warning.
  - Uses RPC-only writes and refreshes roster after success.
- `src/styles/app.css`
  - Adds mobile-first styling for member role/guild action blocks and warnings.
## Milestone 8 Frontend CP Management

- `src/services/adminCpService.js`
  - Isolated CP service.
  - Provides CP permission helpers.
  - Uses only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
  - Does not query protected CP tables directly.
- `src/pages/AdminPanel.jsx`
  - Adds Admin-only CP Management section.
  - Loads CP only after frontend CP view gating passes.
  - Keeps CP roster, leaderboard, and CP drafts local to AdminPanel.
  - Shows update controls only for CP updaters.
- `src/styles/app.css`
  - Adds mobile-first CP roster and leaderboard styling.
## Milestone 9 Admin Permission Management

- `src/services/adminPermissionService.js`
  - Loads permission catalog.
  - Loads active approved Admin permission targets.
  - Loads current Admin permission keys.
  - Saves changes through `grant_admin_permission` and `revoke_admin_permission`.
  - Provides Owner/Leader/Vice permission-toggle helpers.
- `src/pages/AdminPanel.jsx`
  - Adds Permission Management section.
  - Shows checkbox controls for active Admin memberships only.
  - Disables CP permissions for Leader/Vice with Owner-only messaging.
- `src/styles/app.css`
  - Adds mobile-first permission-card and checkbox styling.
## Milestone 10 GvG Management And Voting

- `src/services/gvgService.js`
  - Isolated GvG service.
  - Loads active member events through RLS-safe `gvg_events` reads.
  - Loads own vote through RLS-safe `gvg_votes` read filtered to the current profile.
  - Uses `submit_gvg_vote`, `create_gvg_event`, `set_gvg_event_status`, and `get_gvg_results`.
- `src/pages/Gvg.jsx`
  - Member-facing active event voting UI.
  - Supports Present/Absent vote switching through RPC upsert.
  - Shows only the current member's own vote/reason.
- `src/pages/AdminPanel.jsx`
  - Adds GvG management/results section.
  - Authorized staff can create/open/close events and view present/absent results with reasons.
- `src/styles/app.css`
  - Adds GvG management, summary, results, and active vote styles.
## Milestone 11A Audit Log Read Hardening

- `supabase/migrations/20260515000300_audit_log_read_hardening.sql`
  - Adds `public.get_audit_logs(...)`.
  - Restricts direct non-Owner `audit_logs` SELECT.
  - Redacts CP-sensitive audit metadata unless the viewer has scoped `view_cp`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 11A validation for audit visibility, CP metadata redaction, direct table read hardening, private audit writer grants, and audit spoof protection.
## Milestone 11B Frontend Audit Log Viewer

- `src/services/adminAuditService.js`
  - Isolated audit-viewer service.
  - Uses only `get_audit_logs` for audit reads.
  - Provides frontend audit visibility gating, action/actor/target formatting, default filters, and whitelist-based metadata formatting.
  - Does not query `audit_logs` directly and does not call CP tables/RPCs.
- `src/pages/AdminPanel.jsx`
  - Adds read-only Audit Logs section.
  - Supports refresh, action filter, safe/simple guild filter, date range filters, limit selector, and load older pagination through `p_before`.
  - Shows loading, empty, error, and clean not-authorized states.
  - Shows `Sensitive CP metadata hidden.` when `metadata_redacted` is true.
- `src/styles/app.css`
  - Adds mobile-first dark/red audit filters, cards, metadata summary, and load-older styles.

## Milestone 14C AdminPanel Tabs And Section Organization

- `src/pages/AdminPanel.jsx`
  - Coordinates AdminPanel session/membership context, admin permission-key loading, visible tab calculation, active tab state, and section handlers.
  - Renders only the active tab section.
  - Lazy-loads CP, Audit Logs, and GvG management data only when those tabs are opened.
  - Keeps backend/RLS/RPC checks as the authority and preserves existing service paths.
- `src/components/admin/AdminTabs.jsx`
  - Mobile-first horizontal tab bar for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Extracted approval queue UI; writes still flow through existing approval RPC handlers.
- `src/components/admin/AdminMembersSection.jsx`
  - Extracted member management UI; writes still flow through existing member-management RPC handlers.
- `src/components/admin/AdminCpSection.jsx`
  - Extracted CP UI; CP service paths remain approved CP RPCs only.
- `src/components/admin/AdminGvgSection.jsx`
  - Extracted GvG management UI; GvG service paths remain approved RPCs/safe reads.
- `src/components/admin/AdminAuditSection.jsx`
  - Extracted audit viewer UI; audit reads remain `get_audit_logs` only.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Extracted permission checkbox UI; writes remain `grant_admin_permission` / `revoke_admin_permission`.
- `src/components/admin/AdminToolsSection.jsx`
  - Extracted planned admin modules placeholder.
- `src/styles/app.css`
  - Adds sticky/mobile horizontal admin tab styling and tab content spacing.

## Milestone 15B Frontend Member Status UI

- `src/services/profileService.js`
  - Includes `roster_status` in the safe current membership shape.
- `src/services/adminMemberService.js`
  - Includes `roster_status` in the safe member roster select.
  - Loads approved primary memberships across active/suspended/left hard states.
  - Adds roster status label/tone/summary helpers.
  - Adds `updateMemberRosterStatus(...)`, which calls only `update_member_roster_status`.
- `src/App.jsx`
  - Derives UX-only hard roster blocking for `suspended`, `left`, and `kicked`.
  - Keeps pending/rejected/profile approval gating intact.
- `src/pages/RosterRestrictedStatus.jsx`
  - Shows safe restricted notices for roster hard-block states.
- `src/pages/Dashboard.jsx` and `src/pages/Profile.jsx`
  - Show own roster status badges/notes without adding CP reads.
- `src/pages/Gvg.jsx`
  - Shows no vote controls for `inactive` and `on_break`; backend remains authority.
- `src/pages/AdminPanel.jsx`
  - Coordinates roster status filters, drafts, RPC action handler, and refresh after status changes.
- `src/components/admin/AdminMembersSection.jsx`
  - Displays roster badges/filter/status controls, reason input, and hard-block confirmation.
  - Does not display private status history/reasons.
- `src/styles/app.css`
  - Adds roster badge tones, badge rows, restricted panels, and compact status reason styling.

## Milestone 16B AdminPanel UI Cleanup

- `src/pages/AdminPanel.jsx`
  - Keeps AdminPanel behavior and tab coordination unchanged.
  - Shortens AdminPanel shell and restricted-state copy.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Tightens approval tab heading, empty state, cards, and rejection-note copy.
- `src/components/admin/AdminMembersSection.jsx`
  - Tightens member cards, metadata, roster status controls, role controls, and guild transfer copy while preserving existing action handlers.
- `src/components/admin/AdminCpSection.jsx`
  - Tightens CP roster, empty state, read-only, and leaderboard copy.
- `src/components/admin/AdminGvgSection.jsx`
  - Tightens GvG event creation/results copy while preserving event lifecycle controls.
- `src/components/admin/AdminAuditSection.jsx`
  - Tightens audit empty/denied states while preserving CP redaction notice.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Tightens permission target copy without changing checkbox behavior.
- `src/components/admin/AdminToolsSection.jsx`
  - Replaces milestone-style placeholder language with compact coming-later rows.
- `src/styles/app.css`
  - Adds compact AdminPanel card, empty-state, metadata, control-block, tab, and narrow-mobile styles.

## Milestone 18D AdminPanel Full Translation

- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add full AdminPanel translation keys for shell, common admin labels, Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, errors, success messages, permission catalog display labels/descriptions, audit actions, and audit metadata labels.
- `src/pages/AdminPanel.jsx`
  - Adds UI-only translation wrappers for roles, membership statuses, roster statuses, GvG statuses, dates, audit actions, audit metadata labels, and permission labels/descriptions.
  - Keeps all logic values, select values, RPC payload values, audit metadata values, permission keys, and roster/GvG/member status values unchanged.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Translates approval queue labels, buttons, empty/loading states, details labels, and rejection note labels.
- `src/components/admin/AdminMembersSection.jsx`
  - Translates roster filters, compact row metadata, Manage disclosure controls, roster status controls, role controls, guild transfer controls, confirmations, warnings, and empty/loading states.
- `src/components/admin/AdminCpSection.jsx`
  - Translates CP roster, filters, CP details labels, read-only/update controls, empty states, and leaderboard labels.
- `src/components/admin/AdminGvgSection.jsx`
  - Translates GvG event creation, scope labels, date labels, lifecycle buttons, result summaries, and empty/loading states while preserving event titles and status values used in logic.
- `src/components/admin/AdminAuditSection.jsx`
  - Translates audit filters, action labels, card metadata labels, read-only badge, CP redaction notice, metadata labels, and load-older controls while preserving raw metadata values.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Translates permission target labels, sensitive/Owner-only notes, save/cancel controls, and permission catalog display labels/descriptions without renaming permission keys.
- `src/components/admin/AdminToolsSection.jsx`
  - Translates Tools placeholder copy.

Milestone 18F production note:
- The frontend-only language pack is live in production as commit `1f5b956 feat: add English French German language pack`.
- Supported languages are English, French, and German.
- Full AdminPanel translation is production-smoke validated.
- Translation remains display-only; backend logic, permission keys, audit values, guild names, usernames, IGN, and user-generated text remain raw/unchanged.
