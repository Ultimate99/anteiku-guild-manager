# Security Rules

## Active Profile 3v3 Team Finder Security Rules

Milestone 29E.3 3v3 Team Finder active-profile migration is live in production through `20260531000400_active_profile_three_v_three.sql` and commit `a5eb9e6 feat: migrate 3v3 to active profile`.

Rules:
- 3v3 actor/viewer identity must resolve through `private.get_active_profile_id()` for migrated 3v3 setup/team/request/owner actions.
- Frontend must not provide arbitrary actor profile ids for Discord username updates, public 3v3 Combined CP updates, team creation, team/status reads, join requests, cancel, approve/decline, remove, close/reopen, or disband.
- Frontend 3v3 access must continue through RPC service wrappers only.
- Existing 3v3 constraints remain backend-enforced: one active team membership, one owned active team, owner slot 1, max 3 members, owner-only request decisions/team management, and request spam/cooldown limits.
- CP get/submit, GvG vote, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain separate future migrations.

Privacy:
- 3v3 payloads may show safe public 3v3 profile/team fields only, including Discord username and public self-entered 3v3 Combined CP.
- 3v3 Combined CP is not protected normal CP and must not be populated from `member_cp`.
- 3v3 payloads must not return or display normal CP, `member_cp`, `cp_snapshots`, email, auth secrets, passwords, service-role data, admin private metadata, audit-private metadata, or arbitrary linked profile ids.

Validation status:
- Local validation passed with the active-profile 3v3 block at `17 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000400_active_profile_three_v_three.sql`; production apply/list verification passed.
- Production DB verification confirmed all 13 public 3v3 RPCs use `private.get_active_profile_id()`, 3v3 tables keep RLS/no broad direct grants, active Owner count remains `1`, and simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows.
- Authenticated production smoke passed for 3v3 page/sub-tab rendering and no normal CP/private data; no production 3v3 mutation was performed.

## Active Profile Wall/Profile Reaction Security Rules

Milestone 29E.2 Guild Wall / Global Wall and Public Profile reactions active-profile migration is live in production through `20260531000300_active_profile_wall_reactions.sql` and commit `db2b9e5 feat: migrate wall reactions to active profile`.

Rules:
- Wall and Profile Reaction actor identity must resolve through `private.get_active_profile_id()` for migrated actions/viewer state.
- Frontend must not provide arbitrary actor profile ids for Wall posts, comments, reactions, own deletes, profile reactions, or reaction details.
- Guild Wall and Global Wall frontend access must continue through RPC service wrappers only.
- Public Profile reaction writes/details must continue through RPC service wrappers only.
- My Org scope may use the safe active profile summary for selected guild context; Global scope remains null/global and must not mix guild-scoped posts.
- CP get/submit, GvG vote, 3v3 actions, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain separate future migrations.

Privacy:
- Wall/Profile Reaction payloads may show safe public profile, guild, cosmetic, reaction, and timestamp fields only.
- They must not return or display normal CP, `member_cp`, `cp_snapshots`, email, auth secrets, passwords, service-role data, admin private metadata, audit-private metadata, or arbitrary linked profile ids.

Validation status:
- Local validation passed with the active-profile Wall/Profile Reactions block at `16 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000300_active_profile_wall_reactions.sql`; production apply passed and migration list shows it applied.
- Production DB verification confirmed migrated Wall/Profile Reaction RPCs use `private.get_active_profile_id()`, active Owner count remains `1`, and simulated normal-member direct reads of `member_cp` and `cp_snapshots` returned zero visible rows.
- Production smoke passed for Guild Wall load, Global/My Org scope load, active-profile Wall post create/reaction/delete, Public Profile safe render/reaction detail, controlled RPC smoke for comment create/react/delete and profile reaction add/remove, and no captured console errors.

## Active Profile Profile/Cosmetics Security Rules

Milestone 29E.1 Own Profile + Cosmetics active-profile migration is live in production through `20260531000200_active_profile_profile_cosmetics.sql` and commit `401e67e feat: migrate profile cosmetics to active profile`.

Rules:
- Own Profile identity/details and IGN edit may use active-profile RPCs only: `get_my_active_profile_details()` and `update_my_active_profile(p_ign text)`.
- Profile Customize may use active-profile cosmetics RPCs only: `get_my_active_cosmetics()`, `equip_my_active_avatar(p_avatar_key text)`, and `equip_my_active_frame(p_frame_key text)`.
- Active-profile RPCs must resolve the selected profile through `private.get_active_profile_id()`.
- Frontend must not provide arbitrary profile ids for Profile or Cosmetics actions.
- Frontend must not direct-read or direct-write `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics`.
- Active cosmetics equip must enforce free-or-unlocked checks for the selected active profile.
- CP get/submit is not migrated in 29E.1. If active profile differs from the legacy auth profile, Profile must not render legacy own CP and should show the CP-switching-not-enabled state.
- GvG, 3v3, Wall/Global Wall actions, Profile reactions, Push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain separate future migrations.

Privacy:
- Active Profile/Cosmetics payloads may show safe profile identity, guild/status, and cosmetics fields only.
- They must not return or display normal CP, `member_cp`, `cp_snapshots`, email, auth secrets, passwords, service-role data, admin private metadata, audit-private metadata, or arbitrary linked profile ids.

Validation status:
- Local validation passed with the active-profile Profile/Cosmetics block at `10 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000200_active_profile_profile_cosmetics.sql`; production apply passed and migration list shows it applied.
- Production smoke passed for Profile active identity/details, active cosmetics modal load, frame equip-and-restore, single-profile CP unchanged, and no captured console errors.

## Account Switcher Security Rules

