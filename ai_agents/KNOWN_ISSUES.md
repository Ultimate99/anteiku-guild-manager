# Known Issues

## Production Readiness

- Production Supabase is created, linked, migrated, schema/RLS/seed verified, and Owner-bootstrapped.
- Production Vercel deployment is live at `https://anteiku-guild-manager.vercel.app`.
- Production Auth Site URL and Redirect URL allow-list are configured for the production URL.
- Milestone 13B production smoke/security validation passed.
- Controlled production test member remains in production and should not be removed or changed unless cleanup/member management is explicitly approved.
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data without a cleanup/delete flow.
- CP redaction browser test was intentionally not tested because no production staff/data combination exists for `view_audit_logs` without `view_cp` plus fresh CP-sensitive audit metadata.
- Milestone 14A documented production hardening and cleanup policy only; no production changes were performed.
- Milestone 14B recorded user-confirmed Vercel GitHub App restriction to only `Ultimate99/anteiku-guild-manager`.
- Vercel project remains connected to `Ultimate99/anteiku-guild-manager` on `main`.
- Preview deployments should not be configured until the approved staging/Vercel Preview step.
- Staging uses a separate Supabase project, not production.
- Milestone 14E staging migration/apply/verification is complete for project `ckyihuxkioeibzpgwenc` / `Anteiku Guild Manager Staging`.
- Milestone 14F staging Owner bootstrap is complete and verified.
- Milestone 14G controlled staging test users and permission matrix setup is complete.
- Milestone 14H staging CP audit redaction and GvG full-smoke validation is complete.
- Milestone 15D Member Status staging migration/browser validation is complete.
- Production rollout for the Member Status migration/frontend remains pending.
- Staging test data remains intentionally; do not cleanup/delete it unless separately approved.
- Vercel Preview env has not been configured for staging yet.

## Production Safety Hazards

- `supabase db reset` must never be run against production.
- `supabase/tests/local_validation_anteiku.sql` must never run against production because it inserts fake auth users and test data.
- `supabase/config.toml` references `./seed.sql`, but `supabase/seed.sql` is missing. Core guild and permission seed data currently comes from migration `20260514000400_seed_core_data.sql`; do not use `db push --include-seed` until this is intentionally resolved.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend env or Vercel public env.
- Do not hard-delete the controlled production test member; preserve audit/history unless a cleanup plan is explicitly approved.
- Do not create production GvG test events without explicit approval and a cleanup/data-retention plan.
- Do not broaden Supabase redirect wildcards for Preview deployments against production.
- Do not point Vercel Preview env at production Supabase by default.
- Do not add preview wildcard redirects to production Supabase. If preview wildcards are needed, use staging Supabase.
- Do not use `db push --include-seed` for staging or production until the missing `supabase/seed.sql` hazard is intentionally resolved.
- Do not run Owner bootstrap against the wrong project; staging and production Owner bootstrap actions must be separately reviewed.
- Do not rerun staging Owner bootstrap unless a recovery plan is explicitly approved; staging already has exactly one active Owner.
- Literal DevTools request capture was unavailable during 14H browser automation; source-path inspection confirmed approved RPC usage. Treat this as a recorded caveat, not a 14H blocker.
- `manage_permissions` is not seeded in the current permission catalog migration. Treat it as a future/open permission question, not a Milestone 14E blocker, unless explicitly approved later.
- The 15B Member Status frontend reads `guild_memberships.roster_status`; do not deploy it to production until `20260523000100_member_roster_status_system.sql` is applied and verified in production.

## Product Gaps

- Reapply UI is not implemented.
- Suspended/left/rejected member management is not implemented.
- Avatar editing is not implemented.
- Normal users cannot edit username/profile slug by design.
- CP Update Window / Member CP Self-Submit is not implemented. Future rule: members may see and submit only their own CP through safe RPCs when allowed by an open CP update window; they must not see other members' CP, roster, leaderboard, snapshots, or CP history.
- Weekly CP snapshot/growth report UI is not implemented.
- Guild/subguild management UI is not implemented.

## Development Notes

- Git is available in the current shell.
- After local DB reset, stale browser auth can cause `profiles_id_fkey` registration errors; clear localStorage/sessionStorage before retesting auth/registration.
- `npm.cmd audit` reports 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`. This affects Vite dev-server behavior. Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade.
