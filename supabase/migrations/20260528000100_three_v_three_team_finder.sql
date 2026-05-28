-- Anteiku Guild Manager - 3v3 Team Finder backend foundation
-- Safe migration: adds public self-entered 3v3 profile fields, global
-- 3-person teams, join requests, and RPC-only team management. Normal
-- protected CP in member_cp/cp_snapshots is not read or exposed.

create table if not exists public.three_v_three_player_profiles (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  discord_username text,
  combined_cp bigint,
  updated_at timestamptz not null default now(),
  constraint three_v_three_player_profiles_discord_chk check (
    discord_username is null
    or discord_username ~ '^[a-z0-9_.]{2,32}$'
  ),
  constraint three_v_three_player_profiles_combined_cp_chk check (
    combined_cp is null
    or combined_cp >= 0
  )
);

create table if not exists public.three_v_three_teams (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_profile_id uuid not null references public.profiles(id) on delete restrict,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  disbanded_at timestamptz,
  constraint three_v_three_teams_name_length_chk check (
    char_length(btrim(name)) between 3 and 50
  ),
  constraint three_v_three_teams_status_chk check (
    status in ('open', 'full', 'closed', 'disbanded')
  ),
  constraint three_v_three_teams_disbanded_at_chk check (
    (status = 'disbanded' and disbanded_at is not null)
    or (status <> 'disbanded')
  )
);

create table if not exists public.three_v_three_team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.three_v_three_teams(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  slot_number integer not null,
  role text not null default 'member',
  combined_cp_snapshot bigint not null,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  removed_by uuid references public.profiles(id) on delete set null,
  constraint three_v_three_team_members_slot_chk check (slot_number in (1, 2, 3)),
  constraint three_v_three_team_members_role_chk check (role in ('owner', 'member')),
  constraint three_v_three_team_members_combined_cp_chk check (combined_cp_snapshot >= 0)
);

create table if not exists public.three_v_three_join_requests (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.three_v_three_teams(id) on delete cascade,
  requester_profile_id uuid not null references public.profiles(id) on delete cascade,
  combined_cp_snapshot bigint not null,
  status text not null default 'pending',
  attempt_number integer not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  decided_by uuid references public.profiles(id) on delete set null,
  decided_at timestamptz,
  constraint three_v_three_join_requests_status_chk check (
    status in ('pending', 'approved', 'declined', 'cancelled')
  ),
  constraint three_v_three_join_requests_attempt_chk check (attempt_number between 1 and 2),
  constraint three_v_three_join_requests_combined_cp_chk check (combined_cp_snapshot >= 0)
);

create unique index if not exists three_v_three_teams_one_active_owner_uidx
  on public.three_v_three_teams (owner_profile_id)
  where status in ('open', 'full', 'closed');

create unique index if not exists three_v_three_team_members_active_slot_uidx
  on public.three_v_three_team_members (team_id, slot_number)
  where left_at is null;

create unique index if not exists three_v_three_team_members_active_profile_team_uidx
  on public.three_v_three_team_members (team_id, profile_id)
  where left_at is null;

create unique index if not exists three_v_three_team_members_one_active_profile_uidx
  on public.three_v_three_team_members (profile_id)
  where left_at is null;

create index if not exists three_v_three_team_members_team_active_idx
  on public.three_v_three_team_members (team_id, left_at, slot_number);

create unique index if not exists three_v_three_join_requests_one_pending_uidx
  on public.three_v_three_join_requests (team_id, requester_profile_id)
  where status = 'pending';

create index if not exists three_v_three_join_requests_team_status_idx
  on public.three_v_three_join_requests (team_id, status, created_at desc);

create index if not exists three_v_three_join_requests_requester_status_idx
  on public.three_v_three_join_requests (requester_profile_id, status, created_at desc);

drop trigger if exists set_three_v_three_player_profiles_updated_at on public.three_v_three_player_profiles;
create trigger set_three_v_three_player_profiles_updated_at
before update on public.three_v_three_player_profiles
for each row
execute function public.set_updated_at();

drop trigger if exists set_three_v_three_teams_updated_at on public.three_v_three_teams;
create trigger set_three_v_three_teams_updated_at
before update on public.three_v_three_teams
for each row
execute function public.set_updated_at();

