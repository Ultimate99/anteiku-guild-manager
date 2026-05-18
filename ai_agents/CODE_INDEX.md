# Code Index

- `src/main.jsx`: React root.
- `src/App.jsx`: Local page state and placeholder session.
- `src/layouts/AppShell.jsx`: Header, content frame, and bottom navigation container.
- `src/components/AppNav.jsx`: Mobile-first page navigation.
- `src/components/StatusBadge.jsx`: Small status label component.
- `src/config/supabaseClient.js`: Supabase env check and client placeholder.
- `src/context/AuthContext.jsx`: Local Supabase auth/session provider and safe viewer state.
- `src/hooks/useAuth.js`: Hook for reading auth context.
- `src/services/authService.js`: Supabase auth wrappers for session, signin, signup, and signout.
- `src/services/profileService.js`: Safe own profile/membership/guild loading, registration RPC call, and own IGN update RPC wrapper.
- `src/services/guildService.js`: Safe core guild loading for registration.
- `src/services/adminApprovalService.js`: RLS-safe approval queue reads, own approval permission lookup, and approval/rejection RPC wrappers.
- `src/services/adminMemberService.js`: RLS-safe active approved member roster reads, member-management permission helpers, and admin member IGN/slug RPC wrappers.
- `src/data/guilds.js`: Core guild list.
- `src/data/navigation.js`: Navigation items.
- `src/pages/LoginRegister.jsx`: Local Supabase signin/signup and registration UI.
- `src/pages/PendingApproval.jsx`: Pending approval gate with manual refresh.
- `src/pages/RejectedStatus.jsx`: Rejected account gate; reapply is planned later.
- `src/pages/SuspendedStatus.jsx`: Suspended account gate.
- `src/pages/Dashboard.jsx`: Approved-user safe guild dashboard.
- `src/pages/Profile.jsx`: Safe profile display without CP, plus own IGN edit mode for approved users.
- `src/pages/Gvg.jsx`: GvG voting placeholder without persistence.
- `src/pages/AdminPanel.jsx`: Restricted admin view with registration approval/rejection queue, active approved member management, and planned future admin modules.
- `src/styles/app.css`: Plain mobile-first dark styling.

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
