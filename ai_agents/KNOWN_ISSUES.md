# Known Issues

## Production Readiness

- Production Supabase has not been created or linked.
- Migrations have not been applied to a remote/production Supabase project.
- Production Auth Site URL and redirect URLs are not configured.
- Vercel deployment is not configured or performed.
- Production Owner bootstrap has not been performed.
- Milestone 13 needs explicit approval before any production command or deployment.

## Production Safety Hazards

- `supabase db reset` must never be run against production.
- `supabase/tests/local_validation_anteiku.sql` must never run against production because it inserts fake auth users and test data.
- `supabase/config.toml` references `./seed.sql`, but `supabase/seed.sql` is missing. Core guild and permission seed data currently comes from migration `20260514000400_seed_core_data.sql`; do not use `db push --include-seed` until this is intentionally resolved.
- Service role keys, `sb_secret_*` keys, database URLs, JWT secrets, SMTP secrets, and OAuth secrets must never be placed in frontend env or Vercel public env.

## Product Gaps

- Reapply UI is not implemented.
- Suspended/left/rejected member management is not implemented.
- Avatar editing is not implemented.
- Normal users cannot edit username/profile slug by design.
- Weekly CP snapshot/growth report UI is not implemented.
- Guild/subguild management UI is not implemented.

## Development Notes

- Git is not available in the current shell PATH.
- After local DB reset, stale browser auth can cause `profiles_id_fkey` registration errors; clear localStorage/sessionStorage before retesting auth/registration.
- `npm.cmd audit` reports 2 moderate vulnerabilities from `esbuild <=0.24.2` via `vite <=6.4.1`. This affects Vite dev-server behavior. Do not run `npm audit fix --force`; it would install Vite 8.0.13 as a breaking major upgrade.
