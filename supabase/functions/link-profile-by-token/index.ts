import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';

type ProfileRow = {
  id: string;
  username: string;
  profile_slug: string;
  ign: string;
  approval_status: string;
};

type MembershipRow = {
  guild_id: string | null;
  role: string | null;
  membership_status: string | null;
  roster_status: string | null;
};

type GuildRow = {
  name: string | null;
  slug: string | null;
};

type CosmeticRow = {
  key: string | null;
  asset_path: string | null;
};

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const RESTRICTED_ROSTER_STATUSES = new Set(['suspended', 'left', 'kicked']);

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...CORS_HEADERS,
      'Content-Type': 'application/json',
    },
  });
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();

  if (!value) {
    throw new Error(`${name} is required.`);
  }

  return value;
}

function bearerToken(request: Request): string {
  const header = request.headers.get('Authorization') ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);

  return match?.[1]?.trim() ?? '';
}

function roleLabel(role: string | null): string | null {
  switch (role) {
    case 'owner':
      return 'Owner';
    case 'leader':
      return 'Leader';
    case 'vice':
      return 'Vice';
    case 'admin':
      return 'Admin';
    case 'member':
      return 'Member';
    default:
      return null;
  }
}

function safeAssetPath(path: string | null, type: 'avatar' | 'frame'): string {
  const value = typeof path === 'string' ? path.trim() : '';
  const prefix = type === 'frame' ? '/cosmetics/frames/' : '/cosmetics/avatars/';

  if (!value.startsWith(prefix) || value.includes('..')) {
    return '';
  }

  return value;
}

async function loadPrimaryMembership(supabase: ReturnType<typeof createClient>, profileId: string) {
  const { data: membership, error } = await supabase
    .from('guild_memberships')
    .select('guild_id, role, membership_status, roster_status')
    .eq('profile_id', profileId)
    .eq('is_primary', true)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (membership ?? null) as MembershipRow | null;
}

function isEligibleProfile(profile: ProfileRow | null, membership: MembershipRow | null): boolean {
  if (!profile || profile.approval_status !== 'approved') {
    return false;
  }

  if (!membership || membership.membership_status !== 'active') {
    return false;
  }

  return !RESTRICTED_ROSTER_STATUSES.has(membership.roster_status ?? 'active');
}

async function resolveActorProfileId(supabase: ReturnType<typeof createClient>, authUserId: string): Promise<string> {
  const { data: activeProfile } = await supabase
    .from('user_active_profiles')
    .select('active_profile_id')
    .eq('auth_user_id', authUserId)
    .maybeSingle();

  const candidateProfileId = activeProfile?.active_profile_id || authUserId;

  const { data: link } = await supabase
    .from('user_profile_links')
    .select('profile_id')
    .eq('auth_user_id', authUserId)
    .eq('profile_id', candidateProfileId)
    .is('disabled_at', null)
    .maybeSingle();

  if (link?.profile_id) {
    return link.profile_id;
  }

  const { data: fallbackProfile } = await supabase
    .from('profiles')
    .select('id')
    .eq('id', authUserId)
    .maybeSingle();

  if (fallbackProfile?.id) {
    return fallbackProfile.id;
  }

  throw new Error('Active profile is required.');
}

