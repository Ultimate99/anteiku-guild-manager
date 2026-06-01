-- Milestone 30B: TCG/Card Collection catalog + inventory backend foundation.
-- Backend/RPC only. No pack opening, shop, economy, UI, or normal CP usage.

create table if not exists public.tcg_sets (
  id uuid primary key default gen_random_uuid(),
  set_key text not null unique,
  name text not null,
  description text,
  release_status text not null default 'active'
    check (release_status in ('draft', 'active', 'retired')),
  sort_order integer not null default 0,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_sets_set_key_format_chk
    check (set_key ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$')
);

create table if not exists public.tcg_rarities (
  id uuid primary key default gen_random_uuid(),
  rarity_key text not null unique,
  name text not null,
  sort_order integer not null,
  display_tier integer not null,
  style_summary text,
  style_prompt_prefix text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_rarities_key_format_chk
    check (rarity_key ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$'),
  constraint tcg_rarities_sort_order_positive_chk
    check (sort_order > 0),
  constraint tcg_rarities_display_tier_positive_chk
    check (display_tier > 0)
);

create table if not exists public.tcg_cards (
  id uuid primary key default gen_random_uuid(),
  card_key text not null unique,
  card_no text not null,
  set_id uuid not null references public.tcg_sets(id) on delete restrict,
  rarity_id uuid not null references public.tcg_rarities(id) on delete restrict,
  name text not null,
  card_type text not null
    check (card_type in ('Character', 'Organization', 'Scene', 'Relic')),
  subject_or_character text,
  faction text,
  collector_value integer not null default 0 check (collector_value >= 0),
  short_description text,
  flavor_text text,
  art_prompt text,
  s1_validation_note text,
  art_path text,
  image_url text,
  thumbnail_url text,
  release_status text not null default 'active'
    check (release_status in ('draft', 'active', 'retired')),
  is_collectible boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_cards_key_format_chk
    check (card_key ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$'),
  constraint tcg_cards_card_no_format_chk
    check (card_no ~ '^S[0-9]+-[0-9]{3}$'),
  constraint tcg_cards_set_card_no_uidx unique (set_id, card_no),
  constraint tcg_cards_art_path_chk
    check (art_path is null or art_path ~ '^/assets/tcg/art/[a-zA-Z0-9_./-]+$')
);

create table if not exists public.tcg_player_inventory (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid not null references public.tcg_cards(id) on delete restrict,
  quantity integer not null default 0 check (quantity >= 0),
  first_acquired_at timestamptz,
  last_acquired_at timestamptz,
  is_favorite boolean not null default false,
  is_locked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_player_inventory_profile_card_uidx unique (profile_id, card_id),
  constraint tcg_player_inventory_acquired_consistency_chk
    check (
      (quantity = 0 and first_acquired_at is null and last_acquired_at is null)
      or (quantity > 0 and first_acquired_at is not null and last_acquired_at is not null)
    )
);

create table if not exists public.tcg_inventory_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  card_id uuid references public.tcg_cards(id) on delete restrict,
  quantity_delta integer not null check (quantity_delta <> 0),
  event_type text not null check (event_type in ('admin_grant')),
  source_type text not null check (source_type in ('admin_tool')),
  source_id uuid,
  actor_user_id uuid,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists tcg_sets_release_status_sort_idx
  on public.tcg_sets (release_status, sort_order, set_key);

create index if not exists tcg_rarities_sort_idx
  on public.tcg_rarities (sort_order, rarity_key);

create index if not exists tcg_cards_set_sort_idx
  on public.tcg_cards (set_id, sort_order, card_no);

create index if not exists tcg_cards_rarity_idx
  on public.tcg_cards (rarity_id, sort_order);

create index if not exists tcg_cards_release_collectible_idx
  on public.tcg_cards (release_status, is_collectible, sort_order);

create index if not exists tcg_inventory_profile_idx
  on public.tcg_player_inventory (profile_id, updated_at desc);

create index if not exists tcg_inventory_card_idx
  on public.tcg_player_inventory (card_id, quantity);

create index if not exists tcg_inventory_events_profile_idx
  on public.tcg_inventory_events (profile_id, created_at desc);

create index if not exists tcg_inventory_events_card_idx
  on public.tcg_inventory_events (card_id, created_at desc);

create index if not exists tcg_inventory_events_actor_idx
  on public.tcg_inventory_events (actor_profile_id, created_at desc);

drop trigger if exists set_tcg_sets_updated_at on public.tcg_sets;
create trigger set_tcg_sets_updated_at
before update on public.tcg_sets
for each row
execute function public.set_updated_at();

drop trigger if exists set_tcg_rarities_updated_at on public.tcg_rarities;
create trigger set_tcg_rarities_updated_at
before update on public.tcg_rarities
for each row
execute function public.set_updated_at();

drop trigger if exists set_tcg_cards_updated_at on public.tcg_cards;
create trigger set_tcg_cards_updated_at
before update on public.tcg_cards
for each row
execute function public.set_updated_at();

drop trigger if exists set_tcg_player_inventory_updated_at on public.tcg_player_inventory;
create trigger set_tcg_player_inventory_updated_at
before update on public.tcg_player_inventory
for each row
execute function public.set_updated_at();

alter table public.tcg_sets enable row level security;
alter table public.tcg_rarities enable row level security;
alter table public.tcg_cards enable row level security;
alter table public.tcg_player_inventory enable row level security;
alter table public.tcg_inventory_events enable row level security;

revoke all on public.tcg_sets from public, anon, authenticated;
revoke all on public.tcg_rarities from public, anon, authenticated;
revoke all on public.tcg_cards from public, anon, authenticated;
revoke all on public.tcg_player_inventory from public, anon, authenticated;
revoke all on public.tcg_inventory_events from public, anon, authenticated;

insert into public.tcg_sets (
  set_key,
  name,
  description,
  release_status,
  sort_order
)
values (
  'season_0_anteiku_origins',
  'Season 0: Anteiku Origins',
  'Canonical Catalog v0.1. Inner artwork only; app-rendered frames, names, rarities, counts, and collector display values.',
  'active',
  0
)
on conflict (set_key) do update
set name = excluded.name,
    description = excluded.description,
    release_status = excluded.release_status,
    sort_order = excluded.sort_order,
    updated_at = now();

insert into public.tcg_rarities (
  rarity_key,
  name,
  sort_order,
  display_tier,
  style_summary,
  style_prompt_prefix
)
values
  ('common', 'Common', 1, 1, 'Matte black/charcoal; thin smoke-gray border; tiny crimson scratch accent; no glow; gritty street-level feeling.', 'Matte black and charcoal mood, smoke-gray restraint, tiny crimson scratch accent, gritty street-level feeling.'),
  ('uncommon', 'Uncommon', 2, 2, 'Dark gunmetal frame; double-line border; muted crimson side slashes; faint red rim light; grounded but sharper than Common.', 'Dark gunmetal mood, muted crimson side slashes, faint red rim light, grounded but sharper than common.'),
  ('rare', 'Rare', 3, 3, 'Black lacquer frame; polished crimson bevel; broken-glass corner accents; small rarity gem; subtle kagune-like vein frame pattern.', 'Black lacquer mood, polished crimson bevel energy, broken-glass corner accents, subtle kagune-like veins.'),
  ('epic', 'Epic', 4, 4, 'Obsidian shard frame; thick crimson cracked-glass glow; smoke/rain overlay; larger cinematic art window; intense red highlights.', 'Obsidian shard mood, thick crimson cracked-glass glow, smoke and rain, cinematic red highlights.'),
  ('legendary', 'Legendary', 5, 5, 'Ceremonial black steel frame; crimson enamel inlays; symmetrical crest slots; dark silver edge highlights; controlled crimson aura.', 'Ceremonial black steel mood, crimson enamel inlays, dark silver highlights, controlled crimson aura.'),
  ('mythic', 'Mythic', 6, 6, 'Black void frame; crimson eclipse ring; asymmetric organic kagune-like border; red particle glow; blood-moon atmosphere; unique Season 0 seal.', 'Black void mood, crimson eclipse ring, organic kagune-like edge, red particle glow, blood-moon atmosphere.')
on conflict (rarity_key) do update
set name = excluded.name,
    sort_order = excluded.sort_order,
    display_tier = excluded.display_tier,
    style_summary = excluded.style_summary,
    style_prompt_prefix = excluded.style_prompt_prefix,
    updated_at = now();

with season_zero as (
  select id
  from public.tcg_sets
  where set_key = 'season_0_anteiku_origins'
),
catalog_input (
  card_no,
  card_key,
  card_name,
  rarity_key,
  card_type,
  faction,
  collector_value,
  art_path,
  sort_order
) as (
  values
    ('S0-001', 's0_001_20th_ward_civilian', '20th Ward Civilian', 'common', 'Character', '20th Ward', 10, '/assets/tcg/art/s0_001_20th_ward_civilian.png', 1),
    ('S0-002', 's0_002_anteiku_regular_customer', 'Anteiku Regular Customer', 'common', 'Character', 'Anteiku', 10, '/assets/tcg/art/s0_002_anteiku_regular_customer.png', 2),
    ('S0-003', 's0_003_rainy_alley', 'Rainy Alley', 'common', 'Scene', '20th Ward', 10, '/assets/tcg/art/s0_003_rainy_alley.png', 3),
    ('S0-004', 's0_004_black_coffee', 'Black Coffee', 'common', 'Relic', 'Anteiku', 10, '/assets/tcg/art/s0_004_black_coffee.png', 4),
    ('S0-005', 's0_005_broken_mask_fragment', 'Broken Mask Fragment', 'common', 'Relic', 'Neutral', 10, '/assets/tcg/art/s0_005_broken_mask_fragment.png', 5),
    ('S0-006', 's0_006_ccg_patrol', 'CCG Patrol', 'common', 'Scene', 'CCG', 10, '/assets/tcg/art/s0_006_ccg_patrol.png', 6),
    ('S0-007', 's0_007_ward_backstreet', 'Ward Backstreet', 'common', 'Scene', '20th Ward', 10, '/assets/tcg/art/s0_007_ward_backstreet.png', 7),
    ('S0-008', 's0_008_anteiku_apron', 'Anteiku Apron', 'common', 'Relic', 'Anteiku', 10, '/assets/tcg/art/s0_008_anteiku_apron.png', 8),
    ('S0-009', 's0_009_quiet_barista', 'Quiet Barista', 'common', 'Character', 'Anteiku', 10, '/assets/tcg/art/s0_009_quiet_barista.png', 9),
    ('S0-010', 's0_010_night_train_platform', 'Night Train Platform', 'common', 'Scene', 'Tokyo', 10, '/assets/tcg/art/s0_010_night_train_platform.png', 10),
    ('S0-011', 's0_011_ghoul_graffiti', 'Ghoul Graffiti', 'common', 'Scene', 'Neutral', 10, '/assets/tcg/art/s0_011_ghoul_graffiti.png', 11),
    ('S0-012', 's0_012_red_umbrella', 'Red Umbrella', 'common', 'Relic', 'Tokyo', 10, '/assets/tcg/art/s0_012_red_umbrella.png', 12),
    ('S0-013', 's0_013_anxious_student', 'Anxious Student', 'common', 'Character', '20th Ward', 10, '/assets/tcg/art/s0_013_anxious_student.png', 13),
    ('S0-014', 's0_014_cafe_after_hours', 'Cafe After Hours', 'common', 'Scene', 'Anteiku', 10, '/assets/tcg/art/s0_014_cafe_after_hours.png', 14),
    ('S0-015', 's0_015_ccg_case_file', 'CCG Case File', 'common', 'Relic', 'CCG', 10, '/assets/tcg/art/s0_015_ccg_case_file.png', 15),
    ('S0-016', 's0_016_smoke_over_rooftops', 'Smoke Over Rooftops', 'common', 'Scene', 'Tokyo', 10, '/assets/tcg/art/s0_016_smoke_over_rooftops.png', 16),
    ('S0-017', 's0_017_mask_shop_curtain', 'Mask Shop Curtain', 'common', 'Scene', 'Neutral', 10, '/assets/tcg/art/s0_017_mask_shop_curtain.png', 17),
    ('S0-018', 's0_018_old_coffee_grinder', 'Old Coffee Grinder', 'common', 'Relic', 'Anteiku', 10, '/assets/tcg/art/s0_018_old_coffee_grinder.png', 18),
    ('S0-019', 's0_019_anteiku_server', 'Anteiku Server', 'uncommon', 'Character', 'Anteiku', 25, '/assets/tcg/art/s0_019_anteiku_server.png', 19),
    ('S0-020', 's0_020_masked_runner', 'Masked Runner', 'uncommon', 'Character', 'Neutral', 25, '/assets/tcg/art/s0_020_masked_runner.png', 20),
    ('S0-021', 's0_021_ccg_investigator_rookie', 'CCG Investigator Rookie', 'uncommon', 'Character', 'CCG', 25, '/assets/tcg/art/s0_021_ccg_investigator_rookie.png', 21),
    ('S0-022', 's0_022_crimson_rain', 'Crimson Rain', 'uncommon', 'Scene', 'Tokyo', 25, '/assets/tcg/art/s0_022_crimson_rain.png', 22),
    ('S0-023', 's0_023_ghoul_restaurant_invite', 'Ghoul Restaurant Invite', 'uncommon', 'Relic', 'Ghoul Restaurant', 25, '/assets/tcg/art/s0_023_ghoul_restaurant_invite.png', 23),
    ('S0-024', 's0_024_aogiri_shadow', 'Aogiri Shadow', 'uncommon', 'Character', 'Aogiri', 25, '/assets/tcg/art/s0_024_aogiri_shadow.png', 24),
    ('S0-025', 's0_025_kagune_scar', 'Kagune Scar', 'uncommon', 'Relic', 'Neutral', 25, '/assets/tcg/art/s0_025_kagune_scar.png', 25),
    ('S0-026', 's0_026_anteiku_back_room', 'Anteiku Back Room', 'uncommon', 'Scene', 'Anteiku', 25, '/assets/tcg/art/s0_026_anteiku_back_room.png', 26),
    ('S0-027', 's0_027_white_coat_researcher', 'White Coat Researcher', 'uncommon', 'Character', 'CCG', 25, '/assets/tcg/art/s0_027_white_coat_researcher.png', 27),
    ('S0-028', 's0_028_hunters_flashlight', 'Hunter''s Flashlight', 'uncommon', 'Relic', 'CCG', 25, '/assets/tcg/art/s0_028_hunters_flashlight.png', 28),
    ('S0-029', 's0_029_rooftop_watcher', 'Rooftop Watcher', 'uncommon', 'Character', 'Neutral', 25, '/assets/tcg/art/s0_029_rooftop_watcher.png', 29),
    ('S0-030', 's0_030_cafe_lantern_glow', 'Cafe Lantern Glow', 'uncommon', 'Scene', 'Anteiku', 25, '/assets/tcg/art/s0_030_cafe_lantern_glow.png', 30),
    ('S0-031', 's0_031_bloodied_bandage', 'Bloodied Bandage', 'uncommon', 'Relic', 'Neutral', 25, '/assets/tcg/art/s0_031_bloodied_bandage.png', 31),
    ('S0-032', 's0_032_hidden_safehouse', 'Hidden Safehouse', 'uncommon', 'Scene', 'Neutral', 25, '/assets/tcg/art/s0_032_hidden_safehouse.png', 32),
    ('S0-033', 's0_033_young_one_eyed_ghoul', 'Young One-Eyed Ghoul', 'rare', 'Character', 'Anteiku', 80, '/assets/tcg/art/s0_033_young_one_eyed_ghoul.png', 33),
    ('S0-034', 's0_034_rabbit_mask_girl', 'Rabbit Mask Girl', 'rare', 'Character', 'Anteiku', 80, '/assets/tcg/art/s0_034_rabbit_mask_girl.png', 34),
    ('S0-035', 's0_035_gentle_manager', 'Gentle Manager', 'rare', 'Character', 'Anteiku', 80, '/assets/tcg/art/s0_035_gentle_manager.png', 35),
    ('S0-036', 's0_036_quiet_anteiku_enforcer', 'Quiet Anteiku Enforcer', 'rare', 'Character', 'Anteiku', 80, '/assets/tcg/art/s0_036_quiet_anteiku_enforcer.png', 36),
    ('S0-037', 's0_037_dove_with_quinque', 'Dove With Quinque', 'rare', 'Character', 'CCG', 80, '/assets/tcg/art/s0_037_dove_with_quinque.png', 37),
    ('S0-038', 's0_038_glutton_in_the_rain', 'Glutton in the Rain', 'rare', 'Character', 'Neutral', 80, '/assets/tcg/art/s0_038_glutton_in_the_rain.png', 38),
    ('S0-039', 's0_039_gourmet_stage', 'Gourmet Stage', 'rare', 'Scene', 'Ghoul Restaurant', 80, '/assets/tcg/art/s0_039_gourmet_stage.png', 39),
    ('S0-040', 's0_040_mask_maker', 'Mask Maker', 'rare', 'Character', 'Neutral', 80, '/assets/tcg/art/s0_040_mask_maker.png', 40),
    ('S0-041', 's0_041_aogiri_raid_signal', 'Aogiri Raid Signal', 'rare', 'Scene', 'Aogiri', 80, '/assets/tcg/art/s0_041_aogiri_raid_signal.png', 41),
    ('S0-042', 's0_042_half_mask_awakening', 'Half-Mask Awakening', 'epic', 'Character', 'Anteiku', 250, '/assets/tcg/art/s0_042_half_mask_awakening.png', 42),
    ('S0-043', 's0_043_crimson_wing_strike', 'Crimson Wing Strike', 'epic', 'Character', 'Anteiku', 250, '/assets/tcg/art/s0_043_crimson_wing_strike.png', 43),
    ('S0-044', 's0_044_owl_shadow', 'Owl Shadow', 'epic', 'Character', 'Anteiku', 250, '/assets/tcg/art/s0_044_owl_shadow.png', 44),
    ('S0-045', 's0_045_white_reaper_case', 'White Reaper Case', 'epic', 'Character', 'CCG', 250, '/assets/tcg/art/s0_045_white_reaper_case.png', 45),
    ('S0-046', 's0_046_aogiri_executioner', 'Aogiri Executioner', 'epic', 'Character', 'Aogiri', 250, '/assets/tcg/art/s0_046_aogiri_executioner.png', 46),
    ('S0-047', 's0_047_anteiku_last_light', 'Anteiku Last Light', 'legendary', 'Scene', 'Anteiku', 750, '/assets/tcg/art/s0_047_anteiku_last_light.png', 47),
    ('S0-048', 's0_048_centipede_unleashed', 'Centipede Unleashed', 'legendary', 'Character', 'Neutral', 750, '/assets/tcg/art/s0_048_centipede_unleashed.png', 48),
    ('S0-049', 's0_049_owl_of_the_ward', 'Owl of the Ward', 'legendary', 'Character', 'Anteiku', 750, '/assets/tcg/art/s0_049_owl_of_the_ward.png', 49),
    ('S0-050', 's0_050_anteiku_origin', 'Anteiku Origin', 'mythic', 'Scene', 'Anteiku', 2500, '/assets/tcg/art/s0_050_anteiku_origin.png', 50)
)
insert into public.tcg_cards (
  card_key,
  card_no,
  set_id,
  rarity_id,
  name,
  card_type,
  subject_or_character,
  faction,
  collector_value,
  art_path,
  image_url,
  thumbnail_url,
  release_status,
  is_collectible,
  sort_order
)
select
  ci.card_key,
  ci.card_no,
  sz.id,
  r.id,
  ci.card_name,
  ci.card_type,
  ci.card_name,
  ci.faction,
  ci.collector_value,
  ci.art_path,
  null,
  null,
  'active',
  true,
  ci.sort_order
from catalog_input ci
cross join season_zero sz
join public.tcg_rarities r on r.rarity_key = ci.rarity_key
on conflict (card_key) do update
set card_no = excluded.card_no,
    set_id = excluded.set_id,
    rarity_id = excluded.rarity_id,
    name = excluded.name,
    card_type = excluded.card_type,
    subject_or_character = excluded.subject_or_character,
    faction = excluded.faction,
    collector_value = excluded.collector_value,
    art_path = excluded.art_path,
    image_url = excluded.image_url,
    thumbnail_url = excluded.thumbnail_url,
    release_status = excluded.release_status,
    is_collectible = excluded.is_collectible,
    sort_order = excluded.sort_order,
    updated_at = now();

create or replace function private.tcg_active_member_profile_id()
returns uuid
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  active_profile_id uuid;
  actor_membership record;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.';
  end if;

  active_profile_id := private.get_active_profile_id();

  if active_profile_id is null then
    raise exception 'Active profile is required.';
  end if;

  select
    p.approval_status,
    gm.membership_status,
    gm.roster_status
  into actor_membership
  from public.profiles p
  join public.guild_memberships gm
    on gm.profile_id = p.id
   and gm.is_primary = true
  where p.id = active_profile_id
  order by
    case gm.membership_status
      when 'active' then 1
      when 'pending' then 2
      when 'suspended' then 3
      when 'left' then 4
      else 5
    end,
    gm.created_at desc
  limit 1;

  if not found
     or actor_membership.approval_status <> 'approved'
     or actor_membership.membership_status <> 'active'
     or coalesce(actor_membership.roster_status, 'active') in ('suspended', 'left', 'kicked') then
    raise exception 'Approved active profile required.';
  end if;

  return active_profile_id;
end;
$$;

create or replace function public.tcg_get_catalog()
returns table (
  card_id uuid,
  set_key text,
  set_name text,
  card_no text,
  card_key text,
  card_name text,
  rarity_key text,
  rarity_name text,
  rarity_sort_order integer,
  rarity_display_tier integer,
  rarity_style_summary text,
  rarity_style_prompt_prefix text,
  card_type text,
  subject_or_character text,
  faction text,
  collector_value integer,
  art_path text,
  image_url text,
  thumbnail_url text,
  sort_order integer
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
begin
  return query
  select
    c.id,
    s.set_key,
    s.name,
    c.card_no,
    c.card_key,
    c.name,
    r.rarity_key,
    r.name,
    r.sort_order,
    r.display_tier,
    r.style_summary,
    r.style_prompt_prefix,
    c.card_type,
    c.subject_or_character,
    c.faction,
    c.collector_value,
    c.art_path,
    c.image_url,
    c.thumbnail_url,
    c.sort_order
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  join public.tcg_rarities r on r.id = c.rarity_id
  where s.release_status = 'active'
    and c.release_status = 'active'
    and c.is_collectible = true
    and actor_id is not null
  order by s.sort_order asc, c.sort_order asc, c.card_no asc;
end;
$$;

create or replace function public.tcg_get_my_collection()
returns table (
  card_id uuid,
  set_key text,
  set_name text,
  card_no text,
  card_key text,
  card_name text,
  rarity_key text,
  rarity_name text,
  rarity_sort_order integer,
  rarity_display_tier integer,
  rarity_style_summary text,
  rarity_style_prompt_prefix text,
  card_type text,
  subject_or_character text,
  faction text,
  collector_value integer,
  art_path text,
  image_url text,
  thumbnail_url text,
  sort_order integer,
  quantity integer,
  is_owned boolean,
  is_favorite boolean,
  is_locked boolean,
  first_acquired_at timestamptz,
  last_acquired_at timestamptz,
  inventory_updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
begin
  return query
  select
    c.id,
    s.set_key,
    s.name,
    c.card_no,
    c.card_key,
    c.name,
    r.rarity_key,
    r.name,
    r.sort_order,
    r.display_tier,
    r.style_summary,
    r.style_prompt_prefix,
    c.card_type,
    c.subject_or_character,
    c.faction,
    c.collector_value,
    c.art_path,
    c.image_url,
    c.thumbnail_url,
    c.sort_order,
    coalesce(inv.quantity, 0),
    coalesce(inv.quantity, 0) > 0,
    coalesce(inv.is_favorite, false),
    coalesce(inv.is_locked, false),
    inv.first_acquired_at,
    inv.last_acquired_at,
    inv.updated_at
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  join public.tcg_rarities r on r.id = c.rarity_id
  left join public.tcg_player_inventory inv
    on inv.card_id = c.id
   and inv.profile_id = actor_id
  where s.release_status = 'active'
    and c.release_status = 'active'
    and c.is_collectible = true
  order by s.sort_order asc, c.sort_order asc, c.card_no asc;
end;
$$;

create or replace function public.tcg_set_card_favorite(
  p_card_key text,
  p_is_favorite boolean
)
returns table (
  card_key text,
  is_favorite boolean,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  normalized_card_key text := lower(btrim(coalesce(p_card_key, '')));
  result_card_key text;
  result_is_favorite boolean;
  result_updated_at timestamptz;
begin
  if normalized_card_key = '' then
    raise exception 'Card key is required.';
  end if;

  update public.tcg_player_inventory inv
  set is_favorite = coalesce(p_is_favorite, false),
      updated_at = now()
  from public.tcg_cards c
  where inv.card_id = c.id
    and inv.profile_id = actor_id
    and inv.quantity > 0
    and c.card_key = normalized_card_key
    and c.release_status = 'active'
    and c.is_collectible = true
  returning c.card_key, inv.is_favorite, inv.updated_at
  into result_card_key, result_is_favorite, result_updated_at;

  if result_card_key is null then
    raise exception 'Owned card was not found.';
  end if;

  return query
  select result_card_key, result_is_favorite, result_updated_at;
end;
$$;

create or replace function public.tcg_admin_grant_card(
  p_target_profile_id uuid,
  p_card_key text,
  p_quantity integer,
  p_reason text default null
)
returns table (
  profile_id uuid,
  card_key text,
  quantity_added integer,
  new_quantity integer,
  event_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  actor_auth_id uuid := auth.uid();
  actor_is_owner boolean := private.is_owner(actor_id);
  normalized_card_key text := lower(btrim(coalesce(p_card_key, '')));
  target_membership record;
  target_card record;
  existing_inventory record;
  updated_inventory_id uuid;
  previous_quantity integer := 0;
  resulting_quantity integer;
  created_event_id uuid;
  cleaned_reason text := nullif(btrim(coalesce(p_reason, '')), '');
begin
  if p_target_profile_id is null then
    raise exception 'Target profile is required.';
  end if;

  if normalized_card_key = '' then
    raise exception 'Card key is required.';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100 then
    raise exception 'Grant quantity must be between 1 and 100.';
  end if;

  select
    p.id as profile_id,
    p.approval_status,
    gm.guild_id,
    gm.membership_status,
    gm.roster_status
  into target_membership
  from public.profiles p
  join public.guild_memberships gm
    on gm.profile_id = p.id
   and gm.is_primary = true
  where p.id = p_target_profile_id
  order by
    case gm.membership_status
      when 'active' then 1
      when 'pending' then 2
      when 'suspended' then 3
      when 'left' then 4
      else 5
    end,
    gm.created_at desc
  limit 1;

  if not found
     or target_membership.approval_status <> 'approved'
     or target_membership.membership_status <> 'active'
     or coalesce(target_membership.roster_status, 'active') in ('suspended', 'left', 'kicked') then
    raise exception 'Target profile is not eligible for TCG grants.';
  end if;

  if not actor_is_owner
     and not (
       private.has_role(actor_id, target_membership.guild_id, array['leader', 'vice'])
       or private.has_permission(actor_id, target_membership.guild_id, 'manage_members')
     ) then
    raise exception 'Not authorized to grant TCG cards for this profile.';
  end if;

  select
    c.id,
    c.card_key,
    c.name
  into target_card
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  where c.card_key = normalized_card_key
    and c.release_status = 'active'
    and c.is_collectible = true
    and s.release_status = 'active'
  limit 1;

  if not found then
    raise exception 'Active collectible card was not found.';
  end if;

  select inv.*
  into existing_inventory
  from public.tcg_player_inventory inv
  where inv.profile_id = p_target_profile_id
    and inv.card_id = target_card.id
  for update;

  if found then
    previous_quantity := existing_inventory.quantity;
    resulting_quantity := existing_inventory.quantity + p_quantity;

    update public.tcg_player_inventory
    set quantity = resulting_quantity,
        first_acquired_at = coalesce(first_acquired_at, now()),
        last_acquired_at = now(),
        updated_at = now()
    where id = existing_inventory.id
    returning id into updated_inventory_id;
  else
    resulting_quantity := p_quantity;

    insert into public.tcg_player_inventory (
      profile_id,
      card_id,
      quantity,
      first_acquired_at,
      last_acquired_at
    )
    values (
      p_target_profile_id,
      target_card.id,
      resulting_quantity,
      now(),
      now()
    )
    returning id into updated_inventory_id;
  end if;

  insert into public.tcg_inventory_events (
    profile_id,
    card_id,
    quantity_delta,
    event_type,
    source_type,
    source_id,
    actor_user_id,
    actor_profile_id,
    reason,
    metadata
  )
  values (
    p_target_profile_id,
    target_card.id,
    p_quantity,
    'admin_grant',
    'admin_tool',
    updated_inventory_id,
    actor_auth_id,
    actor_id,
    cleaned_reason,
    jsonb_build_object(
      'card_key', target_card.card_key,
      'card_name', target_card.name,
      'previous_quantity', previous_quantity,
      'new_quantity', resulting_quantity
    )
  )
  returning id into created_event_id;

  perform private.write_audit_log(
    actor_id,
    p_target_profile_id,
    target_membership.guild_id,
    'tcg_card_admin_granted',
    'tcg_player_inventory',
    updated_inventory_id,
    jsonb_build_object(
      'card_key', target_card.card_key,
      'quantity_delta', p_quantity,
      'previous_quantity', previous_quantity,
      'new_quantity', resulting_quantity,
      'reason_present', cleaned_reason is not null
    )
  );

  return query
  select p_target_profile_id, target_card.card_key, p_quantity, resulting_quantity, created_event_id;
end;
$$;

revoke all on function private.tcg_active_member_profile_id() from public, anon, authenticated;

revoke all on function public.tcg_get_catalog() from public, anon;
revoke all on function public.tcg_get_my_collection() from public, anon;
revoke all on function public.tcg_set_card_favorite(text, boolean) from public, anon;
revoke all on function public.tcg_admin_grant_card(uuid, text, integer, text) from public, anon;

grant execute on function public.tcg_get_catalog() to authenticated;
grant execute on function public.tcg_get_my_collection() to authenticated;
grant execute on function public.tcg_set_card_favorite(text, boolean) to authenticated;
grant execute on function public.tcg_admin_grant_card(uuid, text, integer, text) to authenticated;
