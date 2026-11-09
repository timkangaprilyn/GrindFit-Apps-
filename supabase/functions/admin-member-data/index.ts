import { createRemoteJWKSet, jwtVerify } from 'https://deno.land/x/jose@v5.9.6/index.ts';
import { requireAdmin, validateAdminRequest } from './policy.ts';

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
    if (!requireAdmin(payload)) return json({error: 'Admin access required'}, 403);
    uid = payload.sub;
  } catch (_) {
    return json({ error: 'Invalid or expired Firebase session' }, 401);
  }
  let input: {action: string; memberUid?: string};
  try {
    const reader = req.body?.getReader();
    if (!reader) throw new Error('Missing body');
    let text = ''; let size = 0;
    const decoder = new TextDecoder();
    while (true) {
      const {value, done} = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 4096) { await reader.cancel(); return json({error:'Body too large'},413); }
      text += decoder.decode(value, {stream:true});
    }
    text += decoder.decode();
    input = validateAdminRequest(JSON.parse(text));
  } catch (_) { return json({error:'Invalid admin read request'},400); }
  const url = Deno.env.get('SUPABASE_URL');
  const key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key) return json({error:'Backend not configured'},503);
  const headers = {apikey:key,Authorization:`Bearer ${key}`};
  const read = async (table: string, columns: string, order: string, limit: number) => {
    const params = new URLSearchParams({select:columns,limit:String(limit)});
    if (input.action === 'member') {
      params.set('firebase_uid', `eq.${input.memberUid}`);
      params.set('order', order);
    }
    try {
      const result = await fetch(`${url}/rest/v1/${table}?${params}`,{headers,signal:AbortSignal.timeout(10000)});
      if (!result.ok) { await result.body?.cancel(); return {available:false,rows:[]}; }
      return {available:true,rows:await result.json()};
    } catch (_) { return {available:false,rows:[]}; }
  };
  const [analytics, meals] = await Promise.all([
    read('analytics_snapshots','local_date,metrics,updated_at','local_date.desc',input.action === 'status' ? 0 : 7),
    read('meal_preferences','preferences,updated_at','updated_at.desc',input.action === 'status' ? 0 : 1),
  ]);
  return json({analytics, meals});
});