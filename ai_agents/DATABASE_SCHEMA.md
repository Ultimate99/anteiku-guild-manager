# Database Schema

## Current Backend Status

Milestone 24E is complete in production. Admin Analytics RPCs and the manual Weekly Growth snapshot batch model are applied and verified in production through `20260526000100_admin_analytics_foundation.sql`.

Milestone 23D completed production rollout for premium cosmetics hardening. Production now has current frames free, future manual avatar/frame enforcement, and grant-by-slug support.

Milestone 22E completed production rollout for preset avatar selection, unlocked/equipped frames, and future cosmetic rewards.

Cosmetics migration:
- `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`
- `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`

Staging and production both have this migration applied and verified. Future new target environments must apply and verify `20260525000100_cosmetics_catalog_unlocks.sql` before deploying cosmetics UI there.

## Production Deployment Status

Production Supabase is live and migrated through Milestone 24E. Member Status, CP Update Window / Member CP Self-Submit, CP Leaderboard, Rank Badge / Profile Border, Cosmetics, Premium Cosmetics, Owner Cosmetics, and Admin Analytics are applied, verified, and live in production.

Current local migration order:

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

Migration `20260523000100_member_roster_status_system.sql` is implemented, locally validated, staging validated, and production applied/verified.

Migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql` are implemented, locally validated, staging validated, and production applied/verified.

Migration `20260524000300_cp_rankings.sql` is implemented, locally validated, staging validated, and production applied/verified.

Migration `20260524000400_cp_rank_badge_summary.sql` is implemented, locally validated, staging validated, and production applied/verified.

Migration `20260525000100_cosmetics_catalog_unlocks.sql` is implemented, locally validated, staging validated, and production applied/verified.

Migration `20260525000200_cp_rankings_cosmetics.sql` is implemented and production applied/verified as part of the leaderboard cosmetic display rollout.

Migration `20260525000300_premium_cosmetics_grant_helper.sql` is implemented, locally validated, staging validated, and production applied/verified.

Migration `20260526000100_admin_analytics_foundation.sql` is implemented, locally validated, staging validated, and production applied/verified. It adds `cp_snapshot_batches`, `cp_snapshot_entries`, Admin Analytics RPCs, and manual Weekly Growth RPCs.

Production Member Status verification:
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- `member_status_history` exists with RLS enabled and no public/client write policies.
- `update_member_roster_status(...)` exists with authenticated execute grant.
- Production frontend smoke validation passed after deployment.
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.

Operational note: Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; future staging/local work must explicitly relink before Supabase commands.

Do not run `supabase db reset` or `supabase/tests/local_validation_anteiku.sql` against production.

`supabase/config.toml` references missing `./seed.sql`; do not use `db push --include-seed` until that hazard is resolved. Core guild and permission seed data currently lives in migration `20260514000400_seed_core_data.sql`.

## Milestone 20B CP Ranking RPCs

Migration:
- `supabase/migrations/20260524000300_cp_rankings.sql`

New RPCs:
- `get_member_cp_rankings(p_scope text default 'guild')`
- `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`

Member-safe ranking behavior:
- Members can view CP rank order for `guild` or `global` scope.
- Guild scope uses the caller's active primary guild.
- Global scope returns rank rows across eligible approved active roster members in all active guilds.
- Return shape is limited to `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member responses do not include `cp_value`, profile id, username, updated timestamps, snapshots, growth, audit metadata, or private CP data.

Admin ranking behavior:
- Guild scope requires existing scoped CP view authority through `private.can_view_cp(...)`.
- Global scope is Owner-only in v1.
- Admin return shape includes `rank`, profile/user labels, guild labels, `cp_value`, and `updated_at`.
- Existing `get_cp_leaderboard(...)`, CP roster, CP Update Window, and CP update behavior are preserved.

Ranking and roster inclusion:
- Ranks use `row_number()` with deterministic ordering by `cp_value desc`, then IGN/profile tie-breaker.
- Ranking rows include approved profiles with active memberships and roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.

Indexes:
- Adds ranking support indexes on `member_cp` for guild and global CP sorting.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 20B focused validation result: 14 PASS / 0 FAIL / 0 SKIP.

