import { createRemoteJWKSet, jwtVerify } from 'https://deno.land/x/jose@v5.9.6/index.ts';
import { validateSnapshot } from './policy.ts';

const firebaseProject = 'grindfit-34b02';
const jwks = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });
  if (req.method !== 'POST') return json({ error: 'Method not allowed' }, 405);
  const token = req.headers.get('Authorization')?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return json({ error: 'Sign in required' }, 401);
  let uid: string;
  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${firebaseProject}`,
      audience: firebaseProject, algorithms: ['RS256'], requiredClaims: ['exp', 'iat', 'sub', 'auth_time'],
    });
    if (!payload.sub || payload.sub.length > 128 || typeof payload.iat !== 'number' || payload.iat > Date.now() / 1000 + 60) throw new Error('Invalid subject');
    uid = payload.sub;
  } catch (_) {
    return json({ error: 'Invalid or expired Firebase session' }, 401);
  }
  let metrics: Record<string, unknown>;
  try {
    // Read with a hard byte limit, including requests without Content-Length.
    const reader = req.body?.getReader();
    if (!reader) throw new Error('Missing body');
    const chunks: Uint8Array[] = [];
    let size = 0;
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 8192) { await reader.cancel(); return json({ error: 'Body too large' }, 413); }
      chunks.push(value);
    }
    const buffer = new Uint8Array(size);
    let offset = 0;
    for (const chunk of chunks) { buffer.set(chunk, offset); offset += chunk.length; }
    metrics = validateSnapshot(JSON.parse(new TextDecoder().decode(buffer)));
  } catch (_) {
    return json({ error: 'Invalid analytics snapshot' }, 400);
  }
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return json({ error: 'Analytics backend not configured' }, 503);
  try {
    const updatedAt = new Date().toISOString();
    const result = await fetch(`${url}/rest/v1/analytics_snapshots?on_conflict=firebase_uid,local_date`, {
      method: 'POST',
      headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Prefer: 'resolution=merge-duplicates,return=representation' },
      body: JSON.stringify({ firebase_uid: uid, local_date: metrics.local_date, metrics, updated_at: updatedAt }),
      signal: AbortSignal.timeout(10000),
    });
    if (!result.ok) { await result.body?.cancel(); return json({ error: 'Could not save analytics' }, 503); }
    const saved = await result.json();
    if (!saved[0]?.updated_at) return json({ error: 'Save not confirmed' }, 503);
    return json({ updated_at: saved[0].updated_at });
  } catch (_) {
    return json({ error: 'Could not save analytics' }, 503);
  }
});
