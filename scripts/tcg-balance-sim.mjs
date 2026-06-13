const RUNS = 10000;
const SEED = 300702;
const PACK_SIZE = 5;
const PACK_PRICE = 100;
const CHECKPOINTS = [20, 40, 60, 100];
const EARLY_EPIC_PACKS = [5, 10, 20];
const MAX_PACKS_FOR_TARGETS = 300;
const COIN_INCOME_OPTIONS = [400, 500, 550];

const CATALOG_DISTRIBUTION = [
  { key: 'common', label: 'Common', catalogCount: 18 },
  { key: 'uncommon', label: 'Uncommon', catalogCount: 14 },
  { key: 'rare', label: 'Rare', catalogCount: 9 },
  { key: 'epic', label: 'Epic', catalogCount: 5 },
  { key: 'legendary', label: 'Legendary', catalogCount: 3 },
  { key: 'mythic', label: 'Mythic', catalogCount: 1 },
];

const MODELS = [
  {
    key: 'current',
    name: 'Current baseline',
    weights: {
      common: 6000,
      uncommon: 2500,
      rare: 1000,
      epic: 400,
      legendary: 90,
      mythic: 10,
    },
  },
  {
    key: 'candidateA',
    name: 'Candidate A - slightly harder Epic',
    weights: {
      common: 6200,
      uncommon: 2500,
      rare: 900,
      epic: 300,
      legendary: 90,
      mythic: 10,
    },
  },
  {
    key: 'candidateB',
    name: 'Candidate B - stronger Epic nerf',
    weights: {
      common: 6300,
      uncommon: 2500,
      rare: 850,
      epic: 250,
      legendary: 90,
      mythic: 10,
    },
  },
];

const TOTAL_CARDS = CATALOG_DISTRIBUTION.reduce((sum, rarity) => sum + rarity.catalogCount, 0);

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

function buildRarities(model) {
  return CATALOG_DISTRIBUTION.map((rarity) => ({
    ...rarity,
    weight: model.weights[rarity.key],
  }));
}

function buildCatalog(rarities) {
  const cards = [];

  for (const rarity of rarities) {
    for (let index = 0; index < rarity.catalogCount; index += 1) {
      cards.push({
        id: `${rarity.key}_${index + 1}`,
        rarity: rarity.key,
      });
    }
  }

  return cards;
}