drop trigger if exists set_three_v_three_join_requests_updated_at on public.three_v_three_join_requests;
create trigger set_three_v_three_join_requests_updated_at
before update on public.three_v_three_join_requests
for each row
execute function public.set_updated_at();

create or replace function private.prevent_three_v_three_team_identity_update()
returns trigger
language plpgsql
set search_path = pg_catalog
as $$
begin
  if new.name is distinct from old.name then
    raise exception '3v3 team name cannot be changed.';
  end if;

  if new.owner_profile_id is distinct from old.owner_profile_id then
    raise exception '3v3 team ownership transfer is not supported.';
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_three_v_three_team_identity_update on public.three_v_three_teams;
create trigger prevent_three_v_three_team_identity_update
before update on public.three_v_three_teams
for each row
execute function private.prevent_three_v_three_team_identity_update();

alter table public.three_v_three_player_profiles enable row level security;
alter table public.three_v_three_teams enable row level security;
alter table public.three_v_three_team_members enable row level security;
alter table public.three_v_three_join_requests enable row level security;

revoke all on public.three_v_three_player_profiles from public, anon, authenticated;
revoke all on public.three_v_three_teams from public, anon, authenticated;
revoke all on public.three_v_three_team_members from public, anon, authenticated;
revoke all on public.three_v_three_join_requests from public, anon, authenticated;

