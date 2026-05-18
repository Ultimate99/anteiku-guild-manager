import { supabase } from '../config/supabaseClient.js';

export const AUDIT_ACTION_OPTIONS = [
  { value: 'all', label: 'All actions' },
  { value: 'profile_registered', label: 'Profile registered' },
  { value: 'profile_reapply_requested', label: 'Reapply requested' },
  { value: 'registration_approved', label: 'Registration approved' },
  { value: 'registration_rejected', label: 'Registration rejected' },
  { value: 'member_ign_updated', label: 'Member IGN updated' },
  { value: 'profile_slug_reset', label: 'Profile slug reset' },
  { value: 'member_role_changed', label: 'Member role changed' },
  { value: 'member_role_updated', label: 'Member role updated' },
  { value: 'member_guild_transferred', label: 'Member guild transferred' },
  { value: 'admin_permission_granted', label: 'Admin permission granted' },
  { value: 'admin_permission_revoked', label: 'Admin permission revoked' },
  { value: 'member_cp_updated', label: 'Member CP updated' },
  { value: 'weekly_cp_snapshot_captured', label: 'Weekly CP snapshot' },
  { value: 'gvg_event_created', label: 'GvG event created' },
  { value: 'gvg_event_status_updated', label: 'GvG status updated' },
];

const ACTION_LABELS = AUDIT_ACTION_OPTIONS.reduce((labels, item) => {
  if (item.value !== 'all') {
    labels[item.value] = item.label;
  }

  return labels;
}, {});

const METADATA_LABELS = {
  approval_status: 'Approval status',
  approval_status_new: 'Approval status',
  role_old: 'Old role',
  role_new: 'New role',
  ign_old: 'Old IGN',
  ign_new: 'New IGN',
  slug_old: 'Old slug',
  slug_new: 'New slug',
  permission_key: 'Permission',
  scope: 'Scope',
  status_old: 'Old status',
  status_new: 'New status',
  snapshot_week_start: 'Snapshot week',
  rows_affected: 'Rows affected',
  from_guild_id: 'From guild ID',
  to_guild_id: 'To guild ID',
  old_membership_status_new: 'Old membership status',
  new_membership_status_new: 'New membership status',
  normal_app_rpc: 'Normal app RPC',
  cp_old: 'Old CP',
  cp_new: 'New CP',
  cp_value: 'CP value',
  cp_from: 'CP from',
  cp_to: 'CP to',
  growth: 'Growth',
  growth_value: 'Growth',
};

const REDACTION_METADATA_KEYS = ['cp_metadata_redacted', 'redaction_reason'];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function isPermissionError(error) {
  const message = error?.message?.toLowerCase() ?? '';

  return (
    message.includes('not authorized') ||
    message.includes('permission denied') ||
    message.includes('approved profile required')
  );
}

function toNullableFilter(value) {
  if (!value || value === 'all') {
    return null;
  }

  return value;
}

function normalizeLimit(limit) {
  const parsedLimit = Number(limit);

  if (!Number.isFinite(parsedLimit)) {
    return 50;
  }

  return Math.min(Math.max(Math.trunc(parsedLimit), 1), 100);
}

function formatPerson({ profileId, username, ign, emptyLabel }) {
  if (ign && username) {
    return `${ign} (@${username})`;
  }

  if (ign) {
    return ign;
  }

  if (username) {
    return `@${username}`;
  }

  if (profileId) {
    return `Profile ${String(profileId).slice(0, 8)}`;
  }

  return emptyLabel;
}

function formatMetadataValue(value) {
  if (value === null || value === undefined || value === '') {
    return '';
  }

  if (typeof value === 'boolean') {
    return value ? 'Yes' : 'No';
  }

  if (typeof value === 'number') {
    return value.toLocaleString();
  }

  if (typeof value === 'string') {
    return value.length > 140 ? `${value.slice(0, 137)}...` : value;
  }

  return '';
}

export function getDefaultAuditFilters() {
  return {
    guildId: 'all',
    action: 'all',
    dateFrom: '',
    dateTo: '',
    limit: 50,
  };
}

export function canViewAuditLogs({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('view_audit_logs');
}

export async function loadAuditLogs(filters = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_audit_logs', {
    p_guild_id: toNullableFilter(filters.guildId),
    p_action: toNullableFilter(filters.action),
    p_actor_id: toNullableFilter(filters.actorId),
    p_target_id: toNullableFilter(filters.targetId),
    p_from: filters.from ?? null,
    p_to: filters.to ?? null,
    p_limit: normalizeLimit(filters.limit),
    p_before: filters.before ?? null,
  });

  if (error) {
    if (isPermissionError(error)) {
      const authorizationError = new Error('Not authorized to view audit logs.');
      authorizationError.code = 'AUDIT_NOT_AUTHORIZED';
      throw authorizationError;
    }

    throw error;
  }

  return data ?? [];
}

export function formatAuditAction(action) {
  if (!action) {
    return 'Unknown action';
  }

  return ACTION_LABELS[action] ?? action.replaceAll('_', ' ');
}

export function formatAuditActor(row) {
  return formatPerson({
    profileId: row.actor_profile_id,
    username: row.actor_username,
    ign: row.actor_ign,
    emptyLabel: 'System',
  });
}

export function formatAuditTarget(row) {
  return formatPerson({
    profileId: row.target_profile_id,
    username: row.target_username,
    ign: row.target_ign,
    emptyLabel: '',
  });
}

export function formatAuditMetadata(metadata, metadataRedacted = false) {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return [];
  }

  return Object.entries(metadata)
    .filter(([key]) => !REDACTION_METADATA_KEYS.includes(key))
    .filter(([key]) => Boolean(METADATA_LABELS[key]))
    .map(([key, value]) => ({
      key,
      label: METADATA_LABELS[key],
      value: formatMetadataValue(value),
      sensitive: metadataRedacted && key.startsWith('cp_'),
    }))
    .filter((item) => item.value !== '');
}
