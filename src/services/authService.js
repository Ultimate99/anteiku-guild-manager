import { supabase } from '../config/supabaseClient.js';

const AUTH_DISPLAY_MESSAGES = new Set([
  'Invalid email or password.',
  'Too many attempts. Try again later.',
  'Email limit reached. Try again later.',
  'Something went wrong. Try again.',
]);

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function getAuthErrorMessage(error, context = 'auth') {
  const rawMessage = typeof error?.message === 'string' ? error.message : String(error ?? '');

  if (AUTH_DISPLAY_MESSAGES.has(rawMessage)) {
    return rawMessage;
  }

  const code = String(error?.code ?? error?.error ?? error?.error_code ?? '').toLowerCase();
  const status = Number(error?.status ?? 0);
  const normalized = `${rawMessage} ${code}`.toLowerCase();

  if (normalized.includes('invalid login credentials')) {
    return 'Invalid email or password.';
  }

  if (status === 429 || normalized.includes('rate limit') || normalized.includes('too many')) {
    return context === 'password-reset'
      ? 'Email limit reached. Try again later.'
      : 'Too many attempts. Try again later.';
  }

  return 'Something went wrong. Try again.';
}

function throwAuthDisplayError(error, context) {
  throw new Error(getAuthErrorMessage(error, context));
}

async function runAuthRequest(request, context) {
  try {
    const { data, error } = await request();

    if (error) {
      throwAuthDisplayError(error, context);
    }

    return data;
  } catch (error) {
    throwAuthDisplayError(error, context);
  }
}

export async function getSession() {
  const client = requireSupabase();
  const { data, error } = await client.auth.getSession();

  if (error) {
    throw error;
  }

  return data.session;
}

export function onAuthStateChange(callback) {
  if (!supabase) {
    return { unsubscribe: () => {} };
  }

  const { data } = supabase.auth.onAuthStateChange(callback);
  return data.subscription;
}

export async function signInWithPassword(email, password) {
  const client = requireSupabase();
  return runAuthRequest(() => client.auth.signInWithPassword({ email, password }), 'sign-in');
}

export async function signUpWithPassword(email, password) {
  const client = requireSupabase();
  return runAuthRequest(() => client.auth.signUp({ email, password }), 'sign-up');
}

export async function requestPasswordReset(email) {
  const client = requireSupabase();
  const redirectTo = typeof window !== 'undefined' ? window.location.origin : undefined;
  const options = redirectTo ? { redirectTo } : undefined;
  return runAuthRequest(() => client.auth.resetPasswordForEmail(email, options), 'password-reset');
}

export async function updateRecoveredPassword(password) {
  const client = requireSupabase();
  const { data, error } = await client.auth.updateUser({ password });

  if (error) {
    throw error;
  }

  return data;
}

export async function signOutUser() {
  const client = requireSupabase();
  const { error } = await client.auth.signOut();

  if (error) {
    throw error;
  }
}
