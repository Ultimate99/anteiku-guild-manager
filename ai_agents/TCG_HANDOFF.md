# TCG/Card Collection Handoff

Milestone 30A planning is complete. No backend, frontend, SQL, Supabase, or production behavior was changed.

## Current Status

- Milestone 30C-A Owner-only Card Collection preview UI is implemented and deployed in production through commit `dbb67da feat: add owner tcg collection preview`.
- Milestone 30C-A2 Owner-only smoke grant control is implemented and deployed in production through commit `e96a489 feat: add owner tcg smoke grant`.
- Milestone 30C-B TCG album visual polish and repo-served asset-pipeline notes are implemented.
- Milestone 30C-C adds temporary generated art assets for only the five Owner smoke-test cards.
- Milestone 30C-D adds temporary generated art assets for all 50 Season 0 cards.
- Milestone 30D-A adds Owner-only test pack backend/RPC support and is production-applied through `20260601000200_tcg_owner_pack_backend.sql`.
- Milestone 30D-B adds the Owner-only `/tcg` pack preview/opening UI and is deployed through commit `fa50b33 feat: add owner tcg pack preview`.
- Milestone 30E-A adds the Owner-only shop/economy backend/RPC foundation and is production-applied through `20260601000300_tcg_owner_shop_economy.sql`.
- Milestone 30E-B adds the Owner-only `/tcg` shop/economy preview UI and is deployed through commit `8e7eb73 feat: add owner tcg shop preview`.
- Milestone 30E-C polishes the Owner-only `/tcg` shop, wallet, and pack reveal UX and is deployed through commit `053f27d style: polish owner tcg shop ux`.
- Milestone 30E-D refactors the Owner-only `/tcg` preview into a compact Album/Packs/Shop/Owner Lab hub and is deployed through commit `d1f4c4a style: add compact tcg hub layout`.
- Milestone 30F-A adds Owner-only TCG balance/economy/pack analytics backend support and is production-applied through `20260601000400_tcg_owner_balance_report.sql`.
- Milestone 30F-B adds Owner-only TCG pack inventory backend support and is production-applied through `20260601000500_tcg_owner_pack_inventory.sql`.
- Milestone 30F-C adds the Owner-only `/tcg` pack inventory/opening UI and is deployed through commit `ada2b74 feat: add tcg pack inventory opening ui`.
- Milestone 30F-D adds temporary Season 0 pack-front and card-back assets and is deployed through commit `6bcebab feat: add tcg pack and card back assets`.
- Milestone 30F-E adds the compact TCG pack inventory UI hotfix and is deployed through commit `bc3c705 fix: compact tcg pack inventory ui`.
- Milestone 30F-F adds the TCG pack/reveal UI polish hotfix and is deployed through commit `e77a385 style: polish tcg pack reveal ui`.
- Milestone 30F-G wires the replaced pack-front and real card-back assets into the Owner-only pack/reveal flow and is deployed through commit `332e38f fix: use tcg card back for reveal cards`.
- Milestone 30F-H polishes the Owner-only `/tcg` UI across Album, Packs, Shop, Owner Lab, and reveal overlay and is deployed through commit `3d92c37 style: polish owner tcg ui`.
- Milestone 30F-I makes the Owner-only Packs and Shop windows compact/windowed instead of full-width item panels and is deployed through commit `14219fe style: make tcg pack shop windows compact`.
- Milestone 30F-J slims the Owner-only Packs/Shop item windows and turns the wallet into a compact currency HUD, deployed through commit `7840366 style: slim tcg pack shop wallet ui`.
- Milestone 30F-K replaces the Owner-only wallet HUD glowing square with a CSS wallet/currency icon, deployed through commit `07d65a9 style: polish tcg wallet hud icon`.
- Milestone 30F-L centers the Owner-only Packs and Shop item windows inside their active panels, deployed through commit `ff94b1c style: center tcg shop pack windows`.
- Milestone 30F-M adds the Owner-only read-only Balance tab using `tcg_owner_get_balance_report()`, deployed through commit `4c4ebc6 feat: add owner tcg balance report ui`.
- Milestone 30G-A documents TCG economy/drop balance planning in `docs/TCG_BALANCE_PLAN.md`, keeping the current low-rate production baseline as the primary next simulation model.
- Milestone 30G-B adds a deterministic local simulation for the Current Low-Rate Baseline in `scripts/tcg-balance-sim.mjs` and records results in `docs/TCG_BALANCE_SIMULATION.md`.
- Milestone 30G-C adds duplicate sell, dust/crafting, and pity/trade-in simulation in `scripts/tcg-duplicate-economy-sim.mjs` and records results in `docs/TCG_DUPLICATE_ECONOMY_SIMULATION.md`.
- Milestone 30G-D specifies the future duplicate economy design in `docs/TCG_DUPLICATE_ECONOMY_DESIGN.md`: Anteiku Fragments, missing-card crafting, Mythic v1 lock, and backend-only soft pity.
- Milestone 30G-E plans the duplicate economy backend/RPC/RLS implementation in `docs/TCG_DUPLICATE_ECONOMY_IMPLEMENTATION_PLAN.md`.
- Milestone 30G-F1 implements and production-applies Anteiku Fragments, duplicate burn, duplicate summary, and missing-card crafting backend/RPC/RLS through `20260612143019_tcg_fragments_duplicate_economy.sql`.
- Milestone 30G-F2 implements and production-applies backend-only Soft Pity counters and owned-pack opening integration through `20260612150113_tcg_soft_pity_backend.sql`.
- Milestone 30G-F3 adds the Owner-only `/tcg` Craft window for Anteiku Fragments, duplicate burn, missing-card crafting, and read-only pity status.
- Milestone 30G-G resets public-release balance direction: Duplicate Burn/Craft is experimental/later, Trading is preferred for duplicate/social value, and Epic-rate Candidate A/B simulations are recorded in `docs/TCG_BALANCE_SIMULATION.md`.
- Milestone 30G-H applies the approved Candidate A Epic-rate balance patch through `20260613101908_tcg_candidate_a_epic_rate_balance.sql`.
- Milestone 30G-I0 adds the dangerous Owner-only TCG test-state reset RPC and Owner Lab UI through `20260613105500_tcg_owner_reset_test_state.sql`.
- Milestone 30B backend/RPC foundation is implemented, locally validated, and production-applied through `20260601000100_tcg_30b_catalog_inventory.sql`.
- No member-facing packs, shop, economy UI, routes beyond `/tcg`, uploads, or Storage have been implemented.
- No member-facing TCG release exists yet. The next step is Owner pack-feel review on Candidate A after optional Owner-only reset, Trading design/spec, or member-safe release planning with Duplicate Economy excluded by default; frontend calls backend RPCs and never calculates drops or mutates wallets/inventory client-side.

## Product Direction

TCG should add a fun collection layer without touching protected app systems.

Initial player value:

- Browse a card catalog.
- View own active-profile card inventory.
- Track duplicates and favorites.
- Later showcase selected cards.

Initial staff value:

- Audited card grants for events or corrections.
- Later catalog/pack/admin management tools.

Delayed:

- Member-facing pack opening.
- Member-facing drop rates/balancing.
- Shop/economy.
- Wallets/currency.
- Premium/payment flows.
- Trading/marketplace/battles.
- Duplicate Burn/Craft public release unless explicitly re-approved later.

## Security Rules

- Do not expose normal CP.
- Do not use `member_cp`.
- Do not use `cp_snapshots`.
- Do not use normal CP RPCs.
- Do not put service-role keys in frontend.
- Do not trust frontend-selected `profile_id` for player actions.
- Use server-side active-profile helpers for player RPCs.
- Use existing admin permission patterns for admin RPCs.
- Backend decides ownership, pack results, inventory mutation, and future currency changes.
- Owner-only balance analytics must remain backend-gated and read-only.
- Pack inventory is backend/RPC authority only; the frontend must not write pack quantities or calculate drops.
- Frontend displays and calls RPCs only.
- Fragment balances, duplicate burns, and missing-card crafting are backend/RPC authority only.
- Frontend must not write fragment wallets, fragment ledgers, crafting rules, or inventory burns directly.
- Pity counters are backend/RPC authority only.
- Frontend must not write pity counters, choose guaranteed rarities, or control pity thresholds.
- The 30G-F3 Craft window is Owner-only and uses RPC wrappers only for fragments, duplicates, burn, craft, and pity status.
- 30G-G keeps Duplicate Burn/Craft experimental/later for public release and prefers future Trading for duplicate/social value.
- The 30G-I0 reset tool is Owner-only, requires exact `RESET_TCG`, resolves the active Owner profile server-side, accepts no `profile_id`, and must not be exposed to members.

## 30G-I0 Owner-Only TCG Test State Reset

Status: implemented, locally validated, production-applied, and frontend-deployed for Owner-only manual use. Codex did not click the production reset button.

Migration:

- `supabase/migrations/20260613105500_tcg_owner_reset_test_state.sql`

Validation artifact:

- `supabase/tests/tcg_30g_owner_reset_validation.sql`

RPC:

- `tcg_owner_reset_my_tcg_test_state(p_confirm text)`

Behavior:

