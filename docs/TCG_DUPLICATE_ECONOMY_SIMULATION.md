# TCG Duplicate Economy Simulation

Milestone 30G-C simulates duplicate sell, dust/crafting, and pity/trade-in options for the current low-rate Season 0 baseline. This is local-only planning and simulation. It does not change SQL, RPCs, prices, drop weights, pack size, coin grants, frontend UI, production data, or member access.

Simulation command:

```powershell
node scripts/tcg-duplicate-economy-sim.mjs
```

## Summary

Historical 30G-C recommendation: **balanced dust/crafting plus soft pity guardrails**, with current low drop rates unchanged.

30G-G direction reset:

- Duplicate Burn/Craft is now experimental/later for public member release.
- Do not include Duplicate Economy in the initial member release by default unless Owner explicitly re-approves it.
- Trading is now the preferred future duplicate/social solution.
- Keep this simulation as a reference for optional later burn, dust, crafting, event trade-in, or pity support.

Why:

- Coin sell helps duplicates feel less dead, but direct coin refunds can inflate pack volume if too generous.
- Balanced dust/crafting gives long-term progress without directly discounting every future pack.
- Soft pity protects extreme bad luck for Legendary/Mythic while preserving rare-pull excitement.
- The current low-rate drop table should stay unchanged until duplicate value is modeled in product terms.

## Current Duplicate Problem

30G-B showed duplicate pressure grows quickly:

| Packs | Avg completion | Avg duplicates | Avg duplicate rate | Own Legendary | Own Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 77.56% | 61.22 | 61.22% | 58.92% | 10.08% |
| 40 | 90.41% | 154.80 | 77.40% | 83.43% | 18.15% |
| 60 | 94.45% | 252.77 | 84.26% | 93.02% | 26.13% |
| 100 | 97.21% | 451.40 | 90.28% | 99.00% | 39.15% |

Problem:

- Early and mid collection speed is healthy.
- After about 40 packs, players have high completion but most new pulls are duplicates.
- Without duplicate value, pack opening risks feeling bad even if drop rates are mathematically fair.
- Mythic remains a prestige chase and should not be made common just to solve duplicate frustration.

## Simulation Method

- Script: `scripts/tcg-duplicate-economy-sim.mjs`.
- Runs: 10,000 simulated players.
- Seed: `300703`.
- Pack price: 100 Anteiku Coins.
- Pack size: 5 cards.
- Drop weights: Common 6000, Uncommon 2500, Rare 1000, Epic 400, Legendary 90, Mythic 10.
- Catalog: 18 Common, 14 Uncommon, 9 Rare, 5 Epic, 3 Legendary, 1 Mythic.
- Each card pull rolls rarity by weight, then picks uniformly within that rarity.
- No production data or Supabase state is read or mutated.

## No-Duplicate-Value Baseline

The no-value baseline is the pain comparison:

- 40 packs already averages about 90% completion and about 155 duplicates.
- 100 packs averages about 97% completion and about 451 duplicates.
- The last cards, especially Mythic, become the main chase while duplicate counts pile up.

This confirms the issue is not early collection speed. The issue is making duplicate-heavy late progress feel useful.

## Coin Sell Model Results

Coin sell converts duplicates back into Anteiku Coins.

### Conservative Sell

Values: Common 1, Uncommon 2, Rare 6, Epic 20, Legendary 75, Mythic 250.

| Packs | Avg refund | Refund/pack | Effective pack cost | Extra packs enabled |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 127.61 | 6.38 | 93.62 | 1.28 |
| 40 | 364.83 | 9.12 | 90.88 | 3.65 |
| 60 | 640.72 | 10.68 | 89.32 | 6.41 |
| 100 | 1240.76 | 12.41 | 87.59 | 12.41 |

Read: safe and mild. It makes duplicates feel a little useful without destabilizing pack cost.

### Balanced Sell

Values: Common 1, Uncommon 3, Rare 10, Epic 30, Legendary 100, Mythic 300.

| Packs | Avg refund | Refund/pack | Effective pack cost | Extra packs enabled |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 172.14 | 8.61 | 91.39 | 1.72 |
| 40 | 501.09 | 12.53 | 87.47 | 5.01 |
| 60 | 886.70 | 14.78 | 85.22 | 8.87 |
| 100 | 1725.97 | 17.26 | 82.74 | 17.26 |

