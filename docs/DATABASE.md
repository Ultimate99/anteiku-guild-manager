# Database

The Supabase schema/RLS/RPC migrations for Anteiku Guild Manager have been implemented through the Weekly Growth baseline scope fix. Remote production is live through `20260526000300_live_cp_growth_baseline_scope.sql`.

Production deployment must follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

Milestone 25B 3v3 Team Finder backend is implemented and locally validated only. Staging and production do not have `20260528000100_three_v_three_team_finder.sql` yet.

## Current Local Migration Order

1. `20260514000100_core_schema.sql`
2. `20260514000200_constraints_indexes.sql`
3. `20260514000300_private_helper_functions.sql`
4. `20260514000400_seed_core_data.sql`
5. `20260514000500_rls_policies.sql`
6. `20260514000600_public_rpc_functions.sql`
7. `20260515000100_member_guild_role_management.sql`
8. `20260515000200_cp_rpc_hardening.sql`
9. `20260515000300_audit_log_read_hardening.sql`
10. `20260523000100_member_roster_status_system.sql`
11. `20260524000100_cp_update_window_self_submit.sql`
12. `20260524000200_cp_update_window_staff_read.sql`
13. `20260524000300_cp_rankings.sql`
14. `20260524000400_cp_rank_badge_summary.sql`
15. `20260525000100_cosmetics_catalog_unlocks.sql`
16. `20260525000200_cp_rankings_cosmetics.sql`
17. `20260525000300_premium_cosmetics_grant_helper.sql`
18. `20260525213531_cosmetics_catalog_sync.sql`
19. `20260525213537_cosmetics_catalog_sync.sql`
20. `20260525213900_cosmetics_catalog_sync.sql`
21. `20260525220522_cosmetics_frame_unlock_hotfix.sql`
22. `20260526000100_admin_analytics_foundation.sql`
23. `20260526000200_live_cp_growth.sql`
24. `20260526000300_live_cp_growth_baseline_scope.sql`
25. `20260528000100_three_v_three_team_finder.sql`

Migration `20260523000100_member_roster_status_system.sql` is locally validated, staging validated, and production applied/verified as of Milestone 15E.

Migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql` are locally validated, staging validated, and production applied/verified.

Migration `20260524000300_cp_rankings.sql` is locally validated, staging validated, and production applied/verified.

Migration `20260524000400_cp_rank_badge_summary.sql` is locally validated, staging validated, and production applied/verified.

Migration `20260525000100_cosmetics_catalog_unlocks.sql` is locally validated, staging validated, and production applied/verified as of Milestone 22E.

Migration `20260525000200_cp_rankings_cosmetics.sql` is production applied/verified as part of the leaderboard cosmetic display rollout.

Migration `20260525000300_premium_cosmetics_grant_helper.sql` is implemented, locally validated, staging validated, and production applied/verified as of Milestone 23D.

Migration `20260526000100_admin_analytics_foundation.sql` is implemented, locally validated, staging validated, and production applied/verified as of Milestone 24E. It adds `cp_snapshot_batches`, `cp_snapshot_entries`, Admin Analytics RPCs, and manual Weekly Growth RPCs for AdminPanel Analytics.

Migration `20260526000200_live_cp_growth.sql` is implemented, locally validated, and production applied/verified. It adds live current-minus-baseline Weekly Growth RPC support, Sunday-baseline start-week capture, and compatibility delegation for `capture_weekly_cp_snapshot(...)`.

Migration `20260526000300_live_cp_growth_baseline_scope.sql` is implemented, locally validated, and production applied/verified. It adds an overload for `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)` so Owner can preserve a selected Global baseline while filtering live growth rows to a guild scope.

Cosmetics catalog sync migrations `20260525213531`, `20260525213537`, and `20260525213900` are applied in production. Migration `20260525220522_cosmetics_frame_unlock_hotfix.sql` is applied in production and corrects frame unlock types so only `TXK_Arena*` and `TXK_KOF*` frames are manual while all other frames are free.

Migration `20260528000100_three_v_three_team_finder.sql` is locally implemented/validated only. It adds 3v3 Team Finder backend tables and RPCs and requires a separate staging/production rollout gate before any frontend 3v3 UI deployment.

## Milestone 25B 3v3 Team Finder Backend

Migration:
- `supabase/migrations/20260528000100_three_v_three_team_finder.sql`

New tables:
- `three_v_three_player_profiles`
- `three_v_three_teams`
- `three_v_three_team_members`
- `three_v_three_join_requests`

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

Rules:
- Teams are global across guilds.
- Team creator fills slot 1.
- Team names are immutable.
- One active owned team and one active team membership are enforced per player.
- Requests enforce one pending request per player/team, max two attempts, and a six-hour cooldown after declined requests.
- Accepted requests cancel the requester's other pending requests.
- `inactive` and `on_break` users can view teams but cannot create/request.
- Pending, suspended, left, and kicked users are denied.

3v3 Combined CP:
- Public self-entered value for 3v3 Team Finder only.
- Separate from protected normal CP.
- Does not use `member_cp` or `cp_snapshots`.

Validation:
- `npx.cmd supabase db reset` passed locally.
- `supabase/tests/local_validation_anteiku.sql` passed through Docker `psql`.
- Milestone 25B result: 45 PASS / 0 FAIL / 0 SKIP.

## Milestone 24B Admin Analytics Backend

Migration:
- `supabase/migrations/20260526000100_admin_analytics_foundation.sql`

New tables:
- `cp_snapshot_batches`
- `cp_snapshot_entries`

New RPCs:
- `get_admin_member_analytics(p_guild_id uuid default null)`
- `get_admin_cp_analytics(p_guild_id uuid default null)`
- `get_admin_gvg_analytics(p_guild_id uuid default null)`
- `capture_weekly_cp_snapshot(p_guild_id uuid default null)`
- `get_admin_cp_snapshot_history(p_guild_id uuid default null)`
- `get_admin_cp_growth_report(p_guild_id uuid default null, p_snapshot_id uuid default null)`

Status:
- Locally implemented/validated, staging validated, and production applied/verified.
- Existing `cp_snapshots` and older CP snapshot/growth RPCs are preserved.
- Snapshot batch tables are RPC-only with RLS enabled and no direct client grants.
- Production Owner smoke passed for AdminPanel Analytics Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Production snapshot capture mutation smoke was not performed by design; require explicit approval before creating production snapshot rows.

## Live CP Growth Backend

Migration:
- `supabase/migrations/20260526000200_live_cp_growth.sql`

RPCs:
- `get_admin_live_cp_growth(p_guild_id uuid default null)`
- `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)`
- `start_new_cp_growth_period(p_guild_id uuid default null, p_label text default null)`

Compatibility:
- `capture_weekly_cp_snapshot(p_guild_id uuid default null)` now delegates to `start_new_cp_growth_period(...)`.

Behavior:
- Live Growth is calculated as current `member_cp.cp_value` minus the latest baseline snapshot value for the selected Analytics scope.
- If a baseline batch id is explicitly selected, Live Growth uses that baseline when backend scoping permits it.
- Owner can use a Global baseline while filtering rows to a selected guild scope.
- Scoped staff cannot use Global baselines for guild analytics.
- Reset day is Sunday.
- Starting a new CP week captures baseline CP values into `cp_snapshot_batches` / `cp_snapshot_entries`; it does not reset player CP.
- Owner can use global scope. Scoped CP staff can use only authorized guild scope.
- No settings table was added in v1.

Security:
- Live Growth requires backend-enforced scoped `view_cp`.
- Members, pending users, admins without `view_cp`, and wrong-guild staff are denied.
- No direct client table grants were added for `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- Production Start New CP Week mutation smoke was not performed by design.
- Production baseline scope smoke confirmed Global and Anteiku both show `安定区×Ulti` growth `+5,002` from the same Global baseline without creating a new snapshot.

Production Member Status rollout:
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- Production smoke validation passed after frontend deployment.
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink before future staging/local Supabase commands.

Do not run `supabase db reset` against production. Do not run `supabase/tests/local_validation_anteiku.sql` against production because it inserts fake auth users and local test data.

## Milestone 22B Cosmetics Catalog / Unlocks Backend

New migration:
- `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`

Production status:
- Applied and verified in production through Milestone 22E.
- Production catalog contains 54 avatars and 10 frames.
- Production catalog asset paths exactly match the 64 repo files under `public/cosmetics/`.
- Active Owner count remained `1`.
- Direct unsafe anon/authenticated writes are not granted.

