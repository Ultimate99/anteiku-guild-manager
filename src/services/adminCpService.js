import { supabase } from '../config/supabaseClient.js';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
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

export async function loadCpLeaderboard({ guildId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_cp_leaderboard', {
    p_guild_id: guildId,
    p_snapshot_week_start: null,
  });

  if (error) {
    throw error;
  }

  return data ?? [];
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