Read: viable if the goal is a light refund loop, but it still accelerates pack count meaningfully by late Season 0.

### Generous Sell

Values: Common 2, Uncommon 5, Rare 18, Epic 60, Legendary 180, Mythic 500.

| Packs | Avg refund | Refund/pack | Effective pack cost | Extra packs enabled |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 320.36 | 16.02 | 83.98 | 3.20 |
| 40 | 931.36 | 23.28 | 76.72 | 9.31 |
| 60 | 1647.37 | 27.46 | 72.54 | 16.47 |
| 100 | 3205.40 | 32.05 | 67.95 | 32.05 |

Read: too inflationary for v1. It effectively discounts packs by about one third at 100 packs and risks speeding completion by refund loops.

Coin sell recommendation:

- If coin sell ships, start with Conservative.
- Do not use Generous.
- Prefer dust/crafting first because it creates progress without directly refunding pack purchases.

## Dust / Crafting Model Results

Dust converts duplicates into a separate non-premium crafting currency, such as Anteiku Fragments.

### Conservative Dust

Values: Common 1, Uncommon 3, Rare 10, Epic 35, Legendary 120, Mythic 400.
Costs: Common 40, Uncommon 120, Rare 500, Epic 1800, Legendary 6000, Mythic 20000.

| Packs | Avg dust | p50 dust | p90 dust | Can craft Rare | Can craft Epic | Can craft Legendary | Can craft Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 181.19 | 165 | 263 | 0.52% | 0.00% | 0.00% | 0.00% |
| 40 | 532.02 | 509 | 698 | 34.21% | 0.00% | 0.00% | 0.00% |
| 60 | 946.69 | 920 | 1193 | 28.25% | 0.08% | 0.00% | 0.00% |
| 100 | 1855.48 | 1822 | 2233 | 3.63% | 3.45% | 0.00% | 0.00% |

Read: too stingy for meaningful duplicate relief. It mostly helps Common/Uncommon and occasionally Rare.

### Balanced Dust

Values: Common 2, Uncommon 5, Rare 18, Epic 60, Legendary 200, Mythic 700.
Costs: Common 30, Uncommon 90, Rare 350, Epic 1400, Legendary 5000, Mythic 16000.

| Packs | Avg dust | p50 dust | p90 dust | Can craft Rare | Can craft Epic | Can craft Legendary | Can craft Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 323.64 | 297 | 461 | 30.68% | 0.01% | 0.00% | 0.00% |
| 40 | 943.95 | 906 | 1224 | 64.92% | 2.30% | 0.00% | 0.00% |
| 60 | 1674.23 | 1630 | 2089 | 28.25% | 27.42% | 0.00% | 0.00% |
| 100 | 3269.94 | 3213 | 3910 | 3.63% | 8.53% | 0.09% | 0.00% |

Read: best v1 candidate. It gives practical Rare/Epic relief but keeps Legendary and Mythic as rare long-tail cards.

### Generous Dust

Values: Common 3, Uncommon 8, Rare 30, Epic 100, Legendary 350, Mythic 1200.
Costs: Common 25, Uncommon 70, Rare 275, Epic 1000, Legendary 3500, Mythic 12000.

| Packs | Avg dust | p50 dust | p90 dust | Can craft Rare | Can craft Epic | Can craft Legendary | Can craft Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 522.90 | 476 | 759 | 95.91% | 2.29% | 0.00% | 0.00% |
| 40 | 1535.18 | 1468 | 2016 | 64.92% | 64.86% | 0.12% | 0.00% |
| 60 | 2732.64 | 2653 | 3447 | 28.25% | 37.20% | 5.53% | 0.00% |
| 100 | 5358.43 | 5256 | 6466 | 3.63% | 8.53% | 52.56% | 0.00% |

Read: strong for frustration relief, but too fast for Legendary crafting in v1. It may be useful later for catch-up seasons.

Dust/crafting historical recommendation:

- Use Balanced Dust as the preferred direction.
- Keep Mythic crafting unrealistic in v1.
- Let Rare/Epic crafting soften frustration.
- Keep Legendary crafting either very expensive, gated, once-per-season, or event-linked.
- 30G-G supersedes this for public release: treat burn/craft as optional later infrastructure, not the default public economy.

