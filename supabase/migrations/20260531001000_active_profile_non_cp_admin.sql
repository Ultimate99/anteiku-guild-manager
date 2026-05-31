-- Milestone 29E.8D: active-profile non-CP Admin migration.
-- Migrates non-CP Admin reads/actions to the selected active admin profile.
-- Intentionally does not migrate Admin CP, CP Ranking, Analytics, Weekly Growth, or Audit Logs.

create or replace function private.active_admin_profile_id()
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  active_profile_id uuid;
  context_payload jsonb;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile is required.';
  end if;

  context_payload := private.get_active_admin_context();

  if coalesce((context_payload->>'can_access_admin_panel')::boolean, false) is not true then
    raise exception 'Admin access is not available for this active profile.';
  end if;

  return active_profile_id;
end;
$$;

revoke all on function private.active_admin_profile_id() from public, anon, authenticated;

create or replace function public.get_admin_approval_queue()
returns table (
  id uuid,
  profile_id uuid,
  guild_id uuid,
  role text,
  membership_status text,
  is_primary boolean,
  created_at timestamptz,
  updated_at timestamptz,
  profile jsonb,
  guild jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  actor_guild_id uuid := private.active_primary_guild_id(actor_id);
  actor_is_owner boolean := private.is_owner(actor_id);
begin
  if not actor_is_owner and (
    actor_guild_id is null
    or not private.can_approve_members(actor_id, actor_guild_id)
  ) then
    raise exception 'Not authorized to review approvals.';
  end if;

  return query
  select
    gm.id,
    gm.profile_id,
    gm.guild_id,
    gm.role,
    gm.membership_status,
    gm.is_primary,
    gm.created_at,
    gm.updated_at,
    jsonb_build_object(
      'id', p.id,
      'username', p.username,
      'profile_slug', p.profile_slug,
      'ign', p.ign,
      'avatar_key', p.avatar_key,
      'approval_status', p.approval_status,
      'reapply_requested_at', p.reapply_requested_at,
      'reapply_note', p.reapply_note,
      'created_at', p.created_at,
      'updated_at', p.updated_at
    ) as profile,
    jsonb_build_object(
      'id', g.id,
      'name', g.name,
      'slug', g.slug
    ) as guild
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  left join public.guilds g on g.id = gm.guild_id
  where gm.is_primary = true
    and (
      gm.membership_status = 'pending'
      or (
        gm.membership_status = 'rejected'
        and p.approval_status = 'rejected'
        and p.reapply_requested_at is not null
      )
    )
    and (actor_is_owner or gm.guild_id = actor_guild_id)
    and (actor_is_owner or private.can_approve_members(actor_id, gm.guild_id))
  order by gm.created_at asc;
end;
$$;

create or replace function public.get_admin_member_roster()
returns table (
  id uuid,
  profile_id uuid,
  guild_id uuid,
  role text,
  membership_status text,
  roster_status text,
  is_primary boolean,
  created_at timestamptz,
  updated_at timestamptz,
  profile jsonb,
  guild jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  actor_guild_id uuid := private.active_primary_guild_id(actor_id);
  actor_is_owner boolean := private.is_owner(actor_id);
begin
  if not actor_is_owner and (
    actor_guild_id is null
    or not (
      private.has_role(actor_id, actor_guild_id, array['leader', 'vice'])
      or private.has_permission(actor_id, actor_guild_id, 'manage_members')
      or private.has_permission(actor_id, actor_guild_id, 'edit_member_ign')
      or private.has_permission(actor_id, actor_guild_id, 'reset_profile_slug')
      or private.has_permission(actor_id, actor_guild_id, 'manage_roles')
    )
  ) then
    raise exception 'Not authorized to view member management.';
  end if;

  return query
  select
    gm.id,
    gm.profile_id,
    gm.guild_id,
    gm.role,
    gm.membership_status,
    gm.roster_status,
    gm.is_primary,
    gm.created_at,
    gm.updated_at,
    jsonb_build_object(
      'id', p.id,
      'username', p.username,
      'profile_slug', p.profile_slug,
      'ign', p.ign,
      'avatar_key', p.avatar_key,
      'approval_status', p.approval_status,
      'created_at', p.created_at,
      'updated_at', p.updated_at
    ) as profile,
    jsonb_build_object(
      'id', g.id,
      'name', g.name,
      'slug', g.slug
    ) as guild
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  left join public.guilds g on g.id = gm.guild_id
  where gm.is_primary = true
    and gm.membership_status in ('active', 'suspended', 'left')
    and p.approval_status = 'approved'
    and (actor_is_owner or gm.guild_id = actor_guild_id)
  order by gm.created_at asc;
end;
$$;

create or replace function public.get_admin_permission_management()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  actor_guild_id uuid := private.active_primary_guild_id(actor_id);
  actor_is_owner boolean := private.is_owner(actor_id);
  catalog_payload jsonb;
  targets_payload jsonb;
begin
  if not actor_is_owner and (
    actor_guild_id is null
    or not private.has_role(actor_id, actor_guild_id, array['leader', 'vice'])
  ) then
    raise exception 'Not authorized to manage admin permissions.';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'key', pc.key,
        'label', pc.label,
        'description', pc.description,
        'is_sensitive', pc.is_sensitive
      )
      order by array_position(
        array[
          'approve_members',
          'manage_members',
          'edit_member_ign',
          'reset_profile_slug',
          'manage_roles',
          'view_cp',
          'update_cp',
          'manage_gvg',
          'view_audit_logs'
        ],
        pc.key
      )
    ),
    '[]'::jsonb
  )
  into catalog_payload
  from public.permission_catalog pc
  where pc.key in (
    'approve_members',
    'manage_members',
    'edit_member_ign',
    'reset_profile_slug',
    'manage_roles',
    'view_cp',
    'update_cp',
    'manage_gvg',
    'view_audit_logs'
  );

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', gm.id,
        'profile_id', gm.profile_id,
        'guild_id', gm.guild_id,
        'role', gm.role,
        'membership_status', gm.membership_status,
        'is_primary', gm.is_primary,
        'created_at', gm.created_at,
        'updated_at', gm.updated_at,
        'profile', jsonb_build_object(
          'id', p.id,
          'username', p.username,
          'profile_slug', p.profile_slug,
          'ign', p.ign,
          'approval_status', p.approval_status
        ),
        'guild', jsonb_build_object(
          'id', g.id,
          'name', g.name,
          'slug', g.slug
        ),
        'permissionKeys', coalesce(
          (
            select jsonb_agg(ap.permission_key order by ap.permission_key)
            from public.admin_permissions ap
            where ap.membership_id = gm.id
          ),
          '[]'::jsonb
        )
      )
      order by gm.created_at asc
    ),
    '[]'::jsonb
  )
  into targets_payload
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  left join public.guilds g on g.id = gm.guild_id
  where gm.role = 'admin'
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and p.approval_status = 'approved'
    and (actor_is_owner or gm.guild_id = actor_guild_id);

  return jsonb_build_object(
    'catalog', catalog_payload,
    'targets', targets_payload
  );
