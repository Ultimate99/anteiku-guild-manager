# TCG Duplicate Economy Implementation Plan

Milestone 30G-E started as a docs-only backend/RPC/RLS implementation plan for the approved duplicate economy direction: **Balanced Dust + Soft Pity**. Milestone 30G-F1 has now implemented and production-applied the Balanced Dust backend foundation for Anteiku Fragments, duplicate burning, duplicate summary, and missing-card crafting. Milestone 30G-F2 has now implemented and production-applied backend-only Soft Pity counters and owned-pack integration. Milestone 30G-F3 adds the Owner-only frontend Craft window for manual Owner review of fragments, duplicate burning, missing-card crafting, and pity status.

## Summary

30G-F1 implemented:

- Anteiku Fragments as a non-premium duplicate-burn crafting currency.
- Backend-only duplicate burn and missing-card craft RPCs.
- A locked crafting rules table for approved dust values and crafting costs.
- Focused validation proving no direct writes, no arbitrary `profile_id`, no CP exposure, and atomic inventory/fragment updates.

30G-F2 implemented:

- Backend-only Legendary/Mythic pity counters.
- Pack-opening integration for pity updates.
- Focused validation proving atomic pity updates.

30G-F3 implements:

- Owner-only `/tcg` Craft hub window.
- RPC-only service wrappers for fragment balance, duplicate summary, burn, craft, and pity status.
- Fragment HUD, duplicate burn cards, missing-card craft cards, and read-only pity progress bars.
- Confirmation prompts before burn/craft mutations.
- No backend, RLS, price, drop-rate, fragment-value, crafting-cost, or pity-threshold changes.

Current production values stay unchanged:

- Pack price: 100 Anteiku Coins.
- Pack size: 5.
- Drop weights: Common 6000, Uncommon 2500, Rare 1000, Epic 400, Legendary 90, Mythic 10.

## 30G-F1 Implementation Status

Implemented migration:

- `supabase/migrations/20260612143019_tcg_fragments_duplicate_economy.sql`

Implemented tables:

- `tcg_fragment_wallets`
- `tcg_fragment_ledger`
- `tcg_crafting_rules`

Implemented RPCs:

- `tcg_get_my_fragments()`
- `tcg_get_my_duplicate_summary()`
- `tcg_burn_duplicate_card(p_card_id uuid, p_quantity integer)`
- `tcg_craft_missing_card(p_card_id uuid)`

Implemented security posture:

- RLS enabled on all new tables.
- Direct grants revoked from `public`, `anon`, and `authenticated`.
- Mutations are RPC-only.
- Active profile is resolved server-side through `private.tcg_active_member_profile_id()`.
- No arbitrary `profile_id` inputs.
- No CP joins, CP tables, CP RPCs, or CP-derived fields.

Validation:

- Local `supabase db reset` applied the migration cleanly.
- Focused validation `supabase/tests/tcg_30g_fragments_validation.sql`: 37 PASS / 0 FAIL / 0 SKIP.
- Existing TCG validations passed:
  - 30B catalog/inventory: 19 PASS / 0 FAIL / 0 SKIP.
  - 30D pack backend: 18 PASS / 0 FAIL / 0 SKIP.
  - 30E shop economy: 32 PASS / 0 FAIL / 0 SKIP.
  - 30F balance report: 20 PASS / 0 FAIL / 0 SKIP.
  - 30F pack inventory: 31 PASS / 0 FAIL / 0 SKIP.

Known validation note:

- Broad `local_validation_anteiku.sql` still reports unrelated cosmetics catalog expectation failures from current avatar/frame counts. The 30G-F1-specific validation, TCG regressions, and CP privacy checks passed.

Production rollout:

- Production dry-run showed only `20260612143019_tcg_fragments_duplicate_economy.sql` pending.
- Migration applied to production project `mzflfyxxkascrfpteexz`.
- Remote migration list shows `20260612143019` applied.
- Read-only verification confirmed:
  - `tcg_fragment_wallets`, `tcg_fragment_ledger`, and `tcg_crafting_rules` exist.
  - RLS is enabled on all new fragment tables.
  - No broad direct `anon`/`authenticated` grants exist on the new fragment tables.
  - `tcg_get_my_fragments`, `tcg_get_my_duplicate_summary`, `tcg_burn_duplicate_card`, and `tcg_craft_missing_card` exist with authenticated execute grants.
  - Balanced crafting rules are seeded.
  - Active Owner count remains `1`.
  - TCG tables still have zero CP-named columns.
  - Existing CP tables remain RLS-protected.
- No production burn/craft mutation was performed.

Still future:

- Owner/member frontend UI for burn/craft.
- Owner/member frontend UI for pity status.
- Member-facing TCG release.

## 30G-F2 Implementation Status

Implemented migration:

- `supabase/migrations/20260612150113_tcg_soft_pity_backend.sql`

Implemented table:

- `tcg_pity_counters`

Implemented RPC/helper behavior:

- `tcg_get_my_pity_status()` returns own active-profile pity status and zero values when no counter exists.
- The private pack-opening helper now checks the backend-owned pack-inventory marker and updates pity only for owned-pack openings.
- `tcg_owner_open_owned_pack(...)` counts as eligible for current Owner-only testing.
- Free Owner test packs, admin grants, smoke grants, and legacy immediate buy-and-open calls do not count.
- Mythic pity has priority at `150`; Legendary pity triggers at `50`.
- Guarantees choose a random active collectible card of the guaranteed rarity in the pack/set, with no missing-card bias in v1.
- Existing Owner openings are not backfilled; counters start from zero after migration.

Implemented security posture:

- RLS enabled on `tcg_pity_counters`.
- Direct grants revoked from `public`, `anon`, and `authenticated`.
- Pity mutation is backend-only and transactional with pack consumption, inventory changes, inventory events, pack opening history, and pack inventory events.
- No arbitrary `profile_id`, no CP joins, no CP tables, and no CP-derived fields.

Validation:

- Focused validation `supabase/tests/tcg_30g_pity_validation.sql`: 22 PASS / 0 FAIL / 0 SKIP.
- Existing TCG validations passed:
  - 30B catalog/inventory: 19 PASS / 0 FAIL / 0 SKIP.
  - 30D pack backend: 18 PASS / 0 FAIL / 0 SKIP.
  - 30E shop economy: 32 PASS / 0 FAIL / 0 SKIP.
  - 30F balance report: 20 PASS / 0 FAIL / 0 SKIP.
  - 30F pack inventory: 31 PASS / 0 FAIL / 0 SKIP.
  - 30G-F1 fragments/crafting: 37 PASS / 0 FAIL / 0 SKIP.

Production rollout:

- Production dry-run showed only `20260612150113_tcg_soft_pity_backend.sql` pending.
- Migration applied to production project `mzflfyxxkascrfpteexz`.
- Remote migration list shows `20260612150113` applied.
- Read-only verification confirmed:
  - `tcg_pity_counters` exists.
  - RLS is enabled.
  - No broad direct `anon`/`authenticated` grants exist on the table.
  - `tcg_get_my_pity_status()` exists with authenticated execute grant.
  - Active Owner count remains `1`.
  - TCG tables still have zero CP-named columns.
- No production pack opening or pity-counter mutation was performed.

## Existing System Inspection

Relevant existing objects:

- `tcg_cards`: Season 0 catalog rows with set, rarity, type, release status, collectibility, art path, and sort metadata.
- `tcg_player_inventory`: active-profile card ownership with `quantity`, acquired timestamps, favorite/locked flags, and unique `(profile_id, card_id)`.
- `tcg_inventory_events`: append-only card inventory event log currently expanded by pack/shop milestones for `admin_grant` and `pack_opened` style mutations.
- `tcg_packs`: pack catalog with code, set, `cards_per_pack`, `is_active`, and `is_owner_test_only`.
- `tcg_pack_drop_rates`: backend rarity weights per pack.
- `tcg_pack_openings`: pack opening result log with profile, pack, JSON result payload, source, and timestamp.
- `tcg_wallets`, `tcg_wallet_ledger`, `tcg_shop_items`: Anteiku Coins owner-test shop/economy foundation.
- `tcg_player_packs`, `tcg_pack_inventory_events`: owned pack inventory and pack quantity event log.

