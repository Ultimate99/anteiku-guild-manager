-- Anteiku Guild Manager - Public RPC Functions
-- Safe migration: creates frontend-callable RPCs with auth.uid() validation, permission checks, and explicit search_path.
-- Sensitive CP access is available only through permission-checked functions, never direct member table reads.

create or replace function public.register_profile(
  p_username text,
  p_ign text,
  p_requested_guild_id uuid
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_slug text := private.normalize_profile_slug(p_username);
  new_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Username/profile slug format is invalid.';
  end if;

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  if not exists (
    select 1 from public.guilds
    where id = p_requested_guild_id and status = 'active'
  ) then
    raise exception 'Requested guild is not available.';
  end if;

  if exists (select 1 from public.profiles where id = actor_id) then
    raise exception 'Profile already exists. Use reapply flow if rejected.';
  end if;

  insert into public.profiles (id, username, profile_slug, ign, approval_status)
  values (actor_id, normalized_slug, normalized_slug, btrim(p_ign), 'pending')
  returning * into new_profile;

  insert into public.guild_memberships (profile_id, guild_id, role, membership_status, is_primary)
  values (actor_id, p_requested_guild_id, 'member', 'pending', true);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    p_requested_guild_id,
    'profile_registered',
    'profiles',
    actor_id,
    jsonb_build_object('approval_status', 'pending')
  );

  return new_profile;
end;
$$;

create or replace function public.request_reapply(p_reapply_note text)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_reapply_note is not null and char_length(p_reapply_note) > 1000 then
    raise exception 'Reapply note cannot exceed 1000 characters.';
  end if;

  select gm.guild_id into target_guild_id
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.is_primary = true
    and gm.membership_status in ('pending', 'rejected')
  order by case gm.membership_status
    when 'rejected' then 1
    when 'pending' then 2
    else 3
  end
  limit 1;

  update public.profiles
  set
    reapply_requested_at = now(),
    reapply_note = nullif(btrim(coalesce(p_reapply_note, '')), ''),
    updated_at = now()
  where id = actor_id
    and approval_status = 'rejected'
  returning * into updated_profile;

  if not found then
    raise exception 'Only rejected profiles can request reapply.';
  end if;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    target_guild_id,
    'profile_reapply_requested',
    'profiles',
    actor_id,
    jsonb_build_object('reapply_requested_at', updated_profile.reapply_requested_at)
  );

  return updated_profile;
end;
$$;

create or replace function public.approve_registration(
  p_profile_id uuid,
  p_guild_id uuid,
  p_role text default 'member'
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_approve_members(actor_id, p_guild_id) then
    raise exception 'Not authorized to approve members for this guild.';
  end if;

  if not private.has_pending_or_reapply_membership(p_profile_id, p_guild_id) then
    raise exception 'Target profile does not have a pending or reapply request for this guild.';
  end if;

  if not private.can_assign_role_on_approval(actor_id, p_guild_id, p_role) then
    raise exception 'Not authorized to assign this role.';
  end if;

  if exists (
    select 1
    from public.guild_memberships gm
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.guild_id <> p_guild_id
  ) then
    raise exception 'Profile already has an active primary guild membership.';
  end if;

  update public.profiles
  set
    approval_status = 'approved',
    approved_at = now(),
    approved_by = actor_id,
    rejected_at = null,
    rejected_by = null,
    reapply_requested_at = null,
    updated_at = now()
  where id = p_profile_id
  returning * into updated_profile;

  if not found then
    raise exception 'Profile not found.';
  end if;

  insert into public.guild_memberships (
    profile_id,
    guild_id,
    role,
    membership_status,
    is_primary,
    assigned_by
  )
  values (p_profile_id, p_guild_id, p_role, 'active', true, actor_id)
  on conflict (profile_id, guild_id) do update
  set
    role = excluded.role,
    membership_status = 'active',
    is_primary = true,
    assigned_by = actor_id,
    updated_at = now();

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    p_guild_id,
    'registration_approved',
    'profiles',
    p_profile_id,
    jsonb_build_object('approval_status_new', 'approved', 'role_new', p_role)
  );

  return updated_profile;
