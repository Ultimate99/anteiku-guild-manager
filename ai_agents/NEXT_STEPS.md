# Next Steps

## Current Recommendation

Milestone 14H staging CP audit redaction and GvG full-smoke validation is complete.

Recorded staging status:
- Staging Supabase project exists: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Project URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.
- Same 9 migrations as production were applied.
- Staging schema/RLS/seed verification passed.
- Permission catalog count is 10 and exactly matches the seed migration.
- Staging Owner exists and is verified:
  - Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
  - Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
  - Username/profile slug: `staging_owner`.
  - IGN: `Staging Owner`.
  - Role: `owner`.
  - Membership status: `active`.
  - Primary membership: `true`.
  - `active_owner_count = 1`.
  - `owner_bootstrapped` audit log count: `1`.
- Controlled staging test users exist and were verified in Milestone 14G:
  - `staging_member`
  - `staging_pending`
  - `staging_wrongguild`
  - `staging_audit_nocp`
  - `staging_audit_cp`
  - `staging_admin_noperms`
- Milestone 14H validation passed for CP audit redaction, CP metadata visibility, full GvG smoke, permission denial checks, wrong-guild denial, and pending lockout.
- Test data remains in staging intentionally.
- Production Supabase was not touched.
- Vercel Preview env remains unconfigured.
- No source or SQL files were changed.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.

Recommended next milestone:
- Vercel Preview env configuration with staging Supabase, or Member Status System planning.

Later milestone options:
- Configure Vercel Preview env with staging Supabase only after staging bootstrap planning is approved.
- Future CP-focused milestone: CP Update Window / Member CP Self-Submit.
- Controlled production test-member cleanup planning for `krsticmiroslav99+m13b21144225@gmail.com`, with no hard delete unless explicitly approved.
- AdminPanel polish planning for sticky-under-header tab behavior and slightly tighter small-mobile tab spacing.
- Future feature planning: reapply flow UI, suspended/left/rejected member management, weekly CP snapshot/growth report UI, or guild/subguild management UI.

## Future CP Update Window / Member CP Self-Submit

Record this as a future CP-focused milestone candidate after staging is fully usable and after staging CP redaction/GvG smoke validation.

Corrected CP privacy rule going forward:
- Members can see their own CP through an approved backend/RPC flow.
- Members can update/submit their own CP only through an approved backend/RPC flow.
- Members must not see other members' CP.
- Members must not see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Members must never directly select or update `member_cp`.
- Members must never directly read `cp_snapshots`.
- Admins/leaders/staff can see CP only through scoped role/permission checks and safe RLS/RPC.

Future behavior:
- AdminPanel CP tab can open, close, or schedule a CP Update Window.
- Member Profile can show a "Your CP" section with the member's own current CP only.
- If the update window is open, the member can submit their own CP.
- If the update window is closed, the input/update action is disabled and the backend rejects updates even if the frontend is bypassed.
- Staff can later review submitted CP through existing authorized CP tools.

Recommended backend-first design:
- Add a future `cp_update_windows` table with guild/scope, status, opens/closes timestamps, creator/closer, and audit-friendly timestamps.
- Add future RPCs: `create_cp_update_window`, `set_cp_update_window_status`, `get_active_cp_update_window_for_me`, `get_my_cp`, and `submit_my_cp_update`.
- `get_my_cp` must use `auth.uid()` and return only the caller's own CP.
- `submit_my_cp_update` must use `auth.uid()`, verify approved active membership, verify the caller updates only self, verify the window is open using database/server time, and verify the window applies to the caller's guild/scope.
- Admin open/close must require Owner/Leader/Vice scope or a safe CP permission such as `update_cp` or a future `manage_cp_windows`.
- Audit logs must record CP submissions/updates, and `get_audit_logs` CP metadata redaction must continue to work.

Future frontend surfaces:
- AdminPanel CP tab: status badge (`Open`, `Closed`, `Scheduled`), open/close controls, optional guild scope, start/end time, notes, and countdown.
- Member Profile: "Your CP", own current CP, input/submit while open, disabled state while closed, success/error state.

