# Code Index

- `src/main.jsx`: React root.
- `src/App.jsx`: Local page state, auth/approval gates, password recovery gate, and roster hard-block gate routing.
- `src/layouts/AppShell.jsx`: Header, content frame, sign-out action, and bottom navigation container.
- `src/components/AppNav.jsx`: Mobile-first page navigation.
- `src/components/StatusBadge.jsx`: Small status label component.
- `src/components/RankBadge.jsx`: Member-safe rank badge component for Profile/Dashboard visuals using safe rank summary fields only.
- `src/components/CosmeticPreview.jsx`: Member avatar/frame preview component using approved static cosmetics asset paths.
- `src/config/supabaseClient.js`: Supabase env check and client placeholder.
- `src/context/AuthContext.jsx`: Local Supabase auth/session provider, password recovery state, and safe viewer state.
- `src/context/LanguageContext.jsx`: Frontend-only language provider, `useLanguage()` hook, `t(key, params?)`, and `agm_language` persistence.
- `src/hooks/useAuth.js`: Hook for reading auth context.
- `src/i18n/index.js`: Lightweight i18n registry, language options, fallback translation lookup, and interpolation helper.
- `src/i18n/en.js`: English UI translation dictionary.
- `src/i18n/fr.js`: French UI translation dictionary.
- `src/i18n/de.js`: German UI translation dictionary.
- `src/services/authService.js`: Supabase auth wrappers for session, signin, signup, password reset/update, and signout.
- `src/services/profileService.js`: Safe own profile/membership/guild loading including `roster_status`, registration RPC call, and own IGN update RPC wrapper.
- `src/services/guildService.js`: Safe core guild loading for registration.
- `src/services/adminApprovalService.js`: RLS-safe approval queue reads, own approval permission lookup, and approval/rejection RPC wrappers.
- `src/services/adminMemberService.js`: RLS-safe approved primary member roster reads, member-management permission helpers, roster status helpers, roster status RPC wrapper, and admin member IGN/slug/role/guild RPC wrappers.
- `src/services/cpWindowService.js`: RPC-only CP Update Window service for own CP, member self-submit, selected-guild staff window status, and staff window open/close.
- `src/services/cpRankBadgeService.js`: RPC-only own CP rank summary wrapper for `get_my_cp_rank_summary`.
- `src/services/cosmeticsService.js`: RPC-only own cosmetics wrapper for `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`; normalizes asset paths to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- `src/data/guilds.js`: Core guild list.
- `src/data/navigation.js`: Navigation items.
- `src/pages/LoginRegister.jsx`: Local Supabase signin/signup, forgot-password, and registration UI.
- `src/pages/SetNewPassword.jsx`: Required password recovery screen shown before normal navigation during recovery sessions.
- `src/pages/PendingApproval.jsx`: Pending approval gate with manual refresh.
- `src/pages/RejectedStatus.jsx`: Rejected account gate; reapply is planned later.
- `src/pages/SuspendedStatus.jsx`: Suspended account gate.
- `src/pages/RosterRestrictedStatus.jsx`: Roster lifecycle hard-block gate for suspended/left/kicked members.
- `src/pages/Dashboard.jsx`: Approved-user safe guild dashboard with roster status display, compact own rank badge, and no CP values.
- `src/pages/Profile.jsx`: Safe profile display with own roster status, rank badge/profile border from safe own-rank RPC, own cosmetics picker through safe cosmetics RPCs, own CP through safe RPCs only, and own IGN edit mode for approved users.
- `src/pages/Gvg.jsx`: GvG voting UI with roster-status UX gating for inactive/on_break and hard-blocked statuses.
- `src/pages/AdminPanel.jsx`: Restricted AdminPanel coordinator for admin permission loading, visible tab calculation, active tab state, lazy section loading, and section action handlers.
- `src/components/admin/AdminTabs.jsx`: Mobile-first AdminPanel tab bar.
- `src/components/admin/AdminApprovalsSection.jsx`: Registration approval/rejection queue section.
- `src/components/admin/AdminMembersSection.jsx`: Approved primary member management section with compact roster rows, roster status badges/filter, and expandable Manage controls for status/IGN/username/role/guild actions.
- `src/components/admin/AdminCpSection.jsx`: Admin-only CP roster/update/leaderboard section plus CP Update Window controls.
- `src/components/admin/AdminGvgSection.jsx`: GvG event management/results section.
- `src/components/admin/AdminAuditSection.jsx`: Read-only audit log viewer section.
- `src/components/admin/AdminPermissionsSection.jsx`: Admin permission checkbox management section.
- `src/components/admin/AdminToolsSection.jsx`: Planned/future admin tools section.
- `src/styles/app.css`: Plain mobile-first dark styling.