end;
$$;

create or replace function public.reject_registration(
  p_profile_id uuid,
  p_reason text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_reason is not null and char_length(p_reason) > 1000 then
    raise exception 'Rejection reason cannot exceed 1000 characters.';
  end if;

  select gm.guild_id into target_guild_id
  from public.guild_memberships gm
  where gm.profile_id = p_profile_id
    and gm.is_primary = true
    and gm.membership_status in ('pending', 'rejected')
  limit 1;

  if target_guild_id is null then
    raise exception 'Pending/reapplying membership not found.';
  end if;

  if not private.has_pending_or_reapply_membership(p_profile_id, target_guild_id) then
    raise exception 'Target profile does not have a pending or reapply request for this guild.';
  end if;

  if not private.can_approve_members(actor_id, target_guild_id) then
    raise exception 'Not authorized to reject this registration.';
  end if;

  update public.profiles
  set
    approval_status = 'rejected',
    rejected_at = now(),
    rejected_by = actor_id,
    reapply_requested_at = null,
    reapply_note = null,
    updated_at = now()
  where id = p_profile_id
  returning * into updated_profile;

  update public.guild_memberships
  set membership_status = 'rejected', updated_at = now()
  where profile_id = p_profile_id
    and guild_id = target_guild_id;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'registration_rejected',
    'profiles',
    p_profile_id,
    jsonb_build_object('approval_status_new', 'rejected', 'reason', p_reason)
  );

  return updated_profile;
end;
$$;

create or replace function public.update_my_profile(
  p_ign text,
  p_avatar_key text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  update public.profiles
  set
    ign = btrim(p_ign),
    avatar_key = nullif(btrim(coalesce(p_avatar_key, '')), ''),
    updated_at = now()
  where id = actor_id
  returning * into updated_profile;

  if not found then
    raise exception 'Profile not found.';
  end if;

  return updated_profile;
end;
$$;

create or replace function public.admin_update_member_ign(
  p_profile_id uuid,
  p_ign text
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  old_ign text;
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  if not private.can_edit_member_ign(actor_id, p_profile_id) then
    raise exception 'Not authorized to edit this IGN.';
  end if;

  select ign into old_ign from public.profiles where id = p_profile_id;
  target_guild_id := private.target_primary_guild_id(p_profile_id);

  update public.profiles
  set ign = btrim(p_ign), updated_at = now()
  where id = p_profile_id
  returning * into updated_profile;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'member_ign_updated',
    'profiles',
    p_profile_id,
    jsonb_build_object('ign_old', old_ign, 'ign_new', updated_profile.ign)
  );

  return updated_profile;
end;
$$;

create or replace function public.admin_reset_profile_slug(
  p_profile_id uuid,
  p_new_slug text
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_slug text := private.normalize_profile_slug(p_new_slug);
  old_slug text;
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Username/profile slug format is invalid.';
  end if;

  if not private.can_reset_profile_slug(actor_id, p_profile_id) then
    raise exception 'Not authorized to reset this profile slug.';
  end if;

  select profile_slug into old_slug from public.profiles where id = p_profile_id;
  target_guild_id := private.target_primary_guild_id(p_profile_id);

  update public.profiles
  set
    username = normalized_slug,
    profile_slug = normalized_slug,
    updated_at = now()
  where id = p_profile_id
  returning * into updated_profile;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'profile_slug_reset',
    'profiles',
    p_profile_id,
    jsonb_build_object('slug_old', old_slug, 'slug_new', normalized_slug)
  );

  return updated_profile;
end;
$$;

create or replace function public.assign_member_role(
  p_profile_id uuid,
  p_guild_id uuid,
  p_role text
)
returns public.guild_memberships
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  old_role text;
  updated_membership public.guild_memberships%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_assign_role(actor_id, p_guild_id, p_role) then
    raise exception 'Not authorized to assign this role.';
  end if;

  select role into old_role
  from public.guild_memberships
  where profile_id = p_profile_id
    and guild_id = p_guild_id
    and membership_status = 'active';

  update public.guild_memberships
  set role = p_role, assigned_by = actor_id, updated_at = now()
  where profile_id = p_profile_id
    and guild_id = p_guild_id
    and membership_status = 'active'
  returning * into updated_membership;

  if not found then
    raise exception 'Active membership not found.';
  end if;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    p_guild_id,
    'member_role_updated',
    'guild_memberships',
    updated_membership.id,
    jsonb_build_object('role_old', old_role, 'role_new', p_role)
  );

  return updated_membership;