Adds:
- `cosmetic_catalog`
- `profile_cosmetic_unlocks`
- `profile_equipped_cosmetics`
- `get_available_avatars()`
- `get_my_cosmetics()`
- `equip_my_avatar(p_avatar_key text)`
- `equip_my_frame(p_frame_key text)`
- `admin_grant_cosmetic(p_profile_id uuid, p_cosmetic_key text, p_reason text default null)`

Seeded cosmetics:
- Avatars: 54 rows from `public/cosmetics/avatars/*.png`, all `unlock_type = 'free'`.
- Frames: 10 rows from `public/cosmetics/frames/*.png`.
- Default avatar: `1079_head`.
- Default frame: `TXK_frame_reOpen_EN_FREE`.
- `TXK_Arena*` and `TXK_KOF*` frames use `unlock_type = 'manual'`; all other current frames use `unlock_type = 'free'`.

Asset storage:
- Database stores keys and static asset paths only.
- Static assets are expected under `/cosmetics/avatars/` and `/cosmetics/frames/`.
- No uploads, arbitrary URLs, or Supabase Storage are introduced.
- Cosmetic keys ending `_FREE` are an asset/import convention and must map to `unlock_type = 'free'`.
- Frame families `TXK_Arena*` and `TXK_KOF*` are the current manual/locked frame families.
- Other frame families, including C-series frames, are free/unlocked.
- Runtime access uses catalog `unlock_type` as the source of truth, not filename parsing alone.
- Catalog asset paths were verified against local files: 64 rows checked, 0 missing files.

Security:
- RLS is enabled on all cosmetics tables.
- Members can read active catalog rows and their own unlock/equipped rows.
- Members equip only their own active avatars and own unlocked/free frames through RPCs.
- Members cannot grant cosmetics.
- Admin grants require existing scoped member-management authority.
- `update_my_profile(p_ign, p_avatar_key)` rejects arbitrary avatar keys and accepts only active catalog avatars.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.
- Catalog unlock mapping verification passed with 0 mapping problems.

Rollout:
- Staging and production both have this migration applied and verified.
- Future new target environments must apply and verify this migration before cosmetics UI is deployed there.

## Milestone 23B Premium Cosmetics / Grant Helper Backend

New migration:
- `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`

Status:
- Backend/database-only implementation complete.
- Existing deployed migration `20260525000100_cosmetics_catalog_unlocks.sql` was not edited.
- Staging and production have received and verified this migration.

Changes:
- All currently existing frame catalog rows become `unlock_type = 'free'`.
- Current avatars remain free.
- Future premium avatars and frames should be inserted with `unlock_type = 'manual'`.
- `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(...)` requires active free avatar or active manual avatar with caller-owned unlock row.
- `update_my_profile(...)` applies the same free-or-unlocked avatar rule for non-empty avatar keys.
- `admin_grant_cosmetic_by_slug(...)` grants by exact username/profile slug and delegates authority/audit behavior to `admin_grant_cosmetic(...)`.

Security:
- Members cannot grant themselves cosmetics.
- Members cannot equip locked/manual avatars or frames without unlock rows.
- Invalid, inactive, and arbitrary cosmetic keys are denied.
- Grant lookup does not use IGN/display names.
- No uploads, arbitrary URLs, or Supabase Storage behavior is added.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.

## Cosmetics Frame Unlock Hotfix

New migration:
- `supabase/migrations/20260525220522_cosmetics_frame_unlock_hotfix.sql`

Status:
- Production applied and read-only verified.

Rule:
- `TXK_Arena*` frames are `unlock_type = 'manual'`.
- `TXK_KOF*` frames are `unlock_type = 'manual'`.
- All other frame rows are `unlock_type = 'free'`.
- Avatar premium/manual behavior is unchanged.

Production verification:
- Production dry-run showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Remote migration list confirmed `20260525220522` applied.
- Production catalog contains 20 frame rows: 7 Arena manual, 3 KOF manual, 10 other free, and 0 other locked.
- Active Owner count remains `1`.
- The migration does not delete catalog rows or mutate profile equipment.

## Milestone 22F Cosmetics Catalog Sync Script

Local developer tooling:
- Script: `scripts/sync-cosmetics-catalog.mjs`
- Command: `npm.cmd run cosmetics:sync`
- Dry-run: `npm.cmd run cosmetics:sync -- --dry-run`

