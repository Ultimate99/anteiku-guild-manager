-- Anteiku Guild Manager - CP Update Window / Member Self-Submit
-- Safe migration: adds guild-scoped CP update windows and RPC-only member own-CP
-- read/submit support. Members still cannot directly read member_cp or cp_snapshots.

create table if not exists public.cp_update_windows (
  id uuid primary key default gen_random_uuid(),
  guild_id uuid not null references public.guilds(id) on delete restrict,
  status text not null default 'open',
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_by uuid not null references public.profiles(id) on delete restrict,
  closed_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cp_update_windows_status_chk check (status in ('open', 'closed')),
  constraint cp_update_windows_time_order_chk check (
    opens_at is null
    or closes_at is null
    or closes_at > opens_at
  ),
  constraint cp_update_windows_note_length_chk check (
    note is null
    or char_length(note) <= 1000
  ),
  constraint cp_update_windows_closed_by_chk check (
    (status = 'open' and closed_by is null)
    or (status = 'closed')
  )
);

create index if not exists cp_update_windows_guild_idx
  on public.cp_update_windows (guild_id);

create index if not exists cp_update_windows_status_idx
  on public.cp_update_windows (status);

create index if not exists cp_update_windows_guild_status_time_idx
  on public.cp_update_windows (guild_id, status, opens_at, closes_at);

create unique index if not exists cp_update_windows_one_open_per_guild_uidx
  on public.cp_update_windows (guild_id)
  where status = 'open';

drop trigger if exists set_cp_update_windows_updated_at on public.cp_update_windows;
create trigger set_cp_update_windows_updated_at
before update on public.cp_update_windows
for each row
execute function public.set_updated_at();

alter table public.cp_update_windows enable row level security;

revoke all on public.cp_update_windows from public, anon, authenticated;