Relevant helper/RPC patterns:

- `private.tcg_active_member_profile_id()` resolves the current active profile server-side and requires approved active profile status.
- `private.active_admin_profile_id()` and `private.is_owner(...)` are used by Owner/admin-only TCG analytics/grant paths.
- Existing TCG tables enable RLS and revoke broad table grants from `public`, `anon`, and `authenticated`.
- Existing frontend access goes through `security definer` RPCs granted to `authenticated`.
- Existing pack-opening logic is centralized in private helper code that creates `tcg_pack_openings`, rolls cards, updates `tcg_player_inventory`, writes `tcg_inventory_events`, and returns result payloads.
- Existing validation tests use rollback-wrapped local SQL files with fake auth users/profiles, `set local role authenticated`, result tables, PASS/FAIL rows, and CP-column/no-direct-write checks.

Implementation should follow those patterns: RPC-only writes, active profile server-side, RLS enabled, broad grants revoked, local rollback validation, and no CP joins.

## Future Tables

### `tcg_fragment_wallets`

Purpose: store Anteiku Fragment balances per active profile.

Schema:

```sql
create table public.tcg_fragment_wallets (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_fragment_wallets_profile_uidx unique (profile_id)
);
```

Indexes/triggers:

- Unique `(profile_id)` constraint.
- Index `(profile_id, updated_at desc)`.
- `set_updated_at` trigger on update.

RLS/grants:

- Enable RLS.
- Revoke all direct table grants from `public`, `anon`, `authenticated`.
- Prefer RPC-only reads/writes for v1. No direct select policy is required if table grants remain revoked.

### `tcg_fragment_ledger`

Purpose: immutable Anteiku Fragment gain/spend ledger.

Schema:

```sql
create table public.tcg_fragment_ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  amount_delta integer not null check (amount_delta <> 0),
  balance_after integer not null check (balance_after >= 0),
  transaction_type text not null
    check (transaction_type in ('duplicate_burn', 'missing_card_craft', 'admin_adjustment', 'event_reward')),
  source text,
  reference_type text
    check (reference_type is null or reference_type in ('tcg_player_inventory', 'tcg_cards', 'tcg_inventory_events', 'tcg_admin_tools', 'tcg_events')),
  reference_id uuid,
  card_id uuid references public.tcg_cards(id) on delete restrict,
  actor_profile_id uuid references public.profiles(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
```

Indexes:

- `(profile_id, created_at desc)`.
- `(transaction_type, created_at desc)`.
- `(card_id, created_at desc)`.
- Optional GIN index on `metadata` only if future queries require it.

RLS/grants:

- Enable RLS.
- Revoke all direct grants from `public`, `anon`, `authenticated`.
- V1 ledger access should be RPC-only and own-profile scoped.

### `tcg_pity_counters`

Purpose: track pity progress per profile, set, and pack.

Schema:

```sql
create table public.tcg_pity_counters (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  set_id uuid not null references public.tcg_sets(id) on delete restrict,
  pack_id uuid not null references public.tcg_packs(id) on delete restrict,
  packs_since_legendary integer not null default 0 check (packs_since_legendary >= 0),
  packs_since_mythic integer not null default 0 check (packs_since_mythic >= 0),
  last_legendary_at timestamptz,
  last_mythic_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint tcg_pity_counters_profile_set_pack_uidx unique (profile_id, set_id, pack_id)
);
```

Indexes/triggers:

- Unique `(profile_id, set_id, pack_id)`.
- Index `(profile_id, updated_at desc)`.
- Index `(pack_id, profile_id)`.
- `set_updated_at` trigger on update.