Workflow:
1. Add approved `.png` or `.webp` assets under `public/cosmetics/avatars/` or `public/cosmetics/frames/`.
2. Run `npm.cmd run cosmetics:sync -- --dry-run`.
3. Review the SQL preview.
4. Run `npm.cmd run cosmetics:sync` to generate a timestamped migration under `supabase/migrations/`.
5. Review the generated migration.
6. Apply it only through normal staging and production migration dry-run/apply gates.

Generated catalog rules:
- Cosmetic key = filename without extension.
- Avatar asset path = `/cosmetics/avatars/<filename>`.
- Frame asset path = `/cosmetics/frames/<filename>`.
- Label key = `cosmetics.avatar.<key>` or `cosmetics.frame.<key>`.
- Keys ending `_FREE` use `unlock_type = 'free'`.
- Premium avatar keys use `unlock_type = 'manual'`; other avatar files without `_FREE` use `unlock_type = 'free'` for v1.
- Frame keys starting `TXK_Arena` or `TXK_KOF` use `unlock_type = 'manual'`.
- All other frame files use `unlock_type = 'free'`.
- `free` rows use `rarity = 'common'`; `manual` rows use `rarity = 'rare'`.
- Sort order is deterministic in increments of `10`: avatars first by filename, then frames by filename.

Safety:
- The script scans repo-backed files only.
- The script does not call Supabase, run migrations, deploy, add uploads, use Supabase Storage, or permit arbitrary URLs.
- Generated migrations upsert rows into `public.cosmetic_catalog` using `ON CONFLICT (key) DO UPDATE`.
- Generated migrations do not delete or deactivate missing catalog rows by default.
- Review generated migrations before applying because catalog `unlock_type` is the runtime authority.

## Milestone 20B CP Ranking Backend

New migration:
- `supabase/migrations/20260524000300_cp_rankings.sql`

Adds:
- `get_member_cp_rankings(p_scope text default 'guild')`
- `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`

Member-safe leaderboard behavior:
- Member rankings support `guild` and `global` scopes.
- Guild scope uses the caller's active primary guild.
- Global scope returns safe rank order across eligible approved active roster members in all active guilds.
- Member return shape is only `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member responses do not include CP values, profile ids, usernames, updated timestamps, snapshots, growth, audit metadata, or private CP fields.

Admin leaderboard behavior:
- Guild scope returns CP values only when the caller passes existing scoped CP view checks.
- Global scope is Owner-only in v1.
- Admin return shape includes rank, profile/user labels, guild labels, CP value, and updated timestamp.

Ranking rules:
- Ranks use deterministic `row_number()` ordering by `cp_value desc`, then IGN/profile tie-breaker.
- Rows include approved profiles with active memberships and roster status `active`, `trial`, or `pending_transfer`.
- Rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.

Security:
- No direct grants are added for `member_cp` or `cp_snapshots`.
- Existing CP Update Window and admin CP roster/update behavior is preserved.

## Milestone 21B CP Rank Badge Summary Backend

New migration:
- `supabase/migrations/20260524000400_cp_rank_badge_summary.sql`

Adds:
- `get_my_cp_rank_summary()`

Behavior:
- Returns only the signed-in user's own rank summary for future Profile/Dashboard badge visuals.
- Return shape is `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Does not return CP values, updated timestamps, growth/history/snapshot data, profile ids, usernames, other-member rows, or private metadata.
- Uses `auth.uid()` and accepts no target profile id parameter.

Tier rules:
- Global rank 1: `rank_one` / `rank_1`.
- Global rank 2: `rank_two` / `rank_2`.
- Global rank 3: `rank_three` / `rank_3`.
- Global ranks 4-5: `elite_five` / `elite_5`.
- Global ranks 6-10: `top_ten` / `top_10`.
- Global ranks 11-25: `high_rank`.
- Global rank 26+: `ranked_member`.
- No CP row or excluded roster state: `unranked`.

Security:
- Uses the same eligible row set as the member-safe CP leaderboard: approved active primary memberships with roster status `active`, `trial`, or `pending_transfer`.
- `inactive` and `on_break` receive the unranked/default state.
- Hard-blocked users remain denied by existing active approved membership gates.
- Direct `member_cp` and `cp_snapshots` access remains blocked.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.