create or replace function public.get_active_cp_update_window_for_me()
returns table (
  window_id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  server_now timestamptz,
  can_submit boolean,
  reason text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
  active_window public.cp_update_windows%rowtype;
  v_now timestamptz := now();
  eligible_roster_statuses constant text[] := array['active', 'trial', 'pending_transfer'];
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into actor_profile
  from public.profiles p
  where p.id = actor_id;

  if not found or actor_profile.approval_status <> 'approved' then
    raise exception 'Approved profile required.';
  end if;

  select * into actor_membership
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  if not found then
    raise exception 'Active primary guild membership required.';
  end if;

  select * into active_window
  from public.cp_update_windows w
  where w.guild_id = actor_membership.guild_id
    and w.status = 'open'
  order by w.created_at desc, w.id desc
  limit 1;

  return query
  select
    active_window.id,
    actor_membership.guild_id,
    coalesce(active_window.status, 'closed'::text),
    active_window.opens_at,
    active_window.closes_at,
    v_now,
    (
      actor_membership.roster_status = any(eligible_roster_statuses)
      and active_window.id is not null
      and (active_window.opens_at is null or v_now >= active_window.opens_at)
      and (active_window.closes_at is null or v_now <= active_window.closes_at)
    ) as can_submit,
    case
      when actor_membership.roster_status <> all(eligible_roster_statuses) then 'not_eligible_roster_status'
      when active_window.id is null then 'window_closed'
      when active_window.opens_at is not null and v_now < active_window.opens_at then 'window_not_open_yet'
      when active_window.closes_at is not null and v_now > active_window.closes_at then 'window_closed'
      else 'open'
    end as reason;
end;
$$;

create or replace function public.get_my_cp()
returns table (
  guild_id uuid,
  cp_value integer,
  updated_at timestamptz,
  updated_by_self boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into actor_profile
  from public.profiles p
  where p.id = actor_id;

  if not found or actor_profile.approval_status <> 'approved' then
    raise exception 'Approved profile required.';
  end if;

  select * into actor_membership
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  if not found then
    raise exception 'Active primary guild membership required.';
  end if;

  return query
  select
    actor_membership.guild_id,
    cp.cp_value,
    cp.updated_at,
    coalesce(cp.updated_by = actor_id, false)
  from (select 1) singleton
  left join public.member_cp cp
    on cp.profile_id = actor_id
   and cp.guild_id = actor_membership.guild_id;
end;
$$;

create or replace function public.submit_my_cp_update(p_cp_value integer)
returns table (
  cp_value integer,
  updated_at timestamptz,
  window_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
  active_window public.cp_update_windows%rowtype;
  old_cp integer;
  updated_cp public.member_cp%rowtype;
  v_now timestamptz := now();
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into actor_profile
  from public.profiles p
  where p.id = actor_id;

  if not found or actor_profile.approval_status <> 'approved' then
    raise exception 'Approved profile required.';
  end if;

  select * into actor_membership
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  if not found then
    raise exception 'Active primary guild membership required.';
  end if;

  if actor_membership.roster_status not in ('active', 'trial', 'pending_transfer') then
    raise exception 'Roster status is not eligible for CP submission.';
  end if;

  if p_cp_value is null or p_cp_value < 0 then
    raise exception 'CP value must be 0 or greater.';
  end if;

  select * into active_window
  from public.cp_update_windows w
  where w.guild_id = actor_membership.guild_id
    and w.status = 'open'
    and (w.opens_at is null or v_now >= w.opens_at)
    and (w.closes_at is null or v_now <= w.closes_at)
  order by w.created_at desc, w.id desc
  limit 1;

  if not found then
    raise exception 'CP update window is not open.';
  end if;

  select cp.cp_value into old_cp
  from public.member_cp cp
  where cp.profile_id = actor_id
    and cp.guild_id = actor_membership.guild_id;

  insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
  values (actor_id, actor_membership.guild_id, p_cp_value, actor_id, v_now)
  on conflict (profile_id) do update
  set
    guild_id = excluded.guild_id,
    cp_value = excluded.cp_value,
    updated_by = excluded.updated_by,
    updated_at = excluded.updated_at
  returning * into updated_cp;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_membership.guild_id,
    'member_cp_self_submitted',
    'member_cp',
    actor_id,
    jsonb_build_object(
      'cp_old', old_cp,
      'cp_new', p_cp_value,
      'window_id', active_window.id,
      'source', 'member_self_submit'
    )
  );

  return query
  select updated_cp.cp_value, updated_cp.updated_at, active_window.id;
end;
$$;

create or replace function public.open_cp_update_window(
  p_guild_id uuid,
  p_opens_at timestamptz default null,
  p_closes_at timestamptz default null,
  p_note text default null
)
returns table (
  window_id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  created_window public.cp_update_windows%rowtype;
  normalized_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_guild_id is null or not exists (
    select 1 from public.guilds g where g.id = p_guild_id and g.status = 'active'
  ) then
    raise exception 'Active guild not found.';
  end if;

  if not private.can_update_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to manage CP update windows for this guild.';
  end if;

  if normalized_note is not null and char_length(normalized_note) > 1000 then
    raise exception 'CP update window note is too long.';
  end if;

  if p_opens_at is not null and p_closes_at is not null and p_closes_at <= p_opens_at then
    raise exception 'CP update window close time must be after open time.';
  end if;

  if p_closes_at is not null and p_closes_at <= now() then
    raise exception 'CP update window close time must be in the future.';
  end if;

  if exists (
    select 1
    from public.cp_update_windows w
    where w.guild_id = p_guild_id
      and w.status = 'open'
  ) then
    raise exception 'A CP update window is already open for this guild.';
  end if;

  insert into public.cp_update_windows (
    guild_id,
    status,
    opens_at,
    closes_at,
    note,
    created_by
  )
  values (
    p_guild_id,
    'open',
    p_opens_at,
    p_closes_at,
    normalized_note,
    actor_id
  )
  returning * into created_window;

  perform private.write_audit_log(
    actor_id,
    null,
    p_guild_id,
    'cp_update_window_opened',
    'cp_update_windows',
    created_window.id,
    jsonb_build_object(
      'window_id', created_window.id,
      'guild_id', p_guild_id,
      'opens_at', p_opens_at,
      'closes_at', p_closes_at,
      'note_provided', normalized_note is not null
    )
  );

  return query
  select
    created_window.id,
    created_window.guild_id,
    created_window.status,
    created_window.opens_at,
    created_window.closes_at,
    created_window.note,
    created_window.created_at,
    created_window.updated_at;
end;
$$;

create or replace function public.close_cp_update_window(p_window_id uuid)
returns table (
  window_id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_window public.cp_update_windows%rowtype;
  closed_window public.cp_update_windows%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_window
  from public.cp_update_windows w
  where w.id = p_window_id
  for update;

  if not found then
    raise exception 'CP update window not found.';
  end if;

  if target_window.status <> 'open' then
    raise exception 'CP update window is already closed.';
  end if;

  if not private.can_update_cp(actor_id, target_window.guild_id) then
    raise exception 'Not authorized to manage CP update windows for this guild.';
  end if;

  update public.cp_update_windows
  set
    status = 'closed',
    closed_by = actor_id,
    updated_at = now()
  where id = target_window.id
  returning * into closed_window;

  perform private.write_audit_log(
    actor_id,
    null,
    target_window.guild_id,
    'cp_update_window_closed',
    'cp_update_windows',
    target_window.id,
    jsonb_build_object(
      'window_id', target_window.id,
      'guild_id', target_window.guild_id
    )
  );

  return query
  select
    closed_window.id,
    closed_window.guild_id,
    closed_window.status,
    closed_window.opens_at,
    closed_window.closes_at,
    closed_window.note,
    closed_window.created_at,
    closed_window.updated_at;
end;
$$;

create or replace function public.get_audit_logs(
  p_guild_id uuid default null,
  p_action text default null,
  p_actor_id uuid default null,
  p_target_id uuid default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 50,
  p_before timestamptz default null
)
returns table (
  id uuid,
  created_at timestamptz,
  action text,
  entity_table text,
  entity_id uuid,
  actor_profile_id uuid,
  actor_username text,
  actor_ign text,
  target_profile_id uuid,
  target_username text,
  target_ign text,
  guild_id uuid,
  guild_name text,
  guild_slug text,
  metadata jsonb,
  metadata_redacted boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  safe_limit integer;
  has_audit_scope boolean;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  safe_limit := least(greatest(coalesce(p_limit, 50), 1), 100);

  select
    private.is_owner(actor_id)
    or exists (
      select 1
      from public.guild_memberships gm
      where gm.profile_id = actor_id
        and gm.membership_status = 'active'
        and (
          gm.role in ('leader', 'vice')
          or private.has_permission(actor_id, gm.guild_id, 'view_audit_logs')
        )
    )
  into has_audit_scope;

  if not has_audit_scope then
    raise exception 'Not authorized to read audit logs.';
  end if;

  if p_guild_id is not null and not private.can_read_audit_logs(actor_id, p_guild_id) then
    raise exception 'Not authorized to read audit logs for this guild.';
  end if;

  return query
  with filtered_logs as (
    select
      al.*,
      (
        al.action in ('member_cp_updated', 'member_cp_self_submitted', 'weekly_cp_snapshot_captured')
        or al.entity_table in ('member_cp', 'cp_snapshots')
        or al.metadata ?| array[
          'cp_old',
          'cp_new',
          'cp_value',
          'cp_from',
          'cp_to',
          'growth',
          'growth_value'
        ]
      ) as is_cp_sensitive,
      private.can_view_cp(actor_id, al.guild_id) as can_view_cp_metadata
    from public.audit_logs al
    where private.can_read_audit_logs(actor_id, al.guild_id)
      and (p_guild_id is null or al.guild_id = p_guild_id)
      and (p_action is null or al.action = p_action)
      and (p_actor_id is null or al.actor_profile_id = p_actor_id)
      and (p_target_id is null or al.target_profile_id = p_target_id)
      and (p_from is null or al.created_at >= p_from)
      and (p_to is null or al.created_at <= p_to)
      and (p_before is null or al.created_at < p_before)
    order by al.created_at desc, al.id desc
    limit safe_limit
  )
  select
    fl.id,
    fl.created_at,
    fl.action,
    fl.entity_table,
    fl.entity_id,
    fl.actor_profile_id,
    actor_profile.username,
    actor_profile.ign,
    fl.target_profile_id,
    target_profile.username,
    target_profile.ign,
    fl.guild_id,
    g.name,
    g.slug,
    case
      when fl.is_cp_sensitive and not fl.can_view_cp_metadata then
        (
          fl.metadata
          - 'cp_old'
          - 'cp_new'
          - 'cp_value'
          - 'cp_from'
          - 'cp_to'
          - 'growth'
          - 'growth_value'
          - 'note'
        ) || jsonb_build_object(
          'cp_metadata_redacted', true,
          'redaction_reason', 'Sensitive CP metadata hidden.'
        )
      else fl.metadata
    end as metadata,
    (fl.is_cp_sensitive and not fl.can_view_cp_metadata) as metadata_redacted
  from filtered_logs fl
  left join public.profiles actor_profile on actor_profile.id = fl.actor_profile_id
  left join public.profiles target_profile on target_profile.id = fl.target_profile_id
  left join public.guilds g on g.id = fl.guild_id
  order by fl.created_at desc, fl.id desc;
end;
$$;

revoke all on function public.get_active_cp_update_window_for_me() from public, anon;
revoke all on function public.get_my_cp() from public, anon;
revoke all on function public.submit_my_cp_update(integer) from public, anon;
revoke all on function public.open_cp_update_window(uuid, timestamptz, timestamptz, text) from public, anon;
revoke all on function public.close_cp_update_window(uuid) from public, anon;
revoke all on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  from public, anon;

grant execute on function public.get_active_cp_update_window_for_me() to authenticated;
grant execute on function public.get_my_cp() to authenticated;
grant execute on function public.submit_my_cp_update(integer) to authenticated;
grant execute on function public.open_cp_update_window(uuid, timestamptz, timestamptz, text) to authenticated;
grant execute on function public.close_cp_update_window(uuid) to authenticated;
grant execute on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  to authenticated;
