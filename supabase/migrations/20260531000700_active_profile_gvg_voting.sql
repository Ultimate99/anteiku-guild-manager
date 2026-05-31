-- Milestone 29E.6: migrate member-facing GvG voting/current-user state
-- to Account Switcher active-profile identity.
--
-- Scope:
-- - Member active-event visibility.
-- - Member own-vote read.
-- - Member vote submit/update.
-- Admin GvG event management, results permissions, Analytics, and unrelated
-- audit actor behavior remain unchanged.

drop policy if exists gvg_events_select_active_in_scope on public.gvg_events;

create policy gvg_events_select_active_in_scope
on public.gvg_events
for select
to authenticated
using (
  status = 'active'
  and private.is_approved(private.get_active_profile_id())
  and (
    (scope = 'global' and private.gvg_eligible_primary_guild_id(private.get_active_profile_id()) is not null)
    or (scope = 'guild' and private.has_gvg_eligible_membership(private.get_active_profile_id(), guild_id))
  )
);

drop policy if exists gvg_votes_select_own on public.gvg_votes;

create policy gvg_votes_select_own
on public.gvg_votes
for select
to authenticated
using (profile_id = private.get_active_profile_id());

create or replace function public.get_my_active_gvg_events()
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
  guild_name text,
  guild_slug text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

  if actor_id is null then
    raise exception 'Active profile is required.';
  end if;

  return query
  select ge.id,
         ge.guild_id,
         ge.scope,
         ge.title,
         ge.status,
         ge.starts_at,
         ge.ends_at,
         ge.created_at,
         ge.updated_at,
         g.name,
         g.slug
  from public.gvg_events ge
  left join public.guilds g on g.id = ge.guild_id
  where private.can_submit_gvg_vote(actor_id, ge.id)
  order by ge.created_at desc;
end;
$$;

create or replace function public.get_my_gvg_vote(p_event_id uuid)
returns table (
  id uuid,
  gvg_event_id uuid,
  vote_status text,
  absence_reason text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_id uuid;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_event_id is null then
    raise exception 'GvG event is required.';
  end if;

  actor_id := private.get_active_profile_id();

  if actor_id is null then
    raise exception 'Active profile is required.';
  end if;

  if not private.can_submit_gvg_vote(actor_id, p_event_id) then
    raise exception 'Not authorized to read this GvG vote.';
  end if;

  return query
  select gv.id,
         gv.gvg_event_id,
         gv.vote_status,
         gv.absence_reason,
         gv.updated_at
  from public.gvg_votes gv
  where gv.gvg_event_id = p_event_id
    and gv.profile_id = actor_id
  limit 1;
end;
$$;

create or replace function public.submit_gvg_vote(
  p_event_id uuid,
  p_vote_status text,
  p_absence_reason text default null
)
returns public.gvg_votes
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  actor_id uuid;
  normalized_reason text;
  updated_vote public.gvg_votes%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

  if actor_id is null then
    raise exception 'Active profile is required.';
  end if;

  if p_vote_status not in ('present', 'absent') then
    raise exception 'Invalid GvG vote status.';
  end if;

  if not private.can_submit_gvg_vote(actor_id, p_event_id) then
    raise exception 'Not authorized to vote on this GvG event.';
  end if;

  normalized_reason := case
    when p_vote_status = 'absent' then nullif(btrim(coalesce(p_absence_reason, '')), '')
    else null
  end;

  if normalized_reason is not null and char_length(normalized_reason) > 500 then
    raise exception 'Absence reason cannot exceed 500 characters.';
  end if;

  insert into public.gvg_votes (gvg_event_id, profile_id, vote_status, absence_reason)
  values (p_event_id, actor_id, p_vote_status, normalized_reason)
  on conflict (gvg_event_id, profile_id) do update
  set
    vote_status = excluded.vote_status,
    absence_reason = excluded.absence_reason,
    updated_at = now()
  returning * into updated_vote;

  return updated_vote;
end;
$$;

revoke all on function public.get_my_active_gvg_events() from public, anon;
revoke all on function public.get_my_gvg_vote(uuid) from public, anon;
revoke all on function public.submit_gvg_vote(uuid, text, text) from public, anon;

grant execute on function public.get_my_active_gvg_events() to authenticated;
grant execute on function public.get_my_gvg_vote(uuid) to authenticated;
grant execute on function public.submit_gvg_vote(uuid, text, text) to authenticated;