RLS/grants:

- Enable RLS.
- Revoke all direct grants from `public`, `anon`, `authenticated`.
- V1 pity access should be through `tcg_get_my_pity_status(...)` only.

### `tcg_crafting_rules`

Recommendation: use a locked table seeded by migration for v1, not hidden hardcoded constants.

Reason:

- Approved values are inspectable and testable.
- Mythic can be explicitly present but inactive/future locked.
- Changes require reviewed SQL migration, not frontend edits.
- Direct client writes remain denied.

Schema:

```sql
create table public.tcg_crafting_rules (
  rarity_code text primary key references public.tcg_rarities(rarity_key) on update cascade on delete restrict,
  dust_value integer not null check (dust_value >= 0),
  crafting_cost integer not null check (crafting_cost > 0),
  is_craftable boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Seed values:

| Rarity | Dust value | Craft cost | v1 craftable |
| --- | ---: | ---: | --- |
| Common | 2 | 30 | yes |
| Uncommon | 5 | 90 | yes |
| Rare | 18 | 350 | yes |
| Epic | 60 | 1400 | yes |
| Legendary | 200 | 5000 | no by default / gated |
| Mythic | 700 | 16000 | no |

RLS/grants:

- Enable RLS.
- Revoke broad direct writes.
- Direct read can remain denied in v1; RPCs can include rule-derived values where needed.

## Future RPC Contracts

All public RPCs should be `security definer`, set `search_path = pg_catalog, public, private, auth`, granted to `authenticated`, and enforce active-profile access internally.

### `tcg_get_my_fragments()`

Input: none.

Behavior:

- Resolve `actor_id := private.tcg_active_member_profile_id()`.
- Return own Anteiku Fragment balance.
- Create no rows as a read side effect unless project style later allows wallet initialization; recommended v1 read returns `0` when no wallet exists.

Return:

- `profile_id uuid`
- `balance integer`
- `updated_at timestamptz nullable`

### `tcg_get_my_duplicate_summary()`

Input: none.

Behavior:

- Resolve active profile.
- Return owned cards where `quantity > 1`.
- Compute `burnable_quantity = quantity - 1`.
- Join active card, set, rarity, and crafting rule data.
- Do not return CP, auth IDs, private admin fields, or other profiles.

Return fields:

- `card_id uuid`
- `card_key text`
- `card_no text`
- `card_name text`
- `rarity_code text`
- `rarity_name text`
- `quantity integer`
- `burnable_quantity integer`
- `dust_value integer`
- `estimated_fragment_gain integer`
- `art_path text`

### `tcg_burn_duplicate_card(p_card_id uuid, p_quantity integer)`

Behavior:

- Resolve active profile server-side.
- Reject `p_quantity <= 0`.
- Lock the inventory row `for update`.
- Reject unowned card.
- Reject if `quantity - 1 < p_quantity`.
- Fetch active crafting rule by card rarity.
- Calculate fragments gained as `p_quantity * dust_value`.
- Insert/update `tcg_fragment_wallets`.
- Decrement `tcg_player_inventory.quantity`.
- Preserve acquired timestamps if quantity remains positive.
- Write `tcg_inventory_events` with `quantity_delta = -p_quantity`, `event_type = 'duplicate_burned'`, `source_type = 'duplicate_economy'`.
- Write `tcg_fragment_ledger` with `transaction_type = 'duplicate_burn'`.
- Return updated card quantity and fragment balance.
- Entire flow is one transaction.

Return fields:

- `card_id uuid`
- `card_key text`
- `burned_quantity integer`
- `fragments_gained integer`
- `new_card_quantity integer`
- `fragment_balance integer`
- `inventory_event_id uuid`
- `fragment_ledger_id uuid`

### `tcg_craft_missing_card(p_card_id uuid)`

Behavior:

- Resolve active profile server-side.
- Lock or create fragment wallet row `for update`.
- Verify target card exists, active, collectible, and belongs to active/current set.
- Verify rarity rule exists, is active, and `is_craftable = true`.
- Reject Mythic while `is_craftable = false`.
- Reject already-owned card for v1 missing-only crafting.
- Reject insufficient fragments.
- Deduct crafting cost from wallet.
- Insert or update `tcg_player_inventory` to quantity `1`.
- Write `tcg_inventory_events` with `quantity_delta = 1`, `event_type = 'crafted'`, `source_type = 'duplicate_economy'`.
- Write `tcg_fragment_ledger` with negative `amount_delta`, `transaction_type = 'missing_card_craft'`.
- Return crafted card and remaining fragment balance.
- Entire flow is one transaction.

Return fields:

- `card_id uuid`
- `card_key text`
- `card_name text`
- `rarity_code text`
- `fragments_spent integer`
- `fragment_balance integer`
- `new_card_quantity integer`
- `inventory_event_id uuid`
- `fragment_ledger_id uuid`

### `tcg_get_my_pity_status(p_pack_code text default 'season_0_test_pack')`

Behavior:

- Resolve active profile.
- Resolve active pack and set.
- Return existing pity counters or zero values if none exist.
- No writes in read RPC.

Return fields:

- `profile_id uuid`
- `pack_id uuid`
- `pack_code text`
- `set_id uuid`
- `set_key text`
- `packs_since_legendary integer`
- `legendary_threshold integer` fixed at `50`
- `packs_since_mythic integer`
- `mythic_threshold integer` fixed at `150`
- `legendary_ready boolean`
- `mythic_ready boolean`
- `last_legendary_at timestamptz`
- `last_mythic_at timestamptz`

### Pack Opening Helper Update

Future implementation should update the private pack-opening helper rather than letting frontend or public RPCs calculate pity.

Required changes:

- Add parameters or internal source checks to determine whether a pack opening is pity-eligible.
- Resolve/create `tcg_pity_counters` row `for update` before rolling.
- If Mythic pity is active, guarantee Mythic in one slot.
- Else if Legendary pity is active, guarantee Legendary or better in one slot.
- Roll remaining slots using current production weights.
- After all cards are known:
  - Increment counters for eligible opening.
  - Reset Legendary counter to `0` if Legendary or Mythic was pulled.
  - Reset Mythic counter to `0` if Mythic was pulled.
  - Update `last_legendary_at` and/or `last_mythic_at`.
- Write pity metadata into `tcg_pack_openings.results` or opening metadata only if safe and useful.
- Keep wallet/pack consumption, pity update, opening row, inventory events, and pack inventory events atomic.

## Pity Implementation Plan

Eligible openings:

- Future member-eligible shop packs count.
- Future member-owned packs purchased through member-safe shop count.
- Admin grants do not count.
- Owner free test packs do not count for production member economy.
- Current Owner-only test shop/opening paths should remain Owner-only and should not become member pity authority until member-safe pack flows exist.

Priority:

- If Mythic pity and Legendary pity are both active, Mythic guarantee takes priority.
- Mythic also satisfies Legendary-or-better and should reset both counters.
- Legendary pity guarantees Legendary or better.
- Mythic pity guarantees Mythic.

Selection:

- V1 guarantees by rarity, not missing-card preference.
- Guaranteed Legendary-or-better should use backend-controlled selection from active eligible Legendary/Mythic cards.
- Missing-card bias is deferred because it changes completion speed and should be separately approved.

UI data later:

- UI may show `Legendary pity: 32 / 50`.
- UI may show `Mythic pity: 77 / 150`.
- UI must read these counters from `tcg_get_my_pity_status(...)`.
- UI must not store or calculate pity authority.

## RLS / Security Plan

Table posture:

- Enable RLS on `tcg_fragment_wallets`, `tcg_fragment_ledger`, `tcg_pity_counters`, and `tcg_crafting_rules`.
- Revoke all direct table grants from `public`, `anon`, and `authenticated`.
- Use RPC-only writes and preferably RPC-only reads for v1.

Identity:

- Use `private.tcg_active_member_profile_id()` for member duplicate economy RPCs.
- Do not accept arbitrary `profile_id`.
- Use Owner/admin helpers only for future admin tools, not member burn/craft.

Privacy:

- Do not join or return normal CP.
- Do not use `member_cp`, `cp_snapshots`, CP analytics RPCs, or CP-derived stats.
- Do not return auth IDs, emails, or private admin metadata.

Function grants:

- Revoke function execute from `public` and `anon`.
- Grant execute to `authenticated`.
- Functions enforce auth and active profile internally.

## Abuse Protections

- Burn rejects unowned cards.
- Burn rejects zero/negative quantity.
- Burn rejects quantities above `quantity - 1`.
- Burn never removes last copy.
- Craft rejects nonexistent, inactive, retired, non-collectible, or wrong-set cards.
- Craft rejects already-owned cards under missing-only v1.
- Craft rejects Mythic while future locked.
- Craft rejects insufficient fragment balance.
- Ledger `balance_after` must match wallet update.
- Inventory events must match inventory mutations.
- Pity counters update transactionally during eligible pack opening.
- Pack opening must remain atomic.
- Duplicate double-submit is controlled with `for update` locks on inventory and fragment wallet rows.
- Craft double-submit is controlled with wallet and inventory locks plus missing-only check.
- Pity double-submit is controlled by locking `tcg_pity_counters` and pack inventory rows in the same transaction.

## Validation Plan

Future focused validation SQL should include:

- Fragment tables exist.
- RLS enabled on fragment/pity/rules tables.
- Broad direct table grants revoked.
- `tcg_get_my_fragments()` returns own balance only.
- Normal member cannot read another fragment wallet.
- Approved member can get duplicate summary.
- Pending/restricted user denied.
- Burn duplicate succeeds when quantity > 1.
- Burn last copy rejected.
- Burn zero/negative rejected.
- Burn unowned card rejected.
- Burn writes inventory event.
- Burn writes fragment ledger.
- Burn updates fragment balance.
- Craft missing card succeeds with enough fragments.
- Craft owned card rejected.
- Craft Mythic rejected in v1.
- Craft inactive/retired card rejected.
- Craft insufficient fragments rejected.
- Craft writes inventory event.
- Craft writes fragment ledger.
- Pity counters create/update after eligible pack open.
- Legendary pity triggers after threshold.
- Mythic pity triggers after threshold.
- Mythic pity priority wins if both pity counters are active.
- Owner free test pack does not count for production pity if intended.
- Normal member cannot direct write new tables.
- No CP-named columns added to TCG schema.
- Direct `member_cp` and `cp_snapshots` protections remain unchanged.
- Existing 30B/30D/30E/30F TCG validations still pass.
- Active Owner count remains 1.

## Rollout Plan For Future Implementation

Future implementation milestone should follow this sequence:

1. Create one focused local migration for fragment wallet, ledger, pity counters, crafting rules, event constraint updates, and RPCs.
2. Add focused local validation SQL.
3. Run local `db reset` only in local/disposable environment.
4. Run focused duplicate economy validation.
5. Run existing TCG regression validations.
6. Run `npm.cmd run build` if frontend source changes exist or as a release sanity check.
7. Production dry-run only after local validation passes.
8. Proceed only if dry-run shows exactly the expected migration and no drift/destructive surprises.
9. Apply production migration only after explicit approval.
10. Perform read-only production DB verification.
11. Do not perform production burn/craft/pity mutation smoke unless explicitly approved.

No Supabase commands are part of 30G-E itself.

## Member Release Impact

Member release remains blocked until:

- Duplicate economy backend exists.
- Duplicate economy UI exists.
- Pity behavior is validated.
- Member-safe pack/shop RPCs exist.
- Owner/dev controls are hidden from members.
- Abuse tests pass.
- No CP exposure is verified.
- No direct table writes are verified.
- Backend-only pack drops are verified.

30G-E can be marked complete once this implementation plan and handoff docs are updated and validation passes.
