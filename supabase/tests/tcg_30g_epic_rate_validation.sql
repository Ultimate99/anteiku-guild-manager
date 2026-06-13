-- Milestone 30G-H Candidate A Epic-rate validation.
-- LOCAL/DISPOSABLE SUPABASE ONLY.
-- Do not run against production. Uses fake UUIDs/emails and rolls back.

begin;

create temp table tcg_30g_epic_rate_validation_results (
  section text not null,
  test_name text not null,
  status text not null check (status in ('PASS', 'FAIL', 'SKIP')),
  details text
) on commit drop;

do $$
declare
  anteiku_id constant uuid := '00000000-0000-0000-0000-000000000101';
  owner_id constant uuid := '3a000000-0000-4000-8000-000000000001';
  target_pack_id uuid;
  target_set_id uuid;
  mismatch_count integer;
  total_weight integer;
  legacy_high_rarity_count integer;
  open_result record;
  remaining_pack_quantity integer;
  counter_row record;
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
  values (
    '00000000-0000-0000-0000-000000000000',
    owner_id,
    'authenticated',
    'authenticated',
    'tcg30gh-owner@local.test',
    'local-only',
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
  );

  insert into public.profiles (id, username, profile_slug, ign, approval_status, approved_at)
  values (owner_id, 'tcg30gh_owner', 'tcg30gh_owner', 'TCG 30G-H Owner', 'approved', now());

  insert into public.guild_memberships (
    profile_id,
    guild_id,
    role,
    membership_status,
    is_primary,
    assigned_by,
    roster_status
  )
  values (owner_id, anteiku_id, 'owner', 'active', true, owner_id, 'active');

  select p.id, p.set_id
  into target_pack_id, target_set_id
  from public.tcg_packs p
  join public.tcg_sets s on s.id = p.set_id
  where p.code = 'season_0_test_pack'
    and s.set_key = 'season_0_anteiku_origins'
    and p.cards_per_pack = 5
    and p.is_active
    and s.release_status = 'active';

  if target_pack_id is not null then
    insert into tcg_30g_epic_rate_validation_results values ('seed', 'season_0_test_pack_exists', 'PASS', 'Season 0 Test Pack exists and still opens 5 cards.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('seed', 'season_0_test_pack_exists', 'FAIL', 'Season 0 Test Pack missing or mutated.');
  end if;

  with expected(rarity_code, weight) as (
    values
      ('common', 6200),
      ('uncommon', 2500),
      ('rare', 900),
      ('epic', 300),
      ('legendary', 90),
      ('mythic', 10)
  )
  select count(*)
  into mismatch_count
  from expected e
  full outer join public.tcg_pack_drop_rates dr
    on dr.pack_id = target_pack_id
   and dr.rarity_code = e.rarity_code
  where e.rarity_code is null
     or dr.rarity_code is null
     or dr.weight <> e.weight;

  if mismatch_count = 0 then
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'candidate_a_weights_exact', 'PASS', 'Season 0 Test Pack matches Candidate A weights.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'candidate_a_weights_exact', 'FAIL', mismatch_count::text || ' mismatched/missing/extra rates.');
  end if;

  select coalesce(sum(weight), 0)
  into total_weight
  from public.tcg_pack_drop_rates
  where pack_id = target_pack_id;

  if total_weight = 10000 then
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'candidate_a_total_weight_10000', 'PASS', 'Drop-rate total remains 10000.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'candidate_a_total_weight_10000', 'FAIL', total_weight::text || ' total weight.');
  end if;

  select count(*)
  into legacy_high_rarity_count
  from public.tcg_pack_drop_rates
  where pack_id = target_pack_id
    and (
      (rarity_code = 'legendary' and weight = 90)
      or (rarity_code = 'mythic' and weight = 10)
    );

  if legacy_high_rarity_count = 2 then
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'legendary_mythic_unchanged', 'PASS', 'Legendary and Mythic weights are unchanged.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('drop_rates', 'legendary_mythic_unchanged', 'FAIL', legacy_high_rarity_count::text || ' matching high-rarity rates found.');
  end if;

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

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);

  begin
    execute 'set local role authenticated';
    select * into open_result from public.tcg_owner_open_owned_pack();
    execute 'reset role';

    if open_result.opening_id is not null
       and open_result.pack_code = 'season_0_test_pack'
       and open_result.cards_opened = 5
       and jsonb_array_length(open_result.results) = 5 then
      insert into tcg_30g_epic_rate_validation_results values ('pack_open', 'owned_pack_still_opens_five_cards', 'PASS', 'Owned-pack opening still returns exactly 5 cards.');
    else
      insert into tcg_30g_epic_rate_validation_results values ('pack_open', 'owned_pack_still_opens_five_cards', 'FAIL', coalesce(open_result::text, 'No owned-open result.'));
    end if;
  exception when others then
    execute 'reset role';
    insert into tcg_30g_epic_rate_validation_results values ('pack_open', 'owned_pack_still_opens_five_cards', 'FAIL', sqlerrm);
  end;

  select coalesce(sum(quantity), 0)
  into remaining_pack_quantity
  from public.tcg_player_packs
  where profile_id = owner_id
    and pack_id = target_pack_id;

  if remaining_pack_quantity = 0 then
    insert into tcg_30g_epic_rate_validation_results values ('pack_open', 'owned_pack_consumed_once', 'PASS', 'Owned pack quantity decreased by 1.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('pack_open', 'owned_pack_consumed_once', 'FAIL', coalesce(remaining_pack_quantity, 0)::text || ' packs remain.');
  end if;

  select *
  into counter_row
  from public.tcg_pity_counters
  where profile_id = owner_id
    and set_id = target_set_id
    and pack_id = target_pack_id;

  if counter_row.total_eligible_openings = 1
     and counter_row.packs_since_legendary >= 0
     and counter_row.packs_since_mythic >= 0 then
    insert into tcg_30g_epic_rate_validation_results values ('pity', 'owned_pack_still_updates_pity', 'PASS', 'Owned-pack opening still updates pity counters.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('pity', 'owned_pack_still_updates_pity', 'FAIL', coalesce(counter_row::text, 'No pity counter row.'));
  end if;

  select count(*) into cp_named_column_count
  from information_schema.columns
  where table_schema = 'public'
    and table_name like 'tcg_%'
    and column_name ilike '%cp%';

  if cp_named_column_count = 0 then
    insert into tcg_30g_epic_rate_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'PASS', 'No TCG columns contain CP names.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('privacy', 'tcg_schema_has_no_cp_columns', 'FAIL', cp_named_column_count::text || ' CP-like columns found.');
  end if;

  select count(*)
  into owner_count
  from public.guild_memberships
  where role = 'owner'
    and membership_status = 'active';

  if owner_count = 1 then
    insert into tcg_30g_epic_rate_validation_results values ('regression', 'active_owner_count_remains_one', 'PASS', 'One active Owner remains.');
  else
    insert into tcg_30g_epic_rate_validation_results values ('regression', 'active_owner_count_remains_one', 'FAIL', owner_count::text || ' active Owners found.');
  end if;
end;
$$;

select *
from tcg_30g_epic_rate_validation_results
order by
  case status when 'FAIL' then 1 when 'SKIP' then 2 else 3 end,
  section,
  test_name;

select count(*) filter (where status = 'PASS') as tcg_30g_epic_rate_total_pass,
       count(*) filter (where status = 'FAIL') as tcg_30g_epic_rate_total_fail,
       count(*) filter (where status = 'SKIP') as tcg_30g_epic_rate_total_skip
from tcg_30g_epic_rate_validation_results;

rollback;
