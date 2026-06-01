-- Milestone 30D-A: Owner-only TCG pack backend/RPC foundation.
-- Backend/RPC only. No frontend pack UI, shop, economy, payments, or normal CP usage.

create table if not exists public.tcg_packs (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  set_id uuid not null references public.tcg_sets(id) on delete restrict,
  cards_per_pack integer not null check (cards_per_pack > 0 and cards_per_pack <= 20),
  is_active boolean not null default true,
  is_owner_test_only boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_packs_code_format_chk
    check (code ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$')
);

create table if not exists public.tcg_pack_drop_rates (
  id uuid primary key default gen_random_uuid(),
  pack_id uuid not null references public.tcg_packs(id) on delete cascade,
  rarity_code text not null references public.tcg_rarities(rarity_key) on update cascade on delete restrict,
  weight integer not null check (weight > 0),
  guaranteed_count integer not null default 0 check (guaranteed_count >= 0),
  created_at timestamptz not null default now(),
  constraint tcg_pack_drop_rates_pack_rarity_uidx unique (pack_id, rarity_code)
);

create table if not exists public.tcg_pack_openings (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  pack_id uuid not null references public.tcg_packs(id) on delete restrict,
  opened_by_profile_id uuid references public.profiles(id) on delete set null,
  results jsonb not null,
  source text not null default 'owner_test'
    check (source in ('owner_test')),
  created_at timestamptz not null default now()
);

create index if not exists tcg_packs_set_active_idx
  on public.tcg_packs (set_id, is_active, is_owner_test_only, code);

create index if not exists tcg_pack_drop_rates_pack_idx
  on public.tcg_pack_drop_rates (pack_id, rarity_code);

create index if not exists tcg_pack_openings_profile_idx
  on public.tcg_pack_openings (profile_id, created_at desc);

create index if not exists tcg_pack_openings_pack_idx
  on public.tcg_pack_openings (pack_id, created_at desc);

drop trigger if exists set_tcg_packs_updated_at on public.tcg_packs;
create trigger set_tcg_packs_updated_at
before update on public.tcg_packs
for each row
execute function public.set_updated_at();

alter table public.tcg_packs enable row level security;
alter table public.tcg_pack_drop_rates enable row level security;
alter table public.tcg_pack_openings enable row level security;

revoke all on public.tcg_packs from public, anon, authenticated;
revoke all on public.tcg_pack_drop_rates from public, anon, authenticated;
revoke all on public.tcg_pack_openings from public, anon, authenticated;

alter table public.tcg_inventory_events
  drop constraint if exists tcg_inventory_events_event_type_check;

alter table public.tcg_inventory_events
  add constraint tcg_inventory_events_event_type_check
  check (event_type in ('admin_grant', 'pack_opened'));

alter table public.tcg_inventory_events
  drop constraint if exists tcg_inventory_events_source_type_check;

alter table public.tcg_inventory_events
  add constraint tcg_inventory_events_source_type_check
  check (source_type in ('admin_tool', 'owner_test_pack'));

with season_zero as (
  select id
  from public.tcg_sets
  where set_key = 'season_0_anteiku_origins'
)
insert into public.tcg_packs (
  code,
  name,
  description,
  set_id,
  cards_per_pack,
  is_active,
  is_owner_test_only
)
select
  'season_0_test_pack',
  'Season 0 Test Pack',
  'Owner-only test pack for Season 0 pack-opening validation. Temporary drop weights; no economy or currency cost.',
  season_zero.id,
  5,
  true,
  true
from season_zero
on conflict (code) do update
set name = excluded.name,
    description = excluded.description,
    set_id = excluded.set_id,
    cards_per_pack = excluded.cards_per_pack,
    is_active = excluded.is_active,
    is_owner_test_only = excluded.is_owner_test_only,
    updated_at = now();

with pack as (
  select id
  from public.tcg_packs
  where code = 'season_0_test_pack'
),
rates(rarity_code, weight, guaranteed_count) as (
  values
    ('common', 6000, 0),
    ('uncommon', 2500, 0),
    ('rare', 1000, 0),
    ('epic', 400, 0),
    ('legendary', 90, 0),
    ('mythic', 10, 0)
)
insert into public.tcg_pack_drop_rates (
  pack_id,
  rarity_code,
  weight,
  guaranteed_count
)
select
  pack.id,
  rates.rarity_code,
  rates.weight,
  rates.guaranteed_count
from pack
cross join rates
on conflict (pack_id, rarity_code) do update
set weight = excluded.weight,
    guaranteed_count = excluded.guaranteed_count;

create or replace function public.tcg_owner_open_test_pack(
  p_pack_code text default 'season_0_test_pack'
)
returns table (
  opening_id uuid,
  pack_code text,
  pack_name text,
  cards_opened integer,
  results jsonb,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  actor_auth_id uuid := auth.uid();
  normalized_pack_code text := lower(btrim(coalesce(p_pack_code, 'season_0_test_pack')));
  target_pack record;
  created_opening_id uuid;
  created_at_value timestamptz;
  total_weight integer;
  roll integer;
  chosen_rarity_code text;
  chosen_card record;
  existing_inventory record;
  previous_quantity integer;
  resulting_quantity integer;
  updated_inventory_id uuid;
  result_items jsonb := '[]'::jsonb;
  item_index integer;
begin
  if actor_id is null then
    raise exception 'Active Owner profile is required.';
  end if;

  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if normalized_pack_code = '' then
    raise exception 'Pack code is required.';
  end if;

  select
    p.id,
    p.code,
    p.name,
    p.cards_per_pack,
    p.is_active,
    p.is_owner_test_only,
    p.set_id,
    s.set_key,
    s.release_status
  into target_pack
  from public.tcg_packs p
  join public.tcg_sets s on s.id = p.set_id
  where p.code = normalized_pack_code
  limit 1;

  if not found
     or not target_pack.is_active
     or not target_pack.is_owner_test_only
     or target_pack.release_status <> 'active' then
    raise exception 'Owner test pack was not found.';
  end if;

  select coalesce(sum(weight), 0)
  into total_weight
  from public.tcg_pack_drop_rates
  where pack_id = target_pack.id;

  if total_weight <= 0 then
    raise exception 'Pack has no configured drop weights.';
  end if;

  insert into public.tcg_pack_openings (
    profile_id,
    pack_id,
    opened_by_profile_id,
    results,
    source
  )
  values (
    actor_id,
    target_pack.id,
    actor_id,
    '[]'::jsonb,
    'owner_test'
  )
  returning public.tcg_pack_openings.id, public.tcg_pack_openings.created_at
  into created_opening_id, created_at_value;

  for item_index in 1..target_pack.cards_per_pack loop
    roll := floor(random() * total_weight)::integer + 1;

    with weighted_rates as (
      select
        rarity_code,
        sum(weight) over (order by rarity_code rows unbounded preceding) as cumulative_weight
      from public.tcg_pack_drop_rates
      where pack_id = target_pack.id
    )
    select rarity_code
    into chosen_rarity_code
    from weighted_rates
    where cumulative_weight >= roll
    order by cumulative_weight asc
    limit 1;

    if chosen_rarity_code is null then
      raise exception 'Pack roll failed.';
    end if;

    select
      c.id,
      c.card_key,
      c.card_no,
      c.name,
      c.card_type,
      c.faction,
      c.collector_value,
      c.art_path,
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order
    into chosen_card
    from public.tcg_cards c
    join public.tcg_rarities r on r.id = c.rarity_id
    where c.set_id = target_pack.set_id
      and c.release_status = 'active'
      and c.is_collectible = true
      and r.rarity_key = chosen_rarity_code
    order by random()
    limit 1;

    if not found then
      raise exception 'No active collectible card exists for rarity %.', chosen_rarity_code;
    end if;

    previous_quantity := 0;
    updated_inventory_id := null;

    select inv.*
    into existing_inventory
    from public.tcg_player_inventory inv
    where inv.profile_id = actor_id
      and inv.card_id = chosen_card.id
    for update;

    if found then
      previous_quantity := existing_inventory.quantity;
      resulting_quantity := existing_inventory.quantity + 1;

      update public.tcg_player_inventory
      set quantity = resulting_quantity,
          first_acquired_at = coalesce(first_acquired_at, now()),
          last_acquired_at = now(),
          updated_at = now()
      where id = existing_inventory.id
      returning id into updated_inventory_id;
    else
      resulting_quantity := 1;

      insert into public.tcg_player_inventory (
        profile_id,
        card_id,
        quantity,
        first_acquired_at,
        last_acquired_at
      )
      values (
        actor_id,
        chosen_card.id,
        1,
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
      actor_id,
      chosen_card.id,
      1,
      'pack_opened',
      'owner_test_pack',
      created_opening_id,
      actor_auth_id,
      actor_id,
      'Owner test pack opened',
      jsonb_build_object(
        'pack_code', target_pack.code,
        'opening_id', created_opening_id,
        'card_key', chosen_card.card_key,
        'card_name', chosen_card.name,
        'previous_quantity', previous_quantity,
        'new_quantity', resulting_quantity
      )
    );

    result_items := result_items || jsonb_build_array(
      jsonb_build_object(
        'card_id', chosen_card.id,
        'card_no', chosen_card.card_no,
        'card_key', chosen_card.card_key,
        'slug', chosen_card.card_key,
        'name', chosen_card.name,
        'rarity_key', chosen_card.rarity_key,
        'rarity_name', chosen_card.rarity_name,
        'rarity_sort_order', chosen_card.rarity_sort_order,
        'card_type', chosen_card.card_type,
        'faction', chosen_card.faction,
        'collector_value', chosen_card.collector_value,
        'art_path', chosen_card.art_path,
        'quantity_delta', 1,
        'previous_quantity', previous_quantity,
        'new_quantity', resulting_quantity,
        'is_duplicate', previous_quantity > 0
      )
    );
  end loop;

  update public.tcg_pack_openings
  set results = result_items
  where id = created_opening_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    null,
    'tcg_owner_test_pack_opened',
    'tcg_pack_openings',
    created_opening_id,
    jsonb_build_object(
      'pack_code', target_pack.code,
      'cards_opened', target_pack.cards_per_pack,
      'owner_test_only', true
    )
  );

  return query
  select
    created_opening_id,
    target_pack.code,
    target_pack.name,
    target_pack.cards_per_pack,
    result_items,
    created_at_value;
end;
$$;

revoke all on function public.tcg_owner_open_test_pack(text) from public, anon;
grant execute on function public.tcg_owner_open_test_pack(text) to authenticated;
