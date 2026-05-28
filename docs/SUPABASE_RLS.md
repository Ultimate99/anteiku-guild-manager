# Supabase RLS

The Supabase RLS/RPC implementation has been validated through the Weekly Growth baseline scope fix. Production is applied/verified through `20260526000300_live_cp_growth_baseline_scope.sql`.

Production setup must not weaken RLS. Follow [DEPLOYMENT.md](DEPLOYMENT.md) and [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) before any production action.

## Milestone 25B 3v3 Team Finder RLS/RPC

Milestone 25B is implemented and locally validated only. Staging and production do not have `20260528000100_three_v_three_team_finder.sql` yet.

Tables:
- `three_v_three_player_profiles`
- `three_v_three_teams`
- `three_v_three_team_members`
- `three_v_three_join_requests`

RLS/grants:
- RLS is enabled on all new 3v3 tables.
- Direct anon/authenticated table grants are revoked.
- Future frontend access should use only the 3v3 RPCs.

Eligibility:
- Approved active-membership users with roster status `active`, `trial`, `pending_transfer`, `inactive`, or `on_break` can browse teams.
- Only `active`, `trial`, and `pending_transfer` can create teams or request joins.
- Pending, suspended, left, and kicked users are denied.

Security:
- Public 3v3 Combined CP is self-entered and separate from protected normal CP.
- 3v3 RPCs must not read or expose `member_cp`, `cp_snapshots`, CP analytics, CP roster, CP ranking, or CP growth.
- Team owner-only mutations are enforced in RPCs.
- Request spam rules are backend-enforced.

Validation:
- Local validation passed with Milestone 25B result: 45 PASS / 0 FAIL / 0 SKIP.

## Live CP Growth RLS/RPC

Live CP Growth is implemented and production applied/verified.

Migration:
- `20260526000200_live_cp_growth.sql`
- `20260526000300_live_cp_growth_baseline_scope.sql`

