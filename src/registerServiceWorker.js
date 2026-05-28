const UPDATE_DISMISSED_KEY = 'anteiku_pwa_update_dismissed';

function hasDismissedUpdate() {
  try {
    return sessionStorage.getItem(UPDATE_DISMISSED_KEY) === 'true';
  } catch {
    return false;
  }
}

function dismissUpdateForSession() {
  try {
    sessionStorage.setItem(UPDATE_DISMISSED_KEY, 'true');
  } catch {
    // Ignore storage failures; the banner can still dismiss in the DOM.
  }
}

function showUpdateBanner(registration, onUpdate) {
  if (!registration.waiting || hasDismissedUpdate() || document.querySelector('[data-pwa-update-banner]')) {
    return;
  }

  const banner = document.createElement('aside');
  banner.className = 'pwa-update-banner';
  banner.dataset.pwaUpdateBanner = 'true';
  banner.setAttribute('role', 'status');
  banner.setAttribute('aria-live', 'polite');

  const copy = document.createElement('div');
  copy.className = 'pwa-update-copy';

  const title = document.createElement('strong');
  title.textContent = 'New version available';

  const body = document.createElement('span');
  body.textContent = 'Update now to get the latest app changes.';

  copy.append(title, body);

  const actions = document.createElement('div');
  actions.className = 'pwa-update-actions';

  const updateButton = document.createElement('button');
  updateButton.type = 'button';
  updateButton.className = 'pwa-update-primary';
  updateButton.textContent = 'Update App';

  const laterButton = document.createElement('button');
  laterButton.type = 'button';
  laterButton.className = 'pwa-update-secondary';
  laterButton.textContent = 'Later';

  actions.append(updateButton, laterButton);
  banner.append(copy, actions);
  document.body.append(banner);

  laterButton.addEventListener('click', () => {
    dismissUpdateForSession();
    banner.remove();
  });

  updateButton.addEventListener('click', () => {
    updateButton.disabled = true;
    laterButton.disabled = true;
    onUpdate();
    registration.waiting?.postMessage({ type: 'SKIP_WAITING' });
  });
}

export function registerServiceWorker() {
  if (!import.meta.env.PROD || !('serviceWorker' in navigator)) {
    return;
  }

  window.addEventListener('load', () => {
    let updateRequested = false;

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (updateRequested) {
        window.location.reload();
      }
    });

    navigator.serviceWorker
      .register('/sw.js')
      .then((registration) => {
        if (registration.waiting && navigator.serviceWorker.controller) {
          showUpdateBanner(registration, () => {
            updateRequested = true;
          });
        }

        registration.addEventListener('updatefound', () => {
          const installingWorker = registration.installing;

          if (!installingWorker) {
            return;
          }

          installingWorker.addEventListener('statechange', () => {
            if (installingWorker.state === 'installed' && navigator.serviceWorker.controller) {
              showUpdateBanner(registration, () => {
                updateRequested = true;
              });
            }
          });
        });
      })
      .catch((error) => {
        console.warn('Service worker registration failed.', error);
      });
  });
}
