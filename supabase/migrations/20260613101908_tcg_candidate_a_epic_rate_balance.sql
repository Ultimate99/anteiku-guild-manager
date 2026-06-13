-- Milestone 30G-H: TCG Candidate A Epic-rate balance patch.
-- Backend data migration only. No pack price, pack size, pity threshold,
-- duplicate economy, frontend, member release, inventory, wallet, or CP changes.

do $$
declare
  target_pack_id uuid;
  rate_count integer;
  updated_count integer;
  total_weight integer;
begin
  select p.id
  into target_pack_id
  from public.tcg_packs p
  join public.tcg_sets s on s.id = p.set_id
  where p.code = 'season_0_test_pack'
    and p.is_active
    and s.set_key = 'season_0_anteiku_origins'
    and s.release_status = 'active'
  limit 1;

  if target_pack_id is null then
    raise exception 'Season 0 Test Pack is missing or inactive.';
  end if;

  select count(*)
  into rate_count
  from public.tcg_pack_drop_rates
  where pack_id = target_pack_id;

  if rate_count <> 6 then
    raise exception 'Expected 6 Season 0 Test Pack drop-rate rows, found %.', rate_count;
  end if;

  with candidate_rates(rarity_code, weight) as (
    values
      ('common', 6200),
      ('uncommon', 2500),
      ('rare', 900),
      ('epic', 300),
      ('legendary', 90),
      ('mythic', 10)
  ),
  updated_rates as (
    update public.tcg_pack_drop_rates dr
    set weight = candidate_rates.weight
    from candidate_rates
    where dr.pack_id = target_pack_id
      and dr.rarity_code = candidate_rates.rarity_code
    returning dr.rarity_code
  )
  select count(*)
  into updated_count
  from updated_rates;

  if updated_count <> 6 then
    raise exception 'Expected to update 6 Season 0 Test Pack drop-rate rows, updated %.', updated_count;
  end if;

  select coalesce(sum(weight), 0)
  into total_weight
  from public.tcg_pack_drop_rates
  where pack_id = target_pack_id;

  if total_weight <> 10000 then
    raise exception 'Season 0 Test Pack drop-rate total must be 10000, found %.', total_weight;
  end if;

  if exists (
    with candidate_rates(rarity_code, weight) as (
      values
        ('common', 6200),
        ('uncommon', 2500),
        ('rare', 900),
        ('epic', 300),
        ('legendary', 90),
        ('mythic', 10)
    )
    select 1
    from candidate_rates
    left join public.tcg_pack_drop_rates dr
      on dr.pack_id = target_pack_id
     and dr.rarity_code = candidate_rates.rarity_code
     and dr.weight = candidate_rates.weight
    where dr.id is null
  ) then
    raise exception 'Season 0 Test Pack drop rates do not match Candidate A after update.';
  end if;
end;
$$;
