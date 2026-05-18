# Supabase RLS

The local Supabase RLS/RPC implementation has been validated through Milestone 11A, and the Milestone 11B frontend audit viewer has been live-browser validated against the safe audit RPC. These migrations have not been applied to production yet.

Production setup must not weaken RLS. Follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) before any production action.

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

Local validation result: 29 PASS / 0 FAIL / 0 SKIP.

Validated:

- Members cannot directly read CP tables.
- Members cannot access CP through CP RPCs.
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
