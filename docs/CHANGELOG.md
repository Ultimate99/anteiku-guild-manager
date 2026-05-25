# Changelog

## 2026-05-25 - Milestone 22F Cosmetics Catalog Sync Script

- Added local developer tooling script `scripts/sync-cosmetics-catalog.mjs`.
- Added npm command `npm.cmd run cosmetics:sync`.
- Script scans `public/cosmetics/avatars/` and `public/cosmetics/frames/` for `.png` and `.webp` files.
- Script generates timestamped `supabase/migrations/*_cosmetics_catalog_sync.sql` files that upsert `public.cosmetic_catalog` rows.
- Generated rows use filename-without-extension keys, repo-backed `/cosmetics/...` asset paths, i18n label keys, deterministic sort order, and `ON CONFLICT (key) DO UPDATE`.
- Unlock defaults: `_FREE` keys are free, v1 avatars without `_FREE` are free, and frames without `_FREE` are manual.
- Dry-run and normal generation were validated locally; generated migration `20260525193210_cosmetics_catalog_sync.sql` was created but not applied.
- `npm.cmd run build` passed.
- No runtime app behavior, Supabase/RLS/RPC behavior, staging, production, deployment, uploads, Supabase Storage, or arbitrary URL behavior changed.

## 2026-05-25 - Leaderboard Podium Polish Live

- Deployed `3f65052 style: tune leaderboard podium layout`.
- Desktop leaderboard podium now visually orders `#2 | #1 | #3`.
- Mobile leaderboard podium stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger centered gold styling and a larger avatar/frame.
- Rank #2 has silver styling.
- Rank #3 has bronze styling.
- Build passed and production app load smoke passed with no captured console errors.
- This was frontend/style-only; no ranking logic, backend/RPC, SQL, Supabase/RLS, Vercel env, production data, or CP privacy behavior changed.

## 2026-05-25 - Milestone 23D Premium Cosmetics Production Rollout Complete

- Applied `20260525000300_premium_cosmetics_grant_helper.sql` to production project `mzflfyxxkascrfpteexz` after dry-run review showed exactly that migration pending.
- Confirmed production already had `20260525000200_cp_rankings_cosmetics.sql` applied.
- Verified `admin_grant_cosmetic_by_slug(...)` exists in production.
- Verified `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- Verified `equip_my_avatar(...)` and `update_my_profile(...)` contain free-or-unlocked/manual-lock enforcement.
- Verified all 10 current frame rows are now free in production.
- Verified direct authenticated write grants to cosmetics unlock/equipped tables remain absent.
- Verified normal Member grant attempt is denied and active Owner count remains `1`.
- Production app load smoke passed with no captured console errors.
- Locked/manual grant/equip runtime success was not repeated in production because production has no active manual cosmetics and production mutation smoke was not approved; staging covered that path in Milestone 23C.
- No frontend deploy, Vercel env change, source edit, SQL edit, new migration, `db reset`, `--include-seed`, service-role key, Supabase Storage, upload path, arbitrary URL path, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`.

## 2026-05-25 - Milestone 23C Premium Cosmetics Staging Rollout Complete

- Applied staging catch-up migrations `20260525000200_cp_rankings_cosmetics.sql` and `20260525000300_premium_cosmetics_grant_helper.sql` to staging project `ckyihuxkioeibzpgwenc` after dry-run showed exactly those two migrations.
- Verified current frames became free on staging.
- Verified `get_my_cosmetics()` avatar unlock fields, locked manual avatar/frame denial before grant, owner grant by profile slug, member/admin denial, granted manual avatar/frame equip, and cosmetic grant audit rows.
- Added staging-only manual test catalog rows `staging_premium_avatar_23c` and `staging_premium_frame_23c` using existing approved repo asset paths.
- Production was not touched during 23C.

## 2026-05-25 - Milestone 23B Premium Cosmetics Backend Implemented Locally

- Added new migration `20260525000300_premium_cosmetics_grant_helper.sql`.
- Did not edit deployed migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Updated all currently existing frame cosmetics to `unlock_type = 'free'`.
- Preserved catalog `unlock_type` as the runtime source of truth; `_FREE` remains only an asset/import naming convention.
- Hardened `equip_my_avatar(...)` so manual avatars require a caller-owned unlock row.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so manual avatars require a caller-owned unlock row before legacy profile avatar update.
- Updated `get_my_cosmetics()` so avatar rows include `unlock_type`, `is_unlocked`, and `is_equipped`.
- Added `admin_grant_cosmetic_by_slug(p_profile_slug, p_cosmetic_key, p_reason)` for exact username/profile-slug grants using existing member-management authority.
- Kept `admin_grant_cosmetic(profile_id, key, reason)` compatible.
- Updated local validation SQL with premium avatar/frame denial, grant-by-slug, unlocked equip, update-profile hardening, invalid input denial, member/admin permission denial, and audit checks.
- Local `npx.cmd supabase db reset` passed.
- Full local validation passed through Docker `psql`; Milestone 23B result: 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend source changed.
- Staging, production, Vercel, frontend UI, Supabase Storage, uploads, arbitrary URL behavior, CP/GvG/audit/role/permission/member-status behavior, and commits were not touched.

## 2026-05-25 - Milestone 22E Cosmetics Production Rollout Complete

- Applied `20260525000100_cosmetics_catalog_unlocks.sql` to production project `mzflfyxxkascrfpteexz` after dry-run review showed exactly that migration pending.
- Verified production cosmetics tables, RLS, catalog counts, exact repo asset-path match, RPC existence/grants, direct-write denial, active Owner count `1`, and `update_my_profile(...)` avatar hardening.
- Merged `wip/cosmetics-backend-assets` into `main` and pushed the cosmetics backend/assets/frontend rollout.
- Vercel deployed the production cosmetics picker and static assets.
- User-confirmed production cosmetics UI smoke passed.
- Owner `ultimatesrb` equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` remains approved/active but did not receive an equipped cosmetics row during this smoke.
- Cosmetics use approved repo static assets only. No player uploads, arbitrary URLs, Supabase Storage, service-role path, direct cosmetics table writes, CP/GvG/audit/role/permission/member-status behavior changes, `db reset`, or `--include-seed` were introduced.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`; relink deliberately before staging/local Supabase commands.

## 2026-05-25 - Milestone 22C Frontend Cosmetics Picker Implemented

- Added frontend-only Profile cosmetics picker for the locally validated Milestone 22B cosmetics backend.
- Added `src/services/cosmeticsService.js` using only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- Added `src/components/CosmeticPreview.jsx` for static avatar/frame previews.
- Updated Profile to render equipped avatar/frame visuals, list available avatars, list free/unlocked/locked frames, equip avatars, and equip free/unlocked frames.
- Locked frames are visible but disabled until unlocked by backend state.
- Avatar equip refreshes the auth profile so legacy `profiles.avatar_key` stays in sync.
- Added mobile-first dark/crimson cosmetics picker styles.
- Added EN/FR/DE cosmetics labels.
- `npm.cmd run build` passed.
- Source validation found no direct frontend `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics` calls.
- Source validation found no admin cosmetic grant UI and no new direct CP/audit/GvG protected table paths.
- Local Vite dev server reached `http://127.0.0.1:5173`.
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel env, deployment, push, or commit action was included.
- Browser validation later passed through staging in Milestone 22D, and production rollout completed in Milestone 22E.
- Staging and production now have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified.

