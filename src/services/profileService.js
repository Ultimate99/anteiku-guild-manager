import { supabase } from '../config/supabaseClient.js';

const SAFE_PROFILE_FIELDS =
  'id, username, profile_slug, ign, avatar_key, approval_status, reapply_requested_at, created_at, updated_at';
const SAFE_MEMBERSHIP_FIELDS = 'id, guild_id, role, membership_status, roster_status, is_primary';
const SAFE_GUILD_FIELDS = 'id, name, slug';
const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
const FORBIDDEN_ACTIVE_PROFILE_FIELDS = [
  'member_cp',
  'cp_snapshots',
  'cp_value',
  'current_cp',
  'combined_cp',
  'email',
  'auth',
  'admin_permissions',
  'audit',
  'permission_key',
  'private',
];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeAssetPath(value, type) {
  const path = safeString(value);
  const prefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(prefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function assertNoPrivateActiveProfileFields(payload) {
  const stack = [payload];

  while (stack.length > 0) {
    const current = stack.pop();

    if (!current || typeof current !== 'object') {
      continue;
    }

    for (const [key, value] of Object.entries(current)) {
      const loweredKey = key.toLowerCase();
      const forbidden = FORBIDDEN_ACTIVE_PROFILE_FIELDS.find((field) => loweredKey.includes(field));

      if (forbidden) {
        throw new Error(`Unexpected private active-profile field returned: ${forbidden}`);
      }

      if (value && typeof value === 'object') {
        stack.push(value);
      }
    }
  }
}

function mapActiveProfile(row) {
  return {
    profileId: row?.profile_id || null,
    username: safeString(row?.username),
    profileSlug: safeString(row?.profile_slug),
    ign: safeString(row?.ign),
    approvalStatus: safeString(row?.approval_status),
    guildId: row?.guild_id || null,
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    role: safeString(row?.role),
    roleLabel: safeString(row?.role_label),
    membershipStatus: safeString(row?.membership_status),
    rosterStatus: safeString(row?.roster_status),
    avatar: {
      key: safeString(row?.avatar_key),
      assetPath: safeAssetPath(row?.avatar_asset_path, 'avatar'),
    },
    frame: {
      key: safeString(row?.frame_key),
      assetPath: safeAssetPath(row?.frame_asset_path, 'frame'),
    },
    isActiveProfile: Boolean(row?.is_active_profile),
    isPrimary: Boolean(row?.is_primary),
  };
}

export async function registerProfile({ username, ign, requestedGuildId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('register_profile', {
    p_username: username,
    p_ign: ign,
    p_requested_guild_id: requestedGuildId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function updateMyProfile({ ign, avatarKey }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_my_profile', {
    p_ign: ign,
    p_avatar_key: avatarKey ?? null,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function loadMyActiveProfileDetails() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_active_profile_details');

  if (error) {
    throw error;
  }

  assertNoPrivateActiveProfileFields(data);

  return mapActiveProfile(data?.profile);
}

export async function updateMyActiveProfile({ ign }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_my_active_profile', {
    p_ign: ign,
  });

  if (error) {
    throw error;
  }

  assertNoPrivateActiveProfileFields(data);

  return mapActiveProfile(data?.profile);
}

export async function loadMyGhoulRep() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_ghoul_rep');

  if (error) {
    throw error;
  }

  const ghoulRep = Number(Array.isArray(data) ? data[0] : data);
  return Number.isFinite(ghoulRep) ? ghoulRep : 0;
}

export async function getOwnProfile(userId) {
  const client = requireSupabase();
  const { data, error } = await client
    .from('profiles')
    .select(SAFE_PROFILE_FIELDS)
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

export async function getOwnPrimaryMembership(userId) {
  const client = requireSupabase();
  const { data, error } = await client
    .from('guild_memberships')
    .select(SAFE_MEMBERSHIP_FIELDS)
    .eq('profile_id', userId)
    .eq('is_primary', true)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

export async function getGuildDisplay(guildId) {
  if (!guildId) {
    return null;
  }

  const client = requireSupabase();
  const { data, error } = await client
    .from('guilds')
    .select(SAFE_GUILD_FIELDS)
    .eq('id', guildId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data;
}

export async function loadSafeViewerState(userId) {
  const profile = await getOwnProfile(userId);

  if (!profile) {
    return {
      profile: null,
      membership: null,
      guild: null,
    };
  }

  const membership = await getOwnPrimaryMembership(userId);
  const guild = await getGuildDisplay(membership?.guild_id);

  return {
    profile,
    membership,
    guild,
  };
}