- Requires authenticated active Owner profile.
- Rejects non-Owner users.
- Rejects unless `p_confirm = 'RESET_TCG'`.
- Does not accept arbitrary `profile_id`.
- Deletes mutable TCG test state only for the active Owner profile.
- Returns deleted row counts and reset timestamp.

Tables reset for active Owner profile only:

- `tcg_player_inventory`
- `tcg_inventory_events`
- `tcg_player_packs`
- `tcg_pack_inventory_events`
- `tcg_pack_openings`
- `tcg_wallets`
- `tcg_wallet_ledger`
- `tcg_fragment_wallets`
- `tcg_fragment_ledger`
- `tcg_pity_counters`

Tables not touched:

- `tcg_sets`
- `tcg_rarities`
- `tcg_cards`
- `tcg_packs`
- `tcg_pack_drop_rates`
- `tcg_shop_items`
- `tcg_crafting_rules`
- Other profiles' TCG rows
- CP tables/systems

Owner Lab UI:

- Shows `Reset TCG Test State` inside Owner Lab only.
- Requires typing exact `RESET_TCG`.
- Uses a final confirmation prompt.
- Calls only `tcg_owner_reset_my_tcg_test_state`.
- Refetches collection, wallet/shop, packs, fragments/duplicates/pity, and balance report after success.
- Does not auto-grant coins/cards after reset.

Validation:

- Local `npx.cmd supabase db reset` passed.
- Focused reset validation: `10 PASS / 0 FAIL / 0 SKIP`.
- Existing TCG regressions passed for 30B, 30D, 30E, 30F pack inventory, 30G-F1 fragments, 30G-F2 pity, and 30G-H Epic-rate validation.
- `npm.cmd run build` passed with existing chunk-size warning only.
- Production dry-run showed only `20260613105500_tcg_owner_reset_test_state.sql`.
- Production read-only verification confirmed RPC signature, definition rows, Candidate A weights, active Owner count `1`, and no TCG CP-named columns.

## 30G-H Candidate A Epic-Rate Balance Patch

Status: implemented, locally validated, production-applied, and read-only verified. No pack price, pack size, Legendary/Mythic weight, duplicate economy backend, fragments/crafting, pity thresholds, frontend UI, member access, inventory, wallet, pack opening history, shop item, CP system, or unrelated behavior changed.

Migration:

- `supabase/migrations/20260613101908_tcg_candidate_a_epic_rate_balance.sql`

Validation artifact:

- `supabase/tests/tcg_30g_epic_rate_validation.sql`

Applied Season 0 Test Pack weights:

| Rarity | Previous | Current |
| --- | ---: | ---: |
| Common | 6000 | 6200 |
| Uncommon | 2500 | 2500 |
| Rare | 1000 | 900 |
| Epic | 400 | 300 |
| Legendary | 90 | 90 |
| Mythic | 10 | 10 |

Verification:

- Total weight remains `10000`.
- Exact Candidate A weights verified in local validation and production read-only query.
- `tcg_owner_open_owned_pack` and `tcg_get_my_pity_status` remain present.
- TCG schema still has no CP-named columns.
- No production pack opening or inventory/wallet mutation was performed by Codex.

## 30G-G Balance Direction Reset + Epic Rate Simulation

Status: complete as docs/local simulation only. No SQL, migrations, RPC/RLS, production values, frontend UI, member access, production data, CP systems, or unrelated app behavior changed.

Direction reset:

- Duplicate Burn/Craft remains Owner-only experimental infrastructure.
- Do not include Duplicate Economy in the default public member release unless Owner explicitly re-approves it later.
- Trading is now the preferred future duplicate/social solution.
- Burning may later become optional as coin sell, event trade-in, fragments backup, pity support, or limited duplicate sink.

Trading design notes:

- Future trading requires a separate spec.
- One-to-one or offer-based trades are candidates.
- Both players must confirm.
- Backend escrow and trade logs/audit are required.
- No CP exposure, no direct inventory writes, no arbitrary profile authority.
- Cooldowns, limits, rarity restrictions, and locked/favorite-card restrictions should be designed before implementation.

Epic-rate simulation:

- Current baseline: `6000 / 2500 / 1000 / 400 / 90 / 10`.
- Candidate A: `6200 / 2500 / 900 / 300 / 90 / 10`.
- Candidate B: `6300 / 2500 / 850 / 250 / 90 / 10`.
- Legendary and Mythic are unchanged in both candidates.
- Current Epic chance is `18.46%` per pack.
- Candidate A Epic chance is `14.13%` per pack.
- Candidate B Epic chance is `11.89%` per pack.
- 30G-G recommendation: Candidate A was the preferred next balance candidate because it makes Epic less casual without making packs feel flat.
- 30G-H later approved and applied Candidate A.

## 30G-A Balance Planning

Status: complete as docs/planning only. No code, SQL, RPC, price, drop-rate, pack-size, coin-income, frontend, production data, or member-access behavior was changed.

Primary next simulation model: Current Low-Rate Baseline.

Current baseline:

- Pack price: 100 Anteiku Coins.
- Pack size: 5 cards.
- Drop weights: Common 6000, Uncommon 2500, Rare 1000, Epic 400, Legendary 90, Mythic 10.
- Season 0 catalog: 50 cards, distributed as 18 Common, 14 Uncommon, 9 Rare, 5 Epic, 3 Legendary, and 1 Mythic.

Owner Balance Report observations:

- Unique owned: 45 / 50.
- Missing cards: 5.
- Total owned quantity: 208.
- Duplicate quantity total: 163.
- Completion: 90%.
- Total pack openings: 40.
- Cards pulled: 200.
- Shop openings: 36; free test openings: 4.
- Current balance: 100 Anteiku Coins.
- Coins granted: 4000; coins spent: 3900; pack spend: 3900.
- Average spend per pack: 100.
- Duplicate rate: 78.37%; missing rate: 10%.
- Rarity pulls: Common 108, Uncommon 56, Rare 27, Epic 8, Legendary 1, Mythic 0.

Interpretation:

- Owner data is polluted by smoke grants, free test packs, shop test packs, and manual testing, so it is directional only.
- Legendary and Mythic should remain rare/flex pulls for now.
- Do not recommend applying higher drop rates yet.
- First test whether low rates feel acceptable with controlled weekly coin income and future duplicate sinks.
- Current Mythic scarcity may be acceptable if duplicate value, pity, crafting, or event rewards exist.

30G-B simulation requirements:

- Keep pack price at 100 Anteiku Coins.
- Simulate active member income around 400-550 coins per week, or about 4-5 packs per week.
- Measure progress and duplicate pressure at 20, 40, 60, and 100 packs.
- Measure expected time to first Legendary and first Mythic.
- Keep Casual, Balanced, and Prestige higher-rate models as alternatives only, marked "do not apply yet."

Release remains blocked until balance, member-safe RPCs, hidden Owner test controls, duplicate value, abuse checks, backend-only drops, no direct table writes, and no CP exposure are validated.

## 30G-B Balance Simulation

Status: complete as local simulation and docs only. No codepath, SQL, RPC, price, drop-rate, pack-size, coin-income, frontend UI, production data, or member-access behavior was changed.

Simulation:

- Script: `scripts/tcg-balance-sim.mjs`.
- Report: `docs/TCG_BALANCE_SIMULATION.md`.
- Runs: 10,000 simulated players.
- Seed: 300702.
- Model: Season 0 Current Low-Rate Baseline only.
- Pack price: 100 Anteiku Coins.
- Pack size: 5 cards.
- Drop weights: Common 6000, Uncommon 2500, Rare 1000, Epic 400, Legendary 90, Mythic 10.

Results:

- 20 packs: average 38.78 unique, 77.56% completion, 61.22 duplicates, 61.22% duplicate rate, 58.92% chance to own at least one Legendary, 10.08% chance to own Mythic.
- 40 packs: average 45.20 unique, 90.41% completion, 154.80 duplicates, 77.40% duplicate rate, 83.43% Legendary, 18.15% Mythic.
- 60 packs: average 47.23 unique, 94.45% completion, 252.77 duplicates, 84.26% duplicate rate, 93.02% Legendary, 26.13% Mythic.
- 100 packs: average 48.60 unique, 97.21% completion, 451.40 duplicates, 90.28% duplicate rate, 99.00% Legendary, 39.15% Mythic.
- First Legendary: 4.42% chance per pack, 22.63 expected packs, 16 median packs.
- First Mythic: 0.50% chance per pack, 200.40 expected packs, 139 median packs.

Coin pacing:

- 400 coins/week: about 4 packs/week, average 90% completion in 9.41 weeks, expected Mythic in 50.10 weeks.
- 500 coins/week: about 5 packs/week, average 90% completion in 7.53 weeks, expected Mythic in 40.08 weeks.
- 550 coins/week: about 5.5 packs/week, average 90% completion in 6.84 weeks, expected Mythic in 36.44 weeks.

Interpretation:

- Current low rates are acceptable for early and mid collection testing.
- 4-5 packs/week is reasonable for a small guild community.
- 100 coins/pack remains a reasonable baseline with 400-550 coins/week.
- Mythic is too rare for full-completion expectations without pity, event rewards, crafting, or trade-ins.
- Duplicate value is needed before member release; duplicate pressure is already painful around 40 packs.
- Historical 30G-B recommendation was not to apply higher drop rates yet.
- 30G-H later applies Candidate A as a low-rate Epic tuning patch, not a high-rarity buff.

