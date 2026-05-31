-- Milestone 29E.3: migrate 3v3 Team Finder current-user identity to active profile.
-- Normal protected CP remains separate; 3v3 uses only public self-entered Combined CP.
create or replace function public.update_my_discord_username(p_discord_username text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  normalized_username text := private.normalize_three_v_three_discord_username(p_discord_username);
  updated_row public.three_v_three_player_profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  if normalized_username is not null
     and not private.is_valid_three_v_three_discord_username(normalized_username) then
    raise exception 'Invalid Discord username.';
  end if;

  insert into public.three_v_three_player_profiles (
    profile_id,
    discord_username
  )
  values (
    actor_id,
    normalized_username
  )
  on conflict (profile_id) do update
  set discord_username = excluded.discord_username,
      updated_at = now()
  returning * into updated_row;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_profile_updated',
    'three_v_three_player_profiles',
    actor_id,
    jsonb_build_object('field', 'discord_username', 'has_discord_username', normalized_username is not null)
  );

  return jsonb_build_object(
    'profile_id', updated_row.profile_id,
    'discord_username', updated_row.discord_username,
    'combined_cp', updated_row.combined_cp,
    'updated_at', updated_row.updated_at
  );
end;
$$;

create or replace function public.update_my_3v3_combined_cp(p_combined_cp bigint)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  updated_row public.three_v_three_player_profiles%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  insert into public.three_v_three_player_profiles (
    profile_id,
    combined_cp
  )
  values (
    actor_id,
    p_combined_cp
  )
  on conflict (profile_id) do update
  set combined_cp = excluded.combined_cp,
      updated_at = now()
  returning * into updated_row;

  update public.three_v_three_team_members tm
  set combined_cp_snapshot = p_combined_cp
  where tm.profile_id = actor_id
    and tm.left_at is null;

  update public.three_v_three_join_requests r
  set combined_cp_snapshot = p_combined_cp,
      updated_at = now()
  where r.requester_profile_id = actor_id
    and r.status = 'pending';

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_profile_updated',
    'three_v_three_player_profiles',
    actor_id,
    jsonb_build_object('field', 'combined_cp')
  );

  return jsonb_build_object(
    'profile_id', updated_row.profile_id,
    'discord_username', updated_row.discord_username,
    'combined_cp', updated_row.combined_cp,
    'updated_at', updated_row.updated_at
  );
end;
$$;

create or replace function public.create_3v3_team(
  p_team_name text,
  p_combined_cp bigint
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  normalized_team_name text := nullif(btrim(coalesce(p_team_name, '')), '');
  player_profile public.three_v_three_player_profiles%rowtype;
  new_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_action_access(actor_id) then
    raise exception 'Active 3v3-eligible membership required.';
  end if;

  if normalized_team_name is null or char_length(normalized_team_name) < 3 or char_length(normalized_team_name) > 50 then
    raise exception 'Team name must be between 3 and 50 characters.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  select * into player_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  if not found or player_profile.discord_username is null then
    raise exception 'Discord username is required for 3v3.';
  end if;

  if private.owned_active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You already own an active 3v3 team.';
  end if;

  if private.active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You are already in an active 3v3 team.';
  end if;

  update public.three_v_three_player_profiles
  set combined_cp = p_combined_cp,
      updated_at = now()
  where profile_id = actor_id
  returning * into player_profile;

  insert into public.three_v_three_teams (
    name,
    owner_profile_id,
    status
  )
  values (
    normalized_team_name,
    actor_id,
    'open'
  )
  returning * into new_team;

  insert into public.three_v_three_team_members (
    team_id,
    profile_id,
    slot_number,
    role,
    combined_cp_snapshot
  )
  values (
    new_team.id,
    actor_id,
    1,
    'owner',
    p_combined_cp
  );

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_team_created',
    'three_v_three_teams',
    new_team.id,
    jsonb_build_object(
      'team_id', new_team.id,
      'team_name', new_team.name,
      'combined_cp_public', true
    )
  );

  return private.build_three_v_three_team_payload(new_team.id, actor_id, true);
end;
$$;

