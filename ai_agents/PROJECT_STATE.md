# Project State

## Weekly Growth Baseline Scope Fix Complete

Weekly Growth baseline scope fix is live in production.

Production status:
- Commit `0130ac6 fix: preserve analytics baseline across guild scope` is deployed.
- New migration `20260526000300_live_cp_growth_baseline_scope.sql` is applied in production.
- Root cause was Weekly Growth scope switching auto-selecting the latest baseline per selected scope. Global used the earlier global baseline, while Anteiku used a later guild-only baseline.
- Fix preserves the selected baseline across Analytics scope changes when the baseline is applicable.
- Added safe RPC overload `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)`.
- Owner can use a Global baseline while filtering rows to a guild scope.
- Production smoke confirmed Global and Anteiku both show `安定区×Ulti` growth `+5,002` from the same Global baseline.
- Start New CP Week was not clicked. No new production snapshot/baseline was created.

Security/scope:
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- Members and non-authorized users cannot access CP/growth data.
- Frontend Analytics still uses RPCs only and does not direct-read `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- No CP values, CP Update Window behavior, CP ranking privacy, GvG, audit, role, permission, cosmetics, or member-status behavior changed.

## Live CP Growth Production Rollout Complete

Live CP Growth for AdminPanel -> Analytics -> Weekly Growth is implemented and live in production.

Production rollout:
- New migration `20260526000200_live_cp_growth.sql` was applied to production project `mzflfyxxkascrfpteexz` after a clean dry-run showing exactly that one pending migration.
- Commit `426a720 feat: add live cp growth analytics` was pushed to `main`; production serves the Live CP Growth UI bundle.
- Supabase CLI remains linked to production; relink deliberately before future staging/local commands.

Backend/RPC:
- Added `start_new_cp_growth_period(p_guild_id uuid default null, p_label text default null)`.
- Added `get_admin_live_cp_growth(p_guild_id uuid default null)`.
- `capture_weekly_cp_snapshot(p_guild_id uuid default null)` now delegates to the new start-period RPC for compatibility.
- Live Growth compares current `member_cp.cp_value` against the latest authorized baseline batch for the selected scope.
- Reset day is Sunday. Starting a new week captures a baseline only; it does not reset player CP.
- No settings table was added in v1.

Validation:
- Local migration apply and full local validation passed through Docker `psql`; Milestone 24B/Live Growth result is 31 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Production DB verification confirmed the migration is applied, new RPCs exist with authenticated execute and anon denied, snapshot tables keep RLS, no direct anon/authenticated snapshot table grants exist, and active Owner count remains `1`.
- Owner production read-only smoke passed: Weekly Growth shows Reset day Sunday, current baseline date, selected scope, and a live table with Baseline CP, Current CP, Growth, and Growth %. Global and Anteiku scoped views loaded.
- No captured browser console errors were observed.
- Production Start New CP Week mutation smoke was NOT performed by design; do not click it without explicit approval.

Security/scope:
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- Members and admins without `view_cp` must not receive CP/growth data.
- Frontend Analytics uses RPCs only and does not direct-read `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, or `cp_snapshot_entries`.
- No CP Update Window, CP ranking privacy, GvG, audit, role, permission, cosmetics, or member-status behavior was changed.

## Milestone 24E Admin Analytics Production Rollout Complete

Milestone 24E is complete. AdminPanel Analytics and Weekly Growth are live in production after the production database received and verified `20260526000100_admin_analytics_foundation.sql`.

Production rollout:
- Production Supabase project `mzflfyxxkascrfpteexz` was deliberately linked before migration actions.
- Migration dry-run showed exactly one pending migration: `20260526000100_admin_analytics_foundation.sql`.
- `npx.cmd supabase db push` applied only that migration.
- Remote migration list now shows `20260526000100` applied.
- `git push origin main` pushed commit `cc2a32b feat: add admin analytics UI`; production now serves a bundle containing the Analytics UI and analytics RPC wrappers.

Production DB verification:
- `cp_snapshot_batches` and `cp_snapshot_entries` exist.
- RLS is enabled on both new snapshot tables.
- No direct anon/authenticated table grants exist for the new snapshot tables.
- Analytics RPCs exist and are executable by authenticated users with internal permission gates:
  - `get_admin_member_analytics`
  - `get_admin_cp_analytics`
  - `get_admin_gvg_analytics`
  - `capture_weekly_cp_snapshot`
  - `get_admin_cp_snapshot_history`
  - `get_admin_cp_growth_report`
- Active Owner count remains `1`.
- Simulated authenticated non-member read of `member_cp` and `cp_snapshots` returned zero visible rows.
- Direct authenticated read of `cp_snapshot_batches` was permission denied.

Production smoke:
- Production app loads at `https://anteiku-guild-manager.vercel.app`.
- Owner authenticated smoke passed for AdminPanel -> Analytics.
- Analytics sub-tabs rendered: Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Owner CP Analytics rendered CP stats.
- Weekly Growth rendered snapshot history controls and the safe `No previous snapshot yet` state.
- Snapshot capture mutation smoke was not performed by design; do not capture production snapshots without explicit approval.
- No captured browser console errors were observed during the Analytics production smoke.

Security/scope:
- CP Analytics and Weekly Growth remain backend-gated by scoped `view_cp`.
- Members have no AdminPanel/Analytics access.
- Analytics frontend uses the six analytics RPCs only.
- No direct frontend `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, Storage/upload, service-role, or arbitrary URL path was found in the Analytics UI/service paths.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

## Milestone 24C Admin Analytics UI Implemented Locally

Milestone 24C is implemented locally as a frontend-only AdminPanel Analytics UI on top of the Milestone 24B backend/RPC foundation.

Implemented:
- Added `src/services/adminAnalyticsService.js` with RPC-only wrappers for the six 24B analytics RPCs.
- Added `src/components/admin/AdminAnalyticsSection.jsx`.
- Added an `Analytics` AdminPanel tab with sub-tabs for Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Wired AdminPanel to lazy-render Analytics only when the Analytics tab is active.
- Added permission-aware locked states for CP Analytics and Weekly Growth.
- Added manual Weekly Growth snapshot UI through the existing `capture_weekly_cp_snapshot(...)` RPC.
- Added EN/FR/DE translation keys for Admin Analytics labels, locked states, snapshot controls, stat cards, and growth table labels.
- Added compact dark/crimson analytics cards, sub-tabs, locked panels, and mobile growth-table styles.

Validation:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation found no SQL migration changes.
- Source validation found no Supabase/RLS/RPC changes.
- `adminAnalyticsService` uses only RPC calls and no direct table reads.
- No direct frontend `member_cp`, `cp_snapshots`, `cp_snapshot_batches`, `cp_snapshot_entries`, unsafe `gvg_votes`, service-role, Storage, upload, or arbitrary URL paths were added.
- No Profile/Dashboard/member-facing CP behavior changed.

Browser validation status:
- Local authenticated browser validation is pending.
- The local Vite dev server was not running on `127.0.0.1:5173` during this checkpoint, so in-browser validation was not completed in 24C.

Scope/security:
- Frontend-only local implementation.
- No SQL migrations, Supabase commands, staging action, production action, Vercel env change, deployment, commit, CP/GvG/audit/role/permission/member-status behavior change, or production data mutation was performed.
- Do not deploy this frontend to any target until `20260526000100_admin_analytics_foundation.sql` is applied and verified on that target database.

Next gate:
- Milestone 24D: apply the 24B migration to staging, run authenticated Analytics browser/network validation, and verify CP/Weekly Growth permission behavior before any production rollout.

## Milestone 24B Admin Analytics Backend Implemented Locally

Milestone 24B is implemented and locally validated as a backend/RPC foundation for a future AdminPanel Analytics tab.

Implemented:
- Added new migration `20260526000100_admin_analytics_foundation.sql`.
- Added RPC-only snapshot batch storage with `cp_snapshot_batches` and `cp_snapshot_entries`.
- Added `get_admin_member_analytics(p_guild_id uuid default null)` for non-CP member status/approval/guild breakdowns.
- Added `get_admin_cp_analytics(p_guild_id uuid default null)` for CP summary data gated by scoped `view_cp`.
- Added `get_admin_gvg_analytics(p_guild_id uuid default null)` for latest-event participation/absence analytics gated by GvG authority.
- Added `capture_weekly_cp_snapshot(p_guild_id uuid default null)`, `get_admin_cp_snapshot_history(...)`, and `get_admin_cp_growth_report(...)` for manual Weekly Growth v1.
- Existing legacy `cp_snapshots` and older CP snapshot/growth RPCs are preserved.

Validation:
- `npx.cmd supabase db reset` passed locally.
- Full local validation passed through Docker `psql`.
- Milestone 24B focused validation result: 23 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend/runtime source files changed.

Security/scope:
- Backend/database/RPC only.
- No AdminPanel frontend UI, React source edit, staging action, production action, Vercel env change, deploy, or commit was performed.
- CP analytics and Weekly Growth require backend-enforced scoped `view_cp`.
- Members, pending users, wrong-guild staff, and admins without `view_cp` are denied CP analytics/growth.
- Snapshot tables have RLS enabled and no direct anon/authenticated table grants.
- No direct frontend `member_cp`/`cp_snapshots`/snapshot table access is introduced.

## Profile Mobile + Inline Edit Polish Complete In Production

Profile mobile + inline edit polish is implemented, deployed, and authenticated-smoke validated in production as a frontend-only UI/layout/copy pass on top of the compact Member Profile card.

Implemented:
- Kept the approved identity header with avatar/frame, IGN, username, status badges, rank badge, and Customize action.
- Replaced the separate `Your CP`, Member profile, and Profile details panels with one compact Member Profile card.
- The unified card includes a compact own-CP block, account/details block, and inline IGN edit flow.
- Edit now converts the existing IGN detail row into a small inline text field with compact Save IGN / Cancel controls.
- Removed the separate edit form so desktop CP/details columns stay balanced in edit mode.
- Tightened mobile spacing and account/details layout; compact read-only fields share rows on phone widths while username/IGN/roster remain readable.
- Cosmetic modal active tabs now use a flatter crimson active style; Admin tabs also keep a flatter active crimson style.
- Added EN/FR/DE keys for `Save IGN`, `Cancel`, short private-own-CP copy, and update-window label.

Validation:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed Profile still uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` through `cpWindowService`.
- Source checks found no Profile calls to `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, `update_member_cp`, direct `member_cp`, or direct `cp_snapshots`.
- Local browser validation confirmed Profile loads, unified Member Profile card renders, Edit toggles the IGN detail row into an input, Save IGN works against local Supabase, Customize opens, and no console errors were captured.
- Desktop validation confirmed the CP and Profile Details columns stay equal height in edit mode.
- Mobile 390px validation passed with no horizontal overflow and verified bottom-nav clearance at page bottom.
- Commit `160c6e9 style: move profile edit action inline` was pushed to `main` and deployed by Vercel.
- Authenticated production smoke passed: signed-in Profile opens, IGN row Edit works inline, Save IGN works, Cancel works, Customize opens, `Your CP` shows only own CP, and no visible UI blocker was found.

Scope/security:
- Frontend UI/copy/layout only.
- No SQL migrations, Supabase/RLS/RPC changes, service behavior changes, auth behavior changes, public profile routing, other-player profile viewing, production data mutation, Vercel env change, uploads, Supabase Storage, or CP/GvG/audit/role/permission/member-status behavior changes.

## Own Profile Polish Implemented Locally

Own Profile polish is implemented as a frontend-only layout/copy pass.

Implemented:
- Reordered Profile into a clearer self identity flow: identity card, private own-CP card, member profile edit card, and compact account/details card.
- Kept avatar/frame, rank badge, approval/status badges, and Customize action in the identity card.
- Moved the `Your CP` card higher on the page and labeled it as private self CP.
- Added short copy clarifying that only the signed-in user's own CP is shown on their profile.
- Added compact account/details rows for username, IGN, guild, role, roster status, and profile status.
- Added EN/FR/DE labels for private self CP, update window, profile/account status, and account details.

Validation:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed Profile still uses only `get_my_cp`, `get_active_cp_update_window_for_me`, and `submit_my_cp_update` through `cpWindowService`.
- Source checks found no Profile calls to `get_current_cp_roster`, `get_cp_leaderboard`, `get_admin_cp_rankings`, `update_member_cp`, direct `member_cp`, or direct `cp_snapshots`.
- Local browser validation confirmed Profile loads, the private `Your CP` card renders, Customize opens/closes, and no console errors were captured.

Scope/security:
- Frontend UI/copy/layout only.
- No SQL migrations, Supabase/RLS/RPC changes, service behavior changes, auth behavior changes, public profile routing, other-player profile viewing, deployment, production data, or CP/GvG/audit/role/permission/member-status behavior changes.
- Dashboard still does not show CP values.

## Frontend Command Center Polish Complete

Frontend-only Command Center polish is live in production.

Implemented:
- Member Dashboard now presents a compact guild command identity panel, safe status badges, quick action cards for Profile/GvG, and a guild status card.
- AdminPanel now opens on an Overview command center tab with permission-aware shortcut cards to existing sections.
- Admin Overview shortcuts switch to existing tabs only; they do not fetch sensitive tab data themselves.
- Mobile/header/nav styling was tightened with a sticky header, clearer bottom-nav active state, crimson glow/accent, and Admin active styling.
- Existing empty/loading/error panels received stronger compact dark/crimson state styling.
- EN/FR/DE text keys were added for the new Dashboard and Admin Overview copy.

Validation:
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Manual browser validation passed for Member Dashboard, Profile/GvG quick actions, Member AdminPanel denial, AdminPanel Overview, Overview shortcut switching, CP/Audit/GvG lazy loading, Owner Tools shortcut visibility, non-owner Admin hidden Owner Tools shortcut, existing AdminPanel tabs, mobile nav/header, EN/FR/DE copy, console checks, and network checks.
- Commit `7f7227a feat: polish command center frontend` was pushed to `main`.
- Vercel deployed the production bundle.
- Production smoke passed for Member Dashboard with no CP values, Profile/GvG quick actions, Member AdminPanel denial, Owner/Admin Overview, Overview shortcut switching, CP/Audit/GvG lazy loading, Owner/non-owner Admin shortcut visibility, existing AdminPanel tabs, mobile nav/header, EN/FR/DE copy, console checks, network checks, and backend/RPC/SQL/security regression checks.

Security/scope:
- Frontend polish only.
- No SQL migrations, Supabase/RLS/RPC logic, package/dependency, service behavior, Vercel/deployment, production data, CP/GvG/audit/ranking/role/permission/member-status, or cosmetics backend behavior changes.
- No new Supabase/RPC/table calls were added.
- Member Dashboard still shows no CP values.

## Owner Cosmetics Grant Tool Complete

AdminPanel -> Tools now includes an Owner-only Owner Cosmetics grant tool.

Implemented:
- Added compact Owner Cosmetics UI inside `AdminToolsSection`.
- Tool is visible only when the current membership role is `owner`.
- Non-owner Admins still see only safe Tools content; Members have no AdminPanel access.
- The form uses username/profile slug wording and warns not to use IGN.
- Cosmetic dropdown loads active catalog options through the existing `get_my_cosmetics()` RPC path.
- Cosmetic dropdown filters by backend `unlock_type` and shows only `manual` / `admin_grant` cosmetics.
- Free/default and auto-unlocked types (`free`, `rank`, `event`, `gvg`, `founder`) are excluded from the Owner grant dropdown.
- Grant action uses only `admin_grant_cosmetic_by_slug(p_profile_slug, p_cosmetic_key, p_reason)`.
- No direct insert/update to `profile_cosmetic_unlocks`, `profile_equipped_cosmetics`, or `cosmetic_catalog` was added.

Validation:
- `npm.cmd run build` passed.
- Dropdown hotfix build also passed after filtering free cosmetics from the Owner grant dropdown.
- Local browser validation passed for Owner visibility, dropdown rendering, empty slug validation, empty cosmetic validation, non-owner Admin hidden state, and Member AdminPanel denial.
- Commit `d97fc9f feat: add owner cosmetics grant tool` was pushed to `main`.
- Commit `24287cb fix: hide free cosmetics from owner grant dropdown` was pushed to `main`.
- Vercel production bundle deployed and production app load smoke passed with no captured console errors.
- Authenticated production smoke passed: Owner sees AdminPanel -> Tools -> Owner Cosmetics; dropdown shows only `manual` / `admin_grant` cosmetics; free/default cosmetics are absent; empty username/profile slug and empty cosmetic validation work; non-owner Admin does not see Owner Cosmetics; Member has no AdminPanel access.
- Controlled production grant smoke passed after explicit approval: a locked avatar/frame grant by exact profile slug / username succeeded, and the granted member could equip the cosmetic afterward.
- No console errors, unexpected network calls, or CP/GvG/audit/ranking/role/member-status regressions were found during authenticated production smoke.

Security:
- Frontend/UI-only change using existing RPCs.
- Owner Cosmetics grants use only `admin_grant_cosmetic_by_slug(...)`; the frontend does not directly insert/update `profile_cosmetic_unlocks`, `profile_equipped_cosmetics`, or `cosmetic_catalog`.
- No SQL migrations, Supabase/RLS/RPC changes, Vercel env changes, uploads, Supabase Storage, arbitrary URLs, or CP/GvG/audit/ranking/role/member-status behavior changes were included.

## Cosmetics Frame Unlock Hotfix Production Rollout

Production frame unlock hotfix is applied to production project `mzflfyxxkascrfpteexz`.

Implemented:
- Updated `scripts/sync-cosmetics-catalog.mjs` so future catalog sync migrations classify frames by family:
  - `TXK_Arena*` frames use `unlock_type = 'manual'`;
  - `TXK_KOF*` frames use `unlock_type = 'manual'`;
  - all other frames use `unlock_type = 'free'`;
  - `_FREE` keys remain free.
- Preserved premium avatar handling in the sync script by keeping `premium` avatar keys manual.
- Added migration `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- The migration updates only `public.cosmetic_catalog.unlock_type` for `type = 'frame'`; it does not delete catalog rows or mutate profile equipment.

