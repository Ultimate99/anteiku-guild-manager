# TCG Balance Simulation

Milestone 30G-B simulates the current low-rate production baseline for Season 0. This is a local-only report. It does not change SQL, RPCs, prices, drop weights, pack size, coin grants, frontend UI, production data, or member access.

Simulation command:

```powershell
node scripts/tcg-balance-sim.mjs
```

30G-G extends the same local script to compare Epic-rate tuning candidates. It still does not change production values.

## 30G-H Applied Outcome

Milestone 30G-H approved and production-applied Candidate A for the Season 0 Test Pack through `20260613101908_tcg_candidate_a_epic_rate_balance.sql`.

Current production weights after 30G-H:

| Rarity | Weight |
| --- | ---: |
| Common | 6200 |
| Uncommon | 2500 |
| Rare | 900 |
| Epic | 300 |
| Legendary | 90 |
| Mythic | 10 |

The historical "Current baseline" rows below refer to the pre-30G-H baseline used for simulation comparison. Candidate A is now the live Owner-only test baseline.

30G-H keeps:

- Legendary and Mythic unchanged.
- Pack price at `100` Anteiku Coins.
- Pack size at `5`.
- Duplicate Burn/Craft experimental/later.
- Trading as the preferred future duplicate/social direction.

## 30G-G Epic Rate Candidate Simulation

30G-G direction:

- Keep Duplicate Burn/Craft experimental/later for public release.
- Prefer future card trading as the main duplicate/social solution.
- Do not change Legendary or Mythic rates.
- Test whether Epic can feel less casual without making packs feel boring.

Simulation method for 30G-G:

- 10,000 simulated players per model.
- Deterministic base seed: `300702`.
- Season 0 catalog: 50 cards.
- Pack size: 5 cards.
- Pack price: 100 Anteiku Coins.
- Each card pull first rolls rarity by model weight, then chooses a card uniformly from that rarity.
- No pity, duplicate protection, duplicate selling, crafting, trading, event rewards, or admin grants are included.

### Model Weights

| Model | Common | Uncommon | Rare | Epic | Legendary | Mythic | Epic chance / pack |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 6000 | 2500 | 1000 | 400 | 90 | 10 | 18.46% |
| Candidate A - slightly harder Epic | 6200 | 2500 | 900 | 300 | 90 | 10 | 14.13% |
| Candidate B - stronger Epic nerf | 6300 | 2500 | 850 | 250 | 90 | 10 | 11.89% |

### Checkpoint Comparison

#### 20 Packs

| Model | Avg unique | Avg completion | Avg duplicates | Avg duplicate rate | Avg Rare unique | Avg Epic unique | Avg Legendary unique | Avg Mythic unique |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 38.78 | 77.56% | 61.22 | 61.22% | 6.05 | 2.75 | 0.77 | 0.10 |
| Candidate A | 37.99 | 75.99% | 62.01 | 62.01% | 5.71 | 2.25 | 0.78 | 0.10 |
| Candidate B | 37.56 | 75.12% | 62.44 | 62.44% | 5.53 | 1.97 | 0.77 | 0.10 |

#### 40 Packs

| Model | Avg unique | Avg completion | Avg duplicates | Avg duplicate rate | Avg Rare unique | Avg Epic unique | Avg Legendary unique | Avg Mythic unique |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 45.20 | 90.41% | 154.80 | 77.40% | 8.06 | 3.99 | 1.36 | 0.18 |
| Candidate A | 44.42 | 88.84% | 155.58 | 77.79% | 7.79 | 3.50 | 1.35 | 0.19 |
| Candidate B | 43.96 | 87.91% | 156.04 | 78.02% | 7.66 | 3.16 | 1.35 | 0.18 |

#### 60 Packs

| Model | Avg unique | Avg completion | Avg duplicates | Avg duplicate rate | Avg Rare unique | Avg Epic unique | Avg Legendary unique | Avg Mythic unique |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 47.23 | 94.45% | 252.77 | 84.26% | 8.69 | 4.56 | 1.78 | 0.26 |
| Candidate A | 46.71 | 93.43% | 253.29 | 84.43% | 8.56 | 4.19 | 1.77 | 0.27 |
| Candidate B | 46.35 | 92.70% | 253.65 | 84.55% | 8.48 | 3.90 | 1.78 | 0.25 |

#### 100 Packs

| Model | Avg unique | Avg completion | Avg duplicates | Avg duplicate rate | Avg Rare unique | Avg Epic unique | Avg Legendary unique | Avg Mythic unique |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 48.60 | 97.21% | 451.40 | 90.28% | 8.97 | 4.91 | 2.33 | 0.39 |
| Candidate A | 48.43 | 96.85% | 451.57 | 90.31% | 8.94 | 4.75 | 2.33 | 0.40 |
| Candidate B | 48.24 | 96.48% | 451.76 | 90.35% | 8.92 | 4.59 | 2.33 | 0.39 |

