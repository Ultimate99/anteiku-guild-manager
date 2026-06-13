-- Milestone 30G-F2: TCG soft pity backend integration.
-- Backend/RPC/RLS only. No frontend UI, no drop-rate/price/pack-size changes.
-- Pity starts from zero after this migration; existing Owner test openings are not backfilled.

create table if not exists public.tcg_pity_counters (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  set_id uuid not null references public.tcg_sets(id) on delete restrict,
  pack_id uuid not null references public.tcg_packs(id) on delete restrict,
  packs_since_legendary integer not null default 0 check (packs_since_legendary >= 0),
  packs_since_mythic integer not null default 0 check (packs_since_mythic >= 0),
  total_eligible_openings integer not null default 0 check (total_eligible_openings >= 0),
  last_legendary_at timestamptz,
  last_mythic_at timestamptz,
  last_eligible_opening_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_pity_counters_profile_set_pack_uidx unique (profile_id, set_id, pack_id)
);

create index if not exists tcg_pity_counters_profile_idx
  on public.tcg_pity_counters (profile_id, updated_at desc);

create index if not exists tcg_pity_counters_pack_idx
  on public.tcg_pity_counters (pack_id, updated_at desc);

drop trigger if exists set_tcg_pity_counters_updated_at on public.tcg_pity_counters;
create trigger set_tcg_pity_counters_updated_at
before update on public.tcg_pity_counters
for each row
execute function public.set_updated_at();

alter table public.tcg_pity_counters enable row level security;

revoke all on public.tcg_pity_counters from public, anon, authenticated;

