-- Anteiku Guild Manager - Active Profile Push Notifications
-- Migrates push preference/recipient-facing RPCs to the selected active
-- profile while keeping the browser subscription owned by the auth account.

alter table public.push_subscriptions
  add column if not exists auth_user_id uuid;

update public.push_subscriptions ps
set auth_user_id = coalesce(
  (
    select upl.auth_user_id
    from public.user_profile_links upl
    where upl.profile_id = ps.profile_id
      and upl.disabled_at is null
    order by upl.is_primary desc, upl.created_at asc
    limit 1
  ),
  ps.profile_id
)
where ps.auth_user_id is null;

alter table public.push_subscriptions
  alter column auth_user_id set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'push_subscriptions_auth_user_id_fkey'
      and conrelid = 'public.push_subscriptions'::regclass
  ) then
    alter table public.push_subscriptions
      add constraint push_subscriptions_auth_user_id_fkey
      foreign key (auth_user_id) references auth.users(id) on delete cascade;
  end if;
end;
$$;

create index if not exists push_subscriptions_auth_active_idx
  on public.push_subscriptions (auth_user_id, disabled_at, updated_at desc);

create or replace function private.push_notification_type_enabled(
  p_recipient_profile_id uuid,
  p_type text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  preference_row public.push_notification_preferences;
begin
  if p_type = 'self_test' then
    return true;
  end if;

  preference_row := private.ensure_push_preferences(p_recipient_profile_id);

  return case p_type
    when 'gvg_event_opened' then preference_row.notify_gvg
    when 'cp_window_opened' then preference_row.notify_cp_window
    when 'three_v_three_join_request_received' then preference_row.notify_3v3
    when 'three_v_three_request_approved' then preference_row.notify_3v3
    when 'three_v_three_request_declined' then preference_row.notify_3v3
    when 'wall_comment_on_post' then preference_row.notify_wall_comments
    else false
  end;
end;
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

  if not private.push_notification_type_enabled(p_recipient_profile_id, p_type) then
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

create or replace function private.build_push_preferences_payload(
  p_profile_id uuid,
  p_auth_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  preference_row public.push_notification_preferences;
  active_subscription_count integer;
  subscription_owner_id uuid := coalesce(p_auth_user_id, auth.uid(), p_profile_id);
begin
  preference_row := private.ensure_push_preferences(p_profile_id);

  select count(*)
  into active_subscription_count
  from public.push_subscriptions ps
  where ps.auth_user_id = subscription_owner_id
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
  auth_account_id uuid := auth.uid();
  actor_id uuid;
  normalized_endpoint text := btrim(coalesce(p_endpoint, ''));
  normalized_p256dh_key text := btrim(coalesce(p_p256dh_key, ''));
  normalized_auth_key text := btrim(coalesce(p_auth_key, ''));
  normalized_user_agent text := nullif(left(btrim(coalesce(p_user_agent, '')), 512), '');
begin
  if auth_account_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

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
    auth_user_id,
    profile_id,
    endpoint,
    p256dh_key,
    auth_key,
    user_agent,
    disabled_at
  )
  values (
    auth_account_id,
    actor_id,
    normalized_endpoint,
    normalized_p256dh_key,
    normalized_auth_key,
    normalized_user_agent,
    null
  )
  on conflict (endpoint) where disabled_at is null do update
  set auth_user_id = excluded.auth_user_id,
      profile_id = excluded.profile_id,
      p256dh_key = excluded.p256dh_key,
      auth_key = excluded.auth_key,
      user_agent = excluded.user_agent,
      disabled_at = null,
      updated_at = now();

  perform private.ensure_push_preferences(actor_id);

  return jsonb_build_object(
    'enabled', true,
    'preferences', private.build_push_preferences_payload(actor_id, auth_account_id)
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
  auth_account_id uuid := auth.uid();
  actor_id uuid;
  normalized_endpoint text := btrim(coalesce(p_endpoint, ''));
begin
  if auth_account_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

  update public.push_subscriptions ps
  set disabled_at = coalesce(ps.disabled_at, now()),
      updated_at = now()
  where ps.auth_user_id = auth_account_id
    and ps.endpoint = normalized_endpoint
    and ps.disabled_at is null;

  return jsonb_build_object(
    'disabled', true,
    'preferences', private.build_push_preferences_payload(actor_id, auth_account_id)
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
  auth_account_id uuid := auth.uid();
  actor_id uuid;
begin
  if auth_account_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

  if not private.has_push_notification_eligibility(actor_id) then
    raise exception 'Approved active profile required for push notifications.';
  end if;

  return private.build_push_preferences_payload(actor_id, auth_account_id);
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
  auth_account_id uuid := auth.uid();
  actor_id uuid;
begin
  if auth_account_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

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

  return private.build_push_preferences_payload(actor_id, auth_account_id);
end;
$$;

create or replace function public.create_my_test_push_notification()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  auth_account_id uuid := auth.uid();
  actor_id uuid;
  new_outbox_id uuid;
begin
  if auth_account_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_id := private.get_active_profile_id();

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

revoke all on function private.push_notification_type_enabled(uuid, text) from public, anon, authenticated;
revoke all on function private.enqueue_push_notification(uuid, text, text, text) from public, anon, authenticated;
revoke all on function private.build_push_preferences_payload(uuid, uuid) from public, anon, authenticated;

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
