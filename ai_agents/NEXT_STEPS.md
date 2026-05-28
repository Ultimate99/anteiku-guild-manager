# Next Steps

## Current Recommendation

PWA install support, the PWA update-available banner, and the offline notice banner are complete and deployed.

Recommended next step:
- Do a quick manual PWA/offline UX check on target devices if desired:
  - Desktop Chrome/Edge install app option.
  - Android Chrome Add to Home Screen / Install app.
  - iOS Safari Add to Home Screen name/icon.
  - Standalone launch opens the production app.
  - After a future deployment, open an already-controlled app session and verify the update banner appears.
  - `Later` dismisses the banner for the current session.
  - `Update App` activates the waiting worker and reloads once after `controllerchange`.
  - Chrome DevTools Network Offline shows `You are offline`.
  - Returning to Online hides the offline notice.
- Continue with the next user-prioritized milestone after the install UX check.

Recorded offline notice status:
- Commit `2bbd24a feat: add offline notice banner` is deployed.
- The app uses `navigator.onLine` plus `online` / `offline` browser events.
- The banner appears only while offline and automatically hides when online returns.
- The banner is UI-only: no queued actions, no full offline mode, and no service worker/cache behavior changes.
- Supabase/API/Auth/RPC/CP/admin/GvG/3v3 data remains uncached.

Recorded PWA update-banner status:
- Commit `bb570a6 feat: add PWA update available banner` is deployed.
- The banner detects a waiting service worker and shows `New version available` / `Update now to get the latest app changes.`
- `Update App` posts `{ type: "SKIP_WAITING" }` to the waiting worker.
- `Later` dismisses through session-only storage.
- No forced auto-reload occurs without user action.
- Service worker no longer auto-runs `skipWaiting()` during install.
- Supabase/API/Auth/RPC/CP/GvG/3v3/admin/analytics data is still not cached.

Recorded Milestone 26A/26B status:
- Added dependency-free PWA support with `public/manifest.webmanifest`, `public/sw.js`, PWA icons under `public/icons/`, iOS meta tags, and production-only service worker registration.
- Icons were derived from the existing approved `public/anteiku-mark.svg` mark.
- Service worker caches only same-origin app shell/static assets/icons/manifest/approved mark.
- Service worker ignores cross-origin requests, so Supabase Auth/RPC/API responses are not cached.
- `npm.cmd run build` passed.
- Commit `1d8b5a5 feat: add PWA install support` was pushed to `main`.
- Production serves the manifest, icons, service worker, and updated bundle.
- Browser-native install prompt / standalone launch were not manually verified from the terminal.

## Previous Recommendation - Milestone 25D

Milestone 25D 3v3 Team Finder production rollout is complete.

Recommended next step:
- Choose the next user-prioritized milestone, likely 3v3 UX polish, a 3v3 operating/cleanup procedure, or another production-safe frontend pass.
- Before assuming the controlled production 3v3 test team is still live or disbanded, verify the cleanup status; the manual smoke note did not specify which state was chosen.
- Keep 3v3 Combined CP separate from protected normal CP. Do not add normal CP reads to 3v3.

Recorded Milestone 25D status:
- Production received `20260528000100_three_v_three_team_finder.sql` after a clean dry-run showing exactly that one pending migration.
- Production DB verification passed for 3v3 table existence, RLS enabled, no broad direct client grants, RPC existence, direct normal-CP read protection, and active Owner count `1`.
- Commit `4c9da98 feat: add 3v3 team finder UI` was pushed to `main` and production serves the 3v3 UI bundle.
- Manual controlled production smoke passed: Member A created a team, Member B requested to join, Member A approved, Member B filled the first empty slot.
- Discord username and public 3v3 Combined CP were required/displayed.
- Normal protected CP was not visible and normal Members had no AdminPanel access.
- No console/UI blocker was found.

## Previous Recommendation - Milestone 25B