create or replace function private.normalize_three_v_three_discord_username(p_discord_username text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select nullif(regexp_replace(lower(btrim(coalesce(p_discord_username, ''))), '^@+', ''), '');
$$;

create or replace function private.is_valid_three_v_three_discord_username(p_discord_username text)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select p_discord_username is not null
    and p_discord_username ~ '^[a-z0-9_.]{2,32}$';
$$;

create or replace function private.has_three_v_three_view_access(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.has_three_v_three_action_access(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.three_v_three_primary_guild_id(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select gm.guild_id
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.profile_id = p_profile_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and p.approval_status = 'approved'
  limit 1;
$$;

create or replace function private.active_three_v_three_team_id(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select tm.team_id
  from public.three_v_three_team_members tm
  join public.three_v_three_teams t on t.id = tm.team_id
  where tm.profile_id = p_profile_id
    and tm.left_at is null
    and t.status in ('open', 'full', 'closed')
  order by tm.joined_at desc, tm.id desc
  limit 1;
$$;

create or replace function private.owned_active_three_v_three_team_id(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select t.id
  from public.three_v_three_teams t
  where t.owner_profile_id = p_profile_id
    and t.status in ('open', 'full', 'closed')
  order by t.created_at desc, t.id desc
  limit 1;
$$;

create or replace function private.first_available_three_v_three_slot(p_team_id uuid)
returns integer
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select s.slot_number
  from generate_series(2, 3) as s(slot_number)
  where not exists (
    select 1
    from public.three_v_three_team_members tm
    where tm.team_id = p_team_id
      and tm.slot_number = s.slot_number
      and tm.left_at is null
  )
  order by s.slot_number
  limit 1;
$$;

create or replace function private.refresh_three_v_three_team_status(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  team_row public.three_v_three_teams%rowtype;
  active_member_count integer;
begin
  select * into team_row
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or team_row.status in ('closed', 'disbanded') then
    return;
  end if;

  select count(*) into active_member_count
  from public.three_v_three_team_members tm
  where tm.team_id = p_team_id
    and tm.left_at is null;

  update public.three_v_three_teams
  set status = case when active_member_count >= 3 then 'full' else 'open' end,
      updated_at = now()
  where id = p_team_id
    and status <> 'disbanded';
end;
$$;

create or replace function private.build_three_v_three_team_payload(
  p_team_id uuid,
  p_actor_id uuid,
  p_include_profile_ids boolean default false
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  team_row public.three_v_three_teams%rowtype;
  slots_payload jsonb;
  member_count integer;
  empty_slot_count integer;
  actor_is_member boolean;
  actor_is_owner boolean;
  actor_has_pending boolean;
  actor_attempt_count integer;
  actor_last_declined_at timestamptz;
  actor_can_request boolean;
  actor_request_block_reason text;
begin
  select * into team_row
  from public.three_v_three_teams t
  where t.id = p_team_id;

  if not found then
    raise exception '3v3 team not found.';
  end if;

  select count(*) into member_count
  from public.three_v_three_team_members tm
  where tm.team_id = team_row.id
    and tm.left_at is null;

  empty_slot_count := greatest(3 - member_count, 0);

  actor_is_member := exists (
    select 1
    from public.three_v_three_team_members tm
    where tm.team_id = team_row.id
      and tm.profile_id = p_actor_id
      and tm.left_at is null
  );
  actor_is_owner := team_row.owner_profile_id = p_actor_id;
  actor_has_pending := exists (
    select 1
    from public.three_v_three_join_requests r
    where r.team_id = team_row.id
      and r.requester_profile_id = p_actor_id
      and r.status = 'pending'
  );

  select count(*) into actor_attempt_count
  from public.three_v_three_join_requests r
  where r.team_id = team_row.id
    and r.requester_profile_id = p_actor_id;

  select max(coalesce(r.decided_at, r.updated_at)) into actor_last_declined_at
  from public.three_v_three_join_requests r
  where r.team_id = team_row.id
    and r.requester_profile_id = p_actor_id
    and r.status = 'declined';

  actor_request_block_reason := case
    when not private.has_three_v_three_action_access(p_actor_id) then 'not_eligible'
    when team_row.status <> 'open' then team_row.status
    when empty_slot_count <= 0 then 'team_full'
    when actor_is_owner then 'own_team'
    when actor_is_member then 'already_in_team'
    when private.active_three_v_three_team_id(p_actor_id) is not null then 'already_in_team'
    when actor_has_pending then 'already_requested'
    when actor_attempt_count >= 2 then 'max_attempts'
    when actor_last_declined_at is not null
      and actor_last_declined_at > now() - interval '6 hours' then 'cooldown'
    else null
  end;
  actor_can_request := actor_request_block_reason is null;

  with slot_rows as (
    select
      s.slot_number,
      tm.profile_id,
      tm.role,
      tm.combined_cp_snapshot,
      tm.joined_at,
      p.username,
      p.profile_slug,
      p.ign,
      gm.guild_id,
      g.name as guild_name,
      g.slug as guild_slug,
      tvp.discord_username,
      coalesce(avatar.key, default_avatar.key) as avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
      coalesce(frame.key, default_frame.key) as frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path
    from generate_series(1, 3) as s(slot_number)
    left join public.three_v_three_team_members tm
      on tm.team_id = team_row.id
     and tm.slot_number = s.slot_number
     and tm.left_at is null
    left join public.profiles p on p.id = tm.profile_id
    left join public.guild_memberships gm
      on gm.profile_id = tm.profile_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
    left join public.guilds g on g.id = gm.guild_id
    left join public.three_v_three_player_profiles tvp on tvp.profile_id = tm.profile_id
    left join public.profile_equipped_cosmetics pec on pec.profile_id = tm.profile_id
    left join public.cosmetic_catalog avatar
      on avatar.key = pec.avatar_key
     and avatar.type = 'avatar'
     and avatar.is_active = true
    left join public.cosmetic_catalog frame
      on frame.key = pec.frame_key
     and frame.type = 'frame'
     and frame.is_active = true
    left join public.cosmetic_catalog default_avatar
      on default_avatar.key = '1079_head'
     and default_avatar.type = 'avatar'
     and default_avatar.is_active = true
    left join public.cosmetic_catalog default_frame
      on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
     and default_frame.type = 'frame'
     and default_frame.is_active = true
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'slot_number', sr.slot_number,
        'is_empty', sr.profile_id is null,
        'profile_id', case when p_include_profile_ids then sr.profile_id else null end,
        'username', sr.username,
        'profile_slug', sr.profile_slug,
        'ign', sr.ign,
        'guild_id', sr.guild_id,
        'guild_name', sr.guild_name,
        'guild_slug', sr.guild_slug,
        'discord_username', sr.discord_username,
        'combined_cp', sr.combined_cp_snapshot,
        'role', sr.role,
        'joined_at', sr.joined_at,
        'avatar_key', sr.avatar_key,
        'avatar_asset_path', sr.avatar_asset_path,
        'frame_key', sr.frame_key,
        'frame_asset_path', sr.frame_asset_path
      )
      order by sr.slot_number
    ),
    '[]'::jsonb
  )
  into slots_payload
  from slot_rows sr;

  return jsonb_build_object(
    'id', team_row.id,
    'name', team_row.name,
    'status', team_row.status,
    'created_at', team_row.created_at,
    'updated_at', team_row.updated_at,
    'member_count', member_count,
    'empty_slots', empty_slot_count,
    'is_owner', actor_is_owner,
    'is_member', actor_is_member,
    'already_requested', actor_has_pending,
    'can_request', actor_can_request,
    'request_block_reason', actor_request_block_reason,
    'slots', slots_payload
  );
end;
$$;

create or replace function public.update_my_discord_username(p_discord_username text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  normalized_username text := private.normalize_three_v_three_discord_username(p_discord_username);
  updated_row public.three_v_three_player_profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  if normalized_username is not null
     and not private.is_valid_three_v_three_discord_username(normalized_username) then
    raise exception 'Invalid Discord username.';
  end if;

  insert into public.three_v_three_player_profiles (
    profile_id,
    discord_username
  )
  values (
    actor_id,
    normalized_username
  )
  on conflict (profile_id) do update
  set discord_username = excluded.discord_username,
      updated_at = now()
  returning * into updated_row;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_profile_updated',
    'three_v_three_player_profiles',
    actor_id,
    jsonb_build_object('field', 'discord_username', 'has_discord_username', normalized_username is not null)
  );

  return jsonb_build_object(
    'profile_id', updated_row.profile_id,
    'discord_username', updated_row.discord_username,
    'combined_cp', updated_row.combined_cp,
    'updated_at', updated_row.updated_at
  );
end;
$$;

create or replace function public.update_my_3v3_combined_cp(p_combined_cp bigint)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  updated_row public.three_v_three_player_profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  insert into public.three_v_three_player_profiles (
    profile_id,
    combined_cp
  )
  values (
    actor_id,
    p_combined_cp
  )
  on conflict (profile_id) do update
  set combined_cp = excluded.combined_cp,
      updated_at = now()
  returning * into updated_row;

  update public.three_v_three_team_members tm
  set combined_cp_snapshot = p_combined_cp
  where tm.profile_id = actor_id
    and tm.left_at is null;

  update public.three_v_three_join_requests r
  set combined_cp_snapshot = p_combined_cp,
      updated_at = now()
  where r.requester_profile_id = actor_id
    and r.status = 'pending';

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_profile_updated',
    'three_v_three_player_profiles',
    actor_id,
    jsonb_build_object('field', 'combined_cp')
  );

  return jsonb_build_object(
    'profile_id', updated_row.profile_id,
    'discord_username', updated_row.discord_username,
    'combined_cp', updated_row.combined_cp,
    'updated_at', updated_row.updated_at
  );
end;
$$;

create or replace function public.create_3v3_team(
  p_team_name text,
  p_combined_cp bigint
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  normalized_team_name text := nullif(btrim(coalesce(p_team_name, '')), '');
  player_profile public.three_v_three_player_profiles%rowtype;
  new_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_action_access(actor_id) then
    raise exception 'Active 3v3-eligible membership required.';
  end if;

  if normalized_team_name is null or char_length(normalized_team_name) < 3 or char_length(normalized_team_name) > 50 then
    raise exception 'Team name must be between 3 and 50 characters.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  select * into player_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  if not found or player_profile.discord_username is null then
    raise exception 'Discord username is required for 3v3.';
  end if;

  if private.owned_active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You already own an active 3v3 team.';
  end if;

  if private.active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You are already in an active 3v3 team.';
  end if;

  update public.three_v_three_player_profiles
  set combined_cp = p_combined_cp,
      updated_at = now()
  where profile_id = actor_id
  returning * into player_profile;

  insert into public.three_v_three_teams (
    name,
    owner_profile_id,
    status
  )
  values (
    normalized_team_name,
    actor_id,
    'open'
  )
  returning * into new_team;

  insert into public.three_v_three_team_members (
    team_id,
    profile_id,
    slot_number,
    role,
    combined_cp_snapshot
  )
  values (
    new_team.id,
    actor_id,
    1,
    'owner',
    p_combined_cp
  );

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_team_created',
    'three_v_three_teams',
    new_team.id,
    jsonb_build_object(
      'team_id', new_team.id,
      'team_name', new_team.name,
      'combined_cp_public', true
    )
  );

  return private.build_three_v_three_team_payload(new_team.id, actor_id, true);
end;
$$;

create or replace function public.get_3v3_teams()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.three_v_three_player_profiles%rowtype;
  actor_guild_id uuid;
  actor_roster_status text;
  actor_team_id uuid;
  owned_team_id uuid;
  teams_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  select * into actor_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  select gm.guild_id, gm.roster_status
  into actor_guild_id, actor_roster_status
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  actor_team_id := private.active_three_v_three_team_id(actor_id);
  owned_team_id := private.owned_active_three_v_three_team_id(actor_id);

  select coalesce(
    jsonb_agg(
      private.build_three_v_three_team_payload(t.id, actor_id, false)
      order by
        case t.status when 'open' then 1 when 'closed' then 2 when 'full' then 3 else 4 end,
        t.created_at desc,
        t.id desc
    ),
    '[]'::jsonb
  )
  into teams_payload
  from public.three_v_three_teams t
  where t.status <> 'disbanded';

  return jsonb_build_object(
    'viewer',
    jsonb_build_object(
      'profile_id', actor_id,
      'guild_id', actor_guild_id,
      'roster_status', actor_roster_status,
      'can_create_or_request', private.has_three_v_three_action_access(actor_id),
      'active_team_id', actor_team_id,
      'owned_team_id', owned_team_id,
      'discord_username', actor_profile.discord_username,
      'combined_cp', actor_profile.combined_cp
    ),
    'teams', teams_payload
  );
end;
$$;

create or replace function public.get_my_3v3_status()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.three_v_three_player_profiles%rowtype;
  actor_team_id uuid;
  owned_team_id uuid;
  current_team_payload jsonb := null;
  owned_team_payload jsonb := null;
  outgoing_payload jsonb;
  incoming_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  select * into actor_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  actor_team_id := private.active_three_v_three_team_id(actor_id);
  owned_team_id := private.owned_active_three_v_three_team_id(actor_id);

  if actor_team_id is not null then
    current_team_payload := private.build_three_v_three_team_payload(actor_team_id, actor_id, true);
  end if;

  if owned_team_id is not null then
    owned_team_payload := private.build_three_v_three_team_payload(owned_team_id, actor_id, true);
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'team_id', r.team_id,
        'team_name', t.name,
        'team_status', t.status,
        'status', r.status,
        'attempt_number', r.attempt_number,
        'combined_cp', r.combined_cp_snapshot,
        'created_at', r.created_at,
        'updated_at', r.updated_at,
        'decided_at', r.decided_at
      )
      order by r.created_at desc, r.id desc
    ),
    '[]'::jsonb
  )
  into outgoing_payload
  from public.three_v_three_join_requests r
  join public.three_v_three_teams t on t.id = r.team_id
  where r.requester_profile_id = actor_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'team_id', r.team_id,
        'team_name', t.name,
        'status', r.status,
        'attempt_number', r.attempt_number,
        'combined_cp', r.combined_cp_snapshot,
        'created_at', r.created_at,
        'updated_at', r.updated_at,
        'requester_profile_id', r.requester_profile_id,
        'requester_username', p.username,
        'requester_profile_slug', p.profile_slug,
        'requester_ign', p.ign,
        'requester_discord_username', tvp.discord_username,
        'requester_avatar_key', coalesce(avatar.key, default_avatar.key),
        'requester_avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
        'requester_frame_key', coalesce(frame.key, default_frame.key),
        'requester_frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path)
      )
      order by r.created_at asc, r.id asc
    ),
    '[]'::jsonb
  )
  into incoming_payload
  from public.three_v_three_join_requests r
  join public.three_v_three_teams t on t.id = r.team_id
  join public.profiles p on p.id = r.requester_profile_id
  left join public.three_v_three_player_profiles tvp on tvp.profile_id = r.requester_profile_id
  left join public.profile_equipped_cosmetics pec on pec.profile_id = r.requester_profile_id
  left join public.cosmetic_catalog avatar
    on avatar.key = pec.avatar_key
   and avatar.type = 'avatar'
   and avatar.is_active = true
  left join public.cosmetic_catalog frame
    on frame.key = pec.frame_key
   and frame.type = 'frame'
   and frame.is_active = true
  left join public.cosmetic_catalog default_avatar
    on default_avatar.key = '1079_head'
   and default_avatar.type = 'avatar'
   and default_avatar.is_active = true
  left join public.cosmetic_catalog default_frame
    on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
   and default_frame.type = 'frame'
   and default_frame.is_active = true
  where t.owner_profile_id = actor_id
    and t.status in ('open', 'full', 'closed')
    and r.status = 'pending';

  return jsonb_build_object(
    'profile',
    jsonb_build_object(
      'profile_id', actor_id,
      'discord_username', actor_profile.discord_username,
      'combined_cp', actor_profile.combined_cp,
      'can_create_or_request', private.has_three_v_three_action_access(actor_id)
    ),
    'current_team', current_team_payload,
    'owned_team', owned_team_payload,
    'outgoing_requests', outgoing_payload,
    'incoming_requests', incoming_payload
  );