## Milestone 19B CP Update Window Backend

New migration:
- `supabase/migrations/20260524000100_cp_update_window_self_submit.sql`

Adds:
- `cp_update_windows`
- `get_active_cp_update_window_for_me()`
- `get_my_cp()`
- `submit_my_cp_update(p_cp_value integer)`
- `open_cp_update_window(p_guild_id uuid, p_opens_at timestamptz default null, p_closes_at timestamptz default null, p_note text default null)`
- `close_cp_update_window(p_window_id uuid)`
- `get_cp_update_window_for_guild(p_guild_id uuid)` from Milestone 19B.1
- `member_cp_self_submitted`, `cp_update_window_opened`, and `cp_update_window_closed` audit actions.

Window behavior:
- CP Update Windows are guild-scoped.
- Only one open window can exist per guild.
- Opening/closing uses existing CP update authority: Owner, scoped Leader/Vice, or scoped Admin with `update_cp`.
- Window timing is checked using database/server time.

Member behavior:
- Members can read only their own CP through `get_my_cp()`.
- Members can submit only their own CP through `submit_my_cp_update(...)`.
- `active`, `trial`, and `pending_transfer` can submit while the guild window is open.
- `inactive` and `on_break` can read own CP but cannot submit.
- `suspended`, `left`, and `kicked` remain blocked.
- Members still cannot directly read or write `member_cp`, read `cp_snapshots`, or read `cp_update_windows`.

Audit/redaction:
- Member self-submit audit metadata includes old/new CP but `get_audit_logs(...)` redacts those values unless the viewer has scoped `view_cp`.

Rollout status:
- Local validation passed for Milestone 19B and 19B.1.
- Staging and production rollout passed through Milestone 19E.
- Frontend UI is live in production.

Staff selected-guild window read:
- `get_cp_update_window_for_guild(p_guild_id uuid)` lets AdminPanel read current/recent CP Update Window status for a selected guild.
- Owner, scoped Leader/Vice, and scoped Admin with `view_cp` or `update_cp` can read it.
- Members, Admin without CP permission, and wrong-guild users are denied.
- The RPC returns the open window first, then latest closed window, or no row if no window exists.

## Milestone 15A Member Status Backend

New migration:
- `supabase/migrations/20260523000100_member_roster_status_system.sql`

Adds:
- `guild_memberships.roster_status`
- `member_status_history`
- `public.update_member_roster_status(p_membership_id uuid, p_new_status text, p_reason text default null)`
- `member_roster_status_changed` audit log action

Roster statuses:
- `active`, `trial`, `inactive`, `on_break`, `suspended`, `left`, `kicked`, `pending_transfer`

Security mapping:
- `profiles.approval_status` remains the account/registration state.
- `guild_memberships.membership_status` remains the hard access/security state.
- `roster_status` is the lifecycle label.
- `inactive` and `on_break` keep active membership but are excluded from GvG event visibility/voting.
- `suspended` maps to `membership_status = 'suspended'`.
- `left` maps to `membership_status = 'left'`.
- `kicked` maps to `membership_status = 'left'`; `rejected` remains reserved for registration/reapply.

History/privacy:
- Members cannot directly read private status history/reasons.
- Scoped staff can read `member_status_history`.
- Status reasons are not placed in broadly visible audit metadata.

## Milestone 11A Audit Log Reader

New migration:
- `supabase/migrations/20260515000300_audit_log_read_hardening.sql`

Safe audit reader RPC:
- `public.get_audit_logs(p_guild_id uuid default null, p_action text default null, p_actor_id uuid default null, p_target_id uuid default null, p_from timestamptz default null, p_to timestamptz default null, p_limit integer default 50, p_before timestamptz default null)`

The RPC returns safe audit fields plus actor/target/guild labels:
- `id`, `created_at`, `action`, `entity_table`, `entity_id`
- `actor_profile_id`, `actor_username`, `actor_ign`
- `target_profile_id`, `target_username`, `target_ign`
- `guild_id`, `guild_name`, `guild_slug`
- `metadata`, `metadata_redacted`

Direct non-Owner table reads from `audit_logs` are restricted. Future audit UI must use the RPC so CP-sensitive metadata can be redacted in the database.

## Tables