## 2026-05-25 - Milestone 22B.1 Cosmetics Catalog Asset Alignment

- Aligned the local cosmetics catalog seed with actual files under `public/cosmetics/avatars/` and `public/cosmetics/frames/`.
- Seeded 54 free avatar keys using file names without extensions, with `1079_head` as the default avatar.
- Seeded 10 frame keys using file names without extensions, with `TXK_frame_reOpen_EN_FREE` as the default frame.
- Mapped frame keys ending `_FREE` to `unlock_type = 'free'`.
- Mapped non-`_FREE` frames to `unlock_type = 'manual'`, so they require profile unlock rows before equip.
- Verified catalog asset paths against the local filesystem: 64 rows checked, 0 missing files, 0 unlock mapping problems.
- Local Supabase reset passed and full local validation passed through Docker `psql`, including Milestone 22B result 19 PASS / 0 FAIL / 0 SKIP.
- Staging and production were not touched.

## 2026-05-25 - Milestone 22B Cosmetics Backend Implemented

- Added backend/database-only support for preset avatars, unlocked/equipped frames, and future cosmetic rewards.
- Created migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Added `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Seeded catalog data for repo static assets under `public/cosmetics/avatars/` and `public/cosmetics/frames/`.
- Captured the `_FREE` naming convention: `_FREE` catalog keys map to `unlock_type = 'free'`, while catalog `unlock_type` remains the runtime source of truth.
- Added RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so arbitrary avatar keys are rejected.
- `equip_my_avatar(...)` syncs `profiles.avatar_key` for backward compatibility.
- Added RLS policies for active catalog reads and caller-owned unlock/equipped reads; direct client writes are not granted.
- Added cosmetic audit actions for avatar equip, frame equip, and admin grant.
- Updated local validation SQL with Milestone 22B coverage.
- Local Supabase reset passed.
- Full local validation passed through Docker `psql`, including Milestone 22B result 19 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend/source UI code changed.
- Staging and production were not touched.
- Future cosmetics picker frontend must wait until the target DB has `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified.

## 2026-05-24 - Milestone 21E Rank Badge / Profile Border Production Rollout Complete

- Applied Rank Badge Summary migration `20260524000400_cp_rank_badge_summary.sql` to production after dry-run review showed only that migration pending.
- Verified production `get_my_cp_rank_summary()` exists, is security definer, grants execute to `authenticated`, does not grant execute to `anon`, and returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Verified an authenticated member-context RPC response contained no CP values, growth/history/snapshot data, timestamps, updated-by metadata, profile ids, usernames, or private metadata.
- Verified direct authenticated member-context reads of `member_cp` and `cp_snapshots` returned zero rows.
- Pushed and deployed commit `e99bec0 feat: add rank badge UI`.
- Production Owner smoke passed: Dashboard rank badge rendered, AdminPanel opened, existing CP tab rendered CP roster/window controls, and `CP Ranking` rendered for Owner.
- Production controlled Member smoke passed: Dashboard/Profile showed the safe default rank badge state, Profile border/badge rendered, Member had no Admin navigation, and EN/FR/DE rank labels worked.
- No production CP/member data, Vercel env vars, service role keys, source edits, SQL edits, staging project, `db reset`, or `--include-seed` action was used during rollout.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## 2026-05-24 - Milestone 21D Rank Badge Staging Validation Passed

- Applied Rank Badge Summary migration `20260524000400_cp_rank_badge_summary.sql` to staging only after dry-run review showed only that migration pending.
- Verified staging `get_my_cp_rank_summary()` safe return shape, authenticated execute grant, no anon execute grant, direct CP table denial, and active Owner count `1`.
- Browser-validated `staging_member` Dashboard/Profile rank badge with `Global Rank #1` / `Rank 1`.
- Browser-validated `staging_wrongguild` safe unranked/default state and `staging_pending` pending lockout.
- Confirmed EN/FR/DE labels and mobile layout.
- Confirmed Profile/Dashboard badge path uses only `get_my_cp_rank_summary()` and no direct CP table/member/admin leaderboard calls.
- Restored `.env.local` to local Supabase after validation.
- Production was not touched.

## 2026-05-24 - Milestone 21C Profile/Dashboard Rank Badge UI Implemented

- Added frontend-only Rank Badge / Profile Border UI.
- Created `src/services/cpRankBadgeService.js` using only `get_my_cp_rank_summary()`.
- Created `src/components/RankBadge.jsx`.
- Profile now shows a rank-based profile border and badge in the profile header.
- Dashboard now shows a compact rank badge in the member summary.
- Added EN/FR/DE `rankBadge` labels.
- Added dark/crimson badge and profile-border styling for `rank_1`, `rank_2`, `rank_3`, `elite_5`, `top_10`, `high_rank`, `ranked_member`, and `unranked`.
- Confirmed the badge path does not call `get_member_cp_rankings`, `get_admin_cp_rankings`, `get_cp_leaderboard`, `get_current_cp_roster`, or direct CP tables.
- Confirmed the badge UI does not render CP values, growth/history/snapshot data, profile ids, updated-by metadata, or other-member data.
- `npm.cmd run build` passed.
- Authenticated browser validation remains pending until staging receives `20260524000400_cp_rank_badge_summary.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 21B Rank Badge Summary Backend Implemented

- Added backend/database-only support for safe rank badge/profile border visuals.
- Created migration `20260524000400_cp_rank_badge_summary.sql`.
- Added RPC `get_my_cp_rank_summary()`.
- RPC returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- RPC does not return CP values, updated timestamps, growth/history/snapshot data, updated-by metadata, usernames, profile ids, other-member data, or private metadata.
- Rank tier keys are `rank_one`, `rank_two`, `rank_three`, `elite_five`, `top_ten`, `high_rank`, `ranked_member`, and `unranked`.
- Visual keys are `rank_1`, `rank_2`, `rank_3`, `elite_5`, `top_10`, `high_rank`, `ranked_member`, and `unranked`.
- Uses `auth.uid()` and accepts no target profile id parameter.
- Uses the same eligible row set as member-safe CP rankings: approved active primary memberships with roster status `active`, `trial`, or `pending_transfer`.
- `inactive` and `on_break` return the unranked/default state; hard-blocked users remain denied by existing gates.
- Updated local validation SQL with Milestone 21B checks.
- Local Supabase reset passed.
- Local validation passed through Docker `psql`, including Milestone 21B result 15 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because no frontend/source UI code changed.
- No React components, frontend services, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 20F CP Leaderboard Production Rollout Complete

- Applied CP Leaderboard migration `20260524000300_cp_rankings.sql` to production after a clean retry dry-run.
- Verified production ranking RPCs and authenticated execute grants.
- Verified member ranking responses contain no CP/private fields.
- Verified Owner admin rankings return CP values through `get_admin_cp_rankings`.
- Verified non-Owner global admin rankings are denied.
- Verified direct `member_cp` and `cp_snapshots` reads remain blocked for normal authenticated users.
- Pushed and deployed commit `7ccf8c9 feat: add CP ranking UI`.
- Production Member smoke passed for My Guild and Global rankings with no CP value exposure.
- Production Owner smoke passed for existing AdminPanel `CP` tab controls and separate `CP Ranking` tab with Guild/Global admin rankings.
- No production CP/member data, Vercel env vars, service role keys, source files, SQL migrations, staging project, `db reset`, or `--include-seed` action was changed during rollout.
- Supabase CLI remains linked to production and must be relinked before future staging/local Supabase commands.

## 2026-05-24 - Milestone 20E CP Leaderboard Staging Validation Passed

- Applied CP Leaderboard migration `20260524000300_cp_rankings.sql` to staging only.
- Dry-run showed only the expected CP Ranking migration pending.
- Verified staging ranking RPCs and authenticated execute grants.
- Verified member ranking responses contain no CP/private fields.
- Verified Owner admin rankings return CP values through `get_admin_cp_rankings`.
- Verified non-Owner global admin rankings are denied.
- Verified pending user and Admin-without-CP ranking access are denied.
- Browser-validated member My Guild and Global rankings with no CP value exposure.
- Browser-validated Owner AdminPanel CP roster/window controls and separate `CP Ranking` tab.
- Browser-validated restricted Admin state with no CP or CP Ranking access.
- Moved AdminPanel CP leaderboard into a separate `CP Ranking` tab after validation feedback.
- `npm.cmd run build` passed after the UI placement fix.
- Restored `.env.local` to local Supabase.
- No production, Vercel env, deployment, commit, SQL edit, or new migration action was performed.

## 2026-05-24 - Milestone 20D AdminPanel CP Leaderboard Upgrade Implemented

- Added frontend-only AdminPanel CP leaderboard upgrade.
- AdminPanel CP leaderboard now uses `get_admin_cp_rankings`.
- Added separate AdminPanel `CP Ranking` tab with Guild and Global tabs.
- Guild tab uses the selected CP guild scope and shows CP values through the permission-checked admin RPC.
- Global tab is visible only to Owner in the frontend; backend RPC authorization remains authoritative.
- Added compact decorated admin rank rows with rank, IGN, username, guild, CP value, and last updated.
- Added top-rank, Elite 5, and Top 10 rank decoration for admin rows.
- Added EN/FR/DE labels and compact mobile styling.
- Preserved existing CP roster, manual CP update, and CP Update Window controls.
- Preserved member-facing CP Ranking page behavior.
- `npm.cmd run build` passed.
- Static checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.
- Authenticated staging validation remains pending until staging receives `20260524000300_cp_rankings.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 20C Member CP Leaderboard Frontend Implemented