end;
$$;

create or replace function public.request_join_3v3_team(
  p_team_id uuid,
  p_combined_cp bigint
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  player_profile public.three_v_three_player_profiles%rowtype;
  target_team public.three_v_three_teams%rowtype;
  attempt_count integer;
  last_declined_at timestamptz;
  new_request public.three_v_three_join_requests%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_action_access(actor_id) then
    raise exception 'Active 3v3-eligible membership required.';
  end if;

  if p_team_id is null then
    raise exception 'Team is required.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  select * into player_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  if not found or player_profile.discord_username is null then
    raise exception 'Discord username is required for 3v3.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.status <> 'open' then
    raise exception 'Team is not accepting requests.';
  end if;

  if target_team.owner_profile_id = actor_id then
    raise exception 'You cannot request to join your own team.';
  end if;

  if private.active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You are already in an active 3v3 team.';
  end if;

  if private.first_available_three_v_three_slot(target_team.id) is null then
    perform private.refresh_three_v_three_team_status(target_team.id);
    raise exception 'Team is full.';
  end if;

  if exists (
    select 1
    from public.three_v_three_join_requests r
    where r.team_id = target_team.id
      and r.requester_profile_id = actor_id
      and r.status = 'pending'
  ) then
    raise exception 'You already have a pending request for this team.';
  end if;

  select count(*) into attempt_count
  from public.three_v_three_join_requests r
  where r.team_id = target_team.id
    and r.requester_profile_id = actor_id;

  if attempt_count >= 2 then
    raise exception 'Request limit reached for this team.';
  end if;

  select max(coalesce(r.decided_at, r.updated_at)) into last_declined_at
  from public.three_v_three_join_requests r
  where r.team_id = target_team.id
    and r.requester_profile_id = actor_id
    and r.status = 'declined';

  if last_declined_at is not null
     and last_declined_at > now() - interval '6 hours' then
    raise exception 'Please wait before requesting this team again.';
  end if;

  update public.three_v_three_player_profiles
  set combined_cp = p_combined_cp,
      updated_at = now()
  where profile_id = actor_id
  returning * into player_profile;

  insert into public.three_v_three_join_requests (
    team_id,
    requester_profile_id,
    combined_cp_snapshot,
    attempt_number
  )
  values (
    target_team.id,
    actor_id,
    p_combined_cp,
    attempt_count + 1
  )
  returning * into new_request;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_team.owner_profile_id,
    actor_guild_id,
    'three_v_three_join_requested',
    'three_v_three_join_requests',
    new_request.id,
    jsonb_build_object('team_id', target_team.id, 'attempt_number', new_request.attempt_number)
  );

  return jsonb_build_object(
    'id', new_request.id,
    'team_id', new_request.team_id,
    'status', new_request.status,
    'attempt_number', new_request.attempt_number,
    'combined_cp', new_request.combined_cp_snapshot,
    'created_at', new_request.created_at
  );
