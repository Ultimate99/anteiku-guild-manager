-- Anteiku Guild Manager - Own Ghoul Rep Profile RPC
-- Exposes only the authenticated user's own live Ghoul Rep total.
-- Does not read or expose protected normal CP tables/RPCs.

create or replace function public.get_my_ghoul_rep()
returns bigint
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

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  return private.get_profile_ghoul_rep(actor_id);
end;
$$;

revoke all on function public.get_my_ghoul_rep() from public, anon;
grant execute on function public.get_my_ghoul_rep() to authenticated;
