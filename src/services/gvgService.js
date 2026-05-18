import { supabase } from '../config/supabaseClient.js';

const SAFE_GVG_EVENT_SELECT = `
  id,
  guild_id,
  scope,
  title,
  status,
  starts_at,
  ends_at,
  created_at,
  updated_at,
  guild:guilds!gvg_events_guild_id_fkey(
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

export function canManageGvg({ membership, permissionKeys = [] }) {
  if (!membership) {
    return false;
  }

  if (['owner', 'leader', 'vice'].includes(membership.role)) {
    return true;
  }

  return membership.role === 'admin' && permissionKeys.includes('manage_gvg');
}

export function getGvgManageGuildOptions({ membership, activeGuilds = [] }) {
  if (!membership) {
    return [];
  }

  if (membership.role === 'owner') {
    return activeGuilds;
  }

  if (!membership.guild_id) {
    return [];
  }

  return [
    {
      id: membership.guild_id,
      name: membership.guild?.name ?? membership.guild_name ?? 'Assigned guild',
      slug: membership.guild?.slug ?? '',
    },
  ];
}

export async function loadGvgGuildOptions() {
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

export async function loadMemberActiveGvgEvents({ guildId }) {
  const client = requireSupabase();
  let query = client
    .from('gvg_events')
    .select(SAFE_GVG_EVENT_SELECT)
    .eq('status', 'active')
    .order('created_at', { ascending: false });

  if (guildId) {
    query = query.or(`scope.eq.global,guild_id.eq.${guildId}`);
  } else {
    query = query.eq('scope', 'global');
  }

  const { data, error } = await query;

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadManageableGvgEvents() {
  const client = requireSupabase();
  const { data, error } = await client
    .from('gvg_events')
    .select(SAFE_GVG_EVENT_SELECT)
    .order('created_at', { ascending: false })
    .limit(20);

  if (error) {
    throw error;
  }

  return data ?? [];
}

export async function loadOwnGvgVote({ eventId, profileId }) {
  if (!eventId || !profileId) {
    return null;
  }

  const client = requireSupabase();
  const { data, error } = await client
    .from('gvg_votes')
    .select('id, gvg_event_id, vote_status, absence_reason, updated_at')
    .eq('gvg_event_id', eventId)
    .eq('profile_id', profileId)
    .maybeSingle();

  if (error) {
    throw error;
  }

  return data ?? null;
}

export async function submitGvgVote({ eventId, voteStatus, absenceReason }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('submit_gvg_vote', {
    p_event_id: eventId,
    p_vote_status: voteStatus,
    p_absence_reason: voteStatus === 'absent' ? absenceReason?.trim() || null : null,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function createGvgEvent({ title, scope, guildId, startsAt, endsAt }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('create_gvg_event', {
    p_title: title,
    p_scope: scope,
    p_guild_id: scope === 'guild' ? guildId : null,
    p_starts_at: startsAt || null,
    p_ends_at: endsAt || null,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function setGvgEventStatus({ eventId, status }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('set_gvg_event_status', {
    p_event_id: eventId,
    p_status: status,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function loadGvgResults({ eventId }) {
  if (!eventId) {
    return [];
  }

  const client = requireSupabase();
  const { data, error } = await client.rpc('get_gvg_results', {
    p_event_id: eventId,
  });

  if (error) {
    throw error;
  }

  return data ?? [];
}
