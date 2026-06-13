-- Milestone 30G-I0: Owner-only TCG test state reset.
-- Backend/RPC only. Resets mutable TCG state for the current active Owner
-- profile and leaves catalog, drop-rate, shop, and crafting definitions intact.

create or replace function public.tcg_owner_reset_my_tcg_test_state(
  p_confirm text
)
returns table (
  reset_profile_id uuid,
  inventory_deleted integer,
  inventory_events_deleted integer,
  player_packs_deleted integer,
  pack_inventory_events_deleted integer,
  pack_openings_deleted integer,
  wallets_deleted integer,
  wallet_ledger_deleted integer,
  fragment_wallets_deleted integer,
  fragment_ledger_deleted integer,
  pity_counters_deleted integer,
  reset_at timestamptz,
  message text
)
language plpgsql
volatile
security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor_id uuid := private.tcg_active_member_profile_id();
begin
  if actor_id is null or not private.is_owner(actor_id) then
    raise exception 'Owner access required.';
  end if;

  if p_confirm <> 'RESET_TCG' then
    raise exception 'RESET_TCG confirmation is required.';
  end if;

  delete from public.tcg_inventory_events
  where profile_id = actor_id;
  get diagnostics inventory_events_deleted = row_count;

  delete from public.tcg_fragment_ledger
  where profile_id = actor_id;
  get diagnostics fragment_ledger_deleted = row_count;

  delete from public.tcg_wallet_ledger
  where profile_id = actor_id;
  get diagnostics wallet_ledger_deleted = row_count;

  delete from public.tcg_pack_inventory_events
  where profile_id = actor_id;
  get diagnostics pack_inventory_events_deleted = row_count;

  delete from public.tcg_player_inventory
  where profile_id = actor_id;
  get diagnostics inventory_deleted = row_count;

  delete from public.tcg_player_packs
  where profile_id = actor_id;
  get diagnostics player_packs_deleted = row_count;

  delete from public.tcg_pack_openings
  where profile_id = actor_id;
  get diagnostics pack_openings_deleted = row_count;

  delete from public.tcg_wallets
  where profile_id = actor_id;
  get diagnostics wallets_deleted = row_count;

  delete from public.tcg_fragment_wallets
  where profile_id = actor_id;
  get diagnostics fragment_wallets_deleted = row_count;

  delete from public.tcg_pity_counters
  where profile_id = actor_id;
  get diagnostics pity_counters_deleted = row_count;

  reset_profile_id := actor_id;
  reset_at := now();
  message := 'Owner TCG test state reset complete.';

  return next;
end;
$$;

revoke all on function public.tcg_owner_reset_my_tcg_test_state(text) from public, anon;
grant execute on function public.tcg_owner_reset_my_tcg_test_state(text) to authenticated;
