-- Anteiku Guild Manager - RLS Policies
-- Safe migration: enables RLS and adds approved table-level access rules.
-- CP tables intentionally have no direct member SELECT policy.

alter table public.profiles enable row level security;
alter table public.guilds enable row level security;
alter table public.guild_memberships enable row level security;
alter table public.permission_catalog enable row level security;
alter table public.admin_permissions enable row level security;
alter table public.member_cp enable row level security;
alter table public.cp_snapshots enable row level security;
alter table public.gvg_events enable row level security;
alter table public.gvg_votes enable row level security;
alter table public.audit_logs enable row level security;

create policy profiles_select_own
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy profiles_select_scoped_staff
on public.profiles
for select
to authenticated
using (
  private.is_owner(auth.uid())
  or private.can_approve_members(auth.uid(), private.requested_or_active_guild_id(id))
  or private.can_manage_members(auth.uid(), private.requested_or_active_guild_id(id))
  or private.can_reset_profile_slug(auth.uid(), id)
  or private.can_edit_member_ign(auth.uid(), id)
);

create policy guilds_select_active
on public.guilds
for select
to anon, authenticated
using (status = 'active' and is_core = true);

create policy guild_memberships_select_own
on public.guild_memberships
for select
to authenticated
using (profile_id = auth.uid());

create policy guild_memberships_select_active_same_guild
on public.guild_memberships
for select
to authenticated
using (
  membership_status = 'active'
  and private.has_active_membership(auth.uid(), guild_id)
);

create policy guild_memberships_select_scoped_staff
on public.guild_memberships
for select
to authenticated
using (
  private.is_owner(auth.uid())
  or private.has_role(auth.uid(), guild_id, array['leader', 'vice'])
  or private.has_permission(auth.uid(), guild_id, 'approve_members')
  or private.has_permission(auth.uid(), guild_id, 'manage_members')
  or private.has_permission(auth.uid(), guild_id, 'manage_roles')
);

create policy permission_catalog_select_authenticated
on public.permission_catalog
for select
to authenticated
using (private.is_approved(auth.uid()) or private.is_owner(auth.uid()));

create policy admin_permissions_select_own
on public.admin_permissions
for select
to authenticated
using (
  exists (
    select 1
    from public.guild_memberships gm
    where gm.id = admin_permissions.membership_id
      and gm.profile_id = auth.uid()
  )
);

create policy admin_permissions_select_scoped_staff
on public.admin_permissions
for select
to authenticated
using (
  private.is_owner(auth.uid())
  or exists (
    select 1
    from public.guild_memberships gm
    where gm.id = admin_permissions.membership_id
      and (
        private.has_role(auth.uid(), gm.guild_id, array['leader', 'vice'])
        or private.has_permission(auth.uid(), gm.guild_id, 'manage_roles')
      )
  )
);

create policy gvg_events_select_active_in_scope
on public.gvg_events
for select
to authenticated
using (
  status = 'active'
  and private.is_approved(auth.uid())
  and (
    (scope = 'global' and private.active_primary_guild_id(auth.uid()) is not null)
    or (scope = 'guild' and private.has_active_membership(auth.uid(), guild_id))
  )
);

create policy gvg_events_select_scoped_staff
on public.gvg_events
for select
to authenticated
using (
  (scope = 'global' and private.is_owner(auth.uid()))
  or (scope = 'guild' and private.can_manage_gvg(auth.uid(), guild_id))
);

create policy gvg_votes_select_own
on public.gvg_votes
for select
to authenticated
using (profile_id = auth.uid());

create policy gvg_votes_select_results
on public.gvg_votes
for select
to authenticated
using (private.can_read_gvg_results(auth.uid(), gvg_event_id));

create policy audit_logs_select_authorized
on public.audit_logs
for select
to authenticated
using (private.can_read_audit_logs(auth.uid(), guild_id));

-- Intentionally no direct member SELECT policies for:
-- - public.member_cp
-- - public.cp_snapshots
--
-- Intentionally no direct member INSERT/UPDATE policies for public.gvg_votes.
-- Members must vote through public.submit_gvg_vote(), which upserts on
-- (gvg_event_id, profile_id) and prevents moving votes between events.
--
-- Intentionally no client DELETE policies for important records.
-- Sensitive writes are handled through permission-checked RPCs.
