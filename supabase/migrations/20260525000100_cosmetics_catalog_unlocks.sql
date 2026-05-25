-- Anteiku Guild Manager - Cosmetics catalog, unlocks, and equip RPCs
-- Safe migration: adds preset avatar/frame metadata and RPC-only equip/grant
-- flows. No uploads, arbitrary URLs, or storage buckets are introduced.

create table if not exists public.cosmetic_catalog (
  key text primary key,
  type text not null,
  label_key text not null,
  asset_path text not null,
  rarity text not null default 'common',
  unlock_type text not null default 'free',
  is_active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cosmetic_catalog_key_format_chk check (
    key ~ '^[A-Za-z0-9](?:[A-Za-z0-9_]{1,62}[A-Za-z0-9])$'
  ),
  constraint cosmetic_catalog_type_chk check (type in ('avatar', 'frame')),
  constraint cosmetic_catalog_label_key_chk check (
    label_key ~ '^cosmetics\.(avatar|frame)\.[A-Za-z0-9_.]+$'
  ),
  constraint cosmetic_catalog_asset_path_chk check (
    (
      type = 'avatar'
      and asset_path ~ '^/cosmetics/avatars/[A-Za-z0-9_-]+\.(png|webp)$'
    )
    or (
      type = 'frame'
      and asset_path ~ '^/cosmetics/frames/[A-Za-z0-9_-]+\.(png|webp)$'
    )
  ),
  constraint cosmetic_catalog_rarity_chk check (
    rarity in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'special')
  ),
  constraint cosmetic_catalog_unlock_type_chk check (
    unlock_type in ('free', 'manual', 'admin_grant', 'rank', 'event', 'gvg', 'founder')
  ),
  constraint cosmetic_catalog_free_suffix_unlock_chk check (
    key !~ '_FREE$'
    or unlock_type = 'free'
  )
);

create table if not exists public.profile_cosmetic_unlocks (
  profile_id uuid not null references public.profiles(id) on delete cascade,
  cosmetic_key text not null references public.cosmetic_catalog(key) on delete restrict,
  unlocked_at timestamptz not null default now(),
  unlocked_by uuid references public.profiles(id) on delete set null,
  reason text,
  primary key (profile_id, cosmetic_key),
  constraint profile_cosmetic_unlocks_reason_length_chk check (
    reason is null
    or char_length(reason) <= 1000
  )
);

create table if not exists public.profile_equipped_cosmetics (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  avatar_key text not null references public.cosmetic_catalog(key) on delete restrict,
  frame_key text not null references public.cosmetic_catalog(key) on delete restrict,
  updated_at timestamptz not null default now()
);

create index if not exists cosmetic_catalog_type_active_sort_idx
  on public.cosmetic_catalog (type, is_active, sort_order, key);

create index if not exists profile_cosmetic_unlocks_cosmetic_key_idx
  on public.profile_cosmetic_unlocks (cosmetic_key);

create index if not exists profile_equipped_cosmetics_avatar_key_idx
  on public.profile_equipped_cosmetics (avatar_key);

create index if not exists profile_equipped_cosmetics_frame_key_idx
  on public.profile_equipped_cosmetics (frame_key);

drop trigger if exists set_cosmetic_catalog_updated_at on public.cosmetic_catalog;
create trigger set_cosmetic_catalog_updated_at
before update on public.cosmetic_catalog
for each row
execute function public.set_updated_at();

drop trigger if exists set_profile_equipped_cosmetics_updated_at on public.profile_equipped_cosmetics;
create trigger set_profile_equipped_cosmetics_updated_at
before update on public.profile_equipped_cosmetics
for each row
execute function public.set_updated_at();