## Milestone 22E Cosmetics Production Rollout

Production status:
- Cosmetics backend/assets/frontend are live in production.
- Production migration: `20260525000100_cosmetics_catalog_unlocks.sql`.
- Production catalog verification passed: 54 avatars, 10 frames, and 64 exact repo asset-path matches.
- Vercel serves the cosmetics picker and static assets.
- Owner equip persistence was verified in production.

Security:
- Frontend cosmetics paths use only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
- No frontend admin grant UI exists.
- No direct cosmetics table writes, arbitrary URLs, Supabase Storage, or upload paths are part of v1.
- Free frames can be equipped by players; manual frames require backend unlock state.

## Milestone 23B Premium Cosmetics Backend

Status:
- Backend/database-only implementation complete; staging validated in Milestone 23C and production applied/verified in Milestone 23D.
- New migration `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`.
- Existing deployed migration `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql` was not edited.

- `supabase/migrations/20260525000300_premium_cosmetics_grant_helper.sql`
  - Updates the current 10 frame keys to `unlock_type = 'free'`.
  - Updates `get_my_cosmetics()` so avatar rows include unlock type, unlock state, and equipped state.
  - Updates `equip_my_avatar(text)` to require free-or-unlocked avatar semantics.
  - Updates `update_my_profile(text, text)` so manual avatar keys require an unlock row.
  - Adds `admin_grant_cosmetic_by_slug(text, text, text)` for exact username/profile-slug grants.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 23B coverage for free current frames, premium manual avatar/frame denial, grant-by-slug, unlocked equip, update-profile hardening, invalid input denial, member/admin denial, and audit rows.

## Milestone 22C Frontend Cosmetics Picker

Status:
- Implemented, staging-validated, polished, and deployed through Milestone 22E.

- `src/services/cosmeticsService.js`
  - Calls only `get_my_cosmetics`, `equip_my_avatar`, and `equip_my_frame`.
  - Does not direct-read `cosmetic_catalog`, `profile_cosmetic_unlocks`, or `profile_equipped_cosmetics`.
  - Does not expose `admin_grant_cosmetic`.
  - Filters rendered asset paths to `/cosmetics/avatars/` and `/cosmetics/frames/`.
- `src/components/CosmeticPreview.jsx`
  - Renders equipped avatar and optional frame as static app assets.
- `src/pages/Profile.jsx`
  - Adds member-facing avatar and frame picker.
  - Shows equipped/unlocked/locked states.
  - Disables locked frames.
  - Refreshes profile state after avatar equip for `profiles.avatar_key` compatibility.
- `src/styles/app.css`
  - Adds mobile-first cosmetics picker and preview styles.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add Profile cosmetics labels.

## Milestone 22B Cosmetics Backend

Status:
- Implemented, locally validated, applied to staging in Milestone 22D, and applied to production in Milestone 22E.

