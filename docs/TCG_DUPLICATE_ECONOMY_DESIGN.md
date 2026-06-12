# TCG Duplicate Economy Design

Milestone 30G-D is a docs-only design specification for the future TCG duplicate economy. It uses the 30G-C recommendation: **Balanced Dust + Soft Pity**. 30G-F1 has since implemented and production-applied the Balanced Dust backend foundation for Anteiku Fragments, duplicate burning, duplicate summary, and missing-card crafting. 30G-F2 has since implemented and production-applied backend-only Soft Pity counters and owned-pack integration. 30G-F3 adds the Owner-only `/tcg` Craft UI for fragments, duplicate burn, missing-card crafting, and read-only pity status. Current production prices, drop weights, pack size, coin grants, production wallet/inventory/fragment/pity data from Codex, and member access remain unchanged.

## Summary

Recommended v1 direction:

- Add a non-premium crafting currency named **Anteiku Fragments**.
- Let players burn duplicates into fragments.
- Let players craft missing Common, Uncommon, Rare, and Epic cards.
- Keep Legendary crafting expensive/gated.
- Disable normal Mythic crafting for v1.
- Add server-side Legendary/Mythic soft pity counters to protect extreme bad luck.
- Keep current low drop rates unchanged.

TCG remains Owner-only until this design is implemented, validated, and approved for member release.

## 30G-F3 Owner UI Status

30G-F3 adds the first Owner-only frontend surface for this design:

- Fragment balance is loaded with `tcg_get_my_fragments()`.
- Burnable duplicate cards are loaded with `tcg_get_my_duplicate_summary()`.
- Burning a duplicate calls `tcg_burn_duplicate_card(p_card_id, p_quantity)` after a confirmation.
- Missing-card crafting calls `tcg_craft_missing_card(p_card_id)` after a confirmation.
- Pity status is read-only and loaded with `tcg_get_my_pity_status()`.
- Mythic crafting remains locked in the UI and backend.
- The frontend displays approved costs and dust values but does not decide authority; backend RPCs remain authoritative.
- No member-facing TCG release exists yet.

## Anteiku Fragments

Anteiku Fragments are a non-premium crafting currency.

Rules:

- Source: duplicate burn only in v1.
- Later source: event rewards only if approved.
- Not purchasable with real money.
- Not the same currency as Anteiku Coins.
- Not transferable between players.
- Backend-authoritative wallet and ledger required.
- Frontend must never directly mutate fragment balances.

Recommended Balanced Dust values:

| Burned duplicate rarity | Fragments gained |
| --- | ---: |
| Common | 2 |
| Uncommon | 5 |
| Rare | 18 |
| Epic | 60 |
| Legendary | 200 |
| Mythic | 700 |

## Duplicate Burn Rules

Players can only burn duplicates.

Rules:

- Burnable quantity is `quantity - 1`.
- A player can never burn their last copy of a card.
- Reject burn quantity `<= 0`.
- Reject burn requests for unowned cards.
- Reject burn requests greater than burnable quantity.
- Burning reduces owned card quantity.
- Burning writes an inventory event.
- Burning writes a fragment ledger event.
- Burn and ledger writes must happen atomically in one backend transaction.

Frontend behavior later:

- Display burnable duplicate quantity from backend data.
- Send only card key and burn quantity.
- Treat backend as authority for quantity and fragment gain.
- Do not calculate final wallet balance client-side.

## Crafting Rules

Crafting should be missing-card focused in v1.

Rules:

- Users can only craft cards they do not own yet.
- Crafting adds exactly 1 card.
- Backend verifies enough fragments.
- Backend verifies card exists, is active, collectible, and belongs to the active/current set.
- Backend rejects already-owned cards under the v1 missing-only rule.
- Crafting writes an inventory event.
- Crafting writes a fragment ledger spend event.
- Crafting and ledger writes must happen atomically.

Recommended Balanced crafting costs:

| Crafted rarity | Fragment cost | v1 status |
| --- | ---: | --- |
| Common | 30 | Enabled |
| Uncommon | 90 | Enabled |
| Rare | 350 | Enabled |
| Epic | 1400 | Enabled |
| Legendary | 5000 | Gated / optional |
| Mythic | 16000 | Future locked / not v1 |

Legendary v1 recommendation:

- Do not enable unrestricted Legendary crafting at member release.
- Prefer one of:
  - Owner-configured event unlock.
  - Once-per-season limit.
  - Long cooldown.
  - Manual release after Owner review.

## Mythic V1 Decision

Mythic should remain prestige/flex in v1.

Recommended:

- Do not allow normal Mythic crafting at member release.
- Mythic can be obtained by raw pull.
- Mythic can be obtained by future event reward if approved.
- Mythic can be obtained by Mythic pity if approved.
- If Mythic crafting remains in config, keep it locked as future-only at 16000 fragments.

Reason:

- 30G-B shows Mythic is a months-long chase under the current low-rate table.
- 30G-C shows duplicate value can reduce frustration without making Mythic common.
- Letting members directly craft Mythic too early would weaken the flex role of the card.

## Soft Pity Rules

Soft pity is now server-side only through the 30G-F2 backend integration.

Counters:

- Track pity per active profile and pack/set.
- Track Legendary pity separately from Mythic pity.
- Count only owned-pack openings. Current Owner-only testing uses `tcg_owner_open_owned_pack(...)`; future member owned-pack openings should use the same backend-only pattern.
- Do not count admin grants.
- Do not count Owner free test packs for production member economy.
- Do not backfill existing Owner test openings; counters start from zero after the 30G-F2 migration.

Legendary pity:

- If a user opens 50 eligible packs without Legendary or better, the next eligible pack guarantees Legendary or better.
- Pulling Legendary or Mythic resets Legendary pity.

Mythic pity:

- If a user opens 150 eligible packs without Mythic, the next eligible pack guarantees Mythic.
- Pulling Mythic resets Mythic pity.

Guarantee behavior:

- Mythic pity has priority if both thresholds are active.
- Guaranteed Legendary rolls from eligible Legendary cards by default in v1.
- Guaranteed Mythic rolls from eligible Mythic cards.
- Prefer normal rarity selection over missing-card selection in v1.
- Missing-card guarantee selection should be a later explicit design, not implied.

Pity display:

- Later UI may show backend-derived progress:
  - Legendary pity: `32 / 50`
  - Mythic pity: `77 / 150`
- Frontend must read pity status from RPC only.
- Frontend must not calculate or store pity authority.

## 30G-F1 Implemented Backend

Implemented and production-applied in `20260612143019_tcg_fragments_duplicate_economy.sql`:

- `tcg_fragment_wallets`
- `tcg_fragment_ledger`
- `tcg_crafting_rules`
- `tcg_get_my_fragments()`
- `tcg_get_my_duplicate_summary()`
- `tcg_burn_duplicate_card(p_card_id uuid, p_quantity integer)`
- `tcg_craft_missing_card(p_card_id uuid)`

Implemented rules:

- Anteiku Fragments are separate from Anteiku Coins.
- Fragment source in v1 is duplicate burn.
- Burns are backend/RPC-only.
- Burnable quantity is `quantity - 1`; last copies cannot be burned.
- Missing-card crafting adds exactly one card.
- Already-owned cards cannot be crafted in v1.
- Mythic crafting is disabled/future locked in v1.
- Legendary crafting is enabled at the approved `5000` fragment cost.
- Fragment wallet, ledger, crafting rules, and inventory mutations remain backend-authoritative.

Validation:

- Focused local validation passed: 37 PASS / 0 FAIL / 0 SKIP.
- Existing TCG regression validations passed for catalog/inventory, pack backend, shop economy, balance report, and pack inventory.
- No CP columns, CP RPC usage, `member_cp`, or `cp_snapshots` usage were added.
- Production read-only verification confirmed the new fragment tables, RLS, RPC grants, seeded rules, active Owner count `1`, and zero CP-named TCG columns.