with seeded_cosmetics as (
  select
    replace(file_name, '.png', '') as key,
    'avatar'::text as type,
    format('cosmetics.avatar.%s', replace(file_name, '.png', '')) as label_key,
    format('/cosmetics/avatars/%s', file_name) as asset_path,
    'common'::text as rarity,
    'free'::text as unlock_type,
    true as is_active,
    sort_order
  from (
    values
      ('1079_head.png', 10),
      ('1001_head.png', 20),
      ('1002_head.png', 30),
      ('1003_head.png', 40),
      ('1004_head.png', 50),
      ('1005_head.png', 60),
      ('1006_head.png', 70),
      ('1007_head.png', 80),
      ('1008_head.png', 90),
      ('1009_head.png', 100),
      ('1010_head.png', 110),
      ('1011_head.png', 120),
      ('1012_head.png', 130),
      ('1013_head.png', 140),
      ('1014_head.png', 150),
      ('1015_head.png', 160),
      ('1016_head.png', 170),
      ('1017_head.png', 180),
      ('1018_head.png', 190),
      ('1019_head.png', 200),
      ('1020_head.png', 210),
      ('1021_head.png', 220),
      ('1023_head.png', 230),
      ('1024_head.png', 240),
      ('1025_head.png', 250),
      ('1027_head.png', 260),
      ('1030_head.png', 270),
      ('1031_head.png', 280),
      ('1036_head.png', 290),
      ('1037_head.png', 300),
      ('1055_head.png', 310),
      ('1073_head.png', 320),
      ('1074_head.png', 330),
      ('1075_head.png', 340),
      ('1076_head.png', 350),
      ('1077_head.png', 360),
      ('1078_head.png', 370),
      ('1080_head.png', 380),
      ('1081_head.png', 390),
      ('1083_head.png', 400),
      ('1084_head.png', 410),
      ('1087_head.png', 420),
      ('1088_head.png', 430),
      ('1145_head.png', 440),
      ('1146_head.png', 450),
      ('1147_head.png', 460),
      ('1148_head.png', 470),
      ('1149_head.png', 480),
      ('1158_head.png', 490),
      ('1160_head.png', 500),
      ('1161_head.png', 510),
      ('1164_head.png', 520),
      ('1165_head.png', 530),
      ('1168_head.png', 540)
  ) as avatar_files(file_name, sort_order)

  union all

  select
    replace(file_name, '.png', '') as key,
    'frame'::text as type,
    format('cosmetics.frame.%s', replace(file_name, '.png', '')) as label_key,
    format('/cosmetics/frames/%s', file_name) as asset_path,
    rarity,
    unlock_type,
    true as is_active,
    sort_order
  from (
    values
      ('TXK_frame_reOpen_EN_FREE.png', 'common'::text, 'free'::text, 10),
      ('TXK_C1121_lock_FREE.png', 'common'::text, 'free'::text, 20),
      ('TXK_C1164_lock_FREE.png', 'common'::text, 'free'::text, 30),
      ('TXK_C1168_lock_FREE.png', 'common'::text, 'free'::text, 40),
      ('TXK_C1001_lock.png', 'rare'::text, 'manual'::text, 100),
      ('TXK_C1007_lock.png', 'rare'::text, 'manual'::text, 110),
      ('TXK_C1135_lock.png', 'rare'::text, 'manual'::text, 120),
      ('TXK_C1138_lock.png', 'rare'::text, 'manual'::text, 130),
      ('TXK_C1147_lock.png', 'rare'::text, 'manual'::text, 140),
      ('TXK_C1160_lock.png', 'rare'::text, 'manual'::text, 150)
  ) as frame_files(file_name, rarity, unlock_type, sort_order)
)
insert into public.cosmetic_catalog (
  key,
  type,
  label_key,
  asset_path,
  rarity,
  unlock_type,
  is_active,
  sort_order
)
select
  key,
  type,
  label_key,
  asset_path,
  rarity,
  unlock_type,
  is_active,
  sort_order
from seeded_cosmetics
on conflict (key) do update
set
  type = excluded.type,
  label_key = excluded.label_key,
  asset_path = excluded.asset_path,
  rarity = excluded.rarity,
  unlock_type = excluded.unlock_type,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  updated_at = now();

update public.profiles p
set
  avatar_key = null,
  updated_at = now()
where p.avatar_key is not null
  and not exists (
    select 1
    from public.cosmetic_catalog c
    where c.key = p.avatar_key
      and c.type = 'avatar'
      and c.is_active = true
  );

alter table public.cosmetic_catalog enable row level security;
alter table public.profile_cosmetic_unlocks enable row level security;
alter table public.profile_equipped_cosmetics enable row level security;

drop policy if exists cosmetic_catalog_select_active_approved on public.cosmetic_catalog;
create policy cosmetic_catalog_select_active_approved
on public.cosmetic_catalog
for select
to authenticated
using (
  is_active = true
  and private.is_approved(auth.uid())
  and private.active_primary_guild_id(auth.uid()) is not null
);

drop policy if exists profile_cosmetic_unlocks_select_own on public.profile_cosmetic_unlocks;
create policy profile_cosmetic_unlocks_select_own
on public.profile_cosmetic_unlocks
for select
to authenticated
using (
  profile_id = auth.uid()
  and private.is_approved(auth.uid())
  and private.active_primary_guild_id(auth.uid()) is not null
);

drop policy if exists profile_equipped_cosmetics_select_own on public.profile_equipped_cosmetics;
create policy profile_equipped_cosmetics_select_own
on public.profile_equipped_cosmetics
for select
to authenticated
using (
  profile_id = auth.uid()
  and private.is_approved(auth.uid())
  and private.active_primary_guild_id(auth.uid()) is not null
);

revoke all on public.cosmetic_catalog from public, anon, authenticated;
revoke all on public.profile_cosmetic_unlocks from public, anon, authenticated;
revoke all on public.profile_equipped_cosmetics from public, anon, authenticated;

grant select on public.cosmetic_catalog to authenticated;
grant select on public.profile_cosmetic_unlocks to authenticated;
grant select on public.profile_equipped_cosmetics to authenticated;

create or replace function private.ensure_profile_equipped_cosmetics(p_profile_id uuid)
returns public.profile_equipped_cosmetics
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  equipped public.profile_equipped_cosmetics%rowtype;
begin
  insert into public.profile_equipped_cosmetics (
    profile_id,
    avatar_key,
    frame_key
  )
  values (
    p_profile_id,
    '1079_head',
    'TXK_frame_reOpen_EN_FREE'
  )
  on conflict (profile_id) do nothing;

  select * into equipped
  from public.profile_equipped_cosmetics pec
  where pec.profile_id = p_profile_id;

  if not found then
    raise exception 'Cosmetic equipment not found.';
  end if;

  return equipped;