- Added frontend-only member CP Ranking page.
- Created `src/services/cpLeaderboardService.js` using only `get_member_cp_rankings`.
- Created `src/pages/Leaderboard.jsx`.
- Added member navigation/routing for CP Ranking.
- Added My Guild and Global tabs.
- My Guild shows rank and IGN.
- Global shows rank, IGN, and guild label.
- Added current-user row highlighting.
- Added top-rank, Elite 5, and Top 10 rank decoration.
- Added EN/FR/DE i18n labels and compact mobile styling.
- Confirmed the member leaderboard path does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, `get_current_cp_roster`, or direct CP tables.
- `npm.cmd run build` passed.
- Local unauthenticated browser smoke passed.
- Authenticated staging browser validation remains pending until staging receives `20260524000300_cp_rankings.sql`.
- No SQL migrations, Supabase/RLS/RPC logic, AdminPanel CP behavior, CP Update Window behavior, GvG, audit, role/permission/member-status behavior, staging, production, Vercel, deployment, or commit action changed.

## 2026-05-24 - Milestone 20B CP Leaderboard Backend Implemented

- Added local backend/database support for CP Leaderboards.
- Created migration `20260524000300_cp_rankings.sql`.
- Added member-safe RPC `get_member_cp_rankings(p_scope text default 'guild')`.
- Added admin/staff RPC `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
- Added ranking support indexes on `member_cp`.
- Member rankings support `guild` and `global` scopes while returning only rank, IGN, optional guild label/slug, and current-user highlight.
- Member rankings do not return CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, audit metadata, or private CP fields.
- Admin guild rankings return CP values only to callers with scoped `view_cp`.
- Admin global rankings are Owner-only in v1.
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.
- Ranks use deterministic `row_number()` ordering by CP descending and stable tie-breakers.
- Updated local validation SQL with Milestone 20B checks.
- Local Supabase reset passed.
- Local validation passed through Docker `psql`, including Milestone 20B result 14 PASS / 0 FAIL / 0 SKIP.
- No frontend UI, staging, production, Vercel, deployment, or commit action was performed.
- `20260524000300_cp_rankings.sql` was local-only at this checkpoint; it was later applied to staging in Milestone 20E and production in Milestone 20F.

## 2026-05-24 - Milestone 19E CP Update Window Production Rollout Complete

- Applied CP Update Window migrations to production after a clean dry-run:
  - `20260524000100_cp_update_window_self_submit.sql`
  - `20260524000200_cp_update_window_staff_read.sql`
- Verified production `cp_update_windows`, RLS, one-open-window unique index, safe RPCs/grants, direct grant absence, audit redaction support, and active Owner count.
- Deployed frontend commit `6a3a181 feat: add CP update window self-submit`.
- Production Owner smoke passed for AdminPanel CP and CP Update Window status.
- Production Member smoke passed for Profile `Your CP`, own-CP-only display, closed-window state, no Admin navigation, and no CP roster/leaderboard exposure.
- No controlled production CP mutation smoke was performed by design.
- No staging, Vercel env, service role, `db reset`, `--include-seed`, source edit, or SQL edit action was performed during rollout.
- Supabase CLI remains linked to production and must be relinked before future staging/local Supabase commands.

## 2026-05-24 - Milestone 19C CP Update Window Frontend Implemented

- Added frontend-only CP Update Window / Member CP Self-Submit UI.
- Created `src/services/cpWindowService.js` with RPC-only wrappers for own CP, own window status, member CP self-submit, selected-guild staff window status, and staff open/close actions.
- Added Profile `Your CP` card that reads only the signed-in member's own CP through `get_my_cp()` and window status through `get_active_cp_update_window_for_me()`.
- Added member CP self-submit through `submit_my_cp_update(...)` with required/numeric/non-negative local validation and backend authority preserved.
- Added AdminPanel CP Update Window controls using `get_cp_update_window_for_guild(...)`, `open_cp_update_window(...)`, and `close_cp_update_window(...)`.
- Added EN/FR/DE i18n copy for Profile CP, Admin CP window controls, and new audit/window labels.
- Added compact styling for the Profile CP card and Admin CP window block.
- `npm.cmd run build` passed.
- Static checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.
- Static checks confirmed Profile and `cpWindowService` do not call admin CP roster/leaderboard RPCs.
- No SQL migrations, Supabase/RLS/RPC logic, staging, production, Vercel, deployment, or commit action was performed.
- Authenticated browser validation remains pending until staging receives migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.

## 2026-05-24 - Milestone 19B.1 CP Update Window Staff Read RPC Implemented

- Added backend-only staff read support for CP Update Window status.
- Created migration `20260524000200_cp_update_window_staff_read.sql`.
- Added `get_cp_update_window_for_guild(p_guild_id uuid)`.
- The RPC returns open window first, otherwise latest closed window, otherwise no row.
- Authorized staff are Owner, scoped Leader/Vice, or scoped Admin with `view_cp` or `update_cp`.
- Member, wrong-guild user, and Admin without CP permission are denied.
- No direct `cp_update_windows` table grants or frontend access were added.
- Local Supabase reset passed.
- Local validation passed, including Milestone 19B.1 result 13 PASS / 0 FAIL / 0 SKIP and existing Milestone 19B result 32 PASS / 0 FAIL / 0 SKIP.
- No frontend UI, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 19B CP Update Window Backend Implemented

- Added local backend/database support for CP Update Window / Member CP Self-Submit.
- Created migration `20260524000100_cp_update_window_self_submit.sql`.
- Added guild-scoped `cp_update_windows` with one-open-window-per-guild enforcement.
- Added member-safe RPCs `get_active_cp_update_window_for_me()`, `get_my_cp()`, and `submit_my_cp_update(integer)`.
- Added staff RPCs `open_cp_update_window(...)` and `close_cp_update_window(uuid)` using existing CP update authority.
- Added audit actions `member_cp_self_submitted`, `cp_update_window_opened`, and `cp_update_window_closed`.
- Extended audit redaction so CP old/new values from member self-submit rows are hidden from viewers without scoped `view_cp`.
- Updated local validation SQL with Milestone 19B checks.
- Local Supabase reset passed.
- Local validation passed, including Milestone 19B result 32 PASS / 0 FAIL / 0 SKIP.
- No frontend UI, staging, production, Vercel, deployment, or commit action was performed.

## 2026-05-24 - Milestone 16H Member-Facing UI Production Rollout Complete

- Deployed `53c7907 style: clean up member-facing UI` to production.
- Member-facing compact UI/copy cleanup is live at `https://anteiku-guild-manager.vercel.app`.
- Production smoke passed for app load, EN/FR/DE language persistence, compact Login/Register, Forgot Password visibility, Owner AdminPanel access, controlled Member login, compact Member Dashboard/Profile/GvG, Member AdminPanel denial, CP non-leakage, missing-key checks, console-error checks, and narrow/mobile layout.
- No SQL, Supabase commands, Supabase/RLS/RPC changes, Vercel env changes, production data mutations, or CP/GvG/audit/role/permission/member-status behavior changes were made.

