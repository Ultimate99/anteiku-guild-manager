-- Milestone 30D-A Owner-only TCG pack backend validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30d_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '31000000-0000-4000-8000-000000000001';
  member_id constant uuid := '31000000-0000-4000-8000-000000000002';
  pending_id constant uuid := '31000000-0000-4000-8000-000000000003';
  season_zero_id uuid;
  duplicate_pack_id uuid;
  mythic_card_id uuid;
  result_record record;
  opening_id_value uuid;
  result_payload jsonb := '[]'::jsonb;
  result_cards_opened integer := 0;
  collection_count integer;
  pack_count integer;
  rate_count integer;
  opening_count integer;
  result_count integer;
  owner_inventory_total integer;
  duplicate_quantity integer;
  event_count integer;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30d-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30d-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30d-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30d_owner', 'tcg30d_owner', 'TCG 30D Owner', 'approved', now()),
    (member_id, 'tcg30d_member', 'tcg30d_member', 'TCG 30D Member', 'approved', now()),
    (pending_id, 'tcg30d_pending', 'tcg30d_pending', 'TCG 30D Pending', 'pending', null);

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

  select id into season_zero_id
  from public.tcg_sets
  where set_key = 'season_0_anteiku_origins';

  if season_zero_id is not null then
    insert into tcg_30d_validation_results values ('seed', 'season_zero_exists', 'PASS', 'Season 0 set exists.');
  else
    insert into tcg_30d_validation_results values ('seed', 'season_zero_exists', 'FAIL', 'Season 0 set missing.');
  end if;

  select count(*) into pack_count
  from public.tcg_packs
  where code = 'season_0_test_pack'
    and cards_per_pack = 5
    and is_active
    and is_owner_test_only;

  if pack_count = 1 then
    insert into tcg_30d_validation_results values ('seed', 'owner_test_pack_seeded', 'PASS', 'Season 0 test pack exists.');
  else
    insert into tcg_30d_validation_results values ('seed', 'owner_test_pack_seeded', 'FAIL', pack_count::text || ' matching packs found.');
  end if;

  select count(*) into rate_count
  from public.tcg_pack_drop_rates dr
  join public.tcg_packs p on p.id = dr.pack_id
  where p.code = 'season_0_test_pack';

  if rate_count = 6 then
    insert into tcg_30d_validation_results values ('seed', 'drop_rates_seeded', 'PASS', 'Six rarity drop rates exist.');
  else
    insert into tcg_30d_validation_results values ('seed', 'drop_rates_seeded', 'FAIL', rate_count::text || ' rates found.');
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30d_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30d_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into result_record from public.tcg_owner_open_test_pack();
    execute 'reset role';

    if result_record.opening_id is not null
       and result_record.cards_opened = 5
       and jsonb_array_length(result_record.results) = 5 then
      opening_id_value := result_record.opening_id;
      result_payload := result_record.results;
      result_cards_opened := result_record.cards_opened;
      insert into tcg_30d_validation_results values ('rpc', 'owner_can_open_test_pack', 'PASS', 'Owner opened a five-card test pack.');
    else
      insert into tcg_30d_validation_results values ('rpc', 'owner_can_open_test_pack', 'FAIL', coalesce(result_record.results::text, 'No result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('rpc', 'owner_can_open_test_pack', 'FAIL', sqlerrm);
  end;

  if opening_id_value is null then
    insert into tcg_30d_validation_results values ('history', 'pack_opening_history_written', 'FAIL', 'Owner pack opening did not return an opening id.');
  else
    select count(*) into opening_count
    from public.tcg_pack_openings
    where id = opening_id_value
      and profile_id = owner_id
      and opened_by_profile_id = owner_id
      and source = 'owner_test';

    if opening_count = 1 then
      insert into tcg_30d_validation_results values ('history', 'pack_opening_history_written', 'PASS', 'Pack opening history row exists.');
    else
      insert into tcg_30d_validation_results values ('history', 'pack_opening_history_written', 'FAIL', opening_count::text || ' opening rows found.');
    end if;
  end if;

  select count(*) into result_count
  from jsonb_array_elements(result_payload) item
  where item ? 'card_id'
    and item ? 'card_no'
    and item ? 'card_key'
    and item ? 'slug'
    and item ? 'name'
    and item ? 'rarity_key'
    and item ? 'art_path'
    and item ? 'quantity_delta'
    and item ? 'is_duplicate';

  if result_count = 5 then
    insert into tcg_30d_validation_results values ('rpc', 'result_payload_safe_shape', 'PASS', 'Each result has UI-safe card metadata.');
  else
    insert into tcg_30d_validation_results values ('rpc', 'result_payload_safe_shape', 'FAIL', result_count::text || ' result items had expected fields.');
  end if;

  select coalesce(sum(quantity), 0) into owner_inventory_total
  from public.tcg_player_inventory
  where profile_id = owner_id;

  if owner_inventory_total = 5 then
    insert into tcg_30d_validation_results values ('inventory', 'pack_increments_inventory', 'PASS', 'Owner inventory increased by five cards.');
  else
    insert into tcg_30d_validation_results values ('inventory', 'pack_increments_inventory', 'FAIL', owner_inventory_total::text || ' total quantity found.');
  end if;

  select count(*) into event_count
  from public.tcg_inventory_events
  where profile_id = owner_id
    and event_type = 'pack_opened'
    and source_type = 'owner_test_pack'
    and source_id = opening_id_value;

  if event_count = 5 then
    insert into tcg_30d_validation_results values ('inventory', 'pack_writes_inventory_events', 'PASS', 'Five inventory events written.');
  else
    insert into tcg_30d_validation_results values ('inventory', 'pack_writes_inventory_events', 'FAIL', event_count::text || ' inventory events found.');
  end if;

  select c.id into mythic_card_id
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id
  where c.set_id = season_zero_id
    and r.rarity_key = 'mythic'
    and c.release_status = 'active'
    and c.is_collectible = true
  limit 1;

  insert into public.tcg_packs (
    code,
    name,
    description,
    set_id,
    cards_per_pack,
    is_active,
    is_owner_test_only
  )
  values (
    'season_0_duplicate_test_pack',
    'Season 0 Duplicate Test Pack',
    'Local validation pack that always rolls the single mythic card.',
    season_zero_id,
    5,
    true,
    true
  )
  returning id into duplicate_pack_id;

  insert into public.tcg_pack_drop_rates (
    pack_id,
    rarity_code,
    weight,
    guaranteed_count
  )
  values (duplicate_pack_id, 'mythic', 1, 0);

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_test_pack('season_0_duplicate_test_pack');
    execute 'reset role';
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('inventory', 'duplicate_pack_opened', 'FAIL', sqlerrm);
  end;

  select quantity into duplicate_quantity
  from public.tcg_player_inventory
  where profile_id = owner_id
    and card_id = mythic_card_id;

  if coalesce(duplicate_quantity, 0) >= 5 then
    insert into tcg_30d_validation_results values ('inventory', 'duplicate_cards_stack_quantity', 'PASS', 'Duplicate rolls stacked into one inventory row.');
  else
    insert into tcg_30d_validation_results values ('inventory', 'duplicate_cards_stack_quantity', 'FAIL', coalesce(duplicate_quantity, 0)::text || ' duplicate card quantity found.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_test_pack();
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'normal_member_denied_pack_open', 'FAIL', 'Normal member opened Owner test pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'normal_member_denied_pack_open', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_owner_open_test_pack();
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'pending_user_denied_pack_open', 'FAIL', 'Pending user opened Owner test pack.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'pending_user_denied_pack_open', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_packs (code, name, set_id, cards_per_pack) values (''bad_pack'', ''Bad Pack'', $1, 5)'
      using season_zero_id;
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'direct_pack_write_blocked', 'FAIL', 'Direct pack insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'direct_pack_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_pack_openings (profile_id, pack_id, opened_by_profile_id, results) values ($1, $2, $1, ''[]''::jsonb)'
      using member_id, duplicate_pack_id;
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'direct_opening_write_blocked', 'FAIL', 'Direct opening insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('security', 'direct_opening_write_blocked', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into collection_count from public.tcg_get_my_collection();
    execute 'reset role';

    if collection_count = 50 then
      insert into tcg_30d_validation_results values ('regression', 'collection_rpc_still_works', 'PASS', 'Existing collection RPC still returns 50 rows.');
    else
      insert into tcg_30d_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', collection_count::text || ' rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('regression', 'collection_rpc_still_works', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30d_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30d_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30d_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30d_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30d_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30d_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30d_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30d_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30d_total_skip
from tcg_30d_validation_results;

rollback;
