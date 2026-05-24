# Supabase RLS

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

Production is live through Milestone 20F. CP Leaderboard / CP Ranking is applied, deployed, and smoke-validated in production.

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
