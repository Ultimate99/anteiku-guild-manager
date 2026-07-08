function secretsMatch(candidate: string, expected: string): boolean {
  const candidateBytes = new TextEncoder().encode(candidate);
  const expectedBytes = new TextEncoder().encode(expected);

  if (candidateBytes.length !== expectedBytes.length) {
    return false;
  }

  let mismatch = 0;

  for (let index = 0; index < candidateBytes.length; index += 1) {
    mismatch |= candidateBytes[index] ^ expectedBytes[index];
  }

  return mismatch === 0;
}

export function isAuthorizedSender(request: Request, expectedSecret: string): boolean {
  const authorization = request.headers.get('authorization')?.trim() ?? '';
  const bearerMatch = authorization.match(/^Bearer\s+(.+)$/i);
  const bearerSecret = bearerMatch?.[1]?.trim() ?? '';
  const cronSecret = request.headers.get('x-cron-secret')?.trim() ?? '';

  return secretsMatch(bearerSecret, expectedSecret) || secretsMatch(cronSecret, expectedSecret);
}