Account Switcher backend foundation is live in production through `20260531000100_account_switcher_foundation.sql`. The Profile Settings Account Switcher UI is live through commit `b8f6162 feat: add account switcher UI`, and low-risk viewer-state display is live through commit `14c3837 feat: add active profile viewer state`.

Rules:
- Frontend must not choose arbitrary `profile_id` for identity-sensitive actions.
- Account switching must use `get_my_switchable_profiles()`, `get_my_active_profile()`, and `set_my_active_profile(p_profile_id uuid)`.
- Backend must verify `auth.uid()` has an active, non-disabled link to the selected profile.
- The Profile Settings switcher may display linked safe profiles and call `set_my_active_profile(...)`, but it must not use localStorage or frontend state as security authority.
- Viewer-state display may call `get_my_active_profile()` for safe display only.
- Topbar/Dashboard active-profile display must not imply high-risk action systems have migrated.
- Normal members cannot link or unlink profiles.
- Owner-only profile linking must use `owner_link_profile_to_auth_user(...)` / `owner_unlink_profile_from_auth_user(...)`.
- Do not update existing CP/GvG/Push/Admin/Analytics/audit RPCs to use active profile without a separately approved, subsystem-specific milestone.
- CP get/submit, GvG vote, push preferences/subscriptions, Admin permissions/actions, Analytics, and audit actor behavior remain legacy-profile based until explicitly migrated.

Privacy:
- Switcher payloads may show safe profile identity/status/guild/cosmetic fields only.
- Switcher payloads must not include normal CP, `member_cp`, `cp_snapshots`, email, auth secrets, passwords, service-role data, admin private metadata, or audit-private metadata.
- Active Owner access must not be orphaned by unlinking.

Validation status:
- Local validation passed with the Account Switcher block at `19 PASS / 0 FAIL / 0 SKIP`.
- Production DB verification passed for RLS/no direct account-link grants, RPC grants, self-link backfill, active Owner count `1`, and normal CP direct-read protection.
- 29C frontend build/source validation passed; production smoke passed for Profile Settings Account Switcher render/current active profile/single-profile state and no captured console errors.
- 29C did not change SQL, Supabase/RLS/RPC, CP privacy, Admin permissions, audit actor behavior, or existing subsystem identity behavior.
- 29D frontend build/source validation passed; production smoke passed for topbar viewer state, Dashboard/Home load, Profile Settings active-profile card, and no captured console errors.
- 29D did not change SQL, Supabase/RLS/RPC, CP privacy, Admin permissions, audit actor behavior, or high-risk subsystem action behavior.

## Push Notification Security Rules

Push Notifications are live in production. Production has `20260530000800_push_notifications_foundation.sql` applied, `send-push-notifications` deployed, required Supabase Edge Function secret names configured, Vercel `VITE_VAPID_PUBLIC_KEY` configured, and manual production push smoke passed.

Frontend rules:
- Use `src/services/pushNotificationService.js` RPC wrappers only.
- Do not direct-read or direct-write push tables.
- `VITE_VAPID_PUBLIC_KEY` is the only browser-exposed VAPID value.
- `VAPID_PRIVATE_KEY` must never be committed, printed in docs/logs, added to frontend code, or placed in Vercel public env.
- Service worker push handling must not cache Supabase RPC/API/Auth responses.
- Service worker notification payloads must stay safe title/body/type/route data only.

UI rules:
- Push settings live under the user's own Profile Settings modal.
- Enable/disable controls affect the current browser subscription.
- Preference toggles update only the authenticated user's preferences through backend RPC.
- Self-test only queues a notification for the authenticated user.

Rules:
- Push registration and preferences must use RPCs only.
- Approved profile plus active primary membership is required.
- Only roster statuses `active`, `trial`, and `pending_transfer` may register/receive self-test push notifications.
- Pending, rejected, suspended, left, kicked, inactive, and on-break users are denied.
- Frontend must never use service-role keys.
- Edge Function service-role access is server-side only and must not be exposed to Vercel/frontend env.
- Event hooks for GvG, CP Update Window, 3v3, and Wall notifications are deferred until a separately approved milestone.

Payload privacy:
- Notification title/body are fixed server-side by notification type.
- No normal CP values, `member_cp`, `cp_snapshots`, CP history/growth, email, auth IDs, audit logs, admin permissions, private notes, private metadata, or arbitrary user content may be included in push payloads.
- Push sender must not cache Supabase RPC/API/Auth responses.

Production validation:
- Production dry-run showed only `20260530000800_push_notifications_foundation.sql`; migration apply passed.
- DB verification passed for push table RLS/no broad direct grants, RPC grants, active Owner count `1`, and normal CP table protection.
- Manual production push smoke passed: notification permission granted, subscription registered, preferences saved, test notification received, notification click opened the app, disable flow worked or is available, and no CP/private/admin data appeared.

## Ranking Public Profile Link Security Rules

Ranking to Public Member Profile links are live in production through `20260530000700_ranking_public_profile_links.sql` and commit `d806974 feat: link rankings to public profiles`.

Rules:
- Member-facing Ranking may use only `get_member_cp_rankings(p_scope)` for rank rows.
- The only added member-ranking routing field is `profile_slug`.
- Ranking rows/cards may navigate to authenticated `/members/:profileSlug` public profiles.
- Ranking order/math must remain unchanged.
- AdminPanel CP Ranking remains permission-protected and uses `get_admin_cp_rankings(...)`.

Privacy:
- Member Ranking must not return or render normal CP values, `member_cp`, `cp_snapshots`, CP history, CP growth, profile ids, email, auth IDs, audit logs, admin permissions, private notes, or private CP metadata.
- Public profile pages remain authenticated app pages for approved members only.

Production validation:
- Local DB reset and full local validation passed with the new migration.
- Production smoke passed for My Guild/Global Ranking links, safe `/members/toji` profile render/refresh, no protected CP values in member Ranking, Admin CP Ranking still loading for Owner, and no captured console errors.