Production rollout:
- Production dry-run showed only `20260525220522_cosmetics_frame_unlock_hotfix.sql` pending.
- Applied only `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Remote migration list confirmed `20260525220522` applied.
- Read-only production verification found 20 frame rows total: 7 Arena manual, 3 KOF manual, 10 other frames free, and 0 non-Arena/KOF frames left locked.
- Active Owner count remains `1`.
- Production app load smoke passed with no captured console errors.
- Authenticated Profile cosmetics browser smoke is pending until a production session is available in the browser.

Scope/security:
- Catalog `unlock_type` remains the runtime source of truth.
- No profile equipment rows, CP/GvG/audit/role/permission/member-status behavior, Vercel env, uploads, Supabase Storage, arbitrary URLs, or service-role paths were changed.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before staging/local Supabase work.

## Milestone 22F Cosmetics Catalog Sync Script Implemented

Milestone 22F is implemented as local developer tooling only.

Implemented:
- Added `scripts/sync-cosmetics-catalog.mjs`.
- Added npm command `cosmetics:sync`.
- The script scans `public/cosmetics/avatars/` and `public/cosmetics/frames/` for `.png` and `.webp` files.
- Hidden files, directories, and unsupported extensions are ignored.
- Cosmetic keys are generated from filenames without extensions.
- Asset paths are generated as `/cosmetics/avatars/<filename>` or `/cosmetics/frames/<filename>`.
- Label keys are generated as `cosmetics.avatar.<key>` or `cosmetics.frame.<key>`.
- Unlock defaults follow the current catalog sync rules:
  - keys ending `_FREE` use `unlock_type = 'free'`;
  - premium avatar keys use `unlock_type = 'manual'`;
  - other avatar files without `_FREE` use `unlock_type = 'free'`;
  - frame keys starting `TXK_Arena` or `TXK_KOF` use `unlock_type = 'manual'`;
  - all other frame files use `unlock_type = 'free'`.
- Rarity defaults to `common` for free cosmetics and `rare` for manual cosmetics.
- Sort order is deterministic in increments of `10`, with avatars first by filename and frames after by filename.
- Generated migrations upsert `public.cosmetic_catalog` rows and do not delete/deactivate missing rows.

Validation:
- `npm.cmd run cosmetics:sync -- --dry-run` passed and printed SQL preview.
- `npm.cmd run cosmetics:sync` generated `supabase/migrations/20260525193210_cosmetics_catalog_sync.sql`.
- Generated migration contains 54 avatar rows and 10 frame rows.
- `npm.cmd run build` passed.

Scope:
- No runtime app behavior changed.
- No Supabase commands were run.
- No staging or production project was touched.
- No deployment was performed.
- No uploads, Supabase Storage, arbitrary URLs, CP/GvG/audit/role/permission/member-status behavior, RLS/RPC behavior, or production data were changed.
- Generated migration has not been applied anywhere and must go through normal staging/production dry-run gates before rollout.
- Review generated migrations before applying because catalog `unlock_type` remains the runtime authority.

Next recommended step:
- Milestone 22F.1 or 23E planning: decide whether to keep/apply the generated sync migration as-is, adjust future frame naming/default policy, or add optional config/override support before staging rollout.

## Leaderboard Podium Polish Production Checkpoint

Leaderboard podium polish is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Commit deployed: `3f65052 style: tune leaderboard podium layout`.
- Build passed before deployment.
- Production app load smoke passed with no captured console errors.

UI result:
- Desktop podium order is visually `#2 | #1 | #3`.
- Mobile podium stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger centered gold styling and a larger avatar/frame.
- Rank #2 has silver styling.
- Rank #3 has bronze styling.

Scope/security:
- Frontend/style-only checkpoint.
- No ranking logic, backend, RPC, SQL, Supabase/RLS, Vercel env, or database behavior changed.
- Member leaderboard CP privacy is unchanged: member-facing ranking remains rank-only and does not expose CP values.
- Admin CP Ranking remains permission-protected and unchanged except for podium presentation styling.

## Milestone 23D Premium Cosmetics Production Rollout Complete

Milestone 23D is complete. Premium cosmetics backend/grant-helper hardening is live in production.

Production rollout:
- Production project `mzflfyxxkascrfpteexz` was explicitly linked before production migration work.
- Production migration list showed `20260525000300_premium_cosmetics_grant_helper.sql` as the only pending migration; `20260525000200_cp_rankings_cosmetics.sql` was already applied.
- Production dry-run showed only `20260525000300_premium_cosmetics_grant_helper.sql`.
- Applied only `20260525000300_premium_cosmetics_grant_helper.sql` to production.
- Remote migration list confirmed `20260525000300` applied.

Production verification:
- `admin_grant_cosmetic_by_slug(...)` exists.
- `get_my_cosmetics()` returns avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `equip_my_avatar(...)` contains free-or-unlocked enforcement markers.
- `update_my_profile(...)` contains locked/manual avatar rejection markers.
- All 10 current frame rows are `unlock_type = 'free'`.
- Active Owner count remains `1`.
- Normal Member grant attempt was denied.
- Owner/member-management authority path remains true for Owner and false for a production Admin without `manage_members`.
- Direct authenticated insert/write grants to cosmetics unlock/equipped tables remain absent.
- Production app load smoke passed at `https://anteiku-guild-manager.vercel.app` with no captured console errors.

Validation note:
- Production currently has `0` active manual cosmetics after this migration because all current frames are now free and current avatars remain free.
- Locked/manual equip denial and grant/equip success were authenticated-validated in staging during Milestone 23C.
- Production locked/manual mutation smoke was intentionally not performed because it would require creating or granting manual production cosmetics.

Scope:
- No frontend deploy, Vercel env change, source edit, SQL edit, new migration, `db reset`, `--include-seed`, service-role key, Supabase Storage, upload path, arbitrary URL path, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before staging/local Supabase commands.

Next recommended step:
- Milestone 23E planning for optional AdminPanel grant UI, premium locked-state picker copy, or production manual-cosmetic seed planning.

## Milestone 23B Premium Cosmetics Backend Implemented Locally

Milestone 23B is backend/database-only and locally validated. It prepares premium avatars/frames while keeping the existing production cosmetics rollout untouched. It later rolled out to staging in Milestone 23C and production in Milestone 23D.

Implemented locally:
- Added new migration `20260525000300_premium_cosmetics_grant_helper.sql`.
- Did not edit deployed migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Updated all 10 currently existing frame catalog rows to `unlock_type = 'free'`.
- Preserved the rule that catalog `unlock_type` is the runtime source of truth; `_FREE` remains only an asset/import naming convention.
- Hardened `equip_my_avatar(...)` so active manual avatars require a caller-owned unlock row before equip.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so active manual avatars require a caller-owned unlock row before legacy avatar-key update.
- Updated `get_my_cosmetics()` so avatars include `unlock_type`, `is_unlocked`, and `is_equipped`, matching frame-style unlock semantics.
- Added `admin_grant_cosmetic_by_slug(p_profile_slug text, p_cosmetic_key text, p_reason text default null)` for Owner/scoped member-management grants by exact username/profile slug.
- Kept `admin_grant_cosmetic(p_profile_id uuid, p_cosmetic_key text, p_reason text default null)` compatible.

Validation:
- Local `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 23B focused validation result: 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because 23B changed only database migrations/tests/docs and no frontend source.

Scope:
- No frontend UI, staging, production, Vercel, deployment, `db push`, service-role key, Supabase Storage, uploads, arbitrary URL path, or CP/GvG/audit/role/permission/member-status behavior change was included.
- Supabase CLI remains linked to production `mzflfyxxkascrfpteexz`; relink deliberately before any staging/local remote Supabase command.

Next recommended step:
- Milestone 23C staging rollout/validation for `20260525000300_premium_cosmetics_grant_helper.sql`.

## Milestone 22E Cosmetics Production Rollout Complete

Milestone 22E is complete. Cosmetics backend, static assets, and frontend picker are live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Production Supabase project `mzflfyxxkascrfpteexz` was linked intentionally for the rollout.
- Production dry-run initially hit a temporary Supabase CLI login/circuit-breaker error, then a retry passed.
- Dry-run showed exactly one pending migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Production migration push applied only `20260525000100_cosmetics_catalog_unlocks.sql`.
- Post-push migration list confirmed the cosmetics migration is applied remotely.
- `wip/cosmetics-backend-assets` was merged into `main` and pushed; Vercel deployed the production build.

Production verification:
- Cosmetics tables exist: `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- RLS is enabled on all cosmetics tables.
- Production catalog contains 54 avatar rows and 10 frame rows.
- Production catalog asset paths exactly match the 64 repo files under `public/cosmetics/`.
- RPCs exist and are granted safely: `get_available_avatars`, `get_my_cosmetics`, `equip_my_avatar`, `equip_my_frame`, and `admin_grant_cosmetic`.
- Direct unsafe anon/authenticated writes to cosmetics tables are not granted.
- Active Owner count remains `1`.
- `update_my_profile(...)` avatar key hardening is active.
- Production Vercel serves the cosmetics assets and deployed bundle markers.

Production smoke:
- User-confirmed production cosmetics UI smoke passed.
- Owner `ultimatesrb` successfully equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` / `krsticmiroslav99+m13b21144225@gmail.com` remains approved/active but did not receive an equipped cosmetics row during this smoke.

Security/scope:
- Cosmetics use approved repo static assets only.
- No player uploads, arbitrary image URLs, Supabase Storage, service-role path, or direct cosmetics table write path is part of v1.
- Players can choose avatars and equip only free/unlocked frames through RPCs.
- Frontend cosmetics paths use only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No CP/GvG/audit/role/permission/member-status behavior was changed.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before staging/local Supabase commands.

## Milestone 22B.1 Cosmetics Catalog Aligned Locally

Milestone 22B/22B.1 is implemented and locally validated as backend/database-only support for preset avatars, unlocked/equipped frames, and future cosmetic rewards.

Implemented locally:
- Added migration `20260525000100_cosmetics_catalog_unlocks.sql`.
- Added `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Aligned the catalog seed with actual Git/Vercel static assets: 54 avatar PNGs and 10 frame PNGs under `public/cosmetics/`.
- Default avatar: `1079_head` -> `/cosmetics/avatars/1079_head.png`.
- Default frame: `TXK_frame_reOpen_EN_FREE` -> `/cosmetics/frames/TXK_frame_reOpen_EN_FREE.png`.
- Added the `_FREE` naming convention: `_FREE` catalog keys must use `unlock_type = 'free'`; runtime equip checks still use explicit catalog `unlock_type`.
- Non-`_FREE` frames use `unlock_type = 'manual'` and require an unlock row before equip.
- Added RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so `avatar_key` can no longer store arbitrary keys; non-empty avatar keys must match an active catalog avatar.
- `equip_my_avatar(...)` syncs `profiles.avatar_key` for backward compatibility while the new equipped-cosmetics table becomes the cosmetics source for future UI.

Security/scope:
- Members can equip only their own active catalog avatars and only frames that are free or explicitly unlocked for their profile.
- Members cannot grant themselves cosmetics and cannot equip for another profile because equip RPCs accept no target profile id.
- Admin grants require existing scoped member-management authority: Owner, scoped Leader/Vice, or Admin with `manage_members` for the target member's active primary guild.
- No player uploads, Supabase Storage buckets, arbitrary image URLs, service-role paths, CP/GvG/audit/role/permission/member-status behavior changes, staging touch, or production touch were introduced.
- RLS is enabled on all new cosmetics tables. Direct client writes are not granted; direct reads are limited to active catalog rows and caller-owned unlock/equipped rows.

Validation:
- Local `npx.cmd supabase db reset` passed.
- Full local validation script passed through Docker `psql`.
- Milestone 22B focused validation result: 19 PASS / 0 FAIL / 0 SKIP.
- Catalog asset-path verification checked 64 rows with 0 missing files and 0 unlock mapping problems.
- `npm.cmd run build` was not run because 22B changed only database migrations/tests/docs and no frontend code.

Rollout:
- Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified through Milestones 22D and 22E.
- Future new target environments must apply and verify this migration before cosmetics UI is deployed there.
- Supabase CLI remains linked to production after Milestone 22E; future staging/local remote work must relink deliberately before any remote Supabase command.

