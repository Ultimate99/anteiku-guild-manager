-- Anteiku Guild Manager - Admin Analytics Backend Foundation
-- Safe migration: adds RPC-only AdminPanel analytics and weekly CP growth
-- snapshot batches. Members still cannot access admin analytics, CP analytics,
-- CP snapshots, or other members' CP.

create table if not exists public.cp_snapshot_batches (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid references public.guilds(id) on delete restrict,
  captured_by uuid not null references public.profiles(id) on delete restrict,
  captured_at timestamptz not null default now(),
  week_start date,
  week_end date,
  label text,
  note text,
  created_at timestamptz not null default now(),
  constraint cp_snapshot_batches_week_order_chk check (
    week_start is null
    or week_end is null
    or week_end >= week_start
  ),
  constraint cp_snapshot_batches_label_length_chk check (
    label is null
    or char_length(label) <= 160
  ),
  constraint cp_snapshot_batches_note_length_chk check (
    note is null
    or char_length(note) <= 1000
  )
);

create table if not exists public.cp_snapshot_entries (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.cp_snapshot_batches(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  cp_value integer not null,
  member_cp_updated_at timestamptz,
  captured_by uuid not null references public.profiles(id) on delete restrict,
  captured_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint cp_snapshot_entries_value_nonnegative_chk check (cp_value >= 0)
);

create unique index if not exists cp_snapshot_entries_batch_profile_guild_uidx
  on public.cp_snapshot_entries (batch_id, profile_id, guild_id);

create index if not exists cp_snapshot_batches_guild_captured_idx
  on public.cp_snapshot_batches (guild_id, captured_at desc);

create index if not exists cp_snapshot_batches_captured_idx
  on public.cp_snapshot_batches (captured_at desc);

create index if not exists cp_snapshot_entries_batch_idx
  on public.cp_snapshot_entries (batch_id);

create index if not exists cp_snapshot_entries_guild_profile_idx
  on public.cp_snapshot_entries (guild_id, profile_id);

alter table public.cp_snapshot_batches enable row level security;
alter table public.cp_snapshot_entries enable row level security;

revoke all on public.cp_snapshot_batches from public, anon, authenticated;
revoke all on public.cp_snapshot_entries from public, anon, authenticated;

create or replace function private.can_view_member_analytics(p_actor_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or (
      p_guild_id is not null
      and (
        private.has_role(p_actor_id, p_guild_id, array['leader', 'vice'])
        or private.has_permission(p_actor_id, p_guild_id, 'manage_members')
        or private.has_permission(p_actor_id, p_guild_id, 'approve_members')
        or private.has_permission(p_actor_id, p_guild_id, 'manage_roles')
      )
    );
$$;

create or replace function public.get_admin_member_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  total_members bigint,
  active_members bigint,
  trial_members bigint,
  pending_transfer_members bigint,
  inactive_members bigint,
  on_break_members bigint,
  suspended_members bigint,
  left_members bigint,
  kicked_members bigint,
  pending_approvals bigint,
  members_by_guild jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
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

  if not private.is_owner(actor_id) and scoped_guild_id is null then
    raise exception 'Guild scope is required.';
  end if;

  if not private.can_view_member_analytics(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view member analytics.';
  end if;

  return query
  with scoped_memberships as (
    select gm.*, p.approval_status, g.name as guild_name, g.slug as guild_slug
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    join public.guilds g on g.id = gm.guild_id
    where (scoped_guild_id is null or gm.guild_id = scoped_guild_id)
      and g.status = 'active'
  ),
  approved_memberships as (
    select *
    from scoped_memberships sm
    where sm.approval_status = 'approved'
  ),
  guild_breakdown as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'guild_id', guild_rows.guild_id,
          'guild_name', guild_rows.guild_name,
          'guild_slug', guild_rows.guild_slug,
          'total_members', guild_rows.total_members,
          'active_members', guild_rows.active_members,
          'pending_approvals', guild_rows.pending_approvals
        )
        order by guild_rows.guild_name
      ),
      '[]'::jsonb
    ) as payload
    from (
      select
        sm.guild_id,
        sm.guild_name,
        sm.guild_slug,
        count(*) filter (where sm.approval_status = 'approved') as total_members,
        count(*) filter (
          where sm.approval_status = 'approved'
            and sm.membership_status = 'active'
            and sm.roster_status = 'active'
        ) as active_members,
        count(*) filter (
          where sm.approval_status = 'pending'
            or sm.membership_status = 'pending'
        ) as pending_approvals
      from scoped_memberships sm
      group by sm.guild_id, sm.guild_name, sm.guild_slug
    ) guild_rows
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    count(*) filter (where am.approval_status = 'approved'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'active'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'trial'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'pending_transfer'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'inactive'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'on_break'),
    count(*) filter (where am.membership_status = 'suspended' or am.roster_status = 'suspended'),
    count(*) filter (where am.membership_status = 'left' or am.roster_status = 'left'),
    count(*) filter (where am.roster_status = 'kicked'),
    (
      select count(*)
      from scoped_memberships sm
      where sm.approval_status = 'pending'
        or sm.membership_status = 'pending'
    ),
    (select gb.payload from guild_breakdown gb)
  from approved_memberships am;
