import { supabase } from '../config/supabaseClient.js';

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
const VALID_RARITIES = new Set(['common', 'rare', 'epic', 'legendary']);
const VALID_UNLOCK_TYPES = new Set(['free', 'manual', 'admin_grant', 'rank', 'event', 'gvg', 'founder']);

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeNumber(value) {
  const numericValue = Number(value);
  return Number.isFinite(numericValue) ? numericValue : 0;
}

function normalizeAssetPath(value, type) {
  const path = safeString(value);
  const expectedPrefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(expectedPrefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function normalizeCosmetic(row, type) {
  const key = safeString(row?.key);
  const assetPath = normalizeAssetPath(row?.asset_path, type);

  if (!key || !assetPath) {
    return null;
  }

  const rarity = safeString(row?.rarity);
  const unlockType = safeString(row?.unlock_type);

  return {
    key,
    labelKey: safeString(row?.label_key),
    assetPath,
    rarity: VALID_RARITIES.has(rarity) ? rarity : 'common',
    sortOrder: safeNumber(row?.sort_order),
    unlockType: VALID_UNLOCK_TYPES.has(unlockType) ? unlockType : 'manual',
    isUnlocked: Boolean(row?.is_unlocked),
    isEquipped: Boolean(row?.is_equipped),
  };
}

function normalizeCosmeticList(rows, type) {
  if (!Array.isArray(rows)) {
    return [];
  }

  return rows.map((row) => normalizeCosmetic(row, type)).filter(Boolean);
}

export function formatCosmeticLabel(item, fallbackType = 'Cosmetic') {
  const key = safeString(item?.key);

  if (!key) {
    return fallbackType;
  }

  return key
    .replace(/^TXK_/, '')
    .replace(/_FREE$/i, '')
    .replace(/_lock$/i, '')
    .replace(/_head$/i, '')
    .replaceAll('_', ' ')
    .replace(/\b\w/g, (letter) => letter.toUpperCase());
}

export async function loadMyCosmetics() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_cosmetics');

  if (error) {
    throw error;
  }

  const avatars = normalizeCosmeticList(data?.avatars, 'avatar');
  const frames = normalizeCosmeticList(data?.frames, 'frame');
  const equippedAvatarKey = safeString(data?.equipped?.avatar_key);
  const equippedFrameKey = safeString(data?.equipped?.frame_key);

  return {
    equipped: {
      avatarKey: equippedAvatarKey,
      frameKey: equippedFrameKey,
    },
    avatars: avatars.map((avatar) => ({
      ...avatar,
      isEquipped: avatar.key === equippedAvatarKey || avatar.isEquipped,
    })),
    frames: frames.map((frame) => ({
      ...frame,
      isEquipped: frame.key === equippedFrameKey || frame.isEquipped,
    })),
  };
}

export async function equipMyAvatar(avatarKey) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('equip_my_avatar', {
    p_avatar_key: avatarKey,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function equipMyFrame(frameKey) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('equip_my_frame', {
    p_frame_key: frameKey,
  });

  if (error) {
    throw error;
  }

  return data;
}
