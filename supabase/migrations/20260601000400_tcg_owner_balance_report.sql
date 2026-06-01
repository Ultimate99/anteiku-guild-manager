-- Milestone 30F-A: Owner-only TCG economy / pack analytics backend.
-- Read-only analytics RPC. No pricing, drop-rate, wallet, inventory, or CP changes.

create or replace function public.tcg_owner_get_balance_report()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.active_admin_profile_id();
  collection_summary jsonb;
  rarity_ownership_summary jsonb;
  pack_opening_summary jsonb;
  rarity_pull_summary jsonb;
  economy_summary jsonb;
  duplicate_pressure_summary jsonb;
  balance_hints jsonb;
begin
  if actor_id is null then
    raise exception 'Active Owner profile is required.';
  end if;

  if not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  with active_cards as (
    select
      c.id,
      c.card_key,
      c.card_no,
      c.name as card_name,
      c.sort_order,
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order
    from public.tcg_cards c
    join public.tcg_sets s on s.id = c.set_id
    join public.tcg_rarities r on r.id = c.rarity_id
    where s.release_status = 'active'
      and c.release_status = 'active'
      and c.is_collectible = true
  ),
  inventory as (
    select
      ac.*,
      coalesce(inv.quantity, 0) as quantity,
      coalesce(inv.is_favorite, false) as is_favorite,
      inv.first_acquired_at,
      inv.last_acquired_at
    from active_cards ac
    left join public.tcg_player_inventory inv
      on inv.card_id = ac.id
     and inv.profile_id = actor_id
  ),
  summary as (
    select
      count(*)::integer as total_cards_in_catalog,
      count(*) filter (where quantity > 0)::integer as unique_owned,
      count(*) filter (where quantity <= 0)::integer as missing_cards,
      coalesce(sum(quantity), 0)::integer as total_quantity_owned,
      coalesce(sum(greatest(quantity - 1, 0)), 0)::integer as duplicate_quantity_total,
      count(*) filter (where is_favorite and quantity > 0)::integer as favorites_count
    from inventory
  )
  select jsonb_build_object(
    'total_cards_in_catalog', total_cards_in_catalog,
    'unique_owned', unique_owned,
    'missing_cards', missing_cards,
    'total_quantity_owned', total_quantity_owned,
    'duplicate_quantity_total', duplicate_quantity_total,
    'completion_percent', case
      when total_cards_in_catalog = 0 then 0
      else round((unique_owned::numeric / total_cards_in_catalog::numeric) * 100, 2)
    end,
    'favorites_count', favorites_count
  )
  into collection_summary
  from summary;

  with active_cards as (
    select
      c.id,
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order
    from public.tcg_cards c
    join public.tcg_sets s on s.id = c.set_id
    join public.tcg_rarities r on r.id = c.rarity_id
    where s.release_status = 'active'
      and c.release_status = 'active'
      and c.is_collectible = true
  ),
  rarity_catalog as (
    select
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order,
      count(ac.id)::integer as catalog_count
    from public.tcg_rarities r
    left join active_cards ac on ac.rarity_key = r.rarity_key
    group by r.rarity_key, r.name, r.sort_order
  ),
  rarity_inventory as (
    select
      ac.rarity_key,
      count(*) filter (where coalesce(inv.quantity, 0) > 0)::integer as unique_owned,
      coalesce(sum(coalesce(inv.quantity, 0)), 0)::integer as total_quantity_owned,
      coalesce(sum(greatest(coalesce(inv.quantity, 0) - 1, 0)), 0)::integer as duplicate_quantity
    from active_cards ac
    left join public.tcg_player_inventory inv
      on inv.card_id = ac.id
     and inv.profile_id = actor_id
    group by ac.rarity_key
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'rarity_code', rc.rarity_key,
        'rarity_name', rc.rarity_name,
        'catalog_count', rc.catalog_count,
        'unique_owned', coalesce(ri.unique_owned, 0),
        'total_quantity_owned', coalesce(ri.total_quantity_owned, 0),
        'missing_count', greatest(rc.catalog_count - coalesce(ri.unique_owned, 0), 0),
        'duplicate_quantity', coalesce(ri.duplicate_quantity, 0),
        'completion_percent', case
          when rc.catalog_count = 0 then 0
          else round((coalesce(ri.unique_owned, 0)::numeric / rc.catalog_count::numeric) * 100, 2)
        end
      )
      order by rc.rarity_sort_order, rc.rarity_key
    ),
    '[]'::jsonb
  )
  into rarity_ownership_summary
  from rarity_catalog rc
  left join rarity_inventory ri on ri.rarity_key = rc.rarity_key;

  with openings as (
    select
      po.id,
      po.source,
      po.results,
      po.created_at
    from public.tcg_pack_openings po
    where po.profile_id = actor_id
  ),
  summary as (
    select
      count(*)::integer as total_pack_openings,
      coalesce(sum(jsonb_array_length(results)), 0)::integer as total_cards_pulled,
      count(*) filter (where source in ('owner_test', 'owner_shop_test'))::integer as test_pack_openings,
      count(*) filter (where source = 'owner_shop_test')::integer as shop_pack_openings,
      count(*) filter (where source = 'owner_test')::integer as free_test_pack_openings,
      max(created_at) as last_pack_opened_at
    from openings
  )
  select jsonb_build_object(
    'total_pack_openings', total_pack_openings,
    'total_cards_pulled', total_cards_pulled,
    'test_pack_openings', test_pack_openings,
    'shop_pack_openings', shop_pack_openings,
    'free_test_pack_openings', free_test_pack_openings,
    'last_pack_opened_at', last_pack_opened_at
  )
  into pack_opening_summary
  from summary;

  with active_cards as (
    select
      c.id,
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order
    from public.tcg_cards c
    join public.tcg_sets s on s.id = c.set_id
    join public.tcg_rarities r on r.id = c.rarity_id
    where s.release_status = 'active'
      and c.release_status = 'active'
      and c.is_collectible = true
  ),
  rarity_catalog as (
    select
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order,
      count(ac.id)::integer as catalog_count
    from public.tcg_rarities r
    left join active_cards ac on ac.rarity_key = r.rarity_key
    group by r.rarity_key, r.name, r.sort_order
  ),
  pulls as (
    select
      ac.rarity_key,
      coalesce(sum(greatest(ie.quantity_delta, 0)), 0)::integer as pulled_quantity
    from public.tcg_inventory_events ie
    join active_cards ac on ac.id = ie.card_id
    where ie.profile_id = actor_id
      and ie.event_type = 'pack_opened'
      and ie.quantity_delta > 0
    group by ac.rarity_key
  ),
  owned as (
    select
      ac.rarity_key,
      count(*) filter (where coalesce(inv.quantity, 0) > 0)::integer as owned_unique
    from active_cards ac
    left join public.tcg_player_inventory inv
      on inv.card_id = ac.id
     and inv.profile_id = actor_id
    group by ac.rarity_key
  ),
  total as (
    select coalesce(sum(pulled_quantity), 0)::integer as total_pulled
    from pulls
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'rarity_code', rc.rarity_key,
        'rarity_name', rc.rarity_name,
        'pulled_quantity', coalesce(p.pulled_quantity, 0),
        'pull_percent', case
          when total.total_pulled = 0 then 0
          else round((coalesce(p.pulled_quantity, 0)::numeric / total.total_pulled::numeric) * 100, 2)
        end,
        'catalog_count', rc.catalog_count,
        'owned_unique', coalesce(o.owned_unique, 0)
      )
      order by rc.rarity_sort_order, rc.rarity_key
    ),
    '[]'::jsonb
  )
  into rarity_pull_summary
  from rarity_catalog rc
  cross join total
  left join pulls p on p.rarity_key = rc.rarity_key
  left join owned o on o.rarity_key = rc.rarity_key;

  with wallet as (
    select coalesce(max(balance), 0)::integer as current_balance
    from public.tcg_wallets
    where profile_id = actor_id
      and currency_code = 'anteiku_coins'
  ),
  ledger as (
    select
      coalesce(sum(amount_delta) filter (where transaction_type = 'owner_test_grant' and amount_delta > 0), 0)::integer as total_coins_granted,
      abs(coalesce(sum(amount_delta) filter (where amount_delta < 0), 0))::integer as total_coins_spent,
      coalesce(sum(amount_delta), 0)::integer as total_coin_delta,
      abs(coalesce(sum(amount_delta) filter (where transaction_type = 'shop_purchase' and amount_delta < 0), 0))::integer as total_pack_purchase_spend,
      count(*) filter (where transaction_type = 'shop_purchase' and amount_delta < 0)::integer as pack_purchase_count
    from public.tcg_wallet_ledger
    where profile_id = actor_id
      and currency_code = 'anteiku_coins'
  )
  select jsonb_build_object(
    'current_balance', wallet.current_balance,
    'currency_code', 'anteiku_coins',
    'total_coins_granted', ledger.total_coins_granted,
    'total_coins_spent', ledger.total_coins_spent,
    'total_coin_delta', ledger.total_coin_delta,
    'total_pack_purchase_spend', ledger.total_pack_purchase_spend,
    'average_spend_per_pack', case
      when ledger.pack_purchase_count = 0 then 0
      else round(ledger.total_pack_purchase_spend::numeric / ledger.pack_purchase_count::numeric, 2)
    end
  )
  into economy_summary
  from wallet
  cross join ledger;

  with active_cards as (
    select
      c.id,
      c.card_key,
      c.card_no,
      c.name as card_name,
      c.sort_order,
      r.rarity_key,
      r.name as rarity_name,
      r.sort_order as rarity_sort_order
    from public.tcg_cards c
    join public.tcg_sets s on s.id = c.set_id
    join public.tcg_rarities r on r.id = c.rarity_id
    where s.release_status = 'active'
      and c.release_status = 'active'
      and c.is_collectible = true
  ),
  inventory as (
    select
      ac.*,
      coalesce(inv.quantity, 0) as quantity,
      inv.first_acquired_at,
      inv.last_acquired_at
    from active_cards ac
    left join public.tcg_player_inventory inv
      on inv.card_id = ac.id
     and inv.profile_id = actor_id
  ),
  duplicated as (
    select *
    from inventory
    where quantity > 1
    order by (quantity - 1) desc, quantity desc, rarity_sort_order desc, card_no asc
    limit 10
  ),
  missing as (
    select *
    from inventory
    where quantity <= 0
    order by rarity_sort_order desc, sort_order asc, card_no asc
  ),
  newest as (
    select *
    from inventory
    where quantity > 0
    order by last_acquired_at desc nulls last, first_acquired_at desc nulls last, card_no asc
    limit 10
  )
  select jsonb_build_object(
    'most_duplicated_cards', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'card_no', card_no,
          'card_key', card_key,
          'card_name', card_name,
          'rarity_code', rarity_key,
          'rarity_name', rarity_name,
          'quantity', quantity,
          'duplicate_quantity', greatest(quantity - 1, 0)
        )
        order by (quantity - 1) desc, quantity desc, rarity_sort_order desc, card_no asc
      )
      from duplicated
    ), '[]'::jsonb),
    'missing_cards', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'card_no', card_no,
          'card_key', card_key,
          'card_name', card_name,
          'rarity_code', rarity_key,
          'rarity_name', rarity_name
        )
        order by rarity_sort_order desc, sort_order asc, card_no asc
      )
      from missing
    ), '[]'::jsonb),
    'cards_never_obtained_count', (select count(*)::integer from missing),
    'newest_obtained_cards', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'card_no', card_no,
          'card_key', card_key,
          'card_name', card_name,
          'rarity_code', rarity_key,
          'rarity_name', rarity_name,
          'quantity', quantity,
          'last_acquired_at', last_acquired_at
        )
        order by last_acquired_at desc nulls last, first_acquired_at desc nulls last, card_no asc
      )
      from newest
    ), '[]'::jsonb)
  )
  into duplicate_pressure_summary;

  balance_hints := jsonb_build_object(
    'duplicate_rate_percent', case
      when (collection_summary->>'total_quantity_owned')::numeric = 0 then 0
      else round(((collection_summary->>'duplicate_quantity_total')::numeric / (collection_summary->>'total_quantity_owned')::numeric) * 100, 2)
    end,
    'missing_card_percent', case
      when (collection_summary->>'total_cards_in_catalog')::numeric = 0 then 0
      else round(((collection_summary->>'missing_cards')::numeric / (collection_summary->>'total_cards_in_catalog')::numeric) * 100, 2)
    end,
    'average_cards_per_opening', case
      when (pack_opening_summary->>'total_pack_openings')::numeric = 0 then 0
      else round((pack_opening_summary->>'total_cards_pulled')::numeric / (pack_opening_summary->>'total_pack_openings')::numeric, 2)
    end
  );

  return jsonb_build_object(
    'generated_at', now(),
    'profile_id', actor_id,
    'collection_summary', collection_summary,
    'rarity_ownership_summary', rarity_ownership_summary,
    'pack_opening_summary', pack_opening_summary,
    'rarity_pull_summary', rarity_pull_summary,
    'economy_summary', economy_summary,
    'duplicate_pressure_summary', duplicate_pressure_summary,
    'balance_hints', balance_hints
  );
end;
$$;

revoke all on function public.tcg_owner_get_balance_report() from public, anon;
grant execute on function public.tcg_owner_get_balance_report() to authenticated;
