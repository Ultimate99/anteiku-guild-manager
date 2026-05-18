-- Anteiku Guild Manager - Audit Log Read Hardening
-- Safe migration: adds a permission-checked audit log reader RPC and prevents
-- direct non-Owner audit_logs SELECT from bypassing SQL-side CP metadata redaction.
-- This does not change audit writes, CP update logic, role/guild logic, GvG logic, or frontend code.

drop policy if exists audit_logs_select_authorized on public.audit_logs;

create policy audit_logs_select_owner_only
on public.audit_logs
for select
to authenticated
using (private.is_owner(auth.uid()));

create or replace function public.get_audit_logs(
  p_guild_id uuid default null,
  p_action text default null,
  p_actor_id uuid default null,
  p_target_id uuid default null,
  p_from timestamptz default null,
  p_to timestamptz default null,
  p_limit integer default 50,
  p_before timestamptz default null
)
returns table (
  id uuid,
  created_at timestamptz,
  action text,
  entity_table text,
  entity_id uuid,
  actor_profile_id uuid,
  actor_username text,
  actor_ign text,
  target_profile_id uuid,
  target_username text,
  target_ign text,
  guild_id uuid,
  guild_name text,
  guild_slug text,
  metadata jsonb,
  metadata_redacted boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  safe_limit integer;
  has_audit_scope boolean;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  safe_limit := least(greatest(coalesce(p_limit, 50), 1), 100);

  select
    private.is_owner(actor_id)
    or exists (
      select 1
      from public.guild_memberships gm
      where gm.profile_id = actor_id
        and gm.membership_status = 'active'
        and (
          gm.role in ('leader', 'vice')
          or private.has_permission(actor_id, gm.guild_id, 'view_audit_logs')
        )
    )
  into has_audit_scope;

  if not has_audit_scope then
    raise exception 'Not authorized to read audit logs.';
  end if;

  if p_guild_id is not null and not private.can_read_audit_logs(actor_id, p_guild_id) then
    raise exception 'Not authorized to read audit logs for this guild.';
  end if;

  return query
  with filtered_logs as (
    select
      al.*,
      (
        al.action in ('member_cp_updated', 'weekly_cp_snapshot_captured')
        or al.entity_table in ('member_cp', 'cp_snapshots')
        or al.metadata ?| array[
          'cp_old',
          'cp_new',
          'cp_value',
          'cp_from',
          'cp_to',
          'growth',
          'growth_value'
        ]
      ) as is_cp_sensitive,
      private.can_view_cp(actor_id, al.guild_id) as can_view_cp_metadata
    from public.audit_logs al
    where private.can_read_audit_logs(actor_id, al.guild_id)
      and (p_guild_id is null or al.guild_id = p_guild_id)
      and (p_action is null or al.action = p_action)
      and (p_actor_id is null or al.actor_profile_id = p_actor_id)
      and (p_target_id is null or al.target_profile_id = p_target_id)
      and (p_from is null or al.created_at >= p_from)
      and (p_to is null or al.created_at <= p_to)
      and (p_before is null or al.created_at < p_before)
    order by al.created_at desc, al.id desc
    limit safe_limit
  )
  select
    fl.id,
    fl.created_at,
    fl.action,
    fl.entity_table,
    fl.entity_id,
    fl.actor_profile_id,
    actor_profile.username,
    actor_profile.ign,
    fl.target_profile_id,
    target_profile.username,
    target_profile.ign,
    fl.guild_id,
    g.name,
    g.slug,
    case
      when fl.is_cp_sensitive and not fl.can_view_cp_metadata then
        (
          fl.metadata
          - 'cp_old'
          - 'cp_new'
          - 'cp_value'
          - 'cp_from'
          - 'cp_to'
          - 'growth'
          - 'growth_value'
          - 'note'
        ) || jsonb_build_object(
          'cp_metadata_redacted', true,
          'redaction_reason', 'Sensitive CP metadata hidden.'
        )
      else fl.metadata
    end as metadata,
    (fl.is_cp_sensitive and not fl.can_view_cp_metadata) as metadata_redacted
  from filtered_logs fl
  left join public.profiles actor_profile on actor_profile.id = fl.actor_profile_id
  left join public.profiles target_profile on target_profile.id = fl.target_profile_id
  left join public.guilds g on g.id = fl.guild_id
  order by fl.created_at desc, fl.id desc;
end;
$$;

revoke all on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  from public, anon;
grant execute on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  to authenticated;
