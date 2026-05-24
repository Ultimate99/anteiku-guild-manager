-- Anteiku Guild Manager - Own CP rank badge summary
-- Safe RPC for Profile/Dashboard rank visuals. It returns only the caller's
-- own rank/tier keys and never exposes CP values or other members' metadata.

create or replace function public.get_my_cp_rank_summary()
returns table (
  global_rank integer,
  guild_rank integer,
  rank_tier text,
  visual_key text,
  is_ranked boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  actor_roster_status text;
  calculated_global_rank integer;
  calculated_guild_rank integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select gm.guild_id, gm.roster_status
  into actor_guild_id, actor_roster_status
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

  if actor_roster_status not in ('active', 'trial', 'pending_transfer') then
    return query
    select
      null::integer,
      null::integer,
      'unranked'::text,
      'unranked'::text,
      false;
    return;
  end if;

  with ranked as (
    select
      cp.profile_id as ranked_profile_id,
      cp.guild_id as ranked_guild_id,
      row_number() over (
        order by
          cp.cp_value desc,
          lower(coalesce(nullif(btrim(p.ign), ''), p.id::text)) asc,
          p.id asc
      )::integer as global_rank_position,
      row_number() over (
        partition by cp.guild_id
        order by
          cp.cp_value desc,
          lower(coalesce(nullif(btrim(p.ign), ''), p.id::text)) asc,
          p.id asc
      )::integer as guild_rank_position
    from public.member_cp cp
    join public.profiles p on p.id = cp.profile_id
    join public.guilds g on g.id = cp.guild_id
    join public.guild_memberships gm
      on gm.profile_id = cp.profile_id
     and gm.guild_id = cp.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
     and gm.roster_status in ('active', 'trial', 'pending_transfer')
    where p.approval_status = 'approved'
      and g.status = 'active'
  )
  select ranked.global_rank_position, ranked.guild_rank_position
  into calculated_global_rank, calculated_guild_rank
  from ranked
  where ranked.ranked_profile_id = actor_id
    and ranked.ranked_guild_id = actor_guild_id
  limit 1;

  if calculated_global_rank is null then
    return query
    select
      null::integer,
      null::integer,
      'unranked'::text,
      'unranked'::text,
      false;
    return;
  end if;

  return query
  select
    calculated_global_rank,
    calculated_guild_rank,
    case
      when calculated_global_rank = 1 then 'rank_one'
      when calculated_global_rank = 2 then 'rank_two'
      when calculated_global_rank = 3 then 'rank_three'
      when calculated_global_rank between 4 and 5 then 'elite_five'
      when calculated_global_rank between 6 and 10 then 'top_ten'
      when calculated_global_rank between 11 and 25 then 'high_rank'
      else 'ranked_member'
    end,
    case
      when calculated_global_rank = 1 then 'rank_1'
      when calculated_global_rank = 2 then 'rank_2'
      when calculated_global_rank = 3 then 'rank_3'
      when calculated_global_rank between 4 and 5 then 'elite_5'
      when calculated_global_rank between 6 and 10 then 'top_10'
      when calculated_global_rank between 11 and 25 then 'high_rank'
      else 'ranked_member'
    end,
    true;
end;
$$;

revoke all on function public.get_my_cp_rank_summary() from public, anon;
grant execute on function public.get_my_cp_rank_summary() to authenticated;
