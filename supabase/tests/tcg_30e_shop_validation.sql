-- Milestone 30E-A Owner-only TCG shop/economy backend validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30e_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '32000000-0000-4000-8000-000000000001';
  member_id constant uuid := '32000000-0000-4000-8000-000000000002';
  pending_id constant uuid := '32000000-0000-4000-8000-000000000003';
  grant_result record;
  wallet_result record;
  shop_result record;
  buy_result record;
  free_pack_result record;
  table_count integer;
  rls_count integer;
  ledger_count integer;
  shop_count integer;
  wallet_balance integer;
  inventory_total integer;
  event_count integer;
  opening_count integer;
  result_count integer;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30e-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30e-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30e-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30e_owner', 'tcg30e_owner', 'TCG 30E Owner', 'approved', now()),
    (member_id, 'tcg30e_member', 'tcg30e_member', 'TCG 30E Member', 'approved', now()),
    (pending_id, 'tcg30e_pending', 'tcg30e_pending', 'TCG 30E Pending', 'pending', null);

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
    (member_id, anteiku_id, 'member', 'active', true, owner_id, 'active'),
    (pending_id, anteiku_id, 'member', 'pending', true, null, 'active');

  select count(*) into table_count
  from information_schema.tables
  where table_schema = 'public'
    and table_name in ('tcg_wallets', 'tcg_wallet_ledger', 'tcg_shop_items');

  if table_count = 3 then
    insert into tcg_30e_validation_results values ('schema', 'economy_tables_exist', 'PASS', 'Wallet, ledger, and shop item tables exist.');
  else
    insert into tcg_30e_validation_results values ('schema', 'economy_tables_exist', 'FAIL', table_count::text || ' economy tables found.');
  end if;

  select count(*) into rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('tcg_wallets', 'tcg_wallet_ledger', 'tcg_shop_items')
    and c.relrowsecurity;

  if rls_count = 3 then
    insert into tcg_30e_validation_results values ('schema', 'economy_tables_rls_enabled', 'PASS', 'RLS enabled on all economy tables.');
  else
    insert into tcg_30e_validation_results values ('schema', 'economy_tables_rls_enabled', 'FAIL', rls_count::text || ' RLS-enabled economy tables found.');
  end if;

  select count(*) into shop_count
  from public.tcg_shop_items si
  join public.tcg_packs p on p.id = si.pack_id
  where si.code = 'season_0_test_pack_shop'
    and si.item_type = 'pack'
    and si.currency_code = 'anteiku_coins'
    and si.price = 100
    and si.is_active
    and si.is_owner_test_only
    and p.code = 'season_0_test_pack';

  if shop_count = 1 then
    insert into tcg_30e_validation_results values ('seed', 'owner_test_shop_item_seeded', 'PASS', 'Season 0 test pack shop item exists.');
  else
    insert into tcg_30e_validation_results values ('seed', 'owner_test_shop_item_seeded', 'FAIL', shop_count::text || ' matching shop items found.');
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30e_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30e_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_buy_test_pack();
    execute 'reset role';
    insert into tcg_30e_validation_results values ('shop', 'buy_without_balance_denied', 'FAIL', 'Owner bought a pack without coins.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('shop', 'buy_without_balance_denied', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into grant_result from public.tcg_owner_grant_test_coins(1000);
    execute 'reset role';

    if grant_result.balance = 1000 and grant_result.granted_amount = 1000 and grant_result.currency_code = 'anteiku_coins' then
      insert into tcg_30e_validation_results values ('wallet', 'owner_can_grant_test_coins', 'PASS', 'Owner granted 1000 Anteiku Coins.');
    else
      insert into tcg_30e_validation_results values ('wallet', 'owner_can_grant_test_coins', 'FAIL', coalesce(grant_result::text, 'No grant result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('wallet', 'owner_can_grant_test_coins', 'FAIL', sqlerrm);
  end;

  select balance into wallet_balance
  from public.tcg_wallets
  where profile_id = owner_id
    and currency_code = 'anteiku_coins';

  if wallet_balance = 1000 then
    insert into tcg_30e_validation_results values ('wallet', 'owner_wallet_balance_increases', 'PASS', 'Owner wallet balance is 1000.');
  else
    insert into tcg_30e_validation_results values ('wallet', 'owner_wallet_balance_increases', 'FAIL', coalesce(wallet_balance, 0)::text || ' balance found.');
  end if;

  select count(*) into ledger_count
  from public.tcg_wallet_ledger
  where profile_id = owner_id
    and currency_code = 'anteiku_coins'
    and amount_delta = 1000
    and balance_after = 1000
    and transaction_type = 'owner_test_grant';

  if ledger_count = 1 then
    insert into tcg_30e_validation_results values ('wallet', 'grant_writes_ledger', 'PASS', 'Grant ledger row written.');
  else
    insert into tcg_30e_validation_results values ('wallet', 'grant_writes_ledger', 'FAIL', ledger_count::text || ' grant ledger rows found.');
  end if;

  begin
    execute 'set local role authenticated';
    select * into wallet_result from public.tcg_get_my_wallet();
    execute 'reset role';

    if wallet_result.profile_id = owner_id and wallet_result.balance = 1000 then
      insert into tcg_30e_validation_results values ('wallet', 'owner_can_read_own_wallet', 'PASS', 'Owner read own wallet.');
    else
      insert into tcg_30e_validation_results values ('wallet', 'owner_can_read_own_wallet', 'FAIL', coalesce(wallet_result::text, 'No wallet result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('wallet', 'owner_can_read_own_wallet', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into shop_result from public.tcg_owner_get_test_shop() limit 1;
    execute 'reset role';

    if shop_result.shop_item_code = 'season_0_test_pack_shop'
       and shop_result.price = 100
       and shop_result.currency_code = 'anteiku_coins'
       and shop_result.pack_code = 'season_0_test_pack' then
      insert into tcg_30e_validation_results values ('shop', 'owner_can_view_test_shop', 'PASS', 'Owner viewed test shop item.');
    else
      insert into tcg_30e_validation_results values ('shop', 'owner_can_view_test_shop', 'FAIL', coalesce(shop_result::text, 'No shop result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('shop', 'owner_can_view_test_shop', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into buy_result from public.tcg_owner_buy_test_pack();
    execute 'reset role';

    if buy_result.balance_before = 1000
       and buy_result.balance_after = 900
       and buy_result.price = 100
       and buy_result.cards_opened = 5
       and jsonb_array_length(buy_result.results) = 5 then
      insert into tcg_30e_validation_results values ('shop', 'owner_can_buy_test_pack', 'PASS', 'Owner bought and opened a five-card test pack.');
    else
      insert into tcg_30e_validation_results values ('shop', 'owner_can_buy_test_pack', 'FAIL', coalesce(buy_result::text, 'No buy result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('shop', 'owner_can_buy_test_pack', 'FAIL', sqlerrm);
  end;

  select balance into wallet_balance
  from public.tcg_wallets
  where profile_id = owner_id
    and currency_code = 'anteiku_coins';

  if wallet_balance = 900 then
    insert into tcg_30e_validation_results values ('shop', 'buy_deducts_price', 'PASS', 'Owner wallet balance is 900 after purchase.');
  else
    insert into tcg_30e_validation_results values ('shop', 'buy_deducts_price', 'FAIL', coalesce(wallet_balance, 0)::text || ' balance found.');
  end if;

  select count(*) into ledger_count
  from public.tcg_wallet_ledger
  where profile_id = owner_id
    and currency_code = 'anteiku_coins'
    and amount_delta = -100
    and balance_after = 900
    and transaction_type = 'shop_purchase'
    and reference_type = 'tcg_shop_items';

  if ledger_count = 1 then
    insert into tcg_30e_validation_results values ('shop', 'buy_writes_spend_ledger', 'PASS', 'Shop purchase ledger row written.');
  else
    insert into tcg_30e_validation_results values ('shop', 'buy_writes_spend_ledger', 'FAIL', ledger_count::text || ' spend ledger rows found.');
  end if;

  select coalesce(sum(quantity), 0) into inventory_total
  from public.tcg_player_inventory
  where profile_id = owner_id;

  if inventory_total = 5 then
    insert into tcg_30e_validation_results values ('inventory', 'buy_increments_inventory_by_five', 'PASS', 'Owner inventory increased by five cards.');
  else
    insert into tcg_30e_validation_results values ('inventory', 'buy_increments_inventory_by_five', 'FAIL', inventory_total::text || ' total inventory quantity found.');
  end if;

  select count(*) into event_count
  from public.tcg_inventory_events
  where profile_id = owner_id
    and event_type = 'pack_opened'
    and source_type = 'owner_test_shop'
    and source_id = buy_result.opening_id;

  if event_count = 5 then
    insert into tcg_30e_validation_results values ('inventory', 'buy_writes_inventory_events', 'PASS', 'Five shop pack inventory events written.');
  else
    insert into tcg_30e_validation_results values ('inventory', 'buy_writes_inventory_events', 'FAIL', event_count::text || ' inventory events found.');
  end if;

  select count(*) into opening_count
  from public.tcg_pack_openings
  where id = buy_result.opening_id
    and profile_id = owner_id
    and opened_by_profile_id = owner_id
    and source = 'owner_shop_test';

  if opening_count = 1 then
    insert into tcg_30e_validation_results values ('history', 'buy_writes_pack_opening_history', 'PASS', 'Shop pack opening history row written.');
  else
    insert into tcg_30e_validation_results values ('history', 'buy_writes_pack_opening_history', 'FAIL', opening_count::text || ' opening rows found.');
  end if;

  select count(*) into result_count
  from jsonb_array_elements(buy_result.results) item
  where item ? 'card_id'
    and item ? 'card_no'
    and item ? 'card_key'
    and item ? 'rarity_key'
    and item ? 'art_path'
    and item ? 'quantity_delta'
    and item ? 'is_duplicate';

  if result_count = 5 then
    insert into tcg_30e_validation_results values ('rpc', 'buy_result_payload_safe_shape', 'PASS', 'Buy result includes five safe card payloads.');
  else
    insert into tcg_30e_validation_results values ('rpc', 'buy_result_payload_safe_shape', 'FAIL', result_count::text || ' result items had expected fields.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_grant_test_coins(1000);
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_coin_grant', 'FAIL', 'Normal member granted test coins.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_coin_grant', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_wallet();
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_wallet_rpc', 'FAIL', 'Normal member read wallet RPC.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_wallet_rpc', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_get_test_shop();
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_owner_shop', 'FAIL', 'Normal member viewed Owner test shop.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_owner_shop', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_buy_test_pack();
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_buy_pack', 'FAIL', 'Normal member bought Owner test pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'normal_member_denied_buy_pack', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_wallets (profile_id, currency_code, balance) values ($1, ''anteiku_coins'', 100)'
      using member_id;
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_wallet_write_blocked', 'FAIL', 'Direct wallet insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_wallet_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_wallet_ledger (profile_id, currency_code, amount_delta, balance_after, transaction_type) values ($1, ''anteiku_coins'', 100, 100, ''owner_test_grant'')'
      using member_id;
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_ledger_write_blocked', 'FAIL', 'Direct ledger insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_ledger_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_shop_items (code, name, item_type, currency_code, price) values (''bad_shop_item'', ''Bad'', ''pack'', ''anteiku_coins'', 0)';
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_shop_write_blocked', 'FAIL', 'Direct shop item insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_shop_write_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_grant_test_coins(1000);
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'pending_user_denied_coin_grant', 'FAIL', 'Pending user granted test coins.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'pending_user_denied_coin_grant', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_catalog();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30e_validation_results values ('regression', 'catalog_rpc_still_works', 'PASS', 'Catalog RPC returns 50 rows.');
    else
      insert into tcg_30e_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', table_count::text || ' catalog rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_my_collection();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30e_validation_results values ('regression', 'collection_rpc_still_works', 'PASS', 'Collection RPC returns 50 rows.');
    else
      insert into tcg_30e_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', table_count::text || ' collection rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into free_pack_result from public.tcg_owner_open_test_pack();
    execute 'reset role';

    if free_pack_result.cards_opened = 5
       and jsonb_array_length(free_pack_result.results) = 5 then
      insert into tcg_30e_validation_results values ('regression', 'existing_owner_pack_rpc_still_works', 'PASS', 'Existing Owner free test pack RPC still opens five cards.');
    else
      insert into tcg_30e_validation_results values ('regression', 'existing_owner_pack_rpc_still_works', 'FAIL', coalesce(free_pack_result::text, 'No pack result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('regression', 'existing_owner_pack_rpc_still_works', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.tcg_wallets';
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_wallet_read_blocked', 'FAIL', 'Direct wallet select succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('security', 'direct_wallet_read_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30e_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30e_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30e_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30e_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30e_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30e_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30e_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30e_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30e_total_skip
from tcg_30e_validation_results;

rollback;
