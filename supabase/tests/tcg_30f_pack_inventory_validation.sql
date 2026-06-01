-- Milestone 30F-B Owner-only TCG pack inventory validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30fb_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '37000000-0000-4000-8000-000000000001';
  member_id constant uuid := '37000000-0000-4000-8000-000000000002';
  pending_id constant uuid := '37000000-0000-4000-8000-000000000003';
  grant_result record;
  buy_result record;
  packs_result record;
  open_result record;
  old_buy_result record;
  table_count integer;
  rls_count integer;
  pack_quantity integer;
  wallet_balance integer;
  ledger_count integer;
  pack_event_count integer;
  inventory_total_before integer;
  inventory_total_after_buy integer;
  inventory_total_after_open integer;
  opening_count_before integer;
  opening_count_after_buy integer;
  opening_count_after_open integer;
  owner_count integer;
  cp_named_column_count integer;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30fb-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30fb-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30fb-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30fb_owner', 'tcg30fb_owner', 'TCG 30F-B Owner', 'approved', now()),
    (member_id, 'tcg30fb_member', 'tcg30fb_member', 'TCG 30F-B Member', 'approved', now()),
    (pending_id, 'tcg30fb_pending', 'tcg30fb_pending', 'TCG 30F-B Pending', 'pending', null);

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
    and table_name in ('tcg_player_packs', 'tcg_pack_inventory_events');

  if table_count = 2 then
    insert into tcg_30fb_validation_results values ('schema', 'pack_inventory_tables_exist', 'PASS', 'Pack inventory tables exist.');
  else
    insert into tcg_30fb_validation_results values ('schema', 'pack_inventory_tables_exist', 'FAIL', table_count::text || ' pack inventory tables found.');
  end if;

  select count(*) into rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('tcg_player_packs', 'tcg_pack_inventory_events')
    and c.relrowsecurity;

  if rls_count = 2 then
    insert into tcg_30fb_validation_results values ('schema', 'pack_inventory_rls_enabled', 'PASS', 'RLS enabled on pack inventory tables.');
  else
    insert into tcg_30fb_validation_results values ('schema', 'pack_inventory_rls_enabled', 'FAIL', rls_count::text || ' RLS-enabled pack inventory tables found.');
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30fb_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30fb_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into grant_result from public.tcg_owner_grant_test_coins(1000);
    execute 'reset role';

    if grant_result.balance = 1000 and grant_result.granted_amount = 1000 then
      insert into tcg_30fb_validation_results values ('wallet', 'owner_can_grant_test_coins', 'PASS', 'Owner granted test coins.');
    else
      insert into tcg_30fb_validation_results values ('wallet', 'owner_can_grant_test_coins', 'FAIL', coalesce(grant_result::text, 'No grant result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('wallet', 'owner_can_grant_test_coins', 'FAIL', sqlerrm);
  end;

  select coalesce(sum(quantity), 0) into inventory_total_before
  from public.tcg_player_inventory
  where profile_id = owner_id;

  select count(*) into opening_count_before
  from public.tcg_pack_openings
  where profile_id = owner_id;

  begin
    execute 'set local role authenticated';
    select * into buy_result from public.tcg_owner_buy_test_pack_to_inventory();
    execute 'reset role';

    if buy_result.balance_before = 1000
       and buy_result.balance_after = 900
       and buy_result.price = 100
       and buy_result.pack_code = 'season_0_test_pack'
       and buy_result.owned_pack_quantity = 1
       and buy_result.pack_inventory_event_id is not null
       and buy_result.ledger_id is not null then
      insert into tcg_30fb_validation_results values ('shop', 'owner_can_buy_pack_to_inventory', 'PASS', 'Owner bought one pack into pack inventory.');
    else
      insert into tcg_30fb_validation_results values ('shop', 'owner_can_buy_pack_to_inventory', 'FAIL', coalesce(buy_result::text, 'No buy result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('shop', 'owner_can_buy_pack_to_inventory', 'FAIL', sqlerrm);
  end;

  select balance into wallet_balance
  from public.tcg_wallets
  where profile_id = owner_id
    and currency_code = 'anteiku_coins';

  if wallet_balance = 900 then
    insert into tcg_30fb_validation_results values ('shop', 'buy_to_inventory_deducts_price', 'PASS', 'Wallet balance is 900 after pack inventory purchase.');
  else
    insert into tcg_30fb_validation_results values ('shop', 'buy_to_inventory_deducts_price', 'FAIL', coalesce(wallet_balance, 0)::text || ' balance found.');
  end if;

  select coalesce(sum(pp.quantity), 0) into pack_quantity
  from public.tcg_player_packs pp
  join public.tcg_packs p on p.id = pp.pack_id
  where pp.profile_id = owner_id
    and p.code = 'season_0_test_pack';

  if pack_quantity = 1 then
    insert into tcg_30fb_validation_results values ('pack_inventory', 'buy_adds_one_pack_quantity', 'PASS', 'Owner has one owned test pack.');
  else
    insert into tcg_30fb_validation_results values ('pack_inventory', 'buy_adds_one_pack_quantity', 'FAIL', coalesce(pack_quantity, 0)::text || ' pack quantity found.');
  end if;

  select count(*) into ledger_count
  from public.tcg_wallet_ledger
  where id = buy_result.ledger_id
    and profile_id = owner_id
    and amount_delta = -100
    and balance_after = 900
    and transaction_type = 'shop_purchase'
    and source = 'owner_test_pack_inventory'
    and metadata ->> 'purchase_behavior' = 'pack_inventory';

  if ledger_count = 1 then
    insert into tcg_30fb_validation_results values ('wallet', 'buy_to_inventory_writes_spend_ledger', 'PASS', 'Pack inventory purchase spend ledger written.');
  else
    insert into tcg_30fb_validation_results values ('wallet', 'buy_to_inventory_writes_spend_ledger', 'FAIL', ledger_count::text || ' matching ledger rows found.');
  end if;

  select count(*) into pack_event_count
  from public.tcg_pack_inventory_events
  where id = buy_result.pack_inventory_event_id
    and profile_id = owner_id
    and quantity_delta = 1
    and event_type = 'owner_test_shop_purchase'
    and reference_type = 'tcg_shop_items';

  if pack_event_count = 1 then
    insert into tcg_30fb_validation_results values ('pack_inventory', 'buy_writes_pack_inventory_event', 'PASS', 'Pack inventory purchase event written.');
  else
    insert into tcg_30fb_validation_results values ('pack_inventory', 'buy_writes_pack_inventory_event', 'FAIL', pack_event_count::text || ' matching pack events found.');
  end if;

  select coalesce(sum(quantity), 0) into inventory_total_after_buy
  from public.tcg_player_inventory
  where profile_id = owner_id;

  if inventory_total_after_buy = inventory_total_before then
    insert into tcg_30fb_validation_results values ('inventory', 'buy_to_inventory_does_not_add_cards', 'PASS', 'Card inventory unchanged after pack inventory purchase.');
  else
    insert into tcg_30fb_validation_results values ('inventory', 'buy_to_inventory_does_not_add_cards', 'FAIL', inventory_total_after_buy::text || ' card quantity found after buy.');
  end if;

  select count(*) into opening_count_after_buy
  from public.tcg_pack_openings
  where profile_id = owner_id;

  if opening_count_after_buy = opening_count_before then
    insert into tcg_30fb_validation_results values ('history', 'buy_to_inventory_does_not_write_opening', 'PASS', 'No pack opening history written by purchase.');
  else
    insert into tcg_30fb_validation_results values ('history', 'buy_to_inventory_does_not_write_opening', 'FAIL', opening_count_after_buy::text || ' opening rows found after buy.');
  end if;

  begin
    execute 'set local role authenticated';
    select * into packs_result from public.tcg_get_my_packs() where pack_code = 'season_0_test_pack' limit 1;
    execute 'reset role';

    if packs_result.pack_code = 'season_0_test_pack'
       and packs_result.quantity = 1
       and packs_result.cards_per_pack = 5
       and packs_result.is_owner_test_only then
      insert into tcg_30fb_validation_results values ('pack_inventory', 'owner_can_read_owned_packs', 'PASS', 'Owner read pack inventory.');
    else
      insert into tcg_30fb_validation_results values ('pack_inventory', 'owner_can_read_owned_packs', 'FAIL', coalesce(packs_result::text, 'No pack inventory result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('pack_inventory', 'owner_can_read_owned_packs', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into open_result from public.tcg_owner_open_owned_pack();
    execute 'reset role';

    if open_result.opening_id is not null
       and open_result.pack_code = 'season_0_test_pack'
       and open_result.cards_opened = 5
       and open_result.remaining_pack_quantity = 0
       and jsonb_array_length(open_result.results) = 5 then
      insert into tcg_30fb_validation_results values ('pack_open', 'owner_can_open_owned_pack', 'PASS', 'Owner consumed one owned pack and opened five cards.');
    else
      insert into tcg_30fb_validation_results values ('pack_open', 'owner_can_open_owned_pack', 'FAIL', coalesce(open_result::text, 'No open result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('pack_open', 'owner_can_open_owned_pack', 'FAIL', sqlerrm);
  end;

  select coalesce(sum(pp.quantity), 0) into pack_quantity
  from public.tcg_player_packs pp
  join public.tcg_packs p on p.id = pp.pack_id
  where pp.profile_id = owner_id
    and p.code = 'season_0_test_pack';

  if pack_quantity = 0 then
    insert into tcg_30fb_validation_results values ('pack_inventory', 'opening_consumes_pack_quantity', 'PASS', 'Owned pack quantity is zero after opening.');
  else
    insert into tcg_30fb_validation_results values ('pack_inventory', 'opening_consumes_pack_quantity', 'FAIL', coalesce(pack_quantity, 0)::text || ' pack quantity found.');
  end if;

  select coalesce(sum(quantity), 0) into inventory_total_after_open
  from public.tcg_player_inventory
  where profile_id = owner_id;

  if inventory_total_after_open = inventory_total_before + 5 then
    insert into tcg_30fb_validation_results values ('inventory', 'opening_adds_five_cards', 'PASS', 'Opening owned pack added five card quantities.');
  else
    insert into tcg_30fb_validation_results values ('inventory', 'opening_adds_five_cards', 'FAIL', inventory_total_after_open::text || ' card quantity found after open.');
  end if;

  select count(*) into opening_count_after_open
  from public.tcg_pack_openings
  where id = open_result.opening_id
    and profile_id = owner_id
    and opened_by_profile_id = owner_id
    and source = 'owner_shop_test';

  if opening_count_after_open = 1 then
    insert into tcg_30fb_validation_results values ('history', 'owned_open_writes_opening_history', 'PASS', 'Owned pack opening history written.');
  else
    insert into tcg_30fb_validation_results values ('history', 'owned_open_writes_opening_history', 'FAIL', opening_count_after_open::text || ' matching opening rows found.');
  end if;

  select count(*) into pack_event_count
  from public.tcg_pack_inventory_events
  where profile_id = owner_id
    and quantity_delta = -1
    and event_type = 'owner_owned_pack_opened'
    and reference_type = 'tcg_pack_openings'
    and reference_id = open_result.opening_id;

  if pack_event_count = 1 then
    insert into tcg_30fb_validation_results values ('pack_inventory', 'opening_writes_pack_inventory_event', 'PASS', 'Pack consume event written.');
  else
    insert into tcg_30fb_validation_results values ('pack_inventory', 'opening_writes_pack_inventory_event', 'FAIL', pack_event_count::text || ' pack consume events found.');
  end if;

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_owned_pack();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('pack_open', 'zero_pack_open_denied', 'FAIL', 'Owner opened an owned pack with zero quantity.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('pack_open', 'zero_pack_open_denied', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_buy_test_pack_to_inventory();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_buy_to_inventory', 'FAIL', 'Normal member bought a test pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_buy_to_inventory', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_packs();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_pack_inventory_read', 'FAIL', 'Normal member read Owner pack inventory RPC.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_pack_inventory_read', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_owned_pack();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_open_owned_pack', 'FAIL', 'Normal member opened owned pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'normal_member_denied_open_owned_pack', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_player_packs (profile_id, pack_id, quantity) select $1, id, 1 from public.tcg_packs where code = ''season_0_test_pack'''
      using member_id;
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'direct_pack_inventory_write_blocked', 'FAIL', 'Direct pack inventory insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'direct_pack_inventory_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_pack_inventory_events (profile_id, pack_id, quantity_delta, event_type) select $1, id, 1, ''owner_test_shop_purchase'' from public.tcg_packs where code = ''season_0_test_pack'''
      using member_id;
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'direct_pack_inventory_event_write_blocked', 'FAIL', 'Direct pack inventory event insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'direct_pack_inventory_event_write_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_buy_test_pack_to_inventory();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'pending_user_denied_buy_to_inventory', 'FAIL', 'Pending user bought a test pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('security', 'pending_user_denied_buy_to_inventory', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_catalog();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30fb_validation_results values ('regression', 'catalog_rpc_still_works', 'PASS', 'Catalog RPC returns 50 rows.');
    else
      insert into tcg_30fb_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', table_count::text || ' catalog rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_my_collection();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30fb_validation_results values ('regression', 'collection_rpc_still_works', 'PASS', 'Collection RPC returns 50 rows.');
    else
      insert into tcg_30fb_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', table_count::text || ' collection rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_wallet();
    perform public.tcg_owner_get_test_shop();
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('regression', 'shop_wallet_rpcs_still_work', 'PASS', 'Existing wallet/shop RPCs still execute for Owner.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('regression', 'shop_wallet_rpcs_still_work', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into old_buy_result from public.tcg_owner_buy_test_pack();
    execute 'reset role';

    if old_buy_result.cards_opened = 5
       and jsonb_array_length(old_buy_result.results) = 5 then
      insert into tcg_30fb_validation_results values ('regression', 'old_buy_rpc_kept_for_compatibility', 'PASS', 'Existing buy RPC still buys and opens immediately.');
    else
      insert into tcg_30fb_validation_results values ('regression', 'old_buy_rpc_kept_for_compatibility', 'FAIL', coalesce(old_buy_result::text, 'No old buy result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('regression', 'old_buy_rpc_kept_for_compatibility', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30fb_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30fb_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30fb_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30fb_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30fb_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30fb_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30fb_total_skip
from tcg_30fb_validation_results;

rollback;
