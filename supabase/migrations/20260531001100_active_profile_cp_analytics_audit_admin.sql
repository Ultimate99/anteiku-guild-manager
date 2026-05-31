-- Milestone 29E.8E: active-profile CP Admin, Analytics, and Audit migration.
-- Migrates CP-heavy Admin RPCs to the selected active admin profile.
-- Member-facing own CP, GvG voting, 3v3, Wall, cosmetics, and push behavior stay unchanged.

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
  actor_id uuid := private.active_admin_profile_id();
begin
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
  actor_id uuid := private.active_admin_profile_id();
  target_profile public.profiles%rowtype;
  target_guild_id uuid;
  old_cp integer;
  updated_cp public.member_cp%rowtype;
begin
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
  actor_id uuid := private.active_admin_profile_id();
begin
  if p_guild_id is null or not exists (
    select 1 from public.guilds g where g.id = p_guild_id and g.status = 'active'
  ) then
    raise exception 'Active guild not found.';
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

create or replace function public.get_admin_cp_rankings(
  p_guild_id uuid default null,
  p_scope text default 'guild'
)
returns table (
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  guild_slug text,
  cp_value integer,
  updated_at timestamptz,
  avatar_key text,
  avatar_asset_path text,
  frame_key text,
  frame_asset_path text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  normalized_scope text := lower(btrim(coalesce(p_scope, 'guild')));
begin
  if normalized_scope not in ('guild', 'global') then
    raise exception 'Invalid ranking scope.';
  end if;

  if normalized_scope = 'guild' then
    if p_guild_id is null then
      raise exception 'Guild is required for guild CP rankings.';
    end if;

    if not exists (select 1 from public.guilds g where g.id = p_guild_id and g.status = 'active') then
      raise exception 'Active guild not found.';
    end if;

    if not private.can_view_cp(actor_id, p_guild_id) then
      raise exception 'Not authorized to view CP rankings for this guild.';
    end if;
  elsif not private.is_owner(actor_id) then
    raise exception 'Only Owner can view global CP rankings.';
  end if;

  return query
  with ranked as (
    select
      row_number() over (
        order by
          cp.cp_value desc,
          lower(coalesce(nullif(btrim(p.ign), ''), p.username, p.id::text)) asc,
          p.id asc
      )::integer as rank_position,
      p.id as ranked_profile_id,
      p.username as ranked_username,
      p.ign as ranked_ign,
      g.id as ranked_guild_id,
      g.name as ranked_guild_name,
      g.slug as ranked_guild_slug,
      cp.cp_value as ranked_cp_value,
      cp.updated_at as ranked_updated_at,
      coalesce(avatar.key, default_avatar.key) as display_avatar_key,
      coalesce(avatar.asset_path, default_avatar.asset_path) as display_avatar_asset_path,
      coalesce(frame.key, default_frame.key) as display_frame_key,
      coalesce(frame.asset_path, default_frame.asset_path) as display_frame_asset_path
    from public.member_cp cp
    join public.profiles p on p.id = cp.profile_id
    join public.guilds g on g.id = cp.guild_id
    join public.guild_memberships gm
      on gm.profile_id = cp.profile_id
     and gm.guild_id = cp.guild_id
     and gm.membership_status = 'active'
     and gm.is_primary = true
     and gm.roster_status in ('active', 'trial', 'pending_transfer')
    left join public.profile_equipped_cosmetics pec
      on pec.profile_id = p.id
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
    where p.approval_status = 'approved'
      and g.status = 'active'
      and (normalized_scope = 'global' or cp.guild_id = p_guild_id)
  )
  select
    ranked.rank_position,
    ranked.ranked_profile_id,
    ranked.ranked_username,
    ranked.ranked_ign,
    ranked.ranked_guild_id,
    ranked.ranked_guild_name,
    ranked.ranked_guild_slug,
    ranked.ranked_cp_value,
    ranked.ranked_updated_at,
    ranked.display_avatar_key,
    ranked.display_avatar_asset_path,
    ranked.display_frame_key,
    ranked.display_frame_asset_path
  from ranked
  order by ranked.rank_position;
end;
$$;

create or replace function public.open_cp_update_window(
  p_guild_id uuid,
  p_opens_at timestamptz default null,
  p_closes_at timestamptz default null,
  p_note text default null
)
returns table (
  window_id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  created_window public.cp_update_windows%rowtype;
  normalized_note text := nullif(btrim(coalesce(p_note, '')), '');
begin
  if p_guild_id is null or not exists (
    select 1 from public.guilds g where g.id = p_guild_id and g.status = 'active'
  ) then
    raise exception 'Active guild not found.';
  end if;

  if not private.can_update_cp(actor_id, p_guild_id) then
    raise exception 'Not authorized to manage CP update windows for this guild.';
  end if;

  if normalized_note is not null and char_length(normalized_note) > 1000 then
    raise exception 'CP update window note is too long.';
  end if;

  if p_opens_at is not null and p_closes_at is not null and p_closes_at <= p_opens_at then
    raise exception 'CP update window close time must be after open time.';
  end if;

  if p_closes_at is not null and p_closes_at <= now() then
    raise exception 'CP update window close time must be in the future.';
  end if;

  if exists (
    select 1
    from public.cp_update_windows w
    where w.guild_id = p_guild_id
      and w.status = 'open'
  ) then
    raise exception 'A CP update window is already open for this guild.';
  end if;

  insert into public.cp_update_windows (
    guild_id,
    status,
    opens_at,
    closes_at,
    note,
    created_by
  )
  values (
    p_guild_id,
    'open',
    p_opens_at,
    p_closes_at,
    normalized_note,
    actor_id
  )
  returning * into created_window;

  perform private.write_audit_log(
    actor_id,
    null,
    p_guild_id,
    'cp_update_window_opened',
    'cp_update_windows',
    created_window.id,
    jsonb_build_object(
      'window_id', created_window.id,
      'guild_id', p_guild_id,
      'opens_at', p_opens_at,
      'closes_at', p_closes_at,
      'note_provided', normalized_note is not null
    )
  );

  return query
  select
    created_window.id,
    created_window.guild_id,
    created_window.status,
    created_window.opens_at,
    created_window.closes_at,
    created_window.note,
    created_window.created_at,
    created_window.updated_at;
end;
$$;

create or replace function public.close_cp_update_window(p_window_id uuid)
returns table (
  window_id uuid,
  guild_id uuid,
  status text,
  opens_at timestamptz,
  closes_at timestamptz,
  note text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  target_window public.cp_update_windows%rowtype;
  closed_window public.cp_update_windows%rowtype;
begin
  select * into target_window
  from public.cp_update_windows w
  where w.id = p_window_id
  for update;

  if not found then
    raise exception 'CP update window not found.';
  end if;

  if target_window.status <> 'open' then
    raise exception 'CP update window is already closed.';
  end if;

  if not private.can_update_cp(actor_id, target_window.guild_id) then
    raise exception 'Not authorized to manage CP update windows for this guild.';
  end if;

  update public.cp_update_windows
  set
    status = 'closed',
    closed_by = actor_id,
    updated_at = now()
  where id = target_window.id
  returning * into closed_window;

  perform private.write_audit_log(
    actor_id,
    null,
    target_window.guild_id,
    'cp_update_window_closed',
    'cp_update_windows',
    target_window.id,
    jsonb_build_object(
      'window_id', target_window.id,
      'guild_id', target_window.guild_id
    )
  );

  return query
  select
    closed_window.id,
    closed_window.guild_id,
    closed_window.status,
    closed_window.opens_at,
    closed_window.closes_at,
    closed_window.note,
    closed_window.created_at,
    closed_window.updated_at;
end;
$$;

create or replace function public.get_admin_member_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  total_members bigint,
  active_members bigint,
  trial_members bigint,
  pending_transfer_members bigint,
  inactive_members bigint,
  on_break_members bigint,
  suspended_members bigint,
  left_members bigint,
  kicked_members bigint,
  pending_approvals bigint,
  members_by_guild jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
begin
  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if not private.is_owner(actor_id) and scoped_guild_id is null then
    raise exception 'Guild scope is required.';
  end if;

  if not private.can_view_member_analytics(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view member analytics.';
  end if;

  return query
  with scoped_memberships as (
    select gm.*, p.approval_status, g.name as guild_name, g.slug as guild_slug
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    join public.guilds g on g.id = gm.guild_id
    where (scoped_guild_id is null or gm.guild_id = scoped_guild_id)
      and g.status = 'active'
  ),
  approved_memberships as (
    select *
    from scoped_memberships sm
    where sm.approval_status = 'approved'
  ),
  guild_breakdown as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'guild_id', guild_rows.guild_id,
          'guild_name', guild_rows.guild_name,
          'guild_slug', guild_rows.guild_slug,
          'total_members', guild_rows.total_members,
          'active_members', guild_rows.active_members,
          'pending_approvals', guild_rows.pending_approvals
        )
        order by guild_rows.guild_name
      ),
      '[]'::jsonb
    ) as payload
    from (
      select
        sm.guild_id,
        sm.guild_name,
        sm.guild_slug,
        count(*) filter (where sm.approval_status = 'approved') as total_members,
        count(*) filter (
          where sm.approval_status = 'approved'
            and sm.membership_status = 'active'
            and sm.roster_status = 'active'
        ) as active_members,
        count(*) filter (
          where sm.approval_status = 'pending'
            or sm.membership_status = 'pending'
        ) as pending_approvals
      from scoped_memberships sm
      group by sm.guild_id, sm.guild_name, sm.guild_slug
    ) guild_rows
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    count(*) filter (where am.approval_status = 'approved'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'active'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'trial'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'pending_transfer'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'inactive'),
    count(*) filter (where am.membership_status = 'active' and am.roster_status = 'on_break'),
    count(*) filter (where am.membership_status = 'suspended' or am.roster_status = 'suspended'),
    count(*) filter (where am.membership_status = 'left' or am.roster_status = 'left'),
    count(*) filter (where am.roster_status = 'kicked'),
    (
      select count(*)
      from scoped_memberships sm
      where sm.approval_status = 'pending'
        or sm.membership_status = 'pending'
    ),
    (select gb.payload from guild_breakdown gb)
  from approved_memberships am;
end;
$$;

create or replace function public.get_admin_cp_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  total_cp bigint,
  average_cp numeric,
  highest_cp integer,
  lowest_cp integer,
  members_missing_cp bigint,
  recently_updated_cp_count bigint,
  cp_update_window_status text,
  cp_update_window_id uuid,
  cp_update_window_updated_at timestamptz,
  open_cp_window_count bigint,
  self_submitted_count bigint,
  recently_updated_members jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
begin
  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global CP analytics.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP analytics.';
  end if;

  return query
  with eligible_members as (
    select gm.profile_id, gm.guild_id, p.username, p.ign, g.name as guild_name
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    join public.guilds g on g.id = gm.guild_id
    where (scoped_guild_id is null or gm.guild_id = scoped_guild_id)
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
      and g.status = 'active'
  ),
  cp_scope as (
    select em.*, cp.cp_value, cp.updated_at, cp.updated_by
    from eligible_members em
    left join public.member_cp cp
      on cp.profile_id = em.profile_id
     and cp.guild_id = em.guild_id
  ),
  latest_window as (
    select w.*
    from public.cp_update_windows w
    where scoped_guild_id is not null
      and w.guild_id = scoped_guild_id
    order by (w.status = 'open') desc, w.updated_at desc, w.created_at desc, w.id desc
    limit 1
  ),
  updated_members as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'profile_id', ranked.profile_id,
          'username', ranked.username,
          'ign', ranked.ign,
          'guild_id', ranked.guild_id,
          'guild_name', ranked.guild_name,
          'cp_value', ranked.cp_value,
          'updated_at', ranked.updated_at
        )
        order by ranked.updated_at desc
      ),
      '[]'::jsonb
    ) as payload
    from (
      select *
      from cp_scope cs
      where cs.cp_value is not null
      order by cs.updated_at desc nulls last, cs.ign asc
      limit 10
    ) ranked
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    coalesce(sum(cs.cp_value), 0)::bigint,
    round(avg(cs.cp_value), 2),
    max(cs.cp_value),
    min(cs.cp_value),
    count(*) filter (where cs.cp_value is null),
    count(*) filter (where cs.updated_at >= now() - interval '7 days'),
    case
      when scoped_guild_id is null and exists (
        select 1 from public.cp_update_windows w where w.status = 'open'
      ) then 'open'
      when scoped_guild_id is null then 'closed'
      else coalesce((select lw.status from latest_window lw), 'closed')
    end,
    (select lw.id from latest_window lw),
    (select lw.updated_at from latest_window lw),
    (
      select count(*)
      from public.cp_update_windows w
      where w.status = 'open'
        and (scoped_guild_id is null or w.guild_id = scoped_guild_id)
    ),
    (
      select count(*)
      from public.audit_logs al
      where al.action = 'member_cp_self_submitted'
        and al.created_at >= now() - interval '7 days'
        and (scoped_guild_id is null or al.guild_id = scoped_guild_id)
    ),
    (select um.payload from updated_members um)
  from cp_scope cs;