## Public Member Profile Security Rules

Public Member Profiles and profile reactions are live in production through `20260530000600_public_member_profiles.sql`, commit `3f55f76 feat: add public member profiles`, and route fallback commit `ffc36e1 fix: support public profile route refresh`.

Rules:
- Public member profiles are authenticated app pages for approved members only, not unauthenticated public internet profiles.
- Frontend reads must use `get_public_member_profile(p_profile_slug)` only.
- Profile reaction writes must use `react_to_public_profile(...)` and `remove_public_profile_reaction(...)` only.
- Reaction detail reads must use `get_public_profile_reaction_details(...)` only.
- Frontend must not direct-read or direct-write `profile_reactions`.
- Profile reactions do not affect Ghoul Rep.
- Guild Wall and 3v3 may link to public profiles only when a safe `profile_slug` is already returned by the backend.
- Ranking rows/cards may link to public profiles because `20260530000700_ranking_public_profile_links.sql` adds safe `profile_slug` to the member-safe ranking RPC.

Privacy:
- Public profiles may show safe identity/social fields: avatar/frame, IGN, username/profile slug, guild, safe role label, safe roster/profile status, Ghoul Rep, public 3v3 Combined CP, and profile reaction counts/details.
- Public profiles must not show normal CP, `member_cp`, `cp_snapshots`, CP RPC data, email, auth IDs, audit logs, admin permissions, private notes, private metadata, uploads, or Storage data.
- Normal CP privacy remains unchanged.

Production validation:
- Production DB verification passed for `profile_reactions` table existence/RLS, RPC existence, direct unsafe write denial, safe payload, active Owner count `1`, and normal CP direct-read protection.
- Frontend source validation passed: no direct `.from(...)` calls in the public profile path and no `member_cp` / `cp_snapshots` usage except the defensive deny-list guard.
- Production smoke passed for direct public profile route, controlled profile reaction add/remove, reaction details safe fields, Wall/3v3 links, no CP/email/private metadata, and no captured console errors.

## Ghoul Rep Profile And Wall Security Rules

Ghoul Rep backend support is live in production through `20260530000400_ghoul_rep_wall_reactions.sql` and `20260530000500_my_ghoul_rep_profile.sql`. The frontend chip/reaction-detail UI is live through commits `cc2a82b`, `3c0ba0b`, and `bc9e30a`.

Rules:
- Ghoul Rep is calculated from Guild Wall and Global Wall reactions only.
- Post reactions count for the post author.
- Comment reactions count for the comment author.
- A reacting profile gives at most `+1` per target post/comment, even if they use multiple reaction types.
- The same reacting profile can count separately for different post/comment targets by the same author.
- Self-reactions remain visible but do not count toward Ghoul Rep.
- Deleted posts/comments and removed reactions do not count.
- `author_ghoul_rep` may be returned by `get_guild_wall_feed(...)`.
- `get_my_ghoul_rep()` may return only the authenticated caller's own live Ghoul Rep number.
- Reaction detail UI must use `get_wall_reaction_details(...)`, not direct table reads.
- Frontend may display compact Ghoul Rep chips on Wall post/comment authors.
- Frontend may display a compact own Ghoul Rep chip on the signed-in user's Profile.
- Frontend reaction detail UI may display safe public reaction-user details only.

Privacy:
- Ghoul Rep must not use or expose normal CP, `member_cp`, `cp_snapshots`, CP analytics, CP roster, CP rankings, CP growth, email, auth metadata, private admin metadata, uploads, or Storage data.
- Reaction details may show only safe public profile/cosmetic fields: avatar/frame if available, IGN, username/profile slug, guild, reaction type, and reaction timestamp.
- Profile Ghoul Rep must use `get_my_ghoul_rep()` or an equivalently scoped own-user RPC; it must not query Wall tables directly and must not add public profile viewing.

Production validation:
- Production dry-run showed only `20260530000400_ghoul_rep_wall_reactions.sql`, migration apply succeeded, and read-only DB verification passed.
- Production dry-run for `20260530000500_my_ghoul_rep_profile.sql` showed exactly that migration pending; migration apply succeeded and remote migration list shows it applied.
- Local validation passed `47 PASS / 0 FAIL / 0 SKIP`.
- Frontend production smoke passed for My Guild/Global Ghoul Rep chips, Profile own Ghoul Rep chip, reaction detail panel, no CP/email visible, and no console errors.

## Global Wall Scope Security Rules

Global Wall is live in production through `20260530000300_global_wall_scope.sql` and commit `feaf2ff feat: add global wall scope`.

Rules:
- `guild_id = null` means the Global Wall scope for wall posts/comments only.
- `My Guild` feed must pass an explicit guild id; `Global` feed passes null and returns only Global posts.
- Approved active/trial/pending_transfer members can create/comment/react in Global.
- `inactive` and `on_break` users can view Global but cannot create/comment/react.
- Pending, rejected, suspended, left, and kicked users remain denied by backend/RPC gates.
- Owner can moderate Global posts/comments.
- Scoped staff moderation remains guild-scoped and must not moderate Global posts.
- Frontend must use the Guild Wall RPC service only; no direct wall table writes.
- Guild Wall must not read or expose `member_cp`, `cp_snapshots`, CP analytics, CP roster, CP ranking, CP growth, auth secrets, emails, private admin metadata, uploads, or Storage data.

Production validation:
- Production DB verification passed for nullable wall scope columns, RLS enabled, zero broad direct wall table grants, wall RPC presence, active Owner count `1`, and Owner Global feed read.
- Controlled production Global post/comment/reaction smoke still requires an authenticated controlled account.

## Milestone 25D 3v3 Team Finder Production Rules

