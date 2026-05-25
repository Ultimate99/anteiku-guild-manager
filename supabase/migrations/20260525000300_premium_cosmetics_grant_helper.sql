-- Anteiku Guild Manager - Premium cosmetics unlock hardening and grant helper
-- Safe migration: keeps current cosmetics live behavior while making all current
-- frames free, enforcing unlocks for future manual avatars/frames, and adding a
-- slug-based admin grant helper. No uploads, arbitrary URLs, or storage buckets
-- are introduced.

update public.cosmetic_catalog
set
  unlock_type = 'free',
  updated_at = now()
where type = 'frame'
  and key in (
    'TXK_frame_reOpen_EN_FREE',
    'TXK_C1121_lock_FREE',
    'TXK_C1164_lock_FREE',
    'TXK_C1168_lock_FREE',
    'TXK_C1001_lock',
    'TXK_C1007_lock',
    'TXK_C1135_lock',
    'TXK_C1138_lock',
    'TXK_C1147_lock',
    'TXK_C1160_lock'
  )
  and unlock_type <> 'free';

create or replace function public.get_my_cosmetics()
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  equipped public.profile_equipped_cosmetics%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id)
     or private.active_primary_guild_id(actor_id) is null then
    raise exception 'Approved active membership required.';
  end if;

  equipped := private.ensure_profile_equipped_cosmetics(actor_id);

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
                where pcu.profile_id = actor_id
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
                where pcu.profile_id = actor_id
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

create or replace function public.equip_my_avatar(p_avatar_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_avatar_key, '')), '');
  selected_cosmetic public.cosmetic_catalog%rowtype;
  current_equipped public.profile_equipped_cosmetics%rowtype;
  updated_equipped public.profile_equipped_cosmetics%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  actor_guild_id := private.active_primary_guild_id(actor_id);

  if not private.is_approved(actor_id) or actor_guild_id is null then
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
       where pcu.profile_id = actor_id
         and pcu.cosmetic_key = selected_cosmetic.key
     ) then
    raise exception 'Avatar is locked.';
  end if;

  current_equipped := private.ensure_profile_equipped_cosmetics(actor_id);

  insert into public.profile_equipped_cosmetics (
    profile_id,
    avatar_key,
    frame_key,
    updated_at
  )
  values (
    actor_id,
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
  where id = actor_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    actor_guild_id,
    'cosmetic_avatar_equipped',
    'profile_equipped_cosmetics',
    actor_id,
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

create or replace function public.update_my_profile(
  p_ign text,
  p_avatar_key text default null
)
returns public.profiles
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_avatar_key text := nullif(btrim(coalesce(p_avatar_key, '')), '');
  updated_profile public.profiles%rowtype;
  current_equipped public.profile_equipped_cosmetics%rowtype;
  selected_avatar public.cosmetic_catalog%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  if normalized_avatar_key is not null then
    select * into selected_avatar
    from public.cosmetic_catalog c
    where c.key = normalized_avatar_key
      and c.type = 'avatar'
      and c.is_active = true;

    if not found then
      raise exception 'Invalid avatar.';
    end if;

    if selected_avatar.unlock_type <> 'free'
       and not exists (
         select 1
         from public.profile_cosmetic_unlocks pcu
         where pcu.profile_id = actor_id
           and pcu.cosmetic_key = selected_avatar.key
       ) then
      raise exception 'Avatar is locked.';
    end if;
  end if;

  update public.profiles
  set
    ign = btrim(p_ign),
    avatar_key = normalized_avatar_key,
    updated_at = now()
  where id = actor_id
  returning * into updated_profile;

  if not found then
    raise exception 'Profile not found.';
  end if;

  if normalized_avatar_key is not null then
    current_equipped := private.ensure_profile_equipped_cosmetics(actor_id);

    insert into public.profile_equipped_cosmetics (
      profile_id,
      avatar_key,
      frame_key,
      updated_at
    )
    values (
      actor_id,
      normalized_avatar_key,
      current_equipped.frame_key,
      now()
    )
    on conflict (profile_id) do update
    set
      avatar_key = excluded.avatar_key,
      updated_at = excluded.updated_at;
  end if;

  return updated_profile;
end;
$$;

create or replace function public.admin_grant_cosmetic_by_slug(
  p_profile_slug text,
  p_cosmetic_key text,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  normalized_slug text := private.normalize_profile_slug(p_profile_slug);
  target_profile public.profiles%rowtype;
  grant_payload jsonb;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_valid_profile_slug(normalized_slug) then
    raise exception 'Invalid profile slug.';
  end if;

  select * into target_profile
  from public.profiles p
  where p.profile_slug = normalized_slug
     or p.username = normalized_slug
  limit 1;

  if not found then
    raise exception 'Target profile not found.';
  end if;

  grant_payload := public.admin_grant_cosmetic(
    target_profile.id,
    p_cosmetic_key,
    p_reason
  );

  return jsonb_build_object(
    'target_profile_id', target_profile.id,
    'username', target_profile.username,
    'profile_slug', target_profile.profile_slug,
    'cosmetic_key', grant_payload ->> 'cosmetic_key',
    'cosmetic_type', grant_payload ->> 'cosmetic_type',
    'unlocked_at', grant_payload ->> 'unlocked_at'
  );
end;
$$;

revoke all on function public.admin_grant_cosmetic_by_slug(text, text, text)
  from public, anon;

grant execute on function public.admin_grant_cosmetic_by_slug(text, text, text)
  to authenticated;
