import { createClient } from '@supabase/supabase-js';
import { supabase, supabaseAnonKey, supabaseUrl } from '../config/supabaseClient.js';

const SAFE_AVATAR_PREFIX = '/cosmetics/avatars/';
const SAFE_FRAME_PREFIX = '/cosmetics/frames/';
const FORBIDDEN_ACCOUNT_SWITCHER_FIELDS = [
  'member_cp',
  'cp_snapshots',
  'cp_value',
  'current_cp',
  'combined_cp',
  'email',
  'auth',
  'admin_permissions',
  'audit',
  'permission_key',
  'private',
];

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function requireSupabaseConfig() {
  if (!supabaseUrl || !supabaseAnonKey) {
    throw new Error('Supabase is not configured.');
  }

  return { supabaseUrl, supabaseAnonKey };
}

function safeString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeBoolean(value) {
  return Boolean(value);
}

function safeAssetPath(value, type) {
  const path = safeString(value);
  const prefix = type === 'frame' ? SAFE_FRAME_PREFIX : SAFE_AVATAR_PREFIX;

  if (!path.startsWith(prefix) || path.includes('..')) {
    return '';
  }

  return path;
}

function assertNoPrivateAccountSwitcherFields(payload) {
  const stack = [payload];

  while (stack.length > 0) {
    const current = stack.pop();

    if (!current || typeof current !== 'object') {
      continue;
    }

    for (const [key, value] of Object.entries(current)) {
      const loweredKey = key.toLowerCase();
      const forbidden = FORBIDDEN_ACCOUNT_SWITCHER_FIELDS.find((field) => loweredKey.includes(field));

      if (forbidden) {
        throw new Error(`Unexpected private account-switcher field returned: ${forbidden}`);
      }

      if (value && typeof value === 'object') {
        stack.push(value);
      }
    }
  }
}

function mapProfile(row) {
  return {
    profileId: row?.profile_id || null,
    username: safeString(row?.username),
    profileSlug: safeString(row?.profile_slug),
    ign: safeString(row?.ign),
    approvalStatus: safeString(row?.approval_status),
    guildId: row?.guild_id || null,
    guildName: safeString(row?.guild_name),
    guildSlug: safeString(row?.guild_slug),
    role: safeString(row?.role),
    roleLabel: safeString(row?.role_label),
    membershipStatus: safeString(row?.membership_status),
    rosterStatus: safeString(row?.roster_status),
    avatar: {
      key: safeString(row?.avatar_key),
      assetPath: safeAssetPath(row?.avatar_asset_path, 'avatar'),
    },
    frame: {
      key: safeString(row?.frame_key),
      assetPath: safeAssetPath(row?.frame_asset_path, 'frame'),
    },
    isActiveProfile: safeBoolean(row?.is_active_profile),
    isPrimary: safeBoolean(row?.is_primary),
  };
}

export async function loadSwitchableProfiles() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_switchable_profiles');

  if (error) {
    throw error;
  }

  assertNoPrivateAccountSwitcherFields(data);

  return {
    profiles: Array.isArray(data?.profiles)
      ? data.profiles.map(mapProfile).filter((profile) => profile.profileId)
      : [],
  };
}

export async function loadActiveProfile() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_active_profile');

  if (error) {
    throw error;
  }

  assertNoPrivateAccountSwitcherFields(data);

  return mapProfile(data?.profile);
}

export async function setActiveProfile(profileId) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('set_my_active_profile', {
    p_profile_id: profileId,
  });

  if (error) {
    throw error;
  }

  assertNoPrivateAccountSwitcherFields(data);

  return mapProfile(data?.profile);
}

export async function linkAccountWithCredentials({ email, password }) {
  const client = requireSupabase();
  const { supabaseUrl: configuredUrl, supabaseAnonKey: configuredAnonKey } = requireSupabaseConfig();
  const normalizedEmail = safeString(email).toLowerCase();

  if (!normalizedEmail || !password) {
    throw new Error('Account could not be linked.');
  }

  const temporaryClient = createClient(configuredUrl, configuredAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
      storageKey: `agm-temp-link-${Date.now()}`,
    },
  });

  try {
    const { data: verificationState, error: verificationError } = await temporaryClient.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    });

    const verifiedAccessToken = verificationState?.session?.access_token;

    if (verificationError || !verifiedAccessToken) {
      throw new Error('Account could not be linked.');
    }

    const { data, error } = await client.functions.invoke('link-profile-by-token', {
      body: {
        account_b_access_token: verifiedAccessToken,
      },
    });

    if (error || data?.error) {
      throw new Error('Account could not be linked.');
    }

    assertNoPrivateAccountSwitcherFields(data);

    return {
      linked: Boolean(data?.linked),
      alreadyLinked: Boolean(data?.already_linked),
      profile: mapProfile(data?.profile),
    };
  } finally {
    await temporaryClient.auth.signOut().catch(() => {});
  }
}