3v3 Team Finder is live in production through `20260528000100_three_v_three_team_finder.sql` and commit `4c9da98 feat: add 3v3 team finder UI`.

Production rules:
- 3v3 Team Finder access remains for approved users with active primary membership.
- `inactive` and `on_break` users may view 3v3 teams but cannot create teams or request joins.
- `active`, `trial`, and `pending_transfer` users may create/request when other requirements pass.
- Pending, suspended, left, and kicked users are denied.
- Discord username is required before creating a team or requesting to join.
- 3v3 Combined CP is public inside the 3v3 feature and is self-entered.
- 3v3 Combined CP must never be sourced from protected normal CP.
- 3v3 must not read `member_cp`, `cp_snapshots`, CP analytics, CP roster, CP ranking, or CP growth data.
- Team owner occupies slot 1 and is the only user who can approve/decline requests, remove slot 2/3 members, close/reopen, or disband.
- Request spam limits remain backend-enforced: one pending request per player/team, max two attempts per player/team, and a six-hour cooldown after declined requests.
- Direct client table access to 3v3 tables must remain blocked; use RPC-only reads/writes.

Production validation:
- Controlled production smoke passed for create team, request join, approve request, slot fill, public Discord/3v3 CP display, normal CP non-exposure, and Member AdminPanel denial.
- Test team cleanup state was not specified in the smoke note; verify before assuming retained/disbanded state.

## Milestone 25B 3v3 Team Finder Security Rules

Milestone 25B is implemented, locally validated, and production applied through Milestone 25D. For future new target environments, do not deploy a 3v3 frontend until `20260528000100_three_v_three_team_finder.sql` is applied and verified on that target database.

Rules:
- 3v3 Team Finder access is for approved users with active primary membership.
- `inactive` and `on_break` users may view 3v3 teams but cannot create teams or request joins.
- `active`, `trial`, and `pending_transfer` users may create/request when other requirements pass.
- Pending, suspended, left, and kicked users are denied.
- Discord username is required before creating a team or requesting to join.
- 3v3 Combined CP is required before creating a team or requesting to join.
- 3v3 Combined CP is public inside the 3v3 feature and is self-entered; it must never be sourced from protected normal CP.
- Do not read `member_cp`, `cp_snapshots`, CP analytics, CP roster, CP ranking, or CP growth data for 3v3.
- One player can have only one active 3v3 team membership and one active owned team.
- Team owner occupies slot 1.
- Team owner only can approve/decline requests, remove slot 2/3 members, close/reopen, or disband.
- Team owner cannot remove themselves; ownership transfer is not supported in v1.
- Team name is immutable after creation.
- Request spam limits are backend-enforced: one pending request per player/team, max two attempts per player/team, and a six-hour cooldown after a declined request.
- Accepted requests cancel the requester's other pending requests.
- Direct client table access to 3v3 tables must remain blocked; use RPC-only reads/writes.

## Live CP Growth Security Rules

Live CP Growth is live in production through `20260526000300_live_cp_growth_baseline_scope.sql`.

Rules:
- Live CP Growth is AdminPanel Analytics only.
- Members, pending users, restricted users, and admins without scoped `view_cp` must not receive CP growth values.
- `get_admin_live_cp_growth(...)` is the only frontend read path for live weekly growth.
- `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)` allows an explicitly selected baseline to be preserved across Analytics scope changes when backend scoping permits it.
- Owner may use a Global baseline while filtering rows to a guild scope. Scoped staff may not use Global baselines for guild analytics.
- `start_new_cp_growth_period(...)` is the approved reset/start-week path. It captures baseline CP values only; it must not reset player CP.
- Production Start New CP Week is a mutation and requires explicit approval before use.
- Frontend must not direct-read `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- Wrong-guild staff must be denied by backend/RPC.
- Owner can view global live growth; scoped staff can view only authorized guild scope.
- Production baseline scope fix smoke confirmed Global and Anteiku can show the same Owner-selected Global baseline filtered by guild without creating a new snapshot.

## Milestone 24B Admin Analytics Security Rules

Admin Analytics backend support is live in production as of Milestone 24E.

Production status:
- Production has `20260526000100_admin_analytics_foundation.sql` applied and verified.
- `cp_snapshot_batches` and `cp_snapshot_entries` have RLS enabled and no direct anon/authenticated table grants.
- AdminPanel Analytics is live in production.
- Weekly Growth is live in production. Start New CP Week / baseline capture must be treated as a mutation and requires explicit approval before use.

Rules:
- Admin Analytics must remain staff-only.
- Members and pending/restricted users must not access analytics RPCs.
- Member analytics can expose non-CP member status/approval/guild summaries only to Owner or scoped staff authority.
- CP Analytics and Weekly Growth require backend-enforced scoped `view_cp`.
- Admins without `view_cp` must not receive CP totals, averages, highest/lowest values, missing-CP details, snapshot rows, or growth values.
- Wrong-guild staff must be denied.
- Owner can view global analytics and capture global snapshots.
- Scoped staff can view/capture only authorized guild scope.
- Frontend must not direct-read `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- Snapshot/baseline writes must go through `start_new_cp_growth_period(...)` or the compatibility `capture_weekly_cp_snapshot(...)` RPC only.
- No service-role path, direct table grant, or member-facing analytics route is allowed.

## Owner Cosmetics Grant Tool Rules

Owner Cosmetics is a frontend-only AdminPanel Tools surface for the existing grant RPC.