- `supabase/migrations/20260525000100_cosmetics_catalog_unlocks.sql`
  - Adds `cosmetic_catalog`, `profile_cosmetic_unlocks`, and `profile_equipped_cosmetics`.
  - Seeds 54 actual avatar asset rows and 10 actual frame asset rows from `public/cosmetics/`.
  - Uses `1079_head` as the default avatar and `TXK_frame_reOpen_EN_FREE` as the default frame.
  - Maps non-`_FREE` frames to `unlock_type = 'manual'`.
  - Enforces the `_FREE` naming convention by requiring `_FREE` catalog keys to use `unlock_type = 'free'`; runtime equip checks still use catalog `unlock_type` as source of truth.
  - Adds RLS policies for active catalog reads and caller-owned unlock/equipped reads.
  - Revokes direct client writes to cosmetics tables.
  - Adds RPCs `get_available_avatars()`, `get_my_cosmetics()`, `equip_my_avatar(text)`, `equip_my_frame(text)`, and `admin_grant_cosmetic(uuid, text, text)`.
  - Hardens `update_my_profile(p_ign, p_avatar_key)` so non-empty avatar keys must match active catalog avatars.
  - Writes cosmetic audit actions: `cosmetic_avatar_equipped`, `cosmetic_frame_equipped`, and `cosmetic_granted`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 22B validation for seeded catalog, RLS, safe member reads, valid/invalid equips, locked-frame grant/equip flow, self-grant denial, no target profile equip argument, legacy avatar hardening, direct-write denial, other-user unlock privacy, and audit rows.

## Milestone 21B Rank Badge Summary Backend

Production status:
- Applied and verified in staging through Milestone 21D and production through Milestone 21E.
- Production migration: `20260524000400_cp_rank_badge_summary.sql`.
- Production smoke confirmed Profile/Dashboard rank badge visuals and no CP value exposure from the badge.

- `supabase/migrations/20260524000400_cp_rank_badge_summary.sql`
  - Adds member-safe own-rank summary RPC `get_my_cp_rank_summary()`.
  - Returns only `global_rank`, `guild_rank`, `rank_tier`, `visual_key`, and `is_ranked`.
  - Uses `auth.uid()` and accepts no target profile id parameter.
  - Does not return CP values, timestamps, growth/history/snapshot data, usernames, profile ids, other-member data, or private metadata.
  - Uses the same eligible row set as member-safe CP rankings and returns `unranked` for excluded active statuses such as `inactive` and `on_break`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 21B validation for rank tiers, unranked/no-CP behavior, inactive exclusion, hard-block denial, private-field absence, no other-user parameter, and direct CP table denial.

## Milestone 21C Profile/Dashboard Rank Badge Frontend

Production status:
- Deployed to production through Milestone 21E with commit `e99bec0 feat: add rank badge UI`.
- Production controlled Member smoke confirmed Dashboard/Profile safe no-rank/default badge state, no Admin navigation, and EN/FR/DE rank badge labels.
- Production Owner smoke confirmed Dashboard badge, AdminPanel access, existing CP tab, and CP Ranking tab.

- `src/services/cpRankBadgeService.js`
  - Adds `loadMyCpRankSummary()` for `get_my_cp_rank_summary`.
  - Guards against unexpected CP/private fields in the rank summary response.
  - Does not call member/admin leaderboard RPCs, CP roster/leaderboard RPCs, or direct CP tables.
- `src/components/RankBadge.jsx`
  - Renders stable rank tier/visual keys as translated badge text and serious compact markers.
  - Shows global rank when ranked, or a no-rank/load-error state without CP values.
- `src/pages/Profile.jsx`
  - Adds rank-based profile border and badge to the profile header.
- `src/pages/Dashboard.jsx`
  - Adds compact rank badge to the member summary.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add `rankBadge` labels.
- `src/styles/app.css`
  - Adds rank badge, dashboard badge, and profile-border visual variants for all 21B visual keys.

## Milestone 20B CP Leaderboard Backend

