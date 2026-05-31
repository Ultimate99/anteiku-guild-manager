# Supabase RLS

## Milestone 29E.4 Active Profile Push Notifications RLS/RPC

Milestone 29E.4 Push Notifications active-profile migration is implemented, locally validated, and production applied through `20260531000500_active_profile_push_notifications.sql`.

Tables:
- `push_subscriptions` now includes `auth_user_id` for auth/browser subscription ownership.
- `push_notification_preferences` remains keyed by recipient profile.
- `push_notification_outbox` remains profile-recipient based.

RPC security:
- `register_push_subscription(...)`, `get_my_push_preferences()`, `update_my_push_preferences(...)`, and `create_my_test_push_notification()` use `private.get_active_profile_id()` for selected-profile behavior.
- `disable_push_subscription(p_endpoint text)` disables only active subscriptions owned by the current `auth.uid()` and endpoint.
- No public push RPC accepts an arbitrary frontend actor profile id.
- `send-push-notifications` resolves profile recipients to active linked auth users and sends only to active subscriptions.

Privacy:
- Notification payloads remain fixed server-side by type and return no normal CP, `member_cp`, `cp_snapshots`, email, auth IDs, service-role data in frontend, admin/private metadata, or audit-private metadata.
- Frontend push paths remain RPC-only.

Validation:
- Local reset applied the migration cleanly.
- Full local validation passed; Milestone 29E.4 block reported `12 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000500_active_profile_push_notifications.sql`; production migration is applied and remote migration list shows it applied.
- Production verification confirmed the auth owner column/FK, push RLS/no broad direct grants, five authenticated push RPC grants, active Owner count `1`, and normal CP direct-read protection.

## Milestone 29E.3 Active Profile 3v3 Team Finder RLS/RPC

Milestone 29E.3 3v3 Team Finder active-profile migration is implemented, locally validated, and production applied through `20260531000400_active_profile_three_v_three.sql`.

RPCs:
- `update_my_discord_username(p_discord_username text)`
- `update_my_3v3_combined_cp(p_combined_cp bigint)`
- `create_3v3_team(p_team_name text, p_combined_cp bigint)`
- `get_3v3_teams()`
- `get_my_3v3_status()`
- `request_join_3v3_team(p_team_id uuid, p_combined_cp bigint)`
- `cancel_3v3_request(p_request_id uuid)`
- `approve_3v3_request(p_request_id uuid)`
- `decline_3v3_request(p_request_id uuid)`
- `remove_3v3_member(p_team_id uuid, p_profile_id uuid)`
- `disband_3v3_team(p_team_id uuid)`
- `close_3v3_team(p_team_id uuid)`
- `reopen_3v3_team(p_team_id uuid)`

RPC security:
- All 13 public 3v3 RPCs use `private.get_active_profile_id()` for actor/viewer identity.
- No migrated 3v3 RPC accepts an arbitrary frontend actor profile id.
- Existing 3v3 eligibility, ownership, slot, membership, cooldown, and owner-only rules remain backend-enforced.
- Public 3v3 Combined CP remains self-entered 3v3 data and is separate from protected normal CP.

Privacy:
- 3v3 payloads return safe public team/profile/Discord/public 3v3 CP/cosmetic fields only.
- No normal CP, `member_cp`, `cp_snapshots`, email, auth IDs, service-role data, admin/private metadata, or audit-private metadata is returned.

Validation:
- Local reset applied the migration cleanly.
- Full local validation passed; Milestone 29E.3 block reported `17 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000400_active_profile_three_v_three.sql`; production migration is applied and remote migration list shows it applied.
- Production verification confirmed active-profile RPC bodies, RLS enabled on all 3v3 tables, no broad direct 3v3 table grants, active Owner count `1`, safe 3v3 payloads, and normal CP direct-read protection.

## Milestone 29E.1 Active Profile Profile/Cosmetics RLS/RPC

Milestone 29E.1 Own Profile + Cosmetics active-profile migration is implemented, locally validated, and production applied through `20260531000200_active_profile_profile_cosmetics.sql`.

RPCs:
- `get_my_active_profile_details()`
- `update_my_active_profile(p_ign text)`
- `get_my_active_cosmetics()`
- `equip_my_active_avatar(p_avatar_key text)`
- `equip_my_active_frame(p_frame_key text)`

