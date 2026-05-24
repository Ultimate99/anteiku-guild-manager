# Security Rules

## Milestone 20F CP Leaderboard Production Rules

Milestone 20F is live in production.

Member ranking rules:
- Members may see CP rank order for `guild` and `global` scopes.
- Member-visible rank order intentionally reveals relative CP strength.
- Member ranking API responses must never include CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, audit metadata, or private CP fields.
- Member UI must show rank, IGN, optional guild label, and current-user highlight only.
- Member leaderboard frontend must use `get_member_cp_rankings(...)` only.

Admin ranking rules:
- AdminPanel CP Ranking must use `get_admin_cp_rankings(...)`.
- Guild rankings require existing scoped `view_cp` authority.
- Global admin rankings are Owner-only in v1.
- Admin without CP permission and normal Members must not receive CP values.

Operational rules:
- Do not query `member_cp` or `cp_snapshots` directly from frontend code.
- Do not send CP values to member clients and hide them in UI; member API responses must omit CP values.
- Existing CP Update Window, CP roster/update, audit, GvG, role, permission, and member-status behavior must remain unchanged.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## Milestone 20B CP Leaderboard Security Rules

Milestone 20B added backend support for member-safe CP rank order and admin CP rankings. The migration is now applied in staging and production through Milestones 20E and 20F.

Member ranking rules:
- Members may see CP rank order for `guild` and `global` scopes.
- This approved tradeoff reveals relative CP strength only.
- Members must not receive CP values from `get_member_cp_rankings(...)`.
- Members must not receive profile ids, usernames, updated timestamps, growth, snapshots, history, audit metadata, or private CP fields from the member ranking RPC.
- Member rankings may show IGN and, for global scope, guild label/slug.
- Current user highlighting uses `is_current_user`; no profile id is needed in the response.

Admin ranking rules:
- Admin guild CP rankings require scoped `view_cp` authority through the existing CP permission model.
- Admin global CP rankings are Owner-only in v1.
- Admin without scoped `view_cp` and normal Members must be denied by the RPC.
- CP values must only be returned by `get_admin_cp_rankings(...)` after database-side permission checks pass.

Roster inclusion:
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, and `kicked`.
- `inactive` and `on_break` members may still view rank order if existing access gates allow them into member pages, but they are not ranked.

CP table privacy:
- Members still cannot directly read `member_cp` or `cp_snapshots`.
- Frontend leaderboard UI must use the member-safe ranking RPC and must not call admin CP ranking/roster APIs for member pages.
- Never send CP values to member frontend and hide them in UI; member API responses must omit them.

Rollout status:
- `20260524000300_cp_rankings.sql` is applied and verified in staging and production.

## Milestone 19E CP Update Window Security Rules

Milestone 19B/19B.1 backend, Milestone 19C frontend, Milestone 19D staging validation, and Milestone 19E production rollout are complete. CP Update Window / Member CP Self-Submit is live in production.

CP Update Window rules:
- CP Update Windows are guild-scoped.
- Only one open CP Update Window can exist per guild.
- Window writes are RPC-only through `open_cp_update_window(...)` and `close_cp_update_window(...)`.
- Opening/closing a window requires Owner, scoped Leader/Vice, or scoped Admin with `update_cp`.
- Staff window reads are RPC-only through `get_cp_update_window_for_guild(p_guild_id uuid)`.
- Staff window reads require Owner, scoped Leader/Vice, or scoped Admin with `view_cp` or `update_cp`.
- Members and wrong-guild users cannot read selected-guild window status through the staff RPC.
- Closing a window only freezes submissions; weekly snapshots remain future work.

Member self-submit rules:
- Members can read their own current CP only through `get_my_cp()`.
- Members can submit their own CP only through `submit_my_cp_update(p_cp_value integer)`.
- Members cannot pass a target profile id.
- Members cannot directly SELECT or UPDATE `member_cp`.
- Members cannot directly read `cp_snapshots`.
- Members cannot directly read `cp_update_windows`.
- CP value must be non-negative.
- Database/server time decides whether a window is open.

Roster eligibility:
- `active`, `trial`, and `pending_transfer` can submit CP during an applicable open window.
- `inactive` and `on_break` can read own CP but cannot submit.
- `suspended`, `left`, and `kicked` remain hard-blocked by membership/security state.

Audit/redaction:
- Member submissions write `member_cp_self_submitted`.
- Audit metadata includes `cp_old`, `cp_new`, `window_id`, and source.
- `get_audit_logs(...)` redacts CP metadata for audit viewers without scoped `view_cp`.

Production operation rules:
- Milestone 19E production smoke was read-only; no production CP window was opened/closed and no production CP value was submitted.
- Optional production CP mutation smoke requires explicit approval, a controlled production test member, and a documented restore/retention decision.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## Milestone 17D Controlled Guild Onboarding Rules

Milestone 17D prepares the app copy for disabling email confirmation later, but production email confirmation remains enabled until a separately approved Auth setting change.

Onboarding rules:
- Admin approval remains the real access gate.
- Registered users must remain pending until approved by authorized staff.
- Pending users must not access member/admin areas.
- Users should register with a real email because password recovery depends on it.
- Password recovery must remain enabled.
- Disabling email confirmation does not grant app access by itself.
- Staff must review the approval queue carefully during bulk onboarding.
- Fake or typo emails can create pending accounts; reject unknown or suspicious registrations.