Rules:
- UI must be visible only to Owner.
- Non-owner Admins must not see the Owner Cosmetics section.
- Members must not access AdminPanel.
- The form must ask for username/profile slug and must not use IGN/display-name lookup.
- Cosmetic options may be loaded only through existing safe RPC/read paths.
- Grants must call only `admin_grant_cosmetic_by_slug(p_profile_slug, p_cosmetic_key, p_reason)`.
- Frontend must not insert/update/delete `profile_cosmetic_unlocks`, `profile_equipped_cosmetics`, or `cosmetic_catalog`.
- No uploads, Supabase Storage, arbitrary URLs, service-role key path, or broad catalog-write UI is allowed.
- Production grant mutation smoke requires explicit approval and must use only the Owner Cosmetics UI / `admin_grant_cosmetic_by_slug(...)` path.
- Controlled production grant smoke has passed for locked avatar/frame grant by exact profile slug / username and member equip after grant.

## Milestone 23D Premium Cosmetics Production Rules

Milestone 23D is live in production. Production has `20260525000300_premium_cosmetics_grant_helper.sql` applied and verified.

Production premium cosmetics rules:
- Catalog `unlock_type` is the source of truth.
- `_FREE` filename/key suffixes are only asset/import conventions.
- All current frame catalog rows are free for approved members.
- Future premium avatars and frames must use `unlock_type = 'manual'`.
- Manual avatars and frames require a caller-owned unlock row before equip.
- `update_my_profile(p_ign, p_avatar_key)` must not bypass manual avatar locks.
- `admin_grant_cosmetic_by_slug(...)` must use exact normalized `profile_slug` or `username`, not IGN/display name.
- Normal Members and Admins without member-management authority must not grant cosmetics.
- No uploads, arbitrary image URLs, or Supabase Storage are allowed.

## Milestone 23B Premium Cosmetics Backend Rules

Milestone 23B was implemented locally, then rolled out to staging in Milestone 23C and production in Milestone 23D.

Premium cosmetics rules:
- Catalog `unlock_type` is the source of truth.
- `_FREE` filename/key suffixes are only asset/import conventions.
- All current frame catalog rows are free for approved members after the 23B migration.
- Future premium avatars and future premium frames must use `unlock_type = 'manual'`.
- Members can equip manual avatars or frames only when a caller-owned `profile_cosmetic_unlocks` row exists.
- Members cannot equip inactive, invalid, or arbitrary cosmetic keys.
- Members cannot grant themselves cosmetics.

Grant rules:
- Use `admin_grant_cosmetic_by_slug(...)` only for exact normalized `profile_slug` or `username` lookup.
- Do not grant by IGN/display name.
- Grant authority remains Owner, scoped Leader/Vice, or scoped Admin with member-management authority through the existing grant path.
- Grant RPCs write the existing `cosmetic_granted` audit action.

Legacy avatar hardening:
- `update_my_profile(p_ign, p_avatar_key)` must apply the same free-or-unlocked avatar rule as `equip_my_avatar(...)`.
- Locked manual avatars must not be accepted through profile edit shortcuts.

Boundary:
- No uploads, arbitrary image URLs, Supabase Storage, service-role path, frontend grant UI, CP/GvG/audit/role/permission/member-status behavior changes, staging action, or production action were included in 23B.

## Milestone 22E Cosmetics Production Rules

Milestone 22E is live in production. Production has `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified, and the cosmetics picker/assets are deployed.

Production cosmetics rules:
- Load/equip cosmetics through RPCs only. Current Profile Customize uses active-profile RPCs `get_my_active_cosmetics`, `equip_my_active_avatar`, and `equip_my_active_frame`; legacy own-user paths remain `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame` where still used outside the migrated Profile surface.
- Do not direct-read or direct-write `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics` from frontend code.
- Do not expose `admin_grant_cosmetic(...)` in member-facing UI.
- Do not add upload, arbitrary URL, or Supabase Storage avatar/frame behavior.
- Render only approved repo asset paths constrained to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- Players can equip active avatars and only frames that are free or explicitly unlocked by backend state.
- Locked/manual frames may be shown as locked but must not be equip-enabled unless the backend marks them unlocked.
- Production direct unsafe anon/authenticated writes to cosmetics tables are not granted.
- Any future target environment must receive and verify `20260525000100_cosmetics_catalog_unlocks.sql` before deploying cosmetics UI.

## Milestone 22C Frontend Cosmetics Picker Rules

Milestone 22C was frontend-only during implementation and is now deployed through Milestone 22E.

Frontend picker rules:
- Load cosmetics through RPCs only. Profile Customize now uses `get_my_active_cosmetics()`; legacy own-user cosmetics surfaces may still use `get_my_cosmetics()`.
- Equip avatars through `equip_my_avatar(...)` only.
- Equip frames through `equip_my_frame(...)` only.
- Do not direct-read or direct-write `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics` from frontend code.
- Do not expose `admin_grant_cosmetic(...)` in member-facing UI.
- Do not add upload, arbitrary URL, or Supabase Storage avatar/frame behavior.
- Render only asset paths constrained to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- Locked frames may be shown as locked but must not be equip-enabled unless backend marks them unlocked.
- Staging and production now have the cosmetics migration applied and verified.

## Milestone 22B Cosmetics Backend Rules

Milestone 22B is backend/database-only implementation work. It is now applied and verified in staging and production through Milestones 22D and 22E.

Cosmetic catalog rules:
- Cosmetic assets are approved preset keys only.
- Database stores keys and static asset paths, not image files.
- Asset paths must stay under `/cosmetics/avatars/` or `/cosmetics/frames/`.
- No player uploads, arbitrary image URLs, or Supabase Storage are allowed in v1.
- `_FREE` suffixes are an asset/import convention for free/default cosmetics.
- All current avatar catalog rows are free for approved players.
- Current non-`_FREE` frame rows use `unlock_type = 'manual'` and require an unlock row.
- Catalog `unlock_type = 'free'` is the runtime source of truth; do not rely on filename parsing alone.

Member equip rules:
- Members equip only their own cosmetics through `equip_my_avatar(...)` and `equip_my_frame(...)`.
- Equip RPCs use `auth.uid()` and accept no target profile id.
- Avatars must exist in `cosmetic_catalog`, be active, and have type `avatar`.
- Frames must exist in `cosmetic_catalog`, be active, have type `frame`, and either be free or unlocked for the caller.
- Members cannot grant themselves cosmetics.

Admin grant rules:
- Cosmetic grants use `admin_grant_cosmetic(...)`.
- Grants require Owner, scoped Leader/Vice, or scoped Admin with `manage_members` for the target member's active primary guild.
- Grant audit metadata may include cosmetic key/type and whether a reason was provided, but should not expose sensitive data.

Legacy avatar hardening:
- `update_my_profile(p_ign, p_avatar_key)` must not store arbitrary avatar keys.
- Non-empty avatar keys now must match an active catalog avatar.
- `equip_my_avatar(...)` syncs `profiles.avatar_key` for backward compatibility.

RLS/direct access:
- RLS is enabled on `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Direct catalog reads are limited to active catalog rows for approved users with active primary membership.
- Direct unlock/equipped reads are caller-owned only.
- Direct client writes are not granted.