## 2026-05-24 - Milestone 16F Member-Facing UI Compact Pass Implemented

- Implemented a frontend-only member-facing UI/copy compact pass.
- Tightened Login/Register, Forgot Password, Set New Password, Pending, Rejected, Suspended, Roster Restricted, Dashboard/Home, Profile, and GvG surfaces.
- Dashboard/Home now prioritizes guild, role, roster status, GvG state, and compact member summary.
- Profile keeps IGN editing unchanged and shortens locked-field copy.
- GvG copy is shorter while preserving voting behavior.
- Changed member-facing copy is translated through EN/FR/DE i18n dictionaries.
- `npm.cmd run build` passed.
- Local browser smoke passed for Login/Register/Forgot Password in EN/FR/DE with no raw keys, no console errors, and no horizontal overflow.
- No SQL migrations, Supabase/RLS/RPC logic, services, auth behavior, CP, GvG voting, audit, role/guild/permission, member-status behavior, deployment, or commit action changed.
- Authenticated staging/member validation remains pending.

## 2026-05-24 - Milestone 18F Language Pack Production Rollout Complete

- Deployed the English/French/German frontend language pack to production.
- Commit deployed: `1f5b956 feat: add English French German language pack`.
- Language switcher works logged out and logged in.
- Selected language persists after reload.
- Login, registration, forgot-password, member-facing surfaces, and full AdminPanel content translate.
- AdminPanel tabs and content render in EN/FR/DE for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Production smoke found no raw translation keys, no captured console errors, and no narrow/mobile horizontal overflow.
- Existing production Member still has no Admin navigation.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.
- No SQL migrations, Supabase/RLS/RPC logic, Vercel env, production data, CP/GvG/audit/role/permission/member-status behavior changed.
- Future improvement: French/German admin wording review by native speakers.

## 2026-05-24 - Milestone 18B i18n Foundation Implemented

- Added a frontend-only EN/FR/DE language-pack foundation.
- Added `LanguageProvider`, `useLanguage()`, `t(key, params?)`, English fallback behavior, and `agm_language` localStorage persistence.
- Added compact topbar language selector visible before and after sign-in.
- Translated core shell, navigation, auth/register, forgot-password, Set New Password, pending/rejected/suspended/roster-restricted, Dashboard/Profile status, and member GvG voting surfaces included in 18B scope.
- Wired basic AdminPanel tab labels for translation.
- Left full AdminPanel content, CP tab content, Audit details, permission descriptions, raw audit metadata, usernames, IGN, guild names, and user-generated notes out of scope.
- `npm.cmd run build` passed.
- Built-app preview validation passed for EN/FR/DE switching, reload persistence, auth/register/recovery translation, missing-key checks, compact language selector, and empty captured console errors.
- No SQL migrations, Supabase/RLS/RPC logic, auth behavior, CP/GvG/audit/role/permission/member-status logic, deployment, or commit action changed.

## 2026-05-24 - Milestone 17D Registration Copy Update Implemented

- Updated registration copy for controlled guild onboarding.
- Registration now says `Register for guild approval.`
- Added email warning: `Use a real email. You'll need it for password reset.`
- Changed registration submit copy to `Request approval`.
- Changed no-session signup fallback to support both email-confirmation-on and email-confirmation-off modes.
- Changed pending screen title to `Awaiting approval.`
- Documented staging-first validation for disabling email confirmation.
- `npm.cmd run build` passed.
- Production email confirmation remains enabled until a separate production Auth setting gate is approved.
- No SQL migrations, Supabase/RLS/RPC logic, Supabase Auth settings, Vercel env, CP, GvG, audit, role/permission/member-status, approval, or membership behavior changed.

## 2026-05-24 - Milestone 17C Password Recovery Production Rollout Complete

- Deployed Password Recovery Required Reset Flow to production.
- Commit deployed: `23dd956 fix: require password reset after recovery link`.
- Production smoke passed.
- Controlled production test member recovery validation passed.
- Recovery links now show the required `Set new password` gate.
- Normal navigation is blocked before password update.
- Password update succeeds and new password login works.
- Role/access remains unchanged after reset.
- No passwords, recovery tokens, or secrets were stored in docs/source.
- No SQL migrations, Supabase/RLS/RPC logic, Supabase Auth settings, Vercel env, CP, GvG, audit, role/permission/member-status, approval, or membership behavior changed.

## 2026-05-24 - Milestone 17A Password Recovery Flow Implemented

- Implemented frontend/auth UX for required password reset after Supabase recovery links.
- Added password reset email request and recovered-password update wrappers.
- Added Supabase `PASSWORD_RECOVERY` handling, recovery URL fallback detection, and a sessionStorage recovery marker.
- Added a `Set new password` screen that blocks normal app navigation while recovery mode is active.
- Added a forgot-password mode to the sign-in screen with neutral reset-email copy.
- Preserved existing approval, membership, roster status, role/guild/permission, CP, GvG, and audit behavior.
- `npm.cmd run build` passed.
- Local browser smoke confirmed forgot-password UI, recovery-gated reset screen, blocked normal navigation, sign-out recovery cleanup, and no captured console warnings/errors.
- No SQL migrations, Supabase/RLS/RPC logic, Vercel env, deployment, or commit action was performed.
- Real staging recovery-email validation remains pending before production rollout.

## 2026-05-24 - Milestone 16D.1 AdminPanel Compact Roster Implemented