end;
$$;

create or replace function public.cancel_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_request public.three_v_three_join_requests%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  if target_request.requester_profile_id <> actor_id then
    raise exception 'Only the requester can cancel this request.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be cancelled.';
  end if;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  return jsonb_build_object(
    'id', target_request.id,
    'team_id', target_request.team_id,
    'status', target_request.status
  );
end;
$$;

create or replace function public.approve_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  target_request public.three_v_three_join_requests%rowtype;
  target_team public.three_v_three_teams%rowtype;
  target_profile public.three_v_three_player_profiles%rowtype;
  selected_slot integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = target_request.team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can approve requests.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be approved.';
  end if;

  if target_team.status <> 'open' then
    raise exception 'Team is not accepting requests.';
  end if;

  if not private.has_three_v_three_action_access(target_request.requester_profile_id) then
    raise exception 'Requester is no longer eligible for 3v3.';
  end if;

  select * into target_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = target_request.requester_profile_id;

  if not found or target_profile.discord_username is null then
    raise exception 'Requester Discord username is missing.';
  end if;

  if private.active_three_v_three_team_id(target_request.requester_profile_id) is not null then
    raise exception 'Requester is already in an active 3v3 team.';
  end if;

  selected_slot := private.first_available_three_v_three_slot(target_team.id);

  if selected_slot is null then
    perform private.refresh_three_v_three_team_status(target_team.id);
    raise exception 'Team is full.';
  end if;

  insert into public.three_v_three_team_members (
    team_id,
    profile_id,
    slot_number,
    role,
    combined_cp_snapshot
  )
  values (
    target_team.id,
    target_request.requester_profile_id,
    selected_slot,
    'member',
    target_request.combined_cp_snapshot
  );

  update public.three_v_three_join_requests
  set status = 'approved',
      decided_by = actor_id,
      decided_at = now(),
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where requester_profile_id = target_request.requester_profile_id
    and id <> target_request.id
    and status = 'pending';

  perform private.refresh_three_v_three_team_status(target_team.id);

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_request.requester_profile_id,
    actor_guild_id,
    'three_v_three_request_approved',
    'three_v_three_join_requests',
    target_request.id,
    jsonb_build_object('team_id', target_team.id, 'slot_number', selected_slot)
  );

  return jsonb_build_object(
    'request_id', target_request.id,
    'team_id', target_team.id,
    'status', target_request.status,
    'slot_number', selected_slot,
    'team', private.build_three_v_three_team_payload(target_team.id, actor_id, true)
  );
