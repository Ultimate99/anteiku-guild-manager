-- Anteiku Guild Manager - Constraints And Indexes
-- Safe migration: adds approved CHECK constraints, unique constraints, and indexes.
-- Keeps early-development statuses as text with CHECK constraints instead of Postgres enums.

alter table public.profiles
  add constraint profiles_approval_status_chk
  check (approval_status in ('pending', 'approved', 'rejected', 'suspended'));

alter table public.profiles
  add constraint profiles_username_format_chk
  check (
    username = lower(username)
    and username ~ '^[a-z0-9](?:[a-z0-9_-]{1,30}[a-z0-9])$'
  );

alter table public.profiles
  add constraint profiles_profile_slug_format_chk
  check (
    profile_slug = lower(profile_slug)
    and profile_slug ~ '^[a-z0-9](?:[a-z0-9_-]{1,30}[a-z0-9])$'
  );

alter table public.profiles
  add constraint profiles_username_profile_slug_match_chk
  check (username = profile_slug);

alter table public.profiles
  add constraint profiles_reapply_note_length_chk
  check (reapply_note is null or char_length(reapply_note) <= 1000);

alter table public.guilds
  add constraint guilds_status_chk
  check (status in ('active', 'archived'));

alter table public.guild_memberships
  add constraint guild_memberships_role_chk
  check (role in ('owner', 'leader', 'vice', 'admin', 'member'));

alter table public.guild_memberships
  add constraint guild_memberships_status_chk
  check (membership_status in ('pending', 'active', 'suspended', 'left', 'rejected'));

alter table public.member_cp
  add constraint member_cp_value_nonnegative_chk
  check (cp_value >= 0);

alter table public.cp_snapshots
  add constraint cp_snapshots_value_nonnegative_chk
  check (cp_value >= 0);

alter table public.gvg_events
  add constraint gvg_events_scope_chk
  check (scope in ('guild', 'global'));

alter table public.gvg_events
  add constraint gvg_events_status_chk
  check (status in ('draft', 'active', 'closed', 'cancelled', 'archived'));

alter table public.gvg_events
  add constraint gvg_events_scope_guild_chk
  check (
    (scope = 'guild' and guild_id is not null)
    or (scope = 'global' and guild_id is null)
  );

alter table public.gvg_votes
  add constraint gvg_votes_status_chk
  check (vote_status in ('present', 'absent'));

alter table public.gvg_votes
  add constraint gvg_votes_absence_reason_length_chk
  check (absence_reason is null or char_length(absence_reason) <= 500);

alter table public.gvg_votes
  add constraint gvg_votes_present_reason_chk
  check (vote_status = 'absent' or absence_reason is null);

create unique index if not exists profiles_username_uidx
  on public.profiles (username);

create unique index if not exists profiles_profile_slug_uidx
  on public.profiles (profile_slug);

create index if not exists profiles_approval_status_idx
  on public.profiles (approval_status);

create unique index if not exists guilds_slug_uidx
  on public.guilds (slug);

create unique index if not exists guilds_name_uidx
  on public.guilds (name);

create index if not exists guilds_status_idx
  on public.guilds (status);

create unique index if not exists guild_memberships_profile_guild_uidx
  on public.guild_memberships (profile_id, guild_id);

create unique index if not exists guild_memberships_one_active_primary_uidx
  on public.guild_memberships (profile_id)
  where membership_status = 'active' and is_primary = true;

create index if not exists guild_memberships_profile_idx
  on public.guild_memberships (profile_id);

create index if not exists guild_memberships_guild_role_status_idx
  on public.guild_memberships (guild_id, role, membership_status);

create unique index if not exists admin_permissions_membership_permission_uidx
  on public.admin_permissions (membership_id, permission_key);

create index if not exists admin_permissions_permission_key_idx
  on public.admin_permissions (permission_key);

create index if not exists member_cp_guild_idx
  on public.member_cp (guild_id);

create unique index if not exists cp_snapshots_profile_guild_week_uidx
  on public.cp_snapshots (profile_id, guild_id, snapshot_week_start);

create index if not exists cp_snapshots_guild_week_idx
  on public.cp_snapshots (guild_id, snapshot_week_start);

create index if not exists gvg_events_guild_status_idx
  on public.gvg_events (guild_id, status);

create index if not exists gvg_events_scope_status_idx
  on public.gvg_events (scope, status);

create unique index if not exists gvg_votes_event_profile_uidx
  on public.gvg_votes (gvg_event_id, profile_id);

create index if not exists gvg_votes_event_status_idx
  on public.gvg_votes (gvg_event_id, vote_status);

create index if not exists audit_logs_guild_created_idx
  on public.audit_logs (guild_id, created_at desc);

create index if not exists audit_logs_actor_created_idx
  on public.audit_logs (actor_profile_id, created_at desc);

create index if not exists audit_logs_target_created_idx
  on public.audit_logs (target_profile_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_guilds_updated_at on public.guilds;
create trigger set_guilds_updated_at
before update on public.guilds
for each row
execute function public.set_updated_at();

drop trigger if exists set_guild_memberships_updated_at on public.guild_memberships;
create trigger set_guild_memberships_updated_at
before update on public.guild_memberships
for each row
execute function public.set_updated_at();

drop trigger if exists set_member_cp_updated_at on public.member_cp;
create trigger set_member_cp_updated_at
before update on public.member_cp
for each row
execute function public.set_updated_at();

drop trigger if exists set_gvg_events_updated_at on public.gvg_events;
create trigger set_gvg_events_updated_at
before update on public.gvg_events
for each row
execute function public.set_updated_at();

drop trigger if exists set_gvg_votes_updated_at on public.gvg_votes;
create trigger set_gvg_votes_updated_at
before update on public.gvg_votes
for each row
execute function public.set_updated_at();
