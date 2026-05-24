# Next Steps

## Current Recommendation

Milestone 19E CP Update Window production rollout is complete. CP Update Window / Member CP Self-Submit is live in production after production DB migration verification, frontend deployment, and read-only Owner/member smoke validation.

Recorded Milestone 19B/19B.1 backend status:
- New migration: `20260524000100_cp_update_window_self_submit.sql`.
- New follow-up migration: `20260524000200_cp_update_window_staff_read.sql`.
- Added guild-scoped `cp_update_windows` with one open window per guild.
- Added safe RPCs for own-window status, own-CP read, member self-submit, and staff open/close.
- Added staff-safe selected-guild read RPC `get_cp_update_window_for_guild(p_guild_id uuid)`.
- Member self-submit is restricted to `active`, `trial`, and `pending_transfer`.
- `inactive` and `on_break` can read own CP but cannot submit.
- `suspended`, `left`, and `kicked` remain hard-blocked.
- Members still cannot directly read/write `member_cp`, read `cp_snapshots`, or read window rows directly.
- `member_cp_self_submitted` audit metadata redacts CP old/new values for viewers without scoped `view_cp`.
- `npx.cmd supabase db reset` passed locally.
- `supabase/tests/local_validation_anteiku.sql` passed, including Milestone 19B result 32 PASS / 0 FAIL / 0 SKIP and Milestone 19B.1 result 13 PASS / 0 FAIL / 0 SKIP.
- Staging rollout and validation passed in Milestone 19D.
- Production rollout and read-only smoke passed in Milestone 19E.

Recorded Milestone 19C/19D/19E frontend and rollout status:
- New frontend service: `src/services/cpWindowService.js`.
- Service wrappers use RPCs only: `get_my_cp`, `get_active_cp_update_window_for_me`, `submit_my_cp_update`, `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.
- Profile shows a compact `Your CP` panel that reads only the signed-in member's own CP and lets eligible members submit CP only through `submit_my_cp_update`.
- AdminPanel CP tab shows CP Update Window status for the selected guild and exposes open/close controls to existing CP-authorized staff UI.
- Staging browser validation passed for Owner open/close, Member self-submit, audit redaction, audit+CP visibility, and Admin-without-permissions denial.
- Production received only `20260524000100` and `20260524000200` during Milestone 19E.
- Production DB verification passed for `cp_update_windows`, RLS, one-open-window unique index, safe RPCs/grants, direct grant absence, audit redaction support, and active Owner count.
- Frontend commit `6a3a181 feat: add CP update window self-submit` was pushed and deployed.
- Production smoke passed for Owner AdminPanel CP tab/window status and Member Profile `Your CP` closed-window state.
- No controlled production CP mutation smoke was performed by design.

Recommended next milestone:
- Docs/handoff commit checkpoint for Milestone 19E.

Later milestone options:
- Optional controlled production CP mutation smoke with explicit approval.
- Weekly CP Snapshot/Growth Reports planning after CP Update Window is deployed.
- Member status history UI planning.
- Announcements, invite codes, or onboarding tools.

## Previous Recommendation - Milestone 18F

Milestone 18F Language Pack production rollout is complete. The app now has a live frontend-only EN/FR/DE language system in production, including full AdminPanel translations.

Recorded Milestone 18F status:
- Deployed commit `1f5b956 feat: add English French German language pack`.
- Supported languages: English, French, and German.
- Language switcher works logged out and logged in.
- Language persists after reload.
- Login/register/forgot-password copy translates.
- Owner AdminPanel opens and AdminPanel tabs translate across EN/FR/DE.
- Members, CP, GvG, Audit Logs, Permissions, and Tools tabs render in production.
- No raw translation keys were visible.
- No console errors were captured during production smoke.
- Mobile/narrow viewport had no horizontal overflow.
- Existing production Member had no Admin navigation.
- No SQL, Supabase/RLS/RPC, service behavior, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.

Recommended next milestone:
- Docs/handoff commit checkpoint for Milestone 18F.
- French/German admin wording review by native speakers.
- Then choose the next approved feature planning track.

Later milestone options:
- Member-facing UI cleanup planning.
- CP Update Window planning.
- Weekly CP Snapshot/Growth Reports planning.
- Member status history UI planning.
- Announcements or onboarding/invite-code planning.

## Previous Recommendation - Milestone 15E

Milestone 15E production rollout is complete. The Member Status System is live in production after DB migration, frontend deployment, and production smoke validation.

Recorded Milestone 15E status:
- Production project: `mzflfyxxkascrfpteexz` / `Anteiku Guild Manager Production`.
- Applied only `20260523000100_member_roster_status_system.sql`.
- Production DB verification passed.
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- `main` was pushed and Vercel deployed the frontend.
- Production smoke validation passed for Owner Member Status UI, Owner CP/Audit/GvG loading, Member Dashboard/Profile/GvG, Member AdminPanel denial, and CP non-leakage.
- No production roster-status mutation smoke was performed.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase work.

Recorded Milestone 15D status:
- Staging project: `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending.
- The 15A migration was applied to staging only.
- Staging schema/RLS verification passed for `roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, backfilled staging memberships, and active Owner count.
- `staging_owner` validated Admin Members roster badges, filter, and status controls.
- `staging_member` was tested through `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, and restored to `active`.
- `suspended` showed the restricted notice and blocked member/admin areas.
- `on_break` allowed Home/Profile and showed not expected for GvG with no vote controls.
- `staging_admin_noperms` had no Members/status/CP/Audit/GvG management controls.
- Final `staging_member` state is `membership_status = active` and `roster_status = active`.
- Read-only verification found 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows.
- `.env.local` was restored to local Supabase after validation.
- Production, Vercel env, deployment, and commit actions were not performed.

