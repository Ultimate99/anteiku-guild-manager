import { supabase } from '../config/supabaseClient.js';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function normalizeGuildId(guildId) {
  return guildId || null;
}

function normalizeNumber(value) {
  if (value === null || value === undefined) {
    return null;
  }

  const nextValue = Number(value);
  return Number.isFinite(nextValue) ? nextValue : null;
}

function normalizeAnalyticsError(error, code) {
  if (!error) {
    return null;
  }

  const nextError = new Error(error.message || 'Analytics request failed.');
  nextError.code = code;
  nextError.details = error.details;
  nextError.hint = error.hint;
  return nextError;
}

function mapMemberAnalytics(row) {
  if (!row) {
    return null;
  }

  return {
    scopeGuildId: row.scope_guild_id,
    scopeGuildName: row.scope_guild_name,
    totalMembers: normalizeNumber(row.total_members) ?? 0,
    activeMembers: normalizeNumber(row.active_members) ?? 0,
    trialMembers: normalizeNumber(row.trial_members) ?? 0,
    pendingTransferMembers: normalizeNumber(row.pending_transfer_members) ?? 0,
    inactiveMembers: normalizeNumber(row.inactive_members) ?? 0,
    onBreakMembers: normalizeNumber(row.on_break_members) ?? 0,
    suspendedMembers: normalizeNumber(row.suspended_members) ?? 0,
    leftMembers: normalizeNumber(row.left_members) ?? 0,
    kickedMembers: normalizeNumber(row.kicked_members) ?? 0,
    pendingApprovals: normalizeNumber(row.pending_approvals) ?? 0,
    membersByGuild: Array.isArray(row.members_by_guild) ? row.members_by_guild : [],
  };
}

function mapCpAnalytics(row) {
  if (!row) {
    return null;
  }

  return {
    scopeGuildId: row.scope_guild_id,
    scopeGuildName: row.scope_guild_name,
    totalCp: normalizeNumber(row.total_cp) ?? 0,
    averageCp: normalizeNumber(row.average_cp),
    highestCp: normalizeNumber(row.highest_cp),
    lowestCp: normalizeNumber(row.lowest_cp),
    membersMissingCp: normalizeNumber(row.members_missing_cp) ?? 0,
    recentlyUpdatedCpCount: normalizeNumber(row.recently_updated_cp_count) ?? 0,
    cpUpdateWindowStatus: row.cp_update_window_status,
    cpUpdateWindowId: row.cp_update_window_id,
    cpUpdateWindowUpdatedAt: row.cp_update_window_updated_at,
    openCpWindowCount: normalizeNumber(row.open_cp_window_count) ?? 0,
    selfSubmittedCount: normalizeNumber(row.self_submitted_count) ?? 0,
    recentlyUpdatedMembers: Array.isArray(row.recently_updated_members) ? row.recently_updated_members : [],
  };
}

function mapGvgAnalytics(row) {
  if (!row) {
    return null;
  }

  return {
    scopeGuildId: row.scope_guild_id,
    scopeGuildName: row.scope_guild_name,
    latestEventId: row.latest_event_id,
    latestEventTitle: row.latest_event_title,
    latestEventScope: row.latest_event_scope,
    latestEventStatus: row.latest_event_status,
    latestEventGuildId: row.latest_event_guild_id,
    latestEventGuildName: row.latest_event_guild_name,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    presentCount: normalizeNumber(row.present_count) ?? 0,
    absentCount: normalizeNumber(row.absent_count) ?? 0,
    noVoteCount: normalizeNumber(row.no_vote_count) ?? 0,
    eligibleCount: normalizeNumber(row.eligible_count) ?? 0,
    participationPercent: normalizeNumber(row.participation_percent) ?? 0,
    absenceReasons: Array.isArray(row.absence_reasons) ? row.absence_reasons : [],
    recentEvents: Array.isArray(row.recent_events) ? row.recent_events : [],
  };
}

function mapSnapshot(row) {
  return {
    id: row.id,
    guildId: row.guild_id,
    guildName: row.guild_name,
    label: row.label,
    capturedAt: row.captured_at,
    capturedByProfileId: row.captured_by_profile_id,
    capturedByUsername: row.captured_by_username,
    capturedByIgn: row.captured_by_ign,
    weekStart: row.week_start,
    weekEnd: row.week_end,
    memberCount: normalizeNumber(row.member_count) ?? 0,
    scope: row.scope,
  };
}

function mapGrowthRow(row) {
  return {
    hasPreviousSnapshot: Boolean(row.has_previous_snapshot),
    currentSnapshotId: row.current_snapshot_id,
    previousSnapshotId: row.previous_snapshot_id,
    rank: normalizeNumber(row.rank),
    profileId: row.profile_id,
    username: row.username,
    ign: row.ign,
    guildId: row.guild_id,
    guildName: row.guild_name,
    previousCp: normalizeNumber(row.previous_cp),
    currentCp: normalizeNumber(row.current_cp),
    growthAmount: normalizeNumber(row.growth_amount),
    growthPercent: normalizeNumber(row.growth_percent),
    lastUpdated: row.last_updated,
    missingUpdate: Boolean(row.missing_update),
  };
}

export async function loadMemberAnalytics({ guildId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_member_analytics', {
    p_guild_id: normalizeGuildId(guildId),
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_MEMBER_DENIED');
  }

  return mapMemberAnalytics(data?.[0]);
}

export async function loadCpAnalytics({ guildId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_cp_analytics', {
    p_guild_id: normalizeGuildId(guildId),
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_CP_DENIED');
  }

  return mapCpAnalytics(data?.[0]);
}

export async function loadGvgAnalytics({ guildId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_gvg_analytics', {
    p_guild_id: normalizeGuildId(guildId),
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_GVG_DENIED');
  }

  return mapGvgAnalytics(data?.[0]);
}

export async function captureWeeklyCpSnapshot({ guildId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('capture_weekly_cp_snapshot', {
    p_guild_id: normalizeGuildId(guildId),
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_SNAPSHOT_DENIED');
  }

  const row = data?.[0];

  return row
    ? {
        batchId: row.batch_id,
        guildId: row.guild_id,
        capturedAt: row.captured_at,
        capturedCount: normalizeNumber(row.captured_count) ?? 0,
      }
    : null;
}

export async function loadCpSnapshotHistory({ guildId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_cp_snapshot_history', {
    p_guild_id: normalizeGuildId(guildId),
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_SNAPSHOT_HISTORY_DENIED');
  }

  return (data ?? []).map(mapSnapshot);
}

export async function loadCpGrowthReport({ guildId = null, snapshotId = null } = {}) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_admin_cp_growth_report', {
    p_guild_id: normalizeGuildId(guildId),
    p_snapshot_id: snapshotId || null,
  });

  if (error) {
    throw normalizeAnalyticsError(error, 'ANALYTICS_GROWTH_DENIED');
  }

  return (data ?? []).map(mapGrowthRow);
}
