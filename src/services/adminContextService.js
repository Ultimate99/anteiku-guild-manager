import { supabase } from '../config/supabaseClient.js';

const FORBIDDEN_ADMIN_CONTEXT_VALUE_KEYS = ['cp_value', 'current_cp', 'previous_cp', 'baseline_cp', 'growth_amount'];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeBoolean(value) {
  return Boolean(value);
}

function safeStringArray(value) {
  return Array.isArray(value) ? value.map((item) => safeString(item)).filter(Boolean) : [];
}

function assertSafeAdminContextPayload(payload) {
  const stack = [payload];

  while (stack.length > 0) {
    const current = stack.pop();

    if (!current || typeof current !== 'object') {
      continue;
    }

    for (const [key, value] of Object.entries(current)) {
      const loweredKey = key.toLowerCase();
      const forbiddenKey = FORBIDDEN_ADMIN_CONTEXT_VALUE_KEYS.find((field) => loweredKey.includes(field));

      if (forbiddenKey) {
        throw new Error(`Unexpected private admin context field returned: ${forbiddenKey}`);
      }

      if (value && typeof value === 'object') {
        stack.push(value);
      }
    }
  }
}

function mapAdminContext(payload) {
  assertSafeAdminContextPayload(payload);

  return {
    activeProfileId: payload?.active_profile_id ?? null,
    profileSlug: safeString(payload?.profile_slug),
    username: safeString(payload?.username),
    ign: safeString(payload?.ign),
    guildId: payload?.guild_id ?? null,
    guildName: safeString(payload?.guild_name),
    guildSlug: safeString(payload?.guild_slug),
    role: safeString(payload?.role),
    isOwner: safeBoolean(payload?.is_owner),
    isLeader: safeBoolean(payload?.is_leader),
    isVice: safeBoolean(payload?.is_vice),
    isAdmin: safeBoolean(payload?.is_admin),
    isStaff: safeBoolean(payload?.is_staff),
    permissionKeys: safeStringArray(payload?.permission_keys),
    canAccessAdminPanel: safeBoolean(payload?.can_access_admin_panel),
    scopedGuildIds: safeStringArray(payload?.scoped_guild_ids),
    activeProfileStatus: safeString(payload?.active_profile_status),
    membershipStatus: safeString(payload?.membership_status),
    rosterStatus: safeString(payload?.roster_status),
    scope: safeString(payload?.scope),
  };
}

export async function loadMyActiveAdminContext() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_active_admin_context');

  if (error) {
    throw error;
  }

  return mapAdminContext(data);
}