end;
$$;

create or replace function public.decline_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  target_request public.three_v_three_join_requests%rowtype;
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = target_request.team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can decline requests.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be declined.';
  end if;

  update public.three_v_three_join_requests
  set status = 'declined',
      decided_by = actor_id,
      decided_at = now(),
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_request.requester_profile_id,
    actor_guild_id,
    'three_v_three_request_declined',
    'three_v_three_join_requests',
    target_request.id,
    jsonb_build_object('team_id', target_team.id)
  );

  return jsonb_build_object(
    'request_id', target_request.id,
    'team_id', target_team.id,
    'status', target_request.status
  );
end;
$$;

create or replace function public.remove_3v3_member(
  p_team_id uuid,
  p_profile_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  target_team public.three_v_three_teams%rowtype;
  target_member public.three_v_three_team_members%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can remove members.';
  end if;

  if p_profile_id = target_team.owner_profile_id then
    raise exception 'Team owner cannot be removed.';
  end if;

  select * into target_member
  from public.three_v_three_team_members tm
  where tm.team_id = target_team.id
    and tm.profile_id = p_profile_id
    and tm.left_at is null
    and tm.role = 'member'
  for update;

  if not found then
    raise exception 'Team member not found.';
  end if;

  update public.three_v_three_team_members
  set left_at = now(),
      removed_by = actor_id
  where id = target_member.id
  returning * into target_member;

  if target_team.status = 'full' then
    update public.three_v_three_teams
    set status = 'open',
        updated_at = now()
    where id = target_team.id;
  elsif target_team.status = 'open' then
    perform private.refresh_three_v_three_team_status(target_team.id);
  end if;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    actor_guild_id,
    'three_v_three_member_removed',
    'three_v_three_team_members',
    target_member.id,
    jsonb_build_object('team_id', target_team.id, 'slot_number', target_member.slot_number)
  );

  return jsonb_build_object(
    'team_id', target_team.id,
    'removed_profile_id', p_profile_id,
    'status', (select t.status from public.three_v_three_teams t where t.id = target_team.id)
  );
