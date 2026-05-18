-- Anteiku Guild Manager - CP RPC Hardening
-- Safe migration: hardens CP update eligibility and improves admin CP roster completeness.
-- This migration does not change frontend code, CP table RLS, GvG logic, or package files.
-- CP access remains RPC-only and permission-checked.

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
  target_profile public.profiles%rowtype;
  target_guild_id uuid;
  old_cp integer;
  updated_cp public.member_cp%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_profile
  from public.profiles p
  where p.id = p_profile_id;

  if not found then
    raise exception 'Target profile not found.';
  end if;

  if target_profile.approval_status <> 'approved' then
    raise exception 'CP can only be updated for approved profiles.';
  end if;

  select gm.guild_id into target_guild_id
  from public.guild_memberships gm
  where gm.profile_id = p_profile_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  if target_guild_id is null then
    raise exception 'Target profile has no active primary guild.';
  end if;

  if p_cp_value is null or p_cp_value < 0 then
    raise exception 'CP value must be 0 or greater.';
  end if;

  if not private.can_update_cp(actor_id, target_guild_id) then
    raise exception 'Not authorized to update CP for this guild.';
  end if;

  select cp.cp_value into old_cp
  from public.member_cp cp
  where cp.profile_id = p_profile_id;

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
  select p.id,
         p.username,
         p.ign,
         gm.guild_id,
         cp.cp_value,
         cp.updated_at
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  left join public.member_cp cp
    on cp.profile_id = gm.profile_id
   and cp.guild_id = gm.guild_id
  where gm.guild_id = p_guild_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
    and p.approval_status = 'approved'
  order by cp.cp_value desc nulls last, p.ign asc;
end;
$$;

revoke all on function public.update_member_cp(uuid, integer, text) from public, anon;
revoke all on function public.get_current_cp_roster(uuid) from public, anon;

grant execute on function public.update_member_cp(uuid, integer, text) to authenticated;
grant execute on function public.get_current_cp_roster(uuid) to authenticated;