Rollout boundary:
- `20260525000100_cosmetics_catalog_unlocks.sql` is applied and verified in staging and production.
- For any future new target environment, apply and verify the cosmetics migration before deploying cosmetics UI.

## Milestone 21E Rank Badge / Profile Border Production Rules

Milestone 21B backend, Milestone 21C frontend, Milestone 21D staging validation, and Milestone 21E production rollout are complete. Rank Badge / Profile Border is live in production.

Own rank summary rules:
- Profile/Dashboard rank badge visuals must use `get_my_cp_rank_summary()`.
- The RPC returns only the caller's own `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- The RPC must not return CP values, updated timestamps, growth/history/snapshot data, updated-by metadata, usernames, profile ids, other-member rows, or private CP metadata.
- The RPC accepts no target profile id; it resolves the caller only through `auth.uid()`.
- Frontend translation should happen from stable keys such as `rank_one`, `elite_five`, `top_ten`, `ranked_member`, and `unranked`; SQL must not return translated labels.

Rank eligibility:
- Tier/rank summary uses the same eligibility as the member-safe leaderboard: approved profile, active primary membership, and roster status `active`, `trial`, or `pending_transfer`.
- `inactive` and `on_break` users with active approved membership receive the `unranked` default state.
- `suspended`, `left`, and `kicked` remain blocked by existing membership/security gates.

Rollout boundary:
- `20260524000400_cp_rank_badge_summary.sql` is applied and verified in staging and production.
- For any future new target environment, apply and verify this migration before deploying the rank badge/profile border frontend.

## Milestone 20F CP Leaderboard Production Rules

Milestone 20F is live in production.

Member ranking rules:
- Members may see CP rank order for `guild` and `global` scopes.
- Member-visible rank order intentionally reveals relative CP strength.
- Member ranking API responses must never include CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, audit metadata, or private CP fields.
- Member UI must show rank, IGN, optional guild label, and current-user highlight only.
- Member leaderboard frontend must use `get_member_cp_rankings(...)` only.

Admin ranking rules:
- AdminPanel CP Ranking must use `get_admin_cp_rankings(...)`.
- Guild rankings require existing scoped `view_cp` authority.
- Global admin rankings are Owner-only in v1.
- Admin without CP permission and normal Members must not receive CP values.

Operational rules:
- Do not query `member_cp` or `cp_snapshots` directly from frontend code.
- Do not send CP values to member clients and hide them in UI; member API responses must omit CP values.
- Existing CP Update Window, CP roster/update, audit, GvG, role, permission, and member-status behavior must remain unchanged.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## Milestone 20B CP Leaderboard Security Rules

Milestone 20B added backend support for member-safe CP rank order and admin CP rankings. The migration is now applied in staging and production through Milestones 20E and 20F.

Member ranking rules:
- Members may see CP rank order for `guild` and `global` scopes.
- This approved tradeoff reveals relative CP strength only.
- Members must not receive CP values from `get_member_cp_rankings(...)`.
- Members must not receive profile ids, usernames, updated timestamps, growth, snapshots, history, audit metadata, or private CP fields from the member ranking RPC.
- Member rankings may show IGN and, for global scope, guild label/slug.
- Current user highlighting uses `is_current_user`; no profile id is needed in the response.

Admin ranking rules:
- Admin guild CP rankings require scoped `view_cp` authority through the existing CP permission model.
- Admin global CP rankings are Owner-only in v1.
- Admin without scoped `view_cp` and normal Members must be denied by the RPC.
- CP values must only be returned by `get_admin_cp_rankings(...)` after database-side permission checks pass.

Roster inclusion:
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- `inactive` and `on_break` members may still view rank order if existing access gates allow them into member pages, but they are not ranked.

CP table privacy:
- Members still cannot directly read `member_cp` or `cp_snapshots`.
- Frontend leaderboard UI must use the member-safe ranking RPC and must not call admin CP ranking/roster APIs for member pages.
- Never send CP values to member frontend and hide them in UI; member API responses must omit them.

Rollout status:
- `20260524000300_cp_rankings.sql` is applied and verified in staging and production.

## Milestone 19E CP Update Window Security Rules

Milestone 19B/19B.1 backend, Milestone 19C frontend, Milestone 19D staging validation, and Milestone 19E production rollout are complete. CP Update Window / Member CP Self-Submit is live in production.