Rules:
- `get_admin_live_cp_growth(...)` requires backend-enforced scoped `view_cp`.
- `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)` preserves explicitly selected baselines across scope changes when backend scoping permits it.
- Owner can use a Global baseline while filtering rows to a selected guild scope.
- Scoped staff cannot use Global baselines for guild analytics.
- `start_new_cp_growth_period(...)` requires backend-enforced scoped `view_cp` or Owner global authority.
- Start New CP Week captures baseline values only; it does not reset player CP.
- Members, pending users, admins without `view_cp`, and wrong-guild staff are denied.
- No direct client grants are added for `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- Production Start New CP Week mutation smoke was not performed by design; explicit approval is required before creating a production baseline.
- Production baseline scope smoke confirmed Global and Anteiku both show `安定区×Ulti` growth `+5,002` from the same Global baseline, without creating a new production snapshot.

## Milestone 24B Admin Analytics RLS/RPC

Milestone 24B/24E Admin Analytics is implemented, locally validated, staging validated, and production applied/verified.

Migration:
- `20260526000100_admin_analytics_foundation.sql`

RLS/grants:
- `cp_snapshot_batches` and `cp_snapshot_entries` have RLS enabled.
- No direct anon/authenticated table grants are provided.
- Snapshot capture and snapshot reads are exposed through permission-checked RPCs only.
- Production verification confirmed direct authenticated reads of the new snapshot tables are denied.
- Production snapshot capture mutation smoke was not performed by design; explicit approval is required before creating production snapshot rows.

Permission model:
- Members and pending users are denied.
- Wrong-guild staff are denied.
- CP Analytics and Weekly Growth require scoped `view_cp`.
- Admins without `view_cp` receive no CP values, growth values, or snapshot data.
- Owner can use global analytics; scoped staff must use an authorized guild scope.

## Milestone 23D Premium Cosmetics Production RLS/RPC

Milestone 23D is applied and verified in production.

Migration:
- `20260525000300_premium_cosmetics_grant_helper.sql`

Rules:
- All current frame catalog rows are free.
- Future premium avatars and frames should use `unlock_type = 'manual'`.
- `get_my_cosmetics()` returns avatar unlock metadata.
- `equip_my_avatar(...)` and `update_my_profile(...)` enforce free-or-unlocked avatar behavior.
- `admin_grant_cosmetic_by_slug(...)` grants by exact normalized username/profile slug through existing member-management authority.
- Direct authenticated insert/write grants to cosmetics unlock/equipped tables remain absent.

## Milestone 23B Premium Cosmetics RLS/RPC

Milestone 23B is backend-only and locally validated. It was later applied to staging in Milestone 23C and production in Milestone 23D.

Migration:
- `20260525000300_premium_cosmetics_grant_helper.sql`

Runtime rules:
- Current frame rows are updated to `unlock_type = 'free'`.
- Future premium avatars and frames should use `unlock_type = 'manual'`.
- Catalog `unlock_type` remains the source of truth; `_FREE` is only an asset/import convention.

RPC behavior:
- `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(text)` now requires a free avatar or a caller-owned unlock for manual avatars.
- `update_my_profile(p_ign, p_avatar_key)` rejects locked manual avatars.
- `equip_my_frame(text)` remains compatible and continues to require free-or-unlocked frame state.
- `admin_grant_cosmetic_by_slug(text, text, text)` grants by exact normalized username/profile slug and uses existing member-management authority through the existing grant path.

Validation:
- Local Supabase reset passed.
- Local validation passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.

## Milestone 22B Cosmetics RLS/RPC

Milestone 22B is implemented and locally validated. Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified through Milestones 22D and 22E.

New tables:
- `cosmetic_catalog`
- `profile_cosmetic_unlocks`
- `profile_equipped_cosmetics`

RLS/grants:
- RLS is enabled on all cosmetics tables.
- Active catalog rows are readable by authenticated approved users with active primary membership.
- Unlock/equipped rows are readable only by the owning profile.
- Direct client writes are not granted.

RPC behavior:
- `get_available_avatars()` returns active avatar catalog rows.
- `get_my_cosmetics()` returns caller-owned equipped keys and caller-scoped frame unlock status.
- `equip_my_avatar(text)` updates only `auth.uid()` and validates active avatar catalog keys.
- `equip_my_frame(text)` updates only `auth.uid()` and requires a free frame or caller-owned unlock.
- `admin_grant_cosmetic(uuid, text, text)` requires existing member-management authority in the target member's active primary guild.

Legacy hardening:
- `update_my_profile(p_ign, p_avatar_key)` rejects arbitrary non-empty avatar keys.
- Valid avatar keys must exist in `cosmetic_catalog` with type `avatar` and `is_active = true`.

Security boundary:
- Database stores cosmetic keys and static asset paths only.
- Asset paths are constrained to `/cosmetics/avatars/` or `/cosmetics/frames/`.
- `_FREE` suffixes are an asset/import convention and are mapped to `unlock_type = 'free'`.
- Current seed rows match actual local assets: 54 free avatars and 10 frames.
- Current non-`_FREE` frames use `unlock_type = 'manual'` and require unlock rows.
- Runtime equip checks use catalog `unlock_type` as source of truth.
- No player uploads, arbitrary image URLs, Supabase Storage, service-role usage, or CP/GvG/audit/role/permission/member-status changes were added.

Validation:
- Milestone 22B local validation passed with 19 PASS / 0 FAIL / 0 SKIP.
- Catalog asset-path verification checked 64 rows with 0 missing files and 0 unlock mapping problems.
- Milestone 22E production verification passed for tables, RLS, catalog counts, exact repo asset-path match, RPC existence/grants, direct-write denial, active Owner count `1`, and `update_my_profile(...)` avatar hardening.

## Milestone 21E Rank Badge Summary RPC

Milestone 21B backend is locally validated. Staging rollout passed in Milestone 21D and production rollout passed in Milestone 21E.

New RPC:
- `get_my_cp_rank_summary()`

Member-safe behavior:
- Uses `auth.uid()` and accepts no profile id parameter.
- Requires approved profile with active primary membership.
- Returns only the caller's own `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Does not return CP values, updated timestamps, growth/history/snapshot data, usernames, profile ids, other-member rows, or private metadata.
- `inactive` and `on_break` users with active approved membership receive the `unranked` default state.
- Hard-blocked users remain denied by existing access gates.

Roster/ranking rules:
- Rank summary uses the same eligible row set as the member-safe leaderboard: approved active primary memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking excludes `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- Ranks use deterministic `row_number()` ordering by `cp_value desc`, then IGN/profile tie-breaker.

Validation:
- Milestone 21B local validation passed with 15 PASS / 0 FAIL / 0 SKIP.

## Milestone 20B CP Ranking RPCs

Milestone 20B is backend/database-only and locally validated. Staging and production rollout passed through Milestones 20E and 20F.

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