end;
$$;

create or replace function public.grant_admin_permission(
  p_membership_id uuid,
  p_permission_key text
)
returns public.admin_permissions
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_membership public.guild_memberships%rowtype;
  new_permission public.admin_permissions%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_membership
  from public.guild_memberships
  where id = p_membership_id
    and role = 'admin'
    and membership_status = 'active';

  if not found then
    raise exception 'Active Admin membership not found.';
  end if;

  if not exists (select 1 from public.permission_catalog where key = p_permission_key) then
    raise exception 'Unknown permission key.';
  end if;

  if not private.can_grant_admin_permission(actor_id, p_membership_id, p_permission_key) then
    raise exception 'Not authorized to grant this permission.';
  end if;

  insert into public.admin_permissions (membership_id, permission_key, granted_by)
  values (p_membership_id, p_permission_key, actor_id)
  on conflict (membership_id, permission_key) do update
  set granted_by = excluded.granted_by, created_at = now()
  returning * into new_permission;

  perform private.write_audit_log(
    actor_id,
    target_membership.profile_id,
    target_membership.guild_id,
    'admin_permission_granted',
    'admin_permissions',
    new_permission.id,
    jsonb_build_object('permission_key', p_permission_key)
  );

  return new_permission;
end;
$$;

create or replace function public.revoke_admin_permission(
  p_membership_id uuid,
  p_permission_key text
)
returns void
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_membership public.guild_memberships%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_membership
  from public.guild_memberships
  where id = p_membership_id
    and role = 'admin'
    and membership_status = 'active';

  if not found then
    raise exception 'Active Admin membership not found.';
  end if;

  if not private.can_grant_admin_permission(actor_id, p_membership_id, p_permission_key) then
    raise exception 'Not authorized to revoke this permission.';
  end if;

  delete from public.admin_permissions
  where membership_id = p_membership_id
    and permission_key = p_permission_key;

  perform private.write_audit_log(
    actor_id,
    target_membership.profile_id,
    target_membership.guild_id,
    'admin_permission_revoked',
    'admin_permissions',
    p_membership_id,
    jsonb_build_object('permission_key', p_permission_key)
  );
end;
$$;

create or replace function public.update_member_cp(
  p_profile_id uuid,
  p_cp_value integer,
  p_note text default null
)
returns public.member_cp
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  target_guild_id uuid := private.target_primary_guild_id(p_profile_id);
  old_cp integer;
  updated_cp public.member_cp%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if target_guild_id is null then
    raise exception 'Target profile has no active primary guild.';
  end if;

  if p_cp_value is null or p_cp_value < 0 then
    raise exception 'CP value must be 0 or greater.';
  end if;

  if not private.can_update_cp(actor_id, target_guild_id) then
    raise exception 'Not authorized to update CP for this guild.';
  end if;

  select cp_value into old_cp from public.member_cp where profile_id = p_profile_id;

  insert into public.member_cp (profile_id, guild_id, cp_value, updated_by, updated_at)
  values (p_profile_id, target_guild_id, p_cp_value, actor_id, now())
  on conflict (profile_id) do update
  set
    guild_id = excluded.guild_id,
    cp_value = excluded.cp_value,
    updated_by = excluded.updated_by,
    updated_at = now()
  returning * into updated_cp;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'member_cp_updated',
    'member_cp',
    p_profile_id,
    jsonb_build_object('cp_old', old_cp, 'cp_new', p_cp_value, 'note', p_note)
  );

  return updated_cp;
