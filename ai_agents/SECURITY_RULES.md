# Security Rules

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