Recorded Milestone 15B status:
- Safe frontend reads include `roster_status`.
- Admin Members tab has roster status badges, status filtering, and status-change controls.
- Status writes use only `update_member_roster_status(...)` through `adminMemberService.js`.
- Hard-block status changes require a reason and confirmation.
- Private `member_status_history` reasons/history are not displayed.
- Dashboard/Profile show safe roster status badges/notes.
- Roster `suspended`, `left`, and `kicked` show a restricted notice instead of member/admin areas.
- GvG hides vote controls for `inactive` and `on_break` users.
- `npm.cmd run build` passed.
- Static source/security checks passed.
- Browser validation passed through staging in Milestone 15D.
- No SQL migrations, Supabase tests, backend/RLS/RPC logic, production, Vercel env, deployment, or commit actions were included.

Recorded Milestone 15A backend status:
- New migration: `supabase/migrations/20260523000100_member_roster_status_system.sql`.
- `guild_memberships.roster_status` is the current roster lifecycle status.
- `member_status_history` stores staff-only private status history/reasons.
- `update_member_roster_status(...)` is the safe status-change RPC.
- `member_roster_status_changed` audit logs are written without full private reason text.
- `inactive` and `on_break` preserve active membership but are excluded from GvG eligibility/expectation.
- `suspended`, `left`, and `kicked` hard-block access by changing `membership_status`; `kicked` maps to `membership_status = 'left'`.
- Local validation passed: `npx.cmd supabase db reset` and `supabase/tests/local_validation_anteiku.sql`.
- Milestone 15A focused validation result: 22 PASS / 0 FAIL / 0 SKIP.
- Production Supabase was not touched.
- Vercel Preview env remains unconfigured.
- No deployment or commit was performed.

Recommended next milestone:
- Optional controlled production status mutation smoke, using the controlled production test member only with explicit approval and restore to `active`.
- CP Update Window planning.
- Weekly CP Snapshot/Growth Reports planning.
- Member status history UI planning.
- Announcements or onboarding/invite-code planning.

Later milestone options:
- Configure Vercel Preview env with staging Supabase only after an approved plan.
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
## Completed Milestone 18E/18F Language Validation And Rollout

Milestone 18E authenticated staging validation passed, and Milestone 18F production rollout is complete.

Recorded status:
- `staging_owner` validated AdminPanel EN/FR/DE translations across all AdminPanel tabs.
- `staging_admin_noperms` validated restricted-admin state.
- Member/pending sanity checks were intentionally skipped in 18E by user direction because they were already covered in Milestone 18C.
- Production smoke passed after pushing `1f5b956 feat: add English French German language pack`.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.
