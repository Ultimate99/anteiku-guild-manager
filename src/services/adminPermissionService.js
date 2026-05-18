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

const SAFE_ADMIN_PERMISSION_TARGET_SELECT = `
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
    approval_status
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

export async function loadPermissionCatalog() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('permission_catalog')
    .select('key, label, description, is_sensitive')
    .in('key', V1_ADMIN_PERMISSION_KEYS);

  if (error) {
    throw error;
  }

  const order = new Map(V1_ADMIN_PERMISSION_KEYS.map((key, index) => [key, index]));

  return (data ?? []).sort((a, b) => (order.get(a.key) ?? 99) - (order.get(b.key) ?? 99));
}

export async function loadAdminPermissionTargets() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('guild_memberships')
    .select(SAFE_ADMIN_PERMISSION_TARGET_SELECT)
    .eq('role', 'admin')
    .eq('membership_status', 'active')
    .eq('is_primary', true)
    .eq('profile.approval_status', 'approved')
    .order('created_at', { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadAdminPermissionRows(membershipIds) {
  if (membershipIds.length === 0) {
    return [];
  }

  const client = requireSupabase();
  const { data, error } = await client
    .from('admin_permissions')
    .select('membership_id, permission_key')
    .in('membership_id', membershipIds);

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadAdminPermissionManagementData() {
  const [catalog, targets] = await Promise.all([
    loadPermissionCatalog(),
    loadAdminPermissionTargets(),
  ]);
  const permissionRows = await loadAdminPermissionRows(targets.map((target) => target.id));
  const permissionsByMembership = permissionRows.reduce((map, row) => {
    const keys = map.get(row.membership_id) ?? [];
    keys.push(row.permission_key);
    map.set(row.membership_id, keys);
    return map;
  }, new Map());

  return {
    catalog,
    targets: targets.map((target) => ({
      ...target,
      permissionKeys: permissionsByMembership.get(target.id) ?? [],
    })),
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
