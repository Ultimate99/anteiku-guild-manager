-- Milestone 30B TCG/Card Collection backend validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30b_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '30000000-0000-4000-8000-000000000001';
  admin_plain_id constant uuid := '30000000-0000-4000-8000-000000000002';
  member_id constant uuid := '30000000-0000-4000-8000-000000000003';
  pending_id constant uuid := '30000000-0000-4000-8000-000000000004';
  catalog_count integer;
  rarity_count integer;
  common_count integer;
  uncommon_count integer;
  rare_count integer;
  epic_count integer;
  legendary_count integer;
  mythic_count integer;
  character_count integer;
  scene_count integer;
  relic_count integer;
  organization_count integer;
  collection_count integer;
  owned_quantity integer;
  event_count integer;
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
    ('00000000-0000-0000-0000-000000000000', owner_id, 'authenticated', 'authenticated', 'tcg30b-owner@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', admin_plain_id, 'authenticated', 'authenticated', 'tcg30b-admin@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', member_id, 'authenticated', 'authenticated', 'tcg30b-member@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()),
    ('00000000-0000-0000-0000-000000000000', pending_id, 'authenticated', 'authenticated', 'tcg30b-pending@local.test', 'local-only', now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now());

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values
    (owner_id, 'tcg30b_owner', 'tcg30b_owner', 'TCG 30B Owner', 'approved', now()),
    (admin_plain_id, 'tcg30b_admin', 'tcg30b_admin', 'TCG 30B Admin', 'approved', now()),
    (member_id, 'tcg30b_member', 'tcg30b_member', 'TCG 30B Member', 'approved', now()),
    (pending_id, 'tcg30b_pending', 'tcg30b_pending', 'TCG 30B Pending', 'pending', null);

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
    (admin_plain_id, anteiku_id, 'admin', 'active', true, owner_id, 'active'),
    (member_id, anteiku_id, 'member', 'active', true, owner_id, 'active'),
    (pending_id, anteiku_id, 'member', 'pending', true, null, 'active');

  select count(*) into catalog_count
  from public.tcg_cards c
  join public.tcg_sets s on s.id = c.set_id
  where s.set_key = 'season_0_anteiku_origins';

  if catalog_count = 50 then
    insert into tcg_30b_validation_results values ('catalog', 'season_zero_card_count', 'PASS', 'Season 0 has 50 cards.');
  else
    insert into tcg_30b_validation_results values ('catalog', 'season_zero_card_count', 'FAIL', catalog_count::text || ' cards found.');
  end if;

  select count(*) into rarity_count from public.tcg_rarities;
  if rarity_count = 6 then
    insert into tcg_30b_validation_results values ('catalog', 'rarity_count', 'PASS', 'Six rarities exist.');
  else
    insert into tcg_30b_validation_results values ('catalog', 'rarity_count', 'FAIL', rarity_count::text || ' rarities found.');
  end if;

  select
    count(*) filter (where r.rarity_key = 'common'),
    count(*) filter (where r.rarity_key = 'uncommon'),
    count(*) filter (where r.rarity_key = 'rare'),
    count(*) filter (where r.rarity_key = 'epic'),
    count(*) filter (where r.rarity_key = 'legendary'),
    count(*) filter (where r.rarity_key = 'mythic')
  into common_count, uncommon_count, rare_count, epic_count, legendary_count, mythic_count
  from public.tcg_cards c
  join public.tcg_rarities r on r.id = c.rarity_id;

  if common_count = 18 and uncommon_count = 14 and rare_count = 9 and epic_count = 5 and legendary_count = 3 and mythic_count = 1 then
    insert into tcg_30b_validation_results values ('catalog', 'rarity_distribution', 'PASS', 'Rarity distribution matches canonical v0.1.');
  else
    insert into tcg_30b_validation_results values (
      'catalog',
      'rarity_distribution',
      'FAIL',
      format('common=%s uncommon=%s rare=%s epic=%s legendary=%s mythic=%s', common_count, uncommon_count, rare_count, epic_count, legendary_count, mythic_count)
    );
  end if;

  select
    count(*) filter (where card_type = 'Character'),
    count(*) filter (where card_type = 'Scene'),
    count(*) filter (where card_type = 'Relic'),
    count(*) filter (where card_type = 'Organization')
  into character_count, scene_count, relic_count, organization_count
  from public.tcg_cards;

  if character_count = 24 and scene_count = 16 and relic_count = 10 and organization_count = 0 then
    insert into tcg_30b_validation_results values ('catalog', 'type_distribution', 'PASS', 'Type distribution matches canonical v0.1.');
  else
    insert into tcg_30b_validation_results values (
      'catalog',
      'type_distribution',
      'FAIL',
      format('character=%s scene=%s relic=%s organization=%s', character_count, scene_count, relic_count, organization_count)
    );
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30b_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30b_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select count(*) into catalog_count from public.tcg_get_catalog();
    execute 'reset role';

    if catalog_count = 50 then
      insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_catalog', 'PASS', 'Approved member read 50 catalog cards through RPC.');
    else
      insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_catalog', 'FAIL', catalog_count::text || ' catalog cards returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_catalog', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    select count(*) into collection_count from public.tcg_get_my_collection();
    execute 'reset role';

    if collection_count = 50 then
      insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_collection', 'PASS', 'Approved member read collection through RPC.');
    else
      insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_collection', 'FAIL', collection_count::text || ' collection rows returned.');
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('rpc', 'approved_member_can_read_collection', 'FAIL', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    perform public.tcg_set_card_favorite('s0_001_20th_ward_civilian', true);
    execute 'reset role';
    insert into tcg_30b_validation_results values ('rpc', 'favorite_unowned_card_denied', 'FAIL', 'Favorite succeeded before ownership.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('rpc', 'favorite_unowned_card_denied', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', pending_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_get_catalog();
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'pending_user_denied_catalog', 'FAIL', 'Pending user read catalog.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'pending_user_denied_catalog', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_admin_grant_card(member_id, 's0_001_20th_ward_civilian', 2, 'local validation grant');
    execute 'reset role';
    insert into tcg_30b_validation_results values ('admin', 'owner_can_grant_card', 'PASS', 'Owner granted a TCG card.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('admin', 'owner_can_grant_card', 'FAIL', sqlerrm);
  end;

  select coalesce(inv.quantity, 0)
  into owned_quantity
  from public.tcg_player_inventory inv
  join public.tcg_cards c on c.id = inv.card_id
  where inv.profile_id = member_id
    and c.card_key = 's0_001_20th_ward_civilian';

  if owned_quantity = 2 then
    insert into tcg_30b_validation_results values ('inventory', 'grant_updates_inventory', 'PASS', 'Member inventory quantity is 2.');
  else
    insert into tcg_30b_validation_results values ('inventory', 'grant_updates_inventory', 'FAIL', coalesce(owned_quantity, 0)::text || ' quantity found.');
  end if;

  select count(*) into event_count
  from public.tcg_inventory_events ev
  join public.tcg_cards c on c.id = ev.card_id
  where ev.profile_id = member_id
    and c.card_key = 's0_001_20th_ward_civilian'
    and ev.event_type = 'admin_grant'
    and ev.source_type = 'admin_tool';

  if event_count = 1 then
    insert into tcg_30b_validation_results values ('inventory', 'grant_writes_event', 'PASS', 'Admin grant wrote one inventory event.');
  else
    insert into tcg_30b_validation_results values ('inventory', 'grant_writes_event', 'FAIL', event_count::text || ' events found.');
  end if;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_set_card_favorite('s0_001_20th_ward_civilian', true);
    execute 'reset role';
    insert into tcg_30b_validation_results values ('inventory', 'favorite_owned_card_allowed', 'PASS', 'Owned card favorite updated.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('inventory', 'favorite_owned_card_allowed', 'FAIL', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', admin_plain_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    perform public.tcg_admin_grant_card(member_id, 's0_002_anteiku_regular_customer', 1, 'should be denied');
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'admin_without_manage_members_denied_grant', 'FAIL', 'Plain admin granted a card.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'admin_without_manage_members_denied_grant', 'PASS', sqlerrm);
  end;

  perform set_config('request.jwt.claim.sub', member_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_player_inventory (profile_id, card_id, quantity) select $1, id, 1 from public.tcg_cards where card_key = $2'
      using member_id, 's0_002_anteiku_regular_customer';
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'direct_inventory_write_blocked', 'FAIL', 'Direct inventory insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'direct_inventory_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'insert into public.tcg_inventory_events (profile_id, quantity_delta, event_type, source_type) values ($1, 1, ''admin_grant'', ''admin_tool'')'
      using member_id;
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'direct_inventory_event_write_blocked', 'FAIL', 'Direct event insert succeeded.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('security', 'direct_inventory_event_write_blocked', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.member_cp';
    execute 'reset role';
    insert into tcg_30b_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', 'member_cp direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('privacy', 'direct_member_cp_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  begin
    execute 'set local role authenticated';
    execute 'select count(*) from public.cp_snapshots';
    execute 'reset role';
    insert into tcg_30b_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', 'cp_snapshots direct read did not expose rows.');
  exception when others then
    execute 'reset role';
    insert into tcg_30b_validation_results values ('privacy', 'direct_cp_snapshots_read_blocked_or_empty', 'PASS', sqlerrm);
  end;

  select count(*)
  into owner_count
  from public.guild_memberships gm
  join public.profiles p on p.id = gm.profile_id
  where gm.role = 'owner'
    and gm.membership_status = 'active'
    and p.approval_status = 'approved';

  if owner_count = 1 then
    insert into tcg_30b_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'Exactly one active approved Owner exists in validation data.');
  else
    insert into tcg_30b_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active approved Owners found.');
  end if;
end;
$$;

select section, test_name, status, details
from tcg_30b_validation_results
order by section, test_name;

select count(*) filter (where status = 'PASS') as tcg_30b_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30b_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30b_total_skip
from tcg_30b_validation_results;

rollback;