## Milestone 22B Cosmetics Catalog / Unlocks Backend

Migration:
- `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`

New tables:
- `cosmetic_catalog`: approved static cosmetic metadata keyed by stable text keys.
- `profile_cosmetic_unlocks`: per-profile cosmetic unlock rows for frames and future rewards.
- `profile_equipped_cosmetics`: per-profile equipped avatar/frame keys.

Catalog columns:
- `key text primary key`
- `type text not null`, limited to `avatar` or `frame`
- `label_key text not null`
- `asset_path text not null`
- `rarity text not null default 'common'`
- `unlock_type text not null default 'free'`
- `is_active boolean not null default true`
- `sort_order integer not null default 100`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Seeded catalog:
- 54 avatar rows from `public/cosmetics/avatars/*.png`; all avatars use `unlock_type = 'free'`.
- 10 frame rows from `public/cosmetics/frames/*.png`.
- Default avatar: `1079_head` -> `/cosmetics/avatars/1079_head.png`.
- Default frame: `TXK_frame_reOpen_EN_FREE` -> `/cosmetics/frames/TXK_frame_reOpen_EN_FREE.png`.
- Free frames: frame keys ending `_FREE`, mapped to `unlock_type = 'free'`.
- Locked/earned frames: non-`_FREE` frame keys, mapped to `unlock_type = 'manual'`.

Free naming convention:
- Cosmetic keys ending `_FREE` are an asset/import convention and must map to `unlock_type = 'free'`.
- Catalog `unlock_type` remains the runtime source of truth for equip checks.
- Frames are equippable when `unlock_type = 'free'` or the caller has a matching unlock row.
- Runtime security does not inspect filenames; the catalog row is the authority.

RPCs:
- `get_available_avatars()`
- `get_my_cosmetics()`
- `equip_my_avatar(p_avatar_key text)`
- `equip_my_frame(p_frame_key text)`
- `admin_grant_cosmetic(p_profile_id uuid, p_cosmetic_key text, p_reason text default null)`

Legacy avatar hardening:
- `update_my_profile(p_ign, p_avatar_key)` now rejects non-empty avatar keys unless they match an active `avatar` row in `cosmetic_catalog`.
- `equip_my_avatar(...)` mirrors the equipped avatar to `profiles.avatar_key` for backward compatibility.

## Milestone 23B Premium Cosmetics / Grant Helper Backend

Migration:
- `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`

Status:
- Backend/database-only implementation complete.
- Local validation passed.
- Staging validation passed in Milestone 23C.
- Production applied/verified in Milestone 23D.
- Existing deployed migration `20260525000100_cosmetics_catalog_unlocks.sql` was not edited.

Catalog rule changes:
- All 10 current frame rows are updated to `unlock_type = 'free'`.
- Current avatars remain free.
- Future premium avatars and frames should use `unlock_type = 'manual'`.
- `_FREE` remains only an asset/import naming convention; catalog `unlock_type` remains the runtime authority.