end;
$$;

create or replace function public.get_admin_cp_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  total_cp bigint,
  average_cp numeric,
  highest_cp integer,
  lowest_cp integer,
  members_missing_cp bigint,
  recently_updated_cp_count bigint,
  cp_update_window_status text,
  cp_update_window_id uuid,
  cp_update_window_updated_at timestamptz,
  open_cp_window_count bigint,
  self_submitted_count bigint,
  recently_updated_members jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
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

  if not private.is_owner(actor_id) and scoped_guild_id is null then
    raise exception 'Guild scope is required.';
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global CP analytics.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP analytics.';
  end if;

  return query
  with eligible_members as (
    select gm.profile_id, gm.guild_id, p.username, p.ign, g.name as guild_name
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
  cp_scope as (
    select em.*, cp.cp_value, cp.updated_at, cp.updated_by
    from eligible_members em
    left join public.member_cp cp
      on cp.profile_id = em.profile_id
     and cp.guild_id = em.guild_id
  ),
  latest_window as (
    select w.*
    from public.cp_update_windows w
    where scoped_guild_id is not null
      and w.guild_id = scoped_guild_id
    order by (w.status = 'open') desc, w.updated_at desc, w.created_at desc, w.id desc
    limit 1
  ),
  updated_members as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'profile_id', ranked.profile_id,
          'username', ranked.username,
          'ign', ranked.ign,
          'guild_id', ranked.guild_id,
          'guild_name', ranked.guild_name,
          'cp_value', ranked.cp_value,
          'updated_at', ranked.updated_at
        )
        order by ranked.updated_at desc
      ),
      '[]'::jsonb
    ) as payload
    from (
      select *
      from cp_scope cs
      where cs.cp_value is not null
      order by cs.updated_at desc nulls last, cs.ign asc
      limit 10
    ) ranked
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    coalesce(sum(cs.cp_value), 0)::bigint,
    round(avg(cs.cp_value), 2),
    max(cs.cp_value),
    min(cs.cp_value),
    count(*) filter (where cs.cp_value is null),
    count(*) filter (where cs.updated_at >= now() - interval '7 days'),
    case
      when scoped_guild_id is null and exists (
        select 1 from public.cp_update_windows w where w.status = 'open'
      ) then 'open'
      when scoped_guild_id is null then 'closed'
      else coalesce((select lw.status from latest_window lw), 'closed')
    end,
    (select lw.id from latest_window lw),
    (select lw.updated_at from latest_window lw),
    (
      select count(*)
      from public.cp_update_windows w
      where w.status = 'open'
        and (scoped_guild_id is null or w.guild_id = scoped_guild_id)
    ),
    (
      select count(*)
      from public.audit_logs al
      where al.action = 'member_cp_self_submitted'
        and al.created_at >= now() - interval '7 days'
        and (scoped_guild_id is null or al.guild_id = scoped_guild_id)
    ),
    (select um.payload from updated_members um)
  from cp_scope cs;
