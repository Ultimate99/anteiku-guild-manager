const RUNS = 10000;
const SEED = 300703;
const PACK_SIZE = 5;
const PACK_PRICE = 100;
const CHECKPOINTS = [20, 40, 60, 100];
const MAX_PACKS = 200;

const RARITIES = [
  { key: 'common', label: 'Common', catalogCount: 18, weight: 6000 },
  { key: 'uncommon', label: 'Uncommon', catalogCount: 14, weight: 2500 },
  { key: 'rare', label: 'Rare', catalogCount: 9, weight: 1000 },
  { key: 'epic', label: 'Epic', catalogCount: 5, weight: 400 },
  { key: 'legendary', label: 'Legendary', catalogCount: 3, weight: 90 },
  { key: 'mythic', label: 'Mythic', catalogCount: 1, weight: 10 },
];

const SELL_MODELS = [
  {
    key: 'conservative',
    label: 'Conservative',
    values: { common: 1, uncommon: 2, rare: 6, epic: 20, legendary: 75, mythic: 250 },
  },
  {
    key: 'balanced',
    label: 'Balanced',
    values: { common: 1, uncommon: 3, rare: 10, epic: 30, legendary: 100, mythic: 300 },
  },
  {
    key: 'generous',
    label: 'Generous',
    values: { common: 2, uncommon: 5, rare: 18, epic: 60, legendary: 180, mythic: 500 },
  },
];

const DUST_MODELS = [
  {
    key: 'conservative',
    label: 'Conservative',
    values: { common: 1, uncommon: 3, rare: 10, epic: 35, legendary: 120, mythic: 400 },
    costs: { common: 40, uncommon: 120, rare: 500, epic: 1800, legendary: 6000, mythic: 20000 },
  },
  {
    key: 'balanced',
    label: 'Balanced',
    values: { common: 2, uncommon: 5, rare: 18, epic: 60, legendary: 200, mythic: 700 },
    costs: { common: 30, uncommon: 90, rare: 350, epic: 1400, legendary: 5000, mythic: 16000 },
  },
  {
    key: 'generous',
    label: 'Generous',
    values: { common: 3, uncommon: 8, rare: 30, epic: 100, legendary: 350, mythic: 1200 },
    costs: { common: 25, uncommon: 70, rare: 275, epic: 1000, legendary: 3500, mythic: 12000 },
  },
];

const TOTAL_CARDS = RARITIES.reduce((sum, rarity) => sum + rarity.catalogCount, 0);
const TOTAL_WEIGHT = RARITIES.reduce((sum, rarity) => sum + rarity.weight, 0);
const RARITY_KEYS = RARITIES.map((rarity) => rarity.key);
const RARITY_ORDER_HIGH_TO_LOW = [...RARITIES].reverse().map((rarity) => rarity.key);

function createRng(seed) {
  let state = seed >>> 0;
  return function next() {
    state += 0x6d2b79f5;
    let value = state;
    value = Math.imul(value ^ (value >>> 15), value | 1);
    value ^= value + Math.imul(value ^ (value >>> 7), value | 61);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
}

function round(value, decimals = 2) {
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
}

function percentile(values, percentileValue) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.ceil((percentileValue / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(sorted.length - 1, index))];
}

