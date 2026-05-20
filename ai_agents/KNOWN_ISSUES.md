# Known Issues

## Production Readiness

- Production Supabase is created, linked, migrated, schema/RLS/seed verified, and Owner-bootstrapped.
- Production Vercel deployment is live at `https://anteiku-guild-manager.vercel.app`.
- Production Auth Site URL and Redirect URL allow-list are configured for the production URL.
- Milestone 13B production smoke/security validation passed.
- Controlled production test member remains in production and should not be removed or changed unless cleanup/member management is explicitly approved.
- GvG production smoke was intentionally not tested to avoid persistent production GvG test data without a cleanup/delete flow.
- CP redaction browser test was intentionally not tested because no production staff/data combination exists for `view_audit_logs` without `view_cp` plus fresh CP-sensitive audit metadata.
- Vercel GitHub App access should be restricted to only `Ultimate99/anteiku-guild-manager` if it is not already repository-scoped.
- Milestone 14A documented production hardening and cleanup policy only; no production changes were performed.
- Vercel GitHub App restriction is recommended but not yet executed.
- Preview deployments should have no Supabase env vars until a separate staging Supabase project exists.
- Future staging must use a separate Supabase project, not production.

## Production Safety Hazards

- `supabase db reset` must never be run against production.
- `supabase/tests/local_validation_anteiku.sql` must never run against production because it inserts fake auth users and test data.
- `supabase/config.toml` references `./seed.sql`, but `supabase/seed.sql` is missing. Core guild and permission seed data currently comes from migration `20260514000400_seed_core_data.sql`; do not use `db push --include-seed` until this is intentionally resolved.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend env or Vercel public env.
- Do not hard-delete the controlled production test member; preserve audit/history unless a cleanup plan is explicitly approved.
- Do not create production GvG test events without explicit approval and a cleanup/data-retention plan.
- Do not broaden Supabase redirect wildcards for Preview deployments against production.

## Product Gaps

- Reapply UI is not implemented.
- Suspended/left/rejected member management is not implemented.
- Avatar editing is not implemented.
- Normal users cannot edit username/profile slug by design.
- Weekly CP snapshot/growth report UI is not implemented.
- Guild/subguild management UI is not implemented.

## Development Notes

- Git is available in the current shell.
- After local DB reset, stale browser auth can cause `profiles_id_fkey` registration errors; clear localStorage/sessionStorage before retesting auth/registration.
- `npm.cmd audit` reports 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`. This affects Vite dev-server behavior. Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade.
