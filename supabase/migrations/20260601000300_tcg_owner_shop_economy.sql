-- Milestone 30E-A: Owner-only TCG shop/economy backend foundation.
-- Backend/RPC only. No frontend shop UI, member shop access, payments, premium currency, or normal CP usage.

create table if not exists public.tcg_wallets (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  currency_code text not null default 'anteiku_coins',
  balance integer not null default 0 check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_wallets_profile_currency_uidx unique (profile_id, currency_code),
  constraint tcg_wallets_currency_chk check (currency_code = 'anteiku_coins')
);

create table if not exists public.tcg_wallet_ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  currency_code text not null default 'anteiku_coins',
  amount_delta integer not null check (amount_delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  transaction_type text not null
    check (transaction_type in ('owner_test_grant', 'shop_purchase')),
  source text,
  reference_type text
    check (reference_type is null or reference_type in ('tcg_shop_items')),
  reference_id uuid,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint tcg_wallet_ledger_currency_chk check (currency_code = 'anteiku_coins')
);

create table if not exists public.tcg_shop_items (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text,
  item_type text not null check (item_type in ('pack')),
  pack_id uuid references public.tcg_packs(id) on delete restrict,
  currency_code text not null default 'anteiku_coins',
  price integer not null check (price >= 0),
  is_active boolean not null default true,
  is_owner_test_only boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_shop_items_code_format_chk
    check (code ~ '^[a-z0-9]+(?:_[a-z0-9]+)*$'),
  constraint tcg_shop_items_currency_chk check (currency_code = 'anteiku_coins')
);

create index if not exists tcg_wallets_profile_idx
  on public.tcg_wallets (profile_id, currency_code);

create index if not exists tcg_wallet_ledger_profile_idx
  on public.tcg_wallet_ledger (profile_id, created_at desc);

create index if not exists tcg_wallet_ledger_type_idx
  on public.tcg_wallet_ledger (transaction_type, created_at desc);

create index if not exists tcg_shop_items_active_sort_idx
  on public.tcg_shop_items (is_active, is_owner_test_only, sort_order, code);

create index if not exists tcg_shop_items_pack_idx
  on public.tcg_shop_items (pack_id);

drop trigger if exists set_tcg_wallets_updated_at on public.tcg_wallets;
create trigger set_tcg_wallets_updated_at
before update on public.tcg_wallets
for each row
execute function public.set_updated_at();

drop trigger if exists set_tcg_shop_items_updated_at on public.tcg_shop_items;
create trigger set_tcg_shop_items_updated_at
before update on public.tcg_shop_items
for each row
execute function public.set_updated_at();

alter table public.tcg_wallets enable row level security;
alter table public.tcg_wallet_ledger enable row level security;
alter table public.tcg_shop_items enable row level security;

revoke all on public.tcg_wallets from public, anon, authenticated;
revoke all on public.tcg_wallet_ledger from public, anon, authenticated;
revoke all on public.tcg_shop_items from public, anon, authenticated;

alter table public.tcg_inventory_events
  drop constraint if exists tcg_inventory_events_source_type_check;

alter table public.tcg_inventory_events
  add constraint tcg_inventory_events_source_type_check
  check (source_type in ('admin_tool', 'owner_test_pack', 'owner_test_shop'));

alter table public.tcg_pack_openings
  drop constraint if exists tcg_pack_openings_source_check;

alter table public.tcg_pack_openings
  add constraint tcg_pack_openings_source_check
  check (source in ('owner_test', 'owner_shop_test'));

with test_pack as (
  select id
  from public.tcg_packs
  where code = 'season_0_test_pack'
)
insert into public.tcg_shop_items (
  code,
  name,
  description,
  item_type,
  pack_id,
  currency_code,
  price,
  is_active,
  is_owner_test_only,
  sort_order
)
select
  'season_0_test_pack_shop',
  'Season 0 Test Pack',
  'Owner-only shop item for testing the free Anteiku Coins economy loop.',
  'pack',
  test_pack.id,
  'anteiku_coins',
  100,
  true,
  true,
  10