Next:

- Simulate duplicate sell/burn/pity before any drop-rate patch.

## 30G-C Duplicate Economy Simulation

Status: complete as local simulation and docs only. No codepath, SQL, RPC, price, drop-rate, pack-size, coin-income, frontend UI, production data, or member-access behavior was changed.

Simulation:

- Script: `scripts/tcg-duplicate-economy-sim.mjs`.
- Report: `docs/TCG_DUPLICATE_ECONOMY_SIMULATION.md`.
- Runs: 10,000 simulated players.
- Seed: 300703.
- Model: Season 0 Current Low-Rate Baseline only.
- Compared no duplicate value, three coin sell tables, three dust/crafting tables, soft pity, and dust trade-in style crafting.

Key results:

- Conservative coin sell reaches about 12.41 coins refunded per pack by 100 packs; mild and safe.
- Balanced coin sell reaches about 17.26 coins refunded per pack by 100 packs; viable but accelerates pack count.
- Generous coin sell reaches about 32.05 coins refunded per pack by 100 packs; too inflationary for v1.
- Balanced Dust reaches average 943.95 dust at 40 packs and 3269.94 dust at 100 packs.
- Balanced Dust gives useful Rare/Epic relief while keeping Legendary and Mythic scarce.
- Generous Dust makes Legendary crafting possible for 52.56% of simulated players by 100 packs, which is too fast for v1.
- Soft pity barely changes early completion but guarantees Mythic by pack 151 and protects the extreme tail.

Historical recommendation:

- Keep current low drop rates unchanged at that time.
- Prefer Balanced Dust + Soft Pity as the future design direction.
- Do not apply higher drop rates yet at that time.
- Do not use generous coin refunds.
- Keep Mythic prestige/event/pity-only for v1.

Next:

- 30G-D Duplicate Economy Design Specification.

## 30G-D Duplicate Economy Design Specification

Status: complete as docs/design only. No SQL, migrations, RPCs, prices, drop weights, pack size, coin grants, frontend UI, production data, or member access changed.

V1 direction:

- Duplicate currency: Anteiku Fragments.
- Currency type: non-premium crafting currency.
- Source: duplicate burn only in v1; future event rewards only if approved.
- Not purchasable with real money.
- Not the same as Anteiku Coins.
- Backend-authoritative wallet and ledger required later.

Balanced dust values:

- Common: 2 fragments.
- Uncommon: 5 fragments.
- Rare: 18 fragments.
- Epic: 60 fragments.
- Legendary: 200 fragments.
- Mythic: 700 fragments.

Crafting:

- Missing-card focused in v1.
- Crafting adds exactly 1 card.
- Common: 30 fragments.
- Uncommon: 90 fragments.
- Rare: 350 fragments.
- Epic: 1400 fragments.
- Legendary: 5000 fragments, gated or optional.
- Mythic: 16000 fragments in future config, but locked/not v1.

Soft pity:

- Track per active profile and pack/set.
- Legendary pity: after 50 eligible packs without Legendary or better, next eligible pack guarantees Legendary or better.
- Mythic pity: after 150 eligible packs without Mythic, next eligible pack guarantees Mythic.
- Pity counters reset when the relevant rarity is pulled.
- Count only normal member-eligible pack openings; do not count admin grants or Owner free test packs for production economy.
- Pity display must come from backend RPC only.

Conceptual future backend:

- `tcg_fragment_wallets`
- `tcg_fragment_ledger`
- `tcg_pity_counters`
- Optional `tcg_crafting_recipes` or backend static rarity config.
- Future RPCs: `tcg_get_my_fragments`, `tcg_get_my_duplicate_summary`, `tcg_burn_duplicate_card`, `tcg_craft_missing_card`, `tcg_get_my_pity_status`, and updated pack-opening helper with pity support.

Security/abuse requirements:

- Backend/RPC authority only.
- RLS on all future tables.
- No direct fragment wallet, inventory burn, or pity counter writes from frontend.
- No arbitrary `profile_id`.
- Active profile resolved server-side.
- Burn only `quantity - 1`; never burn last copy.
- Reject inactive/non-collectible/out-of-set crafting.
- Reject already-owned cards under missing-only v1 crafting.
- Reject Mythic crafting while future locked.
- Ledger every fragment gain/spend and inventory event every burn/craft.
- Pack opening with pity must be atomic.
- No CP joins or CP exposure.

Next:

- 30G-E duplicate economy backend/RPC/RLS implementation planning.

## 30G-E Duplicate Economy Backend/RPC/RLS Implementation Plan

Status: complete as docs/planning only. No SQL, migrations, RPCs, prices, drop weights, pack size, coin grants, frontend UI, production data, or member access changed.

Implementation plan artifact:

- `docs/TCG_DUPLICATE_ECONOMY_IMPLEMENTATION_PLAN.md`

Planned future tables:

- `tcg_fragment_wallets`: own-profile Anteiku Fragment balances.
- `tcg_fragment_ledger`: immutable fragment gain/spend ledger.
- `tcg_pity_counters`: per profile/set/pack Legendary and Mythic pity counters.
- `tcg_crafting_rules`: locked migration-seeded config for dust values, crafting costs, active/craftable flags.

Planned future RPCs:

- `tcg_get_my_fragments()`
- `tcg_get_my_duplicate_summary()`
- `tcg_burn_duplicate_card(p_card_id uuid, p_quantity integer)`
- `tcg_craft_missing_card(p_card_id uuid)`
- `tcg_get_my_pity_status(p_pack_code text default 'season_0_test_pack')`
- Updated private pack-opening helper with backend-only pity support.

Pity plan:

- Member-eligible shop/owned pack openings count.
- Admin grants and Owner free test packs do not count for production pity.
- Mythic pity takes priority if both Legendary and Mythic pity are active.
- Legendary pity guarantees Legendary or better.
- Mythic pity guarantees Mythic.
- No missing-card bias in v1.
- Pity display must come from backend RPC only.

Security plan:

- Enable RLS and revoke broad direct grants on new tables.
- Prefer RPC-only reads/writes for v1.
- Use `private.tcg_active_member_profile_id()` for member duplicate economy RPCs.
- No arbitrary `profile_id`.
- No direct fragment wallet, inventory burn, or pity counter writes from frontend.
- No CP joins, `member_cp`, `cp_snapshots`, CP analytics RPCs, auth IDs, emails, or private admin metadata.

Validation plan:

- Focused rollback local validation should cover table existence, RLS, grant posture, own-profile reads, burn/craft success and denial paths, ledger/event consistency, pity thresholds, no direct writes, no CP columns, existing TCG regressions, and active Owner count remains 1.

Next:

- 30G-F1 and 30G-F2 are now implemented, locally validated, production-applied, and read-only verified. Continue with an Owner-only fragment/burn/craft/pity UI preview or member-safe TCG release planning after Owner review.

## 30G-F1 Fragments / Duplicate Burn / Crafting Backend

Status: implemented, locally validated, production-applied, and read-only verified. Soft Pity is now implemented backend-side in 30G-F2. No frontend UI, pack RNG, prices, drop weights, pack size, coin grants, production wallet/inventory/fragment mutation, CP systems, or member release behavior changed.

Migration:

- `supabase/migrations/20260612143019_tcg_fragments_duplicate_economy.sql`

Tables:

- `tcg_fragment_wallets`: own-profile Anteiku Fragment balance.
- `tcg_fragment_ledger`: immutable fragment gain/spend ledger.
- `tcg_crafting_rules`: migration-seeded rarity dust/crafting rules.

Crafting rules:

- Common: dust `2`, cost `30`, craftable.
- Uncommon: dust `5`, cost `90`, craftable.
- Rare: dust `18`, cost `350`, craftable.
- Epic: dust `60`, cost `1400`, craftable.
- Legendary: dust `200`, cost `5000`, craftable.
- Mythic: dust `700`, cost `null`, not craftable / future locked.

RPCs:

- `tcg_get_my_fragments()`
- `tcg_get_my_duplicate_summary()`
- `tcg_burn_duplicate_card(p_card_id uuid, p_quantity integer)`
- `tcg_craft_missing_card(p_card_id uuid)`

Security:

- All new tables have RLS enabled.
- Direct grants are revoked from `public`, `anon`, and `authenticated`.
- Mutations are RPC-only.
- Active profile is resolved server-side.
- No arbitrary `profile_id` is accepted.
- No CP joins, CP columns, CP RPCs, `member_cp`, or `cp_snapshots` were added.
- Mythic crafting is disabled for v1.
- Burning last copies, zero/negative burn quantities, too-large burns, already-owned crafting, inactive-card crafting, and fragment overspend are rejected.

Validation:

- `npx.cmd supabase db reset` applied all local migrations including 30G-F1.
- `supabase/tests/tcg_30g_fragments_validation.sql`: 37 PASS / 0 FAIL / 0 SKIP.
- Existing TCG validations passed:
  - 30B catalog/inventory: 19 PASS / 0 FAIL / 0 SKIP.
  - 30D pack backend: 18 PASS / 0 FAIL / 0 SKIP.
  - 30E shop economy: 32 PASS / 0 FAIL / 0 SKIP.
  - 30F balance report: 20 PASS / 0 FAIL / 0 SKIP.
  - 30F pack inventory: 31 PASS / 0 FAIL / 0 SKIP.
