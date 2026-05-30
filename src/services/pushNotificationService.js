import { supabase } from '../config/supabaseClient.js';

function requireSupabase() {
  if (!supabase) {
    throw new Error('Supabase is not configured.');
  }

  return supabase;
}

function base64UrlToUint8Array(value) {
  const padding = '='.repeat((4 - (value.length % 4)) % 4);
  const base64 = `${value}${padding}`.replaceAll('-', '+').replaceAll('_', '/');
  const rawData = window.atob(base64);
  const output = new Uint8Array(rawData.length);

  for (let index = 0; index < rawData.length; index += 1) {
    output[index] = rawData.charCodeAt(index);
  }

  return output;
}

export function isPushSupported() {
  return typeof window !== 'undefined'
    && 'Notification' in window
    && 'serviceWorker' in navigator
    && 'PushManager' in window;
}

export function getNotificationPermission() {
  if (typeof window === 'undefined' || !('Notification' in window)) {
    return 'unsupported';
  }

  return Notification.permission;
}

export async function requestNotificationPermission() {
  if (!isPushSupported()) {
    return 'unsupported';
  }

  return Notification.requestPermission();
}

export async function getCurrentPushSubscription() {
  if (!isPushSupported()) {
    return null;
  }

  const registration = await navigator.serviceWorker.ready;
  return registration.pushManager.getSubscription();
}

export async function subscribeToPush({ vapidPublicKey }) {
  if (!isPushSupported()) {
    throw new Error('Push notifications are not supported in this browser.');
  }

  if (!vapidPublicKey) {
    throw new Error('Push notifications are not configured yet.');
  }

  const registration = await navigator.serviceWorker.ready;
  const existingSubscription = await registration.pushManager.getSubscription();

  if (existingSubscription) {
    return existingSubscription;
  }

  return registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: base64UrlToUint8Array(vapidPublicKey),
  });
}

export async function registerPushSubscription(subscription) {
  const client = requireSupabase();
  const subscriptionJson = subscription?.toJSON?.() ?? {};
  const endpoint = subscription?.endpoint ?? subscriptionJson.endpoint;
  const p256dhKey = subscriptionJson.keys?.p256dh;
  const authKey = subscriptionJson.keys?.auth;

  if (!endpoint || !p256dhKey || !authKey) {
    throw new Error('Push subscription is incomplete.');
  }

  const { data, error } = await client.rpc('register_push_subscription', {
    p_endpoint: endpoint,
    p_p256dh_key: p256dhKey,
    p_auth_key: authKey,
    p_user_agent: typeof navigator === 'undefined' ? null : navigator.userAgent,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function disablePushSubscription(endpoint) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('disable_push_subscription', {
    p_endpoint: endpoint,
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function loadMyPushPreferences() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('get_my_push_preferences');

  if (error) {
    throw error;
  }

  return data;
}

export async function updateMyPushPreferences(preferences) {
  const client = requireSupabase();
  const { data, error } = await client.rpc('update_my_push_preferences', {
    p_notify_gvg: Boolean(preferences.notify_gvg),
    p_notify_cp_window: Boolean(preferences.notify_cp_window),
    p_notify_3v3: Boolean(preferences.notify_3v3),
    p_notify_wall_comments: Boolean(preferences.notify_wall_comments),
    p_notify_wall_reactions: Boolean(preferences.notify_wall_reactions),
    p_notify_profile_reactions: Boolean(preferences.notify_profile_reactions),
  });

  if (error) {
    throw error;
  }

  return data;
}

export async function createMyTestPushNotification() {
  const client = requireSupabase();
  const { data, error } = await client.rpc('create_my_test_push_notification');

  if (error) {
    throw error;
  }

  return data;
}
