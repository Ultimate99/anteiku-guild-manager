-- Anteiku Guild Manager - Public Member Profiles + Profile Reactions backend
-- Authenticated in-app public profiles only. No unauthenticated public internet
-- profile access is introduced. Normal protected CP tables/RPCs are not read
-- or exposed.

create table if not exists public.profile_reactions (
  id uuid primary key default gen_random_uuid(),
  target_profile_id uuid not null references public.profiles(id) on delete cascade,
  reactor_profile_id uuid not null references public.profiles(id) on delete cascade,
  reaction_type text not null,
  created_at timestamptz not null default now(),
  constraint profile_reactions_type_chk check (
    reaction_type in ('like', 'fire', 'coffee', 'skull', 'trophy')
  ),
  constraint profile_reactions_no_self_chk check (target_profile_id <> reactor_profile_id)
);

create unique index if not exists profile_reactions_one_per_type_uidx
  on public.profile_reactions (target_profile_id, reactor_profile_id, reaction_type);

create index if not exists profile_reactions_target_type_idx
  on public.profile_reactions (target_profile_id, reaction_type, created_at desc);

create index if not exists profile_reactions_reactor_idx
  on public.profile_reactions (reactor_profile_id, created_at desc);

alter table public.profile_reactions enable row level security;

revoke all on public.profile_reactions from public, anon, authenticated;

create or replace function private.has_public_profile_view_access(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_profile_id)
    or exists (
      select 1
      from public.guild_memberships gm
      join public.profiles p on p.id = gm.profile_id
      join public.guilds g on g.id = gm.guild_id
      where gm.profile_id = p_profile_id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
        and p.approval_status = 'approved'
        and g.status = 'active'
        and g.is_core = true
    );
$$;

create or replace function private.has_public_profile_reaction_access(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_profile_id)
    or exists (
      select 1
      from public.guild_memberships gm
      join public.profiles p on p.id = gm.profile_id
      join public.guilds g on g.id = gm.guild_id
      where gm.profile_id = p_profile_id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and gm.roster_status in ('active', 'trial', 'pending_transfer')
        and p.approval_status = 'approved'
        and g.status = 'active'
        and g.is_core = true
    );
$$;

create or replace function private.is_public_profile_viewable(p_profile_id uuid)
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
    join public.guilds g on g.id = gm.guild_id
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
      and p.approval_status = 'approved'
      and g.status = 'active'
      and g.is_core = true
  );
$$;

create or replace function private.normalize_public_profile_reaction_type(p_reaction_type text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select nullif(lower(btrim(coalesce(p_reaction_type, ''))), '');
$$;

create or replace function private.is_public_profile_reaction_type(p_reaction_type text)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select p_reaction_type in ('like', 'fire', 'coffee', 'skull', 'trophy');
$$;

create or replace function public.get_public_member_profile(p_profile_slug text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  target_profile record;
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_public_profile_view_access(actor_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Public profile not found.';
  end if;

  select
    p.id,
    p.username,
    p.profile_slug,
    p.ign,
    gm.guild_id,
    g.name as guild_name,
    g.slug as guild_slug,
    gm.role,
    gm.roster_status,
    coalesce(avatar.key, default_avatar.key) as avatar_key,
    coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
    coalesce(frame.key, default_frame.key) as frame_key,
    coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path,
    tvp.combined_cp as three_v_three_combined_cp
  into target_profile
  from public.profiles p
  join public.guild_memberships gm
    on gm.profile_id = p.id
   and gm.membership_status = 'active'
   and gm.is_primary = true
   and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
  join public.guilds g
    on g.id = gm.guild_id
   and g.status = 'active'
   and g.is_core = true
  left join public.profile_equipped_cosmetics pec on pec.profile_id = p.id
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
  left join public.three_v_three_player_profiles tvp on tvp.profile_id = p.id
  where p.approval_status = 'approved'
    and (p.profile_slug = normalized_slug or p.username = normalized_slug)
  order by gm.created_at desc
  limit 1;

  if not found then
    raise exception 'Public profile not found.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'type', reaction_types.reaction_type,
        'count', coalesce(reaction_counts.reaction_count, 0),
        'reacted_by_me', exists (
          select 1
          from public.profile_reactions pr_self
          where pr_self.target_profile_id = target_profile.id
            and pr_self.reactor_profile_id = actor_id
            and pr_self.reaction_type = reaction_types.reaction_type
        )
      )
      order by reaction_types.sort_order
    ),
    '[]'::jsonb
  )
  into reactions_payload
  from (
    values
      ('like'::text, 1),
      ('fire'::text, 2),
      ('coffee'::text, 3),
      ('skull'::text, 4),
      ('trophy'::text, 5)
  ) as reaction_types(reaction_type, sort_order)
  left join lateral (
    select count(*)::bigint as reaction_count
    from public.profile_reactions pr
    where pr.target_profile_id = target_profile.id
      and pr.reaction_type = reaction_types.reaction_type
  ) reaction_counts on true;

  return jsonb_build_object(
    'viewer',
    jsonb_build_object(
      'is_self', target_profile.id = actor_id,
      'can_react', target_profile.id <> actor_id
        and private.has_public_profile_reaction_access(actor_id)
    ),
    'profile',
    jsonb_build_object(
      'profile_id', target_profile.id,
      'username', target_profile.username,
      'profile_slug', target_profile.profile_slug,
      'ign', target_profile.ign,
      'guild_id', target_profile.guild_id,
      'guild_name', target_profile.guild_name,
      'guild_slug', target_profile.guild_slug,
      'role_label', case target_profile.role
        when 'owner' then 'Owner'
        when 'leader' then 'Leader'
        when 'vice' then 'Vice'
        when 'admin' then 'Admin'
        else 'Member'
      end,
      'roster_status', target_profile.roster_status,
      'avatar_key', target_profile.avatar_key,
      'avatar_asset_path', target_profile.avatar_asset_path,
      'frame_key', target_profile.frame_key,
      'frame_asset_path', target_profile.frame_asset_path,
      'ghoul_rep', private.get_profile_ghoul_rep(target_profile.id),
      'three_v_three_combined_cp', target_profile.three_v_three_combined_cp,
      'reactions', reactions_payload
    )
  );