end;
$$;

create or replace function public.get_admin_gvg_events()
returns table (
  id uuid,
  guild_id uuid,
  scope text,
  title text,
  status text,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz,
  updated_at timestamptz,
  guild jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  actor_guild_id uuid := private.active_primary_guild_id(actor_id);
  actor_is_owner boolean := private.is_owner(actor_id);
begin
  if not actor_is_owner and (
    actor_guild_id is null
    or not private.can_manage_gvg(actor_id, actor_guild_id)
  ) then
    raise exception 'Not authorized to manage GvG events.';
  end if;

  return query
  select
    ge.id,
    ge.guild_id,
    ge.scope,
    ge.title,
    ge.status,
    ge.starts_at,
    ge.ends_at,
    ge.created_at,
    ge.updated_at,
    case
      when g.id is null then null
      else jsonb_build_object(
        'id', g.id,
        'name', g.name,
        'slug', g.slug
      )
    end as guild
  from public.gvg_events ge
  left join public.guilds g on g.id = ge.guild_id
  where actor_is_owner
     or (ge.scope = 'guild' and ge.guild_id = actor_guild_id)
  order by ge.created_at desc
  limit 20;
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
  actor_id uuid := private.active_admin_profile_id();
  updated_profile public.profiles%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  old_ign text;
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  normalized_slug text := private.normalize_profile_slug(p_new_slug);
  old_slug text;
  target_guild_id uuid;
  updated_profile public.profiles%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  normalized_role text := lower(btrim(coalesce(p_role, '')));
  target_membership public.guild_memberships%rowtype;
  updated_membership public.guild_memberships%rowtype;
begin
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
      'normal_app_rpc', true,
      'active_admin_profile', true
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
  actor_id uuid := private.active_admin_profile_id();
  source_membership public.guild_memberships%rowtype;
  target_membership public.guild_memberships%rowtype;
  active_primary_count integer;
begin
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
      'normal_app_rpc', true,
      'active_admin_profile', true
    )
  );

  return target_membership;
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
  actor_id uuid := private.active_admin_profile_id();
  target_membership public.guild_memberships%rowtype;
  new_permission public.admin_permissions%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  target_membership public.guild_memberships%rowtype;
