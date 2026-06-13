-- Milestone 30G-F2 soft pity validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30g_pity_validation_results (
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
  pending_id constant uuid := '39000000-0000-4000-8000-000000000003';
  target_pack_id uuid;
  target_set_id uuid;
  status_row record;
  open_result record;
  free_open_result record;
  table_count integer;
  rls_count integer;
  counter_count integer;
  direct_count integer;
  pack_quantity integer;
  inventory_total_before integer;
  inventory_total_after integer;
  opening_count integer;
  event_count integer;
  counter_row record;
  first_item jsonb;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30gf2-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30gf2-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30gf2-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30gf2_owner', 'tcg30gf2_owner', 'TCG 30G-F2 Owner', 'approved', now()),
    (member_id, 'tcg30gf2_member', 'tcg30gf2_member', 'TCG 30G-F2 Member', 'approved', now()),
    (pending_id, 'tcg30gf2_pending', 'tcg30gf2_pending', 'TCG 30G-F2 Pending', 'pending', null);

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

  select p.id, p.set_id
  into target_pack_id, target_set_id
  from public.tcg_packs p
  where p.code = 'season_0_test_pack';

  select count(*) into table_count
  from information_schema.tables
  where table_schema = 'public'
    and table_name = 'tcg_pity_counters';

  if table_count = 1 then
    insert into tcg_30g_pity_validation_results values ('schema', 'pity_table_exists', 'PASS', 'tcg_pity_counters exists.');
  else
    insert into tcg_30g_pity_validation_results values ('schema', 'pity_table_exists', 'FAIL', table_count::text || ' pity tables found.');
  end if;

  select count(*) into rls_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname = 'tcg_pity_counters'
    and c.relrowsecurity;

  if rls_count = 1 then
    insert into tcg_30g_pity_validation_results values ('schema', 'pity_rls_enabled', 'PASS', 'RLS enabled on tcg_pity_counters.');
  else
    insert into tcg_30g_pity_validation_results values ('schema', 'pity_rls_enabled', 'FAIL', rls_count::text || ' RLS-enabled pity tables found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into status_row
    from public.tcg_get_my_pity_status()
    where pack_code = 'season_0_test_pack'
    limit 1;
    execute 'reset role';

    if status_row.pack_code = 'season_0_test_pack'
       and status_row.packs_since_legendary = 0
       and status_row.legendary_threshold = 50
       and status_row.legendary_remaining = 50
       and status_row.packs_since_mythic = 0
       and status_row.mythic_threshold = 150
       and status_row.mythic_remaining = 150
       and status_row.total_eligible_openings = 0 then
      insert into tcg_30g_pity_validation_results values ('rpc', 'pity_status_zero_without_counter', 'PASS', 'Zero status returned without lazy counter mutation.');
    else
      insert into tcg_30g_pity_validation_results values ('rpc', 'pity_status_zero_without_counter', 'FAIL', coalesce(status_row::text, 'No status row.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('rpc', 'pity_status_zero_without_counter', 'FAIL', sqlerrm);
  end;

  select count(*) into counter_count
  from public.tcg_pity_counters
  where profile_id = owner_id;

  if counter_count = 0 then
    insert into tcg_30g_pity_validation_results values ('rpc', 'pity_status_is_read_only', 'PASS', 'Status RPC did not create a counter row.');
  else
    insert into tcg_30g_pity_validation_results values ('rpc', 'pity_status_is_read_only', 'FAIL', counter_count::text || ' counter rows found.');
  end if;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_pity_counters (profile_id, set_id, pack_id, packs_since_legendary) values ($1, $2, $3, 1)'
      using owner_id, target_set_id, target_pack_id;
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'direct_pity_counter_write_blocked', 'FAIL', 'Authenticated direct pity insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'direct_pity_counter_write_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.tcg_pity_counters where profile_id = $1'
      into direct_count
      using owner_id;
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'normal_user_cannot_read_other_pity_table', 'FAIL', 'Authenticated direct pity read returned ' || coalesce(direct_count, 0)::text || ' rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'normal_user_cannot_read_other_pity_table', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_my_pity_status();
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'pending_user_denied_pity_status', 'FAIL', 'Pending user read pity status.');
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('security', 'pending_user_denied_pity_status', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_owned_pack();
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('pack_open', 'zero_owned_pack_open_denied', 'FAIL', 'Owned pack opening succeeded with zero packs.');
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('pack_open', 'zero_owned_pack_open_denied', 'PASS', sqlerrm);
  end;

  select count(*) into counter_count
  from public.tcg_pity_counters
  where profile_id = owner_id;

  if counter_count = 0 then
    insert into tcg_30g_pity_validation_results values ('pack_open', 'failed_open_does_not_update_pity', 'PASS', 'Rejected zero-pack open did not create pity counter.');
  else
    insert into tcg_30g_pity_validation_results values ('pack_open', 'failed_open_does_not_update_pity', 'FAIL', counter_count::text || ' counter rows found after failed open.');
  end if;

  begin
    execute 'set local role authenticated';
    select * into free_open_result from public.tcg_owner_open_test_pack();
    execute 'reset role';

    if free_open_result.opening_id is not null
       and jsonb_array_length(free_open_result.results) = 5 then
      insert into tcg_30g_pity_validation_results values ('free_test', 'owner_free_test_pack_opens', 'PASS', 'Free Owner test pack opened.');
    else
      insert into tcg_30g_pity_validation_results values ('free_test', 'owner_free_test_pack_opens', 'FAIL', coalesce(free_open_result::text, 'No free open result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('free_test', 'owner_free_test_pack_opens', 'FAIL', sqlerrm);
  end;

  select count(*) into counter_count
  from public.tcg_pity_counters
  where profile_id = owner_id;

  if counter_count = 0 then
    insert into tcg_30g_pity_validation_results values ('free_test', 'free_test_pack_does_not_update_pity', 'PASS', 'Free Owner test pack did not create pity counter.');
  else
    insert into tcg_30g_pity_validation_results values ('free_test', 'free_test_pack_does_not_update_pity', 'FAIL', counter_count::text || ' counter rows found after free pack.');
  end if;

  select coalesce(sum(quantity), 0) into inventory_total_before
  from public.tcg_player_inventory
  where profile_id = owner_id;

  insert into public.tcg_player_packs (
    profile_id,
    pack_id,
    quantity,
    first_obtained_at
  )
  values (
    owner_id,
    target_pack_id,
    1,
    now()
  )
  on conflict on constraint tcg_player_packs_profile_pack_uidx do update
  set quantity = excluded.quantity,
      first_obtained_at = coalesce(public.tcg_player_packs.first_obtained_at, now()),
      updated_at = now();

  begin
    execute 'set local role authenticated';
    select * into open_result from public.tcg_owner_open_owned_pack();
    execute 'reset role';

    if open_result.opening_id is not null
       and open_result.pack_code = 'season_0_test_pack'
       and open_result.cards_opened = 5
       and open_result.remaining_pack_quantity = 0
       and jsonb_array_length(open_result.results) = 5 then
      insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_opens_five_cards', 'PASS', 'Owned pack opened five cards.');
    else
      insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_opens_five_cards', 'FAIL', coalesce(open_result::text, 'No owned open result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_opens_five_cards', 'FAIL', sqlerrm);
  end;

  select coalesce(sum(pp.quantity), 0) into pack_quantity
  from public.tcg_player_packs pp
  where pp.profile_id = owner_id
    and pp.pack_id = target_pack_id;

  if pack_quantity = 0 then
    insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_quantity_decreased', 'PASS', 'Owned pack quantity consumed.');
  else
    insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_quantity_decreased', 'FAIL', coalesce(pack_quantity, 0)::text || ' packs remain.');
  end if;

  select coalesce(sum(quantity), 0) into inventory_total_after
  from public.tcg_player_inventory
  where profile_id = owner_id;

  if inventory_total_after = inventory_total_before + 5 then
    insert into tcg_30g_pity_validation_results values ('owned_open', 'inventory_added_five_owned_cards', 'PASS', 'Owned pack added five card quantities.');
  else
    insert into tcg_30g_pity_validation_results values ('owned_open', 'inventory_added_five_owned_cards', 'FAIL', inventory_total_after::text || ' total cards after owned open, before was ' || inventory_total_before::text || '.');
  end if;

  select *
  into counter_row
  from public.tcg_pity_counters
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  if counter_row.total_eligible_openings = 1
     and counter_row.packs_since_legendary >= 0
     and counter_row.packs_since_mythic >= 0
     and counter_row.last_eligible_opening_at is not null then
    insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_updates_pity_counter', 'PASS', 'Owned pack counted as eligible pity opening.');
  else
    insert into tcg_30g_pity_validation_results values ('owned_open', 'owned_pack_updates_pity_counter', 'FAIL', coalesce(counter_row::text, 'No counter row.'));
  end if;

  select count(*) into opening_count
  from public.tcg_pack_openings
  where id = open_result.opening_id
    and profile_id = owner_id
    and source = 'owner_shop_test';

  select count(*) into event_count
  from public.tcg_pack_inventory_events
  where profile_id = owner_id
    and reference_id = open_result.opening_id
    and event_type = 'owner_owned_pack_opened'
    and quantity_delta = -1;

  if opening_count = 1 and event_count = 1 then
    insert into tcg_30g_pity_validation_results values ('owned_open', 'opening_history_and_pack_event_written', 'PASS', 'Opening history and pack consume event written.');
  else
    insert into tcg_30g_pity_validation_results values ('owned_open', 'opening_history_and_pack_event_written', 'FAIL', opening_count::text || ' openings and ' || event_count::text || ' pack events found.');
  end if;

  -- Use one-card test packs for deterministic pity guarantee assertions.
  update public.tcg_packs
  set cards_per_pack = 1,
      updated_at = now()
  where id = target_pack_id;

  update public.tcg_pity_counters
  set packs_since_legendary = 50,
      packs_since_mythic = 10,
      total_eligible_openings = 10,
      last_legendary_at = null,
      last_mythic_at = null,
      updated_at = now()
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  update public.tcg_player_packs
  set quantity = 1,
      updated_at = now()
  where profile_id = owner_id
    and pack_id = target_pack_id;

  begin
    execute 'set local role authenticated';
    select * into open_result from public.tcg_owner_open_owned_pack();
    execute 'reset role';

    first_item := open_result.results -> 0;

    if open_result.cards_opened = 1
       and first_item ->> 'rarity_key' = 'legendary'
       and coalesce((first_item ->> 'is_pity_guaranteed')::boolean, false) then
      insert into tcg_30g_pity_validation_results values ('pity', 'legendary_pity_guarantees_legendary', 'PASS', 'Legendary pity guaranteed a Legendary card.');
    else
      insert into tcg_30g_pity_validation_results values ('pity', 'legendary_pity_guarantees_legendary', 'FAIL', coalesce(open_result.results::text, 'No result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('pity', 'legendary_pity_guarantees_legendary', 'FAIL', sqlerrm);
  end;

  select *
  into counter_row
  from public.tcg_pity_counters
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  if counter_row.total_eligible_openings = 11
     and counter_row.packs_since_legendary = 0
     and counter_row.packs_since_mythic = 11
     and counter_row.last_legendary_at is not null then
    insert into tcg_30g_pity_validation_results values ('pity', 'legendary_resets_legendary_counter', 'PASS', 'Legendary pull reset Legendary pity and advanced Mythic pity.');
  else
    insert into tcg_30g_pity_validation_results values ('pity', 'legendary_resets_legendary_counter', 'FAIL', coalesce(counter_row::text, 'No counter row.'));
  end if;

  update public.tcg_pity_counters
  set packs_since_legendary = 50,
      packs_since_mythic = 150,
      total_eligible_openings = 20,
      last_legendary_at = null,
      last_mythic_at = null,
      updated_at = now()
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  update public.tcg_player_packs
  set quantity = 1,
      updated_at = now()
  where profile_id = owner_id
    and pack_id = target_pack_id;

  begin
    execute 'set local role authenticated';
    select * into open_result from public.tcg_owner_open_owned_pack();
    execute 'reset role';

    first_item := open_result.results -> 0;

    if open_result.cards_opened = 1
       and first_item ->> 'rarity_key' = 'mythic'
       and coalesce((first_item ->> 'is_pity_guaranteed')::boolean, false) then
      insert into tcg_30g_pity_validation_results values ('pity', 'mythic_pity_priority_guarantees_mythic', 'PASS', 'Mythic pity beat Legendary pity and guaranteed Mythic.');
    else
      insert into tcg_30g_pity_validation_results values ('pity', 'mythic_pity_priority_guarantees_mythic', 'FAIL', coalesce(open_result.results::text, 'No result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_pity_validation_results values ('pity', 'mythic_pity_priority_guarantees_mythic', 'FAIL', sqlerrm);
  end;

  select *
  into counter_row
  from public.tcg_pity_counters
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  if counter_row.total_eligible_openings = 21
     and counter_row.packs_since_legendary = 0
     and counter_row.packs_since_mythic = 0
     and counter_row.last_legendary_at is not null
     and counter_row.last_mythic_at is not null then
    insert into tcg_30g_pity_validation_results values ('pity', 'mythic_resets_both_counters', 'PASS', 'Mythic pull reset both pity counters.');
  else
    insert into tcg_30g_pity_validation_results values ('pity', 'mythic_resets_both_counters', 'FAIL', coalesce(counter_row::text, 'No counter row.'));
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30g_pity_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30g_pity_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  select count(*) into owner_count
  from public.guild_memberships
  where role = 'owner'
    and membership_status = 'active';

  if owner_count = 1 then
    insert into tcg_30g_pity_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'One active Owner remains.');
  else
    insert into tcg_30g_pity_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active Owners found.');
  end if;
end;
$$;

select *
from tcg_30g_pity_validation_results
order by
  case status when 'FAIL' then 1 when 'SKIP' then 2 else 3 end,
  section,
  test_name;

rollback;
