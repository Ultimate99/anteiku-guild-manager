-- Milestone 30G-I0 Owner-only TCG test state reset validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30gi0_reset_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '3b000000-0000-4000-8000-000000000001';
  member_id constant uuid := '3b000000-0000-4000-8000-000000000002';
  target_card_id uuid;
  target_pack_id uuid;
  target_set_id uuid;
  result_row record;
  function_args text;
  definition_counts_before jsonb;
  definition_counts_after jsonb;
  owner_rows_after integer;
  member_rows_after integer;
  cp_named_column_count integer;
  owner_count integer;
begin
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30gi0-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30gi0-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30gi0_owner', 'tcg30gi0_owner', 'TCG 30G-I0 Owner', 'approved', now()),
    (member_id, 'tcg30gi0_member', 'tcg30gi0_member', 'TCG 30G-I0 Member', 'approved', now());

  insert into public.guild_memberships (
    profile_id,
    guild_id,
    role,
    membership_status,
    is_primary,
    assigned_by,
    roster_status
  )
  values
    (owner_id, anteiku_id, 'owner', 'active', true, owner_id, 'active'),
    (member_id, anteiku_id, 'member', 'active', true, owner_id, 'active');

  select c.id
  into target_card_id
  from public.tcg_cards c
  order by c.sort_order
  limit 1;

  select p.id, p.set_id
  into target_pack_id, target_set_id
  from public.tcg_packs p
  where p.code = 'season_0_test_pack'
  limit 1;

  select jsonb_build_object(
    'sets', (select count(*) from public.tcg_sets),
    'rarities', (select count(*) from public.tcg_rarities),
    'cards', (select count(*) from public.tcg_cards),
    'packs', (select count(*) from public.tcg_packs),
    'drop_rates', (select count(*) from public.tcg_pack_drop_rates),
    'shop_items', (select count(*) from public.tcg_shop_items),
    'crafting_rules', (select count(*) from public.tcg_crafting_rules)
  )
  into definition_counts_before;

  insert into public.tcg_player_inventory (profile_id, card_id, quantity, first_acquired_at, last_acquired_at)
  values
    (owner_id, target_card_id, 2, now(), now()),
    (member_id, target_card_id, 2, now(), now());

  insert into public.tcg_inventory_events (
    profile_id,
    card_id,
    quantity_delta,
    event_type,
    source_type,
    actor_user_id,
    actor_profile_id,
    reason
  )
  values
    (owner_id, target_card_id, 1, 'admin_grant', 'admin_tool', owner_id, owner_id, '30G-I0 local reset validation'),
    (member_id, target_card_id, 1, 'admin_grant', 'admin_tool', owner_id, owner_id, '30G-I0 local reset validation');

  insert into public.tcg_player_packs (profile_id, pack_id, quantity, first_obtained_at)
  values
    (owner_id, target_pack_id, 1, now()),
    (member_id, target_pack_id, 1, now());

  insert into public.tcg_pack_inventory_events (
    profile_id,
    pack_id,
    quantity_delta,
    event_type,
    source,
    actor_profile_id
  )
  values
    (owner_id, target_pack_id, 1, 'owner_test_shop_purchase', '30g_i0_validation', owner_id),
    (member_id, target_pack_id, 1, 'owner_test_shop_purchase', '30g_i0_validation', owner_id);

  insert into public.tcg_pack_openings (profile_id, pack_id, opened_by_profile_id, results, source)
  values
    (owner_id, target_pack_id, owner_id, '[]'::jsonb, 'owner_test'),
    (member_id, target_pack_id, member_id, '[]'::jsonb, 'owner_test');

  insert into public.tcg_wallets (profile_id, currency_code, balance)
  values
    (owner_id, 'anteiku_coins', 100),
    (member_id, 'anteiku_coins', 100);

  insert into public.tcg_wallet_ledger (
    profile_id,
    currency_code,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    actor_profile_id
  )
  values
    (owner_id, 'anteiku_coins', 100, 100, 'owner_test_grant', '30g_i0_validation', owner_id),
    (member_id, 'anteiku_coins', 100, 100, 'owner_test_grant', '30g_i0_validation', owner_id);

  insert into public.tcg_fragment_wallets (profile_id, balance)
  values
    (owner_id, 10),
    (member_id, 10);

  insert into public.tcg_fragment_ledger (
    profile_id,
    amount_delta,
    balance_after,
    transaction_type,
    source,
    card_id,
    actor_profile_id
  )
  values
    (owner_id, 10, 10, 'duplicate_burn', '30g_i0_validation', target_card_id, owner_id),
    (member_id, 10, 10, 'duplicate_burn', '30g_i0_validation', target_card_id, owner_id);

  insert into public.tcg_pity_counters (
    profile_id,
    set_id,
    pack_id,
    packs_since_legendary,
    packs_since_mythic,
    total_eligible_openings
  )
  values
    (owner_id, target_set_id, target_pack_id, 3, 3, 3),
    (member_id, target_set_id, target_pack_id, 3, 3, 3);

  select pg_get_function_arguments(p.oid)
  into function_args
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'tcg_owner_reset_my_tcg_test_state';

  if function_args = 'p_confirm text' then
    insert into tcg_30gi0_reset_validation_results values ('security', 'reset_rpc_has_no_profile_id_arg', 'PASS', function_args);
  else
    insert into tcg_30gi0_reset_validation_results values ('security', 'reset_rpc_has_no_profile_id_arg', 'FAIL', coalesce(function_args, 'Function not found.'));
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_reset_my_tcg_test_state('WRONG');
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('rpc', 'wrong_confirmation_rejected', 'FAIL', 'Reset succeeded with wrong confirmation.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('rpc', 'wrong_confirmation_rejected', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_reset_my_tcg_test_state('RESET_TCG');
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('security', 'member_reset_rejected', 'FAIL', 'Member reset succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('security', 'member_reset_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'delete from public.tcg_wallets where profile_id = $1' using member_id;
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('security', 'direct_wallet_delete_blocked', 'FAIL', 'Authenticated direct wallet delete succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('security', 'direct_wallet_delete_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into result_row
    from public.tcg_owner_reset_my_tcg_test_state('RESET_TCG');
    execute 'reset role';

    if result_row.reset_profile_id = owner_id
       and result_row.inventory_deleted = 1
       and result_row.inventory_events_deleted = 1
       and result_row.player_packs_deleted = 1
       and result_row.pack_inventory_events_deleted = 1
       and result_row.pack_openings_deleted = 1
       and result_row.wallets_deleted = 1
       and result_row.wallet_ledger_deleted = 1
       and result_row.fragment_wallets_deleted = 1
       and result_row.fragment_ledger_deleted = 1
       and result_row.pity_counters_deleted = 1 then
      insert into tcg_30gi0_reset_validation_results values ('rpc', 'owner_reset_succeeds_with_counts', 'PASS', result_row::text);
    else
      insert into tcg_30gi0_reset_validation_results values ('rpc', 'owner_reset_succeeds_with_counts', 'FAIL', coalesce(result_row::text, 'No reset result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gi0_reset_validation_results values ('rpc', 'owner_reset_succeeds_with_counts', 'FAIL', sqlerrm);
  end;

  select
    (select count(*) from public.tcg_player_inventory where profile_id = owner_id) +
    (select count(*) from public.tcg_inventory_events where profile_id = owner_id) +
    (select count(*) from public.tcg_player_packs where profile_id = owner_id) +
    (select count(*) from public.tcg_pack_inventory_events where profile_id = owner_id) +
    (select count(*) from public.tcg_pack_openings where profile_id = owner_id) +
    (select count(*) from public.tcg_wallets where profile_id = owner_id) +
    (select count(*) from public.tcg_wallet_ledger where profile_id = owner_id) +
    (select count(*) from public.tcg_fragment_wallets where profile_id = owner_id) +
    (select count(*) from public.tcg_fragment_ledger where profile_id = owner_id) +
    (select count(*) from public.tcg_pity_counters where profile_id = owner_id)
  into owner_rows_after;

  if owner_rows_after = 0 then
    insert into tcg_30gi0_reset_validation_results values ('scope', 'owner_tcg_rows_cleared', 'PASS', 'Owner mutable TCG rows were cleared.');
  else
    insert into tcg_30gi0_reset_validation_results values ('scope', 'owner_tcg_rows_cleared', 'FAIL', owner_rows_after::text || ' Owner TCG rows remain.');
  end if;

  select
    (select count(*) from public.tcg_player_inventory where profile_id = member_id) +
    (select count(*) from public.tcg_inventory_events where profile_id = member_id) +
    (select count(*) from public.tcg_player_packs where profile_id = member_id) +
    (select count(*) from public.tcg_pack_inventory_events where profile_id = member_id) +
    (select count(*) from public.tcg_pack_openings where profile_id = member_id) +
    (select count(*) from public.tcg_wallets where profile_id = member_id) +
    (select count(*) from public.tcg_wallet_ledger where profile_id = member_id) +
    (select count(*) from public.tcg_fragment_wallets where profile_id = member_id) +
    (select count(*) from public.tcg_fragment_ledger where profile_id = member_id) +
    (select count(*) from public.tcg_pity_counters where profile_id = member_id)
  into member_rows_after;

  if member_rows_after = 10 then
    insert into tcg_30gi0_reset_validation_results values ('scope', 'other_profile_tcg_rows_preserved', 'PASS', 'Member profile TCG rows were not reset.');
  else
    insert into tcg_30gi0_reset_validation_results values ('scope', 'other_profile_tcg_rows_preserved', 'FAIL', member_rows_after::text || ' member rows remain.');
  end if;

  select jsonb_build_object(
    'sets', (select count(*) from public.tcg_sets),
    'rarities', (select count(*) from public.tcg_rarities),
    'cards', (select count(*) from public.tcg_cards),
    'packs', (select count(*) from public.tcg_packs),
    'drop_rates', (select count(*) from public.tcg_pack_drop_rates),
    'shop_items', (select count(*) from public.tcg_shop_items),
    'crafting_rules', (select count(*) from public.tcg_crafting_rules)
  )
  into definition_counts_after;

  if definition_counts_after = definition_counts_before then
    insert into tcg_30gi0_reset_validation_results values ('scope', 'catalog_definition_rows_preserved', 'PASS', 'Catalog/drop-rate/shop/crafting definitions were unchanged.');
  else
    insert into tcg_30gi0_reset_validation_results values ('scope', 'catalog_definition_rows_preserved', 'FAIL', format('before=%s after=%s', definition_counts_before, definition_counts_after));
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30gi0_reset_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30gi0_reset_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  select count(*)
  into owner_count
  from public.guild_memberships
  where role = 'owner'
    and membership_status = 'active';

  if owner_count = 1 then
    insert into tcg_30gi0_reset_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'One active Owner remains.');
  else
    insert into tcg_30gi0_reset_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active Owners found.');
  end if;
end;
$$;

select *
from tcg_30gi0_reset_validation_results
order by
  case status when 'FAIL' then 1 when 'SKIP' then 2 else 3 end,
  section,
  test_name;

select count(*) filter (where status = 'PASS') as tcg_30gi0_reset_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30gi0_reset_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30gi0_reset_total_skip
from tcg_30gi0_reset_validation_results;

rollback;
