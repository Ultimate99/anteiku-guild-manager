-- Anteiku Guild Manager - Account Switcher backend foundation
-- Adds account/profile link storage and safe switcher RPCs for future
-- multi-profile support. Existing runtime behavior is intentionally not
-- switched over in this milestone.

create table if not exists public.user_profile_links (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  link_type text not null default 'owner',
  is_primary boolean not null default false,
  created_by_profile_id uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  disabled_at timestamptz,
  constraint user_profile_links_type_chk check (link_type in ('owner'))
);

create table if not exists public.user_active_profiles (
  auth_user_id uuid primary key references auth.users(id) on delete cascade,
  active_profile_id uuid not null references public.profiles(id) on delete cascade,
  updated_at timestamptz not null default now()
);

create unique index if not exists user_profile_links_active_auth_profile_uidx
  on public.user_profile_links (auth_user_id, profile_id)
  where disabled_at is null;

create unique index if not exists user_profile_links_active_owner_profile_uidx
  on public.user_profile_links (profile_id)
  where disabled_at is null and link_type = 'owner';

create unique index if not exists user_profile_links_primary_auth_uidx
  on public.user_profile_links (auth_user_id)
  where disabled_at is null and is_primary = true;

create index if not exists user_profile_links_auth_active_idx
  on public.user_profile_links (auth_user_id, disabled_at, created_at desc);

create index if not exists user_profile_links_profile_active_idx
  on public.user_profile_links (profile_id, disabled_at);

alter table public.user_profile_links enable row level security;
alter table public.user_active_profiles enable row level security;

revoke all on public.user_profile_links from public, anon, authenticated;
revoke all on public.user_active_profiles from public, anon, authenticated;

create or replace function private.ensure_profile_self_link()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
begin
  if exists (
    select 1
    from auth.users u
    where u.id = new.id
  ) and not exists (
    select 1
    from public.user_profile_links upl
    where upl.auth_user_id = new.id
      and upl.profile_id = new.id
      and upl.disabled_at is null
  ) then
    insert into public.user_profile_links (
      auth_user_id,
      profile_id,
      link_type,
      is_primary,
      created_by_profile_id
    )
    values (
      new.id,
      new.id,
      'owner',
      not exists (
        select 1
        from public.user_profile_links primary_link
        where primary_link.auth_user_id = new.id
          and primary_link.is_primary = true
          and primary_link.disabled_at is null
      ),
      new.id
    );
  end if;

  return new;
end;
$$;

drop trigger if exists ensure_profile_self_link on public.profiles;
create trigger ensure_profile_self_link
after insert on public.profiles
for each row
execute function private.ensure_profile_self_link();

insert into public.user_profile_links (
  auth_user_id,
  profile_id,
  link_type,
  is_primary,
  created_by_profile_id
)
select
  p.id,
  p.id,
  'owner',
  true,
  p.id
from public.profiles p
join auth.users u on u.id = p.id
where not exists (
  select 1
  from public.user_profile_links upl
  where upl.auth_user_id = p.id
    and upl.profile_id = p.id
    and upl.disabled_at is null
);

create or replace function private.enforce_user_active_profile_link()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  if not exists (
    select 1
    from public.user_profile_links upl
    where upl.auth_user_id = new.auth_user_id
      and upl.profile_id = new.active_profile_id
      and upl.disabled_at is null
  ) then
    raise exception 'Active profile must be linked to the signed-in account.';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists enforce_user_active_profile_link on public.user_active_profiles;
create trigger enforce_user_active_profile_link
before insert or update on public.user_active_profiles
for each row
execute function private.enforce_user_active_profile_link();

create or replace function private.get_active_profile_id()
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
begin
  if actor_auth_id is null then
    return null;
  end if;

  if exists (
    select 1
    from public.user_active_profiles uap
    where uap.auth_user_id = actor_auth_id
  ) then
    select uap.active_profile_id
    into active_profile_id
    from public.user_active_profiles uap
    join public.user_profile_links upl
      on upl.auth_user_id = uap.auth_user_id
     and upl.profile_id = uap.active_profile_id
     and upl.disabled_at is null
    where uap.auth_user_id = actor_auth_id
    limit 1;

    if active_profile_id is null then
      raise exception 'Active profile link is no longer available.';
    end if;

    return active_profile_id;
  end if;

  if exists (
    select 1
    from public.profiles p
    where p.id = actor_auth_id
  ) then
    return actor_auth_id;
  end if;

  return null;
