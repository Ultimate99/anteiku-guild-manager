-- Anteiku Guild Manager - Push Notifications foundation
-- Adds opt-in web push subscription/preference storage plus a safe
-- notification outbox. Payload text is generated server-side from fixed
-- notification types; normal protected CP tables/RPCs are not read.

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null,
  p256dh_key text not null,
  auth_key text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  disabled_at timestamptz,
  constraint push_subscriptions_endpoint_chk check (
    char_length(btrim(endpoint)) between 16 and 2048
    and btrim(endpoint) like 'https://%'
  ),
  constraint push_subscriptions_p256dh_chk check (char_length(btrim(p256dh_key)) between 16 and 512),
  constraint push_subscriptions_auth_key_chk check (char_length(btrim(auth_key)) between 8 and 256)
);

create table if not exists public.push_notification_preferences (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  notify_gvg boolean not null default true,
  notify_cp_window boolean not null default true,
  notify_3v3 boolean not null default true,
  notify_wall_comments boolean not null default true,
  notify_wall_reactions boolean not null default false,
  notify_profile_reactions boolean not null default false,
  updated_at timestamptz not null default now()
);

create table if not exists public.push_notification_outbox (
  id uuid primary key default gen_random_uuid(),
  recipient_profile_id uuid not null references public.profiles(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  route text,
  dedupe_key text,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  failed_at timestamptz,
  attempt_count integer not null default 0,
  last_error text,
  constraint push_notification_outbox_type_chk check (
    type in (
      'gvg_event_opened',
      'cp_window_opened',
      'three_v_three_join_request_received',
      'three_v_three_request_approved',
      'three_v_three_request_declined',
      'wall_comment_on_post',
      'self_test'
    )
  ),
  constraint push_notification_outbox_title_chk check (char_length(btrim(title)) between 1 and 80),
  constraint push_notification_outbox_body_chk check (char_length(btrim(body)) between 1 and 160),
  constraint push_notification_outbox_attempt_chk check (attempt_count >= 0),
  constraint push_notification_outbox_route_chk check (
    route is null
    or (
      route like '/%'
      and route not like '//%'
      and route !~ '[[:space:]]'
      and char_length(route) <= 256
    )
  )
);

create unique index if not exists push_subscriptions_active_endpoint_uidx
  on public.push_subscriptions (endpoint)
  where disabled_at is null;

create index if not exists push_subscriptions_profile_active_idx
  on public.push_subscriptions (profile_id, disabled_at, updated_at desc);

create index if not exists push_notification_outbox_pending_idx
  on public.push_notification_outbox (created_at asc)
  where sent_at is null and failed_at is null;

create index if not exists push_notification_outbox_recipient_idx
  on public.push_notification_outbox (recipient_profile_id, created_at desc);

create unique index if not exists push_notification_outbox_pending_dedupe_uidx
  on public.push_notification_outbox (dedupe_key)
  where dedupe_key is not null and sent_at is null and failed_at is null;

drop trigger if exists set_push_subscriptions_updated_at on public.push_subscriptions;
create trigger set_push_subscriptions_updated_at
before update on public.push_subscriptions
for each row
execute function public.set_updated_at();

drop trigger if exists set_push_notification_preferences_updated_at on public.push_notification_preferences;
create trigger set_push_notification_preferences_updated_at
before update on public.push_notification_preferences
for each row
execute function public.set_updated_at();

alter table public.push_subscriptions enable row level security;
alter table public.push_notification_preferences enable row level security;
alter table public.push_notification_outbox enable row level security;

revoke all on public.push_subscriptions from public, anon, authenticated;
revoke all on public.push_notification_preferences from public, anon, authenticated;
revoke all on public.push_notification_outbox from public, anon, authenticated;

create or replace function private.has_push_notification_eligibility(p_profile_id uuid)
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
    join public.guilds g on g.id = gm.guild_id
    where gm.profile_id = p_profile_id
      and gm.membership_status = 'active'
      and gm.roster_status in ('active', 'trial', 'pending_transfer')
      and gm.is_primary = true
      and p.approval_status = 'approved'
      and g.status = 'active'
      and g.is_core = true
  );
$$;

create or replace function private.ensure_push_preferences(p_profile_id uuid)
returns public.push_notification_preferences
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  preference_row public.push_notification_preferences;
begin
  insert into public.push_notification_preferences (profile_id)
  values (p_profile_id)
  on conflict (profile_id) do nothing;

  select *
  into preference_row
  from public.push_notification_preferences
  where profile_id = p_profile_id;

  return preference_row;