- Implemented frontend-only AdminPanel compact member cards and technical text cleanup.
- Changed Members tab from tall always-open cards to compact roster rows.
- Added per-member `Manage` disclosure areas for IGN editing, username reset, roster status, role, and guild-transfer controls.
- Preserved hard-block status reason/confirmation flow and transfer warnings.
- Removed visible environment/status pill copy such as `Supabase configured`.
- Shortened auth, dashboard, GvG, pending, and rejected-state copy.
- Preserved the Permissions copy fix for `Reset username/username`.
- `npm.cmd run build` passed.
- Static checks found no service, SQL migration, Supabase test, protected table, or unsafe GvG write changes.
- Authenticated staging browser validation passed for Owner Members compact rows, expanded Manage controls, and CP/GvG/Audit/Permissions/Tools rendering.
- `.env.local` was restored to local Supabase and Vite was restarted after validation.
- No production, deployment, Vercel env, SQL, Supabase/RLS/RPC, service behavior, or commit action was performed.

## 2026-05-24 - Milestone 16C Authenticated AdminPanel Validation Passed

- Authenticated AdminPanel/UI validation passed against staging through the local frontend.
- Validated Owner AdminPanel tabs, Members status UI, CP, GvG, Audit Logs, Permissions, Tools, and mobile AdminPanel layout.
- Validated restricted admin, normal member, pending user, audit no-CP, audit+CP, and wrong-guild staging accounts.
- Confirmed CP redaction still shows `Sensitive CP metadata hidden.` for users without `view_cp`.
- Confirmed permitted CP audit metadata is visible for the `view_cp` audit account.
- Rephrased user-facing "Profile slug" UI copy to "Username".
- Adjusted limited-admin AdminPanel shell copy to avoid naming unavailable tools.
- `npm.cmd run build` passed after validation fixes.
- Source/security-path validation found no service, SQL migration, Supabase test, protected table, or unsafe GvG write changes.
- `.env.local` was restored to local Supabase settings after validation.
- Vite was restarted locally after the environment restore.
- Staging test credentials were not stored in docs/source.
- No production, Vercel env, deployment, SQL, Supabase/RLS/RPC, service, or commit action was performed.

## 2026-05-24 - Milestone 16B AdminPanel UI Cleanup Implemented

- Implemented a frontend-only AdminPanel UI/copy cleanup.
- Shortened AdminPanel shell copy and removed implementation-facing wording from AdminPanel UI text.
- Tightened Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools tab copy.
- Added compact AdminPanel styling for cards, empty states, metadata rows, controls, tabs, and narrow mobile layout.
- Preserved destructive confirmations, hard-block member-status confirmation/reason flow, CP redaction notice, transfer reset warning, and permission-denial meaning.
- Preserved existing service/RPC paths and behavior; no SQL migrations, Supabase/RLS/RPC logic, CP, GvG, audit, role/guild, permission, or member-status behavior changed.
- `npm.cmd run build` passed.
- Static source checks found no service changes, no Supabase migration/test changes, no new direct protected CP/audit/history table calls, and no unsafe GvG writes.
- Local app loaded at `http://localhost:5173/` with no captured console warnings/errors on the unauthenticated page.
- Authenticated AdminPanel browser validation remains pending before rollout.
- No deployment or commit was performed.

## 2026-05-24 - Milestone 15E Member Status Production Rollout Complete

- Applied `20260523000100_member_roster_status_system.sql` to production only after dry-run showed it was the only pending migration.
- Verified production DB schema/RLS/RPC state for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, indexes, and backfilled memberships.
- Confirmed production memberships were backfilled to `roster_status = active`.
- Confirmed active Owner count remains `1`.
- Pushed `main` and Vercel deployed the Member Status frontend.
- Production smoke validation passed for Owner AdminPanel Members status UI, CP tab, Audit Logs, GvG, Member Dashboard/Profile/GvG, Member AdminPanel denial, and CP non-leakage.
- No production roster-status mutation smoke was performed.
- Optional future production mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; future staging/local work must explicitly relink before Supabase commands.

## 2026-05-24 - Milestone 15D Member Status Staging Validation Passed

- Applied `20260523000100_member_roster_status_system.sql` to staging only after a dry-run showed it was the only pending migration.
- Verified staging schema/RLS for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, policies/grants, backfilled memberships, and active Owner count.
- Browser-validated the Milestone 15B frontend through staging users.
- Confirmed Owner Members tab roster badges, status filter, and status controls worked.
- Tested `staging_member` through `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, and restored `active`.
- Confirmed `suspended` blocks member/admin areas with a restricted notice.
- Confirmed `on_break` allows Home/Profile and shows not expected for GvG with no vote controls.
- Confirmed `staging_admin_noperms` has no Members/status/CP/Audit/GvG management controls.
- Verified final `staging_member` state: `membership_status = active`, `roster_status = active`.
- Verified 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows from validation.
- Source-path validation still shows status updates use only `update_member_roster_status`, with no direct frontend `guild_memberships` writes, no frontend `member_status_history` calls, no new direct `member_cp`/`cp_snapshots`/`audit_logs` calls, and CP privacy unchanged.
- Restored `.env.local` to local Supabase and restarted Vite locally.
- Production, Vercel env, deployment, and commit actions were not performed.
- Production rollout later completed in Milestone 15E.

## 2026-05-23 - Milestone 15B Member Status Frontend Implemented

- Implemented frontend Member Status UI/access gating locally.
- Added safe frontend `roster_status` reads for current viewer membership and Admin Members roster.
- Added roster status badges, filter, status change control, reason input, and hard-block confirmation to Admin Members.
- Added `updateMemberRosterStatus(...)` frontend wrapper using only `update_member_roster_status`.
- Added Dashboard/Profile roster status badges and safe notes without adding CP reads.
- Added roster hard-block restricted notice for `suspended`, `left`, and `kicked`.
- Updated GvG UX so `inactive` and `on_break` users do not get vote controls.
- Preserved private status history/reason privacy; no `member_status_history` UI was added.
- `npm.cmd run build` passed.
- Source/security checks found no direct frontend `guild_memberships` updates, no direct `member_status_history` calls, and no new direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- Browser validation later passed through staging in Milestone 15D.
- This frontend was later deployed to production in Milestone 15E after the production migration was applied and verified.
- No SQL migrations, backend/RLS/RPC changes, production, Vercel env, deployment, or commit action was included.

## 2026-05-23 - Milestone 15A Member Status Backend Complete

- Added backend Member Status support.
- Added migration `20260523000100_member_roster_status_system.sql`.
- Added `guild_memberships.roster_status` with statuses `active`, `trial`, `inactive`, `on_break`, `suspended`, `left`, `kicked`, and `pending_transfer`.
- Added private `member_status_history` table for staff-only reasons/history.
- Added `update_member_roster_status(...)` RPC.
- Added `member_roster_status_changed` audit logging without private reason text in audit metadata.
- Added GvG eligibility protection: `inactive` and `on_break` keep active membership but cannot see/vote on active GvG events; `trial` remains eligible.
- Mapped hard-block statuses:
  - `suspended` -> `membership_status = 'suspended'`
  - `left` -> `membership_status = 'left'`
  - `kicked` -> `membership_status = 'left'`
- Local validation passed:
  - `npx.cmd supabase db reset`
  - `supabase/tests/local_validation_anteiku.sql`
  - Milestone 15A: 22 PASS / 0 FAIL / 0 SKIP
- No React/frontend UI, production Supabase, Vercel env, deployment, or commit action was included.

## 2026-05-23 - Milestone 14H Staging CP Redaction And GvG Smoke Complete

- Completed staging CP audit redaction browser validation.
- Completed staging CP metadata visibility validation for a scoped `view_cp` user.
- Completed staging GvG full smoke validation.
- Completed staging permission denial, wrong-guild denial, and pending lockout checks.
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` saw `Sensitive CP metadata hidden.` and did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke`.
- `staging_member` voted Present, switched Absent with reason, then switched back Present.
- Owner closed the GvG event.
- Read-only SQL confirmed exactly one `gvg_votes` row with final status `present` and `absence_reason = null`.
- `staging_wrongguild` could not see or vote on the Anteiku event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.
- Active Owner count remained `1`.
- Deferred production GvG smoke and CP audit redaction browser scenarios are now covered in staging.
- Recorded network caveat: literal DevTools request capture was unavailable through browser automation, but source-path inspection confirmed approved RPC usage. This is not a 14H blocker.
- Test data remains in staging intentionally.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-23 - Future CP Update Window / Member CP Self-Submit Roadmap Note

- Recorded future CP-focused milestone candidate: CP Update Window / Member CP Self-Submit.
- Corrected future CP privacy rule: members may see their own CP through safe backend/RPC flow, but must not see other members' CP.
- Recorded that members must not see CP roster, CP leaderboard, CP snapshots, or other members' CP history.
- Recorded future backend-first direction: `cp_update_windows` plus safe RPCs such as `create_cp_update_window`, `set_cp_update_window_status`, `get_active_cp_update_window_for_me`, `get_my_cp`, and `submit_my_cp_update`.
- Recorded security requirements for self-only CP submission, database/server-time window checks, guild/scope checks, audit logging, and audit metadata redaction.
- Recorded future frontend surfaces for AdminPanel CP window controls and Member Profile "Your CP".
- No source code, SQL migrations, Supabase/RLS/RPC behavior, production data, deployment, or commit action was included.

## 2026-05-23 - Milestone 14F Staging Owner Bootstrap Complete

- Completed and verified staging Owner bootstrap for `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Recorded staging Owner Auth UUID `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Recorded staging Owner email `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Recorded username/profile slug `staging_owner` and IGN `Staging Owner`.
- Verified Owner membership in `Anteiku` with role `owner`, status `active`, and primary membership `true`.
- Verified `active_owner_count = 1`.
- Verified `owner_bootstrapped` audit log count is `1`.
- Recorded that no controlled staging test users existed at the 14F checkpoint.
- Recorded that Vercel Preview remains unconfigured.
- Recorded next milestone recommendation: Milestone 14G staging controlled test users plus permission matrix setup planning/execution.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-23 - Milestone 14E Staging Supabase Verification Complete