Milestone 25B 3v3 Team Finder backend is implemented and locally validated only.

Recommended next step:
- Milestone 25C: implement the frontend `3v3` page locally with Find Team, Create Team, and My Requests on top of the 25B RPCs.

Important rollout gates:
- Do not deploy any 3v3 frontend to staging or production until `20260528000100_three_v_three_team_finder.sql` is applied and verified on that target database.
- Keep 3v3 Combined CP separate from protected normal account CP.
- Future frontend must use only the 3v3 RPCs and must not read `member_cp`, `cp_snapshots`, CP Analytics, CP roster, or CP ranking data.
- Future staging rollout should dry-run and apply `20260528000100_three_v_three_team_finder.sql` before authenticated 3v3 browser validation.

Recorded Milestone 25B status:
- Added `three_v_three_player_profiles`, `three_v_three_teams`, `three_v_three_team_members`, and `three_v_three_join_requests`.
- Added RPCs for Discord username, public 3v3 Combined CP, team create/browse/status, join request lifecycle, owner approval/decline/removal/disband, and close/reopen.
- Local validation passed: `npx.cmd supabase db reset`; `supabase/tests/local_validation_anteiku.sql`; Milestone 25B result 45 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was skipped because no frontend source changed.
- No staging, production, Vercel, deploy, or commit action was performed.

## Previous Recommendation - Analytics UI Polish

Analytics UI polish is live in production.

Recommended next options:
- Plan the next user-prioritized milestone, likely a production-safe Weekly Growth operating procedure, additional Analytics insights, or another frontend UX pass.
- Keep production Start New CP Week / baseline capture behind explicit approval because it intentionally creates `cp_snapshot_batches` and `cp_snapshot_entries` rows.
- Keep Analytics staff-only and permission-aware; CP Analytics and Weekly Growth must remain backend-gated by scoped `view_cp`.
- Relink Supabase CLI deliberately before staging/local Supabase commands because it is currently linked to production `mzflfyxxkascrfpteexz`.

Recorded Analytics UI polish:
- Commit `1db36d3 style: polish admin analytics UI` was pushed to `main` and deployed.
- Frontend-only polish tightened the Analytics scope selector, sub-tab bar, stat cards, Members grouping, CP/GvG cards, Weekly Growth table/card layout, and Attention cards.
- No SQL migrations, Supabase/RLS/RPC changes, analytics service behavior changes, Supabase commands, Vercel env changes, or production data mutations were performed.
- `npm.cmd run build` passed.
- Production Owner smoke passed for Analytics, scope switching, all sub-tabs, Weekly Growth live growth, baseline preservation, and no captured console errors.
- Start New CP Week was not clicked.
- CP privacy remains `view_cp` gated.

Recorded Weekly Growth baseline scope fix:
- Commit `0130ac6 fix: preserve analytics baseline across guild scope` is deployed.
- Production received `20260526000300_live_cp_growth_baseline_scope.sql`.
- Scope switching now preserves the selected baseline when applicable.
- Added safe RPC overload `get_admin_live_cp_growth(p_guild_id uuid, p_baseline_batch_id uuid)`.
- Owner can use a Global baseline while filtering rows to a guild scope.
- Production smoke confirmed Global and Anteiku both show `安定区×Ulti` growth `+5,002` from the same baseline.
- Start New CP Week was not clicked and no new production snapshot/baseline was created.
- CP privacy remains `view_cp` gated; Members and non-authorized users cannot access CP/growth data.

Recorded Live CP Growth status:
- Production received `20260526000200_live_cp_growth.sql` after a clean dry-run showing exactly that one pending migration.
- Live Growth compares current `member_cp.cp_value` to the latest baseline snapshot for the selected Analytics scope.
- Reset day is Sunday; starting a new CP week captures baseline values only and does not reset player CP.
- Commit `426a720 feat: add live cp growth analytics` was pushed to `main`.
- `npm.cmd run build` passed and production serves the Live CP Growth UI bundle.
- Owner production read-only smoke passed for Global and Anteiku Weekly Growth views.
- Production Start New CP Week mutation smoke was not performed by design.
- Source validation confirmed Analytics UI/service paths do not direct-read protected CP/snapshot tables.