Asset note:
- Static asset paths now match files under `public/cosmetics/avatars/` and `public/cosmetics/frames/`.
- A pre-existing untracked `public/cosmetics/` folder was left untouched during this backend-only task.

Historical next step:
- Milestone 22C frontend cosmetics picker planning/implementation.

## Milestone 21E Rank Badge / Profile Border Production Rollout Complete

Milestone 21E is complete. Rank Badge / Profile Border is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Production project `mzflfyxxkascrfpteexz` was explicitly linked before production migration work.
- Dry-run showed only `20260524000400_cp_rank_badge_summary.sql` pending.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to production.
- Remote migration list confirmed `20260524000400` applied.
- Production DB verification passed for `get_my_cp_rank_summary()` existence, security definer status, authenticated execute grant, no anon execute grant, safe return shape, direct CP table denial under authenticated member context, and active Owner count `1`.
- Commit `e99bec0 feat: add rank badge UI` was pushed to `main` and deployed by Vercel.

Production smoke:
- Owner Dashboard showed a rank badge/profile visual state.
- Owner AdminPanel still opened.
- Existing AdminPanel `CP` tab still rendered CP roster and CP Update Window controls.
- AdminPanel `CP Ranking` still rendered for Owner.
- Controlled production Member Dashboard/Profile showed the safe no-rank/default badge state.
- Controlled production Member had no Admin navigation.
- EN/FR/DE rank badge labels switched correctly.
- No console errors were captured on checked production paths.

Security/scope:
- Profile/Dashboard badge path uses `get_my_cp_rank_summary()` only.
- The rank badge UI does not render CP values, CP growth/history, snapshots, updated-by metadata, profile ids, usernames from the rank RPC, or other-member data.
- Direct frontend CP table calls and member/admin leaderboard RPCs are not used by the Profile/Dashboard badge path.
- No production CP/member data was mutated during rollout.
- No service role keys, Vercel env changes, staging changes, `db reset`, `--include-seed`, source edits, or SQL edits were performed during 21E.
- Supabase CLI is currently linked to production project `mzflfyxxkascrfpteexz`; explicitly relink before future staging/local Supabase commands.

Recommended next step:
- Milestone 22A Character Icons / Avatar Picker planning, or another user-prioritized member prestige/polish pass.

## Milestone 21D Rank Badge Staging Validation Passed

Milestone 21D staging rollout and validation passed for the Rank Badge package.

Staging rollout:
- Staging project `ckyihuxkioeibzpgwenc` was explicitly linked before migration work.
- Dry-run showed only `20260524000400_cp_rank_badge_summary.sql` pending.
- Applied only `20260524000400_cp_rank_badge_summary.sql` to staging.
- Remote migration list confirmed `20260524000400` applied.
- Production project `mzflfyxxkascrfpteexz` was not touched.

Validation:
- Staging DB verification passed for RPC existence, safe return shape, authenticated execute grant, no anon execute grant, direct CP table denial, and active Owner count `1`.
- `staging_member` Dashboard/Profile showed `Global Rank #1` / `Rank 1`.
- `staging_wrongguild` showed a safe unranked/default state.
- `staging_pending` remained locked.
- EN/FR/DE labels and mobile layout passed.
- `.env.local` was restored to local Supabase after validation.

## Milestone 21C Profile/Dashboard Rank Badge UI Implemented

Milestone 21C is implemented as frontend-only Profile/Dashboard rank badge UI and is browser-validated through staging and production rollout.

Implemented locally:
- Added `src/services/cpRankBadgeService.js`.
- Added `src/components/RankBadge.jsx`.
- Updated `Profile` with a rank-based profile border and badge in the profile header.
- Updated `Dashboard` with a compact rank badge in the member summary.
- Added EN/FR/DE `rankBadge` labels.
- Added compact dark/crimson rank badge and profile-border styling for `rank_1`, `rank_2`, `rank_3`, `elite_5`, `top_10`, `high_rank`, `ranked_member`, and `unranked`.

Security/source validation:
- Rank badge service calls only `get_my_cp_rank_summary()`.
- Profile/Dashboard do not call `get_member_cp_rankings`, `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster` for badge data.
- No direct frontend `member_cp` or `cp_snapshots` table calls were added.
- Badge UI does not render CP values, CP growth/history, snapshots, usernames from the rank RPC, profile ids, or other-member data.
- Existing CP Leaderboard, CP Update Window, GvG, audit, role, permission, and member-status behavior was not changed.

Validation:
- `npm.cmd run build` passed.
- Static/source validation passed for rank badge RPC use and protected CP paths.
- Authenticated staging browser validation passed in Milestone 21D.
- Production smoke validation passed in Milestone 21E.

Rollout boundary:
- Resolved for staging and production through Milestones 21D and 21E. Future new target environments must apply and verify `20260524000400_cp_rank_badge_summary.sql` before deploying this frontend.

Recommended next step:
- Completed by Milestones 21D and 21E.

## Milestone 21B Rank Badge Summary Backend Implemented

Milestone 21B is implemented and locally validated as backend/database-only support for safe rank badge/profile border visuals.

Implemented locally:
- Added migration `20260524000400_cp_rank_badge_summary.sql`.
- Added member-safe RPC `get_my_cp_rank_summary()`.
- The RPC returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- The RPC does not return CP values, updated timestamps, growth/history/snapshot data, usernames, profile ids, other-member data, or private metadata.

Rank tier behavior:
- `rank_one` / `rank_1`: global rank 1.
- `rank_two` / `rank_2`: global rank 2.
- `rank_three` / `rank_3`: global rank 3.
- `elite_five` / `elite_5`: global ranks 4-5.
- `top_ten` / `top_10`: global ranks 6-10.
- `high_rank`: global ranks 11-25.
- `ranked_member`: global rank 26+.
- `unranked`: no CP row or excluded from ranking eligibility.

Security/scope:
- Uses `auth.uid()` and accepts no profile id parameter.
- Uses the same ranking eligibility as the member-safe leaderboard: approved profile, active primary membership, and roster status `active`, `trial`, or `pending_transfer`.
- `inactive` and `on_break` return the unranked/default state.
- Hard-blocked users without active approved membership are denied by the same membership gate.
- Direct `member_cp` and `cp_snapshots` access remains blocked.
- Existing `get_member_cp_rankings`, `get_admin_cp_rankings`, CP Update Window, admin CP roster/update, audit, GvG, role, permission, and member-status behavior was not changed.

Validation:
- Local `npx.cmd supabase db reset` passed.
- Local validation script passed through Docker `psql`.
- Milestone 21B focused validation result: 15 PASS / 0 FAIL / 0 SKIP.
- Earlier Milestone 20B, 19B, and 19B.1 CP validation blocks still passed.
- `npm.cmd run build` was not run because 21B changed only database migration/tests/docs and no frontend code.

Rollout boundary:
- Resolved for staging and production through Milestones 21D and 21E.
- Future new target environments must apply and verify `20260524000400_cp_rank_badge_summary.sql` before deploying rank badge/profile border frontend.

Recommended next step:
- Completed later by Milestone 21C frontend implementation.

## Milestone 20F CP Leaderboard Production Rollout Complete

Milestone 20F is complete. CP Leaderboard / CP Ranking is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Production project `mzflfyxxkascrfpteexz` was explicitly linked before migration work.
- Dry-run showed only `20260524000300_cp_rankings.sql` pending.
- Applied only `20260524000300_cp_rankings.sql` to production.
- Remote migration list confirmed `20260524000300` applied.
- Production DB verification passed for ranking RPC existence, authenticated execute grants, member-safe return shape, Owner admin CP fields, non-Owner global admin denial, direct CP table denial, and active Owner count `1`.
- Commit `7ccf8c9 feat: add CP ranking UI` was pushed to `main` and deployed by Vercel.

Production smoke:
- Controlled production Member saw the member `Ranking` page.
- Member My Guild and Global rankings loaded.
- Member rows showed rank + IGN only; Global rows showed guild labels.
- No CP values, CP growth/history/snapshot fields, profile ids, usernames, updated timestamps, or private metadata were visible to Member.
- Member had no Admin navigation.
- Owner opened AdminPanel.
- Existing AdminPanel `CP` tab still loaded CP roster and CP Update Window controls.
- Separate AdminPanel `CP Ranking` tab loaded Guild and Global rankings with CP values for Owner.
- Rank decorations rendered on member and admin ranking rows.
- No console errors were captured on the checked production paths.

Security/scope:
- Member leaderboard uses `get_member_cp_rankings` only.
- Admin CP Ranking uses `get_admin_cp_rankings`.
- No direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls were found.
- Existing CP roster/update/window behavior was unchanged.
- No production CP/member data was mutated during rollout.
- No service role keys, Vercel env changes, staging changes, `db reset`, `--include-seed`, source edits, or SQL edits were performed during 20F.
- Supabase CLI is currently linked to production project `mzflfyxxkascrfpteexz`; explicitly relink before future staging/local Supabase commands.

Recommended next step:
- Completed later by Milestone 21A/21B rank badge planning and backend implementation.

## Milestone 20E CP Leaderboard Staging Validation Passed

Milestone 20E staging rollout and validation passed for the CP Leaderboard package.

Staging rollout:
- Staging project `ckyihuxkioeibzpgwenc` was already linked.
- Dry-run showed only `20260524000300_cp_rankings.sql` pending.
- Applied only `20260524000300_cp_rankings.sql` to staging.
- Remote migration list confirmed `20260524000300` applied.
- Production project `mzflfyxxkascrfpteexz` was not touched.

Validation:
- `get_member_cp_rankings` and `get_admin_cp_rankings` exist in staging.
- Authenticated execute grants exist for both RPCs.
- Member ranking responses return only rank/IGN/guild labels/current-user flag.
- Owner admin rankings return CP values through `get_admin_cp_rankings`.
- Non-Owner global admin rankings are denied.
- Pending user ranking access is denied.
- Admin without CP permissions has no CP/CP Ranking UI and admin ranking RPC is denied.
- Active Owner count remains 1.

Browser validation:
- `staging_member` saw My Guild and Global member ranking tabs with no CP values or private CP fields.
- Owner saw AdminPanel `CP` tab with roster/window controls only.
- Owner saw separate AdminPanel `CP Ranking` tab with Guild and Global rankings, CP values, and rank decoration.
- `staging_admin_noperms` saw only safe Tools access and no CP/CP Ranking tab.
- No console warnings/errors were captured on validated paths.
- Mobile/narrow layout had no horizontal overflow.

Scope confirmation:
- No production data, production Supabase, production Vercel env, or production deployment was touched.
- No SQL migrations were edited or created during 20E.
- `.env.local` was restored to local Supabase after validation.

Recommended next step:
- Completed later in Milestone 20F production rollout.

## Milestone 20D AdminPanel CP Leaderboard Upgrade Implemented

Milestone 20D is implemented locally as a frontend-only AdminPanel CP leaderboard upgrade.

Implemented locally:
- Updated `src/services/adminCpService.js` with normalized `get_admin_cp_rankings` rows for AdminPanel use.
- Updated `src/pages/AdminPanel.jsx` to load admin CP rankings through `get_admin_cp_rankings`.
- Added `src/components/admin/AdminCpLeaderboardSection.jsx` with Guild / Global leaderboard tabs.
- Added a separate AdminPanel `CP Ranking` tab so the CP roster/window tab stays focused.
- Added compact decorated admin rank rows showing rank, IGN, username, guild, CP value, and last updated.
- Added Owner-only frontend visibility for the Global admin leaderboard tab; backend RPC authorization remains the authority.
- Added EN/FR/DE i18n labels for admin leaderboard scope, rank, guild, last-updated, empty, and permission/error states.
- Added compact mobile styling for admin CP ranking rows.

Security/source validation:
- Admin CP leaderboard now calls `get_admin_cp_rankings` and no longer uses the older `get_cp_leaderboard` path.
- Member-facing Leaderboard remains unchanged and still calls only `get_member_cp_rankings`.
- No direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls were added.
- Existing AdminPanel CP roster/update/window controls were preserved.
- Existing CP Update Window, member CP Ranking page, GvG, audit, role, permission, and member-status behavior was not changed.

Validation:
- `npm.cmd run build` passed.
- Static/source validation passed for protected CP paths.
- Authenticated browser validation is pending because staging/production do not yet have `20260524000300_cp_rankings.sql`.

Rollout boundary:
- Do not deploy this frontend to any remote environment until that environment has `20260524000300_cp_rankings.sql` applied and verified.

Recommended next step:
- Milestone 20E staging migration rollout and browser validation for 20B/20C/20D.

## Milestone 20C Member CP Leaderboard Frontend Implemented

Milestone 20C is implemented locally as a frontend-only member-facing CP Ranking page.

Implemented locally:
- Added `src/services/cpLeaderboardService.js`.
- Added `src/pages/Leaderboard.jsx`.
- Added a member nav item for CP Ranking.
- Wired the page into the existing app page-id router.
- Added EN/FR/DE i18n labels for the leaderboard surface.
- Added compact mobile-first rank list styling with top-rank/Elite 5/Top 10 decorations.

Member leaderboard behavior:
- Uses only `get_member_cp_rankings(p_scope)`.
- Supports `guild` and `global` scopes through `My Guild` and `Global` tabs.
- My Guild shows rank and IGN only.
- Global shows rank, IGN, and guild label.
- Current user rows are highlighted when `is_current_user` is returned.
- Empty/loading/error states are compact and translated.
- No CP values, CP growth, CP history, snapshots, admin notes, profile ids, usernames, timestamps, or private metadata are rendered.

Security/source validation:
- `cpLeaderboardService.js` calls only `get_member_cp_rankings`.
- The member leaderboard does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, or `get_current_cp_roster`.
- No direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls were added.
- Existing AdminPanel CP roster/update/window behavior was not changed.
- Existing CP Update Window, GvG, audit, role, permission, and member-status behavior was not changed.

Validation:
- `npm.cmd run build` passed.
- Local browser smoke loaded the app at `http://127.0.0.1:5173/` and verified the unauthenticated shell still renders.
- Authenticated leaderboard browser validation was not completed because staging/production do not have `20260524000300_cp_rankings.sql` yet and no usable local auth browser account was available.

Rollout boundary:
- Do not deploy this frontend to any remote environment until that environment has `20260524000300_cp_rankings.sql` applied and verified.

Recommended next step:
- Milestone 20D AdminPanel CP leaderboard upgrade, or Milestone 20E staging migration rollout and member leaderboard validation if the member-only slice should validate first.

## Milestone 20B CP Leaderboard Backend Implemented

Milestone 20B is implemented and locally validated as backend/database-only support for member-safe CP rankings and admin CP rankings.

Implemented locally:
- Added migration `20260524000300_cp_rankings.sql`.
- Added member-safe RPC `get_member_cp_rankings(p_scope text default 'guild')`.
- Added admin/staff RPC `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
- Added ranking support indexes on `member_cp`.
- Preserved existing CP Update Window, admin CP roster/update, and audit-redaction behavior.

Member-safe ranking behavior:
- Member rankings support `guild` and `global` scopes.
- Member RPC returns only `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member RPC does not return CP values, profile ids, usernames, timestamps, snapshots, growth, history, or audit metadata.
- Member guild scope uses the caller's active primary guild.
- Member global scope returns safe rank order across eligible approved active roster members.

