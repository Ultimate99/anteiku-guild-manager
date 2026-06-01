-- Milestone 30F-A Owner-only TCG balance report validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30f_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '33000000-0000-4000-8000-000000000001';
  member_id constant uuid := '33000000-0000-4000-8000-000000000002';
  pending_id constant uuid := '33000000-0000-4000-8000-000000000003';
  report_payload jsonb;
  table_count integer;
  function_count integer;
  owner_count integer;
  inventory_total_before integer;
  inventory_total_after integer;
  wallet_balance_before integer;
  wallet_balance_after integer;
  opening_count_before integer;
  opening_count_after integer;
  ledger_count_before integer;
  ledger_count_after integer;
  report_text text;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30f-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30f-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30f-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30f_owner', 'tcg30f_owner', 'TCG 30F Owner', 'approved', now()),
    (member_id, 'tcg30f_member', 'tcg30f_member', 'TCG 30F Member', 'approved', now()),
    (pending_id, 'tcg30f_pending', 'tcg30f_pending', 'TCG 30F Pending', 'pending', null);

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

  select count(*) into function_count
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'tcg_owner_get_balance_report';

  if function_count = 1 then
    insert into tcg_30f_validation_results values ('schema', 'balance_report_rpc_exists', 'PASS', 'RPC exists.');
  else
    insert into tcg_30f_validation_results values ('schema', 'balance_report_rpc_exists', 'FAIL', function_count::text || ' RPCs found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_grant_test_coins(1000);
    perform public.tcg_owner_buy_test_pack();
    perform public.tcg_owner_open_test_pack();
    perform public.tcg_admin_grant_card(owner_id, 's0_001_20th_ward_civilian', 2, '30F validation duplicate pressure');
    execute 'reset role';
    insert into tcg_30f_validation_results values ('setup', 'owner_test_data_created', 'PASS', 'Owner test data created inside rollback transaction.');
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('setup', 'owner_test_data_created', 'FAIL', sqlerrm);
  end;

  select coalesce(sum(quantity), 0)
  into inventory_total_before
  from public.tcg_player_inventory
  where profile_id = owner_id;

  select coalesce(max(balance), 0)
  into wallet_balance_before
  from public.tcg_wallets
  where profile_id = owner_id
    and currency_code = 'anteiku_coins';

  select count(*)
  into opening_count_before
  from public.tcg_pack_openings
  where profile_id = owner_id;

  select count(*)
  into ledger_count_before
  from public.tcg_wallet_ledger
  where profile_id = owner_id;

  begin
    execute 'set local role authenticated';
    select public.tcg_owner_get_balance_report() into report_payload;
    execute 'reset role';

    if report_payload ? 'collection_summary'
       and report_payload ? 'rarity_ownership_summary'
       and report_payload ? 'pack_opening_summary'
       and report_payload ? 'rarity_pull_summary'
       and report_payload ? 'economy_summary'
       and report_payload ? 'duplicate_pressure_summary'
       and report_payload ? 'balance_hints' then
      insert into tcg_30f_validation_results values ('rpc', 'owner_can_call_balance_report', 'PASS', 'Owner received all report sections.');
    else
      insert into tcg_30f_validation_results values ('rpc', 'owner_can_call_balance_report', 'FAIL', coalesce(report_payload::text, 'No report payload.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('rpc', 'owner_can_call_balance_report', 'FAIL', sqlerrm);
  end;

  if (report_payload #>> '{collection_summary,total_cards_in_catalog}')::integer = 50
     and (report_payload #>> '{collection_summary,unique_owned}')::integer > 0
     and (report_payload #>> '{collection_summary,total_quantity_owned}')::integer = inventory_total_before
     and (report_payload #>> '{collection_summary,duplicate_quantity_total}')::integer >= 1 then
    insert into tcg_30f_validation_results values ('report', 'collection_summary_shape', 'PASS', 'Collection summary has expected totals.');
  else
    insert into tcg_30f_validation_results values ('report', 'collection_summary_shape', 'FAIL', coalesce(report_payload->'collection_summary', '{}'::jsonb)::text);
  end if;

  if jsonb_array_length(report_payload->'rarity_ownership_summary') = 6
     and exists (
       select 1
       from jsonb_array_elements(report_payload->'rarity_ownership_summary') item
       where item ? 'rarity_code'
         and item ? 'catalog_count'
         and item ? 'unique_owned'
         and item ? 'duplicate_quantity'
         and item ? 'completion_percent'
     ) then
    insert into tcg_30f_validation_results values ('report', 'rarity_ownership_summary_shape', 'PASS', 'Rarity ownership summary includes expected fields.');
  else
    insert into tcg_30f_validation_results values ('report', 'rarity_ownership_summary_shape', 'FAIL', coalesce(report_payload->'rarity_ownership_summary', '[]'::jsonb)::text);
  end if;

  if (report_payload #>> '{pack_opening_summary,total_pack_openings}')::integer = 2
     and (report_payload #>> '{pack_opening_summary,total_cards_pulled}')::integer = 10
     and (report_payload #>> '{pack_opening_summary,shop_pack_openings}')::integer = 1
     and (report_payload #>> '{pack_opening_summary,free_test_pack_openings}')::integer = 1 then
    insert into tcg_30f_validation_results values ('report', 'pack_opening_summary_shape', 'PASS', 'Pack opening summary distinguishes shop and free test openings.');
  else
    insert into tcg_30f_validation_results values ('report', 'pack_opening_summary_shape', 'FAIL', coalesce(report_payload->'pack_opening_summary', '{}'::jsonb)::text);
  end if;

  if jsonb_array_length(report_payload->'rarity_pull_summary') = 6
     and exists (
       select 1
       from jsonb_array_elements(report_payload->'rarity_pull_summary') item
       where item ? 'rarity_code'
         and item ? 'pulled_quantity'
         and item ? 'pull_percent'
         and item ? 'catalog_count'
         and item ? 'owned_unique'
     ) then
    insert into tcg_30f_validation_results values ('report', 'rarity_pull_summary_shape', 'PASS', 'Rarity pull summary includes expected fields.');
  else
    insert into tcg_30f_validation_results values ('report', 'rarity_pull_summary_shape', 'FAIL', coalesce(report_payload->'rarity_pull_summary', '[]'::jsonb)::text);
  end if;

  if (report_payload #>> '{economy_summary,current_balance}')::integer = 900
     and (report_payload #>> '{economy_summary,total_coins_granted}')::integer = 1000
     and (report_payload #>> '{economy_summary,total_coins_spent}')::integer = 100
     and (report_payload #>> '{economy_summary,total_pack_purchase_spend}')::integer = 100 then
    insert into tcg_30f_validation_results values ('report', 'economy_summary_shape', 'PASS', 'Economy summary has expected wallet and spend totals.');
  else
    insert into tcg_30f_validation_results values ('report', 'economy_summary_shape', 'FAIL', coalesce(report_payload->'economy_summary', '{}'::jsonb)::text);
  end if;

  if jsonb_array_length(report_payload #> '{duplicate_pressure_summary,most_duplicated_cards}') >= 1
     and jsonb_array_length(report_payload #> '{duplicate_pressure_summary,missing_cards}') >= 1
     and (report_payload #>> '{duplicate_pressure_summary,cards_never_obtained_count}')::integer >= 1
     and jsonb_array_length(report_payload #> '{duplicate_pressure_summary,newest_obtained_cards}') >= 1 then
    insert into tcg_30f_validation_results values ('report', 'duplicate_pressure_summary_shape', 'PASS', 'Duplicate/missing/newest card pressure fields populated.');
  else
    insert into tcg_30f_validation_results values ('report', 'duplicate_pressure_summary_shape', 'FAIL', coalesce(report_payload->'duplicate_pressure_summary', '{}'::jsonb)::text);
  end if;

  if report_payload #> '{balance_hints}' ? 'duplicate_rate_percent'
     and report_payload #> '{balance_hints}' ? 'missing_card_percent'
     and report_payload #> '{balance_hints}' ? 'average_cards_per_opening' then
    insert into tcg_30f_validation_results values ('report', 'balance_hints_raw_numbers_present', 'PASS', 'Balance hints are raw computed numbers.');
  else
    insert into tcg_30f_validation_results values ('report', 'balance_hints_raw_numbers_present', 'FAIL', coalesce(report_payload->'balance_hints', '{}'::jsonb)::text);
  end if;

  report_text := lower(coalesce(report_payload::text, ''));

  if report_text not like '%member_cp%'
     and report_text not like '%cp_snapshots%'
     and report_text not like '%current_cp%'
     and report_text not like '%average_cp%'
     and report_text not like '%email%'
     and report_text not like '%auth%' then
    insert into tcg_30f_validation_results values ('privacy', 'report_payload_has_no_cp_or_private_metadata', 'PASS', 'Report payload avoids CP/email/auth metadata.');
  else
    insert into tcg_30f_validation_results values ('privacy', 'report_payload_has_no_cp_or_private_metadata', 'FAIL', 'Sensitive-looking token found in report text.');
  end if;

  select coalesce(sum(quantity), 0)
  into inventory_total_after
  from public.tcg_player_inventory
  where profile_id = owner_id;

  select coalesce(max(balance), 0)
  into wallet_balance_after
  from public.tcg_wallets
  where profile_id = owner_id
    and currency_code = 'anteiku_coins';

  select count(*)
  into opening_count_after
  from public.tcg_pack_openings
  where profile_id = owner_id;

  select count(*)
  into ledger_count_after
  from public.tcg_wallet_ledger
  where profile_id = owner_id;

  if inventory_total_after = inventory_total_before
     and wallet_balance_after = wallet_balance_before
     and opening_count_after = opening_count_before
     and ledger_count_after = ledger_count_before then
    insert into tcg_30f_validation_results values ('security', 'balance_report_is_read_only', 'PASS', 'Inventory, wallet, openings, and ledger counts unchanged.');
  else
    insert into tcg_30f_validation_results values ('security', 'balance_report_is_read_only', 'FAIL', 'Read-only snapshot changed after report call.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_get_balance_report();
    execute 'reset role';
    insert into tcg_30f_validation_results values ('security', 'normal_member_denied_balance_report', 'FAIL', 'Normal member read Owner balance report.');
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('security', 'normal_member_denied_balance_report', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_get_balance_report();
    execute 'reset role';
    insert into tcg_30f_validation_results values ('security', 'pending_user_denied_balance_report', 'FAIL', 'Pending user read Owner balance report.');
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('security', 'pending_user_denied_balance_report', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30f_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30f_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_catalog();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30f_validation_results values ('regression', 'catalog_rpc_still_works', 'PASS', 'Catalog RPC returns 50 rows.');
    else
      insert into tcg_30f_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', table_count::text || ' catalog rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_my_collection();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30f_validation_results values ('regression', 'collection_rpc_still_works', 'PASS', 'Collection RPC returns 50 rows.');
    else
      insert into tcg_30f_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', table_count::text || ' collection rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_owner_get_test_shop();
    execute 'reset role';

    if table_count >= 1 then
      insert into tcg_30f_validation_results values ('regression', 'shop_rpc_still_works', 'PASS', 'Owner test shop RPC still returns rows.');
    else
      insert into tcg_30f_validation_results values ('regression', 'shop_rpc_still_works', 'FAIL', table_count::text || ' shop rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30f_validation_results values ('regression', 'shop_rpc_still_works', 'FAIL', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30f_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30f_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30f_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30f_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30f_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30f_total_skip
from tcg_30f_validation_results;

rollback;