Future validation requirements:
- Member can see own CP but not other members' CP.
- Member cannot access CP roster, leaderboard, snapshots, or other members' CP history.
- Member cannot directly query `member_cp` or `cp_snapshots`.
- Member can submit own CP while window is open.
- Member cannot submit while window is closed.
- Member cannot submit CP for another profile.
- Wrong-guild member cannot use another guild's CP window.
- Admin can open/close CP window in scope.
- CP submission writes audit log.
- Audit metadata redacts correctly for users without `view_cp`.
- Network validation shows only safe RPCs: `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update`.

Do not start the next feature, production operation, or cleanup action without a dedicated plan, explicit approval, and security review.

## Previous Recommendation - Milestone 14B

Milestone 14B Vercel GitHub App restriction verification and docs checkpoint is complete.

Validated:
- Production project ref is `mzflfyxxkascrfpteexz`.
- All 9 approved migrations are applied remotely.
- Production schema/RLS/seed verification passed.
- Protected tables, policies, RPCs, grants, indexes, constraints, and seed data were verified.
- Owner bootstrap completed for `ultimatesrb` / `UltimateSRB` in `Anteiku`.
- Exactly one active Owner membership exists.
- `owner_bootstrapped` audit log exists.
- Vercel project is deployed from `Ultimate99/anteiku-guild-manager` on `main`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Site URL and Redirect URL allow-list are configured for the production URL.
- Production Vercel env uses only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- No service role key or secret keys were added to frontend/Vercel env.
- Owner login, AdminPanel, Audit Logs, CP Management, pending user lockout, Member approval, Member CP denial, Network checks, and mobile checks passed.
- Milestone 14A recorded production hardening policy only.
- No production commands, Vercel setting changes, GitHub App changes, user cleanup, source changes, SQL changes, deployment, or commit were performed during Milestone 14A.
- Vercel GitHub App installation is now limited to `Ultimate99/anteiku-guild-manager` per manual user confirmation.
- Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Production app health was checked after the restriction.
- No Vercel env vars were changed during Milestone 14B.
- No source logic or SQL migrations were changed during Milestone 14B.

Documented deferred items:
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data without a cleanup/delete flow.
- CP redaction browser test was intentionally not tested because no production staff/data combination exists for `view_audit_logs` without `view_cp` plus fresh CP-sensitive audit metadata.
- Both deferred areas have earlier backend/source/local validation coverage: GvG in Milestone 10 and audit CP redaction in Milestone 11A/11B.

Production note:
- Controlled test member `krsticmiroslav99+m13b21144225@gmail.com` remains in production as an approved Member unless later cleanup/member management is explicitly approved.
- Vercel GitHub App restriction is complete.
- Preview deployments should have no Supabase env vars until the approved Vercel Preview configuration milestone.
- Never let Preview deployments mutate production by default.

Historical next options at that checkpoint:
- Choose one approved production-hardening or cleanup action.
- Staging Supabase + Vercel Preview environment planning.
- Controlled production test-member cleanup planning.

Alternative future feature planning options after hardening:
- Reapply flow UI/RPC integration.
- Weekly CP snapshot/growth report planning.
- Suspended/left/rejected member management planning.
- Guild/subguild management planning.

Do not start the next feature or production operation without a dedicated plan, explicit approval, and security review.

## Historical Note

Milestone 11A backend audit-log read hardening is implemented and locally validated.

Milestone 11B was later implemented and live-browser validated using `public.get_audit_logs(...)`.

Important constraints:
- Do not direct-read `public.audit_logs` from the frontend.
- Do not display unredacted CP metadata to users without `view_cp`.
- Do not add CP, GvG, role/guild, or permission management changes during 11B unless separately approved.
- Keep audit UI read-only.

## Current Recommendation

Milestone 10 GvG event management and member voting persistence is complete and live browser validated.

Recommended next milestone:
- Milestone 11 planning: choose the next security-reviewed feature area before implementation.

Strong candidates:
- Audit log viewer.
- Production Supabase/bootstrap/deployment planning.
- Weekly CP snapshot/growth report UI.
- Reapply flow UI.

Do not start the next feature without a dedicated plan and security review.

## Current Recommendation

