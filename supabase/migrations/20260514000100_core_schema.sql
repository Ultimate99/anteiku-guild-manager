-- Anteiku Guild Manager - Core Schema
-- Safe migration: creates base application tables only.
-- Does not create an Owner account, does not apply RLS policies, and does not expose CP to members.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null,
  profile_slug text not null,
  ign text not null,
  avatar_key text,
  approval_status text not null default 'pending',
  reapply_requested_at timestamptz,
  reapply_note text,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null,
  rejected_at timestamptz,
  rejected_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.guilds (
  id uuid primary key default gen_random_uuid(),
  slug text not null,
  name text not null,
  parent_guild_id uuid references public.guilds(id) on delete set null,
  is_core boolean not null default false,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.guild_memberships (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  role text not null default 'member',
  membership_status text not null default 'pending',
  is_primary boolean not null default true,
  assigned_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.permission_catalog (
  key text primary key,
  label text not null,
  description text,
  is_sensitive boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.admin_permissions (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null references public.guild_memberships(id) on delete cascade,
  permission_key text not null references public.permission_catalog(key) on delete restrict,
  granted_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.member_cp (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  cp_value integer not null,
  updated_by uuid not null references public.profiles(id) on delete restrict,
  updated_at timestamptz not null default now()
);

create table if not exists public.cp_snapshots (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  snapshot_week_start date not null,
  cp_value integer not null,
  captured_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.gvg_events (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid references public.guilds(id) on delete restrict,
  scope text not null,
  title text not null,
  status text not null default 'draft',
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.gvg_votes (
  id uuid primary key default gen_random_uuid(),
  gvg_event_id uuid not null references public.gvg_events(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  vote_status text not null,
  absence_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid references public.profiles(id) on delete set null,
  target_profile_id uuid references public.profiles(id) on delete set null,
  guild_id uuid references public.guilds(id) on delete set null,
  action text not null,
  entity_table text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
