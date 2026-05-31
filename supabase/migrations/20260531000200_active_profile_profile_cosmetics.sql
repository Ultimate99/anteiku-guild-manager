-- Anteiku Guild Manager - Active Profile Profile/Cosmetics migration
-- Migrates only own Profile identity edit and Cosmetics read/equip paths to the
-- selected active profile. CP, GvG, 3v3, Wall, Push, and Admin action identity
-- remain intentionally unchanged.

create or replace function public.get_my_active_profile_details()
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

create or replace function public.update_my_active_profile(p_ign text)
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

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  update public.profiles
  set
    ign = btrim(p_ign),
    updated_at = now()
  where id = active_profile_id;

  if not found then
    raise exception 'Active profile not found.';
  end if;

  profile_payload := private.build_account_switcher_profile_summary(actor_auth_id, active_profile_id);

  if profile_payload is null then
    raise exception 'Active profile not found.';
  end if;

  return jsonb_build_object('profile', profile_payload);
end;
$$;

create or replace function public.get_my_active_cosmetics()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
  equipped public.profile_equipped_cosmetics%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile not found.';
  end if;

  if not private.is_approved(active_profile_id)
     or private.active_primary_guild_id(active_profile_id) is null then
    raise exception 'Approved active membership required.';
  end if;

  equipped := private.ensure_profile_equipped_cosmetics(active_profile_id);

  return jsonb_build_object(
    'equipped',
    jsonb_build_object(
      'avatar_key', equipped.avatar_key,
      'frame_key', equipped.frame_key
    ),
    'avatars',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'key', c.key,
            'label_key', c.label_key,
            'asset_path', c.asset_path,
            'rarity', c.rarity,
            'sort_order', c.sort_order,
            'unlock_type', c.unlock_type,
            'is_unlocked',
              c.unlock_type = 'free'
              or exists (
                select 1
                from public.profile_cosmetic_unlocks pcu
                where pcu.profile_id = active_profile_id
                  and pcu.cosmetic_key = c.key
              ),
            'is_equipped', c.key = equipped.avatar_key
          )
          order by c.sort_order, c.key
        )
        from public.cosmetic_catalog c
        where c.type = 'avatar'
          and c.is_active = true
      ),
      '[]'::jsonb
    ),
    'frames',
    coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'key', c.key,
            'label_key', c.label_key,
            'asset_path', c.asset_path,
            'rarity', c.rarity,
            'sort_order', c.sort_order,
            'unlock_type', c.unlock_type,
            'is_unlocked',
              c.unlock_type = 'free'
              or exists (
                select 1
                from public.profile_cosmetic_unlocks pcu
                where pcu.profile_id = active_profile_id
                  and pcu.cosmetic_key = c.key
              ),
            'is_equipped', c.key = equipped.frame_key
          )
          order by c.sort_order, c.key
        )
        from public.cosmetic_catalog c
        where c.type = 'frame'
          and c.is_active = true
      ),
      '[]'::jsonb
    )
  );
end;
$$;