- Broad `local_validation_anteiku.sql` still has unrelated cosmetics catalog expectation failures from current avatar/frame counts; 30G-F1-specific paths and CP privacy checks passed.

Production verification:

- Dry-run showed only `20260612143019_tcg_fragments_duplicate_economy.sql` pending.
- Migration applied to production project `mzflfyxxkascrfpteexz`.
- Remote migration list shows `20260612143019` applied.
- Read-only checks confirmed new tables, RLS, no broad direct grants on new fragment tables, RPC existence/authenticated execute grants, seeded crafting rules, active Owner count `1`, and zero CP-named TCG columns.
- No production burn/craft mutation was performed.

Next:

- 30G-F2 backend-only Soft Pity counters and pack-opening integration is complete. Continue with an Owner-only fragment/burn/craft/pity UI preview or member-safe TCG release planning after Owner review.

## 30G-F2 Soft Pity Backend Integration

Status: implemented, locally validated, production-applied, and read-only verified. No frontend UI, member release, drop weights, pack price, pack size, fragment values, crafting costs, coin grants, production pack/wallet/card/pity mutation by Codex, CP systems, or unrelated app behavior changed.

Migration:

- `supabase/migrations/20260612150113_tcg_soft_pity_backend.sql`

Table:

- `tcg_pity_counters`: per active profile + set + pack Legendary/Mythic pity progress.

RPC:

- `tcg_get_my_pity_status()`: read-only own active-profile pity status. If no counter exists, returns zero values without creating a row.

Eligible openings:

- `tcg_owner_open_owned_pack(...)` counts for current Owner-only testing because it consumes owned pack inventory.
- Future member owned-pack opening should count when member-safe TCG release exists.
- `tcg_owner_open_test_pack(...)` free Owner test packs do not count.
- Legacy immediate buy-and-open `tcg_owner_buy_test_pack(...)` does not count.
- Admin grants and smoke grants do not count.
- Existing Owner test openings are not backfilled; pity starts from zero after the migration.

Guarantee rules:

- Mythic pity triggers first if `packs_since_mythic >= 150`.
- Otherwise Legendary pity triggers if `packs_since_legendary >= 50`.
- The guarantee affects one card in the pack and randomly selects an active collectible card from the guaranteed rarity in the pack/set.
- Other cards still use the current low-rate drop weights.
- No missing-card bias exists in v1.

Counter update rules:

- Eligible openings increment `total_eligible_openings`.
- Pulling Mythic resets both Legendary and Mythic counters and timestamps.
- Pulling Legendary resets Legendary and increments Mythic.
- Pulling no Legendary/Mythic increments both counters.
- Updates are transactional with pack consumption, card inventory updates, inventory events, pack opening history, and pack inventory events.

Validation:

- `npx.cmd supabase db reset` applied all local migrations including 30G-F2.
- `supabase/tests/tcg_30g_pity_validation.sql`: 22 PASS / 0 FAIL / 0 SKIP.
- Existing TCG validations passed:
  - 30B catalog/inventory: 19 PASS / 0 FAIL / 0 SKIP.
  - 30D pack backend: 18 PASS / 0 FAIL / 0 SKIP.
  - 30E shop economy: 32 PASS / 0 FAIL / 0 SKIP.
  - 30F balance report: 20 PASS / 0 FAIL / 0 SKIP.
  - 30F pack inventory: 31 PASS / 0 FAIL / 0 SKIP.
  - 30G-F1 fragments/crafting: 37 PASS / 0 FAIL / 0 SKIP.

Production verification:

- Dry-run showed only `20260612150113_tcg_soft_pity_backend.sql` pending.
- Migration applied to production project `mzflfyxxkascrfpteexz`.
- Remote migration list shows `20260612150113` applied.
- Read-only checks confirmed `tcg_pity_counters`, RLS, no broad direct grants, `tcg_get_my_pity_status()` existence/authenticated execute grant, active Owner count `1`, and zero CP-named TCG columns.
- No production pack opening or pity-counter mutation was performed by Codex.

Next:

- Owner-only duplicate economy UI preview for fragments, duplicate burn, missing-card crafting, and pity status.

## 30B Scope

Implemented backend only:

- `tcg_sets`
- `tcg_rarities`
- `tcg_cards`
- `tcg_player_inventory`
- `tcg_inventory_events`
- RLS policies
- RPC-only inventory mutation
- Catalog/inventory read RPCs
- Admin card grant RPC
- Local validation SQL/checklist

Do not implement:

- UI.
- Member-facing pack opening UI.
- Drop rates.
- Shop.
- Economy.
- Currency/wallets.
- Premium/payments.
- Trading.
- Public collection pages.

## 30C-A Owner Preview UI

Implemented frontend only:

- `/tcg` page.
- Owner-only nav entry.
- Owner-only page guard using the existing active admin context.
- `src/services/tcgService.js` RPC wrappers:
  - `tcgGetCatalog()`
  - `tcgGetMyCollection()`
  - `tcgSetCardFavorite(cardKey, isFavorite)`
- Mobile-first album grid and detail sheet.
- Catalog progress: unique owned, total owned quantity, and favorites.
- Filters: All, Owned, Missing, Favorites, and rarity.
- Missing art placeholder.
- EN/FR/DE i18n keys.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no `member_cp`, no `cp_snapshots`, no normal CP RPCs, no uploads/Storage, and no frontend `tcg_admin_grant_card` call.
- Production bundle verification confirmed `/tcg` serves the app shell and the deployed bundle contains the TCG preview plus read/favorite RPC calls.

Manual smoke still recommended:

- Owner sees Cards nav and can open `/tcg`.
- Non-Owner does not see Cards nav and direct `/tcg` shows the Owner-only blocked state.
- Catalog and collection load for Owner.
- Favorite toggle works only on owned cards.
- Missing art placeholders render cleanly.

## 30C-A2 Owner Smoke Grant Control

Implemented frontend-only:

- Compact Owner-only smoke panel on `/tcg`.
- Fixed smoke grant set:
  - `s0_001_20th_ward_civilian` quantity `3`
  - `s0_019_anteiku_server` quantity `2`
  - `s0_033_young_one_eyed_ghoul` quantity `1`
  - `s0_042_half_mask_awakening` quantity `1`
  - `s0_050_anteiku_origin` quantity `1`
- Fixed reason: `30C-A owner visual smoke`.
- Target profile: current selected active Owner profile from active admin context.
- RPC: `tcg_admin_grant_card`.
- After grant, `/tcg` refetches catalog/collection and switches to Owned filter.
- Button disables as `Smoke cards ready` once the active Owner profile has at least the requested quantities.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct `tcg_player_inventory` / `tcg_inventory_events` writes, no normal CP paths, no service-role path, and no uploads/Storage.
- Production bundle verification confirmed the button/RPC path is deployed.

Production smoke status:

- The button is ready for controlled Owner click.
- Codex did not perform the production grant mutation during implementation.
- Expected visual-smoke state after one successful click: Unique owned `5 / 50`, total owned quantity `8`, Owned filter `5`, Missing filter `45`.

## 30C-B Album Visual Polish + Asset Pipeline

Implemented frontend-only:

- Premium collectible-card styling for `/tcg`.
- Rarity visual accents for Common, Uncommon, Rare, Epic, Legendary, and Mythic through CSS borders/glow/accent lines.
- Intentional dark missing-art placeholder with card number, rarity, card name, crimson texture, and diagonal locked-state overlay.
- Owned cards receive stronger border/shadow and compact quantity pill.
- Missing cards are dimmed but still readable.
- Favorite action remains compact and accessible.
- Detail sheet inherits rarity styling and has stronger metadata cards.
- Progress cards are more game-stat-like.
- Smoke grant panel remains dashed/testing-only.

Asset location decision:

- Vite/Vercel serves files from `public/` at the site root.
- Real card inner art should be placed in `public/assets/tcg/art/`.
- Example repo path: `public/assets/tcg/art/s0_001_20th_ward_civilian.png`.
- Example served path / database `art_path`: `/assets/tcg/art/s0_001_20th_ward_civilian.png`.
- Reserved future frame overlays can live in `public/assets/tcg/frames/`.
- Added README notes in both folders.
- Do not use Supabase Storage or uploads for the current TCG preview.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no normal CP paths, no service-role path, and no upload/Storage behavior in the TCG page/service path.

## 30C-C First Smoke-Card Art Assets

Implemented asset-only:

- Added five temporary PNG inner-art files from the provided `S0` source set.
- Assets were copied to canonical Vite public paths that already match the Season 0 `tcg_cards.art_path` values.
- No catalog seed, SQL, RPC, service, or frontend behavior changes were needed.
- Other 45 Season 0 cards intentionally continue using the polished placeholder treatment.

Added files:

- `public/assets/tcg/art/s0_001_20th_ward_civilian.png`
- `public/assets/tcg/art/s0_019_anteiku_server.png`
- `public/assets/tcg/art/s0_033_young_one_eyed_ghoul.png`
- `public/assets/tcg/art/s0_042_half_mask_awakening.png`
- `public/assets/tcg/art/s0_050_anteiku_origin.png`

