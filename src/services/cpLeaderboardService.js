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
    guildName: row.guild_name ?? null,
    guildSlug: row.guild_slug ?? null,
    isCurrentUser: Boolean(row.is_current_user),
  }));
}