end;
$$;

create or replace function public.get_admin_gvg_analytics(p_guild_id uuid default null)
returns table (
  scope_guild_id uuid,
  scope_guild_name text,
  latest_event_id uuid,
  latest_event_title text,
  latest_event_scope text,
  latest_event_status text,
  latest_event_guild_id uuid,
  latest_event_guild_name text,
  starts_at timestamptz,
  ends_at timestamptz,
  present_count bigint,
  absent_count bigint,
  no_vote_count bigint,
  eligible_count bigint,
  participation_percent numeric,
  absence_reasons jsonb,
  recent_events jsonb
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
  latest_event public.gvg_events%rowtype;
begin
  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global GvG analytics.';
    end if;
  elsif not private.can_manage_gvg(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view GvG analytics.';
  end if;

  select ge.* into latest_event
  from public.gvg_events ge
  where (
      scoped_guild_id is null
      or (ge.scope = 'guild' and ge.guild_id = scoped_guild_id)
    )
  order by coalesce(ge.starts_at, ge.created_at) desc, ge.created_at desc, ge.id desc
  limit 1;

  if latest_event.id is null then
    return query
    select
      scoped_guild_id,
      scoped_guild_name,
      null::uuid,
      null::text,
      null::text,
      null::text,
      null::uuid,
      null::text,
      null::timestamptz,
      null::timestamptz,
      0::bigint,
      0::bigint,
      0::bigint,
      0::bigint,
      0::numeric,
      '[]'::jsonb,
      '[]'::jsonb;
    return;
  end if;

  return query
  with eligible_members as (
    select gm.profile_id
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
      and (
        (latest_event.scope = 'global')
        or (latest_event.scope = 'guild' and gm.guild_id = latest_event.guild_id)
      )
  ),
  vote_counts as (
    select
      count(*) filter (where gv.vote_status = 'present') as present_votes,
      count(*) filter (where gv.vote_status = 'absent') as absent_votes,
      count(distinct gv.profile_id) as total_votes
    from public.gvg_votes gv
    where gv.gvg_event_id = latest_event.id
  ),
  reason_payload as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'profile_id', p.id,
          'username', p.username,
          'ign', p.ign,
          'absence_reason', gv.absence_reason,
          'updated_at', gv.updated_at
        )
        order by p.ign asc
      ) filter (where gv.vote_status = 'absent' and gv.absence_reason is not null),
      '[]'::jsonb
    ) as payload
    from public.gvg_votes gv
    join public.profiles p on p.id = gv.profile_id
    where gv.gvg_event_id = latest_event.id
  ),
  recent_payload as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', recent.id,
          'title', recent.title,
          'scope', recent.scope,
          'status', recent.status,
          'guild_id', recent.guild_id,
          'starts_at', recent.starts_at,
          'created_at', recent.created_at
        )
        order by coalesce(recent.starts_at, recent.created_at) desc
      ),
      '[]'::jsonb
    ) as payload
    from (
      select ge.*
      from public.gvg_events ge
      where (
          scoped_guild_id is null
          or (ge.scope = 'guild' and ge.guild_id = scoped_guild_id)
        )
      order by coalesce(ge.starts_at, ge.created_at) desc, ge.created_at desc, ge.id desc
      limit 5
    ) recent
  ),
  eligible_count as (
    select count(*) as count_value from eligible_members
  )
  select
    scoped_guild_id,
    scoped_guild_name,
    latest_event.id,
    latest_event.title,
    latest_event.scope,
    latest_event.status,
    latest_event.guild_id,
    event_guild.name,
    latest_event.starts_at,
    latest_event.ends_at,
    coalesce(vc.present_votes, 0)::bigint,
    coalesce(vc.absent_votes, 0)::bigint,
    greatest(coalesce(ec.count_value, 0) - coalesce(vc.total_votes, 0), 0)::bigint,
    coalesce(ec.count_value, 0)::bigint,
    case
      when coalesce(ec.count_value, 0) = 0 then 0::numeric
      else round(((coalesce(vc.total_votes, 0)::numeric / ec.count_value::numeric) * 100), 2)
    end,
    rp.payload,
    recent_payload.payload
  from vote_counts vc
  cross join eligible_count ec
  cross join reason_payload rp
  cross join recent_payload
  left join public.guilds event_guild on event_guild.id = latest_event.guild_id;