CP Update Window rules:
- CP Update Windows are guild-scoped.
- Only one open CP Update Window can exist per guild.
- Window writes are RPC-only through `open_cp_update_window(...)` and `close_cp_update_window(...)`.
- Opening/closing a window requires Owner, scoped Leader/Vice, or scoped Admin with `update_cp`.
- Staff window reads are RPC-only through `get_cp_update_window_for_guild(p_guild_id uuid)`.
- Staff window reads require Owner, scoped Leader/Vice, or scoped Admin with `view_cp` or `update_cp`.
- Members and wrong-guild users cannot read selected-guild window status through the staff RPC.
- Closing a window only freezes submissions; weekly snapshots remain future work.

Member self-submit rules:
- Members can read their own current CP only through `get_my_cp()`.
- Members can submit their own CP only through `submit_my_cp_update(p_cp_value integer)`.
- Members cannot pass a target profile id.
- Members cannot directly SELECT or UPDATE `member_cp`.
- Members cannot directly read `cp_snapshots`.
- Members cannot directly read `cp_update_windows`.
- CP value must be non-negative.
- Database/server time decides whether a window is open.

Roster eligibility:
- `active`, `trial`, and `pending_transfer` can submit CP during an applicable open window.
- `inactive` and `on_break` can read own CP but cannot submit.
- `suspended`, `left`, and `kicked` remain hard-blocked by membership/security state.

Audit/redaction:
- Member submissions write `member_cp_self_submitted`.
- Audit metadata includes `cp_old`, `cp_new`, `window_id`, and source.
- `get_audit_logs(...)` redacts CP metadata for audit viewers without scoped `view_cp`.

Production operation rules:
- Milestone 19E production smoke was read-only; no production CP window was opened/closed and no production CP value was submitted.
- Optional production CP mutation smoke requires explicit approval, a controlled production test member, and a documented restore/retention decision.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## Milestone 17D Controlled Guild Onboarding Rules

Milestone 17D prepares the app copy for disabling email confirmation later, but production email confirmation remains enabled until a separately approved Auth setting change.

Onboarding rules:
- Admin approval remains the real access gate.
- Registered users must remain pending until approved by authorized staff.
- Pending users must not access member/admin areas.
- Users should register with a real email because password recovery depends on it.
- Password recovery must remain enabled.
- Disabling email confirmation does not grant app access by itself.
- Staff must review the approval queue carefully during bulk onboarding.
- Fake or typo emails can create pending accounts; reject unknown or suspicious registrations.

Validation before production Auth changes:
- Disable email confirmation in staging only first.
- Confirm new staging signups land pending without email confirmation.
- Confirm pending lockout, Owner approval, approved access, and password recovery still work.
- Do not change production Auth settings until staging validation passes and a production gate is approved.

## Milestone 15A Member Status Security Rules

Member Status is live in production as of Milestone 15E and remains separate from auth/approval and hard membership state.

Current rules:
- `profiles.approval_status` remains the account/registration gate.
- `guild_memberships.membership_status` remains the hard security/access gate.
- `guild_memberships.roster_status` is the roster lifecycle/status label.
- `active`, `trial`, and `pending_transfer` keep normal access.
- `inactive` and `on_break` are not hard lockouts; they keep active membership but are excluded from GvG participation/expectation.
- `suspended`, `left`, and `kicked` are hard roster-access blocks.
- `kicked` maps to `membership_status = 'left'` because `membership_status = 'rejected'` is reserved for registration/reapply.
- Members cannot change their own roster status.
- Admin with `manage_members` can set only non-terminal statuses and cannot affect Owners or self.
- Leader/Vice can set scoped non-Owner statuses.
- Owner can set all statuses, but the last active Owner cannot be blocked/removed.
- Private status reasons live in `member_status_history`, not in broadly visible audit metadata.
- Production roster-status mutation smoke was not performed during rollout.
- Any optional production mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.

## Milestone 14D Staging And Preview Rules

Milestone 14D documents staging/preview policy only. It did not create a staging project, link Supabase CLI, run Supabase commands, change Vercel env vars, deploy, commit, edit source logic, or edit SQL migrations.

Future staging rules:
- Staging must be a fresh Supabase project separate from production.
- Staging must use separate Auth users, URL, anon/publishable key, Owner bootstrap, and test data.
- Fake/test data is allowed only in staging.
- Do not copy production data into staging unless explicitly approved.
- Apply the same approved migrations as production.
- Do not use `db push --include-seed` until the missing `supabase/seed.sql` hazard is resolved.
- Confirm the target project ref before linking, pushing migrations, or bootstrapping Owner.

Future Vercel Preview rules:
- Production Vercel env remains production Supabase only.
- Preview Vercel env should point only to staging Supabase once staging exists.
- If staging is not ready, Preview env should remain unconfigured.
- Never add service role keys, `sb_secret_*`, database passwords/URLs, JWT secrets, SMTP secrets, or OAuth/provider secrets to frontend/Vercel env.
- Production Auth URLs stay production-only.
- Preview wildcard redirects, if needed, belong in staging Supabase, not production Supabase.

## Milestone 14A Production Hardening Rules

Milestone 14A documented production hardening policy only. It did not run production commands, change Vercel settings, change GitHub App settings, disable/delete/suspend users, edit source logic, edit SQL migrations, deploy, or commit.

Current production hardening rules:
- Restricting the Vercel GitHub App to `Ultimate99/anteiku-guild-manager` is recommended but must be performed manually only after explicit approval.
- Do not change Vercel env vars during GitHub App restriction.
- Keep the controlled production test member documented for now; do not hard-delete it without an approved cleanup plan.
- Preview deployments should have no Supabase env vars until a separate staging Supabase project exists.
- Future staging must be separate from production.
- Production GvG smoke tests that create data require explicit approval and a cleanup/data-retention plan.
- CP redaction browser tests should preferably use staging with a controlled staff/data setup.
- Milestone 14H completed staging coverage for deferred production GvG smoke and CP audit redaction using `ckyihuxkioeibzpgwenc`; do not repeat those tests in production without explicit approval and a cleanup/data-retention plan.