RPC security:
- All five RPCs use `private.get_active_profile_id()` and accept no arbitrary actor/target profile id.
- Detail/update RPCs require an approved active profile.
- Cosmetics read/equip requires approved active membership for the selected active profile.
- Avatar/frame equip still requires free-or-unlocked cosmetics for the selected active profile.
- Active equip writes update only `profile_equipped_cosmetics` for the selected active profile; avatar sync writes only that active profile.
- Audit rows for active cosmetics equip use the active profile as actor/target.

Privacy:
- Active Profile/Cosmetics payloads return safe profile/guild/status/cosmetic fields only.
- No normal CP, `member_cp`, `cp_snapshots`, email, auth IDs, service-role data, admin/private metadata, or audit-private metadata is returned.
- CP get/submit remains legacy-own only and is not active-profile migrated in this milestone.

Validation:
- Local reset applied the migration cleanly.
- Full local validation passed; Milestone 29E.1 block reported `10 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000200_active_profile_profile_cosmetics.sql`; production apply passed and remote migration list shows it applied.

## Milestone 29B Account Switcher RLS/RPC

Milestone 29B Account Switcher backend foundation is implemented, locally validated, and production applied through `20260531000100_account_switcher_foundation.sql`.

Tables:
- `user_profile_links`
- `user_active_profiles`

RLS/grants:
- RLS is enabled on both account-link tables.
- Direct anon/authenticated table grants are revoked.
- Clients must use the switcher/link-management RPCs; no direct table access is allowed.

RPC security:
- `get_my_switchable_profiles()` returns only profiles actively linked to `auth.uid()`.
- `get_my_active_profile()` returns the selected linked profile, or the legacy self profile when no active row exists.
- `set_my_active_profile(p_profile_id uuid)` requires an active link for the signed-in auth user.
- Owner-only link/unlink RPCs resolve by auth email plus profile slug/username and do not expose auth secrets.
- Disabled links are denied.

Privacy:
- Switcher payloads include safe profile/guild/cosmetic/status fields only.
- No CP values, `member_cp`, `cp_snapshots`, email, password/auth secrets, audit/admin/private metadata, or service-role data are returned.

Validation:
- Local DB reset passed.
- Full local validation passed; Milestone 29B account switcher block reported `19 PASS / 0 FAIL / 0 SKIP`.
- Production dry-run showed only `20260531000100_account_switcher_foundation.sql`; production apply passed.
- Production verification confirmed table existence, RLS, no direct account-link table grants, five public switcher RPCs with authenticated execute grants, self-links for all current profiles, active Owner count `1`, and normal CP direct reads still returning no visible rows for a member-context check.

## Milestone 28 Push Notifications RLS/RPC

Milestone 28 Push Notifications is implemented, locally validated, production applied, and production-smoke verified through `20260530000800_push_notifications_foundation.sql` plus the deployed `send-push-notifications` Edge Function.

Tables:
- `push_subscriptions`
- `push_notification_preferences`
- `push_notification_outbox`

RLS/grants:
- RLS is enabled on all push tables.
- Direct anon/authenticated table grants are revoked.
- Frontend reads/writes should use only the public push RPCs.
- Outbox writes are internal/private helper-driven; clients cannot direct-write arbitrary notification payloads.

RPC security:
- All public push RPCs use `auth.uid()`.
- Registration, preference reads/updates, and self-test enqueue require an approved profile with active primary guild membership and roster status `active`, `trial`, or `pending_transfer`.
- Pending/rejected/suspended/left/kicked/inactive/on_break users are denied.
- `disable_push_subscription` only disables endpoints owned by the authenticated profile.

Privacy:
- Notification payloads are fixed server-side by notification type.
- Payloads must not include CP values, `member_cp`, `cp_snapshots`, email, auth IDs, audit/admin/private metadata, or arbitrary user content.
- The Edge Function sender reads only outbox/subscription rows server-side and does not expose service-role access to the frontend.

Validation:
- Local reset applied the migration cleanly.
- Full local validation passed; Milestone 28B push block reported `13 PASS / 0 FAIL / 0 SKIP`.
- Source sweep found no normal CP table/RPC paths in the new migration or Edge Function.
- Production rollout passed after VAPID secrets were configured by name; secret values are not documented.

## Ghoul Rep Wall Reaction RLS/RPC

Ghoul Rep backend support is implemented, locally validated, and production applied through `20260530000400_ghoul_rep_wall_reactions.sql`.