- Completed staging Supabase migration/apply/verification.
- Recorded staging project `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Applied and verified the same 9 migrations as production.
- Verified staging schema/RLS/seed state.
- Confirmed permission catalog count is 10 and exactly matches `20260514000400_seed_core_data.sql`.
- Confirmed the earlier "7 permissions" report was a partial summary mistake.
- Recorded that `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.
- Recorded that no staging Owner or test users existed at the 14E checkpoint.
- Recorded next milestone recommendation: Milestone 14F staging Owner bootstrap planning.
- No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-22 - Milestone 14D Staging And Preview Planning Docs

- Added documentation-only staging Supabase + Vercel Preview planning.
- Documented future staging architecture: fresh Supabase project, same 9 migrations as production, separate URL, separate anon/publishable key, separate Auth users, separate Owner bootstrap, and staging-only fake/test data.
- Documented that production data must not be copied into staging unless explicitly approved.
- Documented Vercel Preview env policy: Production env remains production-only; Preview env should point only to staging Supabase when staging exists.
- Documented allowed Preview env vars: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Documented forbidden frontend/Vercel env values: service role keys, database passwords/URLs, `sb_secret_*` keys, JWT secrets, SMTP secrets, and OAuth/provider secrets.
- Documented Auth URL strategy: production Site URL remains `https://anteiku-guild-manager.vercel.app`, production redirects stay production-only, and Preview wildcard redirects belong only in staging Supabase if needed.
- Documented future staging test users and moved deferred GvG smoke, CP audit redaction, permission denial, wrong-guild access, and cleanup/archive experiments to staging.
- Documented future phases: 14E staging Supabase create/link/migrate/verify, 14F Vercel Preview env + staging Auth URLs, and 14G staging validation.
- No staging project was created, no Supabase commands were run, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

## 2026-05-22 - Milestone 14C AdminPanel Tabs Production Rollout Complete

- Refactored AdminPanel into a frontend-only tabbed coordinator plus section components.
- Added AdminPanel tabs for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Added mobile-first sticky horizontal tab styling with dark/crimson Anteiku styling.
- Rendered only the active AdminPanel section.
- Lazy-loaded CP, Audit Logs, and GvG management data when their tabs are opened instead of on initial AdminPanel render.
- Preserved existing security paths: Audit Logs use `get_audit_logs`, CP uses approved CP RPCs, and GvG uses approved RPCs/safe reads.
- `npm.cmd run build` passed.
- Source validation found no direct frontend `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- Local browser/network validation passed: CP used approved CP RPCs only, Audit Logs used `get_audit_logs` only, GvG used safe GvG paths only, and no direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- The committed/pushed `main` build was deployed by Vercel.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Production smoke validation passed: Owner login, AdminPanel open, visible tabs, Owner switching through Approvals/Members/CP/GvG/Audit Logs/Permissions/Tools, Audit Logs load, CP load, mobile tab usability, and Member AdminPanel denial.
- No SQL migrations, Supabase schema/RLS/RPC logic, CP logic, GvG logic, audit logic, role/guild behavior, permission checkbox behavior, Vercel env, deployment, or commit actions were changed during the final documentation checkpoint.
- Milestone 14C is complete in production.

## 2026-05-20 - Milestone 14B Vercel GitHub App Restriction Checkpoint

- Recorded user-confirmed Vercel GitHub App restriction to only `Ultimate99/anteiku-guild-manager`.
- Recorded that the Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Verified production URL still loads at `https://anteiku-guild-manager.vercel.app`.
- Browser health check loaded title `Anteiku Guild Manager` and showed no captured console errors.
- Recorded that no Vercel env vars, source logic, SQL migrations, Supabase schema/RLS/RPC, deployment, or commit actions were changed during this checkpoint.

## 2026-05-20 - Milestone 14A Production Hardening Policy Docs

- Added documentation-only production hardening and cleanup policy guidance.
- Documented manual Vercel GitHub App restriction checklist for repository-only access to `Ultimate99/anteiku-guild-manager`.
- Recorded that no Vercel settings, GitHub App settings, production commands, source logic, SQL migrations, deployment, user cleanup, or commit actions were performed.
- Recorded controlled production test member policy for `krsticmiroslav99+m13b21144225@gmail.com`: keep documented for now, do not hard-delete, preserve validation/audit history, and require explicit approval for cleanup.
- Documented Preview/Staging policy: Production env only for Production deployments, Preview env unconfigured until staging exists, future staging Supabase must be separate, and broad production redirect wildcards should be avoided.
- Recorded deferred production smoke tests: GvG production smoke deferred to avoid persistent production test data, and CP redaction browser scenario deferred due missing staff/data setup.
- Added launch operations checklist for member approvals, audit monitoring, CP updates, GvG event safety, admin permission safety, and production SQL safety.

## 2026-05-19 - Milestone 13B Production Deployment Validation Passed