Production status:
- Applied and verified in staging through Milestone 20E and production through Milestone 20F.
- Production migration: `20260524000300_cp_rankings.sql`.
- Production smoke confirmed member rank-only leaderboard and Owner-only/global admin CP values through the permission-checked RPC.

- `supabase/migrations/20260524000300_cp_rankings.sql`
  - Adds member-safe CP ranking RPC `get_member_cp_rankings(p_scope text default 'guild')`.
  - Adds admin CP ranking RPC `get_admin_cp_rankings(p_guild_id uuid default null, p_scope text default 'guild')`.
  - Adds ranking support indexes on `member_cp`.
  - Member RPC returns rank order only and intentionally omits CP values, profile ids, usernames, updated timestamps, snapshots, growth, history, and audit metadata.
  - Admin guild RPC path requires scoped `view_cp`; admin global scope is Owner-only in v1.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 20B validation for member-safe response shape, rank ordering, roster inclusion/exclusion, current-user highlighting, admin permission checks, Owner-only global admin rankings, and direct CP table denial.

## Milestone 20C Member CP Leaderboard Frontend

Production status:
- Deployed to production through Milestone 20F with commit `7ccf8c9 feat: add CP ranking UI`.
- Production Member smoke confirmed My Guild and Global rankings show rank + IGN only, with guild labels on Global and no CP/private fields.

- `src/services/cpLeaderboardService.js`
  - Adds `loadMemberCpRankings(scope)` for the member-safe `get_member_cp_rankings` RPC.
  - Normalizes scope to `guild` or `global`.
  - Guards against unexpected CP/private fields in member ranking responses.
  - Does not call admin CP ranking, CP roster, CP leaderboard, or direct CP tables.
- `src/pages/Leaderboard.jsx`
  - Adds member-facing CP Ranking page with My Guild and Global tabs.
  - Shows rank, IGN, optional guild label on Global, and current-user highlight.
  - Does not render CP values, CP history, growth, snapshots, profile ids, usernames, timestamps, or private metadata.
- `src/data/navigation.js` and `src/App.jsx`
  - Add the member Leaderboard/Ranking navigation item and route.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add member leaderboard labels.
- `src/styles/app.css`
  - Adds compact leaderboard tabs, rows, rank markers, current-user highlight, and top-rank/Elite 5/Top 10 decoration.

## Milestone 20D AdminPanel CP Leaderboard Upgrade

Production status:
- Deployed to production through Milestone 20F with commit `7ccf8c9 feat: add CP ranking UI`.
- Production Owner smoke confirmed the separate AdminPanel `CP Ranking` tab loads Guild and Global rankings with CP values while the existing `CP` tab still renders roster/window controls.

- `src/services/adminCpService.js`
  - Adds normalized `loadAdminCpRankings({ guildId, scope })` mapping for `get_admin_cp_rankings`.
  - Keeps existing CP roster and manual CP update wrappers unchanged.
- `src/pages/AdminPanel.jsx`
  - Loads AdminPanel CP leaderboard data through `get_admin_cp_rankings`.
  - Tracks Guild/Global leaderboard scope and clean leaderboard errors.
  - Keeps Global admin leaderboard frontend visibility Owner-only; backend RPC authorization remains authoritative.
- `src/components/admin/AdminCpLeaderboardSection.jsx`
  - Renders the separate AdminPanel `CP Ranking` tab content.
  - Shows Guild / Global tabs and compact decorated admin ranking rows with CP values for authorized staff.
- `src/components/admin/AdminCpSection.jsx`
  - Preserves CP roster, manual CP update, and CP Update Window controls.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add admin CP leaderboard scope, rank, guild, last-updated, empty, and permission/error labels.
- `src/styles/app.css`
  - Adds compact AdminPanel CP ranking layout and mobile wrapping.

## Milestone 18B Language Pack Foundation

- `src/context/LanguageContext.jsx`
  - Adds `LanguageProvider`, `useLanguage()`, and persisted EN/FR/DE language selection.
  - Uses localStorage key `agm_language`; no database storage.
