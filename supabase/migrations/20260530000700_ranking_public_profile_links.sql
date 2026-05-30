-- Anteiku Guild Manager - Ranking public profile links
-- Safe migration: extends the member-safe CP ranking RPC with profile_slug
-- only so ranked members can link to authenticated public profiles. Member
-- ranking responses still do not expose CP values, profile ids, usernames,
-- timestamps, snapshots, growth, history, or private CP metadata.

drop function if exists public.get_member_cp_rankings(text);

create or replace function public.get_member_cp_rankings(p_scope text default 'guild')
returns table (
  rank integer,
  ign text,
  profile_slug text,
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
      p.profile_slug as member_profile_slug,
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
    ranked.member_profile_slug,
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

revoke all on function public.get_member_cp_rankings(text) from public, anon;
grant execute on function public.get_member_cp_rankings(text) to authenticated;