end;
$$;

create or replace function private.push_notification_payload(p_type text)
returns table(title text, body text)
language sql
stable
set search_path = pg_catalog
as $$
  select
    'Anteiku Guild Manager'::text as title,
    case p_type
      when 'gvg_event_opened' then 'New GvG event is open.'
      when 'cp_window_opened' then 'CP update window is open.'
      when 'three_v_three_join_request_received' then 'You received a 3v3 join request.'
      when 'three_v_three_request_approved' then 'Your 3v3 request was approved.'
      when 'three_v_three_request_declined' then 'Your 3v3 request was declined.'
      when 'wall_comment_on_post' then 'Someone commented on your post.'
      when 'self_test' then 'Test notification from Anteiku.'
      else null
    end::text as body;
$$;

create or replace function private.enqueue_push_notification(
  p_recipient_profile_id uuid,
  p_type text,
  p_route text default null,
  p_dedupe_key text default null
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  payload_record record;
  new_outbox_id uuid;
begin
  if not private.has_push_notification_eligibility(p_recipient_profile_id) then
    return null;
  end if;

  select payload.title, payload.body
  into payload_record
  from private.push_notification_payload(p_type) payload;

  if payload_record.body is null then
    raise exception 'Unsupported push notification type.';
  end if;

  if p_dedupe_key is not null and exists (
    select 1
    from public.push_notification_outbox pno
    where pno.dedupe_key = p_dedupe_key
      and pno.sent_at is null
      and pno.failed_at is null
  ) then
    select pno.id
    into new_outbox_id
    from public.push_notification_outbox pno
    where pno.dedupe_key = p_dedupe_key
      and pno.sent_at is null
      and pno.failed_at is null
    order by pno.created_at desc
    limit 1;

    return new_outbox_id;
  end if;

  insert into public.push_notification_outbox (
    recipient_profile_id,
    type,
    title,
    body,
    route,
    dedupe_key
  )
  values (
    p_recipient_profile_id,
    p_type,
    payload_record.title,
    payload_record.body,
    nullif(btrim(coalesce(p_route, '')), ''),
    nullif(btrim(coalesce(p_dedupe_key, '')), '')
  )
  returning id into new_outbox_id;

  return new_outbox_id;
end;
$$;

create or replace function private.build_push_preferences_payload(p_profile_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  preference_row public.push_notification_preferences;
  active_subscription_count integer;
begin
  preference_row := private.ensure_push_preferences(p_profile_id);

  select count(*)
  into active_subscription_count
  from public.push_subscriptions ps
  where ps.profile_id = p_profile_id
    and ps.disabled_at is null;

  return jsonb_build_object(
    'notify_gvg', preference_row.notify_gvg,
    'notify_cp_window', preference_row.notify_cp_window,
    'notify_3v3', preference_row.notify_3v3,
    'notify_wall_comments', preference_row.notify_wall_comments,
    'notify_wall_reactions', preference_row.notify_wall_reactions,
    'notify_profile_reactions', preference_row.notify_profile_reactions,
    'has_active_subscription', active_subscription_count > 0,
    'active_subscription_count', active_subscription_count
  );
end;
$$;

create or replace function public.register_push_subscription(
  p_endpoint text,
  p_p256dh_key text,
  p_auth_key text,
  p_user_agent text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_endpoint text := btrim(coalesce(p_endpoint, ''));
  normalized_p256dh_key text := btrim(coalesce(p_p256dh_key, ''));
  normalized_auth_key text := btrim(coalesce(p_auth_key, ''));
  normalized_user_agent text := nullif(left(btrim(coalesce(p_user_agent, '')), 512), '');
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_push_notification_eligibility(actor_id) then
    raise exception 'Approved active profile required for push notifications.';
  end if;

  if char_length(normalized_endpoint) < 16
     or char_length(normalized_endpoint) > 2048
     or normalized_endpoint not like 'https://%' then
    raise exception 'Invalid push endpoint.';
  end if;

  if char_length(normalized_p256dh_key) < 16
     or char_length(normalized_p256dh_key) > 512 then
    raise exception 'Invalid push p256dh key.';
  end if;

  if char_length(normalized_auth_key) < 8
     or char_length(normalized_auth_key) > 256 then
    raise exception 'Invalid push auth key.';
  end if;

  insert into public.push_subscriptions (
    profile_id,
    endpoint,
    p256dh_key,
    auth_key,
    user_agent,
    disabled_at
  )
  values (
    actor_id,
    normalized_endpoint,
    normalized_p256dh_key,
    normalized_auth_key,
    normalized_user_agent,
    null
  )
  on conflict (endpoint) where disabled_at is null do update
  set profile_id = excluded.profile_id,
      p256dh_key = excluded.p256dh_key,
      auth_key = excluded.auth_key,
      user_agent = excluded.user_agent,
      disabled_at = null,
      updated_at = now();

  perform private.ensure_push_preferences(actor_id);

  return jsonb_build_object(
    'enabled', true,
    'preferences', private.build_push_preferences_payload(actor_id)
  );
end;
$$;

create or replace function public.disable_push_subscription(p_endpoint text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_endpoint text := btrim(coalesce(p_endpoint, ''));
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  update public.push_subscriptions ps
  set disabled_at = coalesce(ps.disabled_at, now()),
      updated_at = now()
  where ps.profile_id = actor_id
    and ps.endpoint = normalized_endpoint
    and ps.disabled_at is null;

  return jsonb_build_object(
    'disabled', true,
    'preferences', private.build_push_preferences_payload(actor_id)
  );
end;
$$;

create or replace function public.get_my_push_preferences()
returns jsonb
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

  if not private.has_push_notification_eligibility(actor_id) then
    raise exception 'Approved active profile required for push notifications.';
  end if;

  return private.build_push_preferences_payload(actor_id);
end;
$$;

create or replace function public.update_my_push_preferences(
  p_notify_gvg boolean,
  p_notify_cp_window boolean,
  p_notify_3v3 boolean,
  p_notify_wall_comments boolean,
  p_notify_wall_reactions boolean default false,
  p_notify_profile_reactions boolean default false
)
returns jsonb
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

  if not private.has_push_notification_eligibility(actor_id) then
    raise exception 'Approved active profile required for push notifications.';
  end if;

  insert into public.push_notification_preferences (
    profile_id,
    notify_gvg,
    notify_cp_window,
    notify_3v3,
    notify_wall_comments,
    notify_wall_reactions,
    notify_profile_reactions,
    updated_at
  )
  values (
    actor_id,
    coalesce(p_notify_gvg, true),
    coalesce(p_notify_cp_window, true),
    coalesce(p_notify_3v3, true),
    coalesce(p_notify_wall_comments, true),
    coalesce(p_notify_wall_reactions, false),
    coalesce(p_notify_profile_reactions, false),
    now()
  )
  on conflict (profile_id) do update
  set notify_gvg = excluded.notify_gvg,
      notify_cp_window = excluded.notify_cp_window,
      notify_3v3 = excluded.notify_3v3,
      notify_wall_comments = excluded.notify_wall_comments,
      notify_wall_reactions = excluded.notify_wall_reactions,
      notify_profile_reactions = excluded.notify_profile_reactions,
      updated_at = now();

  return private.build_push_preferences_payload(actor_id);
end;
$$;

create or replace function public.create_my_test_push_notification()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  new_outbox_id uuid;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.has_push_notification_eligibility(actor_id) then
    raise exception 'Approved active profile required for push notifications.';
  end if;

  new_outbox_id := private.enqueue_push_notification(
    actor_id,
    'self_test',
    '/',
    'self-test:' || actor_id::text || ':' || date_trunc('minute', now())::text
  );

  return jsonb_build_object('queued', new_outbox_id is not null);
end;
$$;

revoke all on function private.has_push_notification_eligibility(uuid) from public, anon, authenticated;
revoke all on function private.ensure_push_preferences(uuid) from public, anon, authenticated;
revoke all on function private.push_notification_payload(text) from public, anon, authenticated;
revoke all on function private.enqueue_push_notification(uuid, text, text, text) from public, anon, authenticated;
revoke all on function private.build_push_preferences_payload(uuid) from public, anon, authenticated;

revoke all on function public.register_push_subscription(text, text, text, text) from public, anon;
revoke all on function public.disable_push_subscription(text) from public, anon;
revoke all on function public.get_my_push_preferences() from public, anon;
revoke all on function public.update_my_push_preferences(boolean, boolean, boolean, boolean, boolean, boolean) from public, anon;
revoke all on function public.create_my_test_push_notification() from public, anon;

grant execute on function public.register_push_subscription(text, text, text, text) to authenticated;
grant execute on function public.disable_push_subscription(text) to authenticated;
grant execute on function public.get_my_push_preferences() to authenticated;
grant execute on function public.update_my_push_preferences(boolean, boolean, boolean, boolean, boolean, boolean) to authenticated;
grant execute on function public.create_my_test_push_notification() to authenticated;