create or replace function public.tcg_get_my_pity_status()
returns table (
  profile_id uuid,
  pack_id uuid,
  pack_code text,
  pack_name text,
  set_id uuid,
  set_code text,
  set_name text,
  packs_since_legendary integer,
  legendary_threshold integer,
  legendary_remaining integer,
  packs_since_mythic integer,
  mythic_threshold integer,
  mythic_remaining integer,
  total_eligible_openings integer,
  last_legendary_at timestamptz,
  last_mythic_at timestamptz,
  last_eligible_opening_at timestamptz
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
    p.id,
    p.code,
    p.name,
    s.id,
    s.set_key,
    s.name,
    coalesce(pc.packs_since_legendary, 0)::integer,
    50,
    greatest(50 - coalesce(pc.packs_since_legendary, 0), 0)::integer,
    coalesce(pc.packs_since_mythic, 0)::integer,
    150,
    greatest(150 - coalesce(pc.packs_since_mythic, 0), 0)::integer,
    coalesce(pc.total_eligible_openings, 0)::integer,
    pc.last_legendary_at,
    pc.last_mythic_at,
    pc.last_eligible_opening_at
  from public.tcg_packs p
  join public.tcg_sets s on s.id = p.set_id
  left join public.tcg_pity_counters pc
    on pc.profile_id = actor_id
   and pc.set_id = s.id
   and pc.pack_id = p.id
  where p.is_active
    and p.is_owner_test_only
    and s.release_status = 'active'
  order by s.sort_order asc, p.created_at asc, p.code asc;
end;
$$;

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
  count_for_pity boolean := false;
  pity_row record;
  pity_triggered_legendary boolean := false;
  pity_triggered_mythic boolean := false;
  guaranteed_rarity_code text;
  item_is_pity_guaranteed boolean;
  has_legendary_or_better boolean := false;
  has_mythic boolean := false;
  pity_status_after jsonb := null;
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

  -- Only owned-pack openings count for pity. Free Owner test packs and legacy
  -- immediate buy-and-open calls do not include this server-side marker.
  count_for_pity := coalesce(merged_metadata ->> 'pack_inventory_source', '') = 'owned_pack_inventory';

  if count_for_pity then
    insert into public.tcg_pity_counters (
      profile_id,
      set_id,
      pack_id
    )
    values (
      p_actor_profile_id,
      target_pack.set_id,
      target_pack.id
    )
    on conflict on constraint tcg_pity_counters_profile_set_pack_uidx do nothing;

    select *
    into pity_row
    from public.tcg_pity_counters pc
    where pc.profile_id = p_actor_profile_id
      and pc.set_id = target_pack.set_id
      and pc.pack_id = target_pack.id
    for update;

    if coalesce(pity_row.packs_since_mythic, 0) >= 150 then
      guaranteed_rarity_code := 'mythic';
      pity_triggered_mythic := true;
    elsif coalesce(pity_row.packs_since_legendary, 0) >= 50 then
      guaranteed_rarity_code := 'legendary';
      pity_triggered_legendary := true;
    end if;
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
    item_is_pity_guaranteed := item_index = 1 and guaranteed_rarity_code is not null;

    if item_is_pity_guaranteed then
      chosen_rarity_code := guaranteed_rarity_code;
    else
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
    end if;

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

    if chosen_card.rarity_key = 'mythic' then
      has_mythic := true;
      has_legendary_or_better := true;
    elsif chosen_card.rarity_key = 'legendary' then
      has_legendary_or_better := true;
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
        'new_quantity', resulting_quantity,
        'is_pity_guaranteed', item_is_pity_guaranteed,
        'pity_guaranteed_rarity', case when item_is_pity_guaranteed then guaranteed_rarity_code else null end
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
        'is_duplicate', previous_quantity > 0,
        'is_pity_guaranteed', item_is_pity_guaranteed,
        'pity_guaranteed_rarity', case when item_is_pity_guaranteed then guaranteed_rarity_code else null end
      )
    );
  end loop;

  if count_for_pity then
    if has_mythic then
      update public.tcg_pity_counters
      set packs_since_legendary = 0,
          packs_since_mythic = 0,
          total_eligible_openings = total_eligible_openings + 1,
          last_legendary_at = now(),
          last_mythic_at = now(),
          last_eligible_opening_at = now(),
          updated_at = now()
      where profile_id = p_actor_profile_id
        and set_id = target_pack.set_id
        and pack_id = target_pack.id
      returning jsonb_build_object(
        'packs_since_legendary', packs_since_legendary,
        'legendary_threshold', 50,
        'legendary_remaining', greatest(50 - packs_since_legendary, 0),
        'packs_since_mythic', packs_since_mythic,
        'mythic_threshold', 150,
        'mythic_remaining', greatest(150 - packs_since_mythic, 0),
        'total_eligible_openings', total_eligible_openings,
        'last_legendary_at', last_legendary_at,
        'last_mythic_at', last_mythic_at,
        'last_eligible_opening_at', last_eligible_opening_at
      ) into pity_status_after;
    elsif has_legendary_or_better then
      update public.tcg_pity_counters
      set packs_since_legendary = 0,
          packs_since_mythic = packs_since_mythic + 1,
          total_eligible_openings = total_eligible_openings + 1,
          last_legendary_at = now(),
          last_eligible_opening_at = now(),
          updated_at = now()
      where profile_id = p_actor_profile_id
        and set_id = target_pack.set_id
        and pack_id = target_pack.id
      returning jsonb_build_object(
        'packs_since_legendary', packs_since_legendary,
        'legendary_threshold', 50,
        'legendary_remaining', greatest(50 - packs_since_legendary, 0),
        'packs_since_mythic', packs_since_mythic,
        'mythic_threshold', 150,
        'mythic_remaining', greatest(150 - packs_since_mythic, 0),
        'total_eligible_openings', total_eligible_openings,
        'last_legendary_at', last_legendary_at,
        'last_mythic_at', last_mythic_at,
        'last_eligible_opening_at', last_eligible_opening_at
      ) into pity_status_after;
    else
      update public.tcg_pity_counters
      set packs_since_legendary = packs_since_legendary + 1,
          packs_since_mythic = packs_since_mythic + 1,
          total_eligible_openings = total_eligible_openings + 1,
          last_eligible_opening_at = now(),
          updated_at = now()
      where profile_id = p_actor_profile_id
        and set_id = target_pack.set_id
        and pack_id = target_pack.id
      returning jsonb_build_object(
        'packs_since_legendary', packs_since_legendary,
        'legendary_threshold', 50,
        'legendary_remaining', greatest(50 - packs_since_legendary, 0),
        'packs_since_mythic', packs_since_mythic,
        'mythic_threshold', 150,
        'mythic_remaining', greatest(150 - packs_since_mythic, 0),
        'total_eligible_openings', total_eligible_openings,
        'last_legendary_at', last_legendary_at,
        'last_mythic_at', last_mythic_at,
        'last_eligible_opening_at', last_eligible_opening_at
      ) into pity_status_after;
    end if;
  end if;

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
      'owner_test_only', true,
      'pity_eligible', count_for_pity,
      'pity_triggered_legendary', pity_triggered_legendary,
      'pity_triggered_mythic', pity_triggered_mythic,
      'pity_status_after', pity_status_after
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

revoke all on function public.tcg_get_my_pity_status() from public, anon;
revoke all on function private.tcg_open_owner_test_pack_for_profile(uuid, uuid, text, text, text, text, text, jsonb)
  from public, anon, authenticated;

grant execute on function public.tcg_get_my_pity_status() to authenticated;
