-- Milestone 29E.8B: active-admin context foundation.
-- Adds a safe read-only RPC for the selected active profile's admin context.
-- Existing AdminPanel frontend behavior and legacy Admin RPCs remain unchanged.

create or replace function private.get_active_admin_context()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
  context_record record;
  permission_keys text[] := array[]::text[];
  scoped_guild_ids uuid[] := array[]::uuid[];
  active_and_approved boolean := false;
  active_staff boolean := false;
  active_owner boolean := false;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile is required.';
  end if;

  select
    p.id as active_profile_id,
    p.profile_slug,
    p.username,
    p.ign,
    p.approval_status,
    gm.id as membership_id,
    gm.guild_id,
    g.name as guild_name,
    g.slug as guild_slug,
    gm.role,
    gm.membership_status,
    gm.roster_status
  into context_record
  from public.profiles p
  left join lateral (
    select gm_inner.*
    from public.guild_memberships gm_inner
    where gm_inner.profile_id = p.id
      and gm_inner.is_primary = true
    order by
      case gm_inner.membership_status
        when 'active' then 1
        when 'pending' then 2
        when 'rejected' then 3
        when 'suspended' then 4
        when 'left' then 5
        else 6
      end,
      gm_inner.created_at desc
    limit 1
  ) gm on true
  left join public.guilds g on g.id = gm.guild_id
  where p.id = active_profile_id
  limit 1;

  if not found then
    raise exception 'Active profile was not found.';
  end if;

  active_and_approved :=
    context_record.approval_status = 'approved'
    and context_record.membership_status = 'active'
    and coalesce(context_record.roster_status, 'active') not in ('suspended', 'left', 'kicked');

  active_owner :=
    active_and_approved
    and context_record.role = 'owner';

  active_staff :=
    active_and_approved
    and context_record.role in ('owner', 'leader', 'vice', 'admin');

  if active_staff and context_record.membership_id is not null then
    select coalesce(array_agg(distinct ap.permission_key order by ap.permission_key), array[]::text[])
    into permission_keys
    from public.admin_permissions ap
    where ap.membership_id = context_record.membership_id;
  end if;

  if active_staff then
    if active_owner then
      select coalesce(array_agg(guild_scope.id order by guild_scope.name), array[]::uuid[])
      into scoped_guild_ids
      from public.guilds guild_scope
      where guild_scope.status = 'active';
    elsif context_record.guild_id is not null then
      scoped_guild_ids := array[context_record.guild_id];
    end if;
  end if;

  return jsonb_build_object(
    'active_profile_id', context_record.active_profile_id,
    'profile_slug', context_record.profile_slug,
    'username', context_record.username,
    'ign', context_record.ign,
    'guild_id', context_record.guild_id,
    'guild_name', context_record.guild_name,
    'guild_slug', context_record.guild_slug,
    'role', context_record.role,
    'is_owner', active_owner,
    'is_leader', active_and_approved and context_record.role = 'leader',
    'is_vice', active_and_approved and context_record.role = 'vice',
    'is_admin', active_and_approved and context_record.role = 'admin',
    'is_staff', active_staff,
    'permission_keys', to_jsonb(permission_keys),
    'can_access_admin_panel', active_staff,
    'scoped_guild_ids', to_jsonb(scoped_guild_ids),
    'active_profile_status', context_record.approval_status,
    'membership_status', context_record.membership_status,
    'roster_status', context_record.roster_status,
    'scope', case
      when active_owner then 'global'
      when active_staff then 'guild'
      else 'none'
    end
  );
end;
$$;

create or replace function public.get_my_active_admin_context()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  return private.get_active_admin_context();
end;
$$;

revoke all on function private.get_active_admin_context() from public, anon, authenticated;
revoke all on function public.get_my_active_admin_context() from public, anon;
grant execute on function public.get_my_active_admin_context() to authenticated;