Admin ranking behavior:
- Admin guild scope returns CP values only when the caller passes existing scoped `view_cp` authority.
- Admin global scope is Owner-only in v1.
- Admin return shape includes rank, profile/user labels, guild labels, CP value, and updated timestamp.

Roster and ranking rules:
- Rows include approved profiles with active memberships and roster status `active`, `trial`, or `pending_transfer`.
- Rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.
- `inactive` and `on_break` members can still view rank order if existing access gates allow them into the member area, but they are not listed as ranked rows.
- Ranks use `row_number()` with deterministic ordering by `cp_value desc`, then IGN/profile tie-breaker.

Validation:
- Local `npx.cmd supabase db reset` passed.
- Local validation script passed through Docker `psql` after the Supabase CLI query wrapper rejected the multi-statement validation file.
- Milestone 20B focused validation result: 14 PASS / 0 FAIL / 0 SKIP.
- Existing Milestone 19B and 19B.1 CP Update Window validation still passed.
- `npm.cmd run build` was not run because 20B changed only database migration/tests/docs and no frontend code.

Scope confirmation:
- Backend/database only.
- No React components or frontend services were edited.
- No staging or production project was touched.
- No deployment, Vercel configuration, or commit was performed.

Rollout boundary:
- `20260524000300_cp_rankings.sql` is local-only. Staging and production do not have it yet.
- Do not deploy frontend CP leaderboard UI to any target until that target DB has this migration applied and verified.

Recommended next step:
- Milestone 20C member leaderboard frontend planning/implementation, followed by staging migration rollout and validation before any production deployment.

## Milestone 19E CP Update Window Production Rollout Complete

Milestone 19E is complete. CP Update Window / Member CP Self-Submit is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Production project `mzflfyxxkascrfpteexz` was explicitly linked before migration work.
- Dry-run showed only the expected pending migrations:
  - `20260524000100_cp_update_window_self_submit.sql`
  - `20260524000200_cp_update_window_staff_read.sql`
- Both migrations were applied to production and verified remotely.
- Production DB verification passed for `cp_update_windows`, RLS, one-open-window unique index, safe RPC existence/grants, audit redaction support, direct client grant absence, and active Owner count.
- Frontend commit `6a3a181 feat: add CP update window self-submit` was pushed to `main` and deployed by Vercel.

Production smoke:
- Owner sign-in worked.
- AdminPanel CP tab loaded.
- CP Update Window block rendered for the selected guild and showed `Closed`.
- Member sign-in worked.
- Profile showed the `Your CP` card with own CP only.
- With no production CP window open, member submit controls were not exposed and the closed-window message rendered.
- Member had no Admin navigation and no CP roster/leaderboard access.
- No captured console errors were observed during the checked Owner/member paths.

Security/scope:
- No controlled production mutation smoke was performed by design; no production CP window was opened/closed and no production CP value was submitted.
- Optional future mutation smoke must use a controlled production test member only, require explicit approval, and document whether test data is restored or retained.
- No production CP/member data was intentionally mutated beyond schema migration and frontend deployment.
- No service role keys, Vercel env changes, `db reset`, `--include-seed`, staging changes, or source/SQL edits were performed during the production rollout.
- Supabase CLI is currently linked to production project `mzflfyxxkascrfpteexz`; explicitly relink before future staging/local Supabase commands.

Recommended next step:
- Docs/handoff commit checkpoint for Milestone 19E, then choose the next approved milestone. Good candidates are optional controlled production CP mutation smoke, Weekly CP Snapshot/Growth Reports planning, member status history UI planning, or invite/onboarding tools.

## Milestone 19C CP Update Window Frontend Implemented

Milestone 19C is implemented locally as a frontend-only Profile/AdminPanel integration for the Milestone 19B/19B.1 CP Update Window backend.

Implemented locally:
- Added `src/services/cpWindowService.js` with RPC-only wrappers for own CP, own active window status, member self-submit, selected-guild staff window status, and staff open/close actions.
- Added a compact Profile `Your CP` panel that reads only the signed-in member's own CP through `get_my_cp()` and window status through `get_active_cp_update_window_for_me()`.
- Profile CP submission calls only `submit_my_cp_update(...)`, validates required/numeric/non-negative input locally, and refreshes own CP/window status after success.
- Added AdminPanel CP Update Window controls to the CP tab using `get_cp_update_window_for_guild(...)`, `open_cp_update_window(...)`, and `close_cp_update_window(...)`.
- Added EN/FR/DE i18n copy for member CP self-submit, CP window controls, and new audit/window labels.
- Added compact dark/crimson styling for the Profile CP card and Admin CP window block.

Validation:
- `npm.cmd run build` passed.
- Local unauthenticated browser smoke loaded the app with no captured console errors.
- Static source checks found no direct frontend `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.
- Static source checks confirmed Profile and `cpWindowService` do not call `get_current_cp_roster` or `get_cp_leaderboard`.
- SQL/migration files were not changed in 19C.

Validation boundary:
- Authenticated CP-window browser validation is pending because staging and production do not yet have migrations `20260524000100_cp_update_window_self_submit.sql` and `20260524000200_cp_update_window_staff_read.sql`.
- Do not deploy or push this frontend to a target environment until that environment has both CP Update Window migrations applied and verified.

Recommended next step:
- Milestone 19D staging migration rollout and staging browser validation for CP Update Window / Member CP Self-Submit.

## Milestone 19B.1 CP Update Window Staff Read RPC Implemented

Milestone 19B.1 is implemented and locally validated as a backend-only follow-up for AdminPanel CP Update Window status.

Implemented locally:
- Added migration `20260524000200_cp_update_window_staff_read.sql`.
- Added `get_cp_update_window_for_guild(p_guild_id uuid)`.
- The RPC returns safe selected-guild window status for authorized staff only.
- It returns an open window first when present, otherwise the latest closed window, otherwise no row.
- Returned fields include window id, guild id, status, opens/closes timestamps, note, created/updated timestamps, safe creator/closer labels, and server time.
- No direct `cp_update_windows` table grants or policies were added.

Validation:
- `npx.cmd supabase db reset` passed locally.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 19B.1 focused validation result: 13 PASS / 0 FAIL / 0 SKIP.
- Existing Milestone 19B validation still passed: 32 PASS / 0 FAIL / 0 SKIP.

Scope confirmation:
- Backend/database only.
- No frontend UI is implemented yet.
- No React components were edited.
- No staging or production project was touched.
- No deployment, Vercel configuration, or commit was performed.

Recommended next step:
- Milestone 19C frontend implementation using the now-complete 19B/19B.1 backend RPC set.

## Milestone 19B CP Update Window Backend Implemented

Milestone 19B is implemented and locally validated as backend/database-only support for CP Update Window / Member CP Self-Submit.

Implemented locally:
- Added migration `20260524000100_cp_update_window_self_submit.sql`.
- Added guild-scoped `cp_update_windows` with one open window per guild.
- Added RPC-only member CP self-submit support.
- Added safe own-CP read support for members through `get_my_cp()`.
- Added safe own-guild window status through `get_active_cp_update_window_for_me()`.
- Added staff window management RPCs: `open_cp_update_window(...)` and `close_cp_update_window(...)`.
- Added `member_cp_self_submitted`, `cp_update_window_opened`, and `cp_update_window_closed` audit actions.
- Extended audit redaction so CP old/new metadata from member self-submits is hidden from audit users without scoped `view_cp`.

Validation:
- `npx.cmd supabase db reset` passed locally.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 19B focused validation result: 32 PASS / 0 FAIL / 0 SKIP.
- Existing local validation sections still passed, including CP hardening, audit hardening, and Member Status checks.

Scope confirmation:
- Backend/database only.
- No frontend CP Update Window UI is implemented yet.
- No React components were edited.
- No staging or production project was touched.
- No deployment, Vercel configuration, or commit was performed.

Recommended next step:
- Milestone 19C frontend planning for Profile `Your CP` self-submit UI and AdminPanel CP Update Window controls.

## Milestone 16H Member-Facing UI Production Rollout Complete

Milestone 16H is complete. The member-facing compact UI/copy pass is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Deployed commit `53c7907 style: clean up member-facing UI`.
- Production app loaded successfully after Vercel served the new build.
- Login/Register panels are compact and translated.
- Forgot Password remains visible.
- Owner login and AdminPanel access worked.
- Controlled production Member login worked.
- Member Dashboard, Profile, and GvG are compact and translated.
- EN/FR/DE language switching works and persists after reload.
- Mobile/narrow viewport had no horizontal overflow.

Security/scope:
- Member has no Admin navigation or AdminPanel access.
- No other-member CP exposure was found.
- No raw translation keys or console errors were captured.
- CP privacy, GvG behavior, audit access, role/guild/permission behavior, and Member Status behavior are unchanged.
- No SQL, Supabase commands, Supabase/RLS/RPC changes, Vercel env changes, production data mutations, or deployment settings changes were made.

Recommended next milestone:
- Choose the next approved feature or polish track. Good candidates are CP Update Window planning, Weekly CP Snapshot/Growth Reports planning, Member Status history UI planning, announcements/onboarding invite codes, or French/German wording review by native speakers.

## Milestone 16F Member-Facing UI Compact Pass Implemented

Milestone 16F is implemented locally as a frontend-only member-facing UI/copy compact pass.

Implemented:
- Added compact member-facing panel variants for auth, recovery, pending/rejected/suspended/restricted gates, Dashboard/Home, Profile, and GvG.
- Tightened mobile spacing in the app shell, page heading, panels, forms, metric cards, profile details, and GvG vote panel.
- Dashboard/Home now prioritizes guild, role, roster status, GvG state, and a compact member summary.
- Profile keeps IGN editing unchanged while shortening locked-field copy to the equivalent of `Only IGN is editable.`
- GvG copy is shorter: `GvG`, `Awaiting GvG`, `Voting not open.`, and `Not expected for GvG.`
- Pending/rejected/suspended/restricted messages are shorter while preserving lockout meaning.
- Changed copy is wired through the existing EN/FR/DE i18n dictionaries.

Validation:
- `npm.cmd run build` passed.
- Static source checks found no `supabase/` or `src/services/` changes.
- Static source checks found no new direct protected table calls in the frontend diff.
- Local browser smoke passed for Login/Register/Forgot Password in EN/FR/DE.
- Local browser smoke found no raw translation keys, no captured console errors, and no horizontal overflow on checked auth surfaces.

Validation boundary:
- Local app was pointed at local Supabase, so authenticated member/staging validation was not run in this implementation pass.
- A fake `#type=recovery` URL without a live Supabase recovery session did not show the Set New Password screen; this matches the recovery-session dependency. Recovery behavior itself was production-validated in Milestone 17C.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No service behavior was changed.
- No auth behavior, CP logic, GvG voting logic, audit behavior, role/guild/permission behavior, or member-status rules were changed.
- No deployment or commit was performed.

Recommended next step:
- Milestone 16G authenticated staging validation for the member-facing compact UI pass, including member, pending, restricted/roster status if testable, GvG eligibility, no AdminPanel for members, no CP leakage, and EN/FR/DE mobile checks.

## Milestone 18F Language Pack Production Rollout Complete

Milestone 18F is complete. The English/French/German language pack is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Deployed commit `1f5b956 feat: add English French German language pack`.
- Supported languages are English (`en`), French (`fr`), and German (`de`).
- The language switcher works logged out and logged in.
- Selected language persists after reload through `agm_language`.
- Login, registration, forgot-password, member-facing surfaces, and full AdminPanel content are translated.
- Full AdminPanel translation is live for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.

Production validation:
- Production app loaded successfully.
- Owner sign-in and AdminPanel access worked.
- AdminPanel tabs translated across EN/FR/DE.
- Members, CP, GvG, Audit, Permissions, and Tools tabs rendered.
- No raw translation keys were visible.
- No console errors were captured during smoke validation.
- Mobile/narrow viewport had no horizontal overflow.
- Existing production Member had no Admin navigation.

Security/scope:
- Member/admin security behavior is unchanged.
- CP privacy, Audit access, GvG behavior, role/permission behavior, and Member Status behavior are unchanged.
- No SQL, Supabase, RLS/RPC, Vercel env, or production data changes were made.
- Recovery gate copy was not fully re-tested during 18F because no live recovery session was triggered; recovery behavior was already production-validated in Milestone 17C.

Future improvement:
- Have French/German-speaking admins review wording and shorten any labels that feel unnatural in daily use.

Recommended next milestone:
- Milestone 18F docs/handoff commit checkpoint, then translation wording review or the next approved feature planning track.

## Milestone 18B i18n Foundation Implemented

Milestone 18B is implemented locally as a frontend-only language-pack MVP foundation.

Implemented:
- Added lightweight internal i18n dictionaries for English (`en`), French (`fr`), and German (`de`).
- Added `LanguageProvider`, `useLanguage()`, `t(key, params?)`, English fallback behavior, and `agm_language` localStorage persistence.
- Wrapped the app as `LanguageProvider > AuthProvider > AppContent` so auth/login/register and shell surfaces can translate.
- Added a compact EN/FR/DE language selector in the topbar, visible for logged-out and logged-in users.
- Translated core shell/navigation/auth/recovery/gate/status/member-facing status surfaces included in 18B scope.
- AdminPanel full content remains out of scope for 18B; only basic Admin tab labels are wired for translation.

Validation:
- `npm.cmd run build` passed.
- Built-app preview validation passed for EN/FR/DE language switching.
- Reload persistence passed for the selected language.
- Login/register and password recovery surfaces translated in preview.
- No missing translation-key strings were visible in the checked auth/recovery paths.
- Captured console errors were empty during preview validation.
- Static checks found no Supabase migration changes and no new protected-table paths in the touched files.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No auth behavior, CP/GvG/audit/role/permission/member-status logic was changed.
- No deployment or commit was performed.

Recommended next step:
- Milestone 18C: member-facing authenticated language validation and remaining member page translation polish, or Milestone 18D AdminPanel full translation pass.

## Milestone 17D Registration Copy Update Implemented

Milestone 17D frontend copy/auth UX preparation is implemented locally for controlled guild onboarding without assuming email confirmation.

Implemented:
- Registration hero copy now says `Register for guild approval.`
- Registration email field now warns: `Use a real email. You'll need it for password reset.`
- Registration submit button now says `Request approval`.
- The no-session signup fallback now uses mode-tolerant copy: `If a confirmation email was sent, confirm it first. Your account still needs guild approval.`
- Pending screen title now says `Awaiting approval.`

Validation:
- `npm.cmd run build` passed.
- Static checks found no Supabase migration changes.
- Static checks found no service file changes and no new protected-table paths.
- `ai_agents/INDEX.json` parses.

Policy recorded:
- Production email confirmation remains enabled until a separately approved production Auth setting change.
- Staging should be used first to validate disabling email confirmation.
- Admin approval remains mandatory and pending users remain blocked.
- Password recovery remains enabled and was production-validated in Milestone 17C.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No Supabase Auth settings were changed.
- No Vercel env vars were changed.
- No profile approval, membership status, roster status, role/guild/permission, CP, GvG, audit, or member-status behavior was changed.
- No deployment or commit was performed.