## Previous Recommendation - Milestone 24E AdminPanel Analytics

Milestone 24E AdminPanel Analytics production rollout is complete.

Recorded 24E status:
- Production received `20260526000100_admin_analytics_foundation.sql` after a clean dry-run showing exactly that one pending migration.
- Production DB verification passed for `cp_snapshot_batches`, `cp_snapshot_entries`, RLS, no direct client grants, Analytics RPC existence/grants, direct protected-read denial, and active Owner count `1`.
- Commit `cc2a32b feat: add admin analytics UI` was pushed to `main` and production serves the Analytics UI bundle.
- Owner production smoke passed for AdminPanel -> Analytics, Overview, Members, CP, GvG, Weekly Growth, and Attention.
- Weekly Growth snapshot capture mutation smoke was not performed by design.
- Source validation confirmed Analytics frontend uses analytics RPCs only and no direct CP/snapshot table reads.

## Previous Recommendation - Milestone 24C Admin Analytics UI

Recorded 24C status:
- Added AdminPanel `Analytics` tab with Overview, Members, CP, GvG, Weekly Growth, and Attention sub-tabs.
- Added `src/services/adminAnalyticsService.js` using only the 24B analytics RPCs.
- Added `src/components/admin/AdminAnalyticsSection.jsx`.
- `npm.cmd run build` passed.
- Source validation passed with no SQL/migration/RLS/RPC changes and no direct analytics table reads.
- Local authenticated browser validation is pending because the local Vite dev server was not running during the checkpoint.

## Previous Recommendation - Profile Mobile + Inline Edit Polish

Profile mobile + inline edit polish is complete in production.

Recommended next options:
- No immediate Profile follow-up is required.
- Continue with the next user-prioritized frontend polish or planned milestone.
- Keep any public/other-player profile viewing in a separately planned backend-safe milestone.

## Previous Recommendation - Own Profile Polish

Own Profile polish is implemented locally and build/browser validated.

Recommended next options:
- Review the local Profile layout in-browser, especially the `Your CP` private/self copy and mobile spacing.
- If approved, commit the frontend-only Profile polish and optionally deploy through the normal main/Vercel flow.
- Keep public/other-player profile viewing out of this milestone; plan a backend-safe public profile RPC separately if needed.

## Previous Recommendation - Frontend Command Center Polish

Frontend Command Center Polish is complete in production.

Recommended next options:
- Optional next frontend milestone: profile/member identity polish, Owner Tools confirmation/preview polish, or another user-prioritized UX pass.
- Keep backend/security-impacting work in separate planned milestones with staging/production gates.

## Previous Recommendation - Owner Cosmetics Grant Tool

Owner Cosmetics grant tool is complete in production.

Recorded status:
- Commit `d97fc9f feat: add owner cosmetics grant tool` was pushed to `main`.
- Commit `24287cb fix: hide free cosmetics from owner grant dropdown` was pushed to `main`.
- Vercel production bundle contains the Owner Cosmetics UI.
- Owner Cosmetics dropdown now filters by backend `unlock_type` and shows only `manual` / `admin_grant` cosmetics.
- Free/default and auto-unlocked types (`free`, `rank`, `event`, `gvg`, `founder`) are excluded.
- Local browser validation passed for Owner Tools visibility, dropdown rendering, required-field validation, non-owner Admin hidden state, and Member AdminPanel denial.
- Production app load smoke passed with no captured console errors.
- Authenticated production smoke passed for Owner visibility, dropdown filtering, empty username/profile slug validation, empty cosmetic validation, non-owner Admin hidden state, Member AdminPanel denial, no console errors, no unexpected network calls, and no CP/GvG/audit/ranking/member-status regression.
- Controlled production grant smoke passed after explicit approval: a locked avatar/frame grant by exact profile slug / username succeeded, and the granted member could equip it.