create or replace function public.get_3v3_teams()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_profile public.three_v_three_player_profiles%rowtype;
  actor_guild_id uuid;
  actor_roster_status text;
  actor_team_id uuid;
  owned_team_id uuid;
  teams_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  select * into actor_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  select gm.guild_id, gm.roster_status
  into actor_guild_id, actor_roster_status
  from public.guild_memberships gm
  where gm.profile_id = actor_id
    and gm.membership_status = 'active'
    and gm.is_primary = true
  limit 1;

  actor_team_id := private.active_three_v_three_team_id(actor_id);
  owned_team_id := private.owned_active_three_v_three_team_id(actor_id);

  select coalesce(
    jsonb_agg(
      private.build_three_v_three_team_payload(t.id, actor_id, false)
      order by
        case t.status when 'open' then 1 when 'closed' then 2 when 'full' then 3 else 4 end,
        t.created_at desc,
        t.id desc
    ),
    '[]'::jsonb
  )
  into teams_payload
  from public.three_v_three_teams t
  where t.status <> 'disbanded';

  return jsonb_build_object(
    'viewer',
    jsonb_build_object(
      'profile_id', actor_id,
      'guild_id', actor_guild_id,
      'roster_status', actor_roster_status,
      'can_create_or_request', private.has_three_v_three_action_access(actor_id),
      'active_team_id', actor_team_id,
      'owned_team_id', owned_team_id,
      'discord_username', actor_profile.discord_username,
      'combined_cp', actor_profile.combined_cp
    ),
    'teams', teams_payload
  );
end;
$$;

create or replace function public.get_my_3v3_status()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_profile public.three_v_three_player_profiles%rowtype;
  actor_team_id uuid;
  owned_team_id uuid;
  current_team_payload jsonb := null;
  owned_team_payload jsonb := null;
  outgoing_payload jsonb;
  incoming_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_view_access(actor_id) then
    raise exception 'Approved active membership required.';
  end if;

  select * into actor_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  actor_team_id := private.active_three_v_three_team_id(actor_id);
  owned_team_id := private.owned_active_three_v_three_team_id(actor_id);

  if actor_team_id is not null then
    current_team_payload := private.build_three_v_three_team_payload(actor_team_id, actor_id, true);
  end if;

  if owned_team_id is not null then
    owned_team_payload := private.build_three_v_three_team_payload(owned_team_id, actor_id, true);
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'team_id', r.team_id,
        'team_name', t.name,
        'team_status', t.status,
        'status', r.status,
        'attempt_number', r.attempt_number,
        'combined_cp', r.combined_cp_snapshot,
        'created_at', r.created_at,
        'updated_at', r.updated_at,
        'decided_at', r.decided_at
      )
      order by r.created_at desc, r.id desc
    ),
    '[]'::jsonb
  )
  into outgoing_payload
  from public.three_v_three_join_requests r
  join public.three_v_three_teams t on t.id = r.team_id
  where r.requester_profile_id = actor_id;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', r.id,
        'team_id', r.team_id,
        'team_name', t.name,
        'status', r.status,
        'attempt_number', r.attempt_number,
        'combined_cp', r.combined_cp_snapshot,
        'created_at', r.created_at,
        'updated_at', r.updated_at,
        'requester_profile_id', r.requester_profile_id,
        'requester_username', p.username,
        'requester_profile_slug', p.profile_slug,
        'requester_ign', p.ign,
        'requester_discord_username', tvp.discord_username,
        'requester_avatar_key', coalesce(avatar.key, default_avatar.key),
        'requester_avatar_asset_path', coalesce(avatar.asset_path, default_avatar.asset_path),
        'requester_frame_key', coalesce(frame.key, default_frame.key),
        'requester_frame_asset_path', coalesce(frame.asset_path, default_frame.asset_path)
      )
      order by r.created_at asc, r.id asc
    ),
    '[]'::jsonb
  )
  into incoming_payload
  from public.three_v_three_join_requests r
  join public.three_v_three_teams t on t.id = r.team_id
  join public.profiles p on p.id = r.requester_profile_id
  left join public.three_v_three_player_profiles tvp on tvp.profile_id = r.requester_profile_id
  left join public.profile_equipped_cosmetics pec on pec.profile_id = r.requester_profile_id
  left join public.cosmetic_catalog avatar
    on avatar.key = pec.avatar_key
   and avatar.type = 'avatar'
   and avatar.is_active = true
  left join public.cosmetic_catalog frame
    on frame.key = pec.frame_key
   and frame.type = 'frame'
   and frame.is_active = true
  left join public.cosmetic_catalog default_avatar
    on default_avatar.key = '1079_head'
   and default_avatar.type = 'avatar'
   and default_avatar.is_active = true
  left join public.cosmetic_catalog default_frame
    on default_frame.key = 'TXK_frame_reOpen_EN_FREE'
   and default_frame.type = 'frame'
   and default_frame.is_active = true
  where t.owner_profile_id = actor_id
    and t.status in ('open', 'full', 'closed')
    and r.status = 'pending';

  return jsonb_build_object(
    'profile',
    jsonb_build_object(
      'profile_id', actor_id,
      'discord_username', actor_profile.discord_username,
      'combined_cp', actor_profile.combined_cp,
      'can_create_or_request', private.has_three_v_three_action_access(actor_id)
    ),
    'current_team', current_team_payload,
    'owned_team', owned_team_payload,
    'outgoing_requests', outgoing_payload,
    'incoming_requests', incoming_payload
  );