- Vercel setup completed for `Ultimate99/anteiku-guild-manager` on production branch `main`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel framework preset: Vite.
- Vercel build command: `npm run build`.
- Vercel output directory: `dist`.
- Production env uses only `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- No service role key, database password/URL, JWT secret, SMTP/OAuth/provider secret, or `sb_secret_*` key was added to frontend/Vercel env.
- Supabase Auth Site URL and Redirect URL allow-list were configured for `https://anteiku-guild-manager.vercel.app`.
- Production smoke/security validation passed for Owner login, AdminPanel, Audit Logs, CP Management, pending user lockout, Member approval, Member CP denial, mobile layout, and manual Network checks.
- Audit Logs Network validation observed `rpc/get_audit_logs`; no direct `/rest/v1/audit_logs`, CP calls, or audit write/update/delete/export calls were observed.
- CP Management Network validation observed approved CP RPCs only; no direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls after clearing Network.
- Controlled production test member remains in production as an approved Member: `krsticmiroslav99+m13b21144225@gmail.com` / `m13bmember21056302`.
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- CP redaction browser test was intentionally not tested because no current production staff/data combination exists for the scenario; Milestone 11A backend validation covered CP metadata redaction.
- Recommendation recorded to restrict Vercel GitHub App access to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.
- No source logic, React files, SQL migrations, Supabase schema/RLS/RPC, Vercel env changes after validation, redeploy, or commit were included in the final documentation checkpoint.

## 2026-05-19 - Milestone 13A Production Supabase Checkpoint

- Production Supabase project was created and linked: `mzflfyxxkascrfpteexz`.
- Production project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations were applied remotely.
- Production schema/RLS/seed verification passed.
- Verified protected tables, RLS, policies, RPCs, grants, indexes, constraints, and seed data.
- Manual Owner bootstrap completed using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.
- Owner profile `ultimatesrb` / `UltimateSRB` is approved in `Anteiku`.
- Exactly one active Owner membership exists.
- `owner_bootstrapped` audit log exists.
- At the time of the Milestone 13A checkpoint, Vercel was not configured yet.
- At the time of the Milestone 13A checkpoint, production deployment had not happened yet.
- Added documentation/handoff checkpoint for Milestone 13B.
- Supabase CLI was installed locally as dev tooling during Milestone 13A; the CLI tooling/package changes were committed before Milestone 13B planning/execution.
- No source logic, React files, SQL migrations, CP logic, GvG logic, audit logic, role/guild management logic, permission checkbox logic, Vercel config, deploy, or commit actions were included.

## 2026-05-15 - Milestone 12 Production Readiness Docs

- Added docs-only production readiness runbook/checklist.
- Created `docs/PRODUCTION_CHECKLIST.md`.
- Expanded `docs/DEPLOYMENT.md` with production Supabase, migration, Owner bootstrap, Vercel, preview, and post-deploy validation guidance.
- Refreshed setup and README docs to reflect the current Milestone 11B-complete app state.
- Documented browser-safe Vercel env variables: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Documented that service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- Documented production migration order and forbidden production commands.
- Documented that `supabase/tests/local_validation_anteiku.sql` must not run against production because it inserts fake auth users/test data.
- Documented the `supabase/config.toml` missing `seed.sql` hazard and that core seed data currently comes from migration `20260514000400_seed_core_data.sql`.
- Updated ai_agents handoff docs for Milestone 12 completion and Milestone 13 readiness.
- No source logic, React files, SQL migrations, deployment, dependencies, or commits were included.

## 2026-05-15 - Milestone 11B Audit Log Viewer Validation Passed

- Manual live browser validation passed for the AdminPanel Audit Logs section.
- Owner loaded logs, used filters, and used Load Older successfully.
- Leader/Vice and Admin with `view_audit_logs` saw scoped logs only.
- Admin without `view_audit_logs`, normal Member, and pending user could not access audit logs.
- CP-sensitive metadata was hidden for users without `view_cp`.
- CP metadata appeared only for an authorized `view_cp` user when the backend returned it.
- Network validation after clearing initial AdminPanel load showed `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- Empty/error states, metadata rendering, filters, and mobile layout passed.
- No bugs or incomplete tests were reported.
- Milestone 11B is complete.

## 2026-05-15 - Milestone 11B Audit Log Viewer Implemented

- Added frontend-only, read-only AdminPanel Audit Logs section.
- Added isolated `src/services/adminAuditService.js`.
- Audit reads use only `public.get_audit_logs(...)`.
- Added refresh, action filter, safe/simple guild filter, date from/to filters, limit selector, and load older pagination.
- Added loading, error, empty, and not-authorized states.
- Audit cards show action, timestamp, actor, optional target, guild/global scope, entity table/id, safe metadata summary, and CP redaction notice.
- Metadata rendering is whitelist-based and does not dump raw metadata JSON.
- Redacted CP-sensitive rows show `Sensitive CP metadata hidden.`
- No SQL migrations, `get_audit_logs` changes, CP logic, role/guild logic, permission checkbox logic, GvG logic, dependencies, deploy, or commit were included.
- `npm.cmd run build` passed.
- Source validation confirmed no direct frontend `audit_logs` table calls, no CP RPC/table calls in the audit viewer path, and no audit write/update/delete/export UI.
- Manual browser validation later passed; Milestone 11B is complete.

## 2026-05-15 - Milestone 11A Audit Log Read Hardening Validated

- Added backend-only audit log read hardening.
- Added `public.get_audit_logs(...)` as the safe audit reader RPC.
- Restricted direct non-Owner `audit_logs` SELECT.
- Added SQL-side CP metadata redaction for audit viewers without scoped `view_cp`.
- Kept audit writes, CP update logic, role/guild logic, permission checkbox logic, GvG logic, and frontend UI unchanged.
- Updated local validation with audit visibility, redaction, direct table read, private audit writer grant, and audit spoof checks.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 11A validation passed with 14 PASS / 0 FAIL / 0 SKIP.
- Milestone 11B frontend audit log viewer was implemented later as a separate frontend-only pass.

## 2026-05-15 - Milestone 10 GvG Validation Passed

- Corrected live browser validation passed for GvG event management and member voting persistence.
- Build passed with `npm.cmd run build`.
- Owner event creation, voting open, and voting close were validated.
- Same-guild Member voting was validated for Present, Absent with reason, and switching back to Present.
- Read-only SQL confirmed one vote row per event/profile, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff can see present/absent counts and absence reasons.
- Normal Members cannot see other users' absence reasons.
- Admin without `manage_gvg`, wrong-guild Member, and out-of-scope staff denial paths passed.
- Closed events reject vote changes.
- Network validation confirmed GvG actions use only GvG RPCs/safe reads after clearing Network.
- No CP RPC/table calls were triggered by GvG actions.
- No direct frontend writes to `gvg_votes` or `gvg_events` were observed.
- No bugs, security issues, or incomplete validation items were reported.

## 2026-05-15 - Milestone 10 GvG UI Implemented

- Added isolated GvG service.
- Added persistent member GvG voting UI.
- Added AdminPanel GvG event management/results section.
- Member voting uses `submit_gvg_vote`.
- Event management uses `create_gvg_event` and `set_gvg_event_status`.
- Staff results use `get_gvg_results`.
- No direct GvG vote writes were added.
- No CP, role/guild, permission checkbox, SQL, or package changes were made.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 9 Permission Management Validation Passed

- Manual browser validation passed for Admin permission checkbox management.
- Owner permission management validated, including CP permissions.
- Leader scoped non-CP permission management validated.
- CP permissions remain Owner-only.
- Admin users do not get Permission Management UI.
- Member users do not get Admin tab.
- Network writes used only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes were found.
- No CP data/RPC calls occurred during permission-management actions.
- No GvG logic was touched.

## 2026-05-15 - Milestone 9 Permission Management Implemented

- Added Admin permission checkbox management UI.
- Added isolated permission management service.
- Permission checkboxes apply only to active Admin memberships.
- Owner can manage all Admin permissions.
- Leader/Vice can manage non-CP Admin permissions inside assigned guild scope.
- CP permission checkboxes are disabled for Leader/Vice.
- Writes use only `grant_admin_permission` and `revoke_admin_permission`.
- No direct `admin_permissions` writes were added.
- No CP data/RPC calls were added by permission management.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Frontend CP Validation Passed

- Manual browser validation passed for Admin-only CP management and leaderboard.
- Owner can view CP roster, update CP, and view leaderboard.
- Missing CP displays as "Not entered".
- Invalid CP inputs are blocked.
- Normal Member cannot see Admin tab or CP UI.
- CP does not appear on Dashboard/Profile/member-facing pages.
- Network validation confirmed CP uses only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found.
- No GvG logic was touched.
- Recorded local stale-session note after DB reset.

## 2026-05-15 - Milestone 8 Frontend CP UI Implemented

- Added isolated admin CP service.
- Added AdminPanel CP Management section.
- Added CP roster through `get_current_cp_roster`.
- Added CP leaderboard through `get_cp_leaderboard`.
- Added CP update controls through `update_member_cp`.
- Missing CP displays as `Not entered`.
- CP remains isolated from Dashboard, Profile, member-facing pages, and normal member roster cards.
- No direct `member_cp` / `cp_snapshots` reads or writes were added.
- No GvG logic was changed.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 8 Backend CP Hardening Validation Passed

- Local validation passed for backend CP hardening.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- CP update for pending/rejected/suspended profiles is blocked.
- CP update for approved active profile works.
- Admin with `update_cp` cannot update CP for non-approved profiles.
- CP roster includes approved active members with missing CP as `null`.
- Members and Admins without `view_cp` cannot read CP.
- Direct `member_cp` / `cp_snapshots` access remains blocked.
- CP update audit logging works.
- No GvG logic changed.

## 2026-05-15 - Milestone 8 Backend CP Hardening Implemented

- Added CP hardening migration.
- `update_member_cp` now requires approved target profiles.
- `get_current_cp_roster` now includes active approved members without CP rows.
- Missing CP is returned as `null`.
- Added local validation checks for non-approved CP update denial, missing CP roster rows, CP read denial, direct CP table access denial, and CP audit logs.
- No frontend, package, GvG, or direct CP policy changes were made.
- Local validation is pending.

## 2026-05-15 - Milestone 7 Frontend Validation Passed

- Manual browser validation passed for Admin member role and guild management.
- Owner role changes, Owner-only guild transfer, and transfer role reset behavior were validated.
- Leader scoped permissions were validated.
- Normal Member still cannot access Admin tab.
- Network writes used only `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were observed.

