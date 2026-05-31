-- Milestone 29E.7: align audit actor attribution for active-profile member GvG votes.
-- This intentionally does not migrate legacy Admin/Analytics audit attribution.

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
  target_event public.gvg_events%rowtype;
  old_vote_status text;
  old_reason_provided boolean := false;
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

  select *
  into target_event
  from public.gvg_events ge
  where ge.id = p_event_id;

  if not found then
    raise exception 'GvG event not found.';
  end if;

  select gv.vote_status,
         gv.absence_reason is not null
  into old_vote_status,
       old_reason_provided
  from public.gvg_votes gv
  where gv.gvg_event_id = p_event_id
    and gv.profile_id = actor_id;

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

  perform private.write_audit_log(
    actor_id,
    actor_id,
    target_event.guild_id,
    'gvg_vote_submitted',
    'gvg_votes',
    updated_vote.id,
    jsonb_build_object(
      'event_id', p_event_id,
      'event_scope', target_event.scope,
      'vote_status_old', old_vote_status,
      'vote_status_new', updated_vote.vote_status,
      'absence_reason_provided_old', coalesce(old_reason_provided, false),
      'absence_reason_provided_new', updated_vote.absence_reason is not null
    )
  );

  return updated_vote;
end;
$$;

revoke all on function public.submit_gvg_vote(uuid, text, text) from public, anon;
grant execute on function public.submit_gvg_vote(uuid, text, text) to authenticated;