end;
$$;

create or replace function public.react_to_public_profile(
  p_target_profile_id uuid,
  p_reaction_type text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_public_profile_reaction_access(actor_id) then
    raise exception 'Active member access required to react.';
  end if;

  if not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  if p_target_profile_id = actor_id then
    raise exception 'Self profile reactions are not allowed.';
  end if;

  insert into public.profile_reactions (
    target_profile_id,
    reactor_profile_id,
    reaction_type
  )
  values (
    p_target_profile_id,
    actor_id,
    normalized_reaction_type
  )
  on conflict (target_profile_id, reactor_profile_id, reaction_type) do nothing;

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'reacted_by_me', true
  );
end;
$$;

create or replace function public.remove_public_profile_reaction(
  p_target_profile_id uuid,
  p_reaction_type text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
  deleted_count integer := 0;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_public_profile_view_access(actor_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  delete from public.profile_reactions
  where target_profile_id = p_target_profile_id
    and reactor_profile_id = actor_id
    and reaction_type = normalized_reaction_type;

  get diagnostics deleted_count = row_count;

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'removed', deleted_count > 0
  );
end;
$$;

create or replace function public.get_public_profile_reaction_details(
  p_target_profile_id uuid,
  p_reaction_type text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_reaction_type text := private.normalize_public_profile_reaction_type(p_reaction_type);
  reactions_payload jsonb := '[]'::jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_public_profile_view_access(actor_id) then
    raise exception 'Approved member access required.';
  end if;

  if not private.is_public_profile_viewable(p_target_profile_id) then
    raise exception 'Public profile not found.';
  end if;

  if normalized_reaction_type is not null
     and not private.is_public_profile_reaction_type(normalized_reaction_type) then
    raise exception 'Unsupported profile reaction type.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'reaction_type', pr.reaction_type,
        'username', reactor.username,
        'profile_slug', reactor.profile_slug,
        'ign', reactor.ign,
        'guild_name', reactor_guild.guild_name,
        'guild_slug', reactor_guild.guild_slug,
        'avatar_key', coalesce(avatar.key, default_avatar.key),
        'avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
        'frame_key', coalesce(frame.key, default_frame.key),
        'frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path),
        'reacted_at', pr.created_at
      )
      order by pr.reaction_type, pr.created_at desc
    ),
    '[]'::jsonb
  )
  into reactions_payload
  from public.profile_reactions pr
  join public.profiles reactor on reactor.id = pr.reactor_profile_id
  join lateral (
    select g.name as guild_name, g.slug as guild_slug
    from public.guild_memberships gm
    join public.guilds g on g.id = gm.guild_id
    where gm.profile_id = reactor.id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer', 'inactive', 'on_break')
      and g.status = 'active'
      and g.is_core = true
    order by gm.created_at desc
    limit 1
  ) reactor_guild on true
  left join public.profile_equipped_cosmetics pec on pec.profile_id = reactor.id
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
  where pr.target_profile_id = p_target_profile_id
    and reactor.approval_status = 'approved'
    and (normalized_reaction_type is null or pr.reaction_type = normalized_reaction_type);

  return jsonb_build_object(
    'reaction_type', normalized_reaction_type,
    'reactions', reactions_payload
  );
end;
$$;

revoke all on function private.has_public_profile_view_access(uuid) from public, anon, authenticated;
revoke all on function private.has_public_profile_reaction_access(uuid) from public, anon, authenticated;
revoke all on function private.is_public_profile_viewable(uuid) from public, anon, authenticated;
revoke all on function private.normalize_public_profile_reaction_type(text) from public, anon, authenticated;
revoke all on function private.is_public_profile_reaction_type(text) from public, anon, authenticated;

revoke all on function public.get_public_member_profile(text) from public, anon;
revoke all on function public.react_to_public_profile(uuid, text) from public, anon;
revoke all on function public.remove_public_profile_reaction(uuid, text) from public, anon;
revoke all on function public.get_public_profile_reaction_details(uuid, text) from public, anon;

grant execute on function public.get_public_member_profile(text) to authenticated;
grant execute on function public.react_to_public_profile(uuid, text) to authenticated;
grant execute on function public.remove_public_profile_reaction(uuid, text) to authenticated;
grant execute on function public.get_public_profile_reaction_details(uuid, text) to authenticated;