end;
$$;

create or replace function public.request_join_3v3_team(
  p_team_id uuid,
  p_combined_cp bigint
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  player_profile public.three_v_three_player_profiles%rowtype;
  target_team public.three_v_three_teams%rowtype;
  attempt_count integer;
  last_declined_at timestamptz;
  new_request public.three_v_three_join_requests%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_three_v_three_action_access(actor_id) then
    raise exception 'Active 3v3-eligible membership required.';
  end if;

  if p_team_id is null then
    raise exception 'Team is required.';
  end if;

  if p_combined_cp is null or p_combined_cp < 0 then
    raise exception '3v3 Combined CP must be a non-negative number.';
  end if;

  select * into player_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = actor_id;

  if not found or player_profile.discord_username is null then
    raise exception 'Discord username is required for 3v3.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.status <> 'open' then
    raise exception 'Team is not accepting requests.';
  end if;

  if target_team.owner_profile_id = actor_id then
    raise exception 'You cannot request to join your own team.';
  end if;

  if private.active_three_v_three_team_id(actor_id) is not null then
    raise exception 'You are already in an active 3v3 team.';
  end if;

  if private.first_available_three_v_three_slot(target_team.id) is null then
    perform private.refresh_three_v_three_team_status(target_team.id);
    raise exception 'Team is full.';
  end if;

  if exists (
    select 1
    from public.three_v_three_join_requests r
    where r.team_id = target_team.id
      and r.requester_profile_id = actor_id
      and r.status = 'pending'
  ) then
    raise exception 'You already have a pending request for this team.';
  end if;

  select count(*) into attempt_count
  from public.three_v_three_join_requests r
  where r.team_id = target_team.id
    and r.requester_profile_id = actor_id;

  if attempt_count >= 2 then
    raise exception 'Request limit reached for this team.';
  end if;

  select max(coalesce(r.decided_at, r.updated_at)) into last_declined_at
  from public.three_v_three_join_requests r
  where r.team_id = target_team.id
    and r.requester_profile_id = actor_id
    and r.status = 'declined';

  if last_declined_at is not null
     and last_declined_at > now() - interval '6 hours' then
    raise exception 'Please wait before requesting this team again.';
  end if;

  update public.three_v_three_player_profiles
  set combined_cp = p_combined_cp,
      updated_at = now()
  where profile_id = actor_id
  returning * into player_profile;

  insert into public.three_v_three_join_requests (
    team_id,
    requester_profile_id,
    combined_cp_snapshot,
    attempt_number
  )
  values (
    target_team.id,
    actor_id,
    p_combined_cp,
    attempt_count + 1
  )
  returning * into new_request;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_team.owner_profile_id,
    actor_guild_id,
    'three_v_three_join_requested',
    'three_v_three_join_requests',
    new_request.id,
    jsonb_build_object('team_id', target_team.id, 'attempt_number', new_request.attempt_number)
  );

  return jsonb_build_object(
    'id', new_request.id,
    'team_id', new_request.team_id,
    'status', new_request.status,
    'attempt_number', new_request.attempt_number,
    'combined_cp', new_request.combined_cp_snapshot,
    'created_at', new_request.created_at
  );
end;
$$;

create or replace function public.cancel_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  target_request public.three_v_three_join_requests%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  if target_request.requester_profile_id <> actor_id then
    raise exception 'Only the requester can cancel this request.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be cancelled.';
  end if;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  return jsonb_build_object(
    'id', target_request.id,
    'team_id', target_request.team_id,
    'status', target_request.status
  );
