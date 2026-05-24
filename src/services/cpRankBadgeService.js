import { supabase } from '../config/supabaseClient.js';

const FORBIDDEN_RANK_SUMMARY_FIELDS = [
  'cp_value',
  'old_cp',
  'cp_old',
  'cp_new',
  'growth',
  'updated_at',
  'updated_by',
  'profile_id',
  'username',
  'snapshot',
  'metadata',
  'ign',
];

const VALID_TIER_KEYS = new Set([
  'rank_one',
  'rank_two',
  'rank_three',
  'elite_five',
  'top_ten',
  'high_rank',
  'ranked_member',
  'unranked',
]);

const VALID_VISUAL_KEYS = new Set([
  'rank_1',
  'rank_2',
  'rank_3',
  'elite_5',
  'top_10',
  'high_rank',
  'ranked_member',
  'unranked',
]);

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function firstRow(data) {
  return Array.isArray(data) ? data[0] ?? null : data ?? null;
}

function toOptionalNumber(value) {
  if (value === null || value === undefined) {
    return null;
  }

  const numericValue = Number(value);
  return Number.isFinite(numericValue) ? numericValue : null;
}

function assertSafeRankSummary(row) {
  const unsafeField = Object.keys(row ?? {}).find((key) =>
    FORBIDDEN_RANK_SUMMARY_FIELDS.some((forbidden) => key.toLowerCase().includes(forbidden)),
  );

  if (unsafeField) {
    throw new Error(`Unexpected private CP field returned: ${unsafeField}`);
  }
}

function normalizeTierKey(value) {
  return VALID_TIER_KEYS.has(value) ? value : 'unranked';
}

function normalizeVisualKey(value, tierKey) {
  if (VALID_VISUAL_KEYS.has(value)) {
    return value;
  }

  if (tierKey === 'rank_one') {
    return 'rank_1';
  }

  if (tierKey === 'rank_two') {
    return 'rank_2';
  }

  if (tierKey === 'rank_three') {
    return 'rank_3';
  }

  if (tierKey === 'elite_five') {
    return 'elite_5';
  }

  if (tierKey === 'top_ten') {
    return 'top_10';
  }

  return VALID_VISUAL_KEYS.has(tierKey) ? tierKey : 'unranked';
}

export function createUnrankedSummary() {
  return {
    globalRank: null,
    guildRank: null,
    rankTier: 'unranked',
    visualKey: 'unranked',
    isRanked: false,
  };
}

export async function loadMyCpRankSummary() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_cp_rank_summary');

  if (error) {
    throw error;
  }

  const row = firstRow(data);

  if (!row) {
    return createUnrankedSummary();
  }

  assertSafeRankSummary(row);

  const rankTier = normalizeTierKey(row.rank_tier);
  const visualKey = normalizeVisualKey(row.visual_key, rankTier);
  const globalRank = toOptionalNumber(row.global_rank);
  const guildRank = toOptionalNumber(row.guild_rank);
  const isRanked = Boolean(row.is_ranked) && globalRank !== null;

  return {
    globalRank,
    guildRank,
    rankTier: isRanked ? rankTier : 'unranked',
    visualKey: isRanked ? visualKey : 'unranked',
    isRanked,
  };
}