begin
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

create or replace function public.update_member_roster_status(
  p_membership_id uuid,
  p_new_status text,
  p_reason text default null
)
returns public.guild_memberships
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  normalized_status text := lower(btrim(coalesce(p_new_status, '')));
  normalized_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  target_membership public.guild_memberships%rowtype;
  target_profile public.profiles%rowtype;
  updated_membership public.guild_memberships%rowtype;
  next_membership_status text;
  next_is_primary boolean;
  actor_is_owner boolean;
  actor_is_scoped_leadership boolean;
  actor_has_manage_members boolean;
  target_is_owner boolean;
  active_owner_count integer;
  other_active_primary_count integer;
begin
  if normalized_status not in (
    'active',
    'trial',
    'inactive',
    'on_break',
    'suspended',
    'left',
    'kicked',
    'pending_transfer'
  ) then
    raise exception 'Invalid roster status.';
  end if;

  if normalized_reason is not null and char_length(normalized_reason) > 1000 then
    raise exception 'Status reason cannot exceed 1000 characters.';
  end if;

  select gm.* into target_membership
  from public.guild_memberships gm
  where gm.id = p_membership_id
  for update;

  if not found then
    raise exception 'Target membership not found.';
  end if;

  select p.* into target_profile
  from public.profiles p
  where p.id = target_membership.profile_id;

  if not found then
    raise exception 'Target profile not found.';
  end if;

  if target_profile.approval_status <> 'approved' then
    raise exception 'Roster status can only be changed for approved profiles.';
  end if;

  actor_is_owner := private.is_owner(actor_id);
  actor_is_scoped_leadership := private.has_role(actor_id, target_membership.guild_id, array['leader', 'vice']);
  actor_has_manage_members := private.has_permission(actor_id, target_membership.guild_id, 'manage_members');
  target_is_owner := target_membership.role = 'owner';

  if actor_id = target_membership.profile_id and not actor_is_owner then
    raise exception 'Only Owner can change their own roster status.';
  end if;

  if target_is_owner and not actor_is_owner then
    raise exception 'Only Owner can change another Owner roster status.';
  end if;

  if actor_is_owner then
    null;
  elsif actor_is_scoped_leadership then
    if target_is_owner then
      raise exception 'Leader/Vice cannot affect Owner roster status.';
    end if;
  elsif actor_has_manage_members then
    if target_is_owner then
      raise exception 'Admin cannot affect Owner roster status.';
    end if;

    if normalized_status not in ('active', 'trial', 'inactive', 'on_break', 'pending_transfer') then
      raise exception 'Admin with manage_members cannot set hard-block roster statuses.';
    end if;

    if target_membership.membership_status <> 'active' then
      raise exception 'Admin cannot restore hard-blocked memberships.';
    end if;
  else
    raise exception 'Not authorized to update member roster status.';
  end if;

  next_membership_status := case normalized_status
    when 'suspended' then 'suspended'
    when 'left' then 'left'
    when 'kicked' then 'left'
    else 'active'
  end;

  if target_is_owner
     and target_membership.membership_status = 'active'
     and next_membership_status <> 'active' then
    select count(*) into active_owner_count
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.role = 'owner'
      and gm.membership_status = 'active'
      and p.approval_status = 'approved';

    if active_owner_count <= 1 then
      raise exception 'Cannot remove or block the last active Owner.';
    end if;
  end if;

  if next_membership_status = 'active'
     and target_membership.membership_status <> 'active'
     and not (actor_is_owner or actor_is_scoped_leadership) then
    raise exception 'Only Owner or scoped Leader/Vice can restore hard-blocked memberships.';
  end if;

  next_is_primary := target_membership.is_primary;

  if next_membership_status = 'active'
     and target_membership.membership_status <> 'active' then
    select count(*) into other_active_primary_count
    from public.guild_memberships gm
    where gm.profile_id = target_membership.profile_id
      and gm.id <> target_membership.id
      and gm.membership_status = 'active'
      and gm.is_primary = true;

    if other_active_primary_count > 0 then
      raise exception 'Cannot restore membership while another active primary membership exists.';
    end if;

    next_is_primary := true;
  end if;

  update public.guild_memberships
  set
    roster_status = normalized_status,
    membership_status = next_membership_status,
    is_primary = next_is_primary,
    updated_at = now()
  where id = target_membership.id
  returning * into updated_membership;

  insert into public.member_status_history (
    membership_id,
    profile_id,
    guild_id,
    old_status,
    new_status,
    reason,
    changed_by
  )
  values (
    target_membership.id,
    target_membership.profile_id,
    target_membership.guild_id,
    target_membership.roster_status,
    normalized_status,
    normalized_reason,
    actor_id
  );

  perform private.write_audit_log(
    actor_id,
    target_membership.profile_id,
    target_membership.guild_id,
    'member_roster_status_changed',
    'guild_memberships',
    target_membership.id,
    jsonb_build_object(
      'old_status', target_membership.roster_status,
      'new_status', normalized_status,
      'membership_id', target_membership.id,
      'guild_id', target_membership.guild_id,
      'reason_provided', normalized_reason is not null,
      'membership_status_old', target_membership.membership_status,
      'membership_status_new', next_membership_status
    )
  );

  return updated_membership;
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
  actor_id uuid := private.active_admin_profile_id();
  new_event public.gvg_events%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
  old_status text;
  target_guild_id uuid;
  updated_event public.gvg_events%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
