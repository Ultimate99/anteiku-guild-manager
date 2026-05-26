-- Anteiku Guild Manager - Live CP Growth
-- Safe migration: adds RPC-only live Weekly Growth reporting against the
-- latest baseline snapshot. Members still cannot access CP analytics, growth,
-- snapshots, or other members' CP.

create or replace function public.start_new_cp_growth_period(
  p_guild_id uuid default null,
  p_label text default null
)
returns table (
  batch_id uuid,
  guild_id uuid,
  captured_at timestamptz,
  captured_count integer,
  week_start date,
  week_end date,
  reset_day_of_week integer,
  reset_day_label text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
  new_batch public.cp_snapshot_batches%rowtype;
  inserted_count integer;
  v_reset_day integer := 0;
  v_reset_day_label text := 'Sunday';
  v_captured_at timestamptz := clock_timestamp();
  v_local_today date := (clock_timestamp() at time zone 'Europe/Belgrade')::date;
  v_week_start date;
  v_week_end date;
  v_label text := nullif(trim(p_label), '');
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  v_week_start := v_local_today - (((extract(dow from v_local_today)::integer - v_reset_day + 7) % 7));
  v_week_end := v_week_start + 6;

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
      raise exception 'Only Owner can start a global CP growth period.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to start CP growth period.';
  end if;

  insert into public.cp_snapshot_batches (
    guild_id,
    captured_by,
    captured_at,
    week_start,
    week_end,
    label
  )
  values (
    scoped_guild_id,
    actor_id,
    v_captured_at,
    v_week_start,
    v_week_end,
    coalesce(
      v_label,
      case
        when scoped_guild_id is null then 'Global CP week baseline ' || v_week_start::text
        else scoped_guild_name || ' CP week baseline ' || v_week_start::text
      end
    )
  )
  returning * into new_batch;

  insert into public.cp_snapshot_entries (
    batch_id,
    profile_id,
    guild_id,
    cp_value,
    member_cp_updated_at,
    captured_by,
    captured_at
  )
  select
    new_batch.id,
    cp.profile_id,
    cp.guild_id,
    cp.cp_value,
    cp.updated_at,
    actor_id,
    new_batch.captured_at
  from public.member_cp cp
  join public.guild_memberships gm
    on gm.profile_id = cp.profile_id
   and gm.guild_id = cp.guild_id
   and gm.membership_status = 'active'
   and gm.is_primary = true
   and gm.roster_status in ('active', 'trial', 'pending_transfer')
  join public.profiles p
    on p.id = cp.profile_id
   and p.approval_status = 'approved'
  join public.guilds g
    on g.id = cp.guild_id
   and g.status = 'active'
  where scoped_guild_id is null or cp.guild_id = scoped_guild_id;

  get diagnostics inserted_count = row_count;

  perform private.write_audit_log(
    actor_id,
    null,
    scoped_guild_id,
    'weekly_cp_snapshot_captured',
    'cp_snapshot_batches',
    new_batch.id,
    jsonb_build_object(
      'batch_id', new_batch.id,
      'guild_id', scoped_guild_id,
      'rows_affected', inserted_count,
      'week_start', v_week_start,
      'week_end', v_week_end,
      'reset_day_of_week', v_reset_day,
      'reset_day_label', v_reset_day_label,
      'scope', case when scoped_guild_id is null then 'global' else 'guild' end
    )
  );

  return query
  select
    new_batch.id,
    new_batch.guild_id,
    new_batch.captured_at,
    inserted_count,
    new_batch.week_start,
    new_batch.week_end,
    v_reset_day,
    v_reset_day_label;
end;
$$;

create or replace function public.capture_weekly_cp_snapshot(p_guild_id uuid default null)
returns table (
  batch_id uuid,
  guild_id uuid,
  captured_at timestamptz,
  captured_count integer
)
language sql
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select
    period.batch_id,
    period.guild_id,
    period.captured_at,
    period.captured_count
  from public.start_new_cp_growth_period(p_guild_id, null) period;
$$;

create or replace function public.get_admin_live_cp_growth(p_guild_id uuid default null)
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

  select * into baseline_batch
  from public.cp_snapshot_batches b
  where b.guild_id is not distinct from scoped_guild_id
  order by b.captured_at desc, b.id desc
  limit 1;

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

revoke all on function public.start_new_cp_growth_period(uuid, text) from public, anon;
revoke all on function public.get_admin_live_cp_growth(uuid) from public, anon;
revoke all on function public.capture_weekly_cp_snapshot(uuid) from public, anon;

grant execute on function public.start_new_cp_growth_period(uuid, text) to authenticated;
grant execute on function public.get_admin_live_cp_growth(uuid) to authenticated;
grant execute on function public.capture_weekly_cp_snapshot(uuid) to authenticated;
