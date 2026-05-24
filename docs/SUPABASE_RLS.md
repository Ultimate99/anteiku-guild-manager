# Supabase RLS

The local Supabase RLS/RPC implementation has been validated through Milestone 20B, and the Milestone 11B frontend audit viewer has been live-browser validated against the safe audit RPC.

Production setup must not weaken RLS. Follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) before any production action.

## Milestone 20B CP Ranking RPCs

Milestone 20B is backend/database-only and locally validated. Staging and production rollout are pending.

New RPCs:
- `get_member_cp_rankings(p_scope text default 'guild')`
- `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`

Member-safe behavior:
- `get_member_cp_rankings(...)` uses `auth.uid()` and requires an approved profile with active primary membership.
- Members can request `guild` or `global` rank scope only.
- Guild scope uses the caller's active primary guild.
- Global scope returns safe rank order across eligible approved active roster members.
- Return shape is only `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member responses do not include CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, audit metadata, or private CP fields.

Admin behavior:
- `get_admin_cp_rankings(...)` uses `auth.uid()`.
- Guild scope requires existing scoped `view_cp` authority.
- Global scope is Owner-only in v1.
- Normal Members and Admins without scoped `view_cp` are denied.

Roster/ranking rules:
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- Ranks use deterministic `row_number()` ordering by `cp_value desc`, then IGN/profile tie-breaker.

Validation:
- Milestone 20B local validation passed with 14 PASS / 0 FAIL / 0 SKIP.

## Milestone 19B / 19B.1 CP Update Window RLS/RPC

Milestone 19B/19B.1 is backend/database-only, locally validated, staging validated, and production applied/verified as of Milestone 19E.

New table:
- `cp_update_windows`

RLS/grants:
- RLS is enabled.
- Direct table grants are revoked from `public`, `anon`, and `authenticated`.
- No direct client table policies are added.
- Members and staff use RPCs instead of direct table access.

RPCs:
- `get_active_cp_update_window_for_me()` returns only safe own-guild window status and submit eligibility.
- `get_my_cp()` returns only the caller's own CP.
- `submit_my_cp_update(integer)` updates only the caller's own CP after approval, active membership, roster eligibility, guild scope, CP value, and open-window checks.
- `open_cp_update_window(...)` and `close_cp_update_window(uuid)` require `private.can_update_cp`.
- `get_cp_update_window_for_guild(uuid)` returns safe selected-guild window status for Owner, scoped Leader/Vice, or scoped Admin with `view_cp` or `update_cp`.

Audit:
- `member_cp_self_submitted` audit metadata includes CP old/new values.
- `get_audit_logs(...)` redacts CP self-submit metadata for viewers without scoped `view_cp`.

Validation:
- Milestone 19B local validation passed with 32 PASS / 0 FAIL / 0 SKIP.
- Milestone 19B.1 local validation passed with 13 PASS / 0 FAIL / 0 SKIP.

## Milestone 15A Member Status RLS/RPC

Member Status backend support is implemented locally.

New table:
- `member_status_history`

RLS:
- Members cannot directly read private status history/reasons.
- Scoped staff can read history if they are Owner, scoped Leader/Vice, or Admin with `manage_members`.
- No direct client writes are allowed for history.

RPC:
- `public.update_member_roster_status(p_membership_id uuid, p_new_status text, p_reason text default null)`

Rules:
- Owner can set all statuses globally, but cannot block/remove the last active Owner.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only non-terminal statuses.
- Members cannot change status.
- `inactive` and `on_break` preserve active membership but are excluded from GvG event visibility/voting.
- `suspended`, `left`, and `kicked` hard-block access through `membership_status`.
- `kicked` maps to `membership_status = 'left'`.

Validation:
- Milestone 15A local validation passed with 22 PASS / 0 FAIL / 0 SKIP.

## Milestone 11A Audit Log Reads

Frontend audit log reads must use:

- `public.get_audit_logs(...)`

Direct non-Owner `audit_logs` SELECT is restricted so scoped staff cannot bypass database-side CP metadata redaction.

Audit access:
- Owner can read global audit logs.
- Leader/Vice can read scoped guild audit logs.
- Admin can read scoped audit logs only with `view_audit_logs`.
- Member and pending users cannot read audit logs.

CP metadata redaction:
- Audit metadata that includes CP-sensitive values is redacted unless the viewer also has scoped `view_cp`.
- Redacted rows remove CP values and CP update notes, then include `cp_metadata_redacted = true`.
- This redaction is enforced in SQL/RPC, not frontend code.

## Principles

- `auth.uid()` maps directly to `profiles.id`.
- Pending/rejected users can only read their own safe status/reapply data.
- Members cannot directly read CP tables.
- Sensitive actions must use database-side role/permission checks.
- Frontend conditional rendering is only UX. It is not security.
- Important records should not be hard-deleted by clients.

## Implemented Access Model

`profiles`
- Users can read own row.
- Approved members can read safe same-guild profile fields.
- Users can edit own IGN/avatar.
- Username/profile slug reset requires Owner, scoped Leader/Vice, or Admin with `reset_profile_slug`.

`guilds`
- Core active guild names are visible for registration.
- Management requires Owner or approved guild-management path.

`guild_memberships`
- Users can read own membership.
- Approved users can read safe same-guild membership info.
- Role/status changes require approved RPCs.

`member_cp` and `cp_snapshots`
- No member direct select.
- Owner global access via RPC/views.
- Leader/Vice guild-scoped access via RPC/views.
- Admin explicit `view_cp`/`update_cp` only.

`gvg_events`
- Approved users can read active guild/global events in scope.
- Owner/Leader/Vice/Admin with `manage_gvg` can manage scoped events.

`gvg_votes`
- Members insert/update only their own vote while event is active.
- Authorized admins/leaders read results and absence reasons.
- Admins/leaders cannot edit/remove votes in v1.

`audit_logs`
- Owner reads all.
- Leader/Vice read scoped guild logs by default.
- Admin reads logs only with `view_audit_logs`.
- Writes come only from trusted RPCs/triggers.

## Local Validation Status

Base local validation result: 29 PASS / 0 FAIL / 0 SKIP.

Latest focused local validation includes Milestone 20B CP Ranking checks: 14 PASS / 0 FAIL / 0 SKIP, Milestone 19B CP Update Window checks: 32 PASS / 0 FAIL / 0 SKIP, and Milestone 19B.1 staff read checks: 13 PASS / 0 FAIL / 0 SKIP.

Validated:

- Members cannot directly read CP tables.
- Members cannot access other-member CP values through CP RPCs.
- Admin without `view_cp` is blocked.
- Admin with `view_cp` can read scoped CP.
- Leader wrong-guild CP access is blocked.
- Direct `gvg_votes` insert/update is blocked.
- Approval/reapply and audit protections work.

Important fix: local validation caught private helper parameter shadowing that made permission helpers too broad. Helpers now use prefixed `p_*` parameters to avoid ambiguous column/parameter comparisons.
## Milestone 7 RPC Security

Member role changes and guild transfers remain RPC-controlled.

Key rules:
- Frontend must not directly update `guild_memberships`.
- `assign_member_role` rejects `owner` assignment through normal app flow.
- `transfer_member_guild` is Owner-only in v1.
- Both RPCs validate `auth.uid()` and use permission/helper checks server-side.
- Both RPCs write audit logs for sensitive changes.
- No CP or GvG access is added by Milestone 7.

Validation pending:
- Local Supabase reset and validation script run must confirm no grant/signature/security regressions.
## Milestone 8 CP RPC Hardening

CP remains protected by RPC and RLS.

Milestone 8 backend hardening:
- `update_member_cp` rejects non-approved target profiles.
- `get_current_cp_roster` requires `can_view_cp`.
- `update_member_cp` requires `can_update_cp`.
- Direct `member_cp` and `cp_snapshots` frontend/table access remains forbidden.
- No CP table policy was broadened.
