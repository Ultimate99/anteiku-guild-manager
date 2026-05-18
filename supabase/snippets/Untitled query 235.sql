begin;

do $$
declare
  owner_user_id uuid := '7d1d78c6-3545-4522-9861-62ee979a32e6';
  owner_guild_id uuid;
begin
  select id
  into owner_guild_id
  from public.guilds
  where slug = 'anteiku'
    and is_core = true
    and status = 'active'
  limit 1;

  if owner_guild_id is null then
    raise exception 'Core guild Anteiku was not found.';
  end if;

  update public.profiles
  set
    approval_status = 'approved',
    approved_at = now(),
    approved_by = owner_user_id,
    rejected_at = null,
    rejected_by = null,
    reapply_requested_at = null,
    reapply_note = null,
    updated_at = now()
  where id = owner_user_id;

  if not found then
    raise exception 'Profile not found for auth user id %. Register through the app first.', owner_user_id;
  end if;

  insert into public.guild_memberships (
    profile_id,
    guild_id,
    role,
    membership_status,
    is_primary,
    assigned_by,
    updated_at
  )
  values (
    owner_user_id,
    owner_guild_id,
    'owner',
    'active',
    true,
    owner_user_id,
    now()
  )
  on conflict (profile_id, guild_id) do update
  set
    role = 'owner',
    membership_status = 'active',
    is_primary = true,
    assigned_by = owner_user_id,
    updated_at = now();

  insert into public.audit_logs (
    actor_profile_id,
    target_profile_id,
    guild_id,
    action,
    entity_table,
    entity_id,
    metadata
  )
  values (
    owner_user_id,
    owner_user_id,
    owner_guild_id,
    'local_owner_bootstrap',
    'profiles',
    owner_user_id,
    jsonb_build_object(
      'local_only', true,
      'email', 'test1@local.dev',
      'role_new', 'owner',
      'approval_status_new', 'approved'
    )
  );
end $$;

commit;
