import { supabase } from '../config/supabaseClient.js';

const SAFE_PROFILE_FIELDS =
  'id, username, profile_slug, ign, avatar_key, approval_status, reapply_requested_at, created_at, updated_at';
const SAFE_MEMBERSHIP_FIELDS = 'id, guild_id, role, membership_status, roster_status, is_primary';
const SAFE_GUILD_FIELDS = 'id, name, slug';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
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
