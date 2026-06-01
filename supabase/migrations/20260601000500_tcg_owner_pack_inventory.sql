-- Milestone 30F-B: Owner-only TCG pack inventory backend.
-- Backend/RPC only. Shop purchase can now add owned pack quantity without opening.

create table if not exists public.tcg_player_packs (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  pack_id uuid not null references public.tcg_packs(id) on delete restrict,
  quantity integer not null default 0 check (quantity >= 0),
  first_obtained_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_player_packs_profile_pack_uidx unique (profile_id, pack_id)
);

create table if not exists public.tcg_pack_inventory_events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  pack_id uuid not null references public.tcg_packs(id) on delete restrict,
  quantity_delta integer not null check (quantity_delta <> 0),
  event_type text not null
    check (event_type in ('owner_test_shop_purchase', 'owner_owned_pack_opened')),
  source text,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  reference_type text
    check (reference_type is null or reference_type in ('tcg_shop_items', 'tcg_pack_openings')),
  reference_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists tcg_player_packs_profile_idx
  on public.tcg_player_packs (profile_id, updated_at desc);

create index if not exists tcg_player_packs_pack_idx
  on public.tcg_player_packs (pack_id);

create index if not exists tcg_pack_inventory_events_profile_idx
  on public.tcg_pack_inventory_events (profile_id, created_at desc);

create index if not exists tcg_pack_inventory_events_pack_idx
  on public.tcg_pack_inventory_events (pack_id, created_at desc);

create index if not exists tcg_pack_inventory_events_type_idx
  on public.tcg_pack_inventory_events (event_type, created_at desc);

drop trigger if exists set_tcg_player_packs_updated_at on public.tcg_player_packs;
create trigger set_tcg_player_packs_updated_at
before update on public.tcg_player_packs
for each row
execute function public.set_updated_at();

alter table public.tcg_player_packs enable row level security;
alter table public.tcg_pack_inventory_events enable row level security;

revoke all on public.tcg_player_packs from public, anon, authenticated;
revoke all on public.tcg_pack_inventory_events from public, anon, authenticated;