## 2026-05-15 - Milestone 7 Frontend Role/Guild UI Implemented

- Added Admin member role-change UI using `assign_member_role`.
- Added Owner-only member guild-transfer UI using `transfer_member_guild`.
- Added safe active guild option reads for transfer targets.
- Kept Owner assignment out of frontend UI.
- Kept transfer UI Owner-only in v1.
- Confirmed no direct table writes were added.
- Confirmed no CP/GvG access was added.
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## 2026-05-15 - Milestone 7 Backend Validation Passed

- Local Supabase validation passed after backend role/guild SQL changes.
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Role assignment tests passed.
- Guild transfer tests passed.
- Owner-only guild transfer behavior validated.
- Owner assignment remains blocked through normal app RPC.
- Transfer audit logs and role-change audit logs are written.
- No CP/GvG logic was changed.

## 2026-05-15 - Milestone 7 Backend Role/Guild SQL Prepared

- Added backend migration for normal app role assignment hardening.
- Added Owner-only member guild transfer RPC.
- Updated local validation SQL with role assignment and guild transfer checks.
- Documented that Owner assignment remains manual-only and is not exposed through normal app RPC.
- No frontend, package, CP, or GvG changes were made.
- Local Supabase validation is pending.

## 0.1.0

- Added Milestone 1 scaffold for React + Vite.
- Added documentation-first security notes.
- Added placeholder Supabase client configuration.
- Completed local Milestone 1 validation with `npm.cmd install` and `npm.cmd run build`.
- Recorded development-only Vite/esbuild audit issue without upgrading Vite.
- Documented approved Milestone 2 schema/RLS decisions for future migrations.
- Recorded CP privacy, role permission, GvG, Owner bootstrap, reapply, audit visibility, and constraint decisions.
- Added Supabase SQL migrations and local validation script.
- Fixed private helper parameter shadowing that caused CP/RPC permission leakage during validation.
- Completed Milestone 2 local Supabase validation: 29 PASS / 0 FAIL / 0 SKIP.
- Added Milestone 3 local Supabase frontend auth integration.
- Fixed AuthContext loading state issue caused by async auth-state handling.
- Completed Milestone 3 manual browser validation for register, pending gating, signin/signout, session restore, and no frontend CP calls.
- Added Milestone 4 frontend registration approval/rejection UI and service.
- Approval workflow uses current RLS-safe reads plus `approve_registration` and `reject_registration` RPC writes only.
- Kept Owner assignment out of the frontend approval UI and left Owner bootstrap manual-only.
- Completed Milestone 4 build validation with `npm.cmd run build`; full Owner browser testing awaits local Owner bootstrap.
- Fixed approved app shell missing Sign out control by adding Sign out to the `AppShell` header.
- Completed Milestone 4 manual browser validation after local Owner bootstrap: Owner approval/rejection flow passed, normal member Admin tab stayed hidden, rejected user stayed gated, and no CP UI/data was exposed.
- Added Milestone 5 own-profile IGN editing using the existing `update_my_profile` RPC.
- Kept username, profile slug, guild, role, approval status, and avatar/profile icon locked/display-only in the Profile UI.
- Completed Milestone 5 manual browser validation: Owner and Member can edit own IGN, locked fields stayed read-only/display-only, update used `update_my_profile` only, and no protected CP calls were observed.
- Added Milestone 6 admin member management for active approved members only.
- Added safe roster search/filter UI, admin member IGN edit via `admin_update_member_ign`, and username/profile slug reset via `admin_reset_profile_slug`.
- Completed Milestone 6 manual browser validation: Owner roster access, member IGN edit, username/profile slug reset, normal member Admin denial, and no CP calls passed.
- Recorded Milestone 7 requirement: admin/staff member guild + role management must be planned safely and not patched in quickly.
## 2026-05-24 - Milestone 18D AdminPanel Full Translation Implemented

- Added full AdminPanel display translations for English, French, and German.
- Translated AdminPanel shell, Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, admin empty/loading states, errors, success messages, permission display labels/descriptions, audit action labels, and audit metadata labels.
- Preserved raw logic/data values: usernames, IGN, guild names, permission keys, audit metadata values, CP numbers, GvG event titles, absence reasons, user notes, roster status values, and RPC payload values were not translated.
- `npm.cmd run build` passed.
- No SQL migrations, Supabase/RLS/RPC behavior, service behavior, dependencies, deployment, or commit action changed.
- Authenticated staging browser validation is pending.
