import { supabase } from '../config/supabaseClient.js';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';

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

function normalizeRankingCosmetic(row, type) {
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

export function canViewCp({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('view_cp');
}

export function canUpdateCp({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('update_cp');
}

export function isValidCpInput(value) {
  return /^\d+$/.test(value.trim());
}

export function formatCpValue(value) {
  return value === null || value === undefined ? 'Not entered' : value.toLocaleString();
}

export async function loadCpGuildOptions() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('guilds')
    .select('id, name, slug, status, is_core')
    .eq('status', 'active')
    .order('name', { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadCurrentCpRoster({ guildId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_current_cp_roster', {
    p_guild_id: guildId,
  });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadAdminCpRankings({ guildId = null, scope = 'guild' }) {
  const normalizedScope = scope === 'global' ? 'global' : 'guild';
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_cp_rankings', {
    p_guild_id: normalizedScope === 'guild' ? guildId : null,
    p_scope: normalizedScope,
  });

  if (error) {
    throw error;
  }

  return (data ?? []).map((row) => ({
    rank: Number(row.rank),
    profileId: row.profile_id,
    username: row.username,
    ign: row.ign,
    guildId: row.guild_id,
    guildName: row.guild_name,
    guildSlug: row.guild_slug,
    cpValue: row.cp_value,
    updatedAt: row.updated_at,
    avatar: normalizeRankingCosmetic(row, 'avatar'),
    frame: normalizeRankingCosmetic(row, 'frame'),
  }));
}

export async function updateMemberCp({ profileId, cpValue }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_member_cp', {
    p_profile_id: profileId,
    p_cp_value: cpValue,
    p_note: null,
  });

  if (error) {
    throw error;
  }

  return data;
}
