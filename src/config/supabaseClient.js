import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);
export const isLocalSupabase =
  Boolean(supabaseUrl) && (supabaseUrl.includes('localhost') || supabaseUrl.includes('127.0.0.1'));

export const supabaseEnvironmentLabel = !isSupabaseConfigured
  ? 'Supabase not configured'
  : isLocalSupabase
    ? 'Local Supabase'
    : 'Supabase configured';

export const supabase = isSupabaseConfigured
  ? createClient(supabaseUrl, supabaseAnonKey)
  : null;