end;
$$;

create or replace function public.get_admin_gvg_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  latest_event_id uuid,
  latest_event_title text,
  latest_event_scope text,
  latest_event_status text,
  latest_event_guild_id uuid,
  latest_event_guild_name text,
  starts_at timestamptz,
  ends_at timestamptz,
  present_count bigint,
  absent_count bigint,
  no_vote_count bigint,
  eligible_count bigint,
  participation_percent numeric,
  absence_reasons jsonb,
  recent_events jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
  latest_event public.gvg_events%rowtype;
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
      raise exception 'Only Owner can view global GvG analytics.';
    end if;
  elsif not private.can_manage_gvg(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view GvG analytics.';
  end if;

  select ge.* into latest_event
  from public.gvg_events ge
  where (
      scoped_guild_id is null
      or (ge.scope = 'guild' and ge.guild_id = scoped_guild_id)
    )
  order by coalesce(ge.starts_at, ge.created_at) desc, ge.created_at desc, ge.id desc
  limit 1;

  if latest_event.id is null then
    return query
    select
      scoped_guild_id,
      scoped_guild_name,
      null::uuid,
      null::text,
      null::text,
      null::text,
      null::uuid,
      null::text,
      null::timestamptz,
      null::timestamptz,
      0::bigint,
      0::bigint,
      0::bigint,
      0::bigint,
      0::numeric,
      '[]'::jsonb,
      '[]'::jsonb;
    return;
  end if;

  return query
  with eligible_members as (
    select gm.profile_id
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
      and (
        (latest_event.scope = 'global')
        or (latest_event.scope = 'guild' and gm.guild_id = latest_event.guild_id)
      )
  ),
  vote_counts as (
    select
      count(*) filter (where gv.vote_status = 'present') as present_votes,
      count(*) filter (where gv.vote_status = 'absent') as absent_votes,
      count(distinct gv.profile_id) as total_votes
    from public.gvg_votes gv
    where gv.gvg_event_id = latest_event.id
  ),
  reason_payload as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'profile_id', p.id,
          'username', p.username,
          'ign', p.ign,
          'absence_reason', gv.absence_reason,
          'updated_at', gv.updated_at
        )
        order by p.ign asc
      ) filter (where gv.vote_status = 'absent' and gv.absence_reason is not null),
      '[]'::jsonb
    ) as payload
    from public.gvg_votes gv
    join public.profiles p on p.id = gv.profile_id
    where gv.gvg_event_id = latest_event.id
  ),
  recent_payload as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', recent.id,
          'title', recent.title,
          'scope', recent.scope,
          'status', recent.status,
          'guild_id', recent.guild_id,
          'starts_at', recent.starts_at,
          'created_at', recent.created_at
        )
        order by coalesce(recent.starts_at, recent.created_at) desc
      ),
      '[]'::jsonb
    ) as payload
    from (
      select ge.*
      from public.gvg_events ge
      where (
          scoped_guild_id is null
          or (ge.scope = 'guild' and ge.guild_id = scoped_guild_id)
        )
      order by coalesce(ge.starts_at, ge.created_at) desc, ge.created_at desc, ge.id desc
      limit 5
    ) recent
  ),
  eligible_count as (
    select count(*) as count_value from eligible_members
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    latest_event.id,
    latest_event.title,
    latest_event.scope,
    latest_event.status,
    latest_event.guild_id,
    event_guild.name,
    latest_event.starts_at,
    latest_event.ends_at,
    coalesce(vc.present_votes, 0)::bigint,
    coalesce(vc.absent_votes, 0)::bigint,
    greatest(coalesce(ec.count_value, 0) - coalesce(vc.total_votes, 0), 0)::bigint,
    coalesce(ec.count_value, 0)::bigint,
    case
      when coalesce(ec.count_value, 0) = 0 then 0::numeric
      else round(((coalesce(vc.total_votes, 0)::numeric / ec.count_value::numeric) * 100), 2)
    end,
    rp.payload,
    recent_payload.payload
  from vote_counts vc
  cross join eligible_count ec
  cross join reason_payload rp
  cross join recent_payload
  left join public.guilds event_guild on event_guild.id = latest_event.guild_id;
end;
$$;

create or replace function public.capture_weekly_cp_snapshot(p_guild_id uuid default null)
returns table (
  batch_id uuid,
  guild_id uuid,
  captured_at timestamptz,
  captured_count integer
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
  v_week_start date := date_trunc('week', now())::date;
  v_week_end date := (date_trunc('week', now())::date + 6);
  v_captured_at timestamptz := clock_timestamp();
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
      raise exception 'Only Owner can capture global CP snapshots.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to capture CP snapshots.';
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
    case
      when scoped_guild_id is null then 'Global weekly snapshot ' || v_week_start::text
      else scoped_guild_name || ' weekly snapshot ' || v_week_start::text
    end
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
      'scope', case when scoped_guild_id is null then 'global' else 'guild' end
    )
  );

  return query
  select new_batch.id, new_batch.guild_id, new_batch.captured_at, inserted_count;