end;
$$;

create or replace function public.capture_weekly_cp_snapshot(
  p_guild_id uuid,
  p_snapshot_week_start date
)
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  captured_count integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_update_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to capture CP snapshots for this guild.';
  end if;

  insert into public.cp_snapshots (profile_id, guild_id, snapshot_week_start, cp_value, captured_by)
  select cp.profile_id, cp.guild_id, p_snapshot_week_start, cp.cp_value, actor_id
  from public.member_cp cp
  where cp.guild_id = p_guild_id
    and exists (
      select 1
      from public.guild_memberships gm
      join public.profiles p on p.id = gm.profile_id
      where gm.profile_id = cp.profile_id
        and gm.guild_id = cp.guild_id
        and gm.membership_status = 'active'
        and gm.is_primary = true
        and p.approval_status = 'approved'
    )
  on conflict (profile_id, guild_id, snapshot_week_start) do update
  set cp_value = excluded.cp_value,
      captured_by = excluded.captured_by,
      created_at = now();

  get diagnostics captured_count = row_count;

  perform private.write_audit_log(
    actor_id,
    null,
    p_guild_id,
    'weekly_cp_snapshot_captured',
    'cp_snapshots',
    null,
    jsonb_build_object('snapshot_week_start', p_snapshot_week_start, 'rows_affected', captured_count)
  );

  return captured_count;
end;
$$;