end;
$$;

create or replace function private.build_account_switcher_profile_summary(
  p_auth_user_id uuid,
  p_profile_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  profile_record record;
  resolved_active_profile_id uuid;
begin
  select coalesce(uap.active_profile_id, p_auth_user_id)
  into resolved_active_profile_id
  from (select p_auth_user_id as auth_user_id) actor
  left join public.user_active_profiles uap
    on uap.auth_user_id = actor.auth_user_id;

  select
    p.id,
    p.username,
    p.profile_slug,
    p.ign,
    p.approval_status,
    gm.guild_id,
    g.name as guild_name,
    g.slug as guild_slug,
    gm.role,
    gm.membership_status,
    gm.roster_status,
    coalesce(avatar.key, default_avatar.key) as avatar_key,
    coalesce(avatar.asset_path, default_avatar.asset_path) as avatar_asset_path,
    coalesce(frame.key, default_frame.key) as frame_key,
    coalesce(frame.asset_path, default_frame.asset_path) as frame_asset_path,
    upl.is_primary
  into profile_record
  from public.profiles p
  join public.user_profile_links upl
    on upl.auth_user_id = p_auth_user_id
   and upl.profile_id = p.id
   and upl.disabled_at is null
  left join lateral (
    select gm_inner.*
    from public.guild_memberships gm_inner
    where gm_inner.profile_id = p.id
      and gm_inner.is_primary = true
    order by
      case gm_inner.membership_status
        when 'active' then 1
        when 'pending' then 2
        when 'rejected' then 3
        else 4
      end,
      gm_inner.created_at desc
    limit 1
  ) gm on true
  left join public.guilds g on g.id = gm.guild_id
  left join public.profile_equipped_cosmetics pec on pec.profile_id = p.id
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
  where p.id = p_profile_id
  limit 1;

  if not found then
    return null;
  end if;

  return jsonb_build_object(
    'profile_id', profile_record.id,
    'username', profile_record.username,
    'profile_slug', profile_record.profile_slug,
    'ign', profile_record.ign,
    'approval_status', profile_record.approval_status,
    'guild_id', profile_record.guild_id,
    'guild_name', profile_record.guild_name,
    'guild_slug', profile_record.guild_slug,
    'role', profile_record.role,
    'role_label', case profile_record.role
      when 'owner' then 'Owner'
      when 'leader' then 'Leader'
      when 'vice' then 'Vice'
      when 'admin' then 'Admin'
      when 'member' then 'Member'
      else null
    end,
    'membership_status', profile_record.membership_status,
    'roster_status', profile_record.roster_status,
    'avatar_key', profile_record.avatar_key,
    'avatar_asset_path', profile_record.avatar_asset_path,
    'frame_key', profile_record.frame_key,
    'frame_asset_path', profile_record.frame_asset_path,
    'is_active_profile', resolved_active_profile_id = profile_record.id,
    'is_primary', coalesce(profile_record.is_primary, false)
  );
end;
$$;

create or replace function public.get_my_switchable_profiles()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  profiles_payload jsonb := '[]'::jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  select coalesce(
    jsonb_agg(
      private.build_account_switcher_profile_summary(actor_auth_id, upl.profile_id)
      order by upl.is_primary desc, p.ign asc, p.username asc
    ),
    '[]'::jsonb
  )
  into profiles_payload
  from public.user_profile_links upl
  join public.profiles p on p.id = upl.profile_id
  where upl.auth_user_id = actor_auth_id
    and upl.disabled_at is null;

  if profiles_payload = '[]'::jsonb
     and exists (select 1 from public.profiles p where p.id = actor_auth_id) then
    profiles_payload := jsonb_build_array(
      private.build_account_switcher_profile_summary(actor_auth_id, actor_auth_id)
    );
  end if;

  return jsonb_build_object('profiles', profiles_payload);
end;
$$;

create or replace function public.get_my_active_profile()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
  profile_payload jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile not found.';
  end if;

  profile_payload := private.build_account_switcher_profile_summary(actor_auth_id, active_profile_id);

  if profile_payload is null then
    raise exception 'Active profile not found.';
  end if;

  return jsonb_build_object('profile', profile_payload);
end;
$$;

create or replace function public.set_my_active_profile(p_profile_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  previous_profile_id uuid;
  audit_actor_id uuid;
  profile_payload jsonb;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_profile_id is null then
    raise exception 'Profile is required.';
  end if;

  if not exists (
    select 1
    from public.user_profile_links upl
    where upl.auth_user_id = actor_auth_id
      and upl.profile_id = p_profile_id
      and upl.disabled_at is null
  ) then
    raise exception 'Profile is not linked to this account.';
  end if;

  previous_profile_id := private.get_active_profile_id();

  insert into public.user_active_profiles (
    auth_user_id,
    active_profile_id,
    updated_at
  )
  values (
    actor_auth_id,
    p_profile_id,
    now()
  )
  on conflict (auth_user_id) do update
  set active_profile_id = excluded.active_profile_id,
      updated_at = now();

  audit_actor_id := coalesce(previous_profile_id, p_profile_id);

  perform private.write_audit_log(
    audit_actor_id,
    p_profile_id,
    private.target_primary_guild_id(p_profile_id),
    'active_profile_switched',
    'user_active_profiles',
    p_profile_id,
    jsonb_build_object(
      'previous_profile_id', previous_profile_id,
      'active_profile_id', p_profile_id
    )
  );

  profile_payload := private.build_account_switcher_profile_summary(actor_auth_id, p_profile_id);

  return jsonb_build_object('profile', profile_payload);
end;
$$;

create or replace function public.owner_link_profile_to_auth_user(
  p_auth_email text,
  p_profile_slug text,
  p_link_type text default 'owner'
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_email text := lower(btrim(coalesce(p_auth_email, '')));
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  normalized_link_type text := lower(btrim(coalesce(p_link_type, 'owner')));
  target_auth_id uuid;
  target_profile record;
  created_link_id uuid;
  should_be_primary boolean;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if normalized_link_type <> 'owner' then
    raise exception 'Unsupported account link type.';
  end if;

  if normalized_email = '' then
    raise exception 'Auth email is required.';
  end if;

  if normalized_slug = '' then
    raise exception 'Profile slug or username is required.';
  end if;

  select u.id
  into target_auth_id
  from auth.users u
  where lower(u.email) = normalized_email
  order by u.created_at desc
  limit 1;

  if target_auth_id is null then
    raise exception 'Auth user not found.';
  end if;

  select p.id, p.username, p.profile_slug, p.ign
  into target_profile
  from public.profiles p
  where p.profile_slug = normalized_slug
     or lower(p.username) = normalized_slug
  order by p.created_at desc
  limit 1;

  if not found then
    raise exception 'Profile not found.';
  end if;

  if exists (
    select 1
    from public.user_profile_links upl
    where upl.profile_id = target_profile.id
      and upl.link_type = 'owner'
      and upl.disabled_at is null
      and upl.auth_user_id <> target_auth_id
  ) then
    raise exception 'Profile already has an active owner link.';
  end if;

  if exists (
    select 1
    from public.user_profile_links upl
    where upl.auth_user_id = target_auth_id
      and upl.profile_id = target_profile.id
      and upl.disabled_at is null
  ) then
    select upl.id
    into created_link_id
    from public.user_profile_links upl
    where upl.auth_user_id = target_auth_id
      and upl.profile_id = target_profile.id
      and upl.disabled_at is null
    limit 1;
  else
    should_be_primary := not exists (
      select 1
      from public.user_profile_links upl
      where upl.auth_user_id = target_auth_id
        and upl.is_primary = true
        and upl.disabled_at is null
    );

    insert into public.user_profile_links (
      auth_user_id,
      profile_id,
      link_type,
      is_primary,
      created_by_profile_id
    )
    values (
      target_auth_id,
      target_profile.id,
      normalized_link_type,
      should_be_primary,
      actor_id
    )
    returning id into created_link_id;
  end if;

  perform private.write_audit_log(
    actor_id,
    target_profile.id,
    private.target_primary_guild_id(target_profile.id),
    'account_profile_linked',
    'user_profile_links',
    created_link_id,
    jsonb_build_object('link_type', normalized_link_type)
  );

  return jsonb_build_object(
    'linked', true,
    'profile', private.build_account_switcher_profile_summary(target_auth_id, target_profile.id)
  );
end;
$$;

create or replace function public.owner_unlink_profile_from_auth_user(
  p_auth_email text,
  p_profile_slug text
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_email text := lower(btrim(coalesce(p_auth_email, '')));
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  target_auth_id uuid;
  target_profile record;
  disabled_link_id uuid;
  replacement_profile_id uuid;
  active_was_cleared boolean := false;
  active_owner_profile_count integer;
  target_active_link_count integer;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if normalized_email = '' then
    raise exception 'Auth email is required.';
  end if;

  if normalized_slug = '' then
    raise exception 'Profile slug or username is required.';
  end if;

  select u.id
  into target_auth_id
  from auth.users u
  where lower(u.email) = normalized_email
  order by u.created_at desc
  limit 1;

  if target_auth_id is null then
    raise exception 'Auth user not found.';
  end if;

  select p.id, p.username, p.profile_slug, p.ign
  into target_profile
  from public.profiles p
  where p.profile_slug = normalized_slug
     or lower(p.username) = normalized_slug
  order by p.created_at desc
  limit 1;

  if not found then
    raise exception 'Profile not found.';
  end if;

  if private.is_owner(target_profile.id) then
    select count(*)
    into active_owner_profile_count
    from public.guild_memberships gm
    join public.profiles p on p.id = gm.profile_id
    where gm.role = 'owner'
      and gm.membership_status = 'active'
      and p.approval_status = 'approved';

    select count(*)
    into target_active_link_count
    from public.user_profile_links upl
    where upl.profile_id = target_profile.id
      and upl.disabled_at is null;

    if active_owner_profile_count <= 1 and target_active_link_count <= 1 then
      raise exception 'Cannot unlink the only active Owner profile.';
    end if;
  end if;

  update public.user_profile_links upl
  set disabled_at = now(),
      is_primary = false
  where upl.auth_user_id = target_auth_id
    and upl.profile_id = target_profile.id
    and upl.disabled_at is null
  returning upl.id into disabled_link_id;

  if disabled_link_id is null then
    raise exception 'Active account profile link not found.';
  end if;

  if exists (
    select 1
    from public.user_active_profiles uap
    where uap.auth_user_id = target_auth_id
      and uap.active_profile_id = target_profile.id
  ) then
    select upl.profile_id
    into replacement_profile_id
    from public.user_profile_links upl
    where upl.auth_user_id = target_auth_id
      and upl.disabled_at is null
    order by upl.is_primary desc, upl.created_at asc
    limit 1;

    if replacement_profile_id is not null then
      update public.user_active_profiles
      set active_profile_id = replacement_profile_id,
          updated_at = now()
      where auth_user_id = target_auth_id;
    else
      delete from public.user_active_profiles
      where auth_user_id = target_auth_id;
    end if;

    active_was_cleared := true;
  end if;

  if not exists (
    select 1
    from public.user_profile_links upl
    where upl.auth_user_id = target_auth_id
      and upl.is_primary = true
      and upl.disabled_at is null
  ) then
    update public.user_profile_links upl
    set is_primary = true
    where upl.id = (
      select next_link.id
      from public.user_profile_links next_link
      where next_link.auth_user_id = target_auth_id
        and next_link.disabled_at is null
      order by next_link.created_at asc
      limit 1
    );
  end if;

  perform private.write_audit_log(
    actor_id,
    target_profile.id,
    private.target_primary_guild_id(target_profile.id),
    'account_profile_unlinked',
    'user_profile_links',
    disabled_link_id,
    jsonb_build_object('active_profile_cleared', active_was_cleared)
  );

  return jsonb_build_object(
    'unlinked', true,
    'active_profile_cleared', active_was_cleared
  );
end;
$$;

revoke all on function private.ensure_profile_self_link() from public, anon, authenticated;
revoke all on function private.enforce_user_active_profile_link() from public, anon, authenticated;
revoke all on function private.build_account_switcher_profile_summary(uuid, uuid) from public, anon, authenticated;

revoke all on function private.get_active_profile_id() from public, anon, authenticated;
grant execute on function private.get_active_profile_id() to authenticated;

revoke all on function public.get_my_switchable_profiles() from public, anon;
revoke all on function public.get_my_active_profile() from public, anon;
revoke all on function public.set_my_active_profile(uuid) from public, anon;
revoke all on function public.owner_link_profile_to_auth_user(text, text, text) from public, anon;
revoke all on function public.owner_unlink_profile_from_auth_user(text, text) from public, anon;

grant execute on function public.get_my_switchable_profiles() to authenticated;
grant execute on function public.get_my_active_profile() to authenticated;
grant execute on function public.set_my_active_profile(uuid) to authenticated;
grant execute on function public.owner_link_profile_to_auth_user(text, text, text) to authenticated;
grant execute on function public.owner_unlink_profile_from_auth_user(text, text) to authenticated;