RPC updates:
- `get_my_cosmetics()` now includes avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(p_avatar_key text)` now allows active free avatars and active manual avatars only when the caller has an unlock row.
- `update_my_profile(p_ign, p_avatar_key)` now applies the same free-or-unlocked avatar rule for non-empty avatar keys.
- `equip_my_frame(p_frame_key text)` behavior remains compatible and already enforces free-or-unlocked frame semantics.
- `admin_grant_cosmetic(p_profile_id uuid, p_cosmetic_key text, p_reason text default null)` remains compatible.

New RPC:
- `admin_grant_cosmetic_by_slug(p_profile_slug text, p_cosmetic_key text, p_reason text default null)`

Grant-by-slug behavior:
- Uses `auth.uid()`.
- Looks up target by exact normalized `profile_slug` or `username`, not IGN/display name.
- Validates target profile exists.
- Delegates permission, active membership, cosmetic existence, idempotent unlock, and audit behavior to the existing `admin_grant_cosmetic(...)` path.
- Returns a safe summary: target profile id, username, profile slug, cosmetic key/type, and unlock timestamp.
- Grants execute to `authenticated`; normal members and admins without member-management authority are denied by the RPC path.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.

RLS/security:
- RLS enabled on all three cosmetics tables.
- Authenticated approved users with active primary membership can read active catalog rows and their own unlock/equipped rows.
- Direct client writes are not granted.
- Equip RPCs use `auth.uid()` only and accept no target profile id.
- Locked frames require an unlock row unless `unlock_type = 'free'`.
- Admin grants require existing member-management authority for the target member's active primary guild.
- No player uploads, arbitrary image URLs, Supabase Storage, CP/GvG/audit/role/permission/member-status behavior changes, staging, or production changes were included.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.
- Local asset-path verification checked 64 catalog rows with 0 missing files and 0 unlock mapping problems.

## Milestone 21B CP Rank Badge Summary RPC

Migration:
- `supabase/migrations/20260524000400_cp_rank_badge_summary.sql`

New RPC:
- `get_my_cp_rank_summary()`

Purpose:
- Supports future Profile/Dashboard rank badge and profile border visuals without exposing CP values.
- Returns only the caller's own global/guild rank position and stable tier/visual keys.

Return shape:
- `global_rank integer`
- `guild_rank integer`
- `rank_tier text`
- `visual_key text`
- `is_ranked boolean`

Privacy:
- Does not return `cp_value`, updated timestamps, growth/history/snapshot data, usernames, profile ids, other-member rows, or private metadata.
- Accepts no target profile id; the caller is resolved only through `auth.uid()`.
- Direct `member_cp` and `cp_snapshots` access remains blocked.

Ranking and tier rules:
- Uses the same eligible row set as the member-safe leaderboard: approved profile, active primary membership, and roster status `active`, `trial`, or `pending_transfer`.
- Excludes `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.
- Uses deterministic `row_number()` order by `cp_value desc`, then IGN/profile tie-breaker.
- Tiers: `rank_one`, `rank_two`, `rank_three`, `elite_five`, `top_ten`, `high_rank`, `ranked_member`, and `unranked`.

Validation:
- Local Supabase reset passed.
- Local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.

## Milestone 19B CP Update Window Backend

Migration:
- `supabase/migrations/20260524000100_cp_update_window_self_submit.sql`

New table:
- `public.cp_update_windows`