Validation before production Auth changes:
- Disable email confirmation in staging only first.
- Confirm new staging signups land pending without email confirmation.
- Confirm pending lockout, Owner approval, approved access, and password recovery still work.
- Do not change production Auth settings until staging validation passes and a production gate is approved.

## Milestone 15A Member Status Security Rules

Member Status is live in production as of Milestone 15E and remains separate from auth/approval and hard membership state.

Current rules:
- `profiles.approval_status` remains the account/registration gate.
- `guild_memberships.membership_status` remains the hard security/access gate.
- `guild_memberships.roster_status` is the roster lifecycle/status label.
- `active`, `trial`, and `pending_transfer` keep normal access.
- `inactive` and `on_break` are not hard lockouts; they keep active membership but are excluded from GvG participation/expectation.
- `suspended`, `left`, and `kicked` are hard roster-access blocks.
- `kicked` maps to `membership_status = 'left'` because `membership_status = 'rejected'` is reserved for registration/reapply.
- Members cannot change their own roster status.
- Admin with `manage_members` can set only non-terminal statuses and cannot affect Owners or self.
- Leader/Vice can set scoped non-Owner statuses.
- Owner can set all statuses, but the last active Owner cannot be blocked/removed.
- Private status reasons live in `member_status_history`, not in broadly visible audit metadata.
- Production roster-status mutation smoke was not performed during rollout.
- Any optional production mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.

## Milestone 14D Staging And Preview Rules

Milestone 14D documents staging/preview policy only. It did not create a staging project, link Supabase CLI, run Supabase commands, change Vercel env vars, deploy, commit, edit source logic, or edit SQL migrations.

Future staging rules:
- Staging must be a fresh Supabase project separate from production.
- Staging must use separate Auth users, URL, anon/publishable key, Owner bootstrap, and test data.
- Fake/test data is allowed only in staging.
- Do not copy production data into staging unless explicitly approved.
- Apply the same approved migrations as production.
- Do not use `db push --include-seed` until the missing `supabase/seed.sql` hazard is resolved.
- Confirm the target project ref before linking, pushing migrations, or bootstrapping Owner.

Future Vercel Preview rules:
- Production Vercel env remains production Supabase only.
- Preview Vercel env should point only to staging Supabase once staging exists.
- If staging is not ready, Preview env should remain unconfigured.
- Never add service role keys, `sb_secret_*`, database passwords/URLs, JWT secrets, SMTP secrets, or OAuth/provider secrets to frontend/Vercel env.
- Production Auth URLs stay production-only.
- Preview wildcard redirects, if needed, belong in staging Supabase, not production Supabase.

## Milestone 14A Production Hardening Rules

Milestone 14A documented production hardening policy only. It did not run production commands, change Vercel settings, change GitHub App settings, disable/delete/suspend users, edit source logic, edit SQL migrations, deploy, or commit.

Current production hardening rules:
- Restricting the Vercel GitHub App to `Ultimate99/anteiku-guild-manager` is recommended but must be performed manually only after explicit approval.
- Do not change Vercel env vars during GitHub App restriction.
- Keep the controlled production test member documented for now; do not hard-delete it without an approved cleanup plan.
- Preview deployments should have no Supabase env vars until a separate staging Supabase project exists.
- Future staging must be separate from production.
- Production GvG smoke tests that create data require explicit approval and a cleanup/data-retention plan.
- CP redaction browser tests should preferably use staging with a controlled staff/data setup.
- Milestone 14H completed staging coverage for deferred production GvG smoke and CP audit redaction using `ckyihuxkioeibzpgwenc`; do not repeat those tests in production without explicit approval and a cleanup/data-retention plan.

## Production Readiness Rules

Production deployment must not weaken existing RLS/RPC security.

Production is live at `https://anteiku-guild-manager.vercel.app`. Milestone 13B deployment validation passed, and Milestone 14A added hardening/cleanup policy documentation only.

Production hard rules:
- Current implemented production behavior keeps member-facing CP hidden. Corrected future CP privacy rule: members may see their own CP only through a safe backend/RPC flow, but must never see other members' CP.
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
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz` after Milestone 15E; explicitly relink before future staging/local Supabase work.

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
- CP roster, leaderboard, snapshots, and other members' CP remain unavailable to Members.
- Frontend must still avoid direct `member_cp` and `cp_snapshots` table access.

Future CP Update Window / Member CP Self-Submit rules:
- Members may see their own current CP through `get_my_cp` or equivalent safe RPC.
- Members may submit/update only their own CP through `submit_my_cp_update` or equivalent safe RPC.
- Backend must verify `auth.uid()`, approved active membership, self-only target, applicable open CP Update Window using database/server time, and guild/scope.
- Frontend disabled inputs are not security controls; backend/RPC remains the authority.
- CP submissions must write audit logs, and `get_audit_logs` CP metadata redaction must continue to work.

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

CP is private across users. Corrected future rule: members may see their own CP through approved backend/RPC flow, but must not see other members' CP or query CP tables directly.

Approved CP design:

- Do not store CP in `profiles`.
- Store current CP in `member_cp`.
- Store manual weekly history/growth in `cp_snapshots`.
- Members must never directly select `member_cp` or `cp_snapshots`.
- Members must not see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Future own-CP reads must use `auth.uid()` and return only the caller's own CP.
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
