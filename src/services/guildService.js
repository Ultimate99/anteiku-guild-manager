import { supabase } from '../config/supabaseClient.js';

export async function getCoreGuilds() {
  if (!supabase) {
    return [];
  }

  const { data, error } = await supabase
    .from('guilds')
    .select('id, name, slug')
    .eq('is_core', true)
    .eq('status', 'active')
    .order('name', { ascending: true });

  if (error) {
    throw error;
  }

  return data ?? [];
}