- `src/i18n/*.js`
  - Adds English, French, and German dictionaries for common/auth/nav/status/member-facing surfaces.
  - Keeps guild names, usernames, IGN, database keys, raw audit metadata, and user-generated text out of translation scope.
- `src/layouts/AppShell.jsx`
  - Adds compact topbar language selector visible before and after sign-in.
- `src/App.jsx`, `src/data/navigation.js`
  - Wire translated shell/page/nav labels without changing routing or access gates.
- `src/pages/LoginRegister.jsx`, `src/pages/SetNewPassword.jsx`, `src/pages/PendingApproval.jsx`, `src/pages/RejectedStatus.jsx`, `src/pages/SuspendedStatus.jsx`, `src/pages/RosterRestrictedStatus.jsx`
  - Translate core auth/recovery/status gate copy.
- `src/pages/Dashboard.jsx`, `src/pages/Profile.jsx`, `src/pages/Gvg.jsx`
  - Translate member-facing status labels and core GvG voting copy included in 18B scope.
- `src/pages/AdminPanel.jsx`
  - Translates basic Admin tab labels only; full AdminPanel section translation remains future work.

## Milestone 16F Member-Facing UI Compact Pass

Production status:
- Browser-validated in staging through Milestone 16G and deployed to production through Milestone 16H.
- Production commit: `53c7907 style: clean up member-facing UI`.
- Production smoke passed for compact auth, Dashboard, Profile, GvG, EN/FR/DE layout, member AdminPanel denial, and CP non-leakage.

- `src/pages/LoginRegister.jsx`
  - Uses compact auth panel/form classes while preserving sign-in, registration, forgot-password, and approval-request behavior.
- `src/pages/SetNewPassword.jsx`
  - Uses compact recovery panel/form classes while preserving the recovery gate and password update behavior.
- `src/pages/PendingApproval.jsx`, `src/pages/RejectedStatus.jsx`, `src/pages/SuspendedStatus.jsx`, `src/pages/RosterRestrictedStatus.jsx`
  - Use compact gate panel styling while preserving lockout/sign-out behavior.
- `src/pages/Dashboard.jsx`
  - Shows compact member home summary focused on guild, role, roster status, GvG state, and current member identity.
- `src/pages/Profile.jsx`
  - Uses compact profile/detail panels while preserving own-IGN editing and safe profile display.
- `src/pages/Gvg.jsx`
  - Uses compact GvG hero/empty/vote panels while preserving event loading, eligibility, vote submission, and absence-reason behavior.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Shorten member-facing Dashboard/Profile/GvG/gate copy in all supported languages.
- `src/styles/app.css`
  - Adds compact member-facing panel, metric, profile, detail, recovery, and GvG vote styles.

## Milestone 19C CP Update Window Frontend

Production status:
- Browser-validated in staging through Milestone 19D and deployed to production through Milestone 19E.
- Production commit: `6a3a181 feat: add CP update window self-submit`.
- Production smoke passed for Owner AdminPanel CP tab/window status and Member Profile `Your CP` closed-window state.
- Controlled production CP mutation smoke was not performed by design.

- `src/services/cpWindowService.js`
  - Adds RPC-only wrappers for `get_my_cp`, `get_active_cp_update_window_for_me`, `submit_my_cp_update`, `get_cp_update_window_for_guild`, `open_cp_update_window`, and `close_cp_update_window`.
  - Does not query `member_cp`, `cp_snapshots`, or `cp_update_windows` directly.
  - Does not call admin CP roster or leaderboard RPCs.
- `src/pages/Profile.jsx`
  - Adds compact `Your CP` panel.
  - Loads only the signed-in member's own CP and own active CP Update Window status.
  - Submits own CP only through `submit_my_cp_update(...)`.