Validation:

- Source files are `1086x1448` PNGs, matching the 3:4 card-art ratio.
- `npm.cmd run build` passed.
- No Supabase Storage, uploads, generated-new-art step, packs, shop, economy, or CP paths were added.

## 30C-D Full Season 0 Temporary Art Import

Implemented asset-only:

- Added the remaining 45 temporary generated PNG inner-art files so all 50 Season 0 catalog cards have repo-served artwork.
- Kept the five 30C-C smoke-card files aligned with the same source-to-target mapping and verified their hashes did not change.
- Used the approved deterministic source mapping:
  - Batch 1 items 1-10 -> S0-001 through S0-010
  - Batch 2 items 1-10 -> S0-011 through S0-020
  - Batch 3 items 1-10 -> S0-021 through S0-030
  - Batch 4 items 1-10 -> S0-031 through S0-040
  - Batch 5 items 1-10 -> S0-041 through S0-050
- Ignored exact duplicate source `ChatGPT Image May 31, 2026, 09_32_31 PM.png`; used `ChatGPT Image May 31, 2026, 09_32_27 PM (1).png` for Batch 5 item 1 / S0-041.
- No catalog seed, SQL, RPC, service, UI, or CSS changes were needed.

Validation:

- All 50 local target files exist.
- All 50 are valid PNGs at `1086x1448`.
- `npm.cmd run build` passed.
- No Supabase Storage, uploads, generated-new-art step, packs, shop, economy, member visibility, or CP paths were added.

## 30D-A Owner-Only Test Pack Backend/RPC

Implemented backend/RPC only:

- Added `tcg_packs`.
- Added `tcg_pack_drop_rates`.
- Added `tcg_pack_openings`.
- Extended `tcg_inventory_events` allowed event/source values for pack openings.
- Seeded one active Owner-test pack:
  - code `season_0_test_pack`
  - name `Season 0 Test Pack`
  - cards per pack `5`
  - owner-test-only `true`
- Seeded temporary integer drop weights:
  - Common `6000`
  - Uncommon `2500`
  - Rare `1000`
  - Epic `400`
  - Legendary `90`
  - Mythic `10`
- Added `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')`.

RPC behavior:

- Resolves active profile server-side through existing TCG active-profile helper.
- Requires active approved Owner profile.
- Rolls all cards in the backend.
- Updates `tcg_player_inventory`.
- Writes one `tcg_inventory_events` row per card.
- Writes one `tcg_pack_openings` history row.
- Returns a five-card result payload with safe card metadata for later UI.
- Duplicates are allowed and stack inventory quantity.
- No currency, wallet, shop, payment, member access, or frontend UI was added.

Validation:

- Local `npx.cmd supabase db reset` passed through `20260601000200_tcg_owner_pack_backend.sql`.
- `supabase/tests/tcg_30d_pack_validation.sql` passed `18 PASS / 0 FAIL / 0 SKIP`.
- Existing `supabase/tests/tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- Broad `supabase/tests/local_validation_anteiku.sql` passed its regression suite with no failures.
- `npm.cmd run build` passed.

Production:

- Production dry-run showed exactly one pending migration: `20260601000200_tcg_owner_pack_backend.sql`.
- Production migration apply/list verification passed.
- Read-only production verification confirmed:
  - `tcg_packs`, `tcg_pack_drop_rates`, and `tcg_pack_openings` exist with RLS enabled.
  - No direct anon/authenticated table grants exist for the new pack tables.
  - `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` exists.
  - Authenticated execute grant exists for the RPC; anon execute was not present.
  - `season_0_test_pack` is active, Owner-test-only, has 5 cards per pack, 6 drop rates, and total weight 10000.
  - Active Owner count remains `1`.
- No production Owner pack opening smoke was performed; user approval is required before creating production pack-opening/inventory mutations.

## 30D-B Owner-Only Pack Preview UI

Implemented frontend-only:

- Added an Owner-only `Season 0 Test Pack` panel on `/tcg`.
- Added `tcgOwnerOpenTestPack()` in `src/services/tcgService.js`.
- The button calls only `tcg_owner_open_test_pack(p_pack_code => season_0_test_pack)`.
- No profile id is sent from the frontend; the backend resolves the active Owner profile.
- Result cards render directly from the backend payload: art, card name/no, rarity, new/duplicate state, quantity delta, and resulting owned quantity.
- After success the page refetches `tcg_get_my_collection`, switches to Owned, and keeps existing favorite/detail/smoke-grant behavior.
- Added EN/FR/DE i18n and CSS-only staggered reveal styling with reduced-motion fallback.

Validation:

- `npm.cmd run build` passed.
- Source checks confirmed no direct TCG table reads/writes, no pack/drop table reads, no client-side drop calculation, no normal CP paths, no service-role path, and no uploads/Storage in the TCG page/service path.
- Production bundle verification confirmed `/tcg` serves the app shell and the deployed bundle contains the pack UI plus `tcg_owner_open_test_pack`.

Production smoke status:

- Codex did not click `Open Test Pack` in production.
- No production pack-opening or inventory mutation was created during deployment.
- Owner can now manually open a controlled test pack from `/tcg`.

## 30E-A Owner-Only Shop/Economy Backend

Implemented backend/RPC only:

- New migration `20260601000300_tcg_owner_shop_economy.sql`.
- New tables:
  - `tcg_wallets`
  - `tcg_wallet_ledger`
  - `tcg_shop_items`
- New currency code: `anteiku_coins`.
- New seeded Owner-test shop item:
  - code `season_0_test_pack_shop`
  - name `Season 0 Test Pack`
  - price `100`
  - linked to existing `season_0_test_pack`
- Private helper `private.tcg_open_owner_test_pack_for_profile(...)` now owns the shared backend pack-opening flow for existing free Owner test packs and future Owner shop purchases.
- Existing RPC `tcg_owner_open_test_pack(p_pack_code text default 'season_0_test_pack')` is preserved.
- New Owner-only public RPCs:
  - `tcg_owner_grant_test_coins(p_amount integer default 1000)`
  - `tcg_get_my_wallet()`
  - `tcg_owner_get_test_shop()`
  - `tcg_owner_buy_test_pack(p_shop_item_code text default 'season_0_test_pack_shop')`

Security:

- Owner-only through existing active-profile/admin authority.
- No arbitrary target profile id is accepted for player/economy actions.
- Wallet balance changes are server-side and ledger-backed.
- Shop purchase locks the wallet row, rejects insufficient balance, deducts coins, records ledger history, opens the pack server-side, and writes inventory/opening history.
- RLS is enabled on all new tables and direct anon/authenticated table grants are revoked.
- No member-facing shop access, payments, premium currency, uploads, Storage, frontend shop UI, CP references, or normal CP exposure was added.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30e_shop_validation.sql` passed `32 PASS / 0 FAIL / 0 SKIP`.
- Regression validation passed:
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
- `npm.cmd run build` passed.

Production:

- Dry-run showed exactly one pending migration: `20260601000300_tcg_owner_shop_economy.sql`.
- Migration apply/list verification passed.
- Read-only DB verification confirmed:
  - new economy tables exist and have RLS enabled;
  - no direct anon/authenticated client grants exist on the new tables;
  - Owner test shop item is seeded;
  - new public RPCs exist with authenticated execute grants;
  - checked anon execute grants are denied;
  - the private pack helper is not executable by authenticated clients;
  - new economy RPCs contain no CP references;
  - simulated authenticated direct reads of `member_cp` and `cp_snapshots` returned zero rows;
  - active Owner count remains `1`.
- No production Owner coin grant, wallet mutation, shop purchase, or pack purchase smoke was performed. User approval is required before creating those production economy/inventory mutations.

## 30E-B Owner-Only Shop/Economy UI Preview

Implemented frontend-only:

- Owner-only `TCG Shop Test` panel on `/tcg`.
- Wallet card showing `Anteiku Coins` balance from `tcg_get_my_wallet`.
- Owner test/dev button `Grant 1000 test coins` using `tcg_owner_grant_test_coins`.
- Owner shop item card for `Season 0 Test Pack`, price `100 Anteiku Coins`, using `tcg_owner_get_test_shop`.
- `Buy Test Pack` action using `tcg_owner_buy_test_pack`.
- Purchase result display reuses the existing backend-returned pack result/reveal card UI.
- After successful purchase, the UI refetches wallet and collection and switches to Owned.
- Added EN/FR/DE copy and dark/crimson mobile-first shop styling.

Validation:

- `npm.cmd run build` passed.
- Source checks found no SQL/migration/backend changes, no direct `.from('tcg_*')` table access in the TCG page/service, no client-side drop calculation, no `member_cp`/`cp_snapshots` paths in touched TCG page/service files, no service-role path, no payments, and no uploads/Storage.
- Non-Owner direct `/tcg` remains blocked by the existing active Owner page guard.

Production:

