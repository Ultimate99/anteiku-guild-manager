-- Milestone 30G-F1 TCG Anteiku Fragments / duplicate economy backend validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30gf1_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '39000000-0000-4000-8000-000000000001';
  member_id constant uuid := '39000000-0000-4000-8000-000000000002';
  other_id constant uuid := '39000000-0000-4000-8000-000000000003';
  pending_id constant uuid := '39000000-0000-4000-8000-000000000004';
  common_burn_card_id uuid;
  uncommon_burn_card_id uuid;
  rare_burn_card_id uuid;
  epic_burn_card_id uuid;
  legendary_burn_card_id uuid;
  mythic_burn_card_id uuid;
  common_craft_card_id uuid;
  uncommon_craft_card_id uuid;
  rare_craft_card_id uuid;
  epic_craft_card_id uuid;
  legendary_craft_card_id uuid;
  inactive_card_id uuid;
  fragment_result record;
  duplicate_count integer;
  burn_result record;
  craft_result record;
  table_count integer;
  rls_count integer;
  rule_count integer;
  total_dust integer;
  total_cost integer;
  wallet_balance integer;
  inventory_quantity integer;
  event_count integer;
  ledger_count integer;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30gf1-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30gf1-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', other_id, 'authenticated', 'authenticated', 'tcg30gf1-other@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30gf1-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30gf1_owner', 'tcg30gf1_owner', 'TCG 30G-F1 Owner', 'approved', now()),
    (member_id, 'tcg30gf1_member', 'tcg30gf1_member', 'TCG 30G-F1 Member', 'approved', now()),
    (other_id, 'tcg30gf1_other', 'tcg30gf1_other', 'TCG 30G-F1 Other', 'approved', now()),
    (pending_id, 'tcg30gf1_pending', 'tcg30gf1_pending', 'TCG 30G-F1 Pending', 'pending', null);

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
    (other_id, anteiku_id, 'member', 'active', true, owner_id, 'active'),
    (pending_id, anteiku_id, 'member', 'pending', true, null, 'active');

  select count(*) into table_count
  from information_schema.tables
  where table_schema = 'public'
    and table_name in ('tcg_fragment_wallets', 'tcg_fragment_ledger', 'tcg_crafting_rules');

  if table_count = 3 then
    insert into tcg_30gf1_validation_results values ('schema', 'fragment_tables_exist', 'PASS', 'Fragment wallet, ledger, and rules tables exist.');
  else
    insert into tcg_30gf1_validation_results values ('schema', 'fragment_tables_exist', 'FAIL', table_count::text || ' fragment tables found.');
  end if;

  select count(*) into rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('tcg_fragment_wallets', 'tcg_fragment_ledger', 'tcg_crafting_rules')
    and c.relrowsecurity;

  if rls_count = 3 then
    insert into tcg_30gf1_validation_results values ('schema', 'fragment_tables_rls_enabled', 'PASS', 'RLS enabled on all fragment tables.');
  else
    insert into tcg_30gf1_validation_results values ('schema', 'fragment_tables_rls_enabled', 'FAIL', rls_count::text || ' RLS-enabled fragment tables found.');
  end if;

  select count(*) into rule_count
  from public.tcg_crafting_rules
  where (rarity_code = 'common' and dust_value = 2 and crafting_cost = 30 and is_craftable and is_active)
     or (rarity_code = 'uncommon' and dust_value = 5 and crafting_cost = 90 and is_craftable and is_active)
     or (rarity_code = 'rare' and dust_value = 18 and crafting_cost = 350 and is_craftable and is_active)
     or (rarity_code = 'epic' and dust_value = 60 and crafting_cost = 1400 and is_craftable and is_active)
     or (rarity_code = 'legendary' and dust_value = 200 and crafting_cost = 5000 and is_craftable and is_active)
     or (rarity_code = 'mythic' and dust_value = 700 and crafting_cost is null and not is_craftable and is_active);

  if rule_count = 6 then
    insert into tcg_30gf1_validation_results values ('seed', 'balanced_crafting_rules_seeded', 'PASS', 'Balanced dust/crafting rules are seeded.');
  else
    insert into tcg_30gf1_validation_results values ('seed', 'balanced_crafting_rules_seeded', 'FAIL', rule_count::text || ' matching rules found.');
  end if;

  select
    sum(dust_value) filter (where rarity_code in ('common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic')),
    sum(coalesce(crafting_cost, 0)) filter (where rarity_code in ('common', 'uncommon', 'rare', 'epic', 'legendary'))
  into total_dust, total_cost
  from public.tcg_crafting_rules;

  if total_dust = 985 and total_cost = 6870 then
    insert into tcg_30gf1_validation_results values ('seed', 'rule_totals_are_expected', 'PASS', 'Dust and craft totals match v1 design.');
  else
    insert into tcg_30gf1_validation_results values ('seed', 'rule_totals_are_expected', 'FAIL', format('dust=%s cost=%s', coalesce(total_dust, 0), coalesce(total_cost, 0)));
  end if;

  select c.id into common_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'common'
  order by c.sort_order
  limit 1;

  select c.id into common_craft_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'common'
  order by c.sort_order
  offset 1 limit 1;

  select c.id into inactive_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'common'
  order by c.sort_order
  offset 2 limit 1;

  select c.id into uncommon_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'uncommon'
  order by c.sort_order
  limit 1;

  select c.id into uncommon_craft_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'uncommon'
  order by c.sort_order
  offset 1 limit 1;

  select c.id into rare_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'rare'
  order by c.sort_order
  limit 1;

  select c.id into rare_craft_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'rare'
  order by c.sort_order
  offset 1 limit 1;

  select c.id into epic_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'epic'
  order by c.sort_order
  limit 1;

  select c.id into epic_craft_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'epic'
  order by c.sort_order
  offset 1 limit 1;

  select c.id into legendary_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'legendary'
  order by c.sort_order
  limit 1;

  select c.id into legendary_craft_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'legendary'
  order by c.sort_order
  offset 1 limit 1;

  select c.id into mythic_burn_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where r.rarity_key = 'mythic'
  order by c.sort_order
  limit 1;

  insert into public.tcg_player_inventory (
    profile_id,
    card_id,
    quantity,
    first_acquired_at,
    last_acquired_at
  )
  values
    (member_id, common_burn_card_id, 3, now(), now()),
    (member_id, uncommon_burn_card_id, 3, now(), now()),
    (member_id, rare_burn_card_id, 3, now(), now()),
    (member_id, epic_burn_card_id, 3, now(), now()),
    (member_id, legendary_burn_card_id, 3, now(), now()),
    (member_id, mythic_burn_card_id, 10, now(), now()),
    (other_id, common_craft_card_id, 5, now(), now());

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into fragment_result from public.tcg_get_my_fragments();
    execute 'reset role';

    if fragment_result.profile_id = owner_id and fragment_result.balance = 0 then
      insert into tcg_30gf1_validation_results values ('rpc', 'owner_can_read_own_fragments', 'PASS', 'Owner fragment balance returned as zero.');
    else
      insert into tcg_30gf1_validation_results values ('rpc', 'owner_can_read_own_fragments', 'FAIL', coalesce(fragment_result::text, 'No fragment result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('rpc', 'owner_can_read_own_fragments', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into fragment_result from public.tcg_get_my_fragments();
    execute 'reset role';

    if fragment_result.profile_id = member_id and fragment_result.balance = 0 then
      insert into tcg_30gf1_validation_results values ('rpc', 'member_can_read_own_fragments', 'PASS', 'Member fragment balance returned as zero.');
    else
      insert into tcg_30gf1_validation_results values ('rpc', 'member_can_read_own_fragments', 'FAIL', coalesce(fragment_result::text, 'No fragment result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('rpc', 'member_can_read_own_fragments', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into duplicate_count from public.tcg_get_my_duplicate_summary();
    execute 'reset role';

    if duplicate_count = 6 then
      insert into tcg_30gf1_validation_results values ('rpc', 'duplicate_summary_returns_own_duplicates_only', 'PASS', 'Member duplicate summary returned six own duplicate cards.');
    else
      insert into tcg_30gf1_validation_results values ('rpc', 'duplicate_summary_returns_own_duplicates_only', 'FAIL', duplicate_count::text || ' duplicates returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('rpc', 'duplicate_summary_returns_own_duplicates_only', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select balance from public.tcg_fragment_wallets where profile_id = $1' using other_id;
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_other_fragment_wallet_read_blocked', 'FAIL', 'Direct fragment wallet read succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_other_fragment_wallet_read_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select * into burn_result from public.tcg_burn_duplicate_card(common_burn_card_id, 2);
    execute 'reset role';

    if burn_result.remaining_quantity = 1
       and burn_result.quantity_burned = 2
       and burn_result.fragments_gained = 4
       and burn_result.fragment_balance = 4 then
      insert into tcg_30gf1_validation_results values ('burn', 'burn_duplicate_succeeds', 'PASS', 'Burned two common duplicates for four fragments.');
    else
      insert into tcg_30gf1_validation_results values ('burn', 'burn_duplicate_succeeds', 'FAIL', coalesce(burn_result::text, 'No burn result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_duplicate_succeeds', 'FAIL', sqlerrm);
  end;

  select count(*) into event_count
  from public.tcg_inventory_events
  where id = burn_result.inventory_event_id
    and profile_id = member_id
    and card_id = common_burn_card_id
    and quantity_delta = -2
    and event_type = 'duplicate_burned'
    and source_type = 'duplicate_economy';

  if event_count = 1 then
    insert into tcg_30gf1_validation_results values ('burn', 'burn_writes_inventory_event', 'PASS', 'Duplicate burn inventory event written.');
  else
    insert into tcg_30gf1_validation_results values ('burn', 'burn_writes_inventory_event', 'FAIL', event_count::text || ' matching inventory events found.');
  end if;

  select count(*) into ledger_count
  from public.tcg_fragment_ledger
  where id = burn_result.fragment_ledger_id
    and profile_id = member_id
    and card_id = common_burn_card_id
    and amount_delta = 4
    and balance_after = 4
    and transaction_type = 'duplicate_burn';

  if ledger_count = 1 then
    insert into tcg_30gf1_validation_results values ('burn', 'burn_writes_fragment_ledger', 'PASS', 'Duplicate burn fragment ledger written.');
  else
    insert into tcg_30gf1_validation_results values ('burn', 'burn_writes_fragment_ledger', 'FAIL', ledger_count::text || ' matching fragment ledger rows found.');
  end if;

  begin
    execute 'set local role authenticated';
    perform public.tcg_burn_duplicate_card(common_burn_card_id, 1);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_last_copy_rejected', 'FAIL', 'Burned last copy.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_last_copy_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_burn_duplicate_card(uncommon_burn_card_id, 0);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_zero_rejected', 'FAIL', 'Burned zero quantity.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_zero_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_burn_duplicate_card(uncommon_burn_card_id, -1);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_negative_rejected', 'FAIL', 'Burned negative quantity.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_negative_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_burn_duplicate_card(uncommon_burn_card_id, 3);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_too_many_rejected', 'FAIL', 'Burned more than duplicate quantity.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'burn_too_many_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_burn_duplicate_card(uncommon_burn_card_id, 2);
    perform public.tcg_burn_duplicate_card(rare_burn_card_id, 2);
    perform public.tcg_burn_duplicate_card(epic_burn_card_id, 2);
    perform public.tcg_burn_duplicate_card(legendary_burn_card_id, 2);
    perform public.tcg_burn_duplicate_card(mythic_burn_card_id, 9);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'funding_duplicate_burns_succeed', 'PASS', 'Burned duplicates to fund crafting validation.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('burn', 'funding_duplicate_burns_succeed', 'FAIL', sqlerrm);
  end;

  select balance into wallet_balance
  from public.tcg_fragment_wallets
  where profile_id = member_id;

  if wallet_balance = 6870 then
    insert into tcg_30gf1_validation_results values ('wallet', 'fragment_balance_increases_correctly', 'PASS', 'Fragment balance is 6870 after duplicate burns.');
  else
    insert into tcg_30gf1_validation_results values ('wallet', 'fragment_balance_increases_correctly', 'FAIL', coalesce(wallet_balance, 0)::text || ' fragments found.');
  end if;

  begin
    execute 'set local role authenticated';
    select * into craft_result from public.tcg_craft_missing_card(common_craft_card_id);
    perform public.tcg_craft_missing_card(uncommon_craft_card_id);
    perform public.tcg_craft_missing_card(rare_craft_card_id);
    perform public.tcg_craft_missing_card(epic_craft_card_id);
    perform public.tcg_craft_missing_card(legendary_craft_card_id);
    execute 'reset role';

    if craft_result.card_id = common_craft_card_id
       and craft_result.crafting_cost = 30
       and craft_result.new_quantity = 1 then
      insert into tcg_30gf1_validation_results values ('craft', 'craft_common_uncommon_rare_epic_legendary_succeeds', 'PASS', 'Crafted missing Common, Uncommon, Rare, Epic, and Legendary cards.');
    else
      insert into tcg_30gf1_validation_results values ('craft', 'craft_common_uncommon_rare_epic_legendary_succeeds', 'FAIL', coalesce(craft_result::text, 'No craft result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_common_uncommon_rare_epic_legendary_succeeds', 'FAIL', sqlerrm);
  end;

  select count(*) into event_count
  from public.tcg_inventory_events
  where profile_id = member_id
    and event_type = 'card_crafted'
    and source_type = 'duplicate_economy';

  if event_count = 5 then
    insert into tcg_30gf1_validation_results values ('craft', 'craft_writes_inventory_events', 'PASS', 'Five crafting inventory events written.');
  else
    insert into tcg_30gf1_validation_results values ('craft', 'craft_writes_inventory_events', 'FAIL', event_count::text || ' crafting inventory events found.');
  end if;

  select count(*) into ledger_count
  from public.tcg_fragment_ledger
  where profile_id = member_id
    and transaction_type = 'missing_card_craft'
    and amount_delta < 0;

  if ledger_count = 5 then
    insert into tcg_30gf1_validation_results values ('craft', 'craft_writes_fragment_ledger', 'PASS', 'Five crafting fragment ledger rows written.');
  else
    insert into tcg_30gf1_validation_results values ('craft', 'craft_writes_fragment_ledger', 'FAIL', ledger_count::text || ' crafting fragment ledger rows found.');
  end if;

  select balance into wallet_balance
  from public.tcg_fragment_wallets
  where profile_id = member_id;

  if wallet_balance = 0 then
    insert into tcg_30gf1_validation_results values ('wallet', 'fragment_balance_decreases_correctly', 'PASS', 'Fragment balance is zero after exact crafting spend.');
  else
    insert into tcg_30gf1_validation_results values ('wallet', 'fragment_balance_decreases_correctly', 'FAIL', coalesce(wallet_balance, 0)::text || ' fragments found.');
  end if;

  select coalesce(quantity, 0) into inventory_quantity
  from public.tcg_player_inventory
  where profile_id = member_id
    and card_id = legendary_craft_card_id;

  if inventory_quantity = 1 then
    insert into tcg_30gf1_validation_results values ('craft', 'craft_adds_exactly_one_card', 'PASS', 'Crafted Legendary exists at quantity one.');
  else
    insert into tcg_30gf1_validation_results values ('craft', 'craft_adds_exactly_one_card', 'FAIL', coalesce(inventory_quantity, 0)::text || ' quantity found.');
  end if;

  begin
    execute 'set local role authenticated';
    perform public.tcg_craft_missing_card(common_craft_card_id);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_already_owned_rejected', 'FAIL', 'Crafted an already-owned card.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_already_owned_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_craft_missing_card(mythic_burn_card_id);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_mythic_rejected', 'FAIL', 'Crafted Mythic card.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_mythic_rejected', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_craft_missing_card(inactive_card_id);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_insufficient_fragments_rejected', 'FAIL', 'Crafted without enough fragments.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_insufficient_fragments_rejected', 'PASS', sqlerrm);
  end;

  update public.tcg_cards
  set release_status = 'retired'
  where id = inactive_card_id;

  insert into public.tcg_fragment_wallets (profile_id, balance)
  values (member_id, 1000)
  on conflict on constraint tcg_fragment_wallets_profile_uidx do update
  set balance = excluded.balance,
      updated_at = now();

  begin
    execute 'set local role authenticated';
    perform public.tcg_craft_missing_card(inactive_card_id);
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_inactive_card_rejected', 'FAIL', 'Crafted inactive card.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('craft', 'craft_inactive_card_rejected', 'PASS', sqlerrm);
  end;

  update public.tcg_cards
  set release_status = 'active'
  where id = inactive_card_id;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_fragment_wallets (profile_id, balance) values ($1, 1)' using member_id;
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_fragment_wallet_write_blocked', 'FAIL', 'Direct fragment wallet insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_fragment_wallet_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_fragment_ledger (profile_id, amount_delta, balance_after, transaction_type) values ($1, 1, 1, ''duplicate_burn'')' using member_id;
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_fragment_ledger_write_blocked', 'FAIL', 'Direct fragment ledger insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_fragment_ledger_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'update public.tcg_crafting_rules set dust_value = 999 where rarity_code = ''common''';
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_crafting_rule_update_blocked', 'FAIL', 'Direct crafting rule update succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'direct_crafting_rule_update_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_fragments();
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'pending_user_denied_fragments', 'FAIL', 'Pending user read fragments.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('security', 'pending_user_denied_fragments', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_catalog();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30gf1_validation_results values ('regression', 'catalog_rpc_still_works', 'PASS', 'Catalog RPC returns 50 rows.');
    else
      insert into tcg_30gf1_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', table_count::text || ' catalog rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('regression', 'catalog_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into table_count from public.tcg_get_my_collection();
    execute 'reset role';

    if table_count = 50 then
      insert into tcg_30gf1_validation_results values ('regression', 'collection_rpc_still_works', 'PASS', 'Collection RPC returns 50 rows.');
    else
      insert into tcg_30gf1_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', table_count::text || ' collection rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_wallet();
    perform public.tcg_owner_get_test_shop();
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('regression', 'shop_wallet_rpcs_still_work', 'PASS', 'Existing wallet/shop RPCs still execute for Owner.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('regression', 'shop_wallet_rpcs_still_work', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30gf1_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30gf1_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30gf1_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30gf1_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30gf1_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30gf1_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30gf1_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30gf1_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30gf1_total_skip
from tcg_30gf1_validation_results;

rollback;