from test_pack
on conflict (code) do update
set name = excluded.name,
    description = excluded.description,
    item_type = excluded.item_type,
    pack_id = excluded.pack_id,
    currency_code = excluded.currency_code,
    price = excluded.price,
    is_active = excluded.is_active,
    is_owner_test_only = excluded.is_owner_test_only,
    sort_order = excluded.sort_order,
    updated_at = now();

create or replace function private.tcg_open_owner_test_pack_for_profile(
  p_actor_profile_id uuid,
  p_actor_auth_id uuid,
  p_pack_code text default 'season_0_test_pack',
  p_opening_source text default 'owner_test',
  p_inventory_source_type text default 'owner_test_pack',
  p_reason text default 'Owner test pack opened',
  p_audit_action text default 'tcg_owner_test_pack_opened',
  p_event_metadata jsonb default '{}'::jsonb
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
  merged_metadata jsonb := coalesce(p_event_metadata, '{}'::jsonb);
begin
  if p_actor_profile_id is null then
    raise exception 'Active Owner profile is required.';
  end if;

  if normalized_pack_code = '' then
    raise exception 'Pack code is required.';
  end if;

  if p_opening_source not in ('owner_test', 'owner_shop_test') then
    raise exception 'Invalid pack opening source.';
  end if;

  if p_inventory_source_type not in ('owner_test_pack', 'owner_test_shop') then
    raise exception 'Invalid inventory source.';
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
    p_actor_profile_id,
    target_pack.id,
    p_actor_profile_id,
    '[]'::jsonb,
    p_opening_source
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
    where inv.profile_id = p_actor_profile_id
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
        p_actor_profile_id,
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
      p_actor_profile_id,
      chosen_card.id,
      1,
      'pack_opened',
      p_inventory_source_type,
      created_opening_id,
      p_actor_auth_id,
      p_actor_profile_id,
      nullif(btrim(coalesce(p_reason, '')), ''),
      jsonb_build_object(
        'pack_code', target_pack.code,
        'opening_id', created_opening_id,
        'card_key', chosen_card.card_key,
        'card_name', chosen_card.name,
        'previous_quantity', previous_quantity,
        'new_quantity', resulting_quantity
      ) || merged_metadata
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
    p_actor_profile_id,
    p_actor_profile_id,
    null,
    coalesce(nullif(btrim(p_audit_action), ''), 'tcg_owner_test_pack_opened'),
    'tcg_pack_openings',
    created_opening_id,
    jsonb_build_object(
      'pack_code', target_pack.code,
      'cards_opened', target_pack.cards_per_pack,
      'owner_test_only', true
    ) || merged_metadata
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
begin
  if actor_id is null then
    raise exception 'Active Owner profile is required.';
  end if;

  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  return query
  select *
  from private.tcg_open_owner_test_pack_for_profile(
    actor_id,
    actor_auth_id,
    p_pack_code,
    'owner_test',
    'owner_test_pack',
    'Owner test pack opened',
    'tcg_owner_test_pack_opened',
    '{}'::jsonb
  );
end;
$$;

create or replace function public.tcg_owner_grant_test_coins(
  p_amount integer default 1000
)
returns table (
  profile_id uuid,
  currency_code text,
  balance integer,
  granted_amount integer,
  ledger_id uuid,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  wallet_row record;
  before_balance integer;
  after_balance integer;
  created_ledger_id uuid;
  wallet_updated_at timestamptz;
begin
  if actor_id is null or not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if p_amount is null or p_amount <= 0 or p_amount > 1000000 then
    raise exception 'Grant amount must be between 1 and 1000000.';
  end if;

  insert into public.tcg_wallets (
    profile_id,
    currency_code,
    balance
  )
  values (
    actor_id,
    'anteiku_coins',
    0
  )
  on conflict on constraint tcg_wallets_profile_currency_uidx do nothing;

  select *
  into wallet_row
  from public.tcg_wallets w
  where w.profile_id = actor_id
    and w.currency_code = 'anteiku_coins'
  for update;

  before_balance := coalesce(wallet_row.balance, 0);
  after_balance := before_balance + p_amount;

  update public.tcg_wallets
  set balance = after_balance,
      updated_at = now()
  where id = wallet_row.id
  returning public.tcg_wallets.updated_at into wallet_updated_at;

  insert into public.tcg_wallet_ledger (
    profile_id,
    currency_code,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    actor_profile_id,
    metadata
  )
  values (
    actor_id,
    'anteiku_coins',
    p_amount,
    after_balance,
    'owner_test_grant',
    'owner_tool',
    actor_id,
    jsonb_build_object(
      'owner_test_only', true,
      'balance_before', before_balance
    )
  )
  returning id into created_ledger_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    null,
    'tcg_owner_test_coins_granted',
    'tcg_wallets',
    wallet_row.id,
    jsonb_build_object(
      'currency_code', 'anteiku_coins',
      'amount_delta', p_amount,
      'balance_after', after_balance,
      'ledger_id', created_ledger_id
    )
  );

  return query
  select actor_id, 'anteiku_coins'::text, after_balance, p_amount, created_ledger_id, wallet_updated_at;
end;
$$;

create or replace function public.tcg_get_my_wallet()
returns table (
  profile_id uuid,
  currency_code text,
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
  if actor_id is null or not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  return query
  select
    actor_id,
    'anteiku_coins'::text,
    coalesce(w.balance, 0),
    w.updated_at
  from (select actor_id as profile_id) actor
  left join public.tcg_wallets w
    on w.profile_id = actor.profile_id
   and w.currency_code = 'anteiku_coins';
end;
$$;

create or replace function public.tcg_owner_get_test_shop()
returns table (
  shop_item_code text,
  shop_item_name text,
  description text,
  item_type text,
  pack_code text,
  pack_name text,
  cards_per_pack integer,
  currency_code text,
  price integer,
  is_owner_test_only boolean,
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
  if actor_id is null or not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  return query
  select
    si.code,
    si.name,
    si.description,
    si.item_type,
    p.code,
    p.name,
    p.cards_per_pack,
    si.currency_code,
    si.price,
    si.is_owner_test_only,
    si.sort_order
  from public.tcg_shop_items si
  join public.tcg_packs p on p.id = si.pack_id
  where si.is_active
    and si.is_owner_test_only
    and p.is_active
    and p.is_owner_test_only
  order by si.sort_order asc, si.code asc;
end;
$$;

create or replace function public.tcg_owner_buy_test_pack(
  p_shop_item_code text default 'season_0_test_pack_shop'
)
returns table (
  balance_before integer,
  balance_after integer,
  currency_code text,
  shop_item_code text,
  shop_item_name text,
  price integer,
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
  normalized_shop_item_code text := lower(btrim(coalesce(p_shop_item_code, 'season_0_test_pack_shop')));
  shop_item record;
  wallet_row record;
  before_balance integer;
  after_balance integer;
  created_ledger_id uuid;
  opening_result record;
begin
  if actor_id is null or not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if normalized_shop_item_code = '' then
    raise exception 'Shop item code is required.';
  end if;

  select
    si.id,
    si.code,
    si.name,
    si.item_type,
    si.currency_code,
    si.price,
    si.is_active,
    si.is_owner_test_only,
    p.code as pack_code,
    p.name as pack_name,
    p.is_active as pack_is_active,
    p.is_owner_test_only as pack_is_owner_test_only
  into shop_item
  from public.tcg_shop_items si
  join public.tcg_packs p on p.id = si.pack_id
  where si.code = normalized_shop_item_code
  limit 1;

  if not found
     or not shop_item.is_active
     or not shop_item.is_owner_test_only
     or shop_item.item_type <> 'pack'
     or not shop_item.pack_is_active
     or not shop_item.pack_is_owner_test_only then
    raise exception 'Owner test shop item was not found.';
  end if;

  insert into public.tcg_wallets (
    profile_id,
    currency_code,
    balance
  )
  values (
    actor_id,
    shop_item.currency_code,
    0
  )
  on conflict on constraint tcg_wallets_profile_currency_uidx do nothing;

  select *
  into wallet_row
  from public.tcg_wallets w
  where w.profile_id = actor_id
    and w.currency_code = shop_item.currency_code
  for update;

  before_balance := coalesce(wallet_row.balance, 0);

  if before_balance < shop_item.price then
    raise exception 'Insufficient Anteiku Coins.';
  end if;

  after_balance := before_balance - shop_item.price;

  update public.tcg_wallets
  set balance = after_balance,
      updated_at = now()
  where id = wallet_row.id;

  insert into public.tcg_wallet_ledger (
    profile_id,
    currency_code,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    reference_type,
    reference_id,
    actor_profile_id,
    metadata
  )
  values (
    actor_id,
    shop_item.currency_code,
    -shop_item.price,
    after_balance,
    'shop_purchase',
    'owner_test_shop',
    'tcg_shop_items',
    shop_item.id,
    actor_id,
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'pack_code', shop_item.pack_code,
      'price', shop_item.price,
      'balance_before', before_balance,
      'owner_test_only', true
    )
  )
  returning id into created_ledger_id;

  select *
  into opening_result
  from private.tcg_open_owner_test_pack_for_profile(
    actor_id,
    actor_auth_id,
    shop_item.pack_code,
    'owner_shop_test',
    'owner_test_shop',
    'Owner test shop pack opened',
    'tcg_owner_test_pack_purchased',
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'ledger_id', created_ledger_id,
      'price', shop_item.price,
      'currency_code', shop_item.currency_code
    )
  );

  update public.tcg_wallet_ledger
  set metadata = metadata || jsonb_build_object('opening_id', opening_result.opening_id)
  where id = created_ledger_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    null,
    'tcg_owner_test_pack_bought',
    'tcg_shop_items',
    shop_item.id,
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'pack_code', opening_result.pack_code,
      'price', shop_item.price,
      'currency_code', shop_item.currency_code,
      'balance_before', before_balance,
      'balance_after', after_balance,
      'ledger_id', created_ledger_id,
      'opening_id', opening_result.opening_id
    )
  );

  return query
  select
    before_balance,
    after_balance,
    shop_item.currency_code,
    shop_item.code,
    shop_item.name,
    shop_item.price,
    opening_result.opening_id,
    opening_result.pack_code,
    opening_result.pack_name,
    opening_result.cards_opened,
    opening_result.results,
    opening_result.created_at;
end;
$$;

revoke all on function private.tcg_open_owner_test_pack_for_profile(uuid, uuid, text, text, text, text, text, jsonb)
  from public, anon, authenticated;

revoke all on function public.tcg_owner_open_test_pack(text) from public, anon;
revoke all on function public.tcg_owner_grant_test_coins(integer) from public, anon;
revoke all on function public.tcg_get_my_wallet() from public, anon;
revoke all on function public.tcg_owner_get_test_shop() from public, anon;
revoke all on function public.tcg_owner_buy_test_pack(text) from public, anon;

grant execute on function public.tcg_owner_open_test_pack(text) to authenticated;
grant execute on function public.tcg_owner_grant_test_coins(integer) to authenticated;
grant execute on function public.tcg_get_my_wallet() to authenticated;
grant execute on function public.tcg_owner_get_test_shop() to authenticated;
grant execute on function public.tcg_owner_buy_test_pack(text) to authenticated;