function average(values) {
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

function percentile(values, percentileValue) {
  if (values.length === 0) return 0;
  const index = Math.ceil((percentileValue / 100) * values.length) - 1;
  return values[Math.max(0, Math.min(values.length - 1, index))];
}

function round(value, decimals = 2) {
  const factor = 10 ** decimals;
  return Math.round(value * factor) / factor;
}

function makeEmptyCheckpoint(rarities) {
  return {
    uniqueTotals: [],
    completionPercents: [],
    duplicateTotals: [],
    duplicateRates: [],
    rarityUniqueTotals: Object.fromEntries(rarities.map((rarity) => [rarity.key, []])),
    rarityQuantityTotals: Object.fromEntries(rarities.map((rarity) => [rarity.key, []])),
  };
}

function chooseRarity(rng, rarities, totalWeight) {
  const roll = rng() * totalWeight;
  let cumulative = 0;

  for (const rarity of rarities) {
    cumulative += rarity.weight;

    if (roll < cumulative) {
      return rarity;
    }
  }

  return rarities[rarities.length - 1];
}

function openCard(rng, rarities, totalWeight, cardsByRarity) {
  const rarity = chooseRarity(rng, rarities, totalWeight);
  const pool = cardsByRarity.get(rarity.key);
  return pool[Math.floor(rng() * pool.length)];
}

function summarizeCheckpoint(checkpoint, packs, rarities) {
  const uniqueSorted = [...checkpoint.uniqueTotals].sort((a, b) => a - b);
  const completionSorted = [...checkpoint.completionPercents].sort((a, b) => a - b);
  const duplicatesSorted = [...checkpoint.duplicateTotals].sort((a, b) => a - b);

  return {
    packs,
    cardsPulled: packs * PACK_SIZE,
    averageUnique: round(average(checkpoint.uniqueTotals), 2),
    averageCompletionPercent: round(average(checkpoint.completionPercents), 2),
    averageMissingCards: round(TOTAL_CARDS - average(checkpoint.uniqueTotals), 2),
    averageDuplicates: round(average(checkpoint.duplicateTotals), 2),
    averageDuplicateRate: round(average(checkpoint.duplicateRates), 2),
    completionP10: round(percentile(completionSorted, 10), 2),
    completionP50: round(percentile(completionSorted, 50), 2),
    completionP90: round(percentile(completionSorted, 90), 2),
    duplicateP10: percentile(duplicatesSorted, 10),
    duplicateP50: percentile(duplicatesSorted, 50),
    duplicateP90: percentile(duplicatesSorted, 90),
    rarityUniqueAverages: Object.fromEntries(
      rarities.map((rarity) => [rarity.key, round(average(checkpoint.rarityUniqueTotals[rarity.key]), 2)]),
    ),
    rarityQuantityAverages: Object.fromEntries(
      rarities.map((rarity) => [rarity.key, round(average(checkpoint.rarityQuantityTotals[rarity.key]), 2)]),
    ),
    rarityCompletion: Object.fromEntries(
      rarities.map((rarity) => [
        rarity.key,
        round((average(checkpoint.rarityUniqueTotals[rarity.key]) / rarity.catalogCount) * 100, 2),
      ]),
    ),
  };
}

function summarizeFirstPullTiming(rarities) {
  const totalWeight = rarities.reduce((sum, rarity) => sum + rarity.weight, 0);
  const timing = {};

  for (const rarityKey of ['epic', 'legendary', 'mythic']) {
    const rarity = rarities.find((item) => item.key === rarityKey);
    const perCardChance = rarity.weight / totalWeight;
    const packChance = 1 - (1 - perCardChance) ** PACK_SIZE;

    timing[rarityKey] = {
      perCardChance: round(perCardChance * 100, 2),
      chancePerPack: round(packChance * 100, 2),
      expectedPacks: round(1 / packChance, 2),
      medianPacks: Math.ceil(Math.log(0.5) / Math.log(1 - packChance)),
      chanceBy5Packs: round((1 - (1 - packChance) ** 5) * 100, 2),
      chanceBy10Packs: round((1 - (1 - packChance) ** 10) * 100, 2),
      chanceBy20Packs: round((1 - (1 - packChance) ** 20) * 100, 2),
      chanceBy40Packs: round((1 - (1 - packChance) ** 40) * 100, 2),
      chanceBy60Packs: round((1 - (1 - packChance) ** 60) * 100, 2),
      chanceBy100Packs: round((1 - (1 - packChance) ** 100) * 100, 2),
    };
  }

  return timing;
}

function summarizeCoinPacing(targetSummaries, firstPullTiming) {
  return COIN_INCOME_OPTIONS.map((coinsPerWeek) => {
    const packsPerWeek = coinsPerWeek / PACK_PRICE;

    return {
      coinsPerWeek,
      packsPerWeek,
      weeksTo90PercentAverage: round(targetSummaries['90'].averagePacks / packsPerWeek, 2),
      weeksTo90PercentP50: round(targetSummaries['90'].p50Packs / packsPerWeek, 2),
      weeksTo90PercentP90: round(targetSummaries['90'].p90Packs / packsPerWeek, 2),
      weeksToFirstEpicExpected: round(firstPullTiming.epic.expectedPacks / packsPerWeek, 2),
      weeksToFirstLegendaryExpected: round(firstPullTiming.legendary.expectedPacks / packsPerWeek, 2),
      weeksToFirstMythicExpected: round(firstPullTiming.mythic.expectedPacks / packsPerWeek, 2),
    };
  });
}

function simulateModel(model, modelIndex) {
  const rarities = buildRarities(model);
  const totalWeight = rarities.reduce((sum, rarity) => sum + rarity.weight, 0);
  const catalog = buildCatalog(rarities);
  const cardsByRarity = new Map(
    rarities.map((rarity) => [rarity.key, catalog.filter((card) => card.rarity === rarity.key)]),
  );
  const rng = createRng(SEED + modelIndex * 100003);
  const checkpoints = new Map(CHECKPOINTS.map((packs) => [packs, makeEmptyCheckpoint(rarities)]));
  const targetPacks = { 50: [], 75: [], 90: [] };

  for (let run = 0; run < RUNS; run += 1) {
    const inventory = new Map();
    const firstHitByTarget = { 50: null, 75: null, 90: null };

    for (let pack = 1; pack <= MAX_PACKS_FOR_TARGETS; pack += 1) {
      for (let card = 0; card < PACK_SIZE; card += 1) {
        const pulled = openCard(rng, rarities, totalWeight, cardsByRarity);
        inventory.set(pulled.id, (inventory.get(pulled.id) ?? 0) + 1);
      }

      const uniqueCount = inventory.size;
      const completion = (uniqueCount / TOTAL_CARDS) * 100;

      for (const target of Object.keys(firstHitByTarget)) {
        if (firstHitByTarget[target] === null && completion >= Number(target)) {
          firstHitByTarget[target] = pack;
        }
      }

      if (checkpoints.has(pack)) {
        const checkpoint = checkpoints.get(pack);
        const totalPulled = pack * PACK_SIZE;
        const duplicates = totalPulled - uniqueCount;
        const rarityUnique = Object.fromEntries(rarities.map((rarity) => [rarity.key, 0]));
        const rarityQuantity = Object.fromEntries(rarities.map((rarity) => [rarity.key, 0]));

        for (const [cardId, quantity] of inventory.entries()) {
          const cardRarity = cardId.split('_')[0];
          rarityUnique[cardRarity] += 1;
          rarityQuantity[cardRarity] += quantity;
        }

        checkpoint.uniqueTotals.push(uniqueCount);
        checkpoint.completionPercents.push(completion);
        checkpoint.duplicateTotals.push(duplicates);
        checkpoint.duplicateRates.push((duplicates / totalPulled) * 100);

        for (const rarity of rarities) {
          checkpoint.rarityUniqueTotals[rarity.key].push(rarityUnique[rarity.key]);
          checkpoint.rarityQuantityTotals[rarity.key].push(rarityQuantity[rarity.key]);
        }
      }
    }

    for (const target of Object.keys(firstHitByTarget)) {
      if (firstHitByTarget[target] !== null) {
        targetPacks[target].push(firstHitByTarget[target]);
      }
    }
  }

  const checkpointSummaries = CHECKPOINTS.map((packs) => summarizeCheckpoint(checkpoints.get(packs), packs, rarities));
  const targetSummaries = Object.fromEntries(
    Object.entries(targetPacks).map(([target, packs]) => {
      const sorted = packs.sort((a, b) => a - b);

      return [
        target,
        {
          reachedByMaxPacksPercent: round((packs.length / RUNS) * 100, 2),
          averagePacks: round(average(packs), 2),
          p50Packs: percentile(sorted, 50),
          p90Packs: percentile(sorted, 90),
        },
      ];
    }),
  );
  const firstPullTiming = summarizeFirstPullTiming(rarities);

  return {
    ...model,
    runs: RUNS,
    seed: SEED + modelIndex * 100003,
    packPrice: PACK_PRICE,
    packSize: PACK_SIZE,
    totalCards: TOTAL_CARDS,
    totalWeight,
    rarities,
    checkpointSummaries,
    targetSummaries,
    firstPullTiming,
    coinPacing: summarizeCoinPacing(targetSummaries, firstPullTiming),
  };
}

function formatTable(rows, columns) {
  const header = `| ${columns.map((column) => column.label).join(' | ')} |`;
  const divider = `| ${columns.map((column) => (column.align === 'right' ? '---:' : '---')).join(' | ')} |`;
  const body = rows.map((row) => `| ${columns.map((column) => row[column.key]).join(' | ')} |`);
  return [header, divider, ...body].join('\n');
}

function labelForRarity(key) {
  return key[0].toUpperCase() + key.slice(1);
}

function printModelWeights(results) {
  console.log('## Model Weights');
  console.log('');
  console.log(formatTable(
    results.map((model) => ({
      model: model.name,
      common: model.weights.common,
      uncommon: model.weights.uncommon,
      rare: model.weights.rare,
      epic: model.weights.epic,
      legendary: model.weights.legendary,
      mythic: model.weights.mythic,
      epicPackChance: `${model.firstPullTiming.epic.chancePerPack}%`,
    })),
    [
      { key: 'model', label: 'Model' },
      { key: 'common', label: 'Common', align: 'right' },
      { key: 'uncommon', label: 'Uncommon', align: 'right' },
      { key: 'rare', label: 'Rare', align: 'right' },
      { key: 'epic', label: 'Epic', align: 'right' },
      { key: 'legendary', label: 'Legendary', align: 'right' },
      { key: 'mythic', label: 'Mythic', align: 'right' },
      { key: 'epicPackChance', label: 'Epic chance / pack', align: 'right' },
    ],
  ));
  console.log('');
}

function printCheckpointComparison(results) {
  console.log('## Checkpoint Comparison');
  console.log('');

  for (const packs of CHECKPOINTS) {
    console.log(`### ${packs} Packs`);
    console.log('');
    console.log(formatTable(
      results.map((model) => {
        const item = model.checkpointSummaries.find((summary) => summary.packs === packs);

        return {
          model: model.name,
          unique: item.averageUnique,
          completion: `${item.averageCompletionPercent}%`,
          duplicates: item.averageDuplicates,
          duplicateRate: `${item.averageDuplicateRate}%`,
          rareUnique: item.rarityUniqueAverages.rare,
          epicUnique: item.rarityUniqueAverages.epic,
          legendaryUnique: item.rarityUniqueAverages.legendary,
          mythicUnique: item.rarityUniqueAverages.mythic,
        };
      }),
      [
        { key: 'model', label: 'Model' },
        { key: 'unique', label: 'Avg unique', align: 'right' },
        { key: 'completion', label: 'Avg completion', align: 'right' },
        { key: 'duplicates', label: 'Avg duplicates', align: 'right' },
        { key: 'duplicateRate', label: 'Avg duplicate rate', align: 'right' },
        { key: 'rareUnique', label: 'Avg Rare unique', align: 'right' },
        { key: 'epicUnique', label: 'Avg Epic unique', align: 'right' },
        { key: 'legendaryUnique', label: 'Avg Legendary unique', align: 'right' },
        { key: 'mythicUnique', label: 'Avg Mythic unique', align: 'right' },
      ],
    ));
    console.log('');
  }
}

function printFirstPullComparison(results) {
  console.log('## First Pull Timing');
  console.log('');
  console.log(formatTable(
    results.flatMap((model) => ['epic', 'legendary', 'mythic'].map((rarityKey) => {
      const item = model.firstPullTiming[rarityKey];

      return {
        model: model.name,
        rarity: labelForRarity(rarityKey),
        chancePerPack: `${item.chancePerPack}%`,
        expectedPacks: item.expectedPacks,
        medianPacks: item.medianPacks,
        chance5: rarityKey === 'epic' ? `${item.chanceBy5Packs}%` : '-',
        chance10: rarityKey === 'epic' ? `${item.chanceBy10Packs}%` : '-',
        chance20: `${item.chanceBy20Packs}%`,
        chance40: `${item.chanceBy40Packs}%`,
        chance60: `${item.chanceBy60Packs}%`,
        chance100: `${item.chanceBy100Packs}%`,
      };
    })),
    [
      { key: 'model', label: 'Model' },
      { key: 'rarity', label: 'Rarity' },
      { key: 'chancePerPack', label: 'Chance / pack', align: 'right' },
      { key: 'expectedPacks', label: 'Expected packs', align: 'right' },
      { key: 'medianPacks', label: 'Median packs', align: 'right' },
      { key: 'chance5', label: 'By 5 packs', align: 'right' },
      { key: 'chance10', label: 'By 10 packs', align: 'right' },
      { key: 'chance20', label: 'By 20 packs', align: 'right' },
      { key: 'chance40', label: 'By 40 packs', align: 'right' },
      { key: 'chance60', label: 'By 60 packs', align: 'right' },
      { key: 'chance100', label: 'By 100 packs', align: 'right' },
    ],
  ));
  console.log('');
}

function printNinetyPercentPacing(results) {
  console.log('## 90% Collection Timing');
  console.log('');
  console.log(formatTable(
    results.flatMap((model) => model.coinPacing.map((item) => ({
      model: model.name,
      coins: item.coinsPerWeek,
      packs: item.packsPerWeek,
      avgWeeks: item.weeksTo90PercentAverage,
      p50Weeks: item.weeksTo90PercentP50,
      p90Weeks: item.weeksTo90PercentP90,
      epicExpectedWeeks: item.weeksToFirstEpicExpected,
      legendaryExpectedWeeks: item.weeksToFirstLegendaryExpected,
      mythicExpectedWeeks: item.weeksToFirstMythicExpected,
    }))),
    [
      { key: 'model', label: 'Model' },
      { key: 'coins', label: 'Coins/week', align: 'right' },
      { key: 'packs', label: 'Packs/week', align: 'right' },
      { key: 'avgWeeks', label: 'Avg weeks to 90%', align: 'right' },
      { key: 'p50Weeks', label: 'P50 weeks to 90%', align: 'right' },
      { key: 'p90Weeks', label: 'P90 weeks to 90%', align: 'right' },
      { key: 'epicExpectedWeeks', label: 'Expected weeks to Epic', align: 'right' },
      { key: 'legendaryExpectedWeeks', label: 'Expected weeks to Legendary', align: 'right' },
      { key: 'mythicExpectedWeeks', label: 'Expected weeks to Mythic', align: 'right' },
    ],
  ));
  console.log('');
}

function printReport(results) {
  console.log('# TCG Balance Simulation - Epic Rate Candidates');
  console.log('');
  console.log(`Runs per model: ${RUNS.toLocaleString('en-US')}`);
  console.log(`Base seed: ${SEED}`);
  console.log(`Pack price: ${PACK_PRICE} Anteiku Coins`);
  console.log(`Pack size: ${PACK_SIZE} cards`);
  console.log(`Catalog size: ${TOTAL_CARDS} cards`);
  console.log('');
  printModelWeights(results);
  printCheckpointComparison(results);
  printFirstPullComparison(results);
  printNinetyPercentPacing(results);
}

const results = MODELS.map(simulateModel);
printReport(results);
