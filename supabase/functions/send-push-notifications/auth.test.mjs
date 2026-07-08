import assert from 'node:assert/strict';
import test from 'node:test';

import { isAuthorizedSender } from './auth.ts';

const secret = 'local-test-push-sender-secret';

test('accepts the configured bearer secret', () => {
  const request = new Request('http://localhost', {
    headers: {
      Authorization: `Bearer ${secret}`,
    },
  });

  assert.equal(isAuthorizedSender(request, secret), true);
});

test('accepts the bearer scheme case-insensitively', () => {
  const request = new Request('http://localhost', {
    headers: {
      Authorization: `bearer ${secret}`,
    },
  });

  assert.equal(isAuthorizedSender(request, secret), true);
});

test('accepts the configured cron secret', () => {
  const request = new Request('http://localhost', {
    headers: {
      'x-cron-secret': secret,
    },
  });

  assert.equal(isAuthorizedSender(request, secret), true);
});

test('rejects missing or incorrect credentials', () => {
  const missingRequest = new Request('http://localhost');
  const incorrectRequest = new Request('http://localhost', {
    headers: {
      Authorization: 'Bearer wrong-secret',
      'x-cron-secret': 'also-wrong',
    },
  });

  assert.equal(isAuthorizedSender(missingRequest, secret), false);
  assert.equal(isAuthorizedSender(incorrectRequest, secret), false);
});

test('accepts either valid credential when both headers are present', () => {
  const request = new Request('http://localhost', {
    headers: {
      Authorization: 'Bearer wrong-secret',
      'x-cron-secret': secret,
    },
  });

  assert.equal(isAuthorizedSender(request, secret), true);
});
