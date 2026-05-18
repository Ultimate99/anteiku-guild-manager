# Security Rules

## Production Readiness Rules

Production deployment must not weaken existing RLS/RPC security.

Milestone 12 documented the production runbook only. It did not deploy, link production Supabase, edit SQL migrations, or change source logic.

Production hard rules:
- Members must never see CP values.
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
- CP values remain unavailable to Members.
- Frontend must still avoid direct `member_cp` and `cp_snapshots` table access.

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

CP is private. Members must not see CP values or query CP values.

Approved CP design:

- Do not store CP in `profiles`.
- Store current CP in `member_cp`.
- Store manual weekly history/growth in `cp_snapshots`.
- Members must never directly select `member_cp` or `cp_snapshots`.
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
