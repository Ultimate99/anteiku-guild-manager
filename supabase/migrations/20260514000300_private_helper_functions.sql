-- Anteiku Guild Manager - Private Helper Functions
-- Safe migration: creates the private schema and internal security helpers used by RLS/RPCs.
-- These helpers are not frontend RPC endpoints. Public RPCs must validate auth.uid() and permissions.

create schema if not exists private;

-- Security note:
-- The private schema must not be added to Supabase exposed schemas/PostgREST API schemas.
-- Functions here are internal support for RLS/RPC checks and are not public API endpoints.
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
  select auth.uid();
$$;

create or replace function private.normalize_profile_slug(p_input_value text)
returns text
language sql
immutable
set search_path = pg_catalog
as $$
  select lower(btrim(coalesce(p_input_value, '')));
$$;

create or replace function private.is_valid_profile_slug(p_input_value text)
returns boolean
language sql
immutable
set search_path = pg_catalog
as $$
  select coalesce(p_input_value, '') ~ '^[a-z0-9](?:[a-z0-9_-]{1,30}[a-z0-9])$';
$$;

create or replace function private.is_approved(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = p_profile_id
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.is_owner(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.role = 'owner'
      and gm.membership_status = 'active'
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.active_primary_guild_id(p_profile_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select gm.guild_id
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.profile_id = p_profile_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and p.approval_status = 'approved'
  limit 1;
$$;

create or replace function private.has_active_membership(p_profile_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.guild_id = p_guild_id
      and gm.membership_status = 'active'
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.has_role(p_profile_id uuid, p_guild_id uuid, p_roles text[])
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.guild_id = p_guild_id
      and gm.role = any(p_roles)
      and gm.membership_status = 'active'
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.has_permission(p_profile_id uuid, p_guild_id uuid, p_permission_key text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.admin_permissions ap on ap.membership_id = gm.id
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_profile_id
      and gm.guild_id = p_guild_id
      and gm.role = 'admin'
      and gm.membership_status = 'active'
      and p.approval_status = 'approved'
      and ap.permission_key = p_permission_key
  );
$$;

create or replace function private.can_view_cp(p_actor_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or private.has_role(p_actor_id, p_guild_id, array['leader', 'vice'])
    or private.has_permission(p_actor_id, p_guild_id, 'view_cp');
$$;

create or replace function private.can_update_cp(p_actor_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or private.has_role(p_actor_id, p_guild_id, array['leader', 'vice'])
    or private.has_permission(p_actor_id, p_guild_id, 'update_cp');
$$;

create or replace function private.can_approve_members(p_actor_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or private.has_role(p_actor_id, p_guild_id, array['leader', 'vice'])
    or private.has_permission(p_actor_id, p_guild_id, 'approve_members');
$$;

create or replace function private.can_manage_members(p_actor_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or private.has_role(p_actor_id, p_guild_id, array['leader', 'vice'])
    or private.has_permission(p_actor_id, p_guild_id, 'manage_members');
$$;

create or replace function private.can_assign_role(p_actor_id uuid, p_guild_id uuid, p_new_role text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select case
    when private.is_owner(p_actor_id) then p_new_role in ('owner', 'leader', 'vice', 'admin', 'member')
    when private.has_role(p_actor_id, p_guild_id, array['leader', 'vice']) then p_new_role in ('admin', 'member')
    else false
  end;
$$;

create or replace function private.can_assign_role_on_approval(p_actor_id uuid, p_guild_id uuid, p_new_role text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select case
    when private.is_owner(p_actor_id) then p_new_role in ('owner', 'leader', 'vice', 'admin', 'member')
    when private.has_role(p_actor_id, p_guild_id, array['leader', 'vice']) then p_new_role in ('admin', 'member')
    when private.has_permission(p_actor_id, p_guild_id, 'approve_members') then p_new_role = 'member'
    else false
  end;
$$;

create or replace function private.can_grant_admin_permission(p_actor_id uuid, p_membership_id uuid, p_permission_key text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select case
    when private.is_owner(p_actor_id) then true
    when p_permission_key in ('view_cp', 'update_cp') then false
    else exists (
      select 1
      from public.guild_memberships gm
      where gm.id = p_membership_id
        and gm.role = 'admin'
        and gm.membership_status = 'active'
        and private.has_role(p_actor_id, gm.guild_id, array['leader', 'vice'])
    )
  end;
$$;

create or replace function private.target_primary_guild_id(p_target_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select gm.guild_id
  from public.guild_memberships gm
  where gm.profile_id = p_target_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;
$$;

create or replace function private.requested_or_active_guild_id(p_target_id uuid)
returns uuid
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select gm.guild_id
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.profile_id = p_target_id
    and gm.is_primary = true
    and (
      gm.membership_status = 'active'
      or gm.membership_status = 'pending'
      or (
        gm.membership_status = 'rejected'
        and p.approval_status = 'rejected'
        and p.reapply_requested_at is not null
      )
    )
  order by case gm.membership_status
    when 'pending' then 1
    when 'rejected' then 2
    when 'active' then 3
    else 4
  end
  limit 1;
$$;

create or replace function private.has_pending_or_reapply_membership(p_target_id uuid, p_guild_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.profile_id = p_target_id
      and gm.guild_id = p_guild_id
      and gm.is_primary = true
      and (
        gm.membership_status = 'pending'
        or (
          gm.membership_status = 'rejected'
          and p.approval_status = 'rejected'
          and p.reapply_requested_at is not null
        )
      )
  );
$$;

create or replace function private.can_reset_profile_slug(p_actor_id uuid, p_target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or (
      private.target_primary_guild_id(p_target_id) is not null
      and (
        private.has_role(p_actor_id, private.target_primary_guild_id(p_target_id), array['leader', 'vice'])
        or private.has_permission(p_actor_id, private.target_primary_guild_id(p_target_id), 'reset_profile_slug')
      )
    );
$$;

create or replace function private.can_edit_member_ign(p_actor_id uuid, p_target_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.is_owner(p_actor_id)
    or (
      private.target_primary_guild_id(p_target_id) is not null
      and (
        private.has_role(p_actor_id, private.target_primary_guild_id(p_target_id), array['leader', 'vice'])
        or private.has_permission(p_actor_id, private.target_primary_guild_id(p_target_id), 'edit_member_ign')
      )
    );
$$;

create or replace function private.can_manage_gvg(p_actor_id uuid, p_guild_id uuid)
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
        or private.has_permission(p_actor_id, p_guild_id, 'manage_gvg')
      )
    );
$$;

create or replace function private.can_manage_gvg_event(p_actor_id uuid, p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.gvg_events ge
    where ge.id = p_event_id
      and (
        (ge.scope = 'global' and private.is_owner(p_actor_id))
        or (ge.scope = 'guild' and private.can_manage_gvg(p_actor_id, ge.guild_id))
      )
  );
$$;

create or replace function private.can_read_gvg_results(p_actor_id uuid, p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select private.can_manage_gvg_event(p_actor_id, p_event_id);
$$;

create or replace function private.can_submit_gvg_vote(p_actor_id uuid, p_event_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select exists (
    select 1
    from public.gvg_events ge
    where ge.id = p_event_id
      and ge.status = 'active'
      and private.is_approved(p_actor_id)
      and (
        (ge.scope = 'global' and private.active_primary_guild_id(p_actor_id) is not null)
        or (ge.scope = 'guild' and private.has_active_membership(p_actor_id, ge.guild_id))
      )
  );
$$;

create or replace function private.can_read_audit_logs(p_actor_id uuid, p_guild_id uuid)
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
        or private.has_permission(p_actor_id, p_guild_id, 'view_audit_logs')
      )
    );
$$;

create or replace function private.write_audit_log(
  p_actor_id uuid,
  p_target_id uuid,
  p_guild_id uuid,
  p_action text,
  p_entity_table text,
  p_entity_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  new_log_id uuid;
begin
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
    p_actor_id,
    p_target_id,
    p_guild_id,
    p_action,
    p_entity_table,
    p_entity_id,
    coalesce(p_metadata, '{}'::jsonb)
  )
  returning id into new_log_id;

  return new_log_id;
end;
$$;

revoke all on all functions in schema private from public;
revoke all on all functions in schema private from anon;
revoke all on all functions in schema private from authenticated;

grant execute on function private.current_profile_id() to authenticated;
grant execute on function private.is_approved(uuid) to authenticated;
grant execute on function private.is_owner(uuid) to authenticated;
grant execute on function private.active_primary_guild_id(uuid) to authenticated;
grant execute on function private.has_active_membership(uuid, uuid) to authenticated;
grant execute on function private.has_role(uuid, uuid, text[]) to authenticated;
grant execute on function private.has_permission(uuid, uuid, text) to authenticated;
grant execute on function private.can_view_cp(uuid, uuid) to authenticated;
grant execute on function private.can_update_cp(uuid, uuid) to authenticated;
grant execute on function private.can_approve_members(uuid, uuid) to authenticated;
grant execute on function private.can_manage_members(uuid, uuid) to authenticated;
grant execute on function private.can_assign_role(uuid, uuid, text) to authenticated;
grant execute on function private.can_assign_role_on_approval(uuid, uuid, text) to authenticated;
grant execute on function private.can_grant_admin_permission(uuid, uuid, text) to authenticated;
grant execute on function private.target_primary_guild_id(uuid) to authenticated;
grant execute on function private.requested_or_active_guild_id(uuid) to authenticated;
grant execute on function private.has_pending_or_reapply_membership(uuid, uuid) to authenticated;
grant execute on function private.can_reset_profile_slug(uuid, uuid) to authenticated;
grant execute on function private.can_edit_member_ign(uuid, uuid) to authenticated;
grant execute on function private.can_manage_gvg(uuid, uuid) to authenticated;
grant execute on function private.can_manage_gvg_event(uuid, uuid) to authenticated;
grant execute on function private.can_read_gvg_results(uuid, uuid) to authenticated;
grant execute on function private.can_submit_gvg_vote(uuid, uuid) to authenticated;
grant execute on function private.can_read_audit_logs(uuid, uuid) to authenticated;

revoke all on function private.write_audit_log(uuid, uuid, uuid, text, text, uuid, jsonb)
  from public, anon, authenticated;
