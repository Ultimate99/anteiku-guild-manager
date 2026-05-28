import { supabase } from '../config/supabaseClient.js';

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
const VALID_TEAM_STATUSES = new Set(['open', 'full', 'closed', 'disbanded']);
const VALID_REQUEST_STATUSES = new Set(['pending', 'approved', 'declined', 'cancelled']);

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
  if (value === null || value === undefined || value === '') {
    return null;
  }

  const nextValue = Number(value);
  return Number.isFinite(nextValue) ? nextValue : null;
}

function safeAssetPath(value, type) {
  const path = safeString(value);
  const prefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(prefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function mapCosmeticSlot(row) {
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

function mapSlot(row) {
  const slotNumber = safeNumber(row?.slot_number) ?? 0;

  return {
    slotNumber,
    isEmpty: Boolean(row?.is_empty),
    profileId: row?.profile_id || null,
    username: safeString(row?.username),
    profileSlug: safeString(row?.profile_slug),
    ign: safeString(row?.ign),
    guildId: row?.guild_id || null,
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    discordUsername: safeString(row?.discord_username),
    combinedCp: safeNumber(row?.combined_cp),
    role: safeString(row?.role),
    joinedAt: row?.joined_at || null,
    ...mapCosmeticSlot(row),
  };
}

function mapTeam(row) {
  if (!row) {
    return null;
  }

  const status = safeString(row.status);

  return {
    id: row.id || null,
    name: safeString(row.name),
    status: VALID_TEAM_STATUSES.has(status) ? status : 'closed',
    createdAt: row.created_at || null,
    updatedAt: row.updated_at || null,
    memberCount: safeNumber(row.member_count) ?? 0,
    emptySlots: safeNumber(row.empty_slots) ?? 0,
    isOwner: Boolean(row.is_owner),
    isMember: Boolean(row.is_member),
    alreadyRequested: Boolean(row.already_requested),
    canRequest: Boolean(row.can_request),
    requestBlockReason: safeString(row.request_block_reason),
    slots: Array.isArray(row.slots) ? row.slots.map(mapSlot) : [],
  };
}

function mapProfile(row) {
  return {
    profileId: row?.profile_id || null,
    guildId: row?.guild_id || null,
    rosterStatus: safeString(row?.roster_status),
    canCreateOrRequest: Boolean(row?.can_create_or_request),
    activeTeamId: row?.active_team_id || null,
    ownedTeamId: row?.owned_team_id || null,
    discordUsername: safeString(row?.discord_username),
    combinedCp: safeNumber(row?.combined_cp),
  };
}

function mapOutgoingRequest(row) {
  const status = safeString(row?.status);

  return {
    id: row?.id || null,
    teamId: row?.team_id || null,
    teamName: safeString(row?.team_name),
    teamStatus: safeString(row?.team_status),
    status: VALID_REQUEST_STATUSES.has(status) ? status : 'cancelled',
    attemptNumber: safeNumber(row?.attempt_number) ?? 0,
    combinedCp: safeNumber(row?.combined_cp),
    createdAt: row?.created_at || null,
    updatedAt: row?.updated_at || null,
    decidedAt: row?.decided_at || null,
  };
}

function mapIncomingRequest(row) {
  const status = safeString(row?.status);

  return {
    id: row?.id || null,
    teamId: row?.team_id || null,
    teamName: safeString(row?.team_name),
    status: VALID_REQUEST_STATUSES.has(status) ? status : 'cancelled',
    attemptNumber: safeNumber(row?.attempt_number) ?? 0,
    combinedCp: safeNumber(row?.combined_cp),
    createdAt: row?.created_at || null,
    updatedAt: row?.updated_at || null,
    requesterProfileId: row?.requester_profile_id || null,
    requesterUsername: safeString(row?.requester_username),
    requesterProfileSlug: safeString(row?.requester_profile_slug),
    requesterIgn: safeString(row?.requester_ign),
    requesterDiscordUsername: safeString(row?.requester_discord_username),
    avatar: {
      key: safeString(row?.requester_avatar_key),
      assetPath: safeAssetPath(row?.requester_avatar_asset_path, 'avatar'),
    },
    frame: {
      key: safeString(row?.requester_frame_key),
      assetPath: safeAssetPath(row?.requester_frame_asset_path, 'frame'),
    },
  };
}

function mapStatus(data) {
  return {
    profile: mapProfile(data?.profile),
    currentTeam: mapTeam(data?.current_team),
    ownedTeam: mapTeam(data?.owned_team),
    outgoingRequests: Array.isArray(data?.outgoing_requests)
      ? data.outgoing_requests.map(mapOutgoingRequest)
      : [],
    incomingRequests: Array.isArray(data?.incoming_requests)
      ? data.incoming_requests.map(mapIncomingRequest)
      : [],
  };
}

export function parseCombinedCpInput(value) {
  const normalized = safeString(value).replace(/[,\s]/g, '');

  if (!/^\d+$/.test(normalized)) {
    return null;
  }

  const numericValue = Number(normalized);
  return Number.isSafeInteger(numericValue) && numericValue >= 0 ? numericValue : null;
}

export function formatCombinedCp(value, language = 'en') {
  const numericValue = safeNumber(value);

  if (numericValue === null) {
    return '';
  }

  return new Intl.NumberFormat(language).format(numericValue);
}

export function formatDiscordUsername(value) {
  const username = safeString(value).replace(/^@+/, '');
  return username ? `@${username}` : '';
}

export async function loadTeams() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_3v3_teams');

  if (error) {
    throw error;
  }

  return {
    viewer: mapProfile(data?.viewer),
    teams: Array.isArray(data?.teams) ? data.teams.map(mapTeam).filter(Boolean) : [],
  };
}

export async function loadMy3v3Status() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_3v3_status');

  if (error) {
    throw error;
  }

  return mapStatus(data);
}

export async function updateDiscordUsername(discordUsername) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_my_discord_username', {
    p_discord_username: discordUsername || null,
  });

  if (error) {
    throw error;
  }

  return mapProfile(data);
}

export async function updateCombinedCp(combinedCp) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_my_3v3_combined_cp', {
    p_combined_cp: combinedCp,
  });

  if (error) {
    throw error;
  }

  return mapProfile(data);
}

export async function createTeam({ teamName, combinedCp }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('create_3v3_team', {
    p_team_name: teamName,
    p_combined_cp: combinedCp,
  });

  if (error) {
    throw error;
  }

  return mapTeam(data);
}

export async function requestJoinTeam({ teamId, combinedCp }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('request_join_3v3_team', {
    p_team_id: teamId,
    p_combined_cp: combinedCp,
  });

  if (error) {
    throw error;
  }

  return mapOutgoingRequest(data);
}

export async function cancelRequest(requestId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('cancel_3v3_request', {
    p_request_id: requestId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function approveRequest(requestId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('approve_3v3_request', {
    p_request_id: requestId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function declineRequest(requestId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('decline_3v3_request', {
    p_request_id: requestId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function removeMember({ teamId, profileId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('remove_3v3_member', {
    p_team_id: teamId,
    p_profile_id: profileId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function disbandTeam(teamId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('disband_3v3_team', {
    p_team_id: teamId,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function closeTeam(teamId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('close_3v3_team', {
    p_team_id: teamId,
  });

  if (error) {
    throw error;
  }

  return mapTeam(data);
}

export async function reopenTeam(teamId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('reopen_3v3_team', {
    p_team_id: teamId,
  });

  if (error) {
    throw error;
  }

  return mapTeam(data);
}
