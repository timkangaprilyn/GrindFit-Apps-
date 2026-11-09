export function validateSnapshot(input: unknown, now = new Date()): Record<string, unknown> {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid body');
  const v = input as Record<string, unknown>;
  const date = typeof v.local_date === 'string' ? v.local_date : '';
  const parsed = new Date(`${date}T00:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) ||
      parsed.toISOString().slice(0, 10) !== date ||
      Math.abs(parsed.getTime() - now.getTime()) > 2 * 86400000) throw new Error('Invalid local date');
  const integer = (key: string, min: number, max: number, nullable = false) => {
    const x = v[key];
    if (nullable && x === null) return null;
    if (typeof x !== 'number' || !Number.isInteger(x) || x < min || x > max) throw new Error(`Invalid ${key}`);
    return x;
  };
  const decimal = (key: string, min: number, max: number) => {
    const x = v[key];
    if (x === null) return null;
    if (typeof x !== 'number' || !Number.isFinite(x) || x < min || x > max) throw new Error(`Invalid ${key}`);
    return x;
  };
  if (v.algorithm_version !== 1 || typeof v.can_forecast !== 'boolean') throw new Error('Invalid version or forecast flag');
  const scheduled = integer('scheduled_days', 0, 28)!;
  const completed = integer('completed_days', 0, scheduled)!;
  const consistency = decimal('consistency', 0, 1);
  if ((scheduled === 0 && consistency !== null) || (scheduled > 0 &&
      (consistency === null || Math.abs(consistency - completed / scheduled) > 1e-9))) throw new Error('Invalid consistency');
  const next = decimal('next_week_estimate', 0, 7);
  const month = decimal('month_estimate', 0, 31);
  if ((!v.can_forecast && (next !== null || month !== null)) ||
      (v.can_forecast && (scheduled < 4 || next === null || month === null))) throw new Error('Invalid forecast');
  if (typeof v.basis !== 'string' || v.basis.length > 300) throw new Error('Invalid basis');
  // Allowlist fields: never accept a caller-supplied owner, timestamp or extra PII.
  return {
    local_date: date, algorithm_version: 1,
    scheduled_days: scheduled, completed_days: completed, consistency,
    can_forecast: v.can_forecast, next_week_estimate: next, month_estimate: month,
    month_completed: integer('month_completed', 0, 31), month_target: integer('month_target', 0, 31),
    session_change: integer('session_change', -100000, 100000, true),
    minute_change: integer('minute_change', -10000000, 10000000, true), basis: v.basis,
  };
}

import { createRemoteJWKSet, jwtVerify } from 'https://deno.land/x/jose@v5.9.6/index.ts';


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