- `profiles`: one row per Supabase Auth user, with `id uuid primary key references auth.users(id)`.
- `guilds`: core guilds and future subguilds.
- `guild_memberships`: profile-to-guild membership, role, hard membership status, roster lifecycle status, and primary membership.
- `permission_catalog`: approved Admin permission keys.
- `admin_permissions`: explicit Admin permission grants.
- `member_cp`: current CP values, protected from member reads.
- `cp_snapshots`: manual weekly CP history/growth.
- `gvg_events`: guild-specific and global GvG events.
- `gvg_votes`: one vote per user per event.
- `audit_logs`: trusted record of sensitive/admin actions.
- `member_status_history`: private staff-only status history/reasons.

## Key Decisions

- `profiles.id` directly maps to `auth.uid()`.
- `username` and `profile_slug` are identical at v1 registration.
- Username/profile slug are lowercase, unique, length 3-32, start alphanumeric, and do not end with hyphen/underscore.
- CP is never stored in `profiles`.
- Members must never directly select `member_cp` or `cp_snapshots`.
- v1 enforces one active primary guild membership per user.
- Core guild names can be visible during registration.
- Rejected users reapply using the same profile row.
- No public/self-service Owner creation.
- Important records should use status/archive instead of hard deletes.

## CP Tables

Current CP belongs in `member_cp`.

Manual weekly growth snapshots belong in `cp_snapshots`.

CP access must use permission-checked RPC/views:

- Owner: global view/update.
- Leader/Vice: automatic guild-scoped view/update.
- Admin: explicit `view_cp` and/or `update_cp`.
- Member: no CP access.

Owner only can grant Admin CP permissions in v1.

## Required Constraints

- Unique username/profile slug.
- Profile slug and username format checks.
- Unique active primary membership per profile.
- Unique membership per profile/guild.
- Unique Admin permission per membership/key.
- CP value `>= 0`.
- Unique CP snapshot per profile/guild/week.
- Unique GvG vote per event/profile.
- Absence reason max length.

## Local Validation Status

Local Supabase validation passed through Milestone 20B.

The validation confirmed that migrations apply locally, seed data exists, permission catalog rules are present, CP privacy is enforced by direct table denial and RPC checks, GvG vote integrity works, approval/reapply behavior is scoped, and audit spoofing is blocked.
Milestone 15A added 22 PASS / 0 FAIL / 0 SKIP focused checks for roster status, history privacy, status-change permissions, last active Owner protection, and GvG eligibility.
Milestone 19B added 32 PASS / 0 FAIL / 0 SKIP focused checks for CP Update Window RLS/RPC behavior, member own-CP read/submit, roster eligibility, audit creation, and CP metadata redaction.
Milestone 19B.1 added 13 PASS / 0 FAIL / 0 SKIP focused checks for staff selected-guild window status reads.
Milestone 20B added 14 PASS / 0 FAIL / 0 SKIP focused checks for member-safe CP rankings, admin CP rankings, rank ordering, roster inclusion/exclusion, permission denial, Owner-only global admin rankings, and direct CP table denial.
## Milestone 7 Backend Additions

New migration:
- `supabase/migrations/20260515000100_member_guild_role_management.sql`

Role assignment:
- `public.assign_member_role(p_profile_id uuid, p_guild_id uuid, p_role text)` is hardened for normal app role changes.
- Normal app RPC role assignment cannot assign `owner`.
- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Leader/Vice can assign `member` and `admin` only inside guild scope.
- Admin with `manage_roles` can assign `member` and `admin` only inside guild scope.

Guild transfer:
- `public.transfer_member_guild(p_profile_id uuid, p_from_guild_id uuid, p_to_guild_id uuid)` supports Owner-only transfers.
- Old membership is preserved with `membership_status = 'left'` and `is_primary = false`.
- Target guild membership becomes active primary with `role = 'member'`.
- No hard delete is used.
- Transfer does not touch CP or GvG tables.
## Milestone 8 CP Hardening

New migration:
- `supabase/migrations/20260515000200_cp_rpc_hardening.sql`

`update_member_cp` now requires:
- authenticated actor
- target profile exists
- target profile is approved
- target has active primary membership
- actor has CP update permission for the target guild
- CP value is `0` or greater

`get_current_cp_roster` now:
- starts from active approved primary memberships
- left joins current CP by `profile_id` and `guild_id`
- includes active approved members with no CP row
- returns missing CP as `null`