end;
$$;

create or replace function public.get_admin_cp_snapshot_history(p_guild_id uuid default null)
returns table (
  id uuid,
  guild_id uuid,
  guild_name text,
  label text,
  captured_at timestamptz,
  captured_by_profile_id uuid,
  captured_by_username text,
  captured_by_ign text,
  week_start date,
  week_end date,
  member_count bigint,
  scope text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Guild scope is required.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP snapshot history.';
  end if;

  return query
  select
    b.id,
    b.guild_id,
    g.name,
    b.label,
    b.captured_at,
    b.captured_by,
    actor_profile.username,
    actor_profile.ign,
    b.week_start,
    b.week_end,
    count(e.id)::bigint,
    case when b.guild_id is null then 'global' else 'guild' end
  from public.cp_snapshot_batches b
  left join public.cp_snapshot_entries e on e.batch_id = b.id
  left join public.guilds g on g.id = b.guild_id
  left join public.profiles actor_profile on actor_profile.id = b.captured_by
  where (
      scoped_guild_id is null
      or b.guild_id = scoped_guild_id
    )
  group by
    b.id,
    b.guild_id,
    g.name,
    b.label,
    b.captured_at,
    b.captured_by,
    actor_profile.username,
    actor_profile.ign,
    b.week_start,
    b.week_end
  order by b.captured_at desc, b.id desc;
end;
$$;

create or replace function public.get_admin_cp_growth_report(
  p_guild_id uuid default null,
  p_snapshot_id uuid default null
)
returns table (
  has_previous_snapshot boolean,
  current_snapshot_id uuid,
  previous_snapshot_id uuid,
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  previous_cp integer,
  current_cp integer,
  growth_amount integer,
  growth_percent numeric,
  last_updated timestamptz,
  missing_update boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  scoped_guild_id uuid := p_guild_id;
  current_batch public.cp_snapshot_batches%rowtype;
  previous_batch public.cp_snapshot_batches%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  if p_snapshot_id is not null then
    select * into current_batch
    from public.cp_snapshot_batches b
    where b.id = p_snapshot_id;

    if not found then
      raise exception 'Snapshot batch not found.';
    end if;

    if scoped_guild_id is not null and current_batch.guild_id is distinct from scoped_guild_id then
      raise exception 'Snapshot batch does not match requested guild scope.';
    end if;

    scoped_guild_id := current_batch.guild_id;
  else
    if scoped_guild_id is null then
      if not private.is_owner(actor_id) then
        raise exception 'Guild scope is required.';
      end if;

      select * into current_batch
      from public.cp_snapshot_batches b
      where b.guild_id is null
      order by b.captured_at desc, b.id desc
      limit 1;
    else
      select * into current_batch
      from public.cp_snapshot_batches b
      where b.guild_id = scoped_guild_id
      order by b.captured_at desc, b.id desc
      limit 1;
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global CP growth.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP growth.';
  end if;

  if current_batch.id is null then
    return query
    select
      false,
      null::uuid,
      null::uuid,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      scoped_guild_id,
      null::text,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false;
    return;
  end if;

  select * into previous_batch
  from public.cp_snapshot_batches b
  where b.guild_id is not distinct from current_batch.guild_id
    and (
      b.captured_at < current_batch.captured_at
      or (b.captured_at = current_batch.captured_at and b.id <> current_batch.id)
    )
  order by b.captured_at desc, b.id desc
  limit 1;

  if previous_batch.id is null then
    return query
    select
      false,
      current_batch.id,
      null::uuid,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      current_batch.guild_id,
      null::text,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false;
    return;
  end if;

  return query
  with growth_rows as (
    select
      coalesce(current_entry.profile_id, previous_entry.profile_id) as profile_id,
      coalesce(current_entry.guild_id, previous_entry.guild_id) as guild_id,
      previous_entry.cp_value as previous_cp,
      current_entry.cp_value as current_cp,
      case
        when current_entry.cp_value is null or previous_entry.cp_value is null then null
        else current_entry.cp_value - previous_entry.cp_value
      end as growth_amount,
      case
        when current_entry.cp_value is null
          or previous_entry.cp_value is null
          or previous_entry.cp_value = 0 then null
        else round(((current_entry.cp_value - previous_entry.cp_value)::numeric / previous_entry.cp_value::numeric) * 100, 2)
      end as growth_percent,
      current_entry.member_cp_updated_at as last_updated,
      (
        current_entry.id is null
        or current_entry.member_cp_updated_at is null
        or current_entry.member_cp_updated_at <= previous_batch.captured_at
      ) as missing_update
    from (
      select *
      from public.cp_snapshot_entries e
      where e.batch_id = current_batch.id
    ) current_entry
    full join (
      select *
      from public.cp_snapshot_entries e
      where e.batch_id = previous_batch.id
    ) previous_entry
      on previous_entry.profile_id = current_entry.profile_id
     and previous_entry.guild_id = current_entry.guild_id
  ),
  decorated_rows as (
    select
      gr.*,
      p.username,
      p.ign,
      g.name as guild_name,
      row_number() over (
        order by gr.growth_amount desc nulls last, lower(coalesce(p.ign, p.username, p.id::text)) asc, p.id asc
      )::integer as rank_position
    from growth_rows gr
    join public.profiles p on p.id = gr.profile_id
    join public.guilds g on g.id = gr.guild_id
    where scoped_guild_id is null or gr.guild_id = scoped_guild_id
  )
  select
    true,
    current_batch.id,
    previous_batch.id,
    dr.rank_position,
    dr.profile_id,
    dr.username,
    dr.ign,
    dr.guild_id,
    dr.guild_name,
    dr.previous_cp,
    dr.current_cp,
    dr.growth_amount,
    dr.growth_percent,
    dr.last_updated,
    dr.missing_update
  from decorated_rows dr
  order by dr.rank_position;
end;
$$;

revoke all on function private.can_view_member_analytics(uuid, uuid) from public, anon;
grant execute on function private.can_view_member_analytics(uuid, uuid) to authenticated;

revoke all on function public.get_admin_member_analytics(uuid) from public, anon;
revoke all on function public.get_admin_cp_analytics(uuid) from public, anon;
revoke all on function public.get_admin_gvg_analytics(uuid) from public, anon;
revoke all on function public.capture_weekly_cp_snapshot(uuid) from public, anon;
revoke all on function public.get_admin_cp_snapshot_history(uuid) from public, anon;
revoke all on function public.get_admin_cp_growth_report(uuid, uuid) from public, anon;

grant execute on function public.get_admin_member_analytics(uuid) to authenticated;
grant execute on function public.get_admin_cp_analytics(uuid) to authenticated;
grant execute on function public.get_admin_gvg_analytics(uuid) to authenticated;
grant execute on function public.capture_weekly_cp_snapshot(uuid) to authenticated;
grant execute on function public.get_admin_cp_snapshot_history(uuid) to authenticated;
grant execute on function public.get_admin_cp_growth_report(uuid, uuid) to authenticated;
