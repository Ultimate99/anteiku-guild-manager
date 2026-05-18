# Database

The Supabase schema/RLS/RPC migrations for the local Anteiku Guild Manager backend have been implemented and validated locally through Milestone 11A. They have not been applied to a production Supabase project yet.

Production deployment must follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

## Production Migration Order

1. `20260514000100_core_schema.sql`
2. `20260514000200_constraints_indexes.sql`
3. `20260514000300_private_helper_functions.sql`
4. `20260514000400_seed_core_data.sql`
5. `20260514000500_rls_policies.sql`
6. `20260514000600_public_rpc_functions.sql`
7. `20260515000100_member_guild_role_management.sql`
8. `20260515000200_cp_rpc_hardening.sql`
9. `20260515000300_audit_log_read_hardening.sql`

Do not run `supabase db reset` against production. Do not run `supabase/tests/local_validation_anteiku.sql` against production because it inserts fake auth users and local test data.

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
- `guild_memberships`: profile-to-guild membership, role, status, and primary membership.
- `permission_catalog`: approved Admin permission keys.
- `admin_permissions`: explicit Admin permission grants.
- `member_cp`: current CP values, protected from member reads.
- `cp_snapshots`: manual weekly CP history/growth.
- `gvg_events`: guild-specific and global GvG events.
- `gvg_votes`: one vote per user per event.
- `audit_logs`: trusted record of sensitive/admin actions.

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

Local Supabase validation passed with 29 PASS / 0 FAIL / 0 SKIP.

The validation confirmed that migrations apply locally, seed data exists, permission catalog rules are present, CP privacy is enforced by direct table denial and RPC checks, GvG vote integrity works, approval/reapply behavior is scoped, and audit spoofing is blocked.
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