- Commit `8e7eb73 feat: add owner tcg shop preview` was pushed to `main`.
- Production serves the deployed bundle containing `TCG Shop Test`, wallet text, and RPC wrapper names for `tcg_get_my_wallet`, `tcg_owner_get_test_shop`, `tcg_owner_grant_test_coins`, and `tcg_owner_buy_test_pack`.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click production `Grant 1000 test coins` or `Buy Test Pack`.
- Manual Owner mutation smoke is ready: grant test coins, buy the test pack, confirm wallet decreases by `100`, confirm five backend-returned cards reveal, and confirm collection quantity increases by `+5`.

## 30E-C Owner-Only Shop/Pack UX Polish

Implemented frontend/style-only:

- Polished the Owner-only shop panel into a darker game-shop presentation.
- Improved wallet HUD styling for `Anteiku Coins`.
- Improved shop item/price/buy-button visual hierarchy.
- Kept the free Owner test pack visually separate from the shop purchase flow.
- Improved pack result stage, rarity glow, card reveal timing, and Epic/Legendary/Mythic impact.
- Added small card reveal index markers.
- Added ref-based double-submit guards for mutation actions:
  - favorite toggle
  - smoke grant
  - free Owner test pack
  - test coin grant
  - test pack purchase
- Current test values remain unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed.
- Source checks found only `src/pages/TcgCollection.jsx` and `src/styles/app.css` changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added.
- No client-side drop calculation, client-side wallet authority, CP path, service-role path, payments, uploads, or Storage was added.

Production:

- Commit `053f27d style: polish owner tcg shop ux` was pushed to `main`.
- Production serves the updated JS/CSS bundle with the shop polish markers.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click any production mutation controls.
- Owner manual shop-loop smoke remains next: grant coins, buy pack, verify wallet decrease, reveal five cards, verify collection quantity increase.

## 30E-D Compact TCG Hub / Windowed UI Polish

Implemented frontend/style-only:

- Reworked Owner-only `/tcg` into a compact hub instead of one long stacked preview page.
- Added top header stats for unique owned, total owned quantity, favorites, and Anteiku Coins.
- Added frontend-only window tabs:
  - Album
  - Packs
  - Shop
  - Owner Lab
- Album remains the default window and keeps collection progress, filters, rarity filter, card grid, detail sheet, and favorite behavior.
- Packs contains the free Owner test pack opening preview.
- Shop contains wallet, shop item, and `Buy Test Pack`.
- Owner Lab contains the controlled mutation tools:
  - `Grant smoke cards`
  - `Grant 1000 test coins`
- Preserved existing ref-based double-submit guards for favorite toggle, smoke grant, free test pack, test coin grant, and shop purchase.
- Current test values remain unchanged:
  - grant amount `1000`
  - test pack price `100 Anteiku Coins`
  - pack size `5`
  - drop weights unchanged

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks found only `src/pages/TcgCollection.jsx`, `src/styles/app.css`, and EN/FR/DE i18n files changed.
- No SQL/migrations/backend/RPC/RLS/package/service-worker changes were made.
- No direct TCG table reads/writes were added.
- No client-side drop calculation, client-side wallet authority, CP path, service-role path, payments, uploads, or Storage was added.

Production:

- Commit `d1f4c4a style: add compact tcg hub layout` was pushed to `main`.
- Production serves the updated hub bundle with JS/CSS markers for the tabbed TCG hub and Owner Lab.
- Non-mutating production smoke confirmed `/tcg` returns HTTP `200`.
- Codex did not click `Grant smoke cards`, `Open Test Pack`, `Grant 1000 test coins`, `Buy Test Pack`, or favorite toggle in production.
- Owner manual shop-loop smoke remains next.

## 30F-A Owner-Only Balance Report Backend

Implemented backend/RPC only:

- New migration `20260601000400_tcg_owner_balance_report.sql`.
- New read-only RPC `tcg_owner_get_balance_report()`.
- The RPC resolves the active Owner profile server-side through the existing active admin context.
- The RPC rejects non-Owner active profiles.
- Execute is granted to authenticated clients only; the function performs the Owner check internally.
- The report returns structured JSONB sections:
  - `collection_summary`
  - `rarity_ownership_summary`
  - `pack_opening_summary`
  - `rarity_pull_summary`
  - `economy_summary`
  - `duplicate_pressure_summary`
  - `balance_hints`

Behavior:

- Uses existing TCG catalog, inventory, pack opening, wallet, ledger, and shop tables.
- Does not accept arbitrary player/profile ids.
- Does not mutate inventory, wallets, ledger rows, pack openings, prices, drop rates, or pack size.
- Does not expose analytics to members.
- Does not add frontend analytics UI yet.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30f_balance_report_validation.sql` passed `20 PASS / 0 FAIL / 0 SKIP`.
- TCG regression tests passed:
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30e_shop_validation.sql`: `32 PASS / 0 FAIL / 0 SKIP`
- Broad `supabase/tests/local_validation_anteiku.sql` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production:

- Production dry-run showed exactly one pending migration: `20260601000400_tcg_owner_balance_report.sql`.
- Migration apply/list verification passed and remote now shows `20260601000400`.
- Read-only production verification confirmed:
  - `tcg_owner_get_balance_report()` exists.
  - Authenticated execute is granted and anon execute is not granted.
  - Function definition has no CP table references.
  - Simulated active Owner call returned the expected sections.
  - Normal member call was denied.
  - Payload check found no CP/private token exposure.
  - Active Owner count remains `1`.
- No production wallet, inventory, ledger, opening, price, drop-rate, or pack-size mutation was performed.

Next:

- Plan or implement an Owner-only TCG balance report UI inside `/tcg` Owner Lab after explicit approval.
- Keep member TCG release blocked until Owner analytics review and member-release gates are separately planned.

## 30F-B Owner-Only Pack Inventory Backend

Implemented backend/RPC only:

- New migration `20260601000500_tcg_owner_pack_inventory.sql`.
- New tables:
  - `tcg_player_packs`
  - `tcg_pack_inventory_events`
- New Owner-only RPCs:
  - `tcg_get_my_packs()`
  - `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')`
  - `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')`

New behavior:

- `tcg_owner_buy_test_pack_to_inventory(...)` deducts the shop price and adds owned pack quantity.
- Buying to inventory does not roll cards, update card inventory, or write pack opening history.
- `tcg_owner_open_owned_pack(...)` consumes one owned pack and then rolls five cards backend-side through the existing private pack helper.
- Opening an owned pack writes pack inventory event history, card inventory events, and pack opening history.

Backward compatibility:

- Existing `tcg_owner_buy_test_pack(...)` is preserved and still buys-and-opens immediately for the currently deployed frontend.
- Existing free Owner `tcg_owner_open_test_pack(...)` is preserved.
- Future frontend should use the new inventory-based flow.

Validation:

- Local `npx.cmd supabase db reset` passed.
- `supabase/tests/tcg_30f_pack_inventory_validation.sql` passed `31 PASS / 0 FAIL / 0 SKIP`.
- TCG regression tests passed:
  - `supabase/tests/tcg_30b_validation.sql`: `19 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30d_pack_validation.sql`: `18 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30e_shop_validation.sql`: `32 PASS / 0 FAIL / 0 SKIP`
  - `supabase/tests/tcg_30f_balance_report_validation.sql`: `20 PASS / 0 FAIL / 0 SKIP`
- Broad `supabase/tests/local_validation_anteiku.sql` passed.
- `npm.cmd run build` passed with the existing Vite chunk-size warning only.

Production:

- Production dry-run initially hit a transient Supabase pooler auth/circuit-breaker error before SQL execution; rerun after cooldown succeeded.
- Clean dry-run showed exactly one pending migration: `20260601000500_tcg_owner_pack_inventory.sql`.
- Migration apply/list verification passed and remote now shows `20260601000500`.
- Read-only production verification confirmed:
  - `tcg_player_packs` and `tcg_pack_inventory_events` exist.
  - RLS is enabled on both new tables.
  - No direct anon/authenticated table grants exist.
  - All three new RPCs exist.
  - Authenticated execute is granted and anon execute is not granted.
  - New RPC definitions contain no CP table references.
  - Owner can read pack inventory through RPC.
  - Normal member is denied pack inventory RPC access.
  - Normal member direct `member_cp` read remains empty/blocked.
  - Active Owner count remains `1`.
- No production pack buy, owned-pack open, wallet mutation, inventory mutation, or pack-opening smoke was performed by Codex.

## 30F-C Owner-Only Pack Inventory UI

Status: complete and deployed through commit `ada2b74 feat: add tcg pack inventory opening ui`.

Implemented:

- Shop `Buy Test Pack` calls `tcg_owner_buy_test_pack_to_inventory(...)`.
- Shop purchases add a Season 0 Test Pack to pack inventory and do not reveal cards in the Shop.
- Packs calls `tcg_get_my_packs()` and displays owned Season 0 Test Pack quantity.
- Packs uses a CSS-only 4:3 pack sprite/card treatment for the Owner test pack.
- Opening from Packs calls `tcg_owner_open_owned_pack(...)`.
- The backend remains authority for consuming one pack and rolling five card results.
- Opening UI uses a dimmed/blurred overlay, swipe-left/right rip gesture, fallback `Rip Open` button, card-by-card reveal, and `Reveal all`.
- Pack animations are local UI state, default enabled, and can be disabled without changing backend behavior.
- The older free Owner `Open Test Pack` path remains only in Owner Lab.
- EN/FR/DE i18n and dark/crimson mobile styling were added.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source validation confirmed no SQL/migration, Supabase/RLS/RPC, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `ada2b74` was pushed to `main` and production served the updated bundle.
- Non-mutating smoke passed: `/tcg?tcg-pack-inventory-smoke=1` returned HTTP 200 and the bundle contained `tcg_get_my_packs`, `tcg_owner_buy_test_pack_to_inventory`, `tcg_owner_open_owned_pack`, `packInventory`, `swipeToRip`, and `packAnimations`.
- Codex did not click production Buy, Open, Rip, Grant, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-D Temporary Pack Front + Card Back Assets

