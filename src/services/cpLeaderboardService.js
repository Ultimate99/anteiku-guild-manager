import { supabase } from '../config/supabaseClient.js';

const VALID_SCOPES = new Set(['guild', 'global']);
const FORBIDDEN_MEMBER_FIELDS = [
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
];
const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

export function normalizeLeaderboardScope(scope) {
  return VALID_SCOPES.has(scope) ? scope : 'guild';
}

function assertMemberSafeRows(rows) {
  const unsafeField = rows
    .flatMap((row) => Object.keys(row ?? {}))
    .find((key) => FORBIDDEN_MEMBER_FIELDS.some((forbidden) => key.toLowerCase().includes(forbidden)));

  if (unsafeField) {
    throw new Error(`Unexpected private CP field returned: ${unsafeField}`);
  }
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function normalizeCosmeticAssetPath(value, type) {
  const assetPath = safeString(value);
  const expectedPrefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!assetPath.startsWith(expectedPrefix) || assetPath.includes('..')) {
    return '';
  }

  return assetPath;
}

function normalizeLeaderboardCosmetic(row, type) {
  const key = safeString(row?.[`${type}_key`]);
  const assetPath = normalizeCosmeticAssetPath(row?.[`${type}_asset_path`], type);

  if (!key || !assetPath) {
    return null;
  }

  return {
    key,
    assetPath,
  };
}

export async function loadMemberCpRankings(scope = 'guild') {
  const normalizedScope = normalizeLeaderboardScope(scope);
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_member_cp_rankings', {
    p_scope: normalizedScope,
  });

  if (error) {
    throw error;
  }

  const rows = Array.isArray(data) ? data : [];
  assertMemberSafeRows(rows);

  return rows.map((row) => ({
    rank: Number(row.rank),
    ign: row.ign,
    profileSlug: safeString(row.profile_slug),
    guildName: row.guild_name ?? null,
    guildSlug: row.guild_slug ?? null,
    isCurrentUser: Boolean(row.is_current_user),
    avatar: normalizeLeaderboardCosmetic(row, 'avatar'),
    frame: normalizeLeaderboardCosmetic(row, 'frame'),
  }));
}