Milestone 9 permission management validation passed. Recommended next milestone:
- Milestone 10 planning: choose the next security-reviewed feature before implementation.

Strong candidates:
- GvG event/voting UI.
- Audit log viewer.
- Production Supabase/bootstrap/deployment planning.
- Weekly CP snapshot/growth report planning.

Do not start GvG, audit logs, or production deployment without a dedicated plan and security review.

## Current Recommendation

Milestone 9 permission management implementation is build-validated. Recommended next step:
- Manual browser validation for Admin permission checkbox management.

Manual validation should confirm:
- Owner can grant/revoke `approve_members` to an Admin.
- Owner can grant/revoke `view_cp` and `update_cp` to an Admin.
- Leader/Vice can manage non-CP Admin permissions only inside assigned guild scope.
- Leader/Vice cannot toggle `view_cp` or `update_cp`.
- Admin cannot see Permission Management UI.
- Member cannot see Admin tab.
- Network writes use only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes occur.
- Permission management does not call CP data RPCs.

## Current Recommendation

Milestone 8 frontend CP validation passed. Recommended next milestone:
- Milestone 9 planning: choose the next security-reviewed feature area before implementation.

Strong candidates:
- GvG event/voting UI using existing validated vote rules.
- Permission checkbox management UI.
- Audit log viewer.
- Production Supabase/bootstrap/deployment planning.

Important reminder:
- After local DB resets, clear browser localStorage/sessionStorage before auth/registration retesting to avoid stale local session issues.

## Current Recommendation

Milestone 8 frontend CP implementation is build-validated. Recommended next step:
- Manual browser validation for Admin-only CP management and leaderboard.

Manual validation should confirm:
- Owner sees CP section.
- Owner updates member CP.
- Owner sees leaderboard.
- Leader sees scoped CP only.
- Admin without `view_cp` cannot see CP section.
- Admin with `view_cp` can view but not update.
- Admin with `update_cp` can update.
- Member cannot see CP UI.
- Member Network tab shows no CP calls.
- Network tab shows no direct `member_cp` or `cp_snapshots` calls.
- CP reads use `get_current_cp_roster` and `get_cp_leaderboard`.
- CP writes use `update_member_cp`.

## Current Recommendation

Milestone 8 backend CP hardening validation passed. Recommended next step:
- Plan Milestone 8 frontend CP management and leaderboard UI.

Important constraints:
- CP frontend must use only approved CP RPCs.
- Do not query `member_cp` or `cp_snapshots` directly.
- Do not show CP on member dashboard/profile.
- Do not implement GvG in this milestone.

## Current Recommendation

Run local Supabase validation for Milestone 8 backend CP hardening before any CP frontend UI.

Suggested validation:
- `npx.cmd supabase db reset`
- Run `supabase/tests/local_validation_anteiku.sql`

Do not implement CP frontend until the new CP hardening checks pass.

## Current Recommendation

Milestone 7 frontend browser validation passed. Recommended next milestone:
- Milestone 8 planning: choose the next safe feature area before implementation.

Suggested candidates:
- CP admin-only management and leaderboard planning, with a fresh CP security review first.
- GvG event/voting frontend planning, using existing one-vote-per-event backend rules.
- Permission checkbox management UI planning.
- Audit log viewer planning.

Do not start GvG or CP implementation without a dedicated plan and security review.

## Current Recommendation

Milestone 7 frontend implementation is complete and build-validated. Recommended next step:
- Manual browser validation for Admin member role changes and Owner-only guild transfer.

Manual validation should confirm:
- Owner changes a member role `member -> admin -> member`.
- Owner cannot select `owner`.
- Owner transfers a member to a different guild.
- Transfer resets the member role to `member`.
- Transferred member can sign in and sees the new guild/role.
- Normal Member still cannot see Admin tab.
- Network tab writes only use `assign_member_role` and `transfer_member_guild`.
- No CP/GvG calls appear.

## Current Recommendation

Milestone 7 backend validation passed. Recommended next step:
- Plan Milestone 7 frontend integration for Admin member guild + role management.

Important constraints for the next step:
- Use existing validated RPCs for role/guild changes.
- Do not expose Owner assignment in frontend.
- Do not add CP UI or CP queries.
- Do not add GvG yet.
- Do not directly update `guild_memberships` from frontend.
- Keep role/guild changes RPC-only.