### First Pull Timing

| Model | Rarity | Chance / pack | Expected packs | Median packs | By 5 packs | By 10 packs | By 20 packs |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | Epic | 18.46% | 5.42 | 4 | 63.96% | 87.01% | 98.31% |
| Candidate A | Epic | 14.13% | 7.08 | 5 | 53.30% | 78.19% | 95.24% |
| Candidate B | Epic | 11.89% | 8.41 | 6 | 46.90% | 71.80% | 92.05% |
| Current baseline | Legendary | 4.42% | 22.63 | 16 | - | - | 59.51% |
| Candidate A | Legendary | 4.42% | 22.63 | 16 | - | - | 59.51% |
| Candidate B | Legendary | 4.42% | 22.63 | 16 | - | - | 59.51% |
| Current baseline | Mythic | 0.50% | 200.40 | 139 | - | - | 9.52% |
| Candidate A | Mythic | 0.50% | 200.40 | 139 | - | - | 9.52% |
| Candidate B | Mythic | 0.50% | 200.40 | 139 | - | - | 9.52% |

Legendary and Mythic timing stay unchanged because both candidate models keep those weights fixed.

### 90% Collection Timing

At 100 coins per pack:

| Model | Coins/week | Packs/week | Avg weeks to 90% | P50 weeks to 90% | P90 weeks to 90% | Expected weeks to Epic | Expected weeks to Legendary | Expected weeks to Mythic |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Current baseline | 400 | 4.0 | 9.41 | 9.00 | 12.50 | 1.36 | 5.66 | 50.10 |
| Current baseline | 500 | 5.0 | 7.53 | 7.20 | 10.00 | 1.08 | 4.53 | 40.08 |
| Candidate A | 400 | 4.0 | 10.59 | 10.25 | 14.25 | 1.77 | 5.66 | 50.10 |
| Candidate A | 500 | 5.0 | 8.47 | 8.20 | 11.40 | 1.42 | 4.53 | 40.08 |
| Candidate B | 400 | 4.0 | 11.31 | 10.75 | 15.25 | 2.10 | 5.66 | 50.10 |
| Candidate B | 500 | 5.0 | 9.05 | 8.60 | 12.20 | 1.68 | 4.53 | 40.08 |

### 30G-G Interpretation

Current problem:

- Epic appears in almost one out of five packs on average.
- By 10 packs, the current baseline gives an 87.01% chance of at least one Epic.
- By 20 packs, Epic is almost guaranteed at 98.31%.

Candidate A:

- Lowers Epic per-pack chance to 14.13%.
- Expected first Epic moves from 5.42 packs to 7.08 packs.
- Chance of at least one Epic by 10 packs drops to 78.19%.
- Average 90% completion at 5 packs/week moves from 7.53 weeks to 8.47 weeks.
- This is noticeable without making the pack feel flat.

Candidate B:

- Lowers Epic per-pack chance to 11.89%.
- Expected first Epic moves to 8.41 packs.
- Chance of at least one Epic by 10 packs drops to 71.80%.
- Average 90% completion at 5 packs/week moves to 9.05 weeks.
- This makes Epic meaningfully rarer but may make mid-rarity progress feel slower unless trading or event rewards exist.

Recommendation:

- 30G-G recommendation was to prefer **Candidate A** for the next balance patch candidate if Owner wants Epic to feel less casual.
- 30G-G did not apply Candidate A; 30G-H later approved and applied Candidate A.
- Candidate B should remain an alternative if Owner still feels Epic is too common after seeing Candidate A modeled.
- Keep Legendary and Mythic unchanged.
- Keep Duplicate Burn/Craft experimental/later for member release.
- Plan trading separately as the preferred future duplicate/social solution.

Simulation method:

- 10,000 simulated players.
- Deterministic seed: `300702`.
- Season 0 catalog modeled as 50 cards.
- Pack size: 5 cards.
- Pack price: 100 Anteiku Coins.
- Each card pull first rolls rarity by production weight, then chooses a card uniformly from that rarity.
- No pity, duplicate protection, duplicate selling, crafting, event rewards, trading, or admin grants are included.

## Current Baseline Simulated

| Rarity | Catalog count | Weight | Pull share |
| --- | ---: | ---: | ---: |
| Common | 18 | 6000 | 60.0% |
| Uncommon | 14 | 2500 | 25.0% |
| Rare | 9 | 1000 | 10.0% |
| Epic | 5 | 400 | 4.0% |
| Legendary | 3 | 90 | 0.9% |
| Mythic | 1 | 10 | 0.1% |

## Pack Checkpoints