- `src/pages/AdminPanel.jsx`
  - Coordinates selected-guild CP Update Window state, note draft, open action, close action, and refresh after CP window changes.
  - Keeps existing CP roster, leaderboard, and admin CP update behavior in place.
- `src/components/admin/AdminCpSection.jsx`
  - Adds compact CP Update Window status/open/close controls above the existing CP roster/leaderboard UI.
- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Adds Profile CP, Admin CP window, and new audit/window display labels.
- `src/styles/app.css`
  - Adds compact Profile CP panel and Admin CP window block styling.

## Documentation

- `README.md`: Current project overview, milestone status, setup/deployment links, and security summary.
- `.env.example`: Browser-safe Vite Supabase env variable template only.
- `docs/SETUP.md`: Local development setup and local-only Supabase validation warnings.
- `docs/DEPLOYMENT.md`: Future production Supabase + Vercel deployment runbook.
- `docs/PRODUCTION_CHECKLIST.md`: Future production launch checklist and safety gates.
- `docs/TESTING.md`: Validation history plus production validation guidance.
- `docs/CHANGELOG.md`: Human-readable milestone changelog.
## Milestone 7 Frontend Member Role/Guild Management

- `src/services/adminMemberService.js`
  - Adds safe active guild option reads.
  - Adds RPC wrappers for `assign_member_role` and `transfer_member_guild`.
  - Adds role/transfer permission helpers for frontend UX gating.
- `src/pages/AdminPanel.jsx`
  - Adds role-change controls to active approved member cards.
  - Adds Owner-only guild transfer controls with confirmation warning.
  - Uses RPC-only writes and refreshes roster after success.
- `src/styles/app.css`
  - Adds mobile-first styling for member role/guild action blocks and warnings.
## Milestone 8 Frontend CP Management

- `src/services/adminCpService.js`
  - Isolated CP service.
  - Provides CP permission helpers.
  - Uses only `get_current_cp_roster`, `get_cp_leaderboard`, and `update_member_cp`.
  - Does not query protected CP tables directly.
- `src/pages/AdminPanel.jsx`
  - Adds Admin-only CP Management section.
  - Loads CP only after frontend CP view gating passes.
  - Keeps CP roster, leaderboard, and CP drafts local to AdminPanel.
  - Shows update controls only for CP updaters.
- `src/styles/app.css`
  - Adds mobile-first CP roster and leaderboard styling.
## Milestone 9 Admin Permission Management

- `src/services/adminPermissionService.js`
  - Loads permission catalog.
  - Loads active approved Admin permission targets.
  - Loads current Admin permission keys.
  - Saves changes through `grant_admin_permission` and `revoke_admin_permission`.
  - Provides Owner/Leader/Vice permission-toggle helpers.
- `src/pages/AdminPanel.jsx`
  - Adds Permission Management section.
  - Shows checkbox controls for active Admin memberships only.
  - Disables CP permissions for Leader/Vice with Owner-only messaging.
- `src/styles/app.css`
  - Adds mobile-first permission-card and checkbox styling.
## Milestone 10 GvG Management And Voting

- `src/services/gvgService.js`
  - Isolated GvG service.
  - Loads active member events through RLS-safe `gvg_events` reads.
  - Loads own vote through RLS-safe `gvg_votes` read filtered to the current profile.
  - Uses `submit_gvg_vote`, `create_gvg_event`, `set_gvg_event_status`, and `get_gvg_results`.
- `src/pages/Gvg.jsx`
  - Member-facing active event voting UI.
  - Supports Present/Absent vote switching through RPC upsert.
  - Shows only the current member's own vote/reason.
- `src/pages/AdminPanel.jsx`
  - Adds GvG management/results section.
  - Authorized staff can create/open/close events and view present/absent results with reasons.
- `src/styles/app.css`
  - Adds GvG management, summary, results, and active vote styles.
## Milestone 11A Audit Log Read Hardening