end;
$$;

create or replace function public.approve_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  target_request public.three_v_three_join_requests%rowtype;
  target_team public.three_v_three_teams%rowtype;
  target_profile public.three_v_three_player_profiles%rowtype;
  selected_slot integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = target_request.team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can approve requests.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be approved.';
  end if;

  if target_team.status <> 'open' then
    raise exception 'Team is not accepting requests.';
  end if;

  if not private.has_three_v_three_action_access(target_request.requester_profile_id) then
    raise exception 'Requester is no longer eligible for 3v3.';
  end if;

  select * into target_profile
  from public.three_v_three_player_profiles tvp
  where tvp.profile_id = target_request.requester_profile_id;

  if not found or target_profile.discord_username is null then
    raise exception 'Requester Discord username is missing.';
  end if;

  if private.active_three_v_three_team_id(target_request.requester_profile_id) is not null then
    raise exception 'Requester is already in an active 3v3 team.';
  end if;

  selected_slot := private.first_available_three_v_three_slot(target_team.id);

  if selected_slot is null then
    perform private.refresh_three_v_three_team_status(target_team.id);
    raise exception 'Team is full.';
  end if;

  insert into public.three_v_three_team_members (
    team_id,
    profile_id,
    slot_number,
    role,
    combined_cp_snapshot
  )
  values (
    target_team.id,
    target_request.requester_profile_id,
    selected_slot,
    'member',
    target_request.combined_cp_snapshot
  );

  update public.three_v_three_join_requests
  set status = 'approved',
      decided_by = actor_id,
      decided_at = now(),
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where requester_profile_id = target_request.requester_profile_id
    and id <> target_request.id
    and status = 'pending';

  perform private.refresh_three_v_three_team_status(target_team.id);

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_request.requester_profile_id,
    actor_guild_id,
    'three_v_three_request_approved',
    'three_v_three_join_requests',
    target_request.id,
    jsonb_build_object('team_id', target_team.id, 'slot_number', selected_slot)
  );

  return jsonb_build_object(
    'request_id', target_request.id,
    'team_id', target_team.id,
    'status', target_request.status,
    'slot_number', selected_slot,
    'team', private.build_three_v_three_team_payload(target_team.id, actor_id, true)
  );
end;
$$;

create or replace function public.decline_3v3_request(p_request_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  target_request public.three_v_three_join_requests%rowtype;
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_request
  from public.three_v_three_join_requests r
  where r.id = p_request_id
  for update;

  if not found then
    raise exception 'Request not found.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = target_request.team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can decline requests.';
  end if;

  if target_request.status <> 'pending' then
    raise exception 'Only pending requests can be declined.';
  end if;

  update public.three_v_three_join_requests
  set status = 'declined',
      decided_by = actor_id,
      decided_at = now(),
      updated_at = now()
  where id = target_request.id
  returning * into target_request;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    target_request.requester_profile_id,
    actor_guild_id,
    'three_v_three_request_declined',
    'three_v_three_join_requests',
    target_request.id,
    jsonb_build_object('team_id', target_team.id)
  );

  return jsonb_build_object(
    'request_id', target_request.id,
    'team_id', target_team.id,
    'status', target_request.status
  );
end;
$$;

create or replace function public.remove_3v3_member(
  p_team_id uuid,
  p_profile_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  target_team public.three_v_three_teams%rowtype;
  target_member public.three_v_three_team_members%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can remove members.';
  end if;

  if p_profile_id = target_team.owner_profile_id then
    raise exception 'Team owner cannot be removed.';
  end if;

  select * into target_member
  from public.three_v_three_team_members tm
  where tm.team_id = target_team.id
    and tm.profile_id = p_profile_id
    and tm.left_at is null
    and tm.role = 'member'
  for update;

  if not found then
    raise exception 'Team member not found.';
  end if;

  update public.three_v_three_team_members
  set left_at = now(),
      removed_by = actor_id
  where id = target_member.id
  returning * into target_member;

  if target_team.status = 'full' then
    update public.three_v_three_teams
    set status = 'open',
        updated_at = now()
    where id = target_team.id;
  elsif target_team.status = 'open' then
    perform private.refresh_three_v_three_team_status(target_team.id);
  end if;

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    actor_guild_id,
    'three_v_three_member_removed',
    'three_v_three_team_members',
    target_member.id,
    jsonb_build_object('team_id', target_team.id, 'slot_number', target_member.slot_number)
  );

  return jsonb_build_object(
    'team_id', target_team.id,
    'removed_profile_id', p_profile_id,
    'status', (select t.status from public.three_v_three_teams t where t.id = target_team.id)
  );