Recommended next options:
- No immediate Owner Cosmetics follow-up is required.
- Continue to use Owner Cosmetics only for intentional Owner-approved grants.
- Keep all grant operations on the existing `admin_grant_cosmetic_by_slug(...)` RPC path.

## Previous Recommendation - Cosmetics Frame Unlock Hotfix

Cosmetics frame unlock hotfix is applied in production.

Recorded hotfix status:
- Updated `scripts/sync-cosmetics-catalog.mjs` so only `TXK_Arena*` and `TXK_KOF*` frames default to `manual`; all other frames default to `free`.
- Preserved premium avatar sync behavior by keeping `premium` avatar keys manual.
- Added and applied production migration `20260525220522_cosmetics_frame_unlock_hotfix.sql`.
- Production dry-run showed exactly that one migration pending.
- Read-only production catalog verification found 7 Arena manual frames, 3 KOF manual frames, 10 other free frames, and 0 other locked frames.
- Production app load smoke passed with no captured console errors.
- Authenticated Profile cosmetics browser smoke is pending until a production session is available.

Recommended next options:
- Have the user sign in to production and verify Profile -> Customize -> Frames shows only Arena/KOF locked and C-series frames unlocked.
- Commit the hotfix script, migration, and docs after user approval.
- Relink Supabase CLI deliberately before any staging/local Supabase work; it is currently linked to production `mzflfyxxkascrfpteexz`.

## Previous Recommendation - Milestone 22F

Milestone 22F Cosmetics Catalog Sync Script is implemented locally.

Recorded 22F tooling status:
- Added `scripts/sync-cosmetics-catalog.mjs`.
- Added `npm.cmd run cosmetics:sync`.
- Dry-run passed and printed SQL preview for 54 avatars and 10 frames.
- Normal run generated `supabase/migrations/20260525193210_cosmetics_catalog_sync.sql`.
- `npm.cmd run build` passed.
- No Supabase commands, staging/prod commands, deploys, uploads, Storage, arbitrary URLs, runtime source behavior changes, or RLS/RPC behavior changes were included.

Recommended next options:
- Review generated catalog sync migrations before rollout because catalog `unlock_type` is the runtime authority.
- Decide whether to keep this generated migration as the next catalog sync artifact, regenerate after adding new assets, or add optional override/config support before staging.
- If approved later, run normal staging dry-run/apply/verification before production.
- Relink Supabase CLI deliberately before any staging/local Supabase work; it is currently linked to production `mzflfyxxkascrfpteexz`.

## Previous Recommendation - Leaderboard Podium Polish

Leaderboard podium polish is live in production.

Recorded leaderboard podium polish status:
- Commit deployed: `3f65052 style: tune leaderboard podium layout`.
- Desktop podium visually orders `#2 | #1 | #3`.
- Mobile stacks `#1`, `#2`, `#3`.
- Rank #1 has stronger gold/center styling and a larger avatar/frame.
- Rank #2 has silver styling; rank #3 has bronze styling.
- Build passed and production app load smoke passed with no captured console errors.
- This was frontend/style-only; ranking logic, backend/RPC behavior, SQL, and CP privacy are unchanged.

Recommended next options:
- Authenticated production Member/Owner smoke for the final leaderboard polish if the user wants it recorded.
- Milestone 23E: optional AdminPanel Grant Cosmetic UI planning/implementation.
- Premium cosmetic seed planning if future avatar/frame rewards should be added to production.
- Cosmetics picker copy polish for future locked premium avatars, if needed.
- Relink Supabase CLI deliberately before any staging/local Supabase work; it is currently linked to production `mzflfyxxkascrfpteexz`.

