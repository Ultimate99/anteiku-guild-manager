# Database

The Supabase schema/RLS/RPC migrations for Anteiku Guild Manager have been implemented and validated through Milestone 20B locally. Remote production is live through Milestone 19E; the Milestone 20B CP Ranking migration is local-only until a later rollout gate.

Production deployment must follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md).

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
13. `20260524000300_cp_rankings.sql` - local only; not applied to staging or production yet.

Migration `20260523000100_member_roster_status_system.sql` is locally validated, staging validated, and production applied/verified as of Milestone 15E.

Migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql` are locally validated, staging validated, and production applied/verified.

Migration `20260524000300_cp_rankings.sql` is locally validated only.

Production Member Status rollout:
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- Production smoke validation passed after frontend deployment.
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink before future staging/local Supabase commands.

Do not run `supabase db reset` against production. Do not run `supabase/tests/local_validation_anteiku.sql` against production because it inserts fake auth users and local test data.

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