begin
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

create or replace function public.admin_grant_cosmetic(
  p_profile_id uuid,
  p_cosmetic_key text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  target_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_cosmetic_key, '')), '');
  normalized_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  selected_cosmetic public.cosmetic_catalog%rowtype;
  target_unlock public.profile_cosmetic_unlocks%rowtype;
begin
  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if p_profile_id is null then
    raise exception 'Target profile is required.';
  end if;

  target_guild_id := private.active_primary_guild_id(p_profile_id);

  if target_guild_id is null then
    raise exception 'Target approved active membership required.';
  end if;

  if normalized_key is null then
    raise exception 'Cosmetic key is required.';
  end if;

  select * into selected_cosmetic
  from public.cosmetic_catalog c
  where c.key = normalized_key
    and c.is_active = true;

  if not found then
    raise exception 'Invalid cosmetic.';
  end if;

  if normalized_reason is not null and char_length(normalized_reason) > 1000 then
    raise exception 'Cosmetic grant reason is too long.';
  end if;

  insert into public.profile_cosmetic_unlocks (
    profile_id,
    cosmetic_key,
    unlocked_by,
    reason
  )
  values (
    p_profile_id,
    selected_cosmetic.key,
    actor_id,
    normalized_reason
  )
  on conflict (profile_id, cosmetic_key) do update
  set
    unlocked_by = excluded.unlocked_by,
    reason = excluded.reason
  returning * into target_unlock;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'cosmetic_granted',
    'profile_cosmetic_unlocks',
    p_profile_id,
    jsonb_build_object(
      'cosmetic_key', selected_cosmetic.key,
      'cosmetic_type', selected_cosmetic.type,
      'reason_provided', normalized_reason is not null
    )
  );

  return jsonb_build_object(
    'profile_id', target_unlock.profile_id,
    'cosmetic_key', target_unlock.cosmetic_key,
    'cosmetic_type', selected_cosmetic.type,
    'unlocked_at', target_unlock.unlocked_at
  );