end;
$$;

create or replace function public.disband_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can disband this team.';
  end if;

  update public.three_v_three_teams
  set status = 'disbanded',
      disbanded_at = now(),
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  update public.three_v_three_team_members
  set left_at = coalesce(left_at, now()),
      removed_by = actor_id
  where team_id = target_team.id
    and left_at is null;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where team_id = target_team.id
    and status = 'pending';

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_team_disbanded',
    'three_v_three_teams',
    target_team.id,
    jsonb_build_object('team_id', target_team.id)
  );

  return jsonb_build_object(
    'team_id', target_team.id,
    'status', target_team.status,
    'disbanded_at', target_team.disbanded_at
  );
end;
$$;

create or replace function public.close_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can close this team.';
  end if;

  update public.three_v_three_teams
  set status = 'closed',
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  return private.build_three_v_three_team_payload(target_team.id, actor_id, true);
end;
$$;

create or replace function public.reopen_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_team public.three_v_three_teams%rowtype;
  active_member_count integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can reopen this team.';
  end if;

  select count(*) into active_member_count
  from public.three_v_three_team_members tm
  where tm.team_id = target_team.id
    and tm.left_at is null;

  update public.three_v_three_teams
  set status = case when active_member_count >= 3 then 'full' else 'open' end,
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  return private.build_three_v_three_team_payload(target_team.id, actor_id, true);
end;
$$;