Recommended next step:
- Manually disable email confirmation in staging only, then validate controlled staging signup/pending/approval/recovery before any production Auth setting change.

## Milestone 17C Password Recovery Production Rollout Complete

Milestone 17C is complete. The Password Recovery Required Reset Flow is live in production at `https://anteiku-guild-manager.vercel.app`.

Production rollout:
- Deployed commit `23dd956 fix: require password reset after recovery link`.
- Production smoke passed after deployment.
- Forgot-password UI is visible in production.
- Recovery links now show the required `Set new password` gate.
- Normal app navigation is blocked before password update.
- Password update succeeds through the Supabase Auth password update flow.
- New password login works after reset.
- Role/access state remains unchanged after reset.

Validation:
- Controlled production test member `krsticmiroslav99+m13b21144225@gmail.com` was used for first production recovery validation.
- No real member account was used for the first production recovery test.
- No passwords, recovery tokens, or secrets were stored in docs or source.
- Captured production console warnings/errors were empty after rollout validation.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No Supabase Auth settings were changed.
- No Vercel env vars were changed.
- No profile approval, membership status, roster status, role/guild/permission, CP, GvG, or audit behavior was changed.
- No production data was intentionally mutated outside the controlled password reset for the controlled production test member.

Recommended next milestone:
- Milestone 17D / 16F: Disable email confirmation + registration copy update planning for controlled guild onboarding.

## Milestone 17A Password Recovery Required Reset Flow Implemented

Milestone 17A is implemented locally as a frontend/auth UX fix. Supabase password recovery sessions are now treated as a required reset state instead of a normal app sign-in, so normal navigation stays blocked until the user updates their password or signs out.

Implemented:
- Added auth service wrappers for requesting a password reset email and updating a recovered password.
- Added `PASSWORD_RECOVERY` handling plus recovery URL fallback detection in `AuthContext`.
- Added a sessionStorage recovery marker so refreshes during recovery keep showing the reset screen.
- Added a top-priority app routing gate that renders `Set new password` before pending/member/admin routes.
- Added a forgot-password flow on the sign-in screen with neutral success copy: `If the email exists, a reset link was sent.`
- Added `src/pages/SetNewPassword.jsx` with new password, confirmation, validation, update action, and sign-out escape.

Validation:
- `npm.cmd run build` passed.
- Local browser smoke confirmed the auth page shows `Forgot password?`.
- Local browser smoke confirmed `#type=recovery` forces the `Set new password` screen and hides normal navigation.
- Local browser smoke confirmed signing out clears the recovery marker and returns to the auth screen.
- Captured console warnings/errors were empty for the local recovery smoke path.
- Static checks found no Supabase migration changes and no protected-table path changes.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No profile approval, membership status, roster status, role/guild/permission, CP, GvG, or audit behavior was changed.
- No deployment or commit was performed.

Remaining validation:
- Real staging recovery-email validation is still required before marking the recovery flow production-ready: send reset email, click Supabase recovery link, set a valid new password, confirm new password works, and confirm pending/member/admin/suspended gates remain unchanged.

Recommended next milestone:
- Milestone 17B staging password recovery email-link validation, then production rollout planning after staging passes.

## Milestone 16D.1 AdminPanel Compact Member Cards And Copy Cleanup Implemented

Milestone 16D.1 is implemented locally as a frontend-only UI/copy cleanup pass. It makes the AdminPanel Members tab more practical for guilds with 30-40 members by turning the default roster view into compact rows and moving heavier edit controls behind a per-member `Manage` disclosure.

Implemented:
- Replaced tall always-open member cards with compact roster rows showing IGN, username, role badge, roster status badge, guild, membership status, profile status, and updated timestamp.
- Kept IGN editing, username reset, roster status updates, role changes, guild transfer, hard-block status reason input, and confirmations accessible inside `Manage`.
- Removed the product-facing environment pill text such as `Supabase configured` from the app chrome.
- Shortened auth, dashboard, GvG, pending, and rejected-state copy to app-facing language.
- Preserved the previous `Reset username/username` fix in Permissions display copy.

Validation:
- `npm.cmd run build` passed.
- Static source checks found no service, Supabase migration, or Supabase test changes.
- Technical-term search found no remaining product-facing UI strings for `Supabase configured`, `RPC`, `RLS`, `backend`, `policies`, `scaffold`, or `milestone`; remaining matches are internal identifiers/config code only.
- Authenticated staging browser validation passed for `staging_owner`: AdminPanel Members rendered compact rows, a member `Manage` section expanded, and IGN/username/status/role/guild controls remained accessible.
- Staging browser validation also confirmed CP, GvG, Audit Logs, Permissions, and Tools still render and no console warnings/errors were captured.
- `.env.local` was restored to local Supabase settings after staging validation, and Vite was restarted locally.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No service behavior was changed.
- No production deployment, Vercel env change, or commit action was performed.

Recommended next milestone:
- Commit checkpoint for Milestone 16D.1 when approved, then an explicit production UI rollout request if desired.

## Milestone 16C Authenticated AdminPanel Browser Validation Passed

Milestone 16C passed authenticated browser validation against staging through the local frontend temporarily pointed at `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`. Milestone 16B can now be treated as implemented, build/source validated, and authenticated-browser validated.

Validated:
- `staging_owner` opened AdminPanel and switched Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Members tab badges, filters, status controls, hard-block confirmation/reason UI, and role/guild/username tools rendered.
- CP tab loaded with shorter copy and preserved authorized CP visibility.
- GvG tab loaded without behavior changes.
- Audit Logs loaded, kept `Sensitive CP metadata hidden.` for a user without `view_cp`, and showed backend-returned `New CP 1,234,567` for a user with `view_cp`.
- Permissions and Tools rendered for authorized Owner.
- `staging_admin_noperms` saw only safe Tools access and no restricted admin sections.
- `staging_member` had no AdminPanel access and no other-member CP exposure.
- `staging_pending` remained locked to the pending approval screen with no member/admin navigation.
- `staging_wrongguild` remained scoped to Anteiku:Rose and did not see/vote on Anteiku GvG data.
- Mobile AdminPanel viewport remained readable and tappable.

Validation notes:
- The UI copy issue "Profile slug" was rephrased to user-facing "Username" where surfaced in Admin/Profile/auth/audit/permissions display text.
- AdminPanel shell copy was adjusted so restricted admins see neutral available-section copy instead of references to unavailable tools.
- `npm.cmd run build` passed after the UI copy fixes.
- Source/security-path validation found no service changes, no Supabase migration/test changes, no new direct protected CP/audit/history table calls, and no unsafe GvG writes.
- Staging test credentials were used only transiently for validation and were not stored in docs or source.
- `.env.local` was restored to local Supabase settings after validation.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC/service behavior was changed.
- No production, Vercel env, deployment, or commit action was performed.

Recommended next milestone:
- Milestone 16D member-facing UI cleanup planning, or a 16B/16C commit checkpoint before any rollout.

## Milestone 16B AdminPanel UI Cleanup Implemented

Milestone 16B is implemented locally and browser-validated through Milestone 16C as a frontend-only AdminPanel polish pass. It tightens AdminPanel copy, cards, empty states, metadata rows, tabs, and mobile spacing without changing services, database logic, permissions, CP, GvG, audit, role/guild, or member-status behavior.

Implemented:
- Shortened the AdminPanel shell copy to direct operational text.
- Removed live AdminPanel implementation wording such as RPC, backend, policies, scaffold, and milestone language.
- Tightened Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools section copy.
- Added compact AdminPanel card, empty-state, metadata, control-block, and mobile styles.
- Preserved destructive confirmations, hard-block member-status reason/confirmation flow, transfer reset warning, CP redaction notice, and permission-denial meaning.

Validation:
- `npm.cmd run build` passed.
- Static source checks found no service, Supabase migration, or Supabase test changes.
- Static source checks found no new direct frontend `member_cp`, `cp_snapshots`, `audit_logs`, or `member_status_history` calls.
- Existing approved service paths remain unchanged: CP uses approved CP RPCs, Audit uses `get_audit_logs`, GvG uses approved GvG RPCs/safe reads, and member status updates use `update_member_roster_status`.
- Authenticated staging browser validation passed in Milestone 16C for Owner, restricted admin, member, pending, audit no-CP, audit+CP, and wrong-guild accounts.

Scope confirmation:
- No SQL migrations were edited or created.
- No Supabase/RLS/RPC logic was changed.
- No services were edited.
- No deployment or commit was performed.

Recommended next milestone:
- Milestone 16D member-facing UI cleanup planning, or a 16B/16C commit checkpoint before rollout.

## Milestone 15E Member Status Production Rollout Complete

Milestone 15E is complete. The Member Status System is live in production after the production database migration, frontend deployment, and production smoke validation all passed.

Production rollout:
- Production project ref: `mzflfyxxkascrfpteexz`.
- Applied only migration `20260523000100_member_roster_status_system.sql`.
- Production DB verification passed for `guild_memberships.roster_status`, default `active`, `NOT NULL`, allowed-status check constraint, roster-status index, `member_status_history`, RLS/policies/grants, and `update_member_roster_status(...)`.
- Existing production memberships were backfilled to `roster_status = active`.
- Active Owner count remained `1`.
- Commit `23866be feat: add member roster status system` was pushed to `main`.
- Vercel deployed the Member Status frontend.
- Production smoke validation passed for Owner AdminPanel/Members/CP/Audit/GvG paths and Member Home/Profile/GvG paths.

Security/scope:
- No production roster-status mutation smoke was performed.
- Optional future mutation smoke must use the controlled production test member only, require explicit approval, and restore the user to `active`.
- No service role keys, Vercel env changes, destructive SQL, `db reset`, or `--include-seed` were used.
- No production data was copied, deleted, or mutated beyond the schema migration/backfill.
- Member smoke found no AdminPanel access and no CP leakage.

Operational note:
- Supabase CLI is currently linked to production project `mzflfyxxkascrfpteexz`.
- Future staging/local work must explicitly relink before running Supabase commands.

Recommended next milestone options:
- Optional controlled production status mutation smoke.
- CP Update Window planning.
- Weekly CP Snapshot/Growth Reports planning.
- Member status history UI planning.
- Announcements or onboarding/invite codes.

## Milestone 15D Member Status Staging Validation Passed

Milestone 15D staging migration rollout and browser validation passed. The Milestone 15A Member Status migration was applied to staging only, and the Milestone 15B frontend was validated against controlled staging users.

Staging target:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Production project ref `mzflfyxxkascrfpteexz` was not touched.

Migration rollout:
- Dry-run showed only `20260523000100_member_roster_status_system.sql` pending for staging.
- `20260523000100_member_roster_status_system.sql` was applied to staging.
- Staging migration history now includes the prior 9 migrations plus the 15A Member Status migration.
- Staging schema/RLS verification passed for `guild_memberships.roster_status`, `member_status_history`, `update_member_roster_status(...)`, RLS/policies/grants, default/backfilled `roster_status`, and active Owner count.

Browser validation:
- Milestone 15B frontend is browser-validated through staging.
- `staging_owner` Members tab badges, filter, and status controls worked.
- `staging_member` was transitioned through `trial`, `inactive`, `on_break`, `pending_transfer`, `suspended`, and restored to `active`.
- `suspended` showed the restricted notice and blocked member/admin areas.
- `on_break` allowed Home/Profile and showed not expected for GvG with no vote controls.
- `staging_admin_noperms` had no Members/status/CP/Audit/GvG management controls.
- Final `staging_member` state was verified as `membership_status = active` and `roster_status = active`.
- Read-only verification found 8 `member_status_history` rows and 8 `member_roster_status_changed` audit rows from the validation flow.

Source/security-path validation:
- Status updates use `update_member_roster_status(...)` only.
- No direct frontend `guild_memberships` writes were added.
- No frontend `member_status_history` calls were added.
- No new direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls were added.
- CP privacy remains unchanged.

Scope confirmation:
- Production was not touched.
- Vercel env vars were not changed.
- No deployment was performed.
- `.env.local` was restored to local Supabase after validation.
- Vite was restarted locally after `.env.local` restore.
- No source or SQL changes were made during this 15D docs checkpoint.

Production gate:
- Production rollout later completed in Milestone 15E.

Recommended next milestone:
- Completed later: Milestone 15E production rollout planning/execution gate for the Member Status migration and frontend release.

## Milestone 15B Member Status Frontend Implemented And Staging Browser Validated

Milestone 15B frontend work is implemented locally and build/source validated. It wires the Milestone 15A backend Member Status system into the React UI without changing SQL, RLS, RPCs, CP logic, Vercel, staging, or production.

Implemented:
- Safe viewer/member roster reads now include `guild_memberships.roster_status`.
- Admin Members tab shows roster status badges, roster status filtering, and status-change controls.
- Status changes call only `update_member_roster_status(...)` through the frontend service wrapper.
- Hard-block status changes (`suspended`, `left`, `kicked`) require a reason and confirmation.
- Private status history/reasons are not displayed in the roster UI.
- Dashboard and Profile show the current user's roster status badge and safe explanatory notes.
- Hard-blocked roster statuses show a restricted notice instead of member/admin areas.
- GvG hides vote controls for `inactive` and `on_break` users and shows a not-expected/not-eligible message.
- Added `RosterRestrictedStatus` for roster-level `suspended`, `left`, and `kicked` gates.

Validation:
- `npm.cmd run build` passed.
- Static source checks confirmed status writes use `update_member_roster_status`.
- Static source checks found no new direct `member_status_history` calls, no direct `guild_memberships` updates, and no direct `member_cp`, `cp_snapshots`, or `audit_logs` table calls.
- No `supabase/migrations` or `supabase/tests` files were changed during Milestone 15B.

Browser validation status:
- Milestone 15B was browser-validated through staging in Milestone 15D after applying the 15A migration to staging.
- Production browser validation passed in Milestone 15E after the production database migration was applied and verified.

Recommended next milestone:
- Optional controlled production status mutation smoke, CP Update Window planning, Weekly CP Snapshot/Growth Reports planning, Member status history UI planning, or announcements/onboarding/invite-code planning.

Rollout warning:
- Do not deploy this frontend to staging or production before the Milestone 15A migration is applied and verified in that target, because the frontend now reads `guild_memberships.roster_status`.

## Milestone 15A Member Status Backend Implemented And Validated

Milestone 15A backend/database work is complete locally. It adds a separate roster lifecycle concept without reusing `profiles.approval_status` or `guild_memberships.membership_status`.

Implemented:
- New migration: `supabase/migrations/20260523000100_member_roster_status_system.sql`.
- `guild_memberships.roster_status text not null default 'active'`.
- Allowed roster statuses: `active`, `trial`, `inactive`, `on_break`, `suspended`, `left`, `kicked`, and `pending_transfer`.
- New private staff-history table: `member_status_history`.
- New safe RPC: `public.update_member_roster_status(p_membership_id uuid, p_new_status text, p_reason text default null)`.
- New audit action: `member_roster_status_changed`.
- GvG eligibility now excludes `inactive` and `on_break` members from active event visibility/voting while preserving their hard active membership.