function average(values) {
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function buildCatalog() {
  const cards = [];
  for (const rarity of RARITIES) {
    for (let index = 0; index < rarity.catalogCount; index += 1) {
      cards.push({ id: `${rarity.key}_${index + 1}`, rarity: rarity.key });
    }
  }
  return cards;
}

const CATALOG = buildCatalog();
const CARDS_BY_RARITY = new Map(
  RARITIES.map((rarity) => [rarity.key, CATALOG.filter((card) => card.rarity === rarity.key)])
);

function chooseRarity(rng, excludeMythic = false) {
  const eligible = excludeMythic ? RARITIES.filter((rarity) => rarity.key !== 'mythic') : RARITIES;
  const totalWeight = eligible.reduce((sum, rarity) => sum + rarity.weight, 0);
  const roll = rng() * totalWeight;
  let cumulative = 0;
  for (const rarity of eligible) {
    cumulative += rarity.weight;
    if (roll < cumulative) return rarity;
  }
  return eligible[eligible.length - 1];
}

function chooseCardFromRarity(rng, rarityKey) {
  const pool = CARDS_BY_RARITY.get(rarityKey);
  return pool[Math.floor(rng() * pool.length)];
}

function openCard(rng) {
  const rarity = chooseRarity(rng);
  return chooseCardFromRarity(rng, rarity.key);
}

function openLegendaryOrBetter(rng) {
  const total = RARITIES.find((rarity) => rarity.key === 'legendary').weight
    + RARITIES.find((rarity) => rarity.key === 'mythic').weight;
  const roll = rng() * total;
  return chooseCardFromRarity(rng, roll < 90 ? 'legendary' : 'mythic');
}

function addCard(inventory, card) {
  inventory.set(card.id, (inventory.get(card.id) ?? 0) + 1);
}

function analyzeInventory(inventory, packsOpened) {
  const rarityUnique = Object.fromEntries(RARITY_KEYS.map((key) => [key, 0]));
  const rarityQuantity = Object.fromEntries(RARITY_KEYS.map((key) => [key, 0]));
  const rarityDuplicates = Object.fromEntries(RARITY_KEYS.map((key) => [key, 0]));
  const rarityMissing = Object.fromEntries(RARITY_KEYS.map((key) => [key, 0]));

  for (const card of CATALOG) {
    const quantity = inventory.get(card.id) ?? 0;
    if (quantity > 0) rarityUnique[card.rarity] += 1;
    rarityQuantity[card.rarity] += quantity;
    rarityDuplicates[card.rarity] += Math.max(quantity - 1, 0);
    if (quantity === 0) rarityMissing[card.rarity] += 1;
  }

  const totalPulled = packsOpened * PACK_SIZE;
  const unique = inventory.size;
  const duplicates = totalPulled - unique;

  return {
    packsOpened,
    totalPulled,
    unique,
    completionPercent: (unique / TOTAL_CARDS) * 100,
    missing: TOTAL_CARDS - unique,
    duplicates,
    duplicateRate: (duplicates / totalPulled) * 100,
    rarityUnique,
    rarityQuantity,
    rarityDuplicates,
    rarityMissing,
  };
}

function duplicateValue(rarityDuplicates, values) {
  return RARITY_KEYS.reduce((sum, key) => sum + rarityDuplicates[key] * values[key], 0);
}

function canCraftMissingRarity(analysis, dust, costs, rarityKey) {
  return analysis.rarityMissing[rarityKey] > 0 && dust >= costs[rarityKey];
}

function highestAffordableMissingRarity(analysis, dust, costs) {
  for (const key of RARITY_ORDER_HIGH_TO_LOW) {
    if (canCraftMissingRarity(analysis, dust, costs, key)) return key;
  }
  return null;
}

function emptyCheckpointBucket() {
  return {
    baseline: {
      completion: [],
      duplicates: [],
      duplicateRate: [],
      legendaryOwned: [],
      mythicOwned: [],
    },
    sell: Object.fromEntries(SELL_MODELS.map((model) => [model.key, { refund: [] }])),
    dust: Object.fromEntries(DUST_MODELS.map((model) => [
      model.key,
      {
        dust: [],
        craftable: Object.fromEntries(RARITY_KEYS.map((key) => [key, []])),
        highestCraftable: [],
      },
    ])),
  };
}

function simulateBaselineEconomy() {
  const rng = createRng(SEED);
  const checkpoints = new Map(CHECKPOINTS.map((packs) => [packs, emptyCheckpointBucket()]));

  for (let run = 0; run < RUNS; run += 1) {
    const inventory = new Map();

    for (let pack = 1; pack <= Math.max(...CHECKPOINTS); pack += 1) {
      for (let card = 0; card < PACK_SIZE; card += 1) {
        addCard(inventory, openCard(rng));
      }

      if (!checkpoints.has(pack)) continue;

      const analysis = analyzeInventory(inventory, pack);
      const bucket = checkpoints.get(pack);

      bucket.baseline.completion.push(analysis.completionPercent);
      bucket.baseline.duplicates.push(analysis.duplicates);
      bucket.baseline.duplicateRate.push(analysis.duplicateRate);
      bucket.baseline.legendaryOwned.push(analysis.rarityUnique.legendary > 0 ? 1 : 0);
      bucket.baseline.mythicOwned.push(analysis.rarityUnique.mythic > 0 ? 1 : 0);

      for (const model of SELL_MODELS) {
        bucket.sell[model.key].refund.push(duplicateValue(analysis.rarityDuplicates, model.values));
      }

      for (const model of DUST_MODELS) {
        const dust = duplicateValue(analysis.rarityDuplicates, model.values);
        const dustBucket = bucket.dust[model.key];
        dustBucket.dust.push(dust);
        for (const key of RARITY_KEYS) {
          dustBucket.craftable[key].push(canCraftMissingRarity(analysis, dust, model.costs, key) ? 1 : 0);
        }
        dustBucket.highestCraftable.push(highestAffordableMissingRarity(analysis, dust, model.costs) ?? 'none');
      }
    }
  }

  return CHECKPOINTS.map((packs) => summarizeCheckpoint(checkpoints.get(packs), packs));
}

function summarizeCheckpoint(bucket, packs) {
  return {
    packs,
    baseline: {
      averageCompletion: round(average(bucket.baseline.completion), 2),
      averageDuplicates: round(average(bucket.baseline.duplicates), 2),
      averageDuplicateRate: round(average(bucket.baseline.duplicateRate), 2),
      chanceLegendary: round(average(bucket.baseline.legendaryOwned) * 100, 2),
      chanceMythic: round(average(bucket.baseline.mythicOwned) * 100, 2),
    },
    sell: Object.fromEntries(SELL_MODELS.map((model) => {
      const refunds = bucket.sell[model.key].refund;
      const averageRefund = average(refunds);
      const refundPerPack = averageRefund / packs;
      return [model.key, {
        averageRefund: round(averageRefund, 2),
        refundPerPack: round(refundPerPack, 2),
        effectivePackCost: round(PACK_PRICE - refundPerPack, 2),
        extraPacksEnabled: round(averageRefund / PACK_PRICE, 2),
        p50Refund: percentile(refunds, 50),
        p90Refund: percentile(refunds, 90),
      }];
    })),
    dust: Object.fromEntries(DUST_MODELS.map((model) => {
      const dust = bucket.dust[model.key].dust;
      return [model.key, {
        averageDust: round(average(dust), 2),
        p50Dust: percentile(dust, 50),
        p90Dust: percentile(dust, 90),
        craftableChance: Object.fromEntries(RARITY_KEYS.map((key) => [
          key,
          round(average(bucket.dust[model.key].craftable[key]) * 100, 2),
        ])),
        highestCraftable: summarizeHighestCraftable(bucket.dust[model.key].highestCraftable),
      }];
    })),
  };
}

function summarizeHighestCraftable(values) {
  const counts = Object.fromEntries(['none', ...RARITY_KEYS].map((key) => [key, 0]));
  for (const value of values) counts[value] += 1;
  return Object.fromEntries(
    Object.entries(counts).map(([key, count]) => [key, round((count / values.length) * 100, 2)])
  );
}

function simulateSoftPity() {
  const rng = createRng(SEED + 1);
  const baseline = {
    firstLegendary: [],
    firstMythic: [],
    checkpointCompletion: Object.fromEntries(CHECKPOINTS.map((pack) => [pack, []])),
    checkpointMythic: Object.fromEntries(CHECKPOINTS.map((pack) => [pack, []])),
  };
  const pity = {
    firstLegendary: [],
    firstMythic: [],
    checkpointCompletion: Object.fromEntries(CHECKPOINTS.map((pack) => [pack, []])),
    checkpointMythic: Object.fromEntries(CHECKPOINTS.map((pack) => [pack, []])),
  };

  for (let run = 0; run < RUNS; run += 1) {
    simulatePityRun(rng, baseline, false);
    simulatePityRun(rng, pity, true);
  }

  return { baseline: summarizePityBucket(baseline), softPity: summarizePityBucket(pity) };
}

function simulatePityRun(rng, bucket, usePity) {
  const inventory = new Map();
  let firstLegendary = null;
  let firstMythic = null;
  let packsSinceLegendary = 0;
  let packsSinceMythic = 0;

  for (let pack = 1; pack <= MAX_PACKS; pack += 1) {
    packsSinceLegendary += 1;
    packsSinceMythic += 1;

    let forcedLegendary = false;
    let forcedMythic = false;

    if (usePity && packsSinceMythic > 150) {
      forcedMythic = true;
    } else if (usePity && packsSinceLegendary > 50) {
      forcedLegendary = true;
    }

    for (let slot = 0; slot < PACK_SIZE; slot += 1) {
      let pulled;
      if (slot === 0 && forcedMythic) {
        pulled = chooseCardFromRarity(rng, 'mythic');
      } else if (slot === 0 && forcedLegendary) {
        pulled = openLegendaryOrBetter(rng);
      } else {
        pulled = openCard(rng);
      }

      addCard(inventory, pulled);

      if ((pulled.rarity === 'legendary' || pulled.rarity === 'mythic')) {
        if (firstLegendary === null) firstLegendary = pack;
        packsSinceLegendary = 0;
      }
      if (pulled.rarity === 'mythic') {
        if (firstMythic === null) firstMythic = pack;
        packsSinceMythic = 0;
      }
    }

    if (bucket.checkpointCompletion[pack]) {
      const analysis = analyzeInventory(inventory, pack);
      bucket.checkpointCompletion[pack].push(analysis.completionPercent);
      bucket.checkpointMythic[pack].push(analysis.rarityUnique.mythic > 0 ? 1 : 0);
    }
  }

  if (firstLegendary !== null) bucket.firstLegendary.push(firstLegendary);
  if (firstMythic !== null) bucket.firstMythic.push(firstMythic);
}

function summarizePityBucket(bucket) {
  const firstLegendary = [...bucket.firstLegendary].sort((a, b) => a - b);
  const firstMythic = [...bucket.firstMythic].sort((a, b) => a - b);
  return {
    legendary: {
      foundByMaxPercent: round((firstLegendary.length / RUNS) * 100, 2),
      averagePacks: round(average(firstLegendary), 2),
      medianPacks: percentile(firstLegendary, 50),
      p90Packs: percentile(firstLegendary, 90),
    },
    mythic: {
      foundByMaxPercent: round((firstMythic.length / RUNS) * 100, 2),
      averagePacks: round(average(firstMythic), 2),
      medianPacks: percentile(firstMythic, 50),
      p90Packs: percentile(firstMythic, 90),
    },
    checkpoints: Object.fromEntries(CHECKPOINTS.map((pack) => [
      pack,
      {
        averageCompletion: round(average(bucket.checkpointCompletion[pack]), 2),
        mythicChance: round(average(bucket.checkpointMythic[pack]) * 100, 2),
      },
    ])),
  };
}

function formatTable(rows, columns) {
  const header = `| ${columns.map((column) => column.label).join(' | ')} |`;
  const divider = `| ${columns.map((column) => (column.align === 'right' ? '---:' : '---')).join(' | ')} |`;
  const body = rows.map((row) => `| ${columns.map((column) => row[column.key]).join(' | ')} |`);
  return [header, divider, ...body].join('\n');
}

function title(value) {
  return value[0].toUpperCase() + value.slice(1);
}

function printReport(results) {
  console.log('# TCG Duplicate Economy Simulation');
  console.log('');
  console.log(`Runs: ${RUNS.toLocaleString('en-US')}`);
  console.log(`Seed: ${SEED}`);
  console.log(`Baseline: current low-rate production weights, ${PACK_PRICE} coins/pack, ${PACK_SIZE} cards/pack`);
  console.log('');

  console.log('## Coin Sell Models');
  for (const model of SELL_MODELS) {
    console.log('');
    console.log(`### ${model.label}`);
    console.log('');
    console.log(formatTable(
      results.checkpoints.map((checkpoint) => {
        const item = checkpoint.sell[model.key];
        return {
          packs: checkpoint.packs,
          refund: item.averageRefund,
          refundPack: item.refundPerPack,
          effective: item.effectivePackCost,
          extra: item.extraPacksEnabled,
          p50: item.p50Refund,
          p90: item.p90Refund,
        };
      }),
      [
        { key: 'packs', label: 'Packs', align: 'right' },
        { key: 'refund', label: 'Avg refund', align: 'right' },
        { key: 'refundPack', label: 'Refund/pack', align: 'right' },
        { key: 'effective', label: 'Effective pack cost', align: 'right' },
        { key: 'extra', label: 'Extra packs enabled', align: 'right' },
        { key: 'p50', label: 'p50 refund', align: 'right' },
        { key: 'p90', label: 'p90 refund', align: 'right' },
      ]
    ));
  }

  console.log('');
  console.log('## Dust / Crafting Models');
  for (const model of DUST_MODELS) {
    console.log('');
    console.log(`### ${model.label}`);
    console.log('');
    console.log(formatTable(
      results.checkpoints.map((checkpoint) => {
        const item = checkpoint.dust[model.key];
        return {
          packs: checkpoint.packs,
          dust: item.averageDust,
          p50: item.p50Dust,
          p90: item.p90Dust,
          common: `${item.craftableChance.common}%`,
          uncommon: `${item.craftableChance.uncommon}%`,
          rare: `${item.craftableChance.rare}%`,
          epic: `${item.craftableChance.epic}%`,
          legendary: `${item.craftableChance.legendary}%`,
          mythic: `${item.craftableChance.mythic}%`,
        };
      }),
      [
        { key: 'packs', label: 'Packs', align: 'right' },
        { key: 'dust', label: 'Avg dust', align: 'right' },
        { key: 'p50', label: 'p50 dust', align: 'right' },
        { key: 'p90', label: 'p90 dust', align: 'right' },
        { key: 'common', label: 'Can craft Common', align: 'right' },
        { key: 'uncommon', label: 'Can craft Uncommon', align: 'right' },
        { key: 'rare', label: 'Can craft Rare', align: 'right' },
        { key: 'epic', label: 'Can craft Epic', align: 'right' },
        { key: 'legendary', label: 'Can craft Legendary', align: 'right' },
        { key: 'mythic', label: 'Can craft Mythic', align: 'right' },
      ]
    ));
  }

  console.log('');
  console.log('## Soft Pity Timing');
  console.log('');
  console.log(formatTable(
    ['baseline', 'softPity'].map((key) => ({
      model: key === 'baseline' ? 'No pity' : 'Soft pity',
      legendaryAvg: results.pity[key].legendary.averagePacks,
      legendaryMedian: results.pity[key].legendary.medianPacks,
      legendaryP90: results.pity[key].legendary.p90Packs,
      mythicAvg: results.pity[key].mythic.averagePacks,
      mythicMedian: results.pity[key].mythic.medianPacks,
      mythicP90: results.pity[key].mythic.p90Packs,
      mythicFound: `${results.pity[key].mythic.foundByMaxPercent}%`,
    })),
    [
      { key: 'model', label: 'Model' },
      { key: 'legendaryAvg', label: 'Avg first Legendary', align: 'right' },
      { key: 'legendaryMedian', label: 'Median first Legendary', align: 'right' },
      { key: 'legendaryP90', label: 'p90 first Legendary', align: 'right' },
      { key: 'mythicAvg', label: 'Avg first Mythic', align: 'right' },
      { key: 'mythicMedian', label: 'Median first Mythic', align: 'right' },
      { key: 'mythicP90', label: 'p90 first Mythic', align: 'right' },
      { key: 'mythicFound', label: 'Found Mythic by 200 packs', align: 'right' },
    ]
  ));
  console.log('');
  console.log(formatTable(
    CHECKPOINTS.map((pack) => ({
      packs: pack,
      baseCompletion: `${results.pity.baseline.checkpoints[pack].averageCompletion}%`,
      pityCompletion: `${results.pity.softPity.checkpoints[pack].averageCompletion}%`,
      baseMythic: `${results.pity.baseline.checkpoints[pack].mythicChance}%`,
      pityMythic: `${results.pity.softPity.checkpoints[pack].mythicChance}%`,
    })),
    [
      { key: 'packs', label: 'Packs', align: 'right' },
      { key: 'baseCompletion', label: 'No pity completion', align: 'right' },
      { key: 'pityCompletion', label: 'Soft pity completion', align: 'right' },
      { key: 'baseMythic', label: 'No pity Mythic', align: 'right' },
      { key: 'pityMythic', label: 'Soft pity Mythic', align: 'right' },
    ]
  ));

  console.log('');
  console.log('## Baseline Pain Reference');
  console.log('');
  console.log(formatTable(
    results.checkpoints.map((checkpoint) => ({
      packs: checkpoint.packs,
      completion: `${checkpoint.baseline.averageCompletion}%`,
      duplicates: checkpoint.baseline.averageDuplicates,
      duplicateRate: `${checkpoint.baseline.averageDuplicateRate}%`,
      legendary: `${checkpoint.baseline.chanceLegendary}%`,
      mythic: `${checkpoint.baseline.chanceMythic}%`,
    })),
    [
      { key: 'packs', label: 'Packs', align: 'right' },
      { key: 'completion', label: 'Completion', align: 'right' },
      { key: 'duplicates', label: 'Duplicates', align: 'right' },
      { key: 'duplicateRate', label: 'Duplicate rate', align: 'right' },
      { key: 'legendary', label: 'Own Legendary', align: 'right' },
      { key: 'mythic', label: 'Own Mythic', align: 'right' },
    ]
  ));

  console.log('');
  console.log('## Recommended Read');
  console.log('');
  console.log('- Coin sell helps feel, but generous coin refunds risk turning duplicates into too many extra packs.');
  console.log('- Balanced dust creates useful medium-term progress without directly refunding the pack economy.');
  console.log('- Soft pity mainly protects extreme long-tail Legendary/Mythic luck without making early packs much faster.');
  console.log('- Recommended next design: balanced dust/crafting plus soft pity guardrails; keep low drop rates unchanged.');
}

const results = {
  checkpoints: simulateBaselineEconomy(),
  pity: simulateSoftPity(),
};

printReport(results);
