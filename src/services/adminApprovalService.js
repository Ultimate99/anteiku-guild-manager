import { supabase } from '../config/supabaseClient.js';

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

export async function loadApprovalQueue() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_approval_queue');

  if (error) {
    throw error;
  }

  return data ?? [];
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
