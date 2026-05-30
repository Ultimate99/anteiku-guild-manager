import { supabase } from '../config/supabaseClient.js';

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
const FORBIDDEN_PUBLIC_PROFILE_FIELDS = [
  'member_cp',
  'cp_snapshots',
  'cp_value',
  'email',
  'auth',
  'admin_permissions',
  'audit',
  'permission_key',
  'private',
];

export const PROFILE_REACTION_TYPES = ['like', 'fire', 'coffee', 'skull', 'trophy'];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeNullableNumber(value) {
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const nextValue = Number(value);
  return Number.isFinite(nextValue) ? nextValue : null;
}

function safeNumber(value) {
  const nextValue = safeNullableNumber(value);
  return nextValue === null ? 0 : nextValue;
}

function safeBoolean(value) {
  return Boolean(value);
}

function safeAssetPath(value, type) {
  const path = safeString(value);
  const prefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(prefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function assertNoPrivatePublicProfileFields(payload) {
  const stack = [payload];

  while (stack.length > 0) {
    const current = stack.pop();

    if (!current || typeof current !== 'object') {
      continue;
    }

    for (const [key, value] of Object.entries(current)) {
      const loweredKey = key.toLowerCase();
      const forbidden = FORBIDDEN_PUBLIC_PROFILE_FIELDS.find((field) => loweredKey.includes(field));

      if (forbidden) {
        throw new Error(`Unexpected private public-profile field returned: ${forbidden}`);
      }

      if (value && typeof value === 'object') {
        stack.push(value);
      }
    }
  }
}

function mapCosmetics(row) {
  return {
    avatar: {
      key: safeString(row?.avatar_key),
      assetPath: safeAssetPath(row?.avatar_asset_path, 'avatar'),
    },
    frame: {
      key: safeString(row?.frame_key),
      assetPath: safeAssetPath(row?.frame_asset_path, 'frame'),
    },
  };
}

function mapReaction(row) {
  const type = safeString(row?.type);

  return {
    type: PROFILE_REACTION_TYPES.includes(type) ? type : '',
    count: safeNumber(row?.count),
    reactedByMe: safeBoolean(row?.reacted_by_me),
  };
}

function mapReactionDetail(row) {
  const type = safeString(row?.reaction_type);

  return {
    username: safeString(row?.username),
    profileSlug: safeString(row?.profile_slug),
    ign: safeString(row?.ign),
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    reactionType: PROFILE_REACTION_TYPES.includes(type) ? type : '',
    reactedAt: row?.reacted_at || null,
    ...mapCosmetics(row),
  };
}

function mapProfile(row) {
  return {
    profileId: row?.profile_id || null,
    username: safeString(row?.username),
    profileSlug: safeString(row?.profile_slug),
    ign: safeString(row?.ign),
    guildId: row?.guild_id || null,
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    roleLabel: safeString(row?.role_label),
    rosterStatus: safeString(row?.roster_status),
    ghoulRep: safeNullableNumber(row?.ghoul_rep),
    threeVThreeCombinedCp: safeNullableNumber(row?.three_v_three_combined_cp),
    reactions: Array.isArray(row?.reactions) ? row.reactions.map(mapReaction).filter((reaction) => reaction.type) : [],
    ...mapCosmetics(row),
  };
}

function mapViewer(row) {
  return {
    isSelf: safeBoolean(row?.is_self),
    canReact: safeBoolean(row?.can_react),
  };
}

export function getProfileReactionCount(reactions, type) {
  return reactions.find((reaction) => reaction.type === type)?.count ?? 0;
}

export function hasMyProfileReaction(reactions, type) {
  return Boolean(reactions.find((reaction) => reaction.type === type)?.reactedByMe);
}

export async function loadPublicMemberProfile(profileSlug) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_public_member_profile', {
    p_profile_slug: profileSlug,
  });

  if (error) {
    throw error;
  }

  assertNoPrivatePublicProfileFields(data);

  return {
    viewer: mapViewer(data?.viewer),
    profile: mapProfile(data?.profile),
  };
}

export async function reactToPublicProfile({ targetProfileId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('react_to_public_profile', {
    p_target_profile_id: targetProfileId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  assertNoPrivatePublicProfileFields(data);
  return data;
}

export async function removePublicProfileReaction({ targetProfileId, reactionType }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('remove_public_profile_reaction', {
    p_target_profile_id: targetProfileId,
    p_reaction_type: reactionType,
  });

  if (error) {
    throw error;
  }

  assertNoPrivatePublicProfileFields(data);
  return data;
}

export async function loadPublicProfileReactionDetails({ targetProfileId, reactionType = null }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_public_profile_reaction_details', {
    p_target_profile_id: targetProfileId,
    p_reaction_type: reactionType || null,
  });

  if (error) {
    throw error;
  }

  assertNoPrivatePublicProfileFields(data);

  const type = safeString(data?.reaction_type);

  return {
    reactionType: PROFILE_REACTION_TYPES.includes(type) ? type : '',
    reactions: Array.isArray(data?.reactions)
      ? data.reactions.map(mapReactionDetail).filter((reaction) => reaction.reactionType)
      : [],
  };
}
