-- Anteiku Guild Manager - CP Ranking cosmetic display fields
-- Safe migration: extends CP ranking RPCs with approved static avatar/frame
-- display metadata only. Member ranking responses still do not expose CP values,
-- profile ids, usernames, timestamps, snapshots, growth, history, or private CP
-- metadata.

drop function if exists public.get_member_cp_rankings(text);
drop function if exists public.get_admin_cp_rankings(uuid, text);

create or replace function public.get_member_cp_rankings(p_scope text default 'guild')
returns table (
  rank integer,
  ign text,
  guild_name text,
  guild_slug text,
  is_current_user boolean,
  avatar_key text,
  avatar_asset_path text,
  frame_key text,
  frame_asset_path text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_scope text := lower(btrim(coalesce(p_scope, 'guild')));
  actor_guild_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if normalized_scope not in ('guild', 'global') then
    raise exception 'Invalid ranking scope.';
  end if;

  select gm.guild_id
  into actor_guild_id
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and p.approval_status = 'approved'
  limit 1;

  if actor_guild_id is null then
    raise exception 'Active approved membership required.';
  end if;

  return query
  with ranked as (
    select
      row_number() over (
        order by
          cp.cp_value desc,
          lower(coalesce(nullif(btrim(p.ign), ''), p.id::text)) asc,
          p.id asc
      )::integer as rank_position,
      p.ign as member_ign,
      g.name as member_guild_name,
      g.slug as member_guild_slug,
      (p.id = actor_id) as current_user,
      coalesce(avatar.key, default_avatar.key) as display_avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as display_avatar_asset_path,
      coalesce(frame.key, default_frame.key) as display_frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as display_frame_asset_path
    from public.member_cp cp
    join public.profiles p on p.id = cp.profile_id
    join public.guilds g on g.id = cp.guild_id
    join public.guild_memberships gm
      on gm.profile_id = cp.profile_id
     and gm.guild_id = cp.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
     and gm.roster_status in ('active', 'trial', 'pending_transfer')
    left join public.profile_equipped_cosmetics pec
      on pec.profile_id = p.id
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
    where p.approval_status = 'approved'
      and g.status = 'active'
      and (normalized_scope = 'global' or cp.guild_id = actor_guild_id)
  )
  select
    ranked.rank_position,
    ranked.member_ign,
    case when normalized_scope = 'global' then ranked.member_guild_name else null end,
    case when normalized_scope = 'global' then ranked.member_guild_slug else null end,
    ranked.current_user,
    ranked.display_avatar_key,
    ranked.display_avatar_asset_path,
    ranked.display_frame_key,
    ranked.display_frame_asset_path
  from ranked
  order by ranked.rank_position;
end;
$$;

create or replace function public.get_admin_cp_rankings(
  p_guild_id uuid default null,
  p_scope text default 'guild'
)
returns table (
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  guild_slug text,
  cp_value integer,
  updated_at timestamptz,
  avatar_key text,
  avatar_asset_path text,
  frame_key text,
  frame_asset_path text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_scope text := lower(btrim(coalesce(p_scope, 'guild')));
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if normalized_scope not in ('guild', 'global') then
    raise exception 'Invalid ranking scope.';
  end if;

  if normalized_scope = 'guild' then
    if p_guild_id is null then
      raise exception 'Guild is required for guild CP rankings.';
    end if;

    if not exists (select 1 from public.guilds g where g.id = p_guild_id) then
      raise exception 'Guild not found.';
    end if;

    if not private.can_view_cp(actor_id, p_guild_id) then
      raise exception 'Not authorized to view CP rankings for this guild.';
    end if;
  elsif not private.is_owner(actor_id) then
    raise exception 'Only Owner can view global CP rankings.';
  end if;

  return query
  with ranked as (
    select
      row_number() over (
        order by
          cp.cp_value desc,
          lower(coalesce(nullif(btrim(p.ign), ''), p.username, p.id::text)) asc,
          p.id asc
      )::integer as rank_position,
      p.id as ranked_profile_id,
      p.username as ranked_username,
      p.ign as ranked_ign,
      g.id as ranked_guild_id,
      g.name as ranked_guild_name,
      g.slug as ranked_guild_slug,
      cp.cp_value as ranked_cp_value,
      cp.updated_at as ranked_updated_at,
      coalesce(avatar.key, default_avatar.key) as display_avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as display_avatar_asset_path,
      coalesce(frame.key, default_frame.key) as display_frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as display_frame_asset_path
    from public.member_cp cp
    join public.profiles p on p.id = cp.profile_id
    join public.guilds g on g.id = cp.guild_id
    join public.guild_memberships gm
      on gm.profile_id = cp.profile_id
     and gm.guild_id = cp.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
     and gm.roster_status in ('active', 'trial', 'pending_transfer')
    left join public.profile_equipped_cosmetics pec
      on pec.profile_id = p.id
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
    where p.approval_status = 'approved'
      and g.status = 'active'
      and (normalized_scope = 'global' or cp.guild_id = p_guild_id)
  )
  select
    ranked.rank_position,
    ranked.ranked_profile_id,
    ranked.ranked_username,
    ranked.ranked_ign,
    ranked.ranked_guild_id,
    ranked.ranked_guild_name,
    ranked.ranked_guild_slug,
    ranked.ranked_cp_value,
    ranked.ranked_updated_at,
    ranked.display_avatar_key,
    ranked.display_avatar_asset_path,
    ranked.display_frame_key,
    ranked.display_frame_asset_path
  from ranked
  order by ranked.rank_position;
end;
$$;

revoke all on function public.get_member_cp_rankings(text) from public, anon;
revoke all on function public.get_admin_cp_rankings(uuid, text) from public, anon;

grant execute on function public.get_member_cp_rankings(text) to authenticated;
grant execute on function public.get_admin_cp_rankings(uuid, text) to authenticated;