create or replace function public.get_current_cp_roster(p_guild_id uuid)
returns table (
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  cp_value integer,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_view_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to view CP for this guild.';
  end if;

  return query
  select p.id, p.username, p.ign, cp.guild_id, cp.cp_value, cp.updated_at
  from public.member_cp cp
  join public.profiles p on p.id = cp.profile_id
  join public.guild_memberships gm
    on gm.profile_id = cp.profile_id
   and gm.guild_id = cp.guild_id
   and gm.membership_status = 'active'
   and gm.is_primary = true
  where cp.guild_id = p_guild_id
    and p.approval_status = 'approved'
  order by cp.cp_value desc, p.ign asc;
end;
$$;

create or replace function public.get_cp_leaderboard(
  p_guild_id uuid,
  p_snapshot_week_start date default null
)
returns table (
  leaderboard_rank integer,
  profile_id uuid,
  username text,
  ign text,
  cp_value integer
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_view_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to view CP leaderboard for this guild.';
  end if;

  if p_snapshot_week_start is null then
    return query
    select row_number() over (order by cp.cp_value desc, p.ign asc)::integer,
           p.id,
           p.username,
           p.ign,
           cp.cp_value
    from public.member_cp cp
    join public.profiles p on p.id = cp.profile_id
    join public.guild_memberships gm
      on gm.profile_id = cp.profile_id
     and gm.guild_id = cp.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
    where cp.guild_id = p_guild_id
      and p.approval_status = 'approved';
  else
    return query
    select row_number() over (order by cs.cp_value desc, p.ign asc)::integer,
           p.id,
           p.username,
           p.ign,
           cs.cp_value
    from public.cp_snapshots cs
    join public.profiles p on p.id = cs.profile_id
    join public.guild_memberships gm
      on gm.profile_id = cs.profile_id
     and gm.guild_id = cs.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
    where cs.guild_id = p_guild_id
      and cs.snapshot_week_start = p_snapshot_week_start
      and p.approval_status = 'approved';
  end if;
end;
$$;

create or replace function public.get_cp_growth_report(
  p_guild_id uuid,
  p_from_week date,
  p_to_week date
)
returns table (
  profile_id uuid,
  username text,
  ign text,
  from_cp integer,
  to_cp integer,
  growth integer
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_view_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to view CP growth for this guild.';
  end if;

  return query
  select p.id,
         p.username,
         p.ign,
         from_snap.cp_value,
         to_snap.cp_value,
         to_snap.cp_value - from_snap.cp_value
  from public.cp_snapshots from_snap
  join public.cp_snapshots to_snap
    on to_snap.profile_id = from_snap.profile_id
   and to_snap.guild_id = from_snap.guild_id
  join public.profiles p on p.id = from_snap.profile_id
  join public.guild_memberships gm
    on gm.profile_id = from_snap.profile_id
   and gm.guild_id = from_snap.guild_id
   and gm.membership_status = 'active'
   and gm.is_primary = true
  where from_snap.guild_id = p_guild_id
    and from_snap.snapshot_week_start = p_from_week
    and to_snap.snapshot_week_start = p_to_week
    and p.approval_status = 'approved'
  order by (to_snap.cp_value - from_snap.cp_value) desc, p.ign asc;
end;
$$;

create or replace function public.create_gvg_event(
  p_title text,
  p_scope text,
  p_guild_id uuid default null,
  p_starts_at timestamptz default null,
  p_ends_at timestamptz default null
)
returns public.gvg_events
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  new_event public.gvg_events%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_title is null or btrim(p_title) = '' then
    raise exception 'GvG event title is required.';
  end if;

  if p_scope = 'global' then
    if p_guild_id is not null or not private.is_owner(actor_id) then
      raise exception 'Only Owner can create global GvG events.';
    end if;
  elsif p_scope = 'guild' then
    if p_guild_id is null or not private.can_manage_gvg(actor_id, p_guild_id) then
      raise exception 'Not authorized to create GvG events for this guild.';
    end if;
  else
    raise exception 'Invalid GvG event scope.';
  end if;

  insert into public.gvg_events (guild_id, scope, title, status, starts_at, ends_at, created_by)
  values (p_guild_id, p_scope, btrim(p_title), 'draft', p_starts_at, p_ends_at, actor_id)
  returning * into new_event;

  perform private.write_audit_log(
    actor_id,
    null,
    p_guild_id,
    'gvg_event_created',
    'gvg_events',
    new_event.id,
    jsonb_build_object('scope', p_scope, 'status_new', 'draft')
  );

  return new_event;
end;
$$;

create or replace function public.set_gvg_event_status(
  p_event_id uuid,
  p_status text
)
returns public.gvg_events
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  old_status text;
  target_guild_id uuid;
  updated_event public.gvg_events%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_status not in ('draft', 'active', 'closed', 'cancelled', 'archived') then
    raise exception 'Invalid GvG event status.';
  end if;

  if not private.can_manage_gvg_event(actor_id, p_event_id) then
    raise exception 'Not authorized to update this GvG event.';
  end if;

  select status, guild_id into old_status, target_guild_id
  from public.gvg_events
  where id = p_event_id;

  update public.gvg_events
  set status = p_status, updated_at = now()
  where id = p_event_id
  returning * into updated_event;

  perform private.write_audit_log(
    actor_id,
    null,
    target_guild_id,
    'gvg_event_status_updated',
    'gvg_events',
    p_event_id,
    jsonb_build_object('status_old', old_status, 'status_new', p_status)
  );

  return updated_event;
end;
$$;

create or replace function public.submit_gvg_vote(
  p_event_id uuid,
  p_vote_status text,
  p_absence_reason text default null
)
returns public.gvg_votes
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_reason text;
  updated_vote public.gvg_votes%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_vote_status not in ('present', 'absent') then
    raise exception 'Invalid GvG vote status.';
  end if;

  if not private.can_submit_gvg_vote(actor_id, p_event_id) then
    raise exception 'Not authorized to vote on this GvG event.';
  end if;

  normalized_reason := case
    when p_vote_status = 'absent' then nullif(btrim(coalesce(p_absence_reason, '')), '')
    else null
  end;

  if normalized_reason is not null and char_length(normalized_reason) > 500 then
    raise exception 'Absence reason cannot exceed 500 characters.';
  end if;

  insert into public.gvg_votes (gvg_event_id, profile_id, vote_status, absence_reason)
  values (p_event_id, actor_id, p_vote_status, normalized_reason)
  on conflict (gvg_event_id, profile_id) do update
  set
    vote_status = excluded.vote_status,
    absence_reason = excluded.absence_reason,
    updated_at = now()
  returning * into updated_vote;

  return updated_vote;
end;
$$;

create or replace function public.get_gvg_results(p_event_id uuid)
returns table (
  profile_id uuid,
  username text,
  ign text,
  vote_status text,
  absence_reason text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_read_gvg_results(actor_id, p_event_id) then
    raise exception 'Not authorized to read GvG results.';
  end if;

  return query
  select p.id,
         p.username,
         p.ign,
         gv.vote_status,
         gv.absence_reason,
         gv.updated_at
  from public.gvg_votes gv
  join public.profiles p on p.id = gv.profile_id
  where gv.gvg_event_id = p_event_id
  order by gv.vote_status desc, p.ign asc;
end;
$$;

revoke all on function public.register_profile(text, text, uuid) from public, anon;
revoke all on function public.request_reapply(text) from public, anon;
revoke all on function public.approve_registration(uuid, uuid, text) from public, anon;
revoke all on function public.reject_registration(uuid, text) from public, anon;
revoke all on function public.update_my_profile(text, text) from public, anon;
revoke all on function public.admin_update_member_ign(uuid, text) from public, anon;
revoke all on function public.admin_reset_profile_slug(uuid, text) from public, anon;
revoke all on function public.assign_member_role(uuid, uuid, text) from public, anon;
revoke all on function public.grant_admin_permission(uuid, text) from public, anon;
revoke all on function public.revoke_admin_permission(uuid, text) from public, anon;
revoke all on function public.update_member_cp(uuid, integer, text) from public, anon;
revoke all on function public.capture_weekly_cp_snapshot(uuid, date) from public, anon;
revoke all on function public.get_current_cp_roster(uuid) from public, anon;
revoke all on function public.get_cp_leaderboard(uuid, date) from public, anon;
revoke all on function public.get_cp_growth_report(uuid, date, date) from public, anon;
revoke all on function public.create_gvg_event(text, text, uuid, timestamptz, timestamptz) from public, anon;
revoke all on function public.set_gvg_event_status(uuid, text) from public, anon;
revoke all on function public.submit_gvg_vote(uuid, text, text) from public, anon;
revoke all on function public.get_gvg_results(uuid) from public, anon;

grant execute on function public.register_profile(text, text, uuid) to authenticated;
grant execute on function public.request_reapply(text) to authenticated;
grant execute on function public.approve_registration(uuid, uuid, text) to authenticated;
grant execute on function public.reject_registration(uuid, text) to authenticated;
grant execute on function public.update_my_profile(text, text) to authenticated;
grant execute on function public.admin_update_member_ign(uuid, text) to authenticated;
grant execute on function public.admin_reset_profile_slug(uuid, text) to authenticated;
grant execute on function public.assign_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.grant_admin_permission(uuid, text) to authenticated;
grant execute on function public.revoke_admin_permission(uuid, text) to authenticated;
grant execute on function public.update_member_cp(uuid, integer, text) to authenticated;
grant execute on function public.capture_weekly_cp_snapshot(uuid, date) to authenticated;
grant execute on function public.get_current_cp_roster(uuid) to authenticated;
grant execute on function public.get_cp_leaderboard(uuid, date) to authenticated;
grant execute on function public.get_cp_growth_report(uuid, date, date) to authenticated;
grant execute on function public.create_gvg_event(text, text, uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.set_gvg_event_status(uuid, text) to authenticated;
grant execute on function public.submit_gvg_vote(uuid, text, text) to authenticated;
grant execute on function public.get_gvg_results(uuid) to authenticated;
