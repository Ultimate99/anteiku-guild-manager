-- Anteiku Guild Manager - Live CP Growth baseline scope fix
-- Allows Owner-selected global baselines to be reused while filtering live
-- growth rows to a selected guild scope. No snapshots or CP values are mutated.

create or replace function public.get_admin_live_cp_growth(
  p_guild_id uuid,
  p_baseline_batch_id uuid
)
returns table (
  has_baseline boolean,
  baseline_batch_id uuid,
  baseline_captured_at timestamptz,
  baseline_label text,
  baseline_week_start date,
  baseline_week_end date,
  reset_day_of_week integer,
  reset_day_label text,
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  baseline_cp integer,
  current_cp integer,
  growth_amount integer,
  growth_percent numeric,
  last_updated timestamptz,
  missing_baseline boolean,
  missing_current_cp boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  requested_baseline_id uuid := p_baseline_batch_id;
  scoped_guild_name text;
  baseline_batch public.cp_snapshot_batches%rowtype;
  v_reset_day integer := 0;
  v_reset_day_label text := 'Sunday';
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global live CP growth.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view live CP growth.';
  end if;

  if requested_baseline_id is not null then
    select * into baseline_batch
    from public.cp_snapshot_batches b
    where b.id = requested_baseline_id;

    if not found then
      raise exception 'Selected baseline was not found.';
    end if;

    if scoped_guild_id is null and baseline_batch.guild_id is not null then
      raise exception 'Selected baseline is not available for this analytics scope.';
    end if;

    if scoped_guild_id is not null
       and baseline_batch.guild_id is not null
       and baseline_batch.guild_id <> scoped_guild_id then
      raise exception 'Selected baseline is not available for this analytics scope.';
    end if;

    if scoped_guild_id is not null
       and baseline_batch.guild_id is null
       and not private.is_owner(actor_id) then
      raise exception 'Only Owner can use a global baseline for guild analytics.';
    end if;
  else
    select * into baseline_batch
    from public.cp_snapshot_batches b
    where b.guild_id is not distinct from scoped_guild_id
    order by b.captured_at desc, b.id desc
    limit 1;
  end if;

  if baseline_batch.id is null then
    return query
    select
      false,
      null::uuid,
      null::timestamptz,
      null::text,
      null::date,
      null::date,
      v_reset_day,
      v_reset_day_label,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      scoped_guild_id,
      scoped_guild_name,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false,
      false;
    return;
  end if;

  return query
  with eligible_members as (
    select
      gm.profile_id,
      gm.guild_id,
      p.username,
      p.ign,
      g.name as guild_name
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    join public.guilds g on g.id = gm.guild_id
    where (scoped_guild_id is null or gm.guild_id = scoped_guild_id)
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
      and g.status = 'active'
  ),
  growth_rows as (
    select
      em.profile_id,
      em.username,
      em.ign,
      em.guild_id,
      em.guild_name,
      baseline.cp_value as baseline_cp,
      cp.cp_value as current_cp,
      case
        when baseline.cp_value is null or cp.cp_value is null then null
        else cp.cp_value - baseline.cp_value
      end as growth_amount,
      case
        when baseline.cp_value is null
          or cp.cp_value is null
          or baseline.cp_value = 0 then null
        else round(((cp.cp_value - baseline.cp_value)::numeric / baseline.cp_value::numeric) * 100, 2)
      end as growth_percent,
      cp.updated_at as last_updated,
      (baseline.id is null) as missing_baseline,
      (cp.profile_id is null) as missing_current_cp
    from eligible_members em
    left join public.member_cp cp
      on cp.profile_id = em.profile_id
     and cp.guild_id = em.guild_id
    left join public.cp_snapshot_entries baseline
      on baseline.batch_id = baseline_batch.id
     and baseline.profile_id = em.profile_id
     and baseline.guild_id = em.guild_id
  ),
  ranked_rows as (
    select
      gr.*,
      row_number() over (
        order by gr.growth_amount desc nulls last, lower(coalesce(gr.ign, gr.username, gr.profile_id::text)) asc, gr.profile_id asc
      )::integer as rank_position
    from growth_rows gr
  )
  select
    true,
    baseline_batch.id,
    baseline_batch.captured_at,
    baseline_batch.label,
    baseline_batch.week_start,
    baseline_batch.week_end,
    v_reset_day,
    v_reset_day_label,
    rr.rank_position,
    rr.profile_id,
    rr.username,
    rr.ign,
    rr.guild_id,
    rr.guild_name,
    rr.baseline_cp,
    rr.current_cp,
    rr.growth_amount,
    rr.growth_percent,
    rr.last_updated,
    rr.missing_baseline,
    rr.missing_current_cp
  from ranked_rows rr
  order by rr.rank_position;
end;
$$;

revoke all on function public.get_admin_live_cp_growth(uuid, uuid) from public, anon;
grant execute on function public.get_admin_live_cp_growth(uuid, uuid) to authenticated;
