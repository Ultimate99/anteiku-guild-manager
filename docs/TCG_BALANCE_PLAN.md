# TCG Balance Plan

Milestone 30G-A is a planning-only balance analysis for the Owner-only TCG economy and drop-rate system. It does not change SQL, RPCs, prices, drop weights, pack size, coin grants, frontend behavior, production data, or member access.

## 30G-I0 Owner Test-State Reset

Milestone 30G-I0 adds an Owner-only reset tool so the Owner can wipe their own TCG test state and replay Candidate A pack feel from zero.

This is not a balance patch:

- Drop weights remain Candidate A.
- Pack price remains `100` Anteiku Coins.
- Pack size remains `5`.
- Fragment values, crafting costs, and pity thresholds remain unchanged.
- Catalog/drop-rate/shop/crafting definitions are not reset.
- Other profiles are not reset.
- Codex must not click the production reset button.

The reset clears only the current active Owner profile's test-state rows:

- inventory and inventory events
- pack inventory and pack inventory events
- pack opening history
- Anteiku Coins wallet and ledger
- Anteiku Fragments wallet and ledger
- pity counters

Use case:

- Owner may reset manually, then test pack/shop flow cleanly against Candidate A.
- Use the clean run to judge whether Epics now feel less casual and whether future Trading/member-release planning can proceed.

## 30G-H Candidate A Epic-Rate Patch

Milestone 30G-H applies the approved Candidate A drop-rate tuning patch for the Season 0 Test Pack through `20260613101908_tcg_candidate_a_epic_rate_balance.sql`.

Applied change:

| Rarity | Previous weight | 30G-H weight |
| --- | ---: | ---: |
| Common | 6000 | 6200 |
| Uncommon | 2500 | 2500 |
| Rare | 1000 | 900 |
| Epic | 400 | 300 |
| Legendary | 90 | 90 |
| Mythic | 10 | 10 |

Result:

- Total drop weight remains `10000`.
- Epic chance per 5-card pack moves from about `18.46%` to about `14.13%`.
- Expected first Epic moves from about `5.42` packs to about `7.08` packs.
- Legendary and Mythic remain unchanged.
- Pack price remains `100` Anteiku Coins.
- Pack size remains `5`.
- No inventory, wallet, fragments, crafting, pity counters, pack openings, shop items, catalog cards, frontend UI, member access, or CP systems changed.

## 30G-G Direction Reset

Milestone 30G-G resets the public-release balance direction:

- Duplicate Burn/Craft is now **experimental/later**, not the default member-release economy.
- 30G-F1/F2/F3 remain useful Owner-only testing infrastructure, but public member release should not depend on fragments/crafting unless explicitly approved later.
- Trading is now the preferred long-term duplicate/social solution.
- Burning may return later only as an optional backup path: coin sell, event trade-in, fragments backup, pity support, or limited duplicate sinks.
- No production weights, prices, pack size, backend, frontend UI, SQL, RPCs, RLS, or production data changed in 30G-G.

Trading-first duplicate direction:

- Future trading should be designed separately before implementation.
- Start with one-to-one or offer-based trades.
- Both players must confirm.
- Backend escrow is required so neither side can lose cards without the matching transfer.
- Trade logs/audit are required.
- No CP values, email, auth IDs, or private admin metadata should appear in trade payloads.
- Frontend must never directly mutate inventory.
- Cooldowns, limits, rarity restrictions, and locked/favorite-card restrictions should be considered before public release.

Current balance concern:

- Epic is currently 4.0% per card and about 18.46% per 5-card pack.
- Owner feedback says Epic currently feels too casual.
- 30G-G simulates Epic-rate reductions while keeping Legendary and Mythic unchanged.

## Current Production Baseline

After 30G-H, the current production baseline is Candidate A. It remains a low-rate baseline, not a high-rarity buff.

Current constants:

| Value | Current setting |
| --- | --- |
| Pack | Season 0 Test Pack |
| Pack price | 100 Anteiku Coins |
| Pack size | 5 cards |
| Catalog size | 50 cards |
| Catalog distribution | 18 Common, 14 Uncommon, 9 Rare, 5 Epic, 3 Legendary, 1 Mythic |

Current drop weights after 30G-H:

| Rarity | Weight | Pull share |
| --- | ---: | ---: |
| Common | 6200 | 62.0% |
| Uncommon | 2500 | 25.0% |
| Rare | 900 | 9.0% |
| Epic | 300 | 3.0% |
| Legendary | 90 | 0.9% |
| Mythic | 10 | 0.1% |

Interpretation:

- Legendary and Mythic cards should remain rare flex pulls for now.
- Do not balance first by raising high-rarity rates.
- First test whether the low-rate baseline feels acceptable when paired with controlled weekly coin income and later duplicate value.
- Current Mythic scarcity may be acceptable if future duplicate selling, crafting, pity, event rewards, or milestone rewards soften the long tail.

## Owner Test Data

Current observed Owner Balance Report data:

| Metric | Observed value |
| --- | ---: |
| Unique owned | 45 / 50 |
| Missing cards | 5 |
| Total owned quantity | 208 |
| Duplicate quantity total | 163 |
| Completion | 90% |
| Total pack openings | 40 |
| Cards pulled | 200 |
| Test openings | 40 |
| Shop openings | 36 |
| Free test openings | 4 |
| Current balance | 100 Anteiku Coins |
| Coins granted | 4000 |
| Coins spent | 3900 |
| Pack spend | 3900 |
| Average spend per pack | 100 |
| Duplicate rate | 78.37% |
| Missing rate | 10% |

Observed rarity pulls:

| Rarity | Pulled | Pull share |
| --- | ---: | ---: |
| Common | 108 | 54.0% |
| Uncommon | 56 | 28.0% |
| Rare | 27 | 13.5% |
| Epic | 8 | 4.0% |
| Legendary | 1 | 0.5% |
| Mythic | 0 | 0.0% |

Important limitation:

- This is Owner test data, not clean member balance data.
- It includes smoke grants, free test packs, shop test packs, and manual testing.
- Use it directionally only. It is useful for noticing duplicate pressure and long-tail rarity pressure, but it is not final evidence for member release.

Directional read:

- 45 / 50 unique after 40 openings suggests early and mid collection progress is already fast enough under the low-rate baseline.
- 163 duplicates at 90% completion shows duplicate pressure becomes the core pain point before full completion.
- 0 Mythic from 200 pulls is not surprising at 0.1% per card pull; the chance to see at least one Mythic by 40 packs is only about 18%.
- Legendary at 1 pull from 200 pulls is close enough to the low sample-size expectation to avoid overreacting.

## Target Member Progression

Recommended next simulation model: Current Low-Rate Baseline.

Coin and pack assumptions for simulation:

- Keep pack price at 100 Anteiku Coins.
- Simulate active member income around 400-550 coins per week.
- This creates roughly 4-5 packs per active member per week.
- Measure progress at 20, 40, 60, and 100 packs.
- Measure duplicate pressure at the same checkpoints.
- Measure expected time to first Legendary and first Mythic.

Practical guild-app target:

| Target | Directional goal |
| --- | --- |
| 50% collection | Should happen early enough to feel rewarding. |
| 75% collection | Should be reachable through steady activity without special events. |
| 90% collection | Should feel like committed Season 0 progress, not a wall. |
| 100% collection | Should be prestige/endgame unless duplicate value or pity exists. |
| Legendary | Should feel rare but visible for active members. |
| Mythic | Should remain a flex pull and may need event/pity support later. |

Current low-rate timing estimates to validate in 30G-B:

- First Legendary: roughly 4.4% chance per pack; median around 15 packs and average around 23 packs.
- First Mythic: roughly 0.5% chance per pack; median around 139 packs and average around 200 packs.
- At 4-5 packs per week, Mythic can be a long-tail chase measured in months unless event rewards, pity, crafting, or trade-ins exist.

## Economy Model Options

### A. Current Low-Rate Baseline - Primary Next Simulation

Use the current weights and price unchanged. Test whether low high-rarity rates are acceptable with controlled coin income and future duplicate sinks.

Why this is the recommended next step:

- It respects the current production setup.
- It preserves Legendary/Mythic as rare flex pulls.
- It avoids premature high-rarity inflation.
- It gives a clean baseline for deciding whether the pain is drop-rate, coin-income, duplicate-value, or pity related.

### B. Casual Higher-Rate Model - Do Not Apply Yet

Example alternative weights only:

| Rarity | Alternative weight |
| --- | ---: |
| Common | 5000 |
| Uncommon | 2600 |
| Rare | 1450 |
| Epic | 650 |
| Legendary | 250 |
| Mythic | 50 |

Use only if the low-rate baseline feels too punishing after duplicate value and coin-income simulation.

### C. Balanced Higher-Rate Model - Do Not Apply Yet

Example alternative weights only:

| Rarity | Alternative weight |
| --- | ---: |
| Common | 5600 |
| Uncommon | 2550 |
| Rare | 1150 |
| Epic | 500 |
| Legendary | 160 |
| Mythic | 40 |

This was previously a possible default, but 30G-A direction now keeps it as an alternative only.

### D. Prestige Collector Model - Do Not Apply Yet

Example alternative weights only:

| Rarity | Alternative weight |
| --- | ---: |
| Common | 6200 |
| Uncommon | 2500 |
| Rare | 900 |
| Epic | 300 |
| Legendary | 85 |
| Mythic | 15 |

This keeps a hard chase but should not be used until duplicate sinks, pity, or event rewards exist.

## Coin Income Planning

Do not judge the 100 coin pack price by itself. Pack price only makes sense with weekly coin sources.

Initial income sources to simulate:

| Source | Planning amount |
| --- | ---: |
| Daily login / check-in | 25 coins per day |
| Weekly activity reward | 200 coins per week |
| GvG participation reward later | 100 coins per event/week |
| Admin/event grants | 25-150 coins as controlled bonuses |

Simulation target:

- Active members should land around 400-550 coins per week.
- That supports about 4-5 packs per week at the current 100 coin price.
- Inactive or low-activity members should progress slower without being locked out forever.

Do not implement income in 30G-A. This is only the assumption set for 30G-B simulation.