RPCs/helpers:
- `private.get_profile_ghoul_rep(p_profile_id uuid)` is private and not executable by authenticated clients.
- `get_guild_wall_feed(...)` remains the Wall feed read path and now returns `author_ghoul_rep`.
- `get_wall_reaction_details(p_target_type, p_target_id, p_reaction_type)` is the safe reaction-detail read path for future hover/tap UI.

Access rules:
- Reaction detail reads require the same Guild Wall view authorization as feed reads.
- Approved users can read safe reaction details only for visible Guild Wall or Global Wall targets.
- Wrong-guild users are denied guild-scoped reaction details.
- Pending/restricted users are denied.
- Global Wall reaction details are visible to approved users according to Global Wall view rules.

Privacy:
- Reaction details return safe public profile/cosmetic fields only: IGN, username/profile slug, guild, avatar/frame asset fields, reaction type, and reaction timestamp.
- No email, auth metadata, CP, audit/admin/private metadata, `member_cp`, or `cp_snapshots` are returned.

Validation:
- Local Guild Wall/Ghoul Rep validation passed `47 PASS / 0 FAIL / 0 SKIP`.
- Production verification confirmed authenticated execute grant on `get_wall_reaction_details`, no authenticated execute on the private helper, Wall RLS/no direct client grants, no CP references in installed Ghoul Rep functions, Owner Global feed read, and active Owner count `1`.

## Milestone 25B 3v3 Team Finder RLS/RPC

Milestone 25B is implemented and locally validated only. Staging and production do not have `20260528000100_three_v_three_team_finder.sql` yet.

Migration:
- `20260528000100_three_v_three_team_finder.sql`

New RPC-only tables:
- `three_v_three_player_profiles`
- `three_v_three_teams`
- `three_v_three_team_members`
- `three_v_three_join_requests`

RLS/grants:
- RLS is enabled on all new 3v3 tables.
- Direct anon/authenticated table grants are revoked.
- Future frontend reads/writes should use only the 3v3 RPCs.
- Validation confirmed direct authenticated reads/writes on the new tables are denied.

RPC security:
- All public 3v3 RPCs use `auth.uid()` and accept no arbitrary actor profile id.
- 3v3 browse/status RPCs allow approved active-membership users, including `inactive` and `on_break`, to view.
- Team create and join-request RPCs require action-eligible roster status: `active`, `trial`, or `pending_transfer`.
- Pending, suspended, left, and kicked users are denied.
- Team owner-only actions are enforced for approve, decline, remove member, close, reopen, and disband.
- Request approval fills the first empty slot transactionally, cancels the accepted requester's other pending requests, and updates team status.

3v3 CP boundary:
- `combined_cp` is a public, self-entered 3v3 Team Finder value.
- It is separate from protected normal account CP.
- The 3v3 backend must not read or expose `member_cp`, `cp_snapshots`, CP analytics, CP roster, or CP leaderboard data.

Validation:
- Local Supabase reset passed.
- Local validation passed with Milestone 25B result: 45 PASS / 0 FAIL / 0 SKIP.

## Milestone 24B Admin Analytics RLS/RPC

Milestone 24B/24E Admin Analytics is implemented, locally validated, staging validated, and production applied/verified.

Migration:
- `20260526000100_admin_analytics_foundation.sql`

New RPC-only snapshot tables:
- `cp_snapshot_batches`
- `cp_snapshot_entries`

RLS/grants:
- RLS is enabled on both new snapshot tables.
- No direct anon/authenticated table grants are provided.
- Snapshot capture and reads are RPC-only.
- Production verification confirmed direct authenticated reads of the new snapshot tables are denied.
- Production snapshot capture mutation smoke was not performed by design; explicit approval is required before creating production snapshot rows.

Analytics RPCs:
- `get_admin_member_analytics(p_guild_id uuid default null)`
- `get_admin_cp_analytics(p_guild_id uuid default null)`
- `get_admin_gvg_analytics(p_guild_id uuid default null)`
- `capture_weekly_cp_snapshot(p_guild_id uuid default null)`
- `get_admin_cp_snapshot_history(p_guild_id uuid default null)`
- `get_admin_cp_growth_report(p_guild_id uuid default null, p_snapshot_id uuid default null)`