async function loadProfile(supabase: ReturnType<typeof createClient>, profileId: string): Promise<ProfileRow | null> {
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('id, username, profile_slug, ign, approval_status')
    .eq('id', profileId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return (profile ?? null) as ProfileRow | null;
}

async function loadCosmetic(
  supabase: ReturnType<typeof createClient>,
  type: 'avatar' | 'frame',
  preferredKey: string | null,
  fallbackKey: string,
): Promise<CosmeticRow | null> {
  const keys = Array.from(new Set([preferredKey, fallbackKey].filter(Boolean))) as string[];

  const { data: cosmetics, error } = await supabase
    .from('cosmetic_catalog')
    .select('key, asset_path')
    .eq('type', type)
    .eq('is_active', true)
    .in('key', keys);

  if (error) {
    throw error;
  }

  const rows = (cosmetics ?? []) as CosmeticRow[];

  return rows.find((row) => row.key === preferredKey) ?? rows.find((row) => row.key === fallbackKey) ?? null;
}

async function buildSafeProfileSummary(supabase: ReturnType<typeof createClient>, authUserId: string, profileId: string) {
  const profile = await loadProfile(supabase, profileId);

  if (!profile) {
    throw new Error('Profile not found.');
  }

  const membership = await loadPrimaryMembership(supabase, profileId);
  let guild: GuildRow | null = null;

  if (membership?.guild_id) {
    const { data: guildRow, error: guildError } = await supabase
      .from('guilds')
      .select('name, slug')
      .eq('id', membership.guild_id)
      .maybeSingle();

    if (guildError) {
      throw guildError;
    }

    guild = (guildRow ?? null) as GuildRow | null;
  }

  const { data: equipped, error: equippedError } = await supabase
    .from('profile_equipped_cosmetics')
    .select('avatar_key, frame_key')
    .eq('profile_id', profileId)
    .maybeSingle();

  if (equippedError) {
    throw equippedError;
  }

  const [avatar, frame, activeProfile, link] = await Promise.all([
    loadCosmetic(supabase, 'avatar', equipped?.avatar_key ?? null, '1079_head'),
    loadCosmetic(supabase, 'frame', equipped?.frame_key ?? null, 'TXK_frame_reOpen_EN_FREE'),
    supabase
      .from('user_active_profiles')
      .select('active_profile_id')
      .eq('auth_user_id', authUserId)
      .maybeSingle(),
    supabase
      .from('user_profile_links')
      .select('is_primary')
      .eq('auth_user_id', authUserId)
      .eq('profile_id', profileId)
      .is('disabled_at', null)
      .maybeSingle(),
  ]);

  return {
    profile_id: profile.id,
    username: profile.username,
    profile_slug: profile.profile_slug,
    ign: profile.ign,
    approval_status: profile.approval_status,
    guild_id: membership?.guild_id ?? null,
    guild_name: guild?.name ?? null,
    guild_slug: guild?.slug ?? null,
    role: membership?.role ?? null,
    role_label: roleLabel(membership?.role ?? null),
    membership_status: membership?.membership_status ?? null,
    roster_status: membership?.roster_status ?? null,
    avatar_key: avatar?.key ?? '',
    avatar_asset_path: safeAssetPath(avatar?.asset_path ?? '', 'avatar'),
    frame_key: frame?.key ?? '',
    frame_asset_path: safeAssetPath(frame?.asset_path ?? '', 'frame'),
    is_active_profile: activeProfile.data?.active_profile_id === profile.id,
    is_primary: Boolean(link.data?.is_primary),
  };
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: CORS_HEADERS,
    });
  }

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed.' }, 405);
  }

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL');
    const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    const accountAAccessToken = bearerToken(request);

    if (!accountAAccessToken) {
      return jsonResponse({ error: 'Authentication required.' }, 401);
    }

    const body = await request.json().catch(() => ({}));
    const accountBAccessToken = typeof body.account_b_access_token === 'string'
      ? body.account_b_access_token.trim()
      : '';

    if (!accountBAccessToken) {
      return jsonResponse({ error: 'Account verification failed.' }, 400);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    const [{ data: accountAData, error: accountAError }, { data: accountBData, error: accountBError }] =
      await Promise.all([
        supabase.auth.getUser(accountAAccessToken),
        supabase.auth.getUser(accountBAccessToken),
      ]);

    const accountA = accountAData?.user;
    const accountB = accountBData?.user;

    if (accountAError || !accountA?.id) {
      return jsonResponse({ error: 'Authentication required.' }, 401);
    }

    if (accountBError || !accountB?.id) {
      return jsonResponse({ error: 'Account verification failed.' }, 400);
    }

    if (accountA.id === accountB.id) {
      return jsonResponse({ error: 'Account verification failed.' }, 400);
    }

    const actorProfileId = await resolveActorProfileId(supabase, accountA.id);
    const [actorProfile, actorMembership, targetProfile, targetMembership] = await Promise.all([
      loadProfile(supabase, actorProfileId),
      loadPrimaryMembership(supabase, actorProfileId),
      loadProfile(supabase, accountB.id),
      loadPrimaryMembership(supabase, accountB.id),
    ]);

    if (!isEligibleProfile(actorProfile, actorMembership)) {
      return jsonResponse({ error: 'Account verification failed.' }, 403);
    }

    if (!isEligibleProfile(targetProfile, targetMembership)) {
      return jsonResponse({ error: 'Account verification failed.' }, 403);
    }

    const { data: existingLink, error: existingLinkError } = await supabase
      .from('user_profile_links')
      .select('id')
      .eq('auth_user_id', accountA.id)
      .eq('profile_id', accountB.id)
      .is('disabled_at', null)
      .maybeSingle();

    if (existingLinkError) {
      throw existingLinkError;
    }

    let linkId = existingLink?.id ?? null;
    const alreadyLinked = Boolean(linkId);

    if (!linkId) {
      const { data: insertedLink, error: insertError } = await supabase
        .from('user_profile_links')
        .insert({
          auth_user_id: accountA.id,
          profile_id: accountB.id,
          link_type: 'verified',
          is_primary: false,
          created_by_profile_id: actorProfileId,
        })
        .select('id')
        .single();

      if (insertError) {
        throw insertError;
      }

      linkId = insertedLink.id;

      await supabase
        .from('audit_logs')
        .insert({
          actor_profile_id: actorProfileId,
          target_profile_id: accountB.id,
          guild_id: targetMembership?.guild_id ?? null,
          action: 'account_profile_self_linked',
          entity_table: 'user_profile_links',
          entity_id: linkId,
          metadata: {
            link_type: 'verified',
            method: 'credential_proof',
          },
        });
    }

    const profileSummary = await buildSafeProfileSummary(supabase, accountA.id, accountB.id);

    return jsonResponse({
      linked: true,
      already_linked: alreadyLinked,
      profile: profileSummary,
    });
  } catch (_error) {
    return jsonResponse({ error: 'Account could not be linked.' }, 400);
  }
});