Columns:
- `id uuid primary key default gen_random_uuid()`
- `guild_id uuid not null references public.guilds(id)`
- `status text not null default 'open'`, limited to `open` or `closed`
- `opens_at timestamptz null`
- `closes_at timestamptz null`
- `note text null`
- `created_by uuid not null references public.profiles(id)`
- `closed_by uuid null references public.profiles(id)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Indexes and constraints:
- One open CP Update Window per guild through partial unique index on `guild_id where status = 'open'`.
- Guild/status/time indexes for active-window lookups.
- Time-order and note-length checks.

RPCs:
- `get_active_cp_update_window_for_me()`
- `get_my_cp()`
- `submit_my_cp_update(p_cp_value integer)`
- `open_cp_update_window(p_guild_id uuid, p_opens_at timestamptz default null, p_closes_at timestamptz default null, p_note text default null)`
- `close_cp_update_window(p_window_id uuid)`
- `get_cp_update_window_for_guild(p_guild_id uuid)` from Milestone 19B.1

Member CP behavior:
- Members can read only their own current CP through `get_my_cp()`.
- Members can submit only their own CP through `submit_my_cp_update(...)`.
- Members still cannot directly read or update `member_cp`.
- Members still cannot read `cp_snapshots`.
- Multiple member submissions while a valid window is open are allowed; latest CP wins and each submission writes audit history.

Roster eligibility:
- `active`, `trial`, and `pending_transfer` can submit during an applicable open window.
- `inactive` and `on_break` can read own CP but cannot submit.
- `suspended`, `left`, and `kicked` remain hard-blocked through membership/security state.

Audit:
- Member self-submit writes `member_cp_self_submitted` with `cp_old`, `cp_new`, `window_id`, and source metadata.
- Window open/close writes `cp_update_window_opened` and `cp_update_window_closed`.
- `get_audit_logs(...)` redacts CP metadata from self-submit rows for viewers without scoped `view_cp`.

## Milestone 19B.1 Staff CP Window Read RPC

Migration:
- `supabase/migrations/20260524000200_cp_update_window_staff_read.sql`

RPC:
- `get_cp_update_window_for_guild(p_guild_id uuid)`

Purpose:
- Lets AdminPanel safely display the CP Update Window status for the selected guild after refresh.
- The member-focused `get_active_cp_update_window_for_me()` remains scoped to the caller's own guild.

Permission model:
- Owner can read any active guild window status.
- Leader/Vice can read scoped guild window status.
- Admin can read scoped guild window status with `view_cp` or `update_cp`.
- Member and wrong-guild users are denied.

Return shape:
- `id`
- `guild_id`
- `status`
- `opens_at`
- `closes_at`
- `note`
- `created_at`
- `updated_at`
- `created_by_username`
- `created_by_ign`
- `closed_by_username`
- `closed_by_ign`
- `server_now`

Ordering:
- Returns the open window first if one exists.
- If no open window exists, returns the latest closed window.
- If the guild has no CP windows, returns no row.

## Milestone 15A Member Roster Status System

Migration:
- `supabase/migrations/20260523000100_member_roster_status_system.sql`

Current roster status:
- `guild_memberships.roster_status text not null default 'active'`.
- Allowed values: `active`, `trial`, `inactive`, `on_break`, `suspended`, `left`, `kicked`, `pending_transfer`.
- `roster_status` is separate from `profiles.approval_status`.
- `roster_status` is separate from `guild_memberships.membership_status`, which remains the hard security/access state.

Private history:
- `member_status_history` stores `membership_id`, `profile_id`, `guild_id`, old/new status, private reason, changer, and timestamp.
- Members do not directly read private status history/reasons.
- Scoped staff can read status history through RLS.
- There are no direct client write policies for history.

Status-change RPC:
- `public.update_member_roster_status(p_membership_id uuid, p_new_status text, p_reason text default null)`.
- Owner can set all statuses globally, with last-active-Owner protection.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only `active`, `trial`, `inactive`, `on_break`, and `pending_transfer`.
- Members cannot change roster status.

Hard-block mapping:
- `suspended` sets `membership_status = 'suspended'`.
- `left` sets `membership_status = 'left'`.
- `kicked` sets `membership_status = 'left'` because current `membership_status` has no `kicked` value and `rejected` remains reserved for registration/reapply.

GvG behavior:
- `inactive` and `on_break` keep active membership but are excluded from active GvG event visibility/voting.
- `active`, `trial`, and `pending_transfer` remain GvG eligible.

Audit:
- Status changes write `member_roster_status_changed`.
- Audit metadata includes old/new status, membership id, guild id, hard membership status old/new, and `reason_provided`.
- Full private reason text is not stored in broadly visible audit metadata.

## Milestone 11A Audit Log Read Hardening

Migration:
- `supabase/migrations/20260515000300_audit_log_read_hardening.sql`

New RPC:
- `public.get_audit_logs(p_guild_id uuid default null, p_action text default null, p_actor_id uuid default null, p_target_id uuid default null, p_from timestamptz default null, p_to timestamptz default null, p_limit integer default 50, p_before timestamptz default null)`

Returned fields:
- `id`
- `created_at`
- `action`
- `entity_table`
- `entity_id`
- `actor_profile_id`
- `actor_username`
- `actor_ign`
- `target_profile_id`
- `target_username`
- `target_ign`
- `guild_id`
- `guild_name`
- `guild_slug`
- `metadata`
- `metadata_redacted`

Direct audit table reads:
- Non-Owner direct `audit_logs` SELECT is restricted.
- Frontend audit UI must use `get_audit_logs`.

CP metadata:
- CP-sensitive audit metadata is redacted for viewers without scoped `view_cp`.
- Viewers with both audit visibility and scoped CP visibility can receive scoped CP metadata.

## Milestone 8 CP Hardening

Migration:
- `supabase/migrations/20260515000200_cp_rpc_hardening.sql`

CP update behavior:
- `public.update_member_cp(p_profile_id uuid, p_cp_value integer, p_note text default null)` requires:
  - authenticated actor
  - target profile exists
  - target profile `approval_status = 'approved'`
  - target has active primary guild membership
  - `p_cp_value >= 0`
  - actor passes `private.can_update_cp`

CP roster behavior:
- `public.get_current_cp_roster(p_guild_id uuid)` starts from active approved primary memberships.
- It left joins `member_cp` by `profile_id` and `guild_id`.
- Active approved members with no CP row are included with `cp_value = null`.
- Missing CP is not coerced to `0`.

## Milestone 7 Backend Additions

Milestone 7 adds backend support for app-safe member role changes and Owner-only guild transfer through RPCs.

New migration file:

- `supabase/migrations/20260515000100_member_guild_role_management.sql`

Guild transfer behavior:

- Old active primary membership is preserved and changed to `membership_status = 'left'` and `is_primary = false`.
- Target guild membership is created or reactivated as `membership_status = 'active'`, `is_primary = true`, and `role = 'member'`.
- No hard delete is used.
- Exactly one active primary membership must remain after transfer.
- Transfer does not touch CP or GvG tables.

Role assignment behavior:

- Normal app role assignment can assign `member`, `admin`, `vice`, or `leader` according to actor permissions.
- Normal app role assignment cannot assign `owner`.
- Owner role assignment remains manual-only.

Milestone 2 schema/RLS direction was implemented in Supabase migrations and has been locally validated. Later milestones add focused migrations for role/guild management, CP hardening, and audit-log read hardening.

## Core Decisions

- `profiles.id` must be `uuid primary key references auth.users(id)`.
- Do not add a separate `auth_user_id` column unless a later need is approved.
- `username` and `profile_slug` are identical at v1 registration.
- `username` and `profile_slug` are normalized to lowercase before saving.
- Normal users cannot change `username` or `profile_slug` after registration.
- Owner can reset any username/profile slug.
- Leader/Vice can reset username/profile slug only for users in assigned guild scope.
- Admin can reset username/profile slug only with `reset_profile_slug`.
- CP must not be stored in `profiles`.
- Current CP belongs in `member_cp`.
- Weekly/history CP belongs in `cp_snapshots`.
- Members must never directly select `member_cp` or `cp_snapshots`.
- v1 should enforce exactly one active primary guild membership per user.
- Rejected users reapply using the same profile row.
- Important records should avoid hard deletes; use status/archive fields when possible.

## Planned Tables

### `profiles`

Purpose: one row per Supabase Auth user.

Planned columns:

- `id uuid primary key references auth.users(id)`
- `username text not null unique`
- `profile_slug text not null unique`
- `ign text not null`
- `avatar_key text null`
- `approval_status text not null default 'pending'`
- `reapply_requested_at timestamptz null`
- `reapply_note text null`
- `approved_at timestamptz null`
- `approved_by uuid null references profiles(id)`
- `rejected_at timestamptz null`
- `rejected_by uuid null references profiles(id)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Username/profile slug format:

