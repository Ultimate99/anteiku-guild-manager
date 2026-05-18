# Anteiku Guild Manager

Anteiku Guild Manager is a mobile-first React + Vite web app for managing multiple Tokyo Ghoul: Break the Chains guilds and subguilds.

The app currently supports local Supabase-backed registration, approval gates, profile editing, admin member management, role/guild management, admin permission checkboxes, protected CP management, GvG event/voting flows, and a read-only audit log viewer.

## Current Milestone State

Complete:

- Milestone 10: GvG event management and voting.
- Milestone 11A: backend audit-log read hardening.
- Milestone 11B: frontend Audit Log Viewer.
- Milestone 12: docs-only production readiness runbook/checklist.

Milestone 12 did not deploy, link to production Supabase, change source logic, or change SQL migrations.

## Stack

- React 18
- Vite 5
- Supabase JS
- Plain CSS
- Supabase migrations/RLS/RPCs
- Vercel planned for hosting

## Local Setup

See [docs/SETUP.md](docs/SETUP.md).

Short version:

```powershell
npm install
copy .env.example .env.local
npm run dev
```

Use local Supabase values in `.env.local` for development. Do not put production secrets in committed files.

## Build

```powershell
npm run build
```

The Vercel production build command is also `npm run build`, with output directory `dist`.

## Production Readiness

Production deployment is planned for a later milestone only after explicit approval.

Read these before any production action:

- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- [docs/PRODUCTION_CHECKLIST.md](docs/PRODUCTION_CHECKLIST.md)
- [docs/TESTING.md](docs/TESTING.md)

## Security Requirements

Security-sensitive access is enforced by Supabase RLS/RPC, not frontend hiding.

- Members must never see CP values.
- CP access must remain RPC/RLS-protected through approved CP RPCs.
- Pending users must not access member/admin areas.
- Owner bootstrap remains manual-only.
- Admin permissions must remain database-enforced.
- GvG voting must keep one vote per event/profile.
- Audit log reads must use `public.get_audit_logs(...)`.
- CP-sensitive audit metadata must not leak to users without scoped `view_cp`.
- Service role keys and secret keys must never be placed in frontend or Vercel public env variables.
