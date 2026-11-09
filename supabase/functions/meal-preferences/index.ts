import { createRemoteJWKSet, jwtVerify } from 'https://deno.land/x/jose@v5.9.6/index.ts';
import { validatePreferences } from './policy.ts';

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
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return json({ error: 'Meal preferences backend not configured' }, 503);
  let input: Record<string, unknown>;
  try {
    const reader = req.body?.getReader();
    if (!reader) throw new Error('Missing body');
    let text = ''; let size = 0;
    const decoder = new TextDecoder();
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 8192) { await reader.cancel(); return json({error: 'Body too large'}, 413); }
      text += decoder.decode(value, {stream: true});
    }
    text += decoder.decode();
    input = JSON.parse(text);
    if (!input || (input.action !== 'read' && input.action !== 'save')) throw new Error('Invalid action');
  } catch (_) { return json({error: 'Invalid request'}, 400); }
  const headers: Record<string, string> = {apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json'};
  try {
    if (input.action === 'read') {
      const result = await fetch(`${url}/rest/v1/meal_preferences?firebase_uid=eq.${encodeURIComponent(uid)}&select=preferences,updated_at&limit=1`, {headers, signal: AbortSignal.timeout(10000)});
      if (!result.ok) { await result.body?.cancel(); return json({error: 'Could not load preferences'}, 503); }
      const rows = await result.json();
      return json(rows[0] ?? {preferences: null});
    }
    let preferences: Record<string, unknown>;
    try { preferences = validatePreferences(input.preferences); }
    catch (_) { return json({error: 'Invalid meal preferences'}, 400); }
    headers.Prefer = 'resolution=merge-duplicates,return=representation';
    const result = await fetch(`${url}/rest/v1/meal_preferences?on_conflict=firebase_uid`, {
      method: 'POST', headers,
      body: JSON.stringify({firebase_uid: uid, preferences, updated_at: new Date().toISOString()}),
      signal: AbortSignal.timeout(10000),
    });
    if (!result.ok) { await result.body?.cancel(); return json({error: 'Could not save preferences'}, 503); }
    const rows = await result.json();
    if (!rows[0]?.updated_at) return json({error: 'Save not confirmed'}, 503);
    return json({updated_at: rows[0].updated_at});
  } catch (_) { return json({error: 'Meal preferences unavailable'}, 503); }
});