revoke all on function private.prevent_three_v_three_team_identity_update() from public, anon, authenticated;
revoke all on function private.normalize_three_v_three_discord_username(text) from public, anon, authenticated;
revoke all on function private.is_valid_three_v_three_discord_username(text) from public, anon, authenticated;
revoke all on function private.has_three_v_three_view_access(uuid) from public, anon, authenticated;
revoke all on function private.has_three_v_three_action_access(uuid) from public, anon, authenticated;
revoke all on function private.three_v_three_primary_guild_id(uuid) from public, anon, authenticated;
revoke all on function private.active_three_v_three_team_id(uuid) from public, anon, authenticated;
revoke all on function private.owned_active_three_v_three_team_id(uuid) from public, anon, authenticated;
revoke all on function private.first_available_three_v_three_slot(uuid) from public, anon, authenticated;
revoke all on function private.refresh_three_v_three_team_status(uuid) from public, anon, authenticated;
revoke all on function private.build_three_v_three_team_payload(uuid, uuid, boolean) from public, anon, authenticated;

revoke all on function public.update_my_discord_username(text) from public, anon;
revoke all on function public.update_my_3v3_combined_cp(bigint) from public, anon;
revoke all on function public.create_3v3_team(text, bigint) from public, anon;
revoke all on function public.get_3v3_teams() from public, anon;
revoke all on function public.get_my_3v3_status() from public, anon;
revoke all on function public.request_join_3v3_team(uuid, bigint) from public, anon;
revoke all on function public.cancel_3v3_request(uuid) from public, anon;
revoke all on function public.approve_3v3_request(uuid) from public, anon;
revoke all on function public.decline_3v3_request(uuid) from public, anon;
revoke all on function public.remove_3v3_member(uuid, uuid) from public, anon;
revoke all on function public.disband_3v3_team(uuid) from public, anon;
revoke all on function public.close_3v3_team(uuid) from public, anon;
revoke all on function public.reopen_3v3_team(uuid) from public, anon;

grant execute on function public.update_my_discord_username(text) to authenticated;
grant execute on function public.update_my_3v3_combined_cp(bigint) to authenticated;
grant execute on function public.create_3v3_team(text, bigint) to authenticated;
grant execute on function public.get_3v3_teams() to authenticated;
grant execute on function public.get_my_3v3_status() to authenticated;
grant execute on function public.request_join_3v3_team(uuid, bigint) to authenticated;
grant execute on function public.cancel_3v3_request(uuid) to authenticated;
grant execute on function public.approve_3v3_request(uuid) to authenticated;
grant execute on function public.decline_3v3_request(uuid) to authenticated;
grant execute on function public.remove_3v3_member(uuid, uuid) to authenticated;
grant execute on function public.disband_3v3_team(uuid) to authenticated;
grant execute on function public.close_3v3_team(uuid) to authenticated;
grant execute on function public.reopen_3v3_team(uuid) to authenticated;