Security behavior:
- `active`, `trial`, and `pending_transfer` keep normal access.
- `inactive` and `on_break` are not hard lockouts; users can still log in and keep active membership, but they are excluded from GvG participation/expectation.
- `suspended`, `left`, and `kicked` are hard roster-access blocks.
- `suspended` maps to `membership_status = 'suspended'`.
- `left` maps to `membership_status = 'left'`.
- `kicked` maps to `membership_status = 'left'` because current `membership_status` has no `kicked` value and `rejected` is reserved for registration/reapply semantics.
- Owner can set all statuses globally, with last-active-Owner protection.
- Leader/Vice can set scoped non-Owner statuses.
- Admin with `manage_members` can set only `active`, `trial`, `inactive`, `on_break`, and `pending_transfer`; Admin cannot set hard-block statuses, affect Owners, or change self.
- Members cannot change roster status.
- Private reasons live only in `member_status_history`; audit metadata records only whether a reason exists.

Validation:
- `npx.cmd supabase db reset` passed locally.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 15A validation result: 22 PASS / 0 FAIL / 0 SKIP.
- Existing local validation sections still passed.

Scope confirmation:
- Backend/database only.
- No React components or frontend UI were changed.
- No production Supabase project was touched.
- No Vercel env vars were changed.
- No deployment was performed.
- No commit was made.

Recommended next milestone:
- Milestone 15B frontend planning for Member Status UI/access gating.

## Milestone 14H Staging CP Redaction And GvG Smoke Validation Complete

Milestone 14H is complete. Staging browser validation and read-only SQL verification passed for CP audit redaction, CP metadata visibility, full GvG smoke, permission denial checks, wrong-guild denial, and pending-user lockout.

Staging validation target:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Production project ref `mzflfyxxkascrfpteexz` was not touched.

Validated:
- Owner updated `staging_member` CP to `1234567` through the CP UI.
- `staging_audit_nocp` could access Audit Logs and saw `Sensitive CP metadata hidden.`.
- `staging_audit_nocp` did not see CP value, `cp_old`, or `cp_new`.
- `staging_audit_cp` could access Audit Logs and saw backend-returned CP metadata: `New CP 1,234,567`.
- Owner created and opened GvG event `M14H Staging GvG Smoke`.
- `staging_member` voted Present, switched to Absent with reason, then switched back to Present.
- Owner closed the event.
- Read-only SQL confirmed exactly one `gvg_votes` row for `staging_member` and the event, final vote status `present`, and `absence_reason = null`.
- `staging_wrongguild` could not see or vote on the Anteiku-scoped event.
- `staging_admin_noperms` did not see restricted admin tools.
- `staging_pending` was locked to the Pending page.
- Active Owner count remained `1`.

Deferred production tests now covered in staging:
- Full GvG smoke test.
- CP audit redaction browser scenario.
- Permission denial flows.
- Wrong-guild access.
- Pending-user lockout.

Network validation caveat:
- Literal DevTools request capture was not available through the browser automation surface.
- Source-path inspection confirmed Audit uses `get_audit_logs`.
- Source-path inspection confirmed CP uses `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- Source-path inspection confirmed GvG writes use approved RPCs, with the own-vote `gvg_votes` read expected and safe.
- This caveat is recorded as non-blocking for Milestone 14H completion.

Scope confirmation:
- Test data remains in staging intentionally.
- No staging cleanup/delete was performed.
- No production Supabase project was touched.
- No Vercel Preview env vars were configured.
- No deployment was performed.
- No source code, SQL migrations, or new migrations were changed or created.
- `.env.local` was restored to local Supabase settings after validation.
- No commit was made during this docs checkpoint.

Recommended next milestone:
- Vercel Preview env configuration with staging Supabase, or Member Status System planning.

## Milestone 14F Staging Owner Bootstrap Complete

Milestone 14F is complete. The staging Owner was created manually in staging Auth before execution, bootstrapped using the manual Owner bootstrap template pattern, and verified in staging. No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

Staging Owner:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Auth UUID: `e02a6d7a-0663-4a89-b558-9f57245f6361`.
- Email: `krsticmiroslav99+agm-staging-owner@gmail.com`.
- Username/profile slug: `staging_owner`.
- IGN: `Staging Owner`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_count = 1`.
- `owner_bootstrapped` audit log count: `1`.

Scope confirmation:
- No production project was touched.
- Production project ref `mzflfyxxkascrfpteexz` was not used.
- No Vercel Preview env vars were configured.
- No deployment was performed.
- No source code, SQL migrations, or new migrations were changed or created.
- No controlled staging test users had been created at the 14F checkpoint; they were created later in Milestone 14G.
- No commit was made during execution.

Recommended next milestone:
- Milestone 14G: staging controlled test users plus permission matrix setup planning/execution.

## Milestone 14E Staging Supabase Migration And Verification Complete

Milestone 14E is complete. Staging Supabase was created before this checkpoint, linked, migrated, and verified as a staging-only environment. No production Supabase project was touched, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

Staging Supabase:
- Project ref: `ckyihuxkioeibzpgwenc`.
- Project name: `Anteiku Guild Manager Staging`.
- Project URL: `https://ckyihuxkioeibzpgwenc.supabase.co`.
- Region: Central EU / Frankfurt.
- Same 9 migrations as production were applied and verified.
- Schema/RLS/seed verification passed.
- Permission catalog count is 10 and exactly matches `20260514000400_seed_core_data.sql`.
- Earlier "7 permissions" staging report was a partial summary mistake.
- `manage_permissions` is not seeded in the current migration set and remains a future/open permission question unless explicitly approved later.
- Staging Owner was not created during 14E; it was bootstrapped later in Milestone 14F.

Scope confirmation:
- No production project was touched.
- Production project ref `mzflfyxxkascrfpteexz` was not used for staging execution.
- No Vercel Preview env vars were configured.
- No deployment was performed.
- No source code, SQL migrations, or new migrations were changed or created.
- No Owner bootstrap was run.
- No commit was made.

Recommended next milestone at the time:
- Milestone 14F: staging Owner bootstrap planning. Completed later.

## Milestone 14D Staging And Preview Planning Docs Complete

Milestone 14D is complete as a documentation-only staging Supabase + Vercel Preview planning pass. No staging project was created, no Supabase CLI link or command was run, no Vercel env vars were changed, no deployment was performed, and no source or SQL files were changed.

Documented plan:
- Future staging must use a fresh Supabase project, separate from production.
- Staging should receive the same 9 migrations as production.
- Staging must use a separate Supabase URL, anon/publishable key, Auth users, Owner bootstrap, and fake/test data.
- Production data must not be copied to staging unless explicitly approved.
- Production Vercel env remains production-only.
- Vercel Preview env should point only to staging Supabase when staging exists:
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY`
- Preview env should remain unconfigured until staging is ready.
- No service role key, database password/URL, `sb_secret_*`, JWT secret, SMTP secret, or OAuth/provider secret belongs in frontend/Vercel env.
- Production Auth Site URL remains `https://anteiku-guild-manager.vercel.app`.
- Production redirect URLs should remain production-only.
- Preview wildcard redirects, if needed, belong only in staging Supabase.

Staging test plan:
- Owner.
- Approved Member.
- Admin with `view_audit_logs` but without `view_cp`.
- Admin with both `view_audit_logs` and `view_cp`.
- Wrong-guild Member.
- Pending user.

Deferred production tests moved to staging:
- Full GvG smoke test.
- CP audit redaction browser scenario.
- Permission denial flows.
- Wrong-guild access.
- Cleanup/archive experiments.

Recommended future phases at the time:
- Milestone 14E: create/link staging Supabase, dry-run/apply migrations, verify schema/RLS/seed. Completed later.
- Milestone 14F: staging Owner bootstrap planning.
- Later: configure Vercel Preview env with staging Supabase only and staging Auth URLs after bootstrap planning is approved.

## Milestone 14C AdminPanel Tabs Complete In Production

Milestone 14C is complete. The frontend-only AdminPanel organization refactor was implemented, build/source validated, committed/pushed to GitHub `main`, deployed by Vercel, and manually production-smoke validated at `https://anteiku-guild-manager.vercel.app`.

Implemented:
- Split the large AdminPanel into section components:
  - `src/components/admin/AdminTabs.jsx`
  - `src/components/admin/AdminApprovalsSection.jsx`
  - `src/components/admin/AdminMembersSection.jsx`
  - `src/components/admin/AdminCpSection.jsx`
  - `src/components/admin/AdminGvgSection.jsx`
  - `src/components/admin/AdminAuditSection.jsx`
  - `src/components/admin/AdminPermissionsSection.jsx`
  - `src/components/admin/AdminToolsSection.jsx`
- Kept `src/pages/AdminPanel.jsx` as the coordinator for auth/session context, current membership, permission-key loading, visible-tab calculation, active tab state, and action handlers.
- Added mobile-first horizontal admin tabs:
  - Approvals
  - Members
  - CP
  - GvG
  - Audit Logs
  - Permissions
  - Tools
- Added sticky dark/crimson tab styling in `src/styles/app.css`.
- Rendered only the active AdminPanel section.
- Lazy-loaded CP, Audit Logs, and GvG management sections when their tabs are opened instead of on initial AdminPanel render.

Build/source validation:
- `npm.cmd run build` passed.
- No SQL migration files changed.
- No source service behavior changes were made.
- New admin section components do not import services or call Supabase directly.
- Static source checks found no frontend direct `.from('member_cp')`, `.from('cp_snapshots')`, or `.from('audit_logs')` calls.
- Audit reads remain isolated through `src/services/adminAuditService.js` and `get_audit_logs`.
- CP reads/writes remain isolated through approved CP RPCs in `src/services/adminCpService.js`.
- GvG paths remain through existing `src/services/gvgService.js` safe reads/RPCs; no new GvG service calls were added.

Local browser/source-path validation:
- Owner and admin tab switching passed.
- Mobile `390px` tab UX passed.
- Lazy-load/network validation passed through local Kong logs:
  - CP tab used only `get_current_cp_roster` and `get_cp_leaderboard`.
  - Audit tab used only `get_audit_logs`.
  - GvG tab used safe `gvg_events` read only.
  - No direct `member_cp`, `cp_snapshots`, `audit_logs`, or unsafe `gvg_votes` writes were observed.
- No major console errors or tab-refactor bugs were found.

Production rollout validation:
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Owner login passed.
- AdminPanel opened.
- Admin tabs were visible.
- Owner switched Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- Audit Logs tab loaded.
- CP tab loaded.
- Mobile tab layout was usable.
- Member could not access AdminPanel.

Scope confirmation:
- No SQL migrations changed.
- No Supabase schema/RLS/RPC logic changed.
- No CP, GvG, audit, role/guild, or permission behavior changed.
- No source, SQL, Supabase, Vercel env, deployment, or commit action was performed during the final documentation checkpoint.

## Milestone 14B Vercel GitHub App Restriction Checkpoint Complete

Milestone 14B is complete as a verification and documentation checkpoint.

Completed:
- Recorded user-confirmed manual Vercel GitHub App restriction.
- Vercel GitHub App installation is limited to `Ultimate99/anteiku-guild-manager`.
- Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Production URL remains `https://anteiku-guild-manager.vercel.app`.
- Production app health was checked in the browser.
- Browser check loaded title `Anteiku Guild Manager`.
- No captured browser console errors were observed during this checkpoint.
- No Vercel env vars were changed.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No Supabase schema/RLS/RPC changes were made.
- No production commands were run.
- No deployment was performed.
- No commit was made.

Historical next options at the time:
- Staging Supabase + Vercel Preview environment setup, or controlled production test-member cleanup planning.

## Milestone 14A Production Hardening Policy Docs Complete

Milestone 14A is complete as a documentation-only production hardening and cleanup policy pass.

Completed:
- Documented manual Vercel GitHub App restriction checklist.
- Recorded that Vercel GitHub App restriction is recommended but was not executed.
- Documented controlled production test member policy.
- Recorded controlled test member remains in production:
  - Email: `krsticmiroslav99+m13b21144225@gmail.com`.
  - Username/profile slug: `m13bmember21056302`.
  - IGN: `M13B Member 21056302`.
  - Status: approved Member.
- Documented Preview/Staging policy:
  - Production env only on Production deployments.
  - Preview env should have no Supabase env vars until staging exists.
  - Future staging Supabase must be separate from production.
  - Preview deployments must not mutate production by default.
- Recorded deferred production smoke tests:
  - GvG production smoke was deferred to avoid persistent production GvG test data. Milestone 14H later covered full GvG smoke in staging.
  - CP redaction browser scenario was deferred due to missing production staff/data combination. Milestone 14H later covered the browser scenario in staging.
- Added launch operations guidance for approvals, audit monitoring, CP updates, GvG events, admin permissions, and production SQL safety.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No production commands were run.
- No Vercel settings were changed.
- No GitHub App settings were changed.
- No users were disabled, deleted, or suspended.
- No deployment was performed.
- No commit was made.

Recommended next milestone:
- Milestone 14B: manual Vercel GitHub App restriction, controlled test-member cleanup planning, or staging/preview setup planning only after explicit approval.

## Milestone 13B Production Deployment Complete

Milestone 13B Vercel setup, Supabase Auth URL configuration, and production smoke/security validation are complete.

Completed:
- Vercel project deployed from `Ultimate99/anteiku-guild-manager` on production branch `main`.
- Production URL: `https://anteiku-guild-manager.vercel.app`.
- Vercel framework preset: Vite.
- Vercel build command: `npm run build`.
- Vercel output directory: `dist`.
- Production Vercel env uses only browser-safe frontend variables:
  - `VITE_SUPABASE_URL`
  - `VITE_SUPABASE_ANON_KEY`
- No service role key, database password/URL, JWT secret, SMTP/OAuth secret, provider secret, or `sb_secret_*` key was configured in frontend/Vercel env.
- Supabase Auth Site URL is set to `https://anteiku-guild-manager.vercel.app`.
- Supabase Auth Redirect URL allow-list includes `https://anteiku-guild-manager.vercel.app`.
- Production app loads successfully.
- Owner login and AdminPanel access passed.
- Owner mobile AdminPanel validation passed.
- Audit Logs are readable/usable on desktop and mobile.
- CP Management is readable/usable on desktop and mobile.
- Controlled signup created a pending production user after email confirmation.
- Pending user was locked out of member/admin areas.
- Owner approved the controlled user as Member.
- Approved Member login passed.
- Approved Member cannot access AdminPanel.
- Approved Member does not see CP values.
- Member Home/Profile/GvG pages triggered no CP RPC/table calls in manual Network validation.
- Audit Logs Network validation observed `rpc/get_audit_logs` only for audit viewer reads.
- No direct `/rest/v1/audit_logs` calls were observed from Audit Logs actions.
- No CP RPC/table calls or audit write/update/delete/export calls were observed from Audit Logs actions.
- CP Management Network validation observed approved CP RPCs only.
- No direct `/rest/v1/member_cp` or `/rest/v1/cp_snapshots` calls were observed.
- No bugs were found.

Production controlled test member:
- Email: `krsticmiroslav99+m13b21144225@gmail.com`.
- Username/profile slug: `m13bmember21056302`.
- IGN: `M13B Member 21056302`.
- Status: approved Member.
- Note: this controlled test member remains in production unless a later cleanup/member-management action is explicitly approved.

