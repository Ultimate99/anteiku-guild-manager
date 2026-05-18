import { supabase } from '../config/supabaseClient.js';

const SAFE_APPROVAL_QUEUE_SELECT = `
  id,
  profile_id,
  guild_id,
  role,
  membership_status,
  is_primary,
  created_at,
  updated_at,
  profile:profiles!guild_memberships_profile_id_fkey(
    id,
    username,
    profile_slug,
    ign,
    avatar_key,
    approval_status,
    reapply_requested_at,
    reapply_note,
    created_at,
    updated_at
  ),
  guild:guilds!guild_memberships_guild_id_fkey(
    id,
    name,
    slug
  )
`;

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

export function getAllowedApprovalRoles(role) {
  if (role === 'owner') {
    return ['member', 'admin', 'vice', 'leader'];
  }

  if (role === 'leader' || role === 'vice') {
    return ['member', 'admin'];
  }

  if (role === 'admin') {
    return ['member'];
  }

  return [];
}

export function canReviewApprovals({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('approve_members');
}

export async function getOwnAdminPermissionKeys(membershipId) {
  if (!membershipId) {
    return [];
  }

  const client = requireSupabase();
  const { data, error } = await client
    .from('admin_permissions')
    .select('permission_key')
    .eq('membership_id', membershipId);

  if (error) {
    throw error;
  }

  return (data ?? []).map((permission) => permission.permission_key);
}

export async function loadApprovalQueue() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('guild_memberships')
    .select(SAFE_APPROVAL_QUEUE_SELECT)
    .eq('is_primary', true)
    .in('membership_status', ['pending', 'rejected'])
    .order('created_at', { ascending: true });

  if (error) {
    throw error;
  }

  return (data ?? []).filter((item) => {
    if (item.membership_status === 'pending') {
      return true;
    }

    return item.membership_status === 'rejected' && Boolean(item.profile?.reapply_requested_at);
  });
}

export async function approveRegistration({ profileId, guildId, role }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('approve_registration', {
    p_profile_id: profileId,
    p_guild_id: guildId,
    p_role: role,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function rejectRegistration({ profileId, reason }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('reject_registration', {
    p_profile_id: profileId,
    p_reason: reason?.trim() || null,
  });

  if (error) {
    throw error;
  }

  return data;
}