| Packs | Cards | Avg unique | Avg completion | Avg missing | Avg duplicates | Avg duplicate rate | Completion p10/p50/p90 | Duplicates p10/p50/p90 | Own Legendary | Own Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 100 | 38.78 | 77.56% | 11.22 | 61.22 | 61.22% | 72% / 78% / 84% | 58 / 61 / 64 | 58.92% | 10.08% |
| 40 | 200 | 45.20 | 90.41% | 4.80 | 154.80 | 77.40% | 86% / 90% / 94% | 153 / 155 / 157 | 83.43% | 18.15% |
| 60 | 300 | 47.23 | 94.45% | 2.77 | 252.77 | 84.26% | 92% / 94% / 98% | 251 / 253 / 254 | 93.02% | 26.13% |
| 100 | 500 | 48.60 | 97.21% | 1.40 | 451.40 | 90.28% | 94% / 98% / 100% | 450 / 451 / 453 | 99.00% | 39.15% |

## Rarity Completion

| Packs | Common | Uncommon | Rare | Epic | Legendary | Mythic | Avg Legendary qty | Avg Mythic qty |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 20 | 96.65% | 83.65% | 67.18% | 55.01% | 25.80% | 10.08% | 0.90 | 0.11 |
| 40 | 99.89% | 97.35% | 89.50% | 79.87% | 45.49% | 18.15% | 1.82 | 0.20 |
| 60 | 100.00% | 99.58% | 96.55% | 91.17% | 59.20% | 26.13% | 2.70 | 0.30 |
| 100 | 100.00% | 99.99% | 99.65% | 98.25% | 77.78% | 39.15% | 4.52 | 0.49 |

## First Pull Timing

| Rarity | Chance per pack | Expected packs | Median packs | By 20 packs | By 40 packs | By 60 packs | By 100 packs |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Epic | 18.46% | 5.42 | 4 | 98.31% | 99.97% | 100.00% | 100.00% |
| Legendary | 4.42% | 22.63 | 16 | 59.51% | 83.60% | 93.36% | 98.91% |
| Mythic | 0.50% | 200.40 | 139 | 9.52% | 18.14% | 25.93% | 39.36% |

## Coin-Income Pacing

At 100 coins per pack:

| Coins/week | Packs/week | Avg weeks to 50% | Avg weeks to 75% | Avg weeks to 90% | Expected weeks to Legendary | Expected weeks to Mythic | Median weeks to Legendary | Median weeks to Mythic |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 400 | 4.0 | 2.02 | 4.72 | 9.41 | 5.66 | 50.10 | 4.00 | 34.75 |
| 500 | 5.0 | 1.62 | 3.78 | 7.53 | 4.53 | 40.08 | 3.20 | 27.80 |
| 550 | 5.5 | 1.47 | 3.43 | 6.84 | 4.11 | 36.44 | 2.91 | 25.27 |

Interpretation:

- 4-5 packs per week is not too slow for early and mid collection.
- 50% arrives quickly; 75% is a short-term active-player goal.
- 90% arrives in roughly 7-9 weeks for active members under this model.
- Full completion remains long-tail because Mythic is intentionally rare and duplicate pressure grows quickly.

## Duplicate Pressure

Duplicate pressure is the main release risk:

- At 20 packs, the average duplicate rate is already 61.22%.
- At 40 packs, average completion reaches about 90%, but duplicate rate is 77.40%.
- At 60 packs, average duplicate rate is 84.26%.
- At 100 packs, average duplicate rate is 90.28%.

This means the current rates can work only if duplicate value exists before member release. Without selling, crafting, pity, event trade-ins, or duplicate milestones, opening packs after about 40 packs may feel punishing even though completion looks high.

## Balance Answers

Are current low rates acceptable for a guild community game?

- Directionally yes for early and mid collection.
- Not safe for broad member release without duplicate value or long-tail relief.

Is Mythic too rare without pity/duplicate value?

- Yes for full completion expectations.
- No if Mythic is explicitly positioned as a rare flex pull and can also be supported later by event rewards, pity, crafting, or trade-ins.

Is 4-5 packs/week too fast or too slow?

- It looks reasonable for a small guild community.
- It gives satisfying early progress without instantly completing Season 0.

Does 100 coins/pack make sense with 400-550 coins/week?

- Yes as a first test baseline.
- Do not change pack price before duplicate value and income sources are simulated together.

Should we keep low rates and add duplicate value first?

- Historical 30G-B answer: yes, do not apply higher drop rates yet.
- 30G-H later applies a low-rate Epic tuning patch, not a high-rarity buff.

## Recommendation

Historical 30G-B recommendation before 30G-H:

- Do not change weights.
- Do not change pack price.
- Do not change pack size.
- Do not add member access yet.

Next, simulate duplicate value:

- Sell duplicates for Anteiku Coins.
- Burn duplicates into dust/crafting.
- Trade duplicate value toward missing cards.
- Add pity or event rewards for the long tail.

30G-C duplicate economy simulation is complete in `docs/TCG_DUPLICATE_ECONOMY_SIMULATION.md`.

30G-C recommendation:

- Keep current low drop rates unchanged at that time.
- Prefer Balanced Dust + Soft Pity over direct generous coin refunds.
- Simulate/design the concrete backend-safe duplicate economy before any member release.
