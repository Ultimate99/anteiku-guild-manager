-- Anteiku Guild Manager - CP Update Window staff read RPC
-- Safe migration: adds permission-checked staff RPC for AdminPanel CP window status.
-- No direct cp_update_windows table access is granted.

create or replace function public.get_cp_update_window_for_guild(p_guild_id uuid)
returns table (
  id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_at timestamptz,
  updated_at timestamptz,
  created_by_username text,
  created_by_ign text,
  closed_by_username text,
  closed_by_ign text,
  server_now timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_profile public.profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into actor_profile
  from public.profiles p
  where p.id = actor_id;

  if not found or actor_profile.approval_status <> 'approved' then
    raise exception 'Approved profile required.';
  end if;

  if p_guild_id is null or not exists (
    select 1
    from public.guilds g
    where g.id = p_guild_id
      and g.status = 'active'
  ) then
    raise exception 'Active guild not found.';
  end if;

  if not (
    private.can_view_cp(actor_id, p_guild_id)
    or private.can_update_cp(actor_id, p_guild_id)
  ) then
    raise exception 'Not authorized to read CP update window for this guild.';
  end if;

  return query
  select
    w.id,
    w.guild_id,
    w.status,
    w.opens_at,
    w.closes_at,
    w.note,
    w.created_at,
    w.updated_at,
    creator.username,
    creator.ign,
    closer.username,
    closer.ign,
    now()
  from public.cp_update_windows w
  left join public.profiles creator on creator.id = w.created_by
  left join public.profiles closer on closer.id = w.closed_by
  where w.guild_id = p_guild_id
  order by
    (w.status = 'open') desc,
    w.updated_at desc,
    w.created_at desc,
    w.id desc
  limit 1;
end;
$$;

revoke all on function public.get_cp_update_window_for_guild(uuid) from public, anon;
grant execute on function public.get_cp_update_window_for_guild(uuid) to authenticated;
