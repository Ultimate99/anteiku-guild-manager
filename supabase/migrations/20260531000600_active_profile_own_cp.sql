-- Anteiku Guild Manager - Own CP active-profile migration
-- Migrates only member-own CP read/window/self-submit RPCs to the selected
-- active profile. Admin CP roster/update/ranking and analytics remain
-- unchanged.

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
  actor_id uuid := private.get_active_profile_id();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
  active_window public.cp_update_windows%rowtype;
  v_now timestamptz := now();
  eligible_roster_statuses constant text[] := array['active', 'trial', 'pending_transfer'];
begin
  if auth.uid() is null or actor_id is null then
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

  if actor_membership.roster_status in ('suspended', 'left', 'kicked') then
    raise exception 'Roster status is not eligible for CP access.';
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
  actor_id uuid := private.get_active_profile_id();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
begin
  if auth.uid() is null or actor_id is null then
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

  if actor_membership.roster_status in ('suspended', 'left', 'kicked') then
    raise exception 'Roster status is not eligible for CP access.';
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
  actor_id uuid := private.get_active_profile_id();
  actor_profile public.profiles%rowtype;
  actor_membership public.guild_memberships%rowtype;
  active_window public.cp_update_windows%rowtype;
  old_cp integer;
  updated_cp public.member_cp%rowtype;
  v_now timestamptz := now();
begin
  if auth.uid() is null or actor_id is null then
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

revoke all on function public.get_active_cp_update_window_for_me() from public, anon;
revoke all on function public.get_my_cp() from public, anon;
revoke all on function public.submit_my_cp_update(integer) from public, anon;

grant execute on function public.get_active_cp_update_window_for_me() to authenticated;
grant execute on function public.get_my_cp() to authenticated;
grant execute on function public.submit_my_cp_update(integer) to authenticated;
