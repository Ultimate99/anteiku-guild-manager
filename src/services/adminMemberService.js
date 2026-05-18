import { supabase } from '../config/supabaseClient.js';

const SAFE_MEMBER_ROSTER_SELECT = `
  id,
  profile_id,
  guild_id,
  role,
  membership_status,
  is_primary,
  created_at,
  updated_at,
  profile:profiles!guild_memberships_profile_id_fkey!inner(
    id,
    username,
    profile_slug,
    ign,
    avatar_key,
    approval_status,
    created_at,
    updated_at
  ),
  guild:guilds!guild_memberships_guild_id_fkey(
    id,
    name,
    slug
  )
`;

const RELEVANT_MEMBER_PERMISSIONS = ['manage_members', 'edit_member_ign', 'reset_profile_slug', 'manage_roles'];
const PROFILE_SLUG_PATTERN = /^[a-z0-9](?:[a-z0-9_-]{1,30}[a-z0-9])$/;

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

export function normalizeProfileSlug(value) {
  return value.trim().toLowerCase();
}

export function isValidProfileSlug(value) {
  return PROFILE_SLUG_PATTERN.test(value);
}

export function canViewMemberManagement({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return (
    membership.role === 'admin' &&
    RELEVANT_MEMBER_PERMISSIONS.some((permissionKey) => permissionKeys.includes(permissionKey))
  );
}

export function canEditMemberIgn({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('edit_member_ign');
}

export function canResetMemberSlug({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('reset_profile_slug');
}

export function canAssignMemberRole({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('manage_roles');
}

export function canTransferMemberGuild({ membership }) {
  return membership?.role === 'owner';
}

export function getAllowedMemberRoleOptions({ membership, permissionKeys = [] }) {
  if (!membership) {
    return [];
  }

  if (membership.role === 'owner') {
    return ['member', 'admin', 'vice', 'leader'];
  }

  if (['leader', 'vice'].includes(membership.role)) {
    return ['member', 'admin'];
  }

  if (membership.role === 'admin' && permissionKeys.includes('manage_roles')) {
    return ['member', 'admin'];
  }

  return [];
}

export async function loadMemberRoster() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('guild_memberships')
    .select(SAFE_MEMBER_ROSTER_SELECT)
    .eq('is_primary', true)
    .eq('membership_status', 'active')
    .eq('profile.approval_status', 'approved')
    .order('created_at', { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadActiveGuildOptions() {
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

export async function adminUpdateMemberIgn({ profileId, ign }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('admin_update_member_ign', {
    p_profile_id: profileId,
    p_ign: ign,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function adminResetProfileSlug({ profileId, newSlug }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('admin_reset_profile_slug', {
    p_profile_id: profileId,
    p_new_slug: newSlug,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function assignMemberRole({ profileId, guildId, role }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('assign_member_role', {
    p_profile_id: profileId,
    p_guild_id: guildId,
    p_role: role,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function transferMemberGuild({ profileId, fromGuildId, toGuildId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('transfer_member_guild', {
    p_profile_id: profileId,
    p_from_guild_id: fromGuildId,
    p_to_guild_id: toGuildId,
  });

  if (error) {
    throw error;
  }

  return data;
}