Deferred / intentionally not tested in production:
- GvG production smoke was not tested to avoid persistent production GvG test data because no cleanup/delete flow is in scope.
- GvG was fully live-browser validated locally in Milestone 10, and production source/static path validation confirms approved RPCs/safe reads.
- CP redaction browser test was not tested in production because there is no current staff user/data combination with `view_audit_logs` but without `view_cp` and a fresh CP-sensitive audit entry.
- Backend CP metadata redaction was validated in Milestone 11A, and the audit viewer source uses only `get_audit_logs`.

Security note:
- Restrict the Vercel GitHub App installation to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.

Scope confirmation:
- No source logic changed.
- No React files changed.
- No SQL migrations changed.
- No Supabase schema/RLS/RPC changes were made.
- No Vercel env changes were made after final validation.
- No deployment rerun was performed during final validation review.
- No commit was made.

Recommended next milestone:
- Milestone 14 planning: choose the next production-safe feature or operational cleanup task, such as production test-member cleanup policy, staging/preview environment setup, reapply flow, suspended/left/rejected member management, weekly CP snapshot/growth report UI, or guild/subguild management.

## Milestone 13A Production Supabase Checkpoint

Milestone 13A production Supabase setup completed the database-side production checkpoint.

Completed:
- Fresh production Supabase project exists.
- Production project ref: `mzflfyxxkascrfpteexz`.
- Project name: `Anteiku Guild Manager Production`.
- Region: Central EU / Frankfurt.
- All 9 approved migrations were applied remotely.
- `npx.cmd supabase migration list` showed local and remote migration history matched.
- Production schema/RLS/seed verification passed.
- Protected tables, RLS, policies, RPCs, grants, indexes, and seed data were verified.
- Owner bootstrap was run manually using `supabase/templates/owner_bootstrap_TEMPLATE.sql`.
- Exactly one active Owner membership exists.
- Owner profile is approved.
- `owner_bootstrapped` audit log exists.

Owner bootstrap record:
- Owner Auth UUID: `a89d7b78-7a5d-4b53-86d2-59c918709d60`.
- Owner email: `krsticmiroslav99@gmail.com`.
- Owner username/profile slug: `ultimatesrb`.
- Owner IGN: `UltimateSRB`.
- Initial guild: `Anteiku`.
- Initial guild ID: `00000000-0000-0000-0000-000000000101`.
- Role: `owner`.
- Membership status: `active`.
- Primary membership: `true`.
- `active_owner_membership_count = 1`.
- `owner_active_primary_membership_count = 1`.
- `owner_bootstrap_audit_count = 1`.

Scope confirmation at the time of the 13A checkpoint:
- No source logic changed during the checkpoint documentation pass.
- No React files changed.
- No SQL migrations changed.
- No SQL migrations were created.
- No Supabase commands were run during this documentation checkpoint.
- Owner bootstrap was not rerun.
- Vercel had not been configured yet.
- Production deployment had not happened yet.
- No commit was made.

Local tooling note:
- Supabase CLI was installed locally as dev tooling during Milestone 13A.
- The CLI tooling/package changes were committed before Milestone 13B planning/execution.

Historical next milestone:
- Milestone 13B: Vercel setup + Supabase Auth URL configuration + production smoke/security validation. This was completed later.

## Milestone 12 Production Readiness Docs Complete

Milestone 12 was implemented as a documentation-only production readiness pass.

Created/updated:
- `docs/PRODUCTION_CHECKLIST.md`
- `docs/DEPLOYMENT.md`
- `docs/SETUP.md`
- `.env.example`
- `README.md`
- `docs/TESTING.md`
- `docs/CHANGELOG.md`
- supporting stale-doc refreshes for database/RLS/roles docs
- ai_agents handoff files

Scope confirmation:
- No source logic changed.
- No React files changed.
- No Supabase migrations changed.
- No SQL migrations were created.
- No production Supabase project was linked.
- No production commands were run.
- No deployment was performed.
- No dependencies were added.
- No commit was made.

Milestone 12 documents:
- Fresh production Supabase project required.
- Production Auth Site URL and redirect URLs must be configured.
- Vercel env must include only browser-safe Vite variables: `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend/Vercel public env.
- Owner bootstrap remains manual-only using a real production Auth user id.
- Production migration order is documented.
- `supabase db reset` is forbidden on production.
- `supabase/tests/local_validation_anteiku.sql` is local/disposable only and must not run on production because it inserts fake auth users and test data.
- `supabase/config.toml` references missing `./seed.sql`; core seed data currently comes from migration `20260514000400_seed_core_data.sql`, so `db push --include-seed` must not be used until that hazard is resolved.

Recommended next milestone:
- Milestone 13 should be production Supabase + Vercel setup only after explicit user approval.

## Milestone 11B Frontend Audit Log Viewer Complete

Milestone 11B frontend audit log viewer has been implemented, build-validated, source/security-path validated, and manually live-browser validated.

Implemented:
- New isolated audit service `src/services/adminAuditService.js`.
- Read-only AdminPanel Audit Logs section.
- Audit reads use only `public.get_audit_logs(...)`.
- Filters for action, safe/simple guild scope, date from/to, and limit.
- Default limit is 50 and UI max is 100.
- Load older uses `p_before` from the oldest loaded row.
- Loading, error, empty, and not-authorized states are present.
- Audit cards show action label, timestamp, actor, optional target, guild/global display, entity table/id, safe metadata summary, and CP redaction notice.
- Metadata rendering is whitelist-based and does not dump raw metadata JSON.

Security:
- No SQL migrations were changed.
- `get_audit_logs` was not changed.
- No direct frontend `audit_logs` table read was added.
- No audit write/update/delete/export UI was added.
- No CP table/RPC calls were added by audit viewing.
- No CP unredaction or CP value reconstruction was added.
- CP-sensitive redacted rows show `Sensitive CP metadata hidden.`
- Member and pending users do not get audit logs through the UI; Admins without `view_audit_logs` get a clean not-authorized state.

Validation:
- `npm.cmd run build` passed.
- Source check confirmed `src/services/adminAuditService.js` calls only `get_audit_logs`.
- Source check found no frontend `supabase.from('audit_logs')`.
- Source check found no CP RPC/table calls in the audit viewer path.
- Source check found no audit write/update/delete UI in the audit viewer path.
- Manual live browser validation passed with 23 PASS / 0 FAIL / 0 incomplete.
- Owner loaded audit logs, used filters, and used Load Older successfully.
- Leader/Vice and Admin with `view_audit_logs` saw scoped logs only.
- Admin without `view_audit_logs`, normal Member, and pending user could not access audit logs.
- CP-sensitive metadata was hidden for users without `view_cp` and shown only when the backend returned it for authorized `view_cp` users.
- Network validation after clearing initial AdminPanel load showed only `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- Mobile viewport validation passed.

## Milestone 11A Audit Log Read Hardening Validated

Backend audit-log read hardening has been implemented and locally validated. Milestone 11B frontend work has since been implemented and manually live-browser validated.

Implemented:
- New migration `supabase/migrations/20260515000300_audit_log_read_hardening.sql`.
- New safe audit reader RPC `public.get_audit_logs(...)`.
- Direct non-Owner `audit_logs` SELECT is restricted so scoped staff cannot bypass SQL-side redaction.
- CP-sensitive audit metadata is redacted for audit viewers who do not also have scoped `view_cp`.
- Owner can still read global audit logs through the RPC.
- Leader/Vice can read scoped guild audit logs through the RPC.
- Admin can read scoped audit logs only with `view_audit_logs`.

Validation:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 11A audit hardening checks passed: 14 PASS / 0 FAIL / 0 SKIP.
- Admin with `view_audit_logs` but without `view_cp` receives redacted CP metadata.
- Admin with `view_audit_logs` and `view_cp` receives scoped CP metadata.
- Member, pending user, and Admin without `view_audit_logs` are blocked.
- Direct `audit_logs` SELECT as non-Owner returns no rows.
- `authenticated` has no EXECUTE privilege on `private.write_audit_log`.
- Audit spoof insert remains blocked.

Validation note:
- A direct attempted execution of `private.write_audit_log` as `authenticated` caused a local Postgres container segfault instead of a clean permission error. The validation was adjusted to verify the revoked EXECUTE grant with `has_function_privilege`, which proves the direct call is not granted without crashing local Postgres.

## Milestone 10 GvG Browser Validation Passed

GvG event management and member voting persistence have been implemented, build-validated, and live browser validated.

Backend/RLS inspection passed before frontend work:
- `create_gvg_event` exists and enforces Owner/global or scoped `manage_gvg`.
- `set_gvg_event_status` exists and enforces scoped event management.
- `submit_gvg_vote` exists, validates active event scope, and upserts votes.
- `get_gvg_results` exists and restricts absence reasons to authorized staff.
- `gvg_votes_event_profile_uidx` enforces one vote row per event/profile.
- Member own-vote reads are RLS-protected.
- Staff result/reason access is RLS/RPC-protected.

Implemented:
- New isolated GvG service: `src/services/gvgService.js`.
- Member GvG voting UI in `src/pages/Gvg.jsx`.
- AdminPanel GvG management/results section.
- Event creation, open voting, close voting, present/absent counts, and absence reason review.

Security:
- Member votes use only `submit_gvg_vote`.
- Admin event writes use `create_gvg_event` and `set_gvg_event_status`.
- Staff result reads use `get_gvg_results`.
- No CP logic was changed.
- No direct `gvg_votes` writes were added.

Validation:
- `npm.cmd run build` passed.
- Corrected live browser validation passed.
- Owner created a draft GvG event, opened voting, verified active status, and closed voting after member/staff checks.
- Same-guild approved Member saw the active event, voted Present, refreshed successfully, switched to Absent with reason, refreshed successfully, then switched back to Present.
- Read-only SQL confirmed `vote_rows = 1`, final `vote_status = present`, and `absence_reason = null`.
- Authorized staff saw present/absent counts and absence reasons.
- Normal Member could not see other users' absence reasons.
- Admin without `manage_gvg` could not manage events.
- Wrong-guild Member could not see/vote for the guild-specific event.
- Out-of-scope Leader/Vice/Admin could not manage the event.
- Closed event rejected vote changes.
- After clearing Network following initial AdminPanel load, GvG actions used only GvG RPCs/safe reads.
- No CP RPC/table calls were triggered by GvG actions.
- No direct frontend insert/update/upsert/delete calls to `gvg_votes` or `gvg_events` were observed.

## Milestone 9 Permission Management Validation Passed

Manual browser validation passed for Admin permission checkbox management.

Validated:
- Permission Management section appears for authorized Owner/Leader users.
- Empty state appears when no active Admin memberships exist.
- After promoting a member to Admin, that Admin appears in Permission Management.
- Permission checkboxes load from `permission_catalog`.
- Owner can grant/revoke Admin permissions.
- Owner can grant/revoke `view_cp` and `update_cp`.
- Leader can manage allowed non-CP Admin permissions inside assigned guild scope.
- Leader cannot toggle `view_cp` / `update_cp`.
- CP permissions remain Owner-only.
- Admin users do not get Permission Management UI.
- Member users do not get Admin tab.
- Network writes used only `grant_admin_permission` / `revoke_admin_permission`.
- No direct `admin_permissions` writes were found.
- No CP data/RPC calls occurred during permission-management actions.
- No GvG logic was touched.

## Milestone 9 Permission Management Implementation Complete

Admin permission checkbox management has been implemented and build-validated.

Implemented:
- New isolated permission service: `src/services/adminPermissionService.js`.
- Permission Management section in AdminPanel.
- Permission targets are active approved Admin memberships only.
- Permission catalog is used as the source of permission labels/descriptions.
- Writes use only `grant_admin_permission` and `revoke_admin_permission`.
- Owner can manage all Admin permissions.
- Leader/Vice can manage non-CP Admin permissions inside assigned guild scope.
- CP permission checkboxes are disabled for Leader/Vice with Owner-only messaging.
- Admin users cannot see Permission Management UI in v1.

Security:
- No direct `admin_permissions`, `guild_memberships`, or `profiles` writes were added.
- No CP data or CP RPC calls were added by permission management.
- No GvG logic was changed.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## Milestone 8 Frontend CP Validation Passed

Manual browser validation passed for Admin-only CP management and leaderboard.

Validated:
- Owner could see CP Management section.
- Owner could load CP roster.
- Missing CP displayed as "Not entered".
- Owner updated member CP successfully.
- CP roster refreshed after update.
- CP leaderboard displayed correctly.
- Invalid CP inputs were blocked.
- Normal Member could not see Admin tab or CP UI.
- CP did not appear on Dashboard/Profile/member-facing pages.
- Member Network tab showed no CP RPC/table calls.
- Owner Network tab used only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
- No direct `member_cp` or `cp_snapshots` calls were found.
- No GvG logic was touched.

Local testing note:
- After local DB reset, stale browser auth caused a `profiles_id_fkey` registration error.
- Clearing localStorage/sessionStorage fixed it.
- This was local stale session state, not a migration/security issue.

## Milestone 8 Frontend CP Implementation Complete

Admin-only CP management and CP leaderboard UI has been implemented and build-validated.

Implemented:
- New isolated CP service: `src/services/adminCpService.js`.
- AdminPanel CP section visible only to CP-view-authorized users.
- CP roster loads through `get_current_cp_roster`.
- CP leaderboard loads through `get_cp_leaderboard`.
- CP updates use `update_member_cp`.
- Missing CP displays as `Not entered`.
- CP input starts empty when CP is missing.
- CP update controls are visible only to Owner/Leader/Vice/Admin with `update_cp`.

Security:
- CP state is local to AdminPanel CP section and `adminCpService.js`.
- No direct `member_cp` or `cp_snapshots` reads/writes were added.
- CP is not shown on Dashboard, Profile, member-facing pages, or normal member roster cards.
- No GvG logic was changed.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

## Milestone 8 Backend CP Hardening Validation Passed

Local validation passed for Milestone 8 backend CP hardening.

Validated:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- CP update for pending/rejected/suspended profiles is blocked.
- CP update for approved active profile works.
- Admin with `update_cp` cannot update CP for non-approved profiles.
- `get_current_cp_roster` includes approved active members with missing CP as `null`.
- Members still cannot read CP.
- Admin without `view_cp` still cannot read CP.
- Direct `member_cp` / `cp_snapshots` access remains blocked.
- CP update audit log works.
- No GvG logic changed.

## Milestone 8 Backend CP Hardening Implemented

Backend CP hardening has been implemented and is pending local validation.

Implemented:
- New migration `supabase/migrations/20260515000200_cp_rpc_hardening.sql`.
- `update_member_cp` now explicitly requires the target profile to exist and have `approval_status = 'approved'`.
- `update_member_cp` still requires an active primary membership and `private.can_update_cp`.
- `get_current_cp_roster` now starts from active approved memberships/profiles.
- CP roster now includes active approved members with no CP row.
- Missing CP returns `null`, not `0`.
- CP roster joins `member_cp` by both `profile_id` and `guild_id`.

Unchanged:
- No frontend CP UI was implemented.
- No GvG logic was changed.
- No direct CP table policies were added.
- CP access remains RPC-only.