Security:
- Members and pending users are denied Admin Analytics.
- Wrong-guild staff are denied scoped analytics.
- CP Analytics and Weekly Growth require backend-enforced scoped `view_cp`.
- Admins without `view_cp` receive no CP values, growth values, or snapshot data.
- Owner can use global analytics; scoped staff must request an authorized guild scope.

## Milestone 23D Premium Cosmetics Production RLS/RPC

Milestone 23D is applied and verified in production.

Migration:
- `20260525000300_premium_cosmetics_grant_helper.sql`

Production behavior:
- All current frame catalog rows are `unlock_type = 'free'`.
- Future premium avatars and frames should use `unlock_type = 'manual'`.
- `get_my_cosmetics()` returns avatar unlock metadata.
- `equip_my_avatar(...)` requires active free avatar or caller-owned unlock row for manual avatars.
- `update_my_profile(...)` applies the same manual-avatar lock rule.
- `admin_grant_cosmetic_by_slug(...)` grants by exact username/profile slug through the existing grant authority path.

Production verification:
- RPC and function definitions are present.
- Direct authenticated insert/write grants to cosmetics unlock/equipped tables remain absent.
- Normal Member grant attempt was denied.
- Active Owner count remains `1`.

## Milestone 23B Premium Cosmetics / Grant Helper RLS/RPC

Milestone 23B was implemented and locally validated, then applied to staging in Milestone 23C and production in Milestone 23D.

Migration:
- `20260525000300_premium_cosmetics_grant_helper.sql`

Rules:
- Current frame catalog rows are updated to `unlock_type = 'free'`.
- Future premium avatars and frames use `unlock_type = 'manual'`.
- Catalog `unlock_type` remains the runtime source of truth.
- `_FREE` suffixes remain an asset/import convention only.