end;
$$;

create or replace function public.start_new_cp_growth_period(
  p_guild_id uuid default null,
  p_label text default null
)
returns table (
  batch_id uuid,
  guild_id uuid,
  captured_at timestamptz,
  captured_count integer,
  week_start date,
  week_end date,
  reset_day_of_week integer,
  reset_day_label text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  scoped_guild_name text;
  new_batch public.cp_snapshot_batches%rowtype;
  inserted_count integer;
  v_reset_day integer := 0;
  v_reset_day_label text := 'Sunday';
  v_captured_at timestamptz := clock_timestamp();
  v_local_today date := (clock_timestamp() at time zone 'Europe/Belgrade')::date;
  v_week_start date;
  v_week_end date;
  v_label text := nullif(trim(p_label), '');
begin
  v_week_start := v_local_today - (((extract(dow from v_local_today)::integer - v_reset_day + 7) % 7));
  v_week_end := v_week_start + 6;

  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can start a global CP growth period.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to start CP growth period.';
  end if;

  insert into public.cp_snapshot_batches (
    guild_id,
    captured_by,
    captured_at,
    week_start,
    week_end,
    label
  )
  values (
    scoped_guild_id,
    actor_id,
    v_captured_at,
    v_week_start,
    v_week_end,
    coalesce(
      v_label,
      case
        when scoped_guild_id is null then 'Global CP week baseline ' || v_week_start::text
        else scoped_guild_name || ' CP week baseline ' || v_week_start::text
      end
    )
  )
  returning * into new_batch;

  insert into public.cp_snapshot_entries (
    batch_id,
    profile_id,
    guild_id,
    cp_value,
    member_cp_updated_at,
    captured_by,
    captured_at
  )
  select
    new_batch.id,
    cp.profile_id,
    cp.guild_id,
    cp.cp_value,
    cp.updated_at,
    actor_id,
    new_batch.captured_at
  from public.member_cp cp
  join public.guild_memberships gm
    on gm.profile_id = cp.profile_id
   and gm.guild_id = cp.guild_id
   and gm.membership_status = 'active'
   and gm.is_primary = true
   and gm.roster_status in ('active', 'trial', 'pending_transfer')
  join public.profiles p
    on p.id = cp.profile_id
   and p.approval_status = 'approved'
  join public.guilds g
    on g.id = cp.guild_id
   and g.status = 'active'
  where scoped_guild_id is null or cp.guild_id = scoped_guild_id;

  get diagnostics inserted_count = row_count;

  perform private.write_audit_log(
    actor_id,
    null,
    scoped_guild_id,
    'weekly_cp_snapshot_captured',
    'cp_snapshot_batches',
    new_batch.id,
    jsonb_build_object(
      'batch_id', new_batch.id,
      'guild_id', scoped_guild_id,
      'rows_affected', inserted_count,
      'week_start', v_week_start,
      'week_end', v_week_end,
      'reset_day_of_week', v_reset_day,
      'reset_day_label', v_reset_day_label,
      'scope', case when scoped_guild_id is null then 'global' else 'guild' end
    )
  );

  return query
  select
    new_batch.id,
    new_batch.guild_id,
    new_batch.captured_at,
    inserted_count,
    new_batch.week_start,
    new_batch.week_end,
    v_reset_day,
    v_reset_day_label;
end;
$$;

create or replace function public.capture_weekly_cp_snapshot(p_guild_id uuid default null)
returns table (
  batch_id uuid,
  guild_id uuid,
  captured_at timestamptz,
  captured_count integer
)
language sql
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select
    period.batch_id,
    period.guild_id,
    period.captured_at,
    period.captured_count
  from public.start_new_cp_growth_period(p_guild_id, null) period;
$$;

create or replace function public.get_admin_cp_snapshot_history(p_guild_id uuid default null)
returns table (
  id uuid,
  guild_id uuid,
  guild_name text,
  label text,
  captured_at timestamptz,
  captured_by_profile_id uuid,
  captured_by_username text,
  captured_by_ign text,
  week_start date,
  week_end date,
  member_count bigint,
  scope text
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
begin
  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Guild scope is required.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP snapshot history.';
  end if;

  return query
  select
    b.id,
    b.guild_id,
    g.name,
    b.label,
    b.captured_at,
    b.captured_by,
    actor_profile.username,
    actor_profile.ign,
    b.week_start,
    b.week_end,
    count(e.id)::bigint,
    case when b.guild_id is null then 'global' else 'guild' end
  from public.cp_snapshot_batches b
  left join public.cp_snapshot_entries e on e.batch_id = b.id
  left join public.guilds g on g.id = b.guild_id
  left join public.profiles actor_profile on actor_profile.id = b.captured_by
  where (
      scoped_guild_id is null
      or b.guild_id = scoped_guild_id
    )
  group by
    b.id,
    b.guild_id,
    g.name,
    b.label,
    b.captured_at,
    b.captured_by,
    actor_profile.username,
    actor_profile.ign,
    b.week_start,
    b.week_end
  order by b.captured_at desc, b.id desc;
end;
$$;

create or replace function public.get_admin_cp_growth_report(
  p_guild_id uuid default null,
  p_snapshot_id uuid default null
)
returns table (
  has_previous_snapshot boolean,
  current_snapshot_id uuid,
  previous_snapshot_id uuid,
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  previous_cp integer,
  current_cp integer,
  growth_amount integer,
  growth_percent numeric,
  last_updated timestamptz,
  missing_update boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  current_batch public.cp_snapshot_batches%rowtype;
  previous_batch public.cp_snapshot_batches%rowtype;
begin
  if p_snapshot_id is not null then
    select * into current_batch
    from public.cp_snapshot_batches b
    where b.id = p_snapshot_id;

    if not found then
      raise exception 'Snapshot batch not found.';
    end if;

    if scoped_guild_id is not null and current_batch.guild_id is distinct from scoped_guild_id then
      raise exception 'Snapshot batch does not match requested guild scope.';
    end if;

    scoped_guild_id := current_batch.guild_id;
  else
    if scoped_guild_id is null then
      if not private.is_owner(actor_id) then
        raise exception 'Guild scope is required.';
      end if;

      select * into current_batch
      from public.cp_snapshot_batches b
      where b.guild_id is null
      order by b.captured_at desc, b.id desc
      limit 1;
    else
      select * into current_batch
      from public.cp_snapshot_batches b
      where b.guild_id = scoped_guild_id
      order by b.captured_at desc, b.id desc
      limit 1;
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global CP growth.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view CP growth.';
  end if;

  if current_batch.id is null then
    return query
    select
      false,
      null::uuid,
      null::uuid,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      scoped_guild_id,
      null::text,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false;
    return;
  end if;

  select * into previous_batch
  from public.cp_snapshot_batches b
  where b.guild_id is not distinct from current_batch.guild_id
    and (
      b.captured_at < current_batch.captured_at
      or (b.captured_at = current_batch.captured_at and b.id <> current_batch.id)
    )
  order by b.captured_at desc, b.id desc
  limit 1;

  if previous_batch.id is null then
    return query
    select
      false,
      current_batch.id,
      null::uuid,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      current_batch.guild_id,
      null::text,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false;
    return;
  end if;

  return query
  with growth_rows as (
    select
      coalesce(current_entry.profile_id, previous_entry.profile_id) as profile_id,
      coalesce(current_entry.guild_id, previous_entry.guild_id) as guild_id,
      previous_entry.cp_value as previous_cp,
      current_entry.cp_value as current_cp,
      case
        when current_entry.cp_value is null or previous_entry.cp_value is null then null
        else current_entry.cp_value - previous_entry.cp_value
      end as growth_amount,
      case
        when current_entry.cp_value is null
          or previous_entry.cp_value is null
          or previous_entry.cp_value = 0 then null
        else round(((current_entry.cp_value - previous_entry.cp_value)::numeric / previous_entry.cp_value::numeric) * 100, 2)
      end as growth_percent,
      current_entry.member_cp_updated_at as last_updated,
      (
        current_entry.id is null
        or current_entry.member_cp_updated_at is null
        or current_entry.member_cp_updated_at <= previous_batch.captured_at
      ) as missing_update
    from (
      select *
      from public.cp_snapshot_entries e
      where e.batch_id = current_batch.id
    ) current_entry
    full join (
      select *
      from public.cp_snapshot_entries e
      where e.batch_id = previous_batch.id
    ) previous_entry
      on previous_entry.profile_id = current_entry.profile_id
     and previous_entry.guild_id = current_entry.guild_id
  ),
  decorated_rows as (
    select
      gr.*,
      p.username,
      p.ign,
      g.name as guild_name,
      row_number() over (
        order by gr.growth_amount desc nulls last, lower(coalesce(p.ign, p.username, p.id::text)) asc, p.id asc
      )::integer as rank_position
    from growth_rows gr
    join public.profiles p on p.id = gr.profile_id
    join public.guilds g on g.id = gr.guild_id
    where scoped_guild_id is null or gr.guild_id = scoped_guild_id
  )
  select
    true,
    current_batch.id,
    previous_batch.id,
    dr.rank_position,
    dr.profile_id,
    dr.username,
    dr.ign,
    dr.guild_id,
    dr.guild_name,
    dr.previous_cp,
    dr.current_cp,
    dr.growth_amount,
    dr.growth_percent,
    dr.last_updated,
    dr.missing_update
  from decorated_rows dr
  order by dr.rank_position;
end;
$$;

create or replace function public.get_admin_live_cp_growth(
  p_guild_id uuid,
  p_baseline_batch_id uuid
)
returns table (
  has_baseline boolean,
  baseline_batch_id uuid,
  baseline_captured_at timestamptz,
  baseline_label text,
  baseline_week_start date,
  baseline_week_end date,
  reset_day_of_week integer,
  reset_day_label text,
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  baseline_cp integer,
  current_cp integer,
  growth_amount integer,
  growth_percent numeric,
  last_updated timestamptz,
  missing_baseline boolean,
  missing_current_cp boolean
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  scoped_guild_id uuid := p_guild_id;
  requested_baseline_id uuid := p_baseline_batch_id;
  scoped_guild_name text;
  baseline_batch public.cp_snapshot_batches%rowtype;
  v_reset_day integer := 0;
  v_reset_day_label text := 'Sunday';
begin
  if scoped_guild_id is not null then
    select g.name into scoped_guild_name
    from public.guilds g
    where g.id = scoped_guild_id
      and g.status = 'active';

    if scoped_guild_name is null then
      raise exception 'Active guild not found.';
    end if;
  end if;

  if scoped_guild_id is null then
    if not private.is_owner(actor_id) then
      raise exception 'Only Owner can view global live CP growth.';
    end if;
  elsif not private.can_view_cp(actor_id, scoped_guild_id) then
    raise exception 'Not authorized to view live CP growth.';
  end if;

  if requested_baseline_id is not null then
    select * into baseline_batch
    from public.cp_snapshot_batches b
    where b.id = requested_baseline_id;

    if not found then
      raise exception 'Selected baseline was not found.';
    end if;

    if scoped_guild_id is null and baseline_batch.guild_id is not null then
      raise exception 'Selected baseline is not available for this analytics scope.';
    end if;

    if scoped_guild_id is not null
       and baseline_batch.guild_id is not null
       and baseline_batch.guild_id <> scoped_guild_id then
      raise exception 'Selected baseline is not available for this analytics scope.';
    end if;

    if scoped_guild_id is not null
       and baseline_batch.guild_id is null
       and not private.is_owner(actor_id) then
      raise exception 'Only Owner can use a global baseline for guild analytics.';
    end if;
  else
    select * into baseline_batch
    from public.cp_snapshot_batches b
    where b.guild_id is not distinct from scoped_guild_id
    order by b.captured_at desc, b.id desc
    limit 1;
  end if;

  if baseline_batch.id is null then
    return query
    select
      false,
      null::uuid,
      null::timestamptz,
      null::text,
      null::date,
      null::date,
      v_reset_day,
      v_reset_day_label,
      null::integer,
      null::uuid,
      null::text,
      null::text,
      scoped_guild_id,
      scoped_guild_name,
      null::integer,
      null::integer,
      null::integer,
      null::numeric,
      null::timestamptz,
      false,
      false;
    return;
  end if;

  return query
  with eligible_members as (
    select
      gm.profile_id,
      gm.guild_id,
      p.username,
      p.ign,
      g.name as guild_name
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    join public.guilds g on g.id = gm.guild_id
    where (scoped_guild_id is null or gm.guild_id = scoped_guild_id)
      and gm.membership_status = 'active'
      and gm.is_primary = true
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and p.approval_status = 'approved'
      and g.status = 'active'
  ),
  growth_rows as (
    select
      em.profile_id,
      em.username,
      em.ign,
      em.guild_id,
      em.guild_name,
      baseline.cp_value as baseline_cp,
      cp.cp_value as current_cp,
      case
        when baseline.cp_value is null or cp.cp_value is null then null
        else cp.cp_value - baseline.cp_value
      end as growth_amount,
      case
        when baseline.cp_value is null
          or cp.cp_value is null
          or baseline.cp_value = 0 then null
        else round(((cp.cp_value - baseline.cp_value)::numeric / baseline.cp_value::numeric) * 100, 2)
      end as growth_percent,
      cp.updated_at as last_updated,
      (baseline.id is null) as missing_baseline,
      (cp.profile_id is null) as missing_current_cp
    from eligible_members em
    left join public.member_cp cp
      on cp.profile_id = em.profile_id
     and cp.guild_id = em.guild_id
    left join public.cp_snapshot_entries baseline
      on baseline.batch_id = baseline_batch.id
     and baseline.profile_id = em.profile_id
     and baseline.guild_id = em.guild_id
  ),
  ranked_rows as (
    select
      gr.*,
      row_number() over (
        order by gr.growth_amount desc nulls last, lower(coalesce(gr.ign, gr.username, gr.profile_id::text)) asc, gr.profile_id asc
      )::integer as rank_position
    from growth_rows gr
  )
  select
    true,
    baseline_batch.id,
    baseline_batch.captured_at,
    baseline_batch.label,
    baseline_batch.week_start,
    baseline_batch.week_end,
    v_reset_day,
    v_reset_day_label,
    rr.rank_position,
    rr.profile_id,
    rr.username,
    rr.ign,
    rr.guild_id,
    rr.guild_name,
    rr.baseline_cp,
    rr.current_cp,
    rr.growth_amount,
    rr.growth_percent,
    rr.last_updated,
    rr.missing_baseline,
    rr.missing_current_cp
  from ranked_rows rr
  order by rr.rank_position;
end;
$$;

create or replace function public.get_admin_live_cp_growth(p_guild_id uuid default null)
returns table (
  has_baseline boolean,
  baseline_batch_id uuid,
  baseline_captured_at timestamptz,
  baseline_label text,
  baseline_week_start date,
  baseline_week_end date,
  reset_day_of_week integer,
  reset_day_label text,
  rank integer,
  profile_id uuid,
  username text,
  ign text,
  guild_id uuid,
  guild_name text,
  baseline_cp integer,
  current_cp integer,
  growth_amount integer,
  growth_percent numeric,
  last_updated timestamptz,
  missing_baseline boolean,
  missing_current_cp boolean
)
language sql
security definer
set search_path = pg_catalog, public, private, auth
as $$
  select *
  from public.get_admin_live_cp_growth(p_guild_id, null::uuid);
$$;

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
  actor_id uuid := private.active_admin_profile_id();
  safe_limit integer;
  has_audit_scope boolean;
begin
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
        al.action in ('member_cp_updated', 'member_cp_self_submitted', 'weekly_cp_snapshot_captured')
        or al.entity_table in ('member_cp', 'cp_snapshots', 'cp_snapshot_batches', 'cp_snapshot_entries')
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

revoke all on function public.get_cp_update_window_for_guild(uuid) from public, anon;
revoke all on function public.update_member_cp(uuid, integer, text) from public, anon;
revoke all on function public.get_current_cp_roster(uuid) from public, anon;
revoke all on function public.get_admin_cp_rankings(uuid, text) from public, anon;
revoke all on function public.open_cp_update_window(uuid, timestamptz, timestamptz, text) from public, anon;
revoke all on function public.close_cp_update_window(uuid) from public, anon;
revoke all on function public.get_admin_member_analytics(uuid) from public, anon;
revoke all on function public.get_admin_cp_analytics(uuid) from public, anon;
revoke all on function public.get_admin_gvg_analytics(uuid) from public, anon;
revoke all on function public.start_new_cp_growth_period(uuid, text) from public, anon;
revoke all on function public.capture_weekly_cp_snapshot(uuid) from public, anon;
revoke all on function public.get_admin_cp_snapshot_history(uuid) from public, anon;
revoke all on function public.get_admin_cp_growth_report(uuid, uuid) from public, anon;
revoke all on function public.get_admin_live_cp_growth(uuid) from public, anon;
revoke all on function public.get_admin_live_cp_growth(uuid, uuid) from public, anon;
revoke all on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  from public, anon;

grant execute on function public.get_cp_update_window_for_guild(uuid) to authenticated;
grant execute on function public.update_member_cp(uuid, integer, text) to authenticated;
grant execute on function public.get_current_cp_roster(uuid) to authenticated;
grant execute on function public.get_admin_cp_rankings(uuid, text) to authenticated;
grant execute on function public.open_cp_update_window(uuid, timestamptz, timestamptz, text) to authenticated;
grant execute on function public.close_cp_update_window(uuid) to authenticated;
grant execute on function public.get_admin_member_analytics(uuid) to authenticated;
grant execute on function public.get_admin_cp_analytics(uuid) to authenticated;
grant execute on function public.get_admin_gvg_analytics(uuid) to authenticated;
grant execute on function public.start_new_cp_growth_period(uuid, text) to authenticated;
grant execute on function public.capture_weekly_cp_snapshot(uuid) to authenticated;
grant execute on function public.get_admin_cp_snapshot_history(uuid) to authenticated;
grant execute on function public.get_admin_cp_growth_report(uuid, uuid) to authenticated;
grant execute on function public.get_admin_live_cp_growth(uuid) to authenticated;
grant execute on function public.get_admin_live_cp_growth(uuid, uuid) to authenticated;
grant execute on function public.get_audit_logs(uuid, text, uuid, uuid, timestamptz, timestamptz, integer, timestamptz)
  to authenticated;
