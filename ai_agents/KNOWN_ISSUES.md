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
- Milestone 15E Member Status production rollout is complete.
- Milestone 17C Password Recovery Required Reset Flow production rollout is complete and validated with the controlled production test member.
- Milestone 18F Language Pack production rollout is complete. English, French, and German are live in production, including full AdminPanel translation.
- Milestone 19E CP Update Window / Member CP Self-Submit production rollout is complete. Production has both CP Update Window migrations applied, frontend deployment complete, and read-only production smoke passed.
- No controlled production CP mutation smoke was performed during Milestone 19E; do not open/close a production CP window or submit production CP test values without explicit approval.
- Milestone 20F CP Leaderboard production rollout is complete. Production has `20260524000300_cp_rankings.sql` applied, member rank-only leaderboard is live, AdminPanel CP Ranking is permission-protected, and production smoke passed.
- Milestone 21E Rank Badge / Profile Border production rollout is complete. Production has `20260524000400_cp_rank_badge_summary.sql` applied, Profile/Dashboard rank badge visuals are live, and production smoke passed with no CP value exposure from the badge.
- Milestone 22E Cosmetics production rollout is complete. Production has `20260525000100_cosmetics_catalog_unlocks.sql` applied and verified, Vercel serves the cosmetics picker/assets, and cosmetics use approved repo static assets only.
- Milestone 23D Premium Cosmetics production rollout is complete. Production has `20260525000300_premium_cosmetics_grant_helper.sql` applied and verified.
- Milestone 24E AdminPanel Analytics production rollout is complete. Production has `20260526000100_admin_analytics_foundation.sql` applied and verified, Analytics is live, Weekly Growth is live, and Owner production smoke passed.
- Controlled production Member `m13bmember21056302` remains approved/active but did not receive an equipped cosmetics row during the 22E smoke; Owner `ultimatesrb` verified production equip persistence.
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
- Supabase CLI is currently linked to production `mzflfyxxkascrfpteexz`; future staging/local work must explicitly relink before Supabase commands.
- Optional production roster-status mutation smoke must use the controlled production test member only, require explicit approval, and restore to `active`.
- Optional production CP Update Window mutation smoke must use a controlled production test member only, require explicit approval, and document whether test CP/window data is restored or retained.
- Optional production Weekly Growth snapshot capture must require explicit approval because it creates persistent `cp_snapshot_batches` and `cp_snapshot_entries` rows. Milestone 24E production smoke intentionally did not capture a production snapshot.
- Member CP Leaderboard rank order intentionally reveals relative CP strength, but exact CP values remain hidden from member API responses and UI.
- Rank Badge / Profile Border intentionally reveals the caller's own global/guild rank and rank tier only; it must not expose CP values, growth/history/snapshot data, updated-by metadata, profile ids, usernames from the rank RPC, or other-member data.
- Cosmetics catalog asset keys use repo file names without extension. `_FREE` frames are free; non-`_FREE` frames are manual unlocks. Do not add arbitrary URLs or uploads in v1.
- Milestone 23D makes all current production frame keys free and reserves `unlock_type = 'manual'` for future premium avatars/frames.
- Production currently has no active manual cosmetics; locked/manual grant/equip runtime behavior was validated in staging, not by production mutation smoke.
- Cosmetic frame alignment is handled with shared avatar/frame shell CSS. If future frame PNGs use inconsistent transparent padding, prefer asset normalization or per-frame display metadata in a planned milestone rather than ad hoc frontend hacks.
- Recovery gate copy was not fully re-tested during Milestone 18F because no live recovery session was triggered; recovery behavior itself was already production-validated in Milestone 17C.

## Product Gaps

- Reapply UI is not implemented.
- Suspended/left/rejected member management is not implemented.
- Avatar editing is not implemented.
- Normal users cannot edit username/profile slug by design.
- Controlled production CP mutation smoke for CP Update Window / Member CP Self-Submit has not been run. The feature is live and read-only-smoke validated; mutation smoke remains optional and requires explicit approval.
- Weekly CP snapshot/growth report UI is implemented in AdminPanel Analytics and is staff-only / `view_cp` gated for CP values. Production snapshot capture still requires explicit approval before use.
- Guild/subguild management UI is not implemented.
- French/German wording review by native-speaking admins is recommended for the language pack.

## Development Notes

- Git is available in the current shell.
- After local DB reset, stale browser auth can cause `profiles_id_fkey` registration errors; clear localStorage/sessionStorage before retesting auth/registration.
- `npm.cmd audit` reports 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`. This affects Vite dev-server behavior. Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade.