## Duplicate / Trading Planning

Duplicate pressure is the largest observed issue: 163 duplicates at 45 / 50 unique.

Public-release direction:

- Prefer future card trading as the main duplicate/social solution.
- Keep Duplicate Burn/Craft Owner-only and experimental/later by default.
- Do not require fragments/crafting for initial member release unless Owner explicitly re-approves it.
- Keep Soft Pity available as backend protection, but expose member-facing pity only after release rules are approved.

Future trading value options:

- One-to-one trades.
- Offer-based trades.
- Backend escrow with dual confirmation.
- Trade logs/audit.
- Rarity restrictions or cooldowns if abuse risk appears.
- Locked/favorite cards not tradable unless explicitly unlocked.

Optional later duplicate backup paths:

- Sell duplicates for Anteiku Coins.
- Event trade-in.
- Dust/fragments backup.
- Duplicate milestones.
- Pity support.
- Card upgrade cosmetics or profile flair.

Recommended direction:

- Do not raise Legendary/Mythic rates.
- Test Epic nerf candidates first because Epic currently feels too casual.
- Prefer trading design before committing burn/craft to member release.
- Avoid real-money or premium currency planning until the free economy feels healthy.

## Release Gates

TCG must remain Owner-only until these are true:

- Current Low-Rate Baseline simulation is completed and reviewed.
- A balance patch is selected or the current baseline is explicitly accepted.
- Member-safe pack/shop RPCs are planned and validated.
- Owner test controls are hidden from members.
- Free coin sources are planned with abuse checks.
- Duplicate value strategy is selected; Duplicate Burn/Craft is not required by default for initial member release.
- Trading design is either deferred safely or planned as the preferred future social duplicate solution.
- Backend remains the only authority for drops, wallet mutation, pack consumption, and inventory mutation.
- Frontend performs no direct table writes.
- No CP values, `member_cp`, `cp_snapshots`, or CP analytics paths are used.
- No payments or premium currency exist.

## Recommended Next Milestones

- 30G-B: Balance Simulation for Current Low-Rate Baseline. Complete in `docs/TCG_BALANCE_SIMULATION.md`.
- 30G-C: Duplicate sell/burn/pity simulation before any drop-rate patch. Complete in `docs/TCG_DUPLICATE_ECONOMY_SIMULATION.md`.
- 30G-D: Duplicate Economy Design Specification for balanced dust/crafting plus soft pity guardrails. Complete in `docs/TCG_DUPLICATE_ECONOMY_DESIGN.md`.
- 30G-G: Balance Direction Reset + Epic Rate Simulation. Complete in `docs/TCG_BALANCE_SIMULATION.md`.
- 30H: Member-safe TCG release gate.

30G-B result:

- Current low rates are acceptable for early and mid collection testing.
- At 4-5 packs per week, average 90% completion lands around 7-9 weeks.
- Mythic remains a months-long chase: median about 139 packs and expected about 200 packs.
- Duplicate pressure becomes painful around 40 packs, when average completion is about 90% and duplicate rate is about 77%.
- Historical 30G-B recommendation was not to apply higher drop rates yet.
- 30G-H later applies Candidate A as a low-rate Epic tuning patch, not a high-rarity buff.
- Simulate duplicate value, sell/burn, crafting, or pity before member release.

30G-A and 30G-B can be marked complete when the planning and simulation docs plus handoff docs are updated and validation passes.

30G-C result:

- Coin sell helps duplicates feel less dead, but generous coin refunds are inflationary.
- Balanced Dust gives useful Rare/Epic progress without directly refunding the pack economy.
- Soft pity protects extreme Legendary/Mythic bad luck without meaningfully accelerating early completion.
- Historical 30G-C recommendation kept the then-current low drop rates unchanged.
- Historical recommendation was Balanced Dust + Soft Pity, with Mythic remaining prestige/event/pity-only.
- 30G-G supersedes that as the default public-release direction: burn/craft is experimental/later, while trading is the preferred future duplicate/social solution.

30G-D design result:

- Future duplicate currency name: Anteiku Fragments.
- Fragment source: duplicate burn only in v1.
- Balanced burn values: Common 2, Uncommon 5, Rare 18, Epic 60, Legendary 200, Mythic 700.
- Balanced crafting costs: Common 30, Uncommon 90, Rare 350, Epic 1400, Legendary 5000 gated, Mythic 16000 future locked / not v1.
- Crafting is missing-card focused and backend-authoritative.
- Soft pity is server-side only: Legendary at 50 eligible packs without Legendary or better; Mythic at 150 eligible packs without Mythic.
- No production implementation is included in 30G-D.

30G-G result:

- Current Epic chance is about 18.46% per pack.
- Candidate A reduces Epic to about 14.13% per pack and keeps 90% completion around 8.47 weeks at 5 packs/week.
- Candidate B reduces Epic to about 11.89% per pack and pushes 90% completion to about 9.05 weeks at 5 packs/week.
- Legendary and Mythic timing stay unchanged in both candidates.
- Candidate A is the preferred next balance candidate to test because it makes Epic less casual without making packs feel flat.