## Pity / Trade-In Model Results

### Soft Pity

Simulated rule:

- After 50 packs without Legendary, the next pack guarantees Legendary or better.
- After 150 packs without Mythic, the next pack guarantees Mythic.

| Model | Avg first Legendary | Median first Legendary | p90 first Legendary | Avg first Mythic | Median first Mythic | p90 first Mythic | Found Mythic by 200 packs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| No pity | 20.35 | 14 | 46 | 83.17* | 74* | 169* | 62.67% |
| Soft pity | 19.08 | 15 | 47 | 104.00 | 130 | 151 | 100.00% |

`*` No-pity Mythic timing only averages players who found Mythic by 200 packs, so it excludes 37.33% of players who did not find one by then.

Checkpoint impact:

| Packs | No pity completion | Soft pity completion | No pity Mythic | Soft pity Mythic |
| ---: | ---: | ---: | ---: | ---: |
| 20 | 77.46% | 77.52% | 9.22% | 9.61% |
| 40 | 90.29% | 90.33% | 18.12% | 18.61% |
| 60 | 94.44% | 94.61% | 26.41% | 27.71% |
| 100 | 97.22% | 97.41% | 39.74% | 41.61% |

Read:

- Soft pity does not meaningfully speed early completion.
- It protects extreme bad luck.
- Mythic still remains a long-tail flex pull because the guarantee does not matter until after 150 packs.
- This is a good safety valve, but it should be hidden/server-side and carefully audited if implemented later.

### Trade-In Pity

In this simulation, trade-in pity is represented by dust crafting a missing card by rarity.

Recommended guardrails:

- Use a separate non-premium dust currency.
- Allow missing-card crafting only.
- Limit Legendary crafting with once-per-season or cooldown rules.
- Keep Mythic crafting disabled or event-only in v1.
- Avoid converting dust directly into unlimited packs.

Read:

- Balanced Dust supports Rare/Epic relief without making high-rarity completion trivial.
- Generous Dust makes Legendary crafting possible for too many players by 100 packs.
- Conservative Dust is too weak to solve the duplicate pain.

## Risks And Abuse Considerations

- Direct coin refunds can create economy inflation and more pack loops than intended.
- Sell values must not make opening packs self-sustaining.
- Dust must not be transferable or premium-adjacent in v1.
- Crafting should use backend authority only.
- Trade-ins should require ownership/duplicate checks server-side.
- Pity counters must be backend-owned and not frontend-calculated.
- Member-facing release still requires abuse checks, no direct table writes, no client-side drops, no CP exposure, and hidden Owner test tools.

## Recommended Duplicate Economy Direction

Recommended starting model for future implementation: **Balanced Dust + Soft Pity**.

Details:

- Do not apply a drop-rate patch yet.
- Do not use generous coin sell.
- Prefer dust/crafting over coin refunds.
- Use Balanced Dust values as the first implementation candidate.
- Start with Rare/Epic crafting relief.
- Keep Legendary expensive, gated, or event-linked.
- Keep Mythic as prestige/event/pity-only for now.
- Consider Conservative Coin Sell only as a later secondary sink if dust alone feels too abstract.

## Drop Rates

Current low drop rates should stay unchanged for now:

- Common 6000
- Uncommon 2500
- Rare 1000
- Epic 400
- Legendary 90
- Mythic 10

The simulation does not justify buffing Legendary/Mythic rates before duplicate value and pity are tested.

## Recommended Next Milestone

30G-D: Duplicate Economy Design Specification. Complete in `docs/TCG_DUPLICATE_ECONOMY_DESIGN.md`.

Plan the concrete backend-safe model for:

- `Anteiku Fragments` or equivalent dust currency.
- Duplicate burn rules.
- Missing-card crafting rules.
- Legendary/Mythic guardrails.
- Soft pity counters.
- Server-side abuse prevention.
- Owner-only validation before member release.

30G-D design direction:

- Use Anteiku Fragments as a non-premium duplicate-burn currency.
- Enable missing-card crafting for Common, Uncommon, Rare, and Epic.
- Keep Legendary gated.
- Keep Mythic future locked / not v1 for direct crafting.
- Add server-side Legendary and Mythic soft pity counters later.
