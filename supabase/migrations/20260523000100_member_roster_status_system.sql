-- Anteiku Guild Manager - Member Roster Status System
-- Safe migration: adds guild-scoped roster lifecycle state, private status
-- history, a permission-checked status update RPC, and GvG eligibility
-- protection for non-participating roster states.

alter table public.guild_memberships
  add column if not exists roster_status text;

update public.guild_memberships
set roster_status = 'active'
where membership_status = 'active'
  and roster_status is null;

update public.guild_memberships
set roster_status = 'suspended'
where membership_status = 'suspended'
  and roster_status is null;

update public.guild_memberships
set roster_status = 'left'
where membership_status = 'left'
  and roster_status is null;

update public.guild_memberships
set roster_status = 'active'
where roster_status is null;

alter table public.guild_memberships
  alter column roster_status set default 'active',
  alter column roster_status set not null;

alter table public.guild_memberships
  drop constraint if exists guild_memberships_roster_status_chk;

alter table public.guild_memberships
  add constraint guild_memberships_roster_status_chk
  check (
    roster_status in (
      'active',
      'trial',
      'inactive',
      'on_break',
      'suspended',
      'left',
      'kicked',
      'pending_transfer'
    )
  );

create index if not exists guild_memberships_guild_roster_membership_status_idx
  on public.guild_memberships (guild_id, roster_status, membership_status);

create table if not exists public.member_status_history (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid not null references public.guild_memberships(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  guild_id uuid not null references public.guilds(id) on delete restrict,
  old_status text not null,
  new_status text not null,
  reason text,
  changed_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.member_status_history
  drop constraint if exists member_status_history_old_status_chk;

alter table public.member_status_history
  add constraint member_status_history_old_status_chk
  check (
    old_status in (
      'active',
      'trial',
      'inactive',
      'on_break',
      'suspended',
      'left',
      'kicked',
      'pending_transfer'
    )
  );

alter table public.member_status_history
  drop constraint if exists member_status_history_new_status_chk;

alter table public.member_status_history
  add constraint member_status_history_new_status_chk
  check (
    new_status in (
      'active',
      'trial',
      'inactive',
      'on_break',
      'suspended',
      'left',
      'kicked',
      'pending_transfer'
    )
  );

alter table public.member_status_history
  drop constraint if exists member_status_history_reason_length_chk;

alter table public.member_status_history
  add constraint member_status_history_reason_length_chk
  check (reason is null or char_length(reason) <= 1000);

create index if not exists member_status_history_membership_created_idx
  on public.member_status_history (membership_id, created_at desc);

create index if not exists member_status_history_profile_created_idx
  on public.member_status_history (profile_id, created_at desc);

create index if not exists member_status_history_guild_created_idx
  on public.member_status_history (guild_id, created_at desc);

alter table public.member_status_history enable row level security;

drop policy if exists member_status_history_select_scoped_staff on public.member_status_history;

create policy member_status_history_select_scoped_staff
on public.member_status_history
for select
to authenticated
using (
  private.is_owner(auth.uid())
  or private.has_role(auth.uid(), guild_id, array['leader', 'vice'])
  or private.has_permission(auth.uid(), guild_id, 'manage_members')
);

revoke all on public.member_status_history from public, anon, authenticated;
grant select on public.member_status_history to authenticated;

create or replace function private.has_gvg_eligible_membership(p_profile_id uuid, p_guild_id uuid)
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
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
  );
$$;

create or replace function private.gvg_eligible_primary_guild_id(p_profile_id uuid)
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
    and gm.roster_status in ('active', 'trial', 'pending_transfer')
    and gm.is_primary = true
    and p.approval_status = 'approved'
  limit 1;
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
        (ge.scope = 'global' and private.gvg_eligible_primary_guild_id(p_actor_id) is not null)
        or (ge.scope = 'guild' and private.has_gvg_eligible_membership(p_actor_id, ge.guild_id))
      )
  );
$$;

drop policy if exists gvg_events_select_active_in_scope on public.gvg_events;

create policy gvg_events_select_active_in_scope
on public.gvg_events
for select
to authenticated
using (
  status = 'active'
  and private.is_approved(auth.uid())
  and (
    (scope = 'global' and private.gvg_eligible_primary_guild_id(auth.uid()) is not null)
    or (scope = 'guild' and private.has_gvg_eligible_membership(auth.uid(), guild_id))
  )
);

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
  actor_id uuid := auth.uid();
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
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

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

revoke all on function private.has_gvg_eligible_membership(uuid, uuid) from public, anon;
revoke all on function private.gvg_eligible_primary_guild_id(uuid) from public, anon;
revoke all on function private.can_submit_gvg_vote(uuid, uuid) from public, anon;
grant execute on function private.has_gvg_eligible_membership(uuid, uuid) to authenticated;
grant execute on function private.gvg_eligible_primary_guild_id(uuid) to authenticated;
grant execute on function private.can_submit_gvg_vote(uuid, uuid) to authenticated;

revoke all on function public.update_member_roster_status(uuid, text, text) from public, anon;
grant execute on function public.update_member_roster_status(uuid, text, text) to authenticated;