create or replace function public.equip_my_active_avatar(p_avatar_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
  actor_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_avatar_key, '')), '');
  selected_cosmetic public.cosmetic_catalog%rowtype;
  current_equipped public.profile_equipped_cosmetics%rowtype;
  updated_equipped public.profile_equipped_cosmetics%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile not found.';
  end if;

  actor_guild_id := private.active_primary_guild_id(active_profile_id);

  if not private.is_approved(active_profile_id) or actor_guild_id is null then
    raise exception 'Approved active membership required.';
  end if;

  if normalized_key is null then
    raise exception 'Avatar key is required.';
  end if;

  select * into selected_cosmetic
  from public.cosmetic_catalog c
  where c.key = normalized_key
    and c.type = 'avatar'
    and c.is_active = true;

  if not found then
    raise exception 'Invalid avatar.';
  end if;

  if selected_cosmetic.unlock_type <> 'free'
     and not exists (
       select 1
       from public.profile_cosmetic_unlocks pcu
       where pcu.profile_id = active_profile_id
         and pcu.cosmetic_key = selected_cosmetic.key
     ) then
    raise exception 'Avatar is locked.';
  end if;

  current_equipped := private.ensure_profile_equipped_cosmetics(active_profile_id);

  insert into public.profile_equipped_cosmetics (
    profile_id,
    avatar_key,
    frame_key,
    updated_at
  )
  values (
    active_profile_id,
    selected_cosmetic.key,
    current_equipped.frame_key,
    now()
  )
  on conflict (profile_id) do update
  set
    avatar_key = excluded.avatar_key,
    updated_at = excluded.updated_at
  returning * into updated_equipped;

  update public.profiles
  set
    avatar_key = selected_cosmetic.key,
    updated_at = now()
  where id = active_profile_id;

  perform private.write_audit_log(
    active_profile_id,
    active_profile_id,
    actor_guild_id,
    'cosmetic_avatar_equipped',
    'profile_equipped_cosmetics',
    active_profile_id,
    jsonb_build_object(
      'cosmetic_key', selected_cosmetic.key,
      'cosmetic_type', selected_cosmetic.type
    )
  );

  return jsonb_build_object(
    'avatar_key', updated_equipped.avatar_key,
    'frame_key', updated_equipped.frame_key
  );
end;
$$;

create or replace function public.equip_my_active_frame(p_frame_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_auth_id uuid := auth.uid();
  active_profile_id uuid;
  actor_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_frame_key, '')), '');
  selected_cosmetic public.cosmetic_catalog%rowtype;
  current_equipped public.profile_equipped_cosmetics%rowtype;
  updated_equipped public.profile_equipped_cosmetics%rowtype;
begin
  if actor_auth_id is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile not found.';
  end if;

  actor_guild_id := private.active_primary_guild_id(active_profile_id);

  if not private.is_approved(active_profile_id) or actor_guild_id is null then
    raise exception 'Approved active membership required.';
  end if;

  if normalized_key is null then
    raise exception 'Frame key is required.';
  end if;

  select * into selected_cosmetic
  from public.cosmetic_catalog c
  where c.key = normalized_key
    and c.type = 'frame'
    and c.is_active = true;

  if not found then
    raise exception 'Invalid frame.';
  end if;

  if selected_cosmetic.unlock_type <> 'free'
     and not exists (
       select 1
       from public.profile_cosmetic_unlocks pcu
       where pcu.profile_id = active_profile_id
         and pcu.cosmetic_key = selected_cosmetic.key
     ) then
    raise exception 'Frame is locked.';
  end if;

  current_equipped := private.ensure_profile_equipped_cosmetics(active_profile_id);

  insert into public.profile_equipped_cosmetics (
    profile_id,
    avatar_key,
    frame_key,
    updated_at
  )
  values (
    active_profile_id,
    current_equipped.avatar_key,
    selected_cosmetic.key,
    now()
  )
  on conflict (profile_id) do update
  set
    frame_key = excluded.frame_key,
    updated_at = excluded.updated_at
  returning * into updated_equipped;

  perform private.write_audit_log(
    active_profile_id,
    active_profile_id,
    actor_guild_id,
    'cosmetic_frame_equipped',
    'profile_equipped_cosmetics',
    active_profile_id,
    jsonb_build_object(
      'cosmetic_key', selected_cosmetic.key,
      'cosmetic_type', selected_cosmetic.type
    )
  );

  return jsonb_build_object(
    'avatar_key', updated_equipped.avatar_key,
    'frame_key', updated_equipped.frame_key
  );
end;
$$;

revoke all on function public.get_my_active_profile_details() from public, anon;
revoke all on function public.update_my_active_profile(text) from public, anon;
revoke all on function public.get_my_active_cosmetics() from public, anon;
revoke all on function public.equip_my_active_avatar(text) from public, anon;
revoke all on function public.equip_my_active_frame(text) from public, anon;

grant execute on function public.get_my_active_profile_details() to authenticated;
grant execute on function public.update_my_active_profile(text) to authenticated;
grant execute on function public.get_my_active_cosmetics() to authenticated;
grant execute on function public.equip_my_active_avatar(text) to authenticated;
grant execute on function public.equip_my_active_frame(text) to authenticated;