Validation:
- Local Supabase reset and validation script rerun are pending.

## Milestone 7 Frontend Validation Passed

Manual browser validation passed for Admin member guild + role management UI.

Validated:
- Owner changed member role `member -> admin -> member`.
- `owner` role option was not visible.
- Owner transferred member from Anteiku:Re to Anteiku.
- Transfer warning appeared before confirm.
- Transfer reset member role to `member`.
- Member could sign in after transfer.
- Member showed new guild and member role.
- Normal Member still had no Admin tab.
- Leader permissions work correctly inside assigned guild scope.
- Leader does not have Owner/global powers.
- Owner-only guild transfer remains hidden from Leader.
- Network writes used `assign_member_role` and `transfer_member_guild`.
- No CP/GvG table or RPC calls were found.

## Milestone 7 Frontend Implementation Complete

Admin member guild + role management UI has been implemented on top of the locally validated backend RPCs.

Implemented:
- Member role-change controls in Admin member cards.
- Owner role assignment is not exposed.
- Owner can choose only `member`, `admin`, `vice`, and `leader`.
- Leader/Vice can choose only `member` and `admin`.
- Admin with `manage_roles` can choose only `member` and `admin`.
- Admin without `manage_roles` has no role-change UI.
- Owner-only member guild transfer UI.
- Transfer target comes from a safe active guild options read.
- Transfer UI warns: "Moving guild resets this member's role to Member."
- Roster refresh runs after successful role or guild changes.

Validation:
- `npm.cmd run build` passed.
- Manual browser validation is pending.

Security:
- Writes use only `assign_member_role` and `transfer_member_guild`.
- No direct `profiles`, `guild_memberships`, or `admin_permissions` writes were added.
- No CP/GvG access was added.

## Milestone 7 Backend Validation Passed

Milestone 7 backend SQL/RPC support for role hardening and Owner-only guild transfer is implemented and locally validated.

Validated results:
- `npx.cmd supabase db reset` passed.
- `supabase/tests/local_validation_anteiku.sql` passed.
- Milestone 7 role assignment tests passed.
- Milestone 7 guild transfer tests passed.
- Owner can assign `member`, `admin`, `vice`, and `leader`.
- Owner cannot assign `owner` through normal app RPC.
- Leader/Vice can assign `member` and `admin` only.
- Admin with `manage_roles` can assign `member` and `admin` only.
- Admin/Leader/Vice/Member cannot transfer guilds.
- Owner-only guild transfer works.
- Transfer resets role to `member`.
- Old membership becomes `left` and is not deleted.
- New membership becomes active primary.
- Exactly one active primary membership remains.
- Role-change and transfer audit logs are written.
- No CP/GvG logic was changed.

## Current Milestone

Milestone 21E Rank Badge / Profile Border production rollout is complete. The safe own-rank summary RPC and Profile/Dashboard badge UI are live in production. Recommended next step: Milestone 22A Character Icons / Avatar Picker planning, unless the user prioritizes another member prestige/polish pass.

Current CP privacy rule: members can see their own CP through safe backend/RPC flow, can see rank order through `get_member_cp_rankings`, and can receive their own rank/tier summary through `get_my_cp_rank_summary`, but exact CP values remain hidden from member leaderboard/rank-summary APIs and UI. Members must not see other members' CP values, CP snapshots, CP history, or private CP metadata. Members must not directly select or update `member_cp` and must not directly read `cp_snapshots`.

## Current Status

The app is a React + Vite frontend backed by local Supabase migrations/RLS/RPCs. Milestones 10, 11A, and 11B are complete and validated. Milestone 12 is complete as a documentation-only production readiness pass.

Current capabilities include local Supabase auth/session restore, registration through `register_profile`, pending/rejected/suspended gates, approval/rejection queue, own IGN editing, admin member profile management, role/guild management through RPCs, Admin permission checkbox management, protected CP management, CP Update Window / Member CP Self-Submit, member-safe rank-only CP Ranking, production-live Profile/Dashboard rank badge UI, permission-protected AdminPanel CP Ranking, GvG event management and voting, and read-only audit log viewing through `get_audit_logs`.

Production Supabase is set up through migrations and Owner bootstrap. Vercel deployment is live at `https://anteiku-guild-manager.vercel.app`, production Auth Site URL/redirect URL setup is complete, and production browser/network smoke validation has passed with documented deferred items for production GvG data creation and CP redaction browser coverage.

Production hardening policy now documents Vercel GitHub App restriction, controlled test-member retention, Preview/Staging separation, deferred production smoke-test strategy, and launch operations safety. The Vercel GitHub App restriction has since been manually completed and recorded.

Milestone 14C reorganized AdminPanel into mobile-friendly tabs and section components. The refactor is frontend-only and behavior-preserving; CP, Audit Logs, and GvG management sections lazy-load when their tabs are opened. Production rollout validation passed after the Vercel deployment.

Milestone 14D recorded the staging/preview plan for future non-production validation. Milestone 14E created/linked the staging Supabase project, applied the same 9 migrations as production, and verified staging schema/RLS/seed. Milestone 14F bootstrapped and verified the staging Owner. Milestone 14G created and verified controlled staging users and permissions. Milestone 14H validated CP audit redaction and GvG smoke in staging. Milestone 15A implemented and locally validated backend Member Status support. Milestone 15B implemented the frontend UI/access gating. Milestone 15D applied the 15A migration to staging and browser-validated the 15B frontend against staging users. Milestone 15E applied the 15A migration to production, deployed the frontend, and passed production smoke validation. Vercel Preview env remains unchanged.

## Implemented

- Mobile-first frontend shell.
- Placeholder auth, pending, dashboard, profile, GvG, and admin pages.
- Documentation structure.
- Original abstract guild mark.
- Supabase migrations for profiles, guilds, memberships, permissions, protected CP, GvG, audit logs, helper functions, RLS, RPCs, and seed data.
- Local validation script for CP privacy, role scoping, GvG vote integrity, approval/reapply behavior, and audit spoof denial.
- Local Supabase auth/session provider.
- Signup/signin/signout UI.
- Registration flow through `register_profile` RPC.
- Pending/rejected/suspended/approved frontend gating.
- Manual pending status refresh.
- Local Supabase environment badge.
- Manual Milestone 3 local browser auth validation.
- Manual local Owner bootstrap validation for `test1@local.dev`.
- Frontend approval queue for pending/reapply registration requests.
- Approval/rejection service using existing RPCs only.
- Frontend role option limits: Admin with `approve_members` can approve Member only; Leader/Vice can approve Member/Admin; Owner can approve Member/Admin/Vice/Leader. No frontend Owner option.
- Manual Milestone 4 browser approval/rejection validation.
- Member profile edit mode for own IGN only.
- `update_my_profile` service wrapper for safe own-profile RPC updates.
- Manual Milestone 5 browser profile-edit validation.
- Admin active approved member roster.
- Admin member IGN edit using `admin_update_member_ign`.
- Admin username/profile slug reset using `admin_reset_profile_slug`.
- Guild filter and search for safe member roster data.
- Manual Milestone 6 browser member-management validation.
- Hardened normal app role assignment to block assigning `owner`.
- Owner-only member guild transfer RPC.
- Local validation script section for Milestone 7 role/guild backend behavior.
- Admin permission checkbox management.
- Admin-only CP management and leaderboard.
- GvG event management and member voting persistence.
- Manual Milestone 10 browser GvG validation.
- Safe audit log reader RPC with CP metadata redaction.
- Read-only AdminPanel audit log viewer using `get_audit_logs`.
- Mobile-friendly AdminPanel tabs and section components.

## Not Implemented

- Suspended/left/rejected member management
- Avatar editing
- Username/profile slug editing for normal users
- Reapply UI
- Weekly CP snapshot/growth report UI
- Guild/subguild management UI

## Validation Status

Milestone 11B frontend audit log viewer validation passed:

- `npm.cmd run build` passed.
- Source/security-path validation passed.
- Manual live browser validation passed.
- Network validation after clearing initial AdminPanel load showed `get_audit_logs` for audit viewer reads.
- No direct `audit_logs` table calls, CP RPC/table calls, or audit write/update/delete/export calls were observed from audit viewer actions.
- No bugs or incomplete tests were reported.

Local validation completed on 2026-05-14:

- `npm.cmd install`: passed.
- `npm.cmd run build`: passed.
- `package-lock.json` was generated.
- `dist/` was generated.
- `npm.cmd audit`: completed with 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`.

Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade. Keep this as a known development-only Vite dev-server audit issue for now.

Milestone 2 local Supabase validation passed:

- `npx.cmd supabase db reset`: migrations apply locally.
- Local validation script result: 29 PASS / 0 FAIL / 0 SKIP.
- Setup failures: 0.
- Security failures: 0.

Validated behavior includes CP direct table denial, CP RPC permission checks, leader/admin/member scope rules, GvG vote upsert behavior, direct GvG write denial, approval/reapply audit flow, and audit spoof denial.

Important security lesson: validation caught private helper parameter shadowing that caused CP/RPC permission leakage. The helper migration was fixed by renaming helper parameters to `p_*` names and validation now confirms CP privacy and role-scoped access.

Milestone 3 local browser validation passed after the `AuthContext` loading fix:

- Local Supabase badge displays correctly.
- Register flow works and creates a pending user.
- Sign in and sign out work.
- Pending users are locked to the Pending page.
- Pending status refresh works.
- Hard refresh restores the session and returns the pending user to the Pending page.
- Signed-out refresh shows the Auth page.
- The stuck Loading state no longer reproduces.
- DevTools Network inspection found no protected CP table/RPC calls: no `member_cp`, no `cp_snapshots`, no `get_current_cp_roster`, no `get_cp_leaderboard`, and no `get_cp_growth_report`.

Resolved frontend validation bug: an async `onAuthStateChange` callback could wedge session restore/loading state. The fix keeps the auth callback synchronous, ignores duplicate `INITIAL_SESSION`, defers profile loading safely, and always clears state/loading on sign out.

Milestone 4 frontend build validation:

- `npm.cmd run build`: passed.
- No SQL migrations, Owner bootstrap files, Supabase commands, package files, or dependencies were changed.
- No frontend references to protected CP table/RPC identifiers were added.
- Approval writes are limited to `approve_registration` and `reject_registration`.
- Approved app shell initially had no visible Sign out button; fixed by adding a Sign out control to the `AppShell` header.
- `npm.cmd run build` passed after the Sign out fix.

Milestone 4 manual browser validation passed:

- Local Owner bootstrap was applied manually outside migrations.
- Owner account `test1@local.dev` became approved Owner in Anteiku.
- Owner could access the app shell and Admin tab.
- Sign out button is visible in the approved app shell and works.
- Approval queue loaded pending users.
- Owner approved `test2` as Member.
- `test2` could sign in and access the app shell as a member.
- `test2` had role `member` and guild `Anteiku:Re`.
- Admin tab was hidden for normal member.
- Owner rejected `test3` with reason.
- `test3` could sign in but was locked to `RejectedStatus`.
- Rejected user did not see app shell/member/admin screens.
- No CP UI or CP data was exposed during testing.

Milestone 5 frontend build validation:

- Existing RPC confirmed: `public.update_my_profile(p_ign text, p_avatar_key text default null)`.
- RPC uses `auth.uid()` and updates only the authenticated user's `ign`, `avatar_key`, and `updated_at`.
- Profile page edit mode updates IGN only.
- Username, profile slug, guild, role, approval status, and avatar/profile icon remain display-only.
- No direct profile or membership table update was added.
- No frontend references to protected CP table/RPC identifiers were added.
- `npm.cmd run build`: passed.

Milestone 5 manual browser validation passed:

- Owner could edit own IGN successfully.
- Member could edit own IGN successfully.
- Changed IGN displayed correctly after save.
- Empty/invalid IGN validation works or was checked as implemented.
- Cancel keeps/restores original IGN.
- Username/profile slug remained locked and not editable.
- Guild, role, and approval status remained display-only.
- Avatar editing was not implemented.
- Profile update used `update_my_profile` RPC only.
- No direct `profiles` or `guild_memberships` updates were added.
- No protected CP table/RPC calls were added or observed.
- `npm.cmd run build`: passed.

Milestone 6 frontend build validation:

- Existing RPC confirmed: `public.admin_update_member_ign(p_profile_id uuid, p_ign text)`.
- Existing RPC confirmed: `public.admin_reset_profile_slug(p_profile_id uuid, p_new_slug text)`.
- `admin_update_member_ign` uses `auth.uid()`, checks `private.can_edit_member_ign`, updates target IGN, and writes audit metadata.
- `admin_reset_profile_slug` uses `auth.uid()`, normalizes and validates slug format, checks `private.can_reset_profile_slug`, updates `username` and `profile_slug` together, and writes audit metadata.
- Member roster reads only active memberships with approved profiles.
- Member-management writes use only the two admin profile RPCs.
- No direct profile, membership, or permission table writes were added.
- No frontend references to protected CP table/RPC identifiers were added.
- `npm.cmd run build`: passed.

Milestone 6 manual browser validation passed:

- Owner could view active approved member roster.
- Roster excluded pending/rejected/left/suspended users.
- Owner edited `test2` member IGN successfully.
- `test2` saw updated IGN after sign in.
- Owner reset `test2` username/profile_slug successfully.
- `username` and `profile_slug` stayed equal and lowercase.
- `test2` could still sign in by email.
- `test2` remained Member in Anteiku:Re.
- Admin tab remained hidden for normal member.
- No CP table/RPC calls were found in Network tab.

New product requirement recorded for future planning: admins/staff should be able to change a member's guild and role, but this must not be added as an unsafe quick patch.

Milestone 7 backend implementation status:

- Created migration `supabase/migrations/20260515000100_member_guild_role_management.sql`.
- Updated `private.can_assign_role` behavior in the new migration.
- Updated `public.assign_member_role` behavior in the new migration.
- Added `private.can_transfer_member_guild`.
- Added `public.transfer_member_guild`.
- Added local validation-script checks for role assignment hardening and Owner-only transfer behavior.
- No CP table, CP RPC, GvG table, or GvG RPC changes were made.
- No frontend files were changed.
- Local database reset/validation has not been run yet.
## Milestone 18D AdminPanel Full Translation

Milestone 18D is implemented and production-deployed through Milestone 18F as a frontend display-only translation pass.

- Added full AdminPanel translation coverage for EN/FR/DE dictionaries.
- AdminPanel shell, tab content, Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, admin empty/loading states, errors, and success messages now render through i18n display labels.
- Permission catalog display labels/descriptions are translated through UI fallbacks while database permission keys remain unchanged.
- Audit action and metadata display labels are translated while raw audit values, usernames, IGN, guild names, CP values, event titles, absence reasons, and user notes remain untranslated.
- No SQL, Supabase migrations, Supabase/RLS/RPC behavior, services behavior, auth behavior, CP/GvG/audit access logic, role/guild/permission/member-status behavior, dependencies, or data mutation was included.
- `npm.cmd run build` passed.
- Static source checks found no `supabase/` or `src/services/` changes and no new direct protected table calls in frontend source.
- Authenticated staging browser validation passed in Milestone 18E.
- Production rollout and smoke validation passed in Milestone 18F.