end;
$$;

create or replace function public.disband_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  actor_guild_id uuid;
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can disband this team.';
  end if;

  update public.three_v_three_teams
  set status = 'disbanded',
      disbanded_at = now(),
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  update public.three_v_three_team_members
  set left_at = coalesce(left_at, now()),
      removed_by = actor_id
  where team_id = target_team.id
    and left_at is null;

  update public.three_v_three_join_requests
  set status = 'cancelled',
      updated_at = now()
  where team_id = target_team.id
    and status = 'pending';

  actor_guild_id := private.three_v_three_primary_guild_id(actor_id);

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'three_v_three_team_disbanded',
    'three_v_three_teams',
    target_team.id,
    jsonb_build_object('team_id', target_team.id)
  );

  return jsonb_build_object(
    'team_id', target_team.id,
    'status', target_team.status,
    'disbanded_at', target_team.disbanded_at
  );
end;
$$;

create or replace function public.close_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  target_team public.three_v_three_teams%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can close this team.';
  end if;

  update public.three_v_three_teams
  set status = 'closed',
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  return private.build_three_v_three_team_payload(target_team.id, actor_id, true);
end;
$$;

create or replace function public.reopen_3v3_team(p_team_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.get_active_profile_id();
  target_team public.three_v_three_teams%rowtype;
  active_member_count integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  select * into target_team
  from public.three_v_three_teams t
  where t.id = p_team_id
  for update;

  if not found or target_team.status = 'disbanded' then
    raise exception 'Team not found.';
  end if;

  if target_team.owner_profile_id <> actor_id then
    raise exception 'Only the team owner can reopen this team.';
  end if;

  select count(*) into active_member_count
  from public.three_v_three_team_members tm
  where tm.team_id = target_team.id
    and tm.left_at is null;

  update public.three_v_three_teams
  set status = case when active_member_count >= 3 then 'full' else 'open' end,
      updated_at = now()
  where id = target_team.id
  returning * into target_team;

  return private.build_three_v_three_team_payload(target_team.id, actor_id, true);
end;
$$;
revoke all on function public.update_my_discord_username(text) from public, anon;
revoke all on function public.update_my_3v3_combined_cp(bigint) from public, anon;
revoke all on function public.create_3v3_team(text, bigint) from public, anon;
revoke all on function public.get_3v3_teams() from public, anon;
revoke all on function public.get_my_3v3_status() from public, anon;
revoke all on function public.request_join_3v3_team(uuid, bigint) from public, anon;
revoke all on function public.cancel_3v3_request(uuid) from public, anon;
revoke all on function public.approve_3v3_request(uuid) from public, anon;
revoke all on function public.decline_3v3_request(uuid) from public, anon;
revoke all on function public.remove_3v3_member(uuid, uuid) from public, anon;
revoke all on function public.disband_3v3_team(uuid) from public, anon;
revoke all on function public.close_3v3_team(uuid) from public, anon;
revoke all on function public.reopen_3v3_team(uuid) from public, anon;

grant execute on function public.update_my_discord_username(text) to authenticated;
grant execute on function public.update_my_3v3_combined_cp(bigint) to authenticated;
grant execute on function public.create_3v3_team(text, bigint) to authenticated;
grant execute on function public.get_3v3_teams() to authenticated;
grant execute on function public.get_my_3v3_status() to authenticated;
grant execute on function public.request_join_3v3_team(uuid, bigint) to authenticated;
grant execute on function public.cancel_3v3_request(uuid) to authenticated;
grant execute on function public.approve_3v3_request(uuid) to authenticated;
grant execute on function public.decline_3v3_request(uuid) to authenticated;
grant execute on function public.remove_3v3_member(uuid, uuid) to authenticated;
grant execute on function public.disband_3v3_team(uuid) to authenticated;
grant execute on function public.close_3v3_team(uuid) to authenticated;
grant execute on function public.reopen_3v3_team(uuid) to authenticated;
