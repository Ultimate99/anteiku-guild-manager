# Architecture

## Current Architecture

- React + Vite single-page frontend.
- Local component state for page previews.
- Plain CSS.
- Supabase JS client placeholder using Vite environment variables.

## Intended Architecture

- Supabase Auth for login and registration.
- Supabase Postgres for profiles, guilds, memberships, permissions, GvG events, votes, CP snapshots, and audit logs.
- RLS policies and approved RPC functions for sensitive access.
- Vercel hosting.

No real backend behavior is implemented yet.