## Current Recommendation

1. Run local Supabase validation for Milestone 7 backend role/guild RPC changes.
2. Do not use production Supabase yet.
3. Do not add frontend member guild/role UI until backend validation passes.
4. Do not add GvG UI yet; GvG is intentionally later.
5. Keep CP table/RPC access forbidden from member/admin profile-management UI until explicit CP milestone.

Suggested local validation:
- `npx.cmd supabase db reset`
- Run `supabase/tests/local_validation_anteiku.sql` against the local Supabase database.

After validation passes:
- Plan frontend integration for Admin member guild + role management.
- Keep Owner assignment manual-only and outside normal app RPC/UI.

Recommended next task:

1. Locally validate Milestone 7 backend migration and validation script.
2. Do not use production Supabase until deployment steps and production bootstrap are explicitly approved.

Current validated backend assets:

- Supabase migrations apply locally.
- Local validation script passes 29 PASS / 0 FAIL / 0 SKIP.
- CP privacy and scoped role access are validated locally.
- GvG one-vote/update behavior is validated locally.
- Approval/reapply and audit spoof protections are validated locally.
- Frontend local Supabase auth integration is implemented.
- Registration uses `register_profile` RPC.
- Pending/rejected/suspended gating is implemented in the frontend.
- Frontend does not query CP tables or CP RPCs.
- `npm.cmd run build` passes after Milestone 3 implementation.
- Manual Milestone 3 browser validation passed against local Supabase.
- The AuthContext stuck-loading bug is fixed and no longer reproduces.
- Milestone 4 frontend approval UI/service is implemented.
- Approval queue reads use current RLS-safe `guild_memberships` reads with safe related profile/guild fields.
- Approval/rejection writes use only `approve_registration` and `reject_registration` RPCs.
- No frontend Owner approval option exists.
- `npm.cmd run build` passes after Milestone 4 implementation.
- Local Owner bootstrap was manually applied outside migrations for testing.
- Manual Milestone 4 browser validation passed.
- Approved app shell Sign out is visible and works.
- Owner approval/rejection flow works locally.
- Normal members cannot see the Admin tab.
- Rejected users remain blocked from app shell/member/admin screens.
- Milestone 5 member profile IGN editing is implemented.
- Profile edits use `update_my_profile` RPC only.
- Username/profile slug/guild/role/status/avatar remain locked/display-only in the Profile UI.
- `npm.cmd run build` passes after Milestone 5 implementation.
- Manual Milestone 5 browser validation passed.
- Owner and Member can edit own IGN.
- Profile update uses `update_my_profile` RPC only.
- No direct profile/membership updates or protected CP calls were observed.
- Milestone 6 admin member management is implemented.
- Active approved member roster uses current RLS-safe reads.
- Admin member IGN edits use `admin_update_member_ign` RPC only.
- Admin username/profile slug resets use `admin_reset_profile_slug` RPC only.
- Roster excludes pending/rejected/left/suspended users.
- `npm.cmd run build` passes after Milestone 6 implementation.
- Manual Milestone 6 browser validation passed.
- Owner can edit member IGN and reset username/profile_slug.
- Username/profile_slug remained equal and lowercase after reset.
- Normal member Admin tab remains hidden.
- No CP table/RPC calls were observed during Milestone 6 testing.
- Milestone 7 backend migration has been created.
- Role assignment hardening and Owner-only guild transfer RPC are implemented in SQL.
- Local validation script has Milestone 7 role/transfer checks.
- Milestone 7 local validation has not been run yet.

Recommended next milestone:

- Milestone 7 validation: run local Supabase reset and local validation script, then review/fix any SQL/RPC issues before frontend role/guild management UI.

Alternative next step:

- Prepare a disposable remote Supabase validation/deployment checklist before any production project use.

Still required:

- Real Owner bootstrap with a known Supabase Auth user id.
- Remote Supabase environment setup approval.
- Reapply UI/RPC integration.
- Admin/staff member guild changes.
- Admin/staff role changes.
- GvG persistence UI.