end;
$$;

revoke all on function private.ensure_profile_equipped_cosmetics(uuid)
  from public, anon, authenticated;

create or replace function public.get_available_avatars()
returns table (
  key text,
  label_key text,
  asset_path text,
  rarity text,
  sort_order integer
)
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

  if not private.is_approved(actor_id)
     or private.active_primary_guild_id(actor_id) is null then
    raise exception 'Approved active membership required.';
  end if;

  return query
  select
    c.key,
    c.label_key,
    c.asset_path,
    c.rarity,
    c.sort_order
  from public.cosmetic_catalog c
  where c.type = 'avatar'
    and c.is_active = true
  order by c.sort_order, c.key;
end;
$$;

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
            'is_unlocked', true,
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

create or replace function public.equip_my_frame(p_frame_key text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := auth.uid();
  actor_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_frame_key, '')), '');
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
       where pcu.profile_id = actor_id
         and pcu.cosmetic_key = selected_cosmetic.key
     ) then
    raise exception 'Frame is locked.';
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
    actor_id,
    actor_id,
    actor_guild_id,
    'cosmetic_frame_equipped',
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

create or replace function public.admin_grant_cosmetic(
  p_profile_id uuid,
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
  target_guild_id uuid;
  normalized_key text := nullif(btrim(coalesce(p_cosmetic_key, '')), '');
  normalized_reason text := nullif(btrim(coalesce(p_reason, '')), '');
  selected_cosmetic public.cosmetic_catalog%rowtype;
  target_unlock public.profile_cosmetic_unlocks%rowtype;
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if not private.is_approved(actor_id) then
    raise exception 'Approved profile required.';
  end if;

  if p_profile_id is null then
    raise exception 'Target profile is required.';
  end if;

  target_guild_id := private.active_primary_guild_id(p_profile_id);

  if target_guild_id is null then
    raise exception 'Target approved active membership required.';
  end if;

  if normalized_key is null then
    raise exception 'Cosmetic key is required.';
  end if;

  select * into selected_cosmetic
  from public.cosmetic_catalog c
  where c.key = normalized_key
    and c.is_active = true;

  if not found then
    raise exception 'Invalid cosmetic.';
  end if;

  if normalized_reason is not null and char_length(normalized_reason) > 1000 then
    raise exception 'Cosmetic grant reason is too long.';
  end if;

  if not private.can_manage_members(actor_id, target_guild_id) then
    raise exception 'Not authorized to grant cosmetics for this member.';
  end if;

  insert into public.profile_cosmetic_unlocks (
    profile_id,
    cosmetic_key,
    unlocked_by,
    reason
  )
  values (
    p_profile_id,
    selected_cosmetic.key,
    actor_id,
    normalized_reason
  )
  on conflict (profile_id, cosmetic_key) do update
  set
    unlocked_by = excluded.unlocked_by,
    reason = excluded.reason
  returning * into target_unlock;

  perform private.write_audit_log(
    actor_id,
    p_profile_id,
    target_guild_id,
    'cosmetic_granted',
    'profile_cosmetic_unlocks',
    p_profile_id,
    jsonb_build_object(
      'cosmetic_key', selected_cosmetic.key,
      'cosmetic_type', selected_cosmetic.type,
      'reason_provided', normalized_reason is not null
    )
  );

  return jsonb_build_object(
    'profile_id', target_unlock.profile_id,
    'cosmetic_key', target_unlock.cosmetic_key,
    'cosmetic_type', selected_cosmetic.type,
    'unlocked_at', target_unlock.unlocked_at
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
begin
  if actor_id is null then
    raise exception 'Authentication required.';
  end if;

  if p_ign is null or btrim(p_ign) = '' then
    raise exception 'IGN is required.';
  end if;

  if normalized_avatar_key is not null
     and not exists (
       select 1
       from public.cosmetic_catalog c
       where c.key = normalized_avatar_key
         and c.type = 'avatar'
         and c.is_active = true
     ) then
    raise exception 'Invalid avatar.';
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

revoke all on function public.get_available_avatars() from public, anon;
revoke all on function public.get_my_cosmetics() from public, anon;
revoke all on function public.equip_my_avatar(text) from public, anon;
revoke all on function public.equip_my_frame(text) from public, anon;
revoke all on function public.admin_grant_cosmetic(uuid, text, text) from public, anon;
revoke all on function public.update_my_profile(text, text) from public, anon;

grant execute on function public.get_available_avatars() to authenticated;
grant execute on function public.get_my_cosmetics() to authenticated;
grant execute on function public.equip_my_avatar(text) to authenticated;
grant execute on function public.equip_my_frame(text) to authenticated;
grant execute on function public.admin_grant_cosmetic(uuid, text, text) to authenticated;
grant execute on function public.update_my_profile(text, text) to authenticated;
