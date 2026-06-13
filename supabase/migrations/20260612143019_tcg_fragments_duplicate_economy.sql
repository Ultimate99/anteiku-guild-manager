-- Milestone 30G-F1: TCG Anteiku Fragments / duplicate burn / missing-card crafting backend.
-- Backend/RPC/RLS only. No pity, pack RNG, prices, drop rates, pack size, frontend, or CP usage.

create table if not exists public.tcg_fragment_wallets (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_fragment_wallets_profile_uidx unique (profile_id)
);

create table if not exists public.tcg_fragment_ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  amount_delta integer not null check (amount_delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  transaction_type text not null
    check (transaction_type in ('duplicate_burn', 'missing_card_craft')),
  source text,
  reference_type text
    check (reference_type is null or reference_type in ('tcg_player_inventory', 'tcg_cards', 'tcg_inventory_events')),
  reference_id uuid,
  card_id uuid references public.tcg_cards(id) on delete restrict,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.tcg_crafting_rules (
  id uuid primary key default gen_random_uuid(),
  rarity_code text not null references public.tcg_rarities(rarity_key) on update cascade on delete restrict,
  dust_value integer not null check (dust_value >= 0),
  crafting_cost integer check (crafting_cost is null or crafting_cost >= 0),
  is_craftable boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_crafting_rules_rarity_uidx unique (rarity_code)
);

create index if not exists tcg_fragment_wallets_profile_idx
  on public.tcg_fragment_wallets (profile_id, updated_at desc);

create index if not exists tcg_fragment_ledger_profile_idx
  on public.tcg_fragment_ledger (profile_id, created_at desc);

create index if not exists tcg_fragment_ledger_card_idx
  on public.tcg_fragment_ledger (card_id, created_at desc);

create index if not exists tcg_fragment_ledger_type_idx
  on public.tcg_fragment_ledger (transaction_type, created_at desc);

create index if not exists tcg_crafting_rules_active_idx
  on public.tcg_crafting_rules (is_active, is_craftable, rarity_code);

drop trigger if exists set_tcg_fragment_wallets_updated_at on public.tcg_fragment_wallets;
create trigger set_tcg_fragment_wallets_updated_at
before update on public.tcg_fragment_wallets
for each row
execute function public.set_updated_at();

drop trigger if exists set_tcg_crafting_rules_updated_at on public.tcg_crafting_rules;
create trigger set_tcg_crafting_rules_updated_at
before update on public.tcg_crafting_rules
for each row
execute function public.set_updated_at();

alter table public.tcg_fragment_wallets enable row level security;
alter table public.tcg_fragment_ledger enable row level security;
alter table public.tcg_crafting_rules enable row level security;

revoke all on public.tcg_fragment_wallets from public, anon, authenticated;
revoke all on public.tcg_fragment_ledger from public, anon, authenticated;
revoke all on public.tcg_crafting_rules from public, anon, authenticated;

alter table public.tcg_inventory_events
  drop constraint if exists tcg_inventory_events_event_type_check;

alter table public.tcg_inventory_events
  add constraint tcg_inventory_events_event_type_check
  check (event_type in ('admin_grant', 'pack_opened', 'duplicate_burned', 'card_crafted'));

alter table public.tcg_inventory_events
  drop constraint if exists tcg_inventory_events_source_type_check;

alter table public.tcg_inventory_events
  add constraint tcg_inventory_events_source_type_check
  check (source_type in ('admin_tool', 'owner_test_pack', 'owner_test_shop', 'duplicate_economy'));

insert into public.tcg_crafting_rules (
  rarity_code,
  dust_value,
  crafting_cost,
  is_craftable,
  is_active
)
values
  ('common', 2, 30, true, true),
  ('uncommon', 5, 90, true, true),
  ('rare', 18, 350, true, true),
  ('epic', 60, 1400, true, true),
  ('legendary', 200, 5000, true, true),
  ('mythic', 700, null, false, true)
on conflict on constraint tcg_crafting_rules_rarity_uidx do update
set dust_value = excluded.dust_value,
    crafting_cost = excluded.crafting_cost,
    is_craftable = excluded.is_craftable,
    is_active = excluded.is_active,
    updated_at = now();

create or replace function public.tcg_get_my_fragments()
returns table (
  profile_id uuid,
  balance integer,
  updated_at timestamptz
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
    actor_id,
    coalesce(w.balance, 0),
    w.updated_at
  from (select actor_id as profile_id) actor
  left join public.tcg_fragment_wallets w
    on w.profile_id = actor.profile_id;
end;
$$;

create or replace function public.tcg_get_my_duplicate_summary()
returns table (
  card_id uuid,
  card_no text,
  card_key text,
  slug text,
  card_name text,
  rarity_key text,
  rarity_name text,
  art_path text,
  quantity integer,
  burnable_quantity integer,
  dust_value integer,
  max_fragment_gain integer
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
    c.card_no,
    c.card_key,
    c.card_key,
    c.name,
    r.rarity_key,
    r.name,
    c.art_path,
    inv.quantity,
    greatest(inv.quantity - 1, 0)::integer,
    cr.dust_value,
    (greatest(inv.quantity - 1, 0) * cr.dust_value)::integer
  from public.tcg_player_inventory inv
  join public.tcg_cards c on c.id = inv.card_id
  join public.tcg_sets s on s.id = c.set_id
  join public.tcg_rarities r on r.id = c.rarity_id
  join public.tcg_crafting_rules cr
    on cr.rarity_code = r.rarity_key
   and cr.is_active = true
  where inv.profile_id = actor_id
    and inv.quantity > 1
    and c.release_status = 'active'
    and c.is_collectible = true
    and s.release_status = 'active'
  order by r.sort_order desc, c.sort_order asc, c.card_no asc;
end;
$$;

create or replace function public.tcg_burn_duplicate_card(
  p_card_id uuid,
  p_quantity integer
)
returns table (
  profile_id uuid,
  card_id uuid,
  card_no text,
  card_key text,
  card_name text,
  rarity_key text,
  quantity_burned integer,
  fragments_gained integer,
  fragment_balance integer,
  remaining_quantity integer,
  inventory_event_id uuid,
  fragment_ledger_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  actor_auth_id uuid := auth.uid();
  target_card record;
  inventory_row record;
  wallet_row record;
  before_quantity integer;
  after_quantity integer;
  before_balance integer;
  after_balance integer;
  gained_fragments integer;
  created_inventory_event_id uuid;
  created_fragment_ledger_id uuid;
begin
  if p_card_id is null then
    raise exception 'Card is required.';
  end if;

  if p_quantity is null or p_quantity <= 0 then
    raise exception 'Burn quantity must be greater than zero.';
  end if;

  select
    c.id,
    c.card_no,
    c.card_key,
    c.name as card_name,
    r.rarity_key,
    cr.dust_value
  into target_card
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  join public.tcg_rarities r on r.id = c.rarity_id
  join public.tcg_crafting_rules cr
    on cr.rarity_code = r.rarity_key
   and cr.is_active = true
  where c.id = p_card_id
    and c.release_status = 'active'
    and c.is_collectible = true
    and s.release_status = 'active'
  limit 1;

  if not found then
    raise exception 'Active collectible card was not found.';
  end if;

  select *
  into inventory_row
  from public.tcg_player_inventory inv
  where inv.profile_id = actor_id
    and inv.card_id = target_card.id
  for update;

  if not found or coalesce(inventory_row.quantity, 0) <= 0 then
    raise exception 'Owned card was not found.';
  end if;

  before_quantity := inventory_row.quantity;

  if p_quantity > before_quantity - 1 then
    raise exception 'Cannot burn the last copy of a card.';
  end if;

  gained_fragments := p_quantity * target_card.dust_value;
  after_quantity := before_quantity - p_quantity;

  update public.tcg_player_inventory
  set quantity = after_quantity,
      updated_at = now()
  where id = inventory_row.id;

  insert into public.tcg_fragment_wallets (
    profile_id,
    balance
  )
  values (
    actor_id,
    0
  )
  on conflict on constraint tcg_fragment_wallets_profile_uidx do nothing;

  select *
  into wallet_row
  from public.tcg_fragment_wallets w
  where w.profile_id = actor_id
  for update;

  before_balance := coalesce(wallet_row.balance, 0);
  after_balance := before_balance + gained_fragments;

  update public.tcg_fragment_wallets
  set balance = after_balance,
      updated_at = now()
  where id = wallet_row.id;

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
    target_card.id,
    -p_quantity,
    'duplicate_burned',
    'duplicate_economy',
    inventory_row.id,
    actor_auth_id,
    actor_id,
    'Duplicate burned for Anteiku Fragments',
    jsonb_build_object(
      'card_key', target_card.card_key,
      'card_name', target_card.card_name,
      'rarity_key', target_card.rarity_key,
      'dust_value', target_card.dust_value,
      'quantity_before', before_quantity,
      'quantity_after', after_quantity,
      'fragments_gained', gained_fragments,
      'fragment_balance_before', before_balance,
      'fragment_balance_after', after_balance
    )
  )
  returning id into created_inventory_event_id;

  insert into public.tcg_fragment_ledger (
    profile_id,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    reference_type,
    reference_id,
    card_id,
    actor_profile_id,
    metadata
  )
  values (
    actor_id,
    gained_fragments,
    after_balance,
    'duplicate_burn',
    'duplicate_burn',
    'tcg_inventory_events',
    created_inventory_event_id,
    target_card.id,
    actor_id,
    jsonb_build_object(
      'inventory_id', inventory_row.id,
      'card_key', target_card.card_key,
      'quantity_burned', p_quantity,
      'quantity_before', before_quantity,
      'quantity_after', after_quantity,
      'dust_value', target_card.dust_value,
      'balance_before', before_balance
    )
  )
  returning id into created_fragment_ledger_id;

  return query
  select
    actor_id,
    target_card.id,
    target_card.card_no,
    target_card.card_key,
    target_card.card_name,
    target_card.rarity_key,
    p_quantity,
    gained_fragments,
    after_balance,
    after_quantity,
    created_inventory_event_id,
    created_fragment_ledger_id;
end;
$$;

create or replace function public.tcg_craft_missing_card(
  p_card_id uuid
)
returns table (
  profile_id uuid,
  card_id uuid,
  card_no text,
  card_key text,
  card_name text,
  rarity_key text,
  crafting_cost integer,
  fragment_balance integer,
  new_quantity integer,
  inventory_event_id uuid,
  fragment_ledger_id uuid
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  actor_auth_id uuid := auth.uid();
  target_card record;
  inventory_row record;
  wallet_row record;
  before_balance integer;
  after_balance integer;
  updated_inventory_id uuid;
  created_inventory_event_id uuid;
  created_fragment_ledger_id uuid;
begin
  if p_card_id is null then
    raise exception 'Card is required.';
  end if;

  select
    c.id,
    c.card_no,
    c.card_key,
    c.name as card_name,
    r.rarity_key,
    cr.crafting_cost,
    cr.is_craftable
  into target_card
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  join public.tcg_rarities r on r.id = c.rarity_id
  join public.tcg_crafting_rules cr
    on cr.rarity_code = r.rarity_key
   and cr.is_active = true
  where c.id = p_card_id
    and c.release_status = 'active'
    and c.is_collectible = true
    and s.release_status = 'active'
  limit 1;

  if not found then
    raise exception 'Active collectible card was not found.';
  end if;

  if target_card.rarity_key = 'mythic' then
    raise exception 'Mythic crafting is disabled for v1.';
  end if;

  if not target_card.is_craftable or target_card.crafting_cost is null then
    raise exception 'This card rarity is not craftable.';
  end if;

  select *
  into inventory_row
  from public.tcg_player_inventory inv
  where inv.profile_id = actor_id
    and inv.card_id = target_card.id
  for update;

  if found and coalesce(inventory_row.quantity, 0) > 0 then
    raise exception 'Card is already owned.';
  end if;

  select *
  into wallet_row
  from public.tcg_fragment_wallets w
  where w.profile_id = actor_id
  for update;

  if not found or coalesce(wallet_row.balance, 0) < target_card.crafting_cost then
    raise exception 'Insufficient Anteiku Fragments.';
  end if;

  before_balance := wallet_row.balance;
  after_balance := before_balance - target_card.crafting_cost;

  update public.tcg_fragment_wallets
  set balance = after_balance,
      updated_at = now()
  where id = wallet_row.id;

  if inventory_row.id is not null then
    update public.tcg_player_inventory
    set quantity = 1,
        first_acquired_at = coalesce(first_acquired_at, now()),
        last_acquired_at = now(),
        updated_at = now()
    where id = inventory_row.id
    returning id into updated_inventory_id;
  else
    insert into public.tcg_player_inventory (
      profile_id,
      card_id,
      quantity,
      first_acquired_at,
      last_acquired_at
    )
    values (
      actor_id,
      target_card.id,
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
    target_card.id,
    1,
    'card_crafted',
    'duplicate_economy',
    updated_inventory_id,
    actor_auth_id,
    actor_id,
    'Missing card crafted with Anteiku Fragments',
    jsonb_build_object(
      'card_key', target_card.card_key,
      'card_name', target_card.card_name,
      'rarity_key', target_card.rarity_key,
      'crafting_cost', target_card.crafting_cost,
      'fragment_balance_before', before_balance,
      'fragment_balance_after', after_balance
    )
  )
  returning id into created_inventory_event_id;

  insert into public.tcg_fragment_ledger (
    profile_id,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    reference_type,
    reference_id,
    card_id,
    actor_profile_id,
    metadata
  )
  values (
    actor_id,
    -target_card.crafting_cost,
    after_balance,
    'missing_card_craft',
    'missing_card_craft',
    'tcg_inventory_events',
    created_inventory_event_id,
    target_card.id,
    actor_id,
    jsonb_build_object(
      'inventory_id', updated_inventory_id,
      'card_key', target_card.card_key,
      'crafting_cost', target_card.crafting_cost,
      'balance_before', before_balance
    )
  )
  returning id into created_fragment_ledger_id;

  return query
  select
    actor_id,
    target_card.id,
    target_card.card_no,
    target_card.card_key,
    target_card.card_name,
    target_card.rarity_key,
    target_card.crafting_cost,
    after_balance,
    1,
    created_inventory_event_id,
    created_fragment_ledger_id;
end;
$$;

revoke all on function public.tcg_get_my_fragments() from public, anon;
revoke all on function public.tcg_get_my_duplicate_summary() from public, anon;
revoke all on function public.tcg_burn_duplicate_card(uuid, integer) from public, anon;
revoke all on function public.tcg_craft_missing_card(uuid) from public, anon;

grant execute on function public.tcg_get_my_fragments() to authenticated;
grant execute on function public.tcg_get_my_duplicate_summary() to authenticated;
grant execute on function public.tcg_burn_duplicate_card(uuid, integer) to authenticated;
grant execute on function public.tcg_craft_missing_card(uuid) to authenticated;