Status: complete and deployed through commit `6bcebab feat: add tcg pack and card back assets`.

Assets:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`
- Added `public/assets/tcg/packs/README.md`.
- Added `public/assets/tcg/cards/README.md`.

Implemented:

- Packs window and pack opening overlay use the temporary Season 0 pack-front image.
- Unrevealed pack result cards use the temporary Season 0 card-back image.
- Existing CSS/text placeholder fallback remains if either image fails to load.
- Revealed cards still use backend-returned card art/details.
- Swipe/rip, `Rip Open`, `Reveal all`, and pack animation setting behavior were preserved.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Build output contains both image assets in `dist/assets/tcg/packs/` and `dist/assets/tcg/cards/`.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `6bcebab` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-assets-smoke=1` returned HTTP 200.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 image/png.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 image/png.
  - Deployed bundle `assets/index-DW84VTFX.js` references both new asset paths and still contains `tcg_get_my_packs` / `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-E Pack UI Compact Hotfix

Status: complete and deployed through commit `bc3c705 fix: compact tcg pack inventory ui`.

Implemented:

- Removed the app-side hard rectangular box/background around the pack image.
- Kept the pack floating on the dark panel with subtler glow/shadow.
- Kept a compact `xN` quantity badge near the pack.
- Moved `Open Pack` directly under the pack as a smaller compact action.
- Disabled `Open Pack` at quantity `0` remains readable.
- Shop purchases remain on the Shop window after `tcg_owner_buy_test_pack_to_inventory(...)` succeeds.
- Shop success stays inline and shows pack-added / current pack quantity copy.
- Added a small `Go to Packs` secondary action for manual navigation.
- Added EN/FR/DE `tcg.goToPacks` copy.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.
- The temporary pack/card-back PNGs are `Format24bppRgb`, so CSS can remove the app wrapper box but cannot remove opaque black pixels baked into the artwork.

Production:

- Commit `bc3c705` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-pack-compact-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-DLnPnWpl.js` contains `tcg-owned-open-button`, `tcg-shop-success-actions`, `Go to Packs`, `tcg_owner_buy_test_pack_to_inventory`, and `tcg_owner_open_owned_pack`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-F Pack/Reveal UI Polish Hotfix

Status: complete and deployed through commit `e77a385 style: polish tcg pack reveal ui`.

Implemented:

- Added a local canvas cleanup pass for the pack-front image that turns near-black edge-connected background pixels transparent when possible.
- Canvas cleanup is frontend-only, pack-image-only, cached by asset path, and falls back to the original image if processing fails.
- Tightened the Packs window into a collectible-style display with the pack as the hero.
- Kept compact quantity badge and compact `Open Pack` action.
- Simplified reveal overlay so the pack name/status appears once in the top bar.
- Added compact reveal toolbar with revealed-card count and `Reveal all`.
- Improved reveal grid spacing and alignment for unrevealed/revealed mixed states.
- Reduced unrevealed card clutter while keeping the temporary Season 0 card-back asset.
- Preserved Shop stay-in-Shop behavior, swipe/rip, `Rip Open`, tap-to-reveal, `Reveal all`, pack animation setting, and refresh after opening.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `e77a385` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-reveal-polish-smoke=1` returned HTTP 200.
  - Deployed bundle `assets/index-BPcKi_cv.js` contains `tcg-reveal-toolbar`, `tcg-owned-pack-stage`, `tcg_owner_open_owned_pack`, and `tcg_owner_buy_test_pack_to_inventory`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-G Pack Front + Real Card Back Asset Wire-Up

Status: complete and deployed through commit `332e38f fix: use tcg card back for reveal cards`.

Implemented:

- Kept the pack front on `/assets/tcg/packs/season0_test_pack_front.png` for pack inventory and pack opening/rip overlay.
- Wired unrevealed pack result cards to `/assets/tcg/cards/tcg_card_back_season0.png`.
- Kept the CSS/React card-back design as fallback if the real card-back image fails to load.
- Kept the small `Tap to Reveal` overlay label.
- Preserved Shop/Packs behavior: buying stays in Shop, `Go to Packs` remains manual, pack count stays in Packs, and `Open Pack` remains compact.
- Preserved Open Pack, swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, pack animation toggle, collection refetch, and pack quantity refetch behavior.

Asset verification:

- Pack front: `public/assets/tcg/packs/season0_test_pack_front.png`, 1086x1448 PNG, 1,799,800 bytes.
- Card back: `public/assets/tcg/cards/tcg_card_back_season0.png`, 1086x1448 PNG, 2,185,757 bytes.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `332e38f` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg` app shell returned HTTP 200.
  - Deployed bundle `assets/index-DZ6Xj5gs.js` and CSS `assets/index-D5PKDyGy.css` contain the card-back image wire-up/styling.
  - `/assets/tcg/packs/season0_test_pack_front.png` returned HTTP 200 and 1,799,800 bytes.
  - `/assets/tcg/cards/tcg_card_back_season0.png` returned HTTP 200 and 2,185,757 bytes.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-H Owner-Only TCG UI Polish Pass

Status: complete and deployed through commit `3d92c37 style: polish owner tcg ui`.

Implemented:

- Tightened the overall `/tcg` page into a more polished game-hub presentation.
- Improved top header hierarchy, compact refresh action, and HUD stat cards.
- Improved Album filter density, rarity selector, card grid density, owned/missing/favorite states, and detail sheet sizing.
- Kept card art readable while reducing excessive spacing and button weight.
- Improved Packs composition while preserving the pack front as the hero and compact `Open Pack` placement.
- Added an existing pack-front preview to Shop items and tightened wallet, price, purchase, success, and `Go to Packs` presentation.
- Reworked Owner Lab into a clearly separated test-only section for smoke grants and test coins.
- Improved reveal overlay spacing, toolbar, hidden/revealed card grid sizing, and mobile safety.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed no SQL/migration, Supabase/RLS/RPC, service, package, service worker, CP, GvG, Wall, 3v3, Push, Analytics, Ranking, Auth, Approval, or Account Switcher changes.
- Frontend checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.

Production:

- Commit `3d92c37` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-ui-polish-smoke=2` returned HTTP 200.
  - Deployed bundle `assets/index-C9n3v1dY.js` contains `tcg-shop-pack-preview` and `tcg-owner-lab-section`.
  - Deployed CSS `assets/index-DSO3TEr-.css` contains `tcg-shop-pack-preview`, `tcg-owner-lab-section`, and `tcg-hub-hero`.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

## 30F-I Windowed Pack/Shop Layout Hotfix

Status: complete and deployed through commit `14219fe style: make tcg pack shop windows compact`.

Implemented:

- Changed the owned Packs item from a wide row into a compact centered pack window/card.
- Kept the pack front as the hero with quantity badge and compact `Open Pack` action under/near the pack.
- Centered compact metadata chips and no-pack state around the pack card.
- Changed Shop items from wide rows into compact 3:4-style shelf cards.
- Kept the pack image as Shop item art with pack name, price, and `Buy Test Pack` inside/directly under the compact card.
- Kept wallet in the Shop header/HUD area.
- Kept Shop purchase success inline and compact with `Go to Packs` as secondary.
- Added responsive CSS so the compact items center on desktop and stack safely on mobile.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed the source hotfix only changed `src/styles/app.css`.
- TCG checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, and no client-side wallet authority.
- Owner-only `/tcg` source guard remains based on `activeAdminContext?.isOwner`.

Production:

- Commit `14219fe` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-windowed-pack-shop-smoke=1` returned HTTP 200.
  - Deployed CSS `assets/index-lRpgZHRE.css` contains the compact pack/shop layout rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Run controlled Owner manual mutation smoke for the pack loop when approved:
  - grant test coins if needed;
  - buy a test pack into inventory from Shop;
  - open it from Packs;
  - reveal cards;
  - verify wallet decrease, pack quantity decrease, collection count update, and favorites still work.
- Keep member TCG release blocked until this flow is accepted and release gates are planned.

## 30F-J Slim Windows + Wallet HUD Polish

Status: complete and deployed through commit `7840366 style: slim tcg pack shop wallet ui`.

Implemented:

- Slimmed the owned Packs card into a tighter centered pack window.
- Reduced pack preview, copy, metadata chips, and `Open Pack` button weight while keeping the control tappable.
- Slimmed Shop item cards with smaller pack previews, tighter text, compact price display, and smaller `Buy Test Pack` controls.
- Reworked the Shop wallet card into a compact game-currency HUD with a gold/crimson coin mark and stronger balance hierarchy.
- Applied matching gold/crimson polish to the top Anteiku Coins HUD stat.
- Added responsive CSS so Packs, Shop cards, and wallet HUD stay compact on desktop and safe on mobile.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Wallet values remain backend-derived.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed only `src/styles/app.css` changed for the source patch.
- TCG checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.
- Owner-only `/tcg` source guard remains based on `activeAdminContext?.isOwner`.

