import { supabase } from '../config/supabaseClient.js';

const SAFE_MEMBER_ROSTER_SELECT = `
  id,
  profile_id,
  guild_id,
  role,
  membership_status,
  roster_status,
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
const HARD_BLOCKED_ROSTER_STATUSES = ['suspended', 'left', 'kicked'];
const GVG_LIMITED_ROSTER_STATUSES = ['inactive', 'on_break'];
const STAFF_ROSTER_STATUS_VALUES = [
  'active',
  'trial',
  'inactive',
  'on_break',
  'suspended',
  'left',
  'kicked',
  'pending_transfer',
];
const ADMIN_ROSTER_STATUS_VALUES = ['active', 'trial', 'inactive', 'on_break', 'pending_transfer'];

export const ROSTER_STATUS_OPTIONS = [
  {
    value: 'active',
    label: 'Active',
    tone: 'success',
    summary: 'Normal access and counted as reliable for GvG.',
  },
  {
    value: 'trial',
    label: 'Trial',
    tone: 'info',
    summary: 'Normal access with trial visibility for staff.',
  },
  {
    value: 'inactive',
    label: 'Inactive',
    tone: 'muted',
    summary: 'Can sign in and view profile, but is not expected for GvG.',
  },
  {
    value: 'on_break',
    label: 'On break',
    tone: 'warning',
    summary: 'Can sign in and view profile, but is excluded from GvG expectation.',
  },
  {
    value: 'suspended',
    label: 'Suspended',
    tone: 'danger',
    summary: 'Blocked from member and admin areas.',
  },
  {
    value: 'left',
    label: 'Left',
    tone: 'neutral',
    summary: 'No active member access; preserved for history.',
  },
  {
    value: 'kicked',
    label: 'Kicked',
    tone: 'crimson',
    summary: 'Access removed; preserved for history.',
  },
  {
    value: 'pending_transfer',
    label: 'Pending transfer',
    tone: 'orange',
    summary: 'Normal access while flagged for staff transfer review.',
  },
];

const ROSTER_STATUS_BY_VALUE = ROSTER_STATUS_OPTIONS.reduce((map, option) => {
  map[option.value] = option;
  return map;
}, {});

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

export function isHardBlockedRosterStatus(status) {
  return HARD_BLOCKED_ROSTER_STATUSES.includes(status);
}

export function isGvgLimitedRosterStatus(status) {
  return GVG_LIMITED_ROSTER_STATUSES.includes(status);
}

export function formatRosterStatus(status) {
  return ROSTER_STATUS_BY_VALUE[status]?.label ?? 'Active';
}

export function rosterStatusTone(status) {
  return ROSTER_STATUS_BY_VALUE[status]?.tone ?? 'success';
}

export function getRosterStatusSummary(status) {
  return ROSTER_STATUS_BY_VALUE[status]?.summary ?? ROSTER_STATUS_BY_VALUE.active.summary;
}

export function canUpdateMemberRosterStatus({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('manage_members');
}

export function getAllowedRosterStatusOptions({ membership, permissionKeys = [], targetMembership = null }) {
  if (!canUpdateMemberRosterStatus({ membership, permissionKeys })) {
    return [];
  }

  if (targetMembership?.role === 'owner' && membership?.role !== 'owner') {
    return [];
  }

  if (membership?.role === 'admin') {
    if (targetMembership?.membership_status && targetMembership.membership_status !== 'active') {
      return [];
    }

    return ROSTER_STATUS_OPTIONS.filter((option) => ADMIN_ROSTER_STATUS_VALUES.includes(option.value));
  }

  const allowedValues = STAFF_ROSTER_STATUS_VALUES;

  return ROSTER_STATUS_OPTIONS.filter((option) => allowedValues.includes(option.value));
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
    .in('membership_status', ['active', 'suspended', 'left'])
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

export async function updateMemberRosterStatus({ membershipId, status, reason = '' }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_member_roster_status', {
    p_membership_id: membershipId,
    p_new_status: status,
    p_reason: reason?.trim() || null,
  });

  if (error) {
    throw error;
  }

  return data;
}