Member-safe RPC behavior:
- `get_my_cosmetics()` now reports avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(text)` now requires an active free avatar or an active manual avatar with a caller-owned unlock row.
- `equip_my_frame(text)` remains compatible and already requires free or caller-owned unlock state.
- `update_my_profile(p_ign, p_avatar_key)` now applies free-or-unlocked validation for non-empty avatar keys.

Admin grant helper:
- `admin_grant_cosmetic_by_slug(text, text, text)` looks up targets by exact normalized `profile_slug` or `username`, not IGN.
- It delegates permission, active-membership, idempotent unlock, and audit behavior to `admin_grant_cosmetic(...)`.
- Execute is granted to `authenticated`, but normal members and admins without existing member-management authority are denied.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.

## Milestone 22B Cosmetics Catalog / Unlocks RLS/RPC

Milestone 22B backend is implemented and locally validated. Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified through Milestones 22D and 22E.

New tables:
- `cosmetic_catalog`
- `profile_cosmetic_unlocks`
- `profile_equipped_cosmetics`

RLS/grants:
- RLS is enabled on all three cosmetics tables.
- Active catalog rows are readable by authenticated approved users with active primary membership.
- Unlock/equipped rows are readable only by their owning profile.
- Direct client writes are not granted to catalog, unlock, or equipped tables.
- Member writes use RPCs only.

Member-safe RPCs:
- `get_available_avatars()` returns active avatar catalog rows only.
- `get_my_cosmetics()` returns the caller's equipped keys plus active avatar/frame catalog data, with frame unlock booleans scoped to the caller.
- `equip_my_avatar(text)` validates active avatar keys and updates only `auth.uid()`.
- `equip_my_frame(text)` validates active frame keys and requires `unlock_type = 'free'` or a caller-owned unlock row.

Admin grant RPC:
- `admin_grant_cosmetic(uuid, text, text)` validates the target member's active primary guild and uses existing member-management authority: Owner, scoped Leader/Vice, or scoped Admin with `manage_members`.
- Normal Members cannot grant cosmetics, including to themselves.

Legacy avatar hardening:
- `update_my_profile(p_ign, p_avatar_key)` rejects arbitrary non-empty avatar keys. Keys must match an active `avatar` row in `cosmetic_catalog`.

Asset/security boundary:
- Database stores keys and static asset paths only.
- Asset paths are constrained to `/cosmetics/avatars/*.png|webp` or `/cosmetics/frames/*.png|webp`.
- `_FREE` suffixes are an asset/import convention and are mapped to `unlock_type = 'free'`.
- Current seed rows match actual local assets: 54 free avatars and 10 frames.
- Current non-`_FREE` frames use `unlock_type = 'manual'` and require unlock rows.
- Runtime equip checks use catalog `unlock_type` as source of truth.
- No player uploads, arbitrary URLs, Supabase Storage, service role usage, or CP/GvG/audit/role/permission/member-status behavior changes were introduced.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.
- Catalog asset-path verification checked 64 rows with 0 missing files and 0 unlock mapping problems.
- Milestone 22E production verification passed for cosmetics tables, RLS, catalog counts, exact repo asset-path match, RPC existence/grants, direct-write denial, active Owner count `1`, and `update_my_profile(...)` avatar hardening.

## Milestone 21E Rank Badge Summary RPC

Milestone 21B backend is implemented and locally validated. `20260524000400_cp_rank_badge_summary.sql` is applied and verified in staging through Milestone 21D and production through Milestone 21E.

New RPC:
- `get_my_cp_rank_summary()`

Member-safe behavior:
- Uses `auth.uid()` and accepts no profile id parameter.
- Requires an approved profile with active primary membership.
- Returns only the caller's own `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Does not return CP values, updated timestamps, growth/history/snapshot data, updated-by metadata, usernames, profile ids, other-member data, or private metadata.
- `inactive` and `on_break` callers with active approved membership receive the unranked/default state instead of CP data.
- Hard-blocked users without active approved membership are denied by the same membership gate.

Roster/ranking rules:
- Rank summary uses the same eligible row set as `get_member_cp_rankings`: approved active primary memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking excludes `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- Ranks use deterministic `row_number()` order by `cp_value desc`, then IGN/profile tie-breaker.

Direct table access:
- No direct `member_cp` or `cp_snapshots` grants/policies were broadened.
- Existing CP Ranking, CP Update Window, admin CP roster/update, audit, GvG, role, permission, and member-status behavior is preserved.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.

## Milestone 20B CP Ranking RPCs

Milestone 20B is implemented and locally validated. `20260524000300_cp_rankings.sql` is applied and verified in staging as of Milestone 20E and production as of Milestone 20F.

New RPCs:
- `get_member_cp_rankings(p_scope text default 'guild')`
- `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`

Member-safe RPC behavior:
- `get_member_cp_rankings(...)` uses `auth.uid()` and requires an approved profile with active primary membership.
- Members can request only `guild` or `global` rank scopes.
- Guild scope uses the caller's active primary guild.
- Global scope returns safe rank order across eligible approved active roster members in all active guilds.
- Return shape is limited to `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- The member RPC does not return CP values, profile ids, usernames, updated timestamps, snapshots, growth, audit metadata, or other private CP data.

Admin RPC behavior:
- `get_admin_cp_rankings(...)` uses `auth.uid()`.
- Guild scope requires existing scoped `private.can_view_cp(actor_id, guild_id)` authority.
- Global scope is Owner-only in v1.
- Admin response can include CP values only after permission checks pass.
- Normal members and Admins without scoped `view_cp` are denied.

Roster/ranking rules:
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- Ranks use deterministic `row_number()` order by `cp_value desc`, then IGN/profile tie-breaker.

Direct table access:
- No direct `member_cp` or `cp_snapshots` grants/policies were broadened.
- Members still cannot directly read CP tables.
- Existing CP Update Window and admin CP roster/update RPC behavior is preserved.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 20B focused validation result: 14 PASS / 0 FAIL / 0 SKIP.

## Milestone 19B / 19B.1 CP Update Window RLS/RPC

Milestone 19B and 19B.1 are implemented, locally validated, staging validated, and production applied/verified as of Milestone 19E.

New table:
- `public.cp_update_windows`

RLS/grants:
- RLS is enabled.
- Direct table grants are revoked from `public`, `anon`, and `authenticated`.
- No direct client SELECT/INSERT/UPDATE/DELETE policies are exposed.
- Staff and member access is RPC-only.

Member-safe RPCs:
- `get_active_cp_update_window_for_me()` returns only safe own-guild window status, server time, `can_submit`, and a reason code.
- `get_my_cp()` returns only the caller's own current CP in their active primary guild.
- `submit_my_cp_update(p_cp_value integer)` updates only the caller's own CP after database-side eligibility and open-window checks.

Staff RPCs:
- `open_cp_update_window(...)` and `close_cp_update_window(...)` require `private.can_update_cp(actor_id, guild_id)`.
- That preserves the existing CP authority model: Owner globally, Leader/Vice in scope, and Admin only with scoped `update_cp`.
- `get_cp_update_window_for_guild(p_guild_id uuid)` lets authorized staff read safe selected-guild window status.
- Staff window reads allow Owner, scoped Leader/Vice, and scoped Admin with `view_cp` or `update_cp`.

Security behavior:
- Members cannot directly read `member_cp`, `cp_snapshots`, or `cp_update_windows`.
- Frontend disabled controls are UX only; the RPCs enforce open-window timing, guild scope, roster eligibility, and self-only CP update rules.
- Audit redaction includes `member_cp_self_submitted` rows so users without scoped `view_cp` do not see `cp_old` or `cp_new`.

Validation:
- Local Supabase reset passed.
- Local validation script passed Milestone 19B checks with 32 PASS / 0 FAIL / 0 SKIP.
- Local validation script passed Milestone 19B.1 checks with 13 PASS / 0 FAIL / 0 SKIP.

## Production Deployment Reminder

Production is live through Milestone 21E. CP Leaderboard / CP Ranking and Rank Badge / Profile Border are applied, deployed, and smoke-validated in production.

Future production setup must:
- Apply migrations in documented timestamp order.
- Verify RLS is enabled on protected tables.
- Verify policies, functions, grants, constraints, and indexes.
- Keep CP access RPC/RLS-enforced.
- Keep audit reads on `public.get_audit_logs(...)`.
- Keep direct non-Owner `audit_logs` reads hardened.
- Never run `supabase db reset` on production.
- Never run local fake-user validation SQL on production.

## Milestone 15A Member Status RLS/RPC

Milestone 15A adds backend-only Member Status support.

New table:
- `public.member_status_history`

RLS:
- Members cannot directly read private status reasons/history.
- Scoped staff can read status history when they are Owner, scoped Leader/Vice, or Admin with `manage_members`.
- No direct client insert/update/delete policies exist for `member_status_history`.

New RPC:
- `public.update_member_roster_status(p_membership_id uuid, p_new_status text, p_reason text default null)`

Security behavior:
- Status writes must use the RPC.
- Owner can set all statuses globally, with last-active-Owner protection.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only `active`, `trial`, `inactive`, `on_break`, and `pending_transfer`.
- Members cannot change status.
- `suspended`, `left`, and `kicked` are hard blocks through `membership_status`.
- `kicked` maps to `membership_status = 'left'`; `rejected` remains reserved for registration/reapply.
- `inactive` and `on_break` preserve active membership but are excluded from GvG event visibility/voting.

Validation:
- Local Supabase reset passed.
- Local validation script passed Milestone 15A checks with 22 PASS / 0 FAIL / 0 SKIP.

## Milestone 11A Audit Log Read Hardening

Audit log reads now go through a safe RPC for frontend use:

- `public.get_audit_logs(...)`

Direct non-Owner `audit_logs` SELECT is restricted by the new owner-only direct SELECT policy. This prevents scoped staff with `view_audit_logs` from bypassing SQL-side metadata redaction.

Audit visibility remains database-enforced:
- Owner can read global audit logs.
- Leader/Vice can read scoped guild audit logs.
- Admin can read scoped audit logs only with `view_audit_logs`.
- Member and pending users cannot read audit logs.

CP metadata redaction:
- Audit entries that contain CP-sensitive metadata are redacted unless the viewer also passes `private.can_view_cp(actor_id, guild_id)`.
- Redacted metadata removes CP values and CP update notes, then adds `cp_metadata_redacted = true`.
- Redaction happens in SQL/RPC, not in frontend code.

Validation:
- Local Supabase reset passed.
- Local validation script passed Milestone 11A checks with 14 PASS / 0 FAIL / 0 SKIP.

## Milestone 8 CP RPC Hardening

CP remains RPC-only.

Hardened RPC behavior:
- `update_member_cp` rejects pending, rejected, suspended, and otherwise non-approved profiles.
- `update_member_cp` still requires `private.can_update_cp`.
- `get_current_cp_roster` still requires `private.can_view_cp`.
- Direct `member_cp` and `cp_snapshots` table access remains blocked by RLS/policies.

No direct CP table policies were broadened.

## Milestone 7 RPC Strategy

Milestone 7 keeps direct table writes blocked for member guild and role management. Sensitive changes use RPCs:

- `public.assign_member_role(p_profile_id uuid, p_guild_id uuid, p_role text)`
- `public.transfer_member_guild(p_profile_id uuid, p_from_guild_id uuid, p_to_guild_id uuid)`

RLS policy broadening is not required for frontend writes because these operations are handled by permission-checked `SECURITY DEFINER` RPCs with fixed `search_path`.

No CP or GvG RLS policies were changed.

Milestone 2 RLS direction was implemented in Supabase migrations and has been locally validated. Later milestones add focused RPC/RLS hardening migrations on top of that baseline.

## Global Rules

- `auth.uid()` should match `profiles.id`.
- Pending/rejected users can read only their own safe profile/approval/reapply state.
- Members must never directly select CP tables.
- Frontend hiding is not security.
- Role and permission checks must be database-side for sensitive access.
- Avoid direct table writes for sensitive actions; prefer permission-checked RPCs.
- No hard deletes for important records where status/archive can be used.

## Table Strategy

### `profiles`

- SELECT: own row for pending/rejected users; safe same-guild approved profiles for approved members; scoped admin/leader access; Owner all.
- INSERT: registration trigger/RPC only, with `id = auth.uid()`.
- UPDATE: users can update own IGN/avatar only through controlled path; slug/username reset requires Owner, scoped Leader/Vice, or Admin with `reset_profile_slug`.
- DELETE: no client delete.

### `guilds`

- SELECT: core active guild names can be public/visible for registration.
- INSERT/UPDATE: Owner or approved management RPC only.
- DELETE: no client delete; archive/status instead.

### `guild_memberships`

- SELECT: own membership; safe same-guild membership info for approved users; scoped Leader/Vice/Admin; Owner all.
- INSERT/UPDATE: approval and role-management RPCs only.
- DELETE: no client delete; status changes instead.
- v1 must enforce one active primary membership per profile with a database constraint/index.

### `permission_catalog`

- SELECT: authenticated approved users may read permission labels if needed for UI; public access is not required.
- INSERT/UPDATE/DELETE: migration/Owner-controlled only.

### `admin_permissions`

- SELECT: Admin can read own grants; Leader/Vice can read scoped guild grants; Owner all.
- INSERT/DELETE: grant/revoke RPC only.
- UPDATE: avoid; revoke and re-grant.
- Owner only can grant/revoke `view_cp` and `update_cp` to Admins in v1.

### `member_cp`

- SELECT: no direct member access; preferably no broad direct client select at all.
- INSERT/UPDATE: `update_member_cp` RPC only.
- DELETE: no client delete.
- Owner has global access through RPC/views.
- Leader/Vice have automatic CP view/update inside assigned guild through RPC/views.
- Admin requires explicit `view_cp` and/or `update_cp`.

### `cp_snapshots`

- SELECT: no direct member access; authorized RPC/views only.
- INSERT: manual weekly snapshot RPC only.
- UPDATE/DELETE: no client access.
- Same CP permission model as `member_cp`.

### `gvg_events`

- SELECT: approved users can read active events in their guild plus global active events.
- INSERT/UPDATE: Owner globally; Leader/Vice in assigned guild; Admin with `manage_gvg`.
- DELETE: no client delete; close/cancel/archive instead.

### `gvg_votes`

- SELECT: member can read own vote; authorized leaders/admins can read scoped results and absence reasons.
- INSERT/UPDATE: current authenticated user only, event active only, user in event scope.
- DELETE: no client delete.
- v1 does not allow admins/leaders to edit or remove member votes.

### `audit_logs`

- SELECT: Owner all; Leader/Vice scoped guild logs by default; Admin only with `view_audit_logs`.
- INSERT: trusted RPCs/triggers only.
- UPDATE/DELETE: never through client.

## Required Helper Checks

- `is_owner(actor_id)`
- `has_active_membership(actor_id, guild_id)`
- `has_role(actor_id, guild_id, roles)`
- `has_permission(actor_id, guild_id, permission_key)`
- `can_view_cp(actor_id, guild_id)`
- `can_update_cp(actor_id, guild_id)`
- `can_reset_profile_slug(actor_id, target_id)`
- `can_edit_member_ign(actor_id, target_id)`

Security definer functions must set a fixed `search_path`, validate the caller internally, and avoid recursive RLS pitfalls.
