import { supabase } from '../config/supabaseClient.js';

export const V1_ADMIN_PERMISSION_KEYS = [
  'approve_members',
  'manage_members',
  'edit_member_ign',
  'reset_profile_slug',
  'manage_roles',
  'view_cp',
  'update_cp',
  'manage_gvg',
  'view_audit_logs',
];

const CP_PERMISSION_KEYS = ['view_cp', 'update_cp'];
const SENSITIVE_PERMISSION_KEYS = ['view_cp', 'update_cp', 'manage_roles', 'view_audit_logs'];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

export function canManageAdminPermissions({ membership }) {
  return ['owner', 'leader', 'vice'].includes(membership?.role);
}

export function isCpPermissionKey(permissionKey) {
  return CP_PERMISSION_KEYS.includes(permissionKey);
}

export function isSensitivePermissionKey(permissionKey) {
  return SENSITIVE_PERMISSION_KEYS.includes(permissionKey);
}

export function canToggleAdminPermission({ membership, permissionKey }) {
  if (membership?.role === 'owner') {
    return true;
  }

  if (['leader', 'vice'].includes(membership?.role)) {
    return !isCpPermissionKey(permissionKey);
  }

  return false;
}

export async function loadAdminPermissionManagementData() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_permission_management');

  if (error) {
    throw error;
  }

  return {
    catalog: data?.catalog ?? [],
    targets: data?.targets ?? [],
  };
}

export async function grantAdminPermission({ membershipId, permissionKey }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('grant_admin_permission', {
    p_membership_id: membershipId,
    p_permission_key: permissionKey,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function revokeAdminPermission({ membershipId, permissionKey }) {
  const client = requireSupabase();
  const { error } = await client.rpc('revoke_admin_permission', {
    p_membership_id: membershipId,
    p_permission_key: permissionKey,
  });

  if (error) {
    throw error;
  }
}

export async function saveAdminPermissionChanges({ membershipId, currentKeys, nextKeys }) {
  const currentSet = new Set(currentKeys);
  const nextSet = new Set(nextKeys);
  const grants = V1_ADMIN_PERMISSION_KEYS.filter((key) => nextSet.has(key) && !currentSet.has(key));
  const revokes = V1_ADMIN_PERMISSION_KEYS.filter((key) => currentSet.has(key) && !nextSet.has(key));

  for (const permissionKey of grants) {
    await grantAdminPermission({ membershipId, permissionKey });
  }

  for (const permissionKey of revokes) {
    await revokeAdminPermission({ membershipId, permissionKey });
  }

  return {
    granted: grants.length,
    revoked: revokes.length,
  };
}