## Production Readiness Rules

Production deployment must not weaken existing RLS/RPC security.

Production is live at `https://anteiku-guild-manager.vercel.app`. Milestone 13B deployment validation passed, and Milestone 14A added hardening/cleanup policy documentation only.

Production hard rules:
- Current implemented production behavior keeps member-facing CP hidden. Corrected future CP privacy rule: members may see their own CP only through a safe backend/RPC flow, but must never see other members' CP.
- CP access must remain enforced by Supabase RLS/RPC, not frontend hiding.
- Pending users must not access member/admin areas.
- Owner bootstrap remains manual-only with a known real Auth user id.
- Admin permissions must remain server/database enforced.
- GvG voting must keep one vote per event/profile.
- Audit logs must be read through `public.get_audit_logs(...)`.
- CP-sensitive audit metadata must not leak to users without scoped `view_cp`.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- Do not run `supabase db reset` on production.
- Do not run local fake-user validation SQL on production.
- Do not disable RLS or add broad grants.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz` after Milestone 15E; explicitly relink before future staging/local Supabase work.

## Milestone 11A Audit Log Read Safety

Audit logs can contain sensitive metadata. Future frontend audit UI must use only the safe audit reader RPC:

- `public.get_audit_logs(...)`

Do not directly read `public.audit_logs` from frontend code.

Security requirements now enforced database-side:
- Member and pending users cannot read audit logs.
- Admins need `view_audit_logs` for scoped audit access.
- Leader/Vice audit access is scoped to assigned guilds.
- Owner has global audit access.
- CP-sensitive audit metadata is redacted unless the viewer also has scoped `view_cp`.
- CP redaction removes CP old/new/value/growth fields and CP update notes.
- Redacted rows include a safe marker such as `cp_metadata_redacted`.

`private.write_audit_log` remains an internal helper only. Normal authenticated users do not have EXECUTE privilege on it.

## Milestone 8 CP Safety Rules

CP update eligibility:
- CP can only be updated for approved profiles.
- Target must have an active primary guild membership.
- Actor must pass `private.can_update_cp`.
- CP values must be non-negative.
- CP updates must write audit logs with old/new CP metadata.

CP roster safety:
- Authorized CP roster reads include active approved members only.
- Missing CP is returned as `null`, not `0`.
- CP roster, leaderboard, snapshots, and other members' CP remain unavailable to Members.
- Frontend must still avoid direct `member_cp` and `cp_snapshots` table access.

Future CP Update Window / Member CP Self-Submit rules:
- Members may see their own current CP through `get_my_cp` or equivalent safe RPC.
- Members may submit/update only their own CP through `submit_my_cp_update` or equivalent safe RPC.
- Backend must verify `auth.uid()`, approved active membership, self-only target, applicable open CP Update Window using database/server time, and guild/scope.
- Frontend disabled inputs are not security controls; backend/RPC remains the authority.
- CP submissions must write audit logs, and `get_audit_logs` CP metadata redaction must continue to work.

## Milestone 7 Security Rules

- Normal app RPCs must not assign `owner`.
- Member guild transfer is Owner-only in v1.
- Guild transfer must preserve membership history and avoid hard deletes.
- Guild transfer must leave exactly one active primary membership.
- Transferred member role resets to `member`.
- Role/guild management must not touch CP or GvG tables.
- Frontend must not direct-write `guild_memberships`; it must use approved RPCs.

No database security implementation exists yet. These are approved Milestone 2 specs for future SQL/RLS work.

## CP Privacy

CP is private across users. Corrected future rule: members may see their own CP through approved backend/RPC flow, but must not see other members' CP or query CP tables directly.

Approved CP design:

- Do not store CP in `profiles`.
- Store current CP in `member_cp`.
- Store manual weekly history/growth in `cp_snapshots`.
- Members must never directly select `member_cp` or `cp_snapshots`.
- Members must not see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Future own-CP reads must use `auth.uid()` and return only the caller's own CP.
- Authorized CP access must go through permission-checked RPC/views.
- Owner has global CP visibility and update access.
- Leader/Vice have automatic CP visibility and update access inside assigned guild.
- Admin needs explicit `view_cp` and/or `update_cp`.
- Only Owner can grant Admin `view_cp` and `update_cp` in v1.

Do not expose CP through:

- member profile queries
- leaderboard queries
- public views
- cached frontend state
- unrestricted Supabase selects
- placeholder demo data

## Approval

Registered users must start pending. Pending users cannot access member or admin areas.

Rejected users can request reapply using the same profile row by setting `reapply_requested_at` and `reapply_note`. Reapply does not grant access automatically.

## Username And Profile Slug

- `username` and `profile_slug` are identical at v1 registration.
- Normalize both to lowercase before saving.
- Format: lowercase letters, numbers, underscore, hyphen, length 3-32.
- Must start with a letter or number.
- Must not end with hyphen or underscore.
- Locked for normal users after registration.
- Owner can reset any username/profile slug.
- Leader/Vice can reset within assigned guild.
- Admin needs `reset_profile_slug`.

## IGN

- Users can edit their own IGN.
- Owner/Leader/Vice can edit member IGN inside scope.
- Admin needs `edit_member_ign`.

## Admin Permissions

Admin permissions must be enforced by database-side policies, approved RPC functions, or equivalent server-side checks.

Frontend conditionals are only presentation.

## Owner Bootstrap

Schema may support multiple Owners, but the initial Owner must be bootstrapped explicitly by migration/manual SQL using a known auth user id. There must be no public/self-service Owner creation.

## Deletes

Avoid hard deletes for important records. Prefer statuses such as `active`, `archived`, `closed`, `cancelled`, `suspended`, or `left`.