- lowercase `a-z`
- numbers `0-9`
- underscore `_`
- hyphen `-`
- length 3-32
- starts with a letter or number
- does not end with hyphen or underscore

### `guilds`

Purpose: guild/subguild records.

Core seed rows:

- Anteiku
- Anteiku:Re
- Anteiku:Rose
- Anteiku:Goat

Planned columns:

- `id uuid primary key`
- `slug text not null unique`
- `name text not null unique`
- `parent_guild_id uuid null references guilds(id)`
- `is_core boolean not null default false`
- `status text not null default 'active'`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Core guild names are public/visible during registration.

### `guild_memberships`

Purpose: role and membership state for a profile in a guild.

Planned columns:

- `id uuid primary key`
- `profile_id uuid not null references profiles(id)`
- `guild_id uuid not null references guilds(id)`
- `role text not null`
- `membership_status text not null default 'pending'`
- `roster_status text not null default 'active'`
- `is_primary boolean not null default true`
- `assigned_by uuid null references profiles(id)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

v1 rule: exactly one active primary membership per profile, ideally enforced with a partial unique index on `profile_id` where `membership_status = 'active' and is_primary = true`.

### `permission_catalog`

Purpose: approved permission keys for checkbox-driven Admin permissions.

Planned columns:

- `key text primary key`
- `label text not null`
- `description text null`
- `is_sensitive boolean not null default false`
- `created_at timestamptz not null default now()`

### `admin_permissions`

Purpose: explicit Admin permission grants.

Planned columns:

- `id uuid primary key`
- `membership_id uuid not null references guild_memberships(id)`
- `permission_key text not null references permission_catalog(key)`
- `granted_by uuid not null references profiles(id)`
- `created_at timestamptz not null default now()`

Owner only can grant `view_cp` and `update_cp` to Admins in v1.

### `member_cp`

Purpose: current CP value.

Planned columns:

- `profile_id uuid primary key references profiles(id)`
- `guild_id uuid not null references guilds(id)`
- `cp_value integer not null`
- `updated_by uuid not null references profiles(id)`
- `updated_at timestamptz not null default now()`

Direct member select is forbidden. Access must go through permission-checked RPC/views.

### `cp_snapshots`

Purpose: manual weekly CP snapshots for growth/history.

Planned columns:

- `id uuid primary key`
- `profile_id uuid not null references profiles(id)`
- `guild_id uuid not null references guilds(id)`
- `snapshot_week_start date not null`
- `cp_value integer not null`
- `captured_by uuid not null references profiles(id)`
- `created_at timestamptz not null default now()`

Current CP updates and weekly snapshot capture are separate concepts in v1.

### `gvg_events`

Purpose: guild-specific or global GvG event definitions.

Planned columns:

- `id uuid primary key`
- `guild_id uuid null references guilds(id)`
- `scope text not null`
- `title text not null`
- `status text not null default 'draft'`
- `starts_at timestamptz null`
- `ends_at timestamptz null`
- `created_by uuid not null references profiles(id)`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Supported scopes:

- `guild`: event applies to one guild.
- `global`: event applies to all approved users with active primary memberships.

v1 UI may start with guild-specific events first.

### `gvg_votes`

Purpose: member present/absent vote for a GvG event.

Planned columns:

- `id uuid primary key`
- `gvg_event_id uuid not null references gvg_events(id)`
- `profile_id uuid not null references profiles(id)`
- `vote_status text not null`
- `absence_reason text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Members can update only their own vote while an event is active. Admins/leaders do not edit/remove member votes in v1.