## Previous Recommendation - Milestone 23D

Milestone 23D Premium Cosmetics production rollout is complete. Production now has `20260525000300_premium_cosmetics_grant_helper.sql` applied and verified.

Recorded Milestone 23D production status:
- Production dry-run showed exactly one pending migration: `20260525000300_premium_cosmetics_grant_helper.sql`.
- Production migration push applied that migration only.
- Remote migration list confirmed `20260525000300` applied.
- Production verification passed for `admin_grant_cosmetic_by_slug(...)` existence, avatar unlock fields in `get_my_cosmetics()`, free-or-unlocked enforcement markers in `equip_my_avatar(...)`, locked/manual avatar rejection markers in `update_my_profile(...)`, all current frames free, direct cosmetic write grants blocked, normal Member grant denial, and active Owner count `1`.
- Production app load smoke passed with no captured console errors.
- Locked/manual runtime denial and grant/equip success were authenticated-validated in staging during Milestone 23C because production currently has no active manual cosmetics and production mutation smoke was not approved.

Recommended next options:
- Milestone 23E: optional AdminPanel Grant Cosmetic UI planning/implementation.
- Premium cosmetic seed planning if future avatar/frame rewards should be added to production.
- Cosmetics picker copy polish for future locked premium avatars, if needed.
- Relink Supabase CLI deliberately before any staging/local Supabase work; it is currently linked to production `mzflfyxxkascrfpteexz`.

## Previous Recommendation - Milestone 23B/23C

Milestone 23B Premium Cosmetics backend was implemented and locally validated, then staged in Milestone 23C.

Recorded Milestone 23B local status:
- New migration: `20260525000300_premium_cosmetics_grant_helper.sql`.
- Existing deployed cosmetics migration `20260525000100_cosmetics_catalog_unlocks.sql` was not edited.
- All currently existing frame rows are updated to `unlock_type = 'free'`.
- Future premium avatars and frames should use `unlock_type = 'manual'`.
- `equip_my_avatar(...)` now requires free-or-unlocked semantics, matching frames.
- `update_my_profile(p_ign, p_avatar_key)` now rejects locked manual avatars.
- `get_my_cosmetics()` now reports avatar `unlock_type`, `is_unlocked`, and `is_equipped`.
- `admin_grant_cosmetic_by_slug(...)` grants by exact username/profile slug using existing member-management authority and writes the existing cosmetic grant audit path.
- Local validation passed: `npx.cmd supabase db reset`; `supabase/tests/local_validation_anteiku.sql`; Milestone 23B result 18 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because 23B changed no frontend source.

Recommended next options:
- Milestone 23C: staging dry-run/apply/DB validation for `20260525000300_premium_cosmetics_grant_helper.sql`.
- Milestone 23D: production rollout after staging passes.
- Milestone 23E: optional AdminPanel grant UI or clearer premium locked-state copy in the cosmetics picker.

## Previous Recommendation - Milestone 22E

Milestone 22E cosmetics production rollout is complete. Production now has `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified, and the cosmetics picker/assets are deployed at `https://anteiku-guild-manager.vercel.app`.

Recorded Milestone 22E production status:
- Production dry-run showed exactly one pending migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Production migration push applied that migration only.
- Production DB verification passed for cosmetics tables, RLS, catalog counts, exact repo asset-path match, RPC existence/grants, direct-write denial, active Owner count `1`, and `update_my_profile(...)` avatar hardening.
- `wip/cosmetics-backend-assets` was merged into `main` and pushed.
- Vercel deployed the cosmetics frontend/assets.
- Production smoke was user-confirmed as passing.
- Owner `ultimatesrb` equipped avatar `1147_head` and free frame `TXK_C1121_lock_FREE`; read-only verification confirmed persistence.
- Controlled production Member `m13bmember21056302` remains approved/active but did not receive an equipped cosmetics row during this smoke.