create or replace function public.tcg_get_my_packs()
returns table (
  profile_id uuid,
  pack_id uuid,
  pack_code text,
  pack_name text,
  description text,
  cards_per_pack integer,
  quantity integer,
  is_owner_test_only boolean,
  first_obtained_at timestamptz,
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
    p.id,
    p.code,
    p.name,
    p.description,
    p.cards_per_pack,
    coalesce(pp.quantity, 0)::integer,
    p.is_owner_test_only,
    pp.first_obtained_at,
    pp.updated_at
  from public.tcg_packs p
  join public.tcg_sets s on s.id = p.set_id
  left join public.tcg_player_packs pp
    on pp.pack_id = p.id
   and pp.profile_id = actor_id
  where p.is_active
    and p.is_owner_test_only
    and s.release_status = 'active'
  order by p.created_at asc, p.code asc;
end;
$$;

create or replace function public.tcg_owner_buy_test_pack_to_inventory(
  p_shop_item_code text default 'season_0_test_pack_shop'
)
returns table (
  balance_before integer,
  balance_after integer,
  currency_code text,
  shop_item_code text,
  shop_item_name text,
  price integer,
  pack_code text,
  pack_name text,
  owned_pack_quantity integer,
  pack_inventory_event_id uuid,
  ledger_id uuid,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
  normalized_shop_item_code text := lower(btrim(coalesce(p_shop_item_code, 'season_0_test_pack_shop')));
  shop_item record;
  wallet_row record;
  pack_inventory_row record;
  before_balance integer;
  after_balance integer;
  before_pack_quantity integer;
  after_pack_quantity integer;
  created_ledger_id uuid;
  created_pack_event_id uuid;
  pack_updated_at timestamptz;
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
    p.id as pack_id,
    p.code as pack_code,
    p.name as pack_name,
    p.is_active as pack_is_active,
    p.is_owner_test_only as pack_is_owner_test_only,
    s.release_status as set_release_status
  into shop_item
  from public.tcg_shop_items si
  join public.tcg_packs p on p.id = si.pack_id
  join public.tcg_sets s on s.id = p.set_id
  where si.code = normalized_shop_item_code
  limit 1;

  if not found
     or not shop_item.is_active
     or not shop_item.is_owner_test_only
     or shop_item.item_type <> 'pack'
     or not shop_item.pack_is_active
     or not shop_item.pack_is_owner_test_only
     or shop_item.set_release_status <> 'active' then
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
    'owner_test_pack_inventory',
    'tcg_shop_items',
    shop_item.id,
    actor_id,
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'pack_code', shop_item.pack_code,
      'price', shop_item.price,
      'balance_before', before_balance,
      'owner_test_only', true,
      'purchase_behavior', 'pack_inventory'
    )
  )
  returning id into created_ledger_id;

  insert into public.tcg_player_packs (
    profile_id,
    pack_id,
    quantity
  )
  values (
    actor_id,
    shop_item.pack_id,
    0
  )
  on conflict on constraint tcg_player_packs_profile_pack_uidx do nothing;

  select *
  into pack_inventory_row
  from public.tcg_player_packs pp
  where pp.profile_id = actor_id
    and pp.pack_id = shop_item.pack_id
  for update;

  before_pack_quantity := coalesce(pack_inventory_row.quantity, 0);
  after_pack_quantity := before_pack_quantity + 1;

  update public.tcg_player_packs
  set quantity = after_pack_quantity,
      first_obtained_at = coalesce(first_obtained_at, now()),
      updated_at = now()
  where id = pack_inventory_row.id
  returning public.tcg_player_packs.updated_at into pack_updated_at;

  insert into public.tcg_pack_inventory_events (
    profile_id,
    pack_id,
    quantity_delta,
    event_type,
    source,
    actor_profile_id,
    reference_type,
    reference_id,
    metadata
  )
  values (
    actor_id,
    shop_item.pack_id,
    1,
    'owner_test_shop_purchase',
    'owner_test_pack_inventory',
    actor_id,
    'tcg_shop_items',
    shop_item.id,
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'pack_code', shop_item.pack_code,
      'ledger_id', created_ledger_id,
      'price', shop_item.price,
      'currency_code', shop_item.currency_code,
      'pack_quantity_before', before_pack_quantity,
      'pack_quantity_after', after_pack_quantity
    )
  )
  returning id into created_pack_event_id;

  update public.tcg_wallet_ledger
  set metadata = metadata || jsonb_build_object(
    'pack_inventory_event_id', created_pack_event_id,
    'pack_quantity_after', after_pack_quantity
  )
  where id = created_ledger_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    null,
    'tcg_owner_test_pack_bought_to_inventory',
    'tcg_shop_items',
    shop_item.id,
    jsonb_build_object(
      'shop_item_code', shop_item.code,
      'pack_code', shop_item.pack_code,
      'price', shop_item.price,
      'currency_code', shop_item.currency_code,
      'balance_before', before_balance,
      'balance_after', after_balance,
      'ledger_id', created_ledger_id,
      'pack_inventory_event_id', created_pack_event_id,
      'pack_quantity_after', after_pack_quantity
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
    shop_item.pack_code,
    shop_item.pack_name,
    after_pack_quantity,
    created_pack_event_id,
    created_ledger_id,
    pack_updated_at;
end;
$$;

create or replace function public.tcg_owner_open_owned_pack(
  p_pack_code text default 'season_0_test_pack'
)
returns table (
  opening_id uuid,
  pack_code text,
  pack_name text,
  cards_opened integer,
  remaining_pack_quantity integer,
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
  pack_inventory_row record;
  before_pack_quantity integer;
  after_pack_quantity integer;
  opening_result record;
  created_pack_event_id uuid;
begin
  if actor_id is null or not private.is_owner(actor_id) then
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

  select *
  into pack_inventory_row
  from public.tcg_player_packs pp
  where pp.profile_id = actor_id
    and pp.pack_id = target_pack.id
  for update;

  if not found or coalesce(pack_inventory_row.quantity, 0) <= 0 then
    raise exception 'No owned test packs available.';
  end if;

  before_pack_quantity := pack_inventory_row.quantity;
  after_pack_quantity := before_pack_quantity - 1;

  update public.tcg_player_packs
  set quantity = after_pack_quantity,
      updated_at = now()
  where id = pack_inventory_row.id;

  select *
  into opening_result
  from private.tcg_open_owner_test_pack_for_profile(
    actor_id,
    actor_auth_id,
    target_pack.code,
    'owner_shop_test',
    'owner_test_shop',
    'Owner owned test pack opened',
    'tcg_owner_owned_pack_opened',
    jsonb_build_object(
      'pack_inventory_quantity_before', before_pack_quantity,
      'pack_inventory_quantity_after', after_pack_quantity,
      'pack_inventory_source', 'owned_pack_inventory'
    )
  );

  insert into public.tcg_pack_inventory_events (
    profile_id,
    pack_id,
    quantity_delta,
    event_type,
    source,
    actor_profile_id,
    reference_type,
    reference_id,
    metadata
  )
  values (
    actor_id,
    target_pack.id,
    -1,
    'owner_owned_pack_opened',
    'owner_test_pack_inventory',
    actor_id,
    'tcg_pack_openings',
    opening_result.opening_id,
    jsonb_build_object(
      'pack_code', target_pack.code,
      'opening_id', opening_result.opening_id,
      'pack_quantity_before', before_pack_quantity,
      'pack_quantity_after', after_pack_quantity
    )
  )
  returning id into created_pack_event_id;

  perform private.write_audit_log(
    actor_id,
    actor_id,
    null,
    'tcg_owner_owned_pack_consumed',
    'tcg_player_packs',
    pack_inventory_row.id,
    jsonb_build_object(
      'pack_code', target_pack.code,
      'opening_id', opening_result.opening_id,
      'pack_inventory_event_id', created_pack_event_id,
      'pack_quantity_before', before_pack_quantity,
      'pack_quantity_after', after_pack_quantity
    )
  );

  return query
  select
    opening_result.opening_id,
    opening_result.pack_code,
    opening_result.pack_name,
    opening_result.cards_opened,
    after_pack_quantity,
    opening_result.results,
    opening_result.created_at;
end;
$$;

revoke all on function public.tcg_get_my_packs() from public, anon;
revoke all on function public.tcg_owner_buy_test_pack_to_inventory(text) from public, anon;
revoke all on function public.tcg_owner_open_owned_pack(text) from public, anon;

grant execute on function public.tcg_get_my_packs() to authenticated;
grant execute on function public.tcg_owner_buy_test_pack_to_inventory(text) to authenticated;
grant execute on function public.tcg_owner_open_owned_pack(text) to authenticated;
