import { supabase } from '../config/supabaseClient.js';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function firstRow(data) {
  return Array.isArray(data) ? data[0] ?? null : data ?? null;
}

export function isValidCpValueInput(value) {
  return /^\d+$/.test(String(value ?? '').trim());
}

export function formatCpDisplayValue(value, fallback) {
  return value === null || value === undefined ? fallback : Number(value).toLocaleString();
}

export async function loadMyCp() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_cp');

  if (error) {
    throw error;
  }

  return firstRow(data);
}

export async function loadMyCpUpdateWindow() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_active_cp_update_window_for_me');

  if (error) {
    throw error;
  }

  return firstRow(data);
}

export async function submitMyCpUpdate({ cpValue }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('submit_my_cp_update', {
    p_cp_value: cpValue,
  });

  if (error) {
    throw error;
  }

  return firstRow(data);
}

export async function loadCpUpdateWindowForGuild({ guildId }) {
  if (!guildId) {
    return null;
  }

  const client = requireSupabase();
  const { data, error } = await client.rpc('get_cp_update_window_for_guild', {
    p_guild_id: guildId,
  });

  if (error) {
    throw error;
  }

  return firstRow(data);
}

export async function openCpUpdateWindow({ guildId, opensAt = null, closesAt = null, note = '' }) {
  const client = requireSupabase();
  const normalizedNote = note.trim() || null;
  const { data, error } = await client.rpc('open_cp_update_window', {
    p_guild_id: guildId,
    p_opens_at: opensAt,
    p_closes_at: closesAt,
    p_note: normalizedNote,
  });

  if (error) {
    throw error;
  }

  return firstRow(data);
}

export async function closeCpUpdateWindow({ windowId }) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('close_cp_update_window', {
    p_window_id: windowId,
  });

  if (error) {
    throw error;
  }

  return firstRow(data);
}