## 30G-F2 Implemented Backend

Implemented and production-applied in `20260612150113_tcg_soft_pity_backend.sql`:

`tcg_pity_counters`

- `id`
- `profile_id`
- `pack_id`
- `set_id`
- `packs_since_legendary`
- `packs_since_mythic`
- `total_eligible_openings`
- `last_legendary_at`
- `last_mythic_at`
- `last_eligible_opening_at`
- `created_at`
- `updated_at`
- unique `(profile_id, set_id, pack_id)`

Implemented RPC:

- `tcg_get_my_pity_status()`

Implemented integration:

- `tcg_owner_open_owned_pack(...)` counts as pity-eligible for current Owner-only testing.
- `tcg_owner_open_test_pack(...)` free test packs and legacy immediate buy-and-open calls do not count.
- Pack results include safe per-card pity metadata such as `is_pity_guaranteed` and `pity_guaranteed_rarity`.
- Pity updates are transactional with pack consumption, pack opening history, inventory changes, inventory events, and pack inventory events.

Optional config:

- Additional future crafting recipe tables only if rarity-based `tcg_crafting_rules` is not enough.

Implemented pity RPC/helper:

- `tcg_get_my_pity_status()`
- Updated pack-opening helper with pity counter support.

RPC return rules:

- Return only own active-profile fragment balances.
- Return only own duplicate/crafting eligibility.
- Return only own pity counters.
- Do not return CP, admin metadata, auth IDs, or service-role-only data.

## Security Requirements

- Backend/RPC authority only.
- RLS enabled on all fragment and pity tables.
- Revoke broad direct table access.
- No direct fragment wallet writes from frontend.
- No direct inventory burns from frontend.
- No direct pity counter writes from frontend.
- No arbitrary `profile_id` from frontend.
- Active profile resolved server-side.
- No CP joins, `member_cp`, `cp_snapshots`, CP analytics RPCs, or CP-derived data.
- No service-role key in frontend.
- Fragment and pity reads are own-profile only.
- Admin tools, if added later, must be Owner-gated.

## Abuse Protections

- Burn only quantity above 1.
- Reject burn quantity `<= 0`.
- Reject crafting inactive, retired, or non-collectible cards.
- Reject crafting cards outside the current eligible set.
- Reject crafting already-owned cards under the v1 missing-only rule.
- Reject Mythic crafting while Mythic is future locked.
- Ledger every fragment gain and spend.
- Inventory event every burn and craft.
- Pity counters updated transactionally during pack opening.
- Pack opening remains atomic: wallet/pack consumption, pity, card rolls, inventory, events, and counters commit or fail together.
- Avoid client-visible formulas becoming authority.
- Add rate limits or cooldowns later if burn/craft endpoints are abused.

## Release Impact

Member release remains blocked until one of these is true:

- Duplicate burn/crafting backend exists and is validated, or
- Owner explicitly accepts high duplicate pressure without duplicate value.

Additional release gates:

- Pity design approved.
- Member-safe pack/shop RPCs exist.
- Owner/test controls are hidden from members.
- No direct table writes verified.
- No CP exposure verified.
- Backend-only drops verified.
- Fragment ledger and inventory event audit paths validated.
- Mythic v1 lock/gate validated.

## Implementation Sequence Later

Recommended later milestone order:

1. Backend/RPC/RLS for fragments, burn, missing-card crafting, and pity counters.
2. Local validation for burn/craft/pity atomicity and abuse cases.
3. Owner-only UI preview for duplicate burn/craft and pity status.
4. Owner smoke with controlled inventory only.
5. Member-release planning after Owner acceptance.

30G-E backend/RPC/RLS planning is documented in `docs/TCG_DUPLICATE_ECONOMY_IMPLEMENTATION_PLAN.md`.

30G-D and 30G-E are documentation/planning only. No implementation is included in either milestone.