Production:

- Commit `7840366` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-slim-wallet-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-Bzxq0oc_.css` contains the slim pack, slim shop, and wallet HUD rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Owner can visually retest Packs, Shop, and Wallet HUD.
- Keep controlled pack-loop mutation smoke gated until explicitly approved.

## 30F-K Wallet Icon HUD Hotfix

Status: complete and deployed through commit `07d65a9 style: polish tcg wallet hud icon`.

Implemented:

- Replaced the wallet HUD glowing-square mark with a compact CSS wallet/currency object.
- Added wallet body, flap, and clasp pseudo-elements.
- Used a restrained dark gold, black, and crimson treatment so it reads as a wallet/token without becoming too bright.
- Added a matching small wallet mark to the top Anteiku Coins HUD stat.

Preserved behavior:

- Wallet balance remains backend-derived.
- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed only `src/styles/app.css` changed for the source patch.
- TCG checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.

Production:

- Commit `07d65a9` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-wallet-icon-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-CIvARjRw.css` contains the wallet body, flap, clasp, and Anteiku Coins HUD icon rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Owner can visually retest the wallet HUD icon.
- Keep controlled pack-loop mutation smoke gated until explicitly approved.

## 30F-L Centering / Alignment Hotfix

Status: complete and deployed through commit `ff94b1c style: center tcg shop pack windows`.

Implemented:

- Centered the owned Packs card inside the Packs window while keeping the panel header full-width.
- Aligned the pack image, quantity badge, metadata, and `Open Pack` action on one cleaner visual axis.
- Centered the compact Shop item card/list inside the Shop window on a dedicated content rail.
- Kept the wallet HUD in the Shop header and reduced its effect on the main Shop card's visual center.
- Added mobile rules so the Shop card stays centered with safe margins and no horizontal overflow.

Preserved behavior:

- Shop buy stays on Shop.
- Shop buy adds pack inventory through backend RPC.
- `Go to Packs` remains manual.
- Packs open owned packs through backend RPC.
- Swipe/rip, `Rip Open`, card-by-card reveal, `Reveal all`, animation toggle, wallet and collection refetch, pack quantity refetch, and favorite toggle remain unchanged.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed only `src/styles/app.css` changed for the source patch.
- TCG checks confirmed no direct TCG table access, no `member_cp`, no `cp_snapshots`, no CP analytics RPCs, no client-side drops, no service-role path, and no client-side wallet authority.

Production:

- Commit `ff94b1c` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-centering-smoke=1` returned the production app shell.
  - Deployed CSS `assets/index-Cm2PILN7.css` contains the centering content rail, pack card centering, wallet alignment, and mobile width rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Owner can visually retest Packs and Shop centering.
- Keep controlled pack-loop mutation smoke gated until explicitly approved.

## 30F-M Owner-Only Balance Report UI

Status: complete and deployed through commit `4c4ebc6 feat: add owner tcg balance report ui`.

Implemented:

- Added a `Balance` tab/window to the Owner-only `/tcg` hub.
- Added frontend service wrapper `tcgOwnerGetBalanceReport()` for the existing production RPC `tcg_owner_get_balance_report()`.
- Displayed collection summary, rarity ownership, pack summary, rarity pulls, economy summary, duplicate pressure, and balance hints in compact dashboard sections.
- Added loading, empty, error, and `Refresh Report` states.
- Added EN/FR/DE labels and mobile-safe report styling.

Preserved behavior:

- TCG remains Owner-only.
- Album, Packs, Shop, Owner Lab, pack opening/reveal, wallet, pack inventory, favorite toggle, smoke grant, and test coin controls remain unchanged.
- Balance report is read-only and does not apply price, drop-rate, pack-size, wallet, or economy changes.

Validation:

- `npm.cmd run build` passed with the existing Vite chunk-size warning only.
- Source checks confirmed frontend-only changes in `TcgCollection.jsx`, `tcgService.js`, `app.css`, and EN/FR/DE i18n.
- TCG checks confirmed no direct TCG table access, no `member_cp` or `cp_snapshots` in the TCG page/service path, no CP analytics RPCs, no client-side drops, no payments/uploads/storage additions, no service-role path, and no client-side wallet authority.
- Owner-only `/tcg` source guard remains based on `activeAdminContext?.isOwner`.

Production:

- Commit `4c4ebc6` was pushed to `main`.
- Non-mutating smoke passed:
  - `/tcg?tcg-balance-ui-smoke=1` returned the production app shell.
  - Deployed bundle `assets/index-BQrXiP8d.js` contains `tcg_owner_get_balance_report` and Balance UI text.
  - Deployed CSS `assets/index-D23BkU1w.css` contains the Balance report panel/table rules.
- Codex did not click production Buy, Open, Rip, Grant, Grant Coins, or Favorite controls.
- No production wallet, pack inventory, card inventory, or favorite mutation was performed by Codex during this smoke.

Next:

- Owner can visually review Balance analytics.
- Use Balance feedback to plan member-facing release/economy gates separately.

## 30B RPC Candidates

- `tcg_get_catalog()`
- `tcg_get_my_collection()`
- `tcg_set_card_favorite(p_card_key text, p_is_favorite boolean)`
- `tcg_admin_grant_card(p_target_profile_id uuid, p_card_key text, p_quantity integer, p_reason text default null)`
- `tcg_owner_get_balance_report()`
- `tcg_get_my_packs()`
- `tcg_owner_buy_test_pack_to_inventory(p_shop_item_code text default 'season_0_test_pack_shop')`
- `tcg_owner_open_owned_pack(p_pack_code text default 'season_0_test_pack')`

## 30B Local Validation

- `npm.cmd run build` passed.
- Local `npx.cmd supabase db reset` passed through `20260601000100_tcg_30b_catalog_inventory.sql`.
- `supabase/tests/tcg_30b_validation.sql` passed `19 PASS / 0 FAIL / 0 SKIP`.
- The full existing local validation suite passed after the TCG migration.

## 30B Production Verification

- Production dry-run showed exactly one pending migration: `20260601000100_tcg_30b_catalog_inventory.sql`.
- Production migration apply/list verification passed.
- Production DB verification confirmed `tcg_sets`, `tcg_rarities`, `tcg_cards`, `tcg_player_inventory`, and `tcg_inventory_events` exist with RLS enabled.
- Production verification confirmed Season 0 has exactly 50 cards with Common 18, Uncommon 14, Rare 9, Epic 5, Legendary 3, Mythic 1; Character 24, Scene 16, Relic 10, Organization 0.
- Production verification found no broad anon/authenticated direct table grants and no TCG RPC references to `member_cp`, `cp_snapshots`, normal CP RPCs, or Analytics CP paths.
- Rollback-wrapped production smoke confirmed approved-member catalog/collection reads work, direct inventory insert is blocked, and normal member admin grant is denied.
- No real production inventory grant or card ownership mutation was performed.

## Season 0 Catalog

The canonical "Season 0: Anteiku Origins" catalog v0.1 is available in the thread and supersedes earlier placeholder distribution notes.

Catalog shape:

- Exactly 50 cards.
- Common 18, Uncommon 14, Rare 9, Epic 5, Legendary 3, Mythic 1.
- Character 24, Scene 16, Relic 10, Organization 0.
- No invented cards.
- No pack/drop/economy/combat fields.
- Collector values are display values only, not spendable currency.
- `art_path` stores canonical inner-art asset paths.
- `image_url` and `thumbnail_url` remain `NULL` until approved rendered assets need those fields.

## Asset Pipeline

AI-generated card images are inner art only.

The app owns:

- Frame overlay.
- Rarity badge.
- Card name.
- Duplicate/ownership state.
- Future coin value.

Generated art must not bake in frames, text, badges, borders, nameplates, UI, or coin values.

## 30C UI Direction

- Mobile-first Card Collection page.
- Card grid with owned/missing/favorite states.
- Rarity/type/set filters.
- Card detail modal.
- Dark/crimson Anteiku styling.
- EN/FR/DE i18n.
- No CP display.

## Validation Focus

Backend:

- Local reset/migration passes.
- RLS enabled.
- Catalog read is safe.
- Inventory is active-profile scoped.
- Direct inventory/event writes blocked.
- Admin grant permission-gated and audited.
- No CP table/RPC references.
- Active Owner count remains `1`.

Frontend:

- `npm.cmd run build`.
- RPC-only service.
- No direct inventory writes.
- No client-side pack/drop/currency logic.
- No CP values.

Production-direct gate:

- Dry-run must show exactly the intended TCG migration.
- Apply only after clean migration list/dry-run.
- Deploy UI only after target DB has required TCG backend migration.

## References

- Planning document: `docs/TCG_CARD_COLLECTION_PLAN.md`
- Current project state: `ai_agents/PROJECT_STATE.md`
- Security rules: `ai_agents/SECURITY_RULES.md`
- RLS notes: `ai_agents/SUPABASE_RLS.md`