- `supabase/migrations/20260515000300_audit_log_read_hardening.sql`
  - Adds `public.get_audit_logs(...)`.
  - Restricts direct non-Owner `audit_logs` SELECT.
  - Redacts CP-sensitive audit metadata unless the viewer has scoped `view_cp`.
- `supabase/tests/local_validation_anteiku.sql`
  - Adds Milestone 11A validation for audit visibility, CP metadata redaction, direct table read hardening, private audit writer grants, and audit spoof protection.
## Milestone 11B Frontend Audit Log Viewer

- `src/services/adminAuditService.js`
  - Isolated audit-viewer service.
  - Uses only `get_audit_logs` for audit reads.
  - Provides frontend audit visibility gating, action/actor/target formatting, default filters, and whitelist-based metadata formatting.
  - Does not query `audit_logs` directly and does not call CP tables/RPCs.
- `src/pages/AdminPanel.jsx`
  - Adds read-only Audit Logs section.
  - Supports refresh, action filter, safe/simple guild filter, date range filters, limit selector, and load older pagination through `p_before`.
  - Shows loading, empty, error, and clean not-authorized states.
  - Shows `Sensitive CP metadata hidden.` when `metadata_redacted` is true.
- `src/styles/app.css`
  - Adds mobile-first dark/red audit filters, cards, metadata summary, and load-older styles.

## Milestone 14C AdminPanel Tabs And Section Organization

- `src/pages/AdminPanel.jsx`
  - Coordinates AdminPanel session/membership context, admin permission-key loading, visible tab calculation, active tab state, and section handlers.
  - Renders only the active tab section.
  - Lazy-loads CP, Audit Logs, and GvG management data only when those tabs are opened.
  - Keeps backend/RLS/RPC checks as the authority and preserves existing service paths.
- `src/components/admin/AdminTabs.jsx`
  - Mobile-first horizontal tab bar for Approvals, Members, CP, GvG, Audit Logs, Permissions, and Tools.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Extracted approval queue UI; writes still flow through existing approval RPC handlers.
- `src/components/admin/AdminMembersSection.jsx`
  - Extracted member management UI; writes still flow through existing member-management RPC handlers.
- `src/components/admin/AdminCpSection.jsx`
  - Extracted CP UI; CP service paths remain approved CP RPCs only.
- `src/components/admin/AdminGvgSection.jsx`
  - Extracted GvG management UI; GvG service paths remain approved RPCs/safe reads.
- `src/components/admin/AdminAuditSection.jsx`
  - Extracted audit viewer UI; audit reads remain `get_audit_logs` only.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Extracted permission checkbox UI; writes remain `grant_admin_permission` / `revoke_admin_permission`.
- `src/components/admin/AdminToolsSection.jsx`
  - Extracted planned admin modules placeholder.
- `src/styles/app.css`
  - Adds sticky/mobile horizontal admin tab styling and tab content spacing.

## Milestone 15B Frontend Member Status UI

- `src/services/profileService.js`
  - Includes `roster_status` in the safe current membership shape.
- `src/services/adminMemberService.js`
  - Includes `roster_status` in the safe member roster select.
  - Loads approved primary memberships across active/suspended/left hard states.
  - Adds roster status label/tone/summary helpers.
  - Adds `updateMemberRosterStatus(...)`, which calls only `update_member_roster_status`.
- `src/App.jsx`
  - Derives UX-only hard roster blocking for `suspended`, `left`, and `kicked`.
  - Keeps pending/rejected/profile approval gating intact.
- `src/pages/RosterRestrictedStatus.jsx`
  - Shows safe restricted notices for roster hard-block states.
- `src/pages/Dashboard.jsx` and `src/pages/Profile.jsx`
  - Show own roster status badges/notes without adding CP reads.
- `src/pages/Gvg.jsx`
  - Shows no vote controls for `inactive` and `on_break`; backend remains authority.
