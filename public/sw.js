const CACHE_NAME = 'anteiku-static-v2';
const APP_SHELL_URLS = [
  '/',
  '/index.html',
  '/manifest.webmanifest',
  '/anteiku-mark.svg',
  '/icons/icon-192.png',
  '/icons/icon-512.png',
  '/icons/maskable-512.png',
  '/icons/apple-touch-icon.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches
      .open(CACHE_NAME)
      .then((cache) => cache.addAll(APP_SHELL_URLS)),
  );
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((cacheNames) =>
        Promise.all(cacheNames.filter((cacheName) => cacheName !== CACHE_NAME).map((cacheName) => caches.delete(cacheName))),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);

  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          const responseCopy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put('/', responseCopy));
          return response;
        })
        .catch(() => caches.match('/')),
    );
    return;
  }

  const cacheableStaticPath =
    requestUrl.pathname.startsWith('/assets/') ||
    requestUrl.pathname.startsWith('/icons/') ||
    requestUrl.pathname === '/anteiku-mark.svg' ||
    requestUrl.pathname === '/manifest.webmanifest';

  if (!cacheableStaticPath) {
    return;
  }

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }

      return fetch(event.request).then((response) => {
        if (response.ok) {
          const responseCopy = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseCopy));
        }

        return response;
      });
    }),
  );
});

function sanitizeNotificationRoute(route) {
  if (typeof route !== 'string' || !route.startsWith('/') || route.startsWith('//') || /\s/.test(route)) {
    return '/';
  }

  return route;
}

function readPushPayload(event) {
  if (!event.data) {
    return {};
  }

  try {
    return event.data.json();
  } catch {
    return {
      body: event.data.text(),
    };
  }
}

self.addEventListener('push', (event) => {
  const payload = readPushPayload(event);
  const title = typeof payload.title === 'string' && payload.title.trim()
    ? payload.title.trim().slice(0, 80)
    : 'Anteiku Guild Manager';
  const body = typeof payload.body === 'string' ? payload.body.trim().slice(0, 160) : '';
  const route = sanitizeNotificationRoute(payload.route);

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      icon: '/icons/icon-192.png',
      badge: '/icons/icon-192.png',
      data: {
        route,
      },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const route = sanitizeNotificationRoute(event.notification.data?.route);
  const targetUrl = new URL(route, self.location.origin).href;

  event.waitUntil(
    self.clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((clientList) => {
        const sameOriginClient = clientList.find((client) => new URL(client.url).origin === self.location.origin);

        if (sameOriginClient) {
          sameOriginClient.focus();
          return sameOriginClient.navigate(targetUrl);
        }

        return self.clients.openWindow(targetUrl);
      }),
  );
});