### `audit_logs`

Purpose: immutable record of sensitive/admin actions.

Planned columns:

- `id uuid primary key`
- `actor_profile_id uuid null references profiles(id)`
- `target_profile_id uuid null references profiles(id)`
- `guild_id uuid null references guilds(id)`
- `action text not null`
- `entity_table text null`
- `entity_id uuid null`
- `metadata jsonb not null default '{}'::jsonb`
- `created_at timestamptz not null default now()`

Client direct inserts/updates/deletes are forbidden. Logs should be written by trusted RPCs/triggers.

## Required Constraints And Indexes

- Unique `profiles.username`.
- Unique `profiles.profile_slug`.
- Check username/profile slug format.
- Check `approval_status` allowed values.
- Check membership role allowed values.
- Check membership status allowed values.
- Unique `guild_memberships(profile_id, guild_id)`.
- Partial unique active primary membership per profile.
- Unique `admin_permissions(membership_id, permission_key)`.
- Check `member_cp.cp_value >= 0`.
- Check `cp_snapshots.cp_value >= 0`.
- Unique `cp_snapshots(profile_id, guild_id, snapshot_week_start)`.
- Check GvG event scope/status values.
- Check GvG vote status values: `present`, `absent`.
- Unique `gvg_votes(gvg_event_id, profile_id)`.
- Check `absence_reason` max length.
- Index membership lookups by `profile_id`, `guild_id`, role/status.
- Index CP snapshots by `guild_id` and `snapshot_week_start`.
- Index GvG votes by `gvg_event_id` and `vote_status`.
- Index audit logs by `guild_id`, actor, target, and `created_at`.