Recommended next options:
- Optional controlled Member cosmetics smoke in production if the user wants member-account persistence explicitly recorded.
- Cosmetics reward/admin-grant UI planning, if future reward workflows are desired.
- Cosmetic asset normalization review if future frame PNGs have inconsistent transparent padding.
- Relink Supabase CLI deliberately before any staging/local Supabase work; it is currently linked to production `mzflfyxxkascrfpteexz`.

## Previous Recommendation - Milestone 22B

Recorded Milestone 22B backend status:
- New local migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Added `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
- Seeded 54 free avatar keys from `public/cosmetics/avatars/*.png`.
- Seeded 10 frame keys from `public/cosmetics/frames/*.png`.
- Default avatar: `1079_head`.
- Default frame: `TXK_frame_reOpen_EN_FREE`.
- `_FREE` cosmetic keys are mapped to `unlock_type = 'free'`; catalog `unlock_type` is the runtime source of truth.
- Non-`_FREE` frames use `unlock_type = 'manual'` and require an unlock row.
- Added RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
- Hardened `update_my_profile(p_ign, p_avatar_key)` so arbitrary avatar keys are rejected; valid active catalog avatar keys still work.
- Equip RPCs use `auth.uid()` only and accept no target profile id.
- Frame equip requires a free frame or caller-owned unlock row.
- Admin grants use existing member-management authority for the target member's active primary guild.
- Local validation passed: `npx.cmd supabase db reset`; `supabase/tests/local_validation_anteiku.sql` through Docker `psql`; Milestone 22B result 19 PASS / 0 FAIL / 0 SKIP.
- Catalog asset-path verification passed: 64 rows checked, 0 missing files, 0 unlock mapping problems.
- `npm.cmd run build` was not run because 22B changed only backend migrations/tests/docs.

Rollout:
- Staging and production both have `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified through Milestones 22D and 22E.
- Future new target environments must apply and verify this migration before cosmetics UI is deployed there.
- Static assets are present under `public/cosmetics/avatars/` and `public/cosmetics/frames/`; the catalog seed paths match those files.
- Supabase CLI remains linked to production after Milestone 22E; relink deliberately before any future remote Supabase command.

Recorded Milestone 21E production status:
- Production project `mzflfyxxkascrfpteexz` received only `20260524000400_cp_rank_badge_summary.sql` after a clean dry-run.
- Production DB verification passed for `get_my_cp_rank_summary()`, authenticated execute grant, no anon execute grant, safe return shape, direct CP table denial, and active Owner count `1`.
- Commit `e99bec0 feat: add rank badge UI` was pushed and deployed to production.
- Owner Dashboard rank badge rendered; Owner AdminPanel still opened; existing CP tab and CP Ranking tab still rendered.
- Controlled production Member Dashboard/Profile showed the safe default/no-rank badge state and no Admin navigation.
- EN/FR/DE rank badge labels worked.
- No CP values, growth/history/snapshot data, updated-by metadata, profile ids, usernames from the rank RPC, or private rank metadata were exposed by the badge.
- No production CP/member data was mutated.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

Recorded Milestone 21D staging status:
- Staging project `ckyihuxkioeibzpgwenc` received only `20260524000400_cp_rank_badge_summary.sql`.
- Staging DB verification passed for RPC existence, safe return shape, grants, direct CP table denial, and active Owner count `1`.
- `staging_member` showed `Global Rank #1` / `Rank 1`.
- `staging_wrongguild` showed a safe unranked/default state.
- `staging_pending` remained locked.
- EN/FR/DE labels and mobile layout passed.
- `.env.local` was restored to local Supabase after validation.

Recorded Milestone 21C frontend status:
- Added `src/services/cpRankBadgeService.js`.
- Added `src/components/RankBadge.jsx`.
- Profile now shows a rank-based profile border and badge in the profile header.
- Dashboard now shows a compact rank badge in the member summary.
- Added EN/FR/DE `rankBadge` labels.
- Added compact dark/crimson rank badge/profile-border styles for all 21B visual keys.
- Rank badge data uses only `get_my_cp_rank_summary()`.
- Profile/Dashboard do not use member/admin leaderboard RPCs, admin CP roster/leaderboard RPCs, or direct CP tables for badge data.
- `npm.cmd run build` passed.
- Authenticated browser validation passed in staging through Milestone 21D and production smoke passed through Milestone 21E.

Rollout boundary:
- Resolved for staging and production. For any future new target environment, apply and verify `20260524000400_cp_rank_badge_summary.sql` before deploying the rank badge frontend.

Recorded Milestone 21B backend status:
- New local migration: `20260524000400_cp_rank_badge_summary.sql`.
- Added `get_my_cp_rank_summary()`.
- Return shape is limited to `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
- Rank tier keys are stable SQL keys for frontend translation later: `rank_one`, `rank_two`, `rank_three`, `elite_five`, `top_ten`, `high_rank`, `ranked_member`, and `unranked`.
- Visual keys are `rank_1`, `rank_2`, `rank_3`, `elite_5`, `top_10`, `high_rank`, `ranked_member`, and `unranked`.
- The RPC uses `auth.uid()` and accepts no profile id parameter.
- It does not return CP values, timestamps, growth/history/snapshot data, updated-by metadata, usernames, profile ids, other-member data, or private metadata.
- `inactive` and `on_break` users return the `unranked` default state; hard-blocked users remain denied by existing active-membership gates.
- Direct `member_cp` and `cp_snapshots` access remains blocked.
- Local validation passed: `npx.cmd supabase db reset`; `supabase/tests/local_validation_anteiku.sql` through Docker `psql`; Milestone 21B result 15 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because 21B changed only database migration/tests/docs and no frontend code.

Rollout boundary:
- Resolved for staging and production through Milestones 21D and 21E.

Recorded Milestone 20F production status:
- Production project `mzflfyxxkascrfpteexz` received only `20260524000300_cp_rankings.sql`.
- Production DB verification passed for `get_member_cp_rankings`, `get_admin_cp_rankings`, authenticated execute grants, member-safe return shape, Owner admin CP fields, non-Owner global admin denial, direct CP table denial, and active Owner count 1.
- Commit `7ccf8c9 feat: add CP ranking UI` was pushed and deployed to production.
- Member `Ranking` page loaded My Guild and Global rankings with rank + IGN only.
- Member Global rankings showed guild labels and no CP values/private CP fields.
- Owner AdminPanel `CP` tab still loaded roster/window controls.
- Owner AdminPanel separate `CP Ranking` tab loaded Guild and Global rankings with CP values.
- No console errors were captured on checked production member/admin paths.
- No production CP/member data was mutated.
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; relink deliberately before future staging/local Supabase commands.

Recorded Milestone 20E staging status:
- Staging project `ckyihuxkioeibzpgwenc` received only `20260524000300_cp_rankings.sql`.
- Production project `mzflfyxxkascrfpteexz` was not touched.
- Staging DB verification passed for ranking RPC existence, authenticated execute grants, member-safe return shape, Owner/admin CP fields, non-Owner global denial, and active Owner count 1.
- `staging_member` browser validation passed for My Guild and Global member rankings with no CP values or private CP fields.
- Owner browser validation passed for AdminPanel CP roster/window controls and the separate `CP Ranking` tab with Guild/Global admin rankings and CP values.
- `staging_admin_noperms` saw only Tools and no CP/CP Ranking access.
- Pending ranking access was denied through API validation.
- `.env.local` was restored to local Supabase after validation.

Recorded Milestone 20D frontend status:
- AdminPanel CP leaderboard now uses `get_admin_cp_rankings`.
- Added a separate AdminPanel `CP Ranking` tab with Guild / Global leaderboard tabs.
- Guild tab uses the selected CP guild scope and shows CP values through the permission-checked admin RPC.
- Global tab is shown only for Owner in the frontend; backend Owner-only authorization remains the real gate.
- Admin leaderboard rows show rank, IGN, username, guild, CP value, and last updated.
- Added top-rank, Elite 5, and Top 10 rank decoration to admin rows.
- Added EN/FR/DE i18n labels and compact mobile styling.
- Existing CP roster, manual CP update, and CP Update Window controls were preserved.
- Member-facing CP Ranking page behavior was not changed.
- `npm.cmd run build` passed.
- Static checks found no direct `member_cp`, `cp_snapshots`, or `cp_update_windows` table calls.

Rollout boundary:
- This older 20D boundary was resolved in Milestone 20E/20F; staging and production now have `20260524000300_cp_rankings.sql` applied and verified.

Recorded Milestone 20C frontend status:
- Added `src/services/cpLeaderboardService.js`.
- Added `src/pages/Leaderboard.jsx`.
- Added member nav/routing for CP Ranking.
- Added EN/FR/DE i18n labels and compact mobile styling.
- Member leaderboard uses only `get_member_cp_rankings(p_scope)`.
- It does not call `get_admin_cp_rankings`, `get_cp_leaderboard`, `get_current_cp_roster`, or direct CP tables.
- My Guild tab shows rank and IGN.
- Global tab shows rank, IGN, and guild label.
- Current user row highlights when returned.
- CP values, CP growth/history/snapshots, updated timestamps, profile ids, usernames, admin notes, and private metadata are not rendered.
- `npm.cmd run build` passed.
- Local browser smoke covered the unauthenticated shell only; authenticated leaderboard validation awaits staging DB migration and staging users.

Rollout boundary:
- This older 20C boundary was resolved in Milestone 20E/20F; staging and production now have `20260524000300_cp_rankings.sql` applied and verified.

Recorded Milestone 20B backend status:
- New local migration: `20260524000300_cp_rankings.sql`.
- Added `get_member_cp_rankings(p_scope text default 'guild')`.
- Added `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
- Member rankings support `guild` and `global` scopes and return rank order only.
- Member ranking responses include only `rank`, `ign`, `guild_name`, `guild_slug`, and `is_current_user`.
- Member ranking responses intentionally do not include CP values, profile ids, usernames, timestamps, snapshots, growth, history, or audit metadata.
- Admin guild rankings return CP values only through existing scoped `view_cp` authority.
- Admin global rankings are Owner-only in v1.
- Ranking rows include approved active memberships with roster status `active`, `trial`, or `pending_transfer`.
- Ranking rows exclude `inactive`, `on_break`, `suspended`, `left`, `kicked`, pending memberships, and rejected memberships.
- Ranks use deterministic `row_number()` ordering by `cp_value desc`, then IGN/profile tie-breaker.
- Direct `member_cp` and `cp_snapshots` access remains blocked for normal members.
- Local validation passed: `npx.cmd supabase db reset`; `supabase/tests/local_validation_anteiku.sql` through Docker `psql`; Milestone 20B result 14 PASS / 0 FAIL / 0 SKIP.
- `npm.cmd run build` was not run because 20B changed only database migration/tests/docs and no frontend code.

Rollout boundary:
- This older Milestone 20B boundary was resolved in Milestone 20E/20F; staging and production now have `20260524000300_cp_rankings.sql` applied and verified.

Recorded Milestone 19E production status:
- CP Update Window / Member CP Self-Submit is live in production after production DB migration verification, frontend deployment, and read-only Owner/member smoke validation.

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
- Milestone 20C member leaderboard frontend planning/implementation, then Milestone 20D/20E staging migration rollout and staging validation.

Later milestone options:
- Optional controlled production CP mutation smoke with explicit approval.
- Weekly CP Snapshot/Growth Reports planning after CP Leaderboard work.
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
