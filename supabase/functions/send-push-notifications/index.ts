import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.8';
import webpush from 'npm:web-push@3.6.7';

type PushOutboxRow = {
  id: string;
  recipient_profile_id: string;
  type: string;
  title: string;
  body: string;
  route: string | null;
  attempt_count: number;
};

type PushSubscriptionRow = {
  id: string;
  endpoint: string;
  p256dh_key: string;
  auth_key: string;
};

const MAX_BATCH_SIZE = 25;
const MAX_ATTEMPTS = 5;
const SAFE_NOTIFICATION_TYPES = new Set([
  'gvg_event_opened',
  'cp_window_opened',
  'three_v_three_join_request_received',
  'three_v_three_request_approved',
  'three_v_three_request_declined',
  'wall_comment_on_post',
  'self_test',
]);

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();

  if (!value) {
    throw new Error(`${name} is required.`);
  }

  return value;
}

function safeRoute(route: string | null): string {
  if (!route || !route.startsWith('/') || route.startsWith('//') || /\s/.test(route)) {
    return '/';
  }

  return route;
}

function buildNotificationPayload(row: PushOutboxRow): string {
  if (!SAFE_NOTIFICATION_TYPES.has(row.type)) {
    throw new Error(`Unsafe notification type: ${row.type}`);
  }

  return JSON.stringify({
    type: row.type,
    title: row.title,
    body: row.body,
    route: safeRoute(row.route),
  });
}

async function markOutboxRow(supabase: ReturnType<typeof createClient>, row: PushOutboxRow, result: { sent: boolean; error?: string }) {
  const updatePayload = result.sent
    ? {
        sent_at: new Date().toISOString(),
        failed_at: null,
        last_error: null,
        attempt_count: row.attempt_count + 1,
      }
    : {
        failed_at: new Date().toISOString(),
        last_error: (result.error || 'Unknown push send failure.').slice(0, 1000),
        attempt_count: row.attempt_count + 1,
      };

  const { error } = await supabase
    .from('push_notification_outbox')
    .update(updatePayload)
    .eq('id', row.id);

  if (error) {
    throw error;
  }
}

async function disableSubscription(supabase: ReturnType<typeof createClient>, subscriptionId: string) {
  await supabase
    .from('push_subscriptions')
    .update({
      disabled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', subscriptionId);
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed.' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  let supabase;

  try {
    const supabaseUrl = requireEnv('SUPABASE_URL');
    const serviceRoleKey = requireEnv('SUPABASE_SERVICE_ROLE_KEY');
    const vapidPublicKey = requireEnv('VAPID_PUBLIC_KEY');
    const vapidPrivateKey = requireEnv('VAPID_PRIVATE_KEY');
    const vapidSubject = requireEnv('VAPID_SUBJECT');

    webpush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);

    supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : 'Push sender configuration is incomplete.',
      }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  const { data: outboxRows, error: outboxError } = await supabase
    .from('push_notification_outbox')
    .select('id, recipient_profile_id, type, title, body, route, attempt_count')
    .is('sent_at', null)
    .is('failed_at', null)
    .lt('attempt_count', MAX_ATTEMPTS)
    .order('created_at', { ascending: true })
    .limit(MAX_BATCH_SIZE);

  if (outboxError) {
    return new Response(JSON.stringify({ error: outboxError.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const results = [];

  for (const row of (outboxRows ?? []) as PushOutboxRow[]) {
    const { data: subscriptions, error: subscriptionError } = await supabase
      .from('push_subscriptions')
      .select('id, endpoint, p256dh_key, auth_key')
      .eq('profile_id', row.recipient_profile_id)
      .is('disabled_at', null);

    if (subscriptionError) {
      await markOutboxRow(supabase, row, { sent: false, error: subscriptionError.message });
      results.push({ id: row.id, sent: false, error: subscriptionError.message });
      continue;
    }

    if (!subscriptions || subscriptions.length === 0) {
      await markOutboxRow(supabase, row, { sent: false, error: 'No active push subscriptions.' });
      results.push({ id: row.id, sent: false, error: 'No active push subscriptions.' });
      continue;
    }

    let sentCount = 0;
    const errors: string[] = [];
    const payload = buildNotificationPayload(row);

    for (const subscription of subscriptions as PushSubscriptionRow[]) {
      try {
        await webpush.sendNotification(
          {
            endpoint: subscription.endpoint,
            keys: {
              p256dh: subscription.p256dh_key,
              auth: subscription.auth_key,
            },
          },
          payload,
        );
        sentCount += 1;
      } catch (error) {
        const statusCode = typeof error === 'object' && error !== null && 'statusCode' in error
          ? Number((error as { statusCode?: unknown }).statusCode)
          : 0;
        const message = error instanceof Error ? error.message : 'Push send failed.';

        errors.push(message);

        if (statusCode === 404 || statusCode === 410) {
          await disableSubscription(supabase, subscription.id);
        }
      }
    }

    const sent = sentCount > 0;
    await markOutboxRow(supabase, row, {
      sent,
      error: sent ? undefined : errors.join('; ') || 'Push send failed for all active subscriptions.',
    });

    results.push({
      id: row.id,
      sent,
      sentCount,
      error: sent ? null : errors.join('; '),
    });
  }

  return new Response(
    JSON.stringify({
      processed: results.length,
      results,
    }),
    {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    },
  );
});
