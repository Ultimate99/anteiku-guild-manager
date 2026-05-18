# Database Schema

## Production Deployment Status

Milestone 12 documented production readiness only. The schema has been validated locally, but it has not been applied to production Supabase.

Production migration order:

1. `20260514000100_core_schema.sql`
2. `20260514000200_constraints_indexes.sql`
3. `20260514000300_private_helper_functions.sql`
4. `20260514000400_seed_core_data.sql`
5. `20260514000500_rls_policies.sql`
6. `20260514000600_public_rpc_functions.sql`
7. `20260515000100_member_guild_role_management.sql`
8. `20260515000200_cp_rpc_hardening.sql`
9. `20260515000300_audit_log_read_hardening.sql`

Do not run `supabase db reset` or `supabase/tests/local_validation_anteiku.sql` against production.

`supabase/config.toml` references missing `./seed.sql`; do not use `db push --include-seed` until that hazard is resolved. Core guild and permission seed data currently lives in migration `20260514000400_seed_core_data.sql`.

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