- `src/pages/AdminPanel.jsx`
  - Coordinates roster status filters, drafts, RPC action handler, and refresh after status changes.
- `src/components/admin/AdminMembersSection.jsx`
  - Displays roster badges/filter/status controls, reason input, and hard-block confirmation.
  - Does not display private status history/reasons.
- `src/styles/app.css`
  - Adds roster badge tones, badge rows, restricted panels, and compact status reason styling.

## Milestone 16B AdminPanel UI Cleanup

- `src/pages/AdminPanel.jsx`
  - Keeps AdminPanel behavior and tab coordination unchanged.
  - Shortens AdminPanel shell and restricted-state copy.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Tightens approval tab heading, empty state, cards, and rejection-note copy.
- `src/components/admin/AdminMembersSection.jsx`
  - Tightens member cards, metadata, roster status controls, role controls, and guild transfer copy while preserving existing action handlers.
- `src/components/admin/AdminCpSection.jsx`
  - Tightens CP roster, empty state, read-only, and leaderboard copy.
- `src/components/admin/AdminGvgSection.jsx`
  - Tightens GvG event creation/results copy while preserving event lifecycle controls.
- `src/components/admin/AdminAuditSection.jsx`
  - Tightens audit empty/denied states while preserving CP redaction notice.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Tightens permission target copy without changing checkbox behavior.
- `src/components/admin/AdminToolsSection.jsx`
  - Replaces milestone-style placeholder language with compact coming-later rows.
- `src/styles/app.css`
  - Adds compact AdminPanel card, empty-state, metadata, control-block, tab, and narrow-mobile styles.

## Milestone 18D AdminPanel Full Translation

- `src/i18n/en.js`, `src/i18n/fr.js`, `src/i18n/de.js`
  - Add full AdminPanel translation keys for shell, common admin labels, Approvals, Members, CP, GvG, Audit Logs, Permissions, Tools, errors, success messages, permission catalog display labels/descriptions, audit actions, and audit metadata labels.
- `src/pages/AdminPanel.jsx`
  - Adds UI-only translation wrappers for roles, membership statuses, roster statuses, GvG statuses, dates, audit actions, audit metadata labels, and permission labels/descriptions.
  - Keeps all logic values, select values, RPC payload values, audit metadata values, permission keys, and roster/GvG/member status values unchanged.
- `src/components/admin/AdminApprovalsSection.jsx`
  - Translates approval queue labels, buttons, empty/loading states, details labels, and rejection note labels.
- `src/components/admin/AdminMembersSection.jsx`
  - Translates roster filters, compact row metadata, Manage disclosure controls, roster status controls, role controls, guild transfer controls, confirmations, warnings, and empty/loading states.
- `src/components/admin/AdminCpSection.jsx`
  - Translates CP roster, filters, CP details labels, read-only/update controls, empty states, and leaderboard labels.
- `src/components/admin/AdminGvgSection.jsx`
  - Translates GvG event creation, scope labels, date labels, lifecycle buttons, result summaries, and empty/loading states while preserving event titles and status values used in logic.
- `src/components/admin/AdminAuditSection.jsx`
  - Translates audit filters, action labels, card metadata labels, read-only badge, CP redaction notice, metadata labels, and load-older controls while preserving raw metadata values.
- `src/components/admin/AdminPermissionsSection.jsx`
  - Translates permission target labels, sensitive/Owner-only notes, save/cancel controls, and permission catalog display labels/descriptions without renaming permission keys.
- `src/components/admin/AdminToolsSection.jsx`
  - Translates Tools placeholder copy.

Milestone 18F production note:
- The frontend-only language pack is live in production as commit `1f5b956 feat: add English French German language pack`.
- Supported languages are English, French, and German.
- Full AdminPanel translation is production-smoke validated.
- Translation remains display-only; backend logic, permission keys, audit values, guild names, usernames, IGN, and user-generated text remain raw/unchanged.