end;
$$;

create or replace function public.admin_grant_cosmetic_by_slug(
  p_profile_slug text,
  p_cosmetic_key text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  target_profile public.profiles%rowtype;
  grant_payload jsonb;
begin
  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Invalid profile slug.';
  end if;

  select * into target_profile
  from public.profiles p
  where p.profile_slug = normalized_slug
     or p.username = normalized_slug
  limit 1;

  if not found then
    raise exception 'Target profile not found.';
  end if;

  grant_payload := public.admin_grant_cosmetic(
    target_profile.id,
    p_cosmetic_key,
    p_reason
  );

  return jsonb_build_object(
    'target_profile_id', target_profile.id,
    'username', target_profile.username,
    'profile_slug', target_profile.profile_slug,
    'cosmetic_key', grant_payload ->> 'cosmetic_key',
    'cosmetic_type', grant_payload ->> 'cosmetic_type',
    'unlocked_at', grant_payload ->> 'unlocked_at'
  );
end;
$$;

revoke all on function public.get_admin_approval_queue() from public, anon;
revoke all on function public.get_admin_member_roster() from public, anon;
revoke all on function public.get_admin_permission_management() from public, anon;
revoke all on function public.get_admin_gvg_events() from public, anon;
revoke all on function public.approve_registration(uuid, uuid, text) from public, anon;
revoke all on function public.reject_registration(uuid, text) from public, anon;
revoke all on function public.admin_update_member_ign(uuid, text) from public, anon;
revoke all on function public.admin_reset_profile_slug(uuid, text) from public, anon;
revoke all on function public.assign_member_role(uuid, uuid, text) from public, anon;
revoke all on function public.transfer_member_guild(uuid, uuid, uuid) from public, anon;
revoke all on function public.grant_admin_permission(uuid, text) from public, anon;
revoke all on function public.revoke_admin_permission(uuid, text) from public, anon;
revoke all on function public.update_member_roster_status(uuid, text, text) from public, anon;
revoke all on function public.create_gvg_event(text, text, uuid, timestamptz, timestamptz) from public, anon;
revoke all on function public.set_gvg_event_status(uuid, text) from public, anon;
revoke all on function public.get_gvg_results(uuid) from public, anon;
revoke all on function public.admin_grant_cosmetic(uuid, text, text) from public, anon;
revoke all on function public.admin_grant_cosmetic_by_slug(text, text, text) from public, anon;

grant execute on function public.get_admin_approval_queue() to authenticated;
grant execute on function public.get_admin_member_roster() to authenticated;
grant execute on function public.get_admin_permission_management() to authenticated;
grant execute on function public.get_admin_gvg_events() to authenticated;
grant execute on function public.approve_registration(uuid, uuid, text) to authenticated;
grant execute on function public.reject_registration(uuid, text) to authenticated;
grant execute on function public.admin_update_member_ign(uuid, text) to authenticated;
grant execute on function public.admin_reset_profile_slug(uuid, text) to authenticated;
grant execute on function public.assign_member_role(uuid, uuid, text) to authenticated;
grant execute on function public.transfer_member_guild(uuid, uuid, uuid) to authenticated;
grant execute on function public.grant_admin_permission(uuid, text) to authenticated;
grant execute on function public.revoke_admin_permission(uuid, text) to authenticated;
grant execute on function public.update_member_roster_status(uuid, text, text) to authenticated;
grant execute on function public.create_gvg_event(text, text, uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.set_gvg_event_status(uuid, text) to authenticated;
grant execute on function public.get_gvg_results(uuid) to authenticated;
grant execute on function public.admin_grant_cosmetic(uuid, text, text) to authenticated;
grant execute on function public.admin_grant_cosmetic_by_slug(text, text, text) to authenticated;
