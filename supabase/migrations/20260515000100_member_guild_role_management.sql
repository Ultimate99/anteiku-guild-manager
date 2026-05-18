-- Anteiku Guild Manager - Member Guild + Role Management
-- Safe migration: hardens normal app role assignment and adds Owner-only guild transfer.
-- Does not edit CP tables, GvG tables, RLS policies, frontend code, or package files.
-- Owner role assignment remains manual-only and is intentionally blocked in the normal app RPC.

create or replace function private.can_assign_role(
  p_actor_id uuid,
  p_guild_id uuid,
  p_new_role text
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select case
    when p_new_role = 'owner' then false
    when private.is_owner(p_actor_id) then p_new_role in ('member', 'admin', 'vice', 'leader')
    when private.has_role(p_actor_id, p_guild_id, array['leader', 'vice']) then p_new_role in ('member', 'admin')
    when private.has_permission(p_actor_id, p_guild_id, 'manage_roles') then p_new_role in ('member', 'admin')
    else false
  end;
$$;

create or replace function private.can_transfer_member_guild(
  p_actor_id uuid,
  p_profile_id uuid,
  p_from_guild_id uuid,
  p_to_guild_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    and p_actor_id <> p_profile_id
    and p_from_guild_id <> p_to_guild_id;
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
  normalized_role text := lower(btrim(coalesce(p_role, '')));
  target_membership public.guild_memberships%rowtype;
  updated_membership public.guild_memberships%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if normalized_role = 'owner' then
    raise exception 'Owner role assignment is manual-only.';
  end if;

  if not private.is_approved(p_profile_id) then
    raise exception 'Target profile must be approved.';
  end if;

  select gm.* into target_membership
  from public.guild_memberships gm
  where gm.profile_id = p_profile_id
    and gm.guild_id = p_guild_id
    and gm.membership_status = 'active'
    and gm.is_primary = true;

  if not found then
    raise exception 'Active primary membership not found for this guild.';
  end if;

  if target_membership.role = 'owner' then
    raise exception 'Owner memberships must be managed manually.';
  end if;

  if not private.can_assign_role(actor_id, p_guild_id, normalized_role) then
    raise exception 'Not authorized to assign this role.';
  end if;

  update public.guild_memberships
  set
    role = normalized_role,
    assigned_by = actor_id,
    updated_at = now()
  where id = target_membership.id
  returning * into updated_membership;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    p_guild_id,
    'member_role_changed',
    'guild_memberships',
    updated_membership.id,
    jsonb_build_object(
      'role_old', target_membership.role,
      'role_new', updated_membership.role,
      'guild_id', p_guild_id,
      'normal_app_rpc', true
    )
  );

  return updated_membership;
end;
$$;

create or replace function public.transfer_member_guild(
  p_profile_id uuid,
  p_from_guild_id uuid,
  p_to_guild_id uuid
)
returns public.guild_memberships
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  source_membership public.guild_memberships%rowtype;
  target_membership public.guild_memberships%rowtype;
  active_primary_count integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.can_transfer_member_guild(actor_id, p_profile_id, p_from_guild_id, p_to_guild_id) then
    raise exception 'Only Owners can transfer members between guilds.';
  end if;

  if not private.is_approved(p_profile_id) then
    raise exception 'Target profile must be approved.';
  end if;

  if not exists (
    select 1
    from public.guilds g
    where g.id = p_to_guild_id
      and g.status = 'active'
  ) then
    raise exception 'Target guild must be active.';
  end if;

  select gm.* into source_membership
  from public.guild_memberships gm
  where gm.profile_id = p_profile_id
    and gm.guild_id = p_from_guild_id
    and gm.membership_status = 'active'
    and gm.is_primary = true;

  if not found then
    raise exception 'Source active primary membership not found.';
  end if;

  if source_membership.role = 'owner' then
    raise exception 'Owner memberships must be managed manually.';
  end if;

  if exists (
    select 1
    from public.guild_memberships gm
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.guild_id <> p_from_guild_id
  ) then
    raise exception 'Profile already has another active primary membership.';
  end if;

  update public.guild_memberships
  set
    membership_status = 'left',
    is_primary = false,
    updated_at = now()
  where id = source_membership.id;

  insert into public.guild_memberships (
    profile_id,
    guild_id,
    role,
    membership_status,
    is_primary,
    assigned_by
  )
  values (
    p_profile_id,
    p_to_guild_id,
    'member',
    'active',
    true,
    actor_id
  )
  on conflict (profile_id, guild_id) do update
  set
    role = 'member',
    membership_status = 'active',
    is_primary = true,
    assigned_by = actor_id,
    updated_at = now()
  returning * into target_membership;

  select count(*) into active_primary_count
  from public.guild_memberships gm
  where gm.profile_id = p_profile_id
    and gm.membership_status = 'active'
    and gm.is_primary = true;

  if active_primary_count <> 1 then
    raise exception 'Transfer failed to preserve exactly one active primary membership.';
  end if;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    p_to_guild_id,
    'member_guild_transferred',
    'guild_memberships',
    target_membership.id,
    jsonb_build_object(
      'from_guild_id', p_from_guild_id,
      'to_guild_id', p_to_guild_id,
      'old_membership_id', source_membership.id,
      'new_membership_id', target_membership.id,
      'role_old', source_membership.role,
      'role_new', target_membership.role,
      'old_membership_status_new', 'left',
      'new_membership_status_new', 'active',
      'normal_app_rpc', true
    )
  );

  return target_membership;
end;
$$;

revoke all on function public.transfer_member_guild(uuid, uuid, uuid) from public, anon;
grant execute on function public.transfer_member_guild(uuid, uuid, uuid) to authenticated;

revoke all on function public.assign_member_role(uuid, uuid, text) from public, anon;
grant execute on function public.assign_member_role(uuid, uuid, text) to authenticated;
