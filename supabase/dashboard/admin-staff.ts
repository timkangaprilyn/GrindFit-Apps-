// Single-file copy of functions/admin-staff (policy.ts + index.ts) for the Supabase dashboard editor. Regenerate after edits.
// Trainer account management. Only a verified Firebase `admin: true` claim may call it.
type StaffRequest =
  | {action: 'list'}
  | {action: 'create'; email: string; displayName: string; password: string}
  | {action: 'set-disabled'; uid: string; disabled: boolean};

export function requireAdmin(claims: Record<string, unknown>): boolean {
  return claims.admin === true;
}

export function validateStaffRequest(input: unknown): StaffRequest {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid request');
  const v = input as Record<string, unknown>;
  if (v.action === 'list') return {action: 'list'};
  if (v.action === 'create') {
    const email = typeof v.email === 'string' ? v.email.trim().toLowerCase() : '';
    const displayName = typeof v.displayName === 'string' ? v.displayName.trim().replace(/\s+/g, ' ') : '';
    const password = typeof v.password === 'string' ? v.password : '';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254) throw new Error('Enter a valid email address.');
    if (displayName.length < 2 || displayName.length > 80 || /[\x00-\x1f]/.test(displayName)) throw new Error('Enter the trainer name (2–80 characters).');
    if (password.length < 12 || password.length > 128) throw new Error('Use a password with 12 to 128 characters.');
    if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) throw new Error('The password needs at least one letter and one number.');
    return {action: 'create', email, displayName, password};
  }
  if (v.action === 'set-disabled') {
    const uid = typeof v.uid === 'string' ? v.uid : '';
    if (!uid.length || uid.length > 128 || /[\x00-\x1f/]/.test(uid)) throw new Error('Choose a trainer account.');
    if (typeof v.disabled !== 'boolean') throw new Error('Choose whether to enable or disable access.');
    return {action: 'set-disabled', uid, disabled: v.disabled};
  }
  throw new Error('Unsupported action');
}

// Identity Toolkit stores custom claims as a JSON string.
export function parseClaims(customAttributes: unknown): Record<string, unknown> {
  if (typeof customAttributes !== 'string' || !customAttributes) return {};
  try {
    const parsed = JSON.parse(customAttributes);
    return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? parsed : {};
  } catch (_) {
    return {};
  }
}

// Merge the trainer claim into existing claims; never grants or removes admin.
export function withTrainerClaim(existing: Record<string, unknown>): string {
  const {admin: _admin, ...rest} = existing;
  return JSON.stringify({...rest, trainer: true});
}

// A trainer account the website may enable or disable: trainer claim, not admin.
export function isManagedTrainer(claims: Record<string, unknown>): boolean {
  return claims.trainer === true && claims.admin !== true;
}

export function trainerSummary(user: Record<string, unknown>) {
  const millis = (value: unknown) => {
    const n = Number(value);
    return Number.isFinite(n) && n > 0 ? new Date(n).toISOString() : null;
  };
  return {
    uid: String(user.localId ?? ''),
    email: String(user.email ?? ''),
    displayName: String(user.displayName ?? ''),
    disabled: user.disabled === true,
    createdAt: millis(user.createdAt),
    lastSignIn: millis(user.lastLoginAt),
  };
}

import { createRemoteJWKSet, importPKCS8, jwtVerify, SignJWT } from 'https://deno.land/x/jose@v5.9.6/index.ts';


const firebaseProject = 'grindfit-34b02';
const identity = `https://identitytoolkit.googleapis.com/v1/projects/${firebaseProject}`;
const jwks = createRemoteJWKSet(new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com'));
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...cors, 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
});

class ApiError extends Error {
  constructor(public status: number, message: string) { super(message); }
}

// Google OAuth token for the Firebase service account stored in the
// FIREBASE_SERVICE_ACCOUNT secret. The key never leaves this function.
let cachedToken: {value: string; expires: number} | null = null;
async function googleToken(): Promise<string> {
  if (cachedToken && cachedToken.expires > Date.now() + 60_000) return cachedToken.value;
  let account: {client_email?: string; private_key?: string; private_key_id?: string; project_id?: string};
  try { account = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? ''); } catch (_) { account = {}; }
  if (!account.client_email || !account.private_key || account.project_id !== firebaseProject) {
    throw new ApiError(503, 'Trainer management is not configured. Add the FIREBASE_SERVICE_ACCOUNT secret in Supabase.');
  }
  const key = await importPKCS8(account.private_key, 'RS256');
  const assertion = await new SignJWT({ scope: 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/identitytoolkit' })
    .setProtectedHeader({ alg: 'RS256', kid: account.private_key_id, typ: 'JWT' })
    .setIssuer(account.client_email).setSubject(account.client_email)
    .setAudience('https://oauth2.googleapis.com/token').setIssuedAt().setExpirationTime('1h')
    .sign(key);
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST', signal: AbortSignal.timeout(10000),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
  });
  if (!response.ok) { await response.body?.cancel(); throw new ApiError(503, 'Firebase rejected the service account. Check the FIREBASE_SERVICE_ACCOUNT secret.'); }
  const result = await response.json();
  cachedToken = { value: result.access_token, expires: Date.now() + Number(result.expires_in ?? 3600) * 1000 };
  return cachedToken.value;
}

async function firebase(path: string, body?: unknown, method = 'POST') {
  const response = await fetch(`${identity}${path}`, {
    method, signal: AbortSignal.timeout(10000),
    headers: { Authorization: `Bearer ${await googleToken()}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    const code = String(result?.error?.message ?? '');
    if (code.startsWith('EMAIL_EXISTS') || code.startsWith('DUPLICATE_EMAIL')) throw new ApiError(409, 'An account with this email already exists. No account was changed.');
    if (code.startsWith('USER_NOT_FOUND')) throw new ApiError(404, 'That account no longer exists.');
    if (code.startsWith('WEAK_PASSWORD')) throw new ApiError(400, 'Firebase rejected this password as too weak.');
    if (code.startsWith('INVALID_EMAIL')) throw new ApiError(400, 'Enter a valid email address.');
    if (response.status === 401 || response.status === 403) throw new ApiError(503, 'The Firebase service account cannot manage users. Check its permissions.');
    throw new ApiError(502, 'Firebase could not complete the request. Try again.');
  }
  return result;
}

const getUser = async (uid: string) => {
  const result = await firebase('/accounts:lookup', { localId: [uid] });
  const user = result.users?.[0];
  if (!user) throw new ApiError(404, 'That account no longer exists.');
  return user;
};

async function listTrainers() {
  const trainers = [];
  let pageToken = '';
  do {
    const params = new URLSearchParams({ maxResults: '1000' });
    if (pageToken) params.set('nextPageToken', pageToken);
    const page = await firebase(`/accounts:batchGet?${params}`, undefined, 'GET');
    for (const user of page.users ?? []) {
      if (parseClaims(user.customAttributes).trainer === true) trainers.push(trainerSummary(user));
    }
    pageToken = page.nextPageToken ?? '';
  } while (pageToken);
  trainers.sort((a, b) => (a.displayName || a.email).localeCompare(b.displayName || b.email));
  return { trainers };
}

async function createTrainer(email: string, displayName: string, password: string) {
  const existing = await firebase('/accounts:lookup', { email: [email] });
  if (existing.users?.length) throw new ApiError(409, 'An account with this email already exists. No account was changed.');
  // Created disabled; enabled only after the trainer claim is saved.
  const created = await firebase('/accounts', { email, password, displayName, disabled: true, emailVerified: false });
  const uid = created.localId;
  await firebase('/accounts:update', { localId: uid, customAttributes: withTrainerClaim({}) });
  await firebase('/accounts:update', { localId: uid, disableUser: false });
  const verified = await getUser(uid);
  if (parseClaims(verified.customAttributes).trainer !== true || verified.disabled === true) {
    throw new ApiError(502, 'The account was created but not fully verified. It was left disabled; check Firebase Authentication.');
  }
  return { uid, email, displayName };
}

async function setDisabled(callerUid: string, uid: string, disabled: boolean) {
  if (uid === callerUid) throw new ApiError(400, 'You cannot change your own account here.');
  const user = await getUser(uid);
  if (!isManagedTrainer(parseClaims(user.customAttributes))) throw new ApiError(400, 'Only trainer accounts can be changed here.');
  const update: Record<string, unknown> = { localId: uid, disableUser: disabled };
  // Revoke existing sessions when disabling.
  if (disabled) update.validSince = String(Math.floor(Date.now() / 1000));
  await firebase('/accounts:update', update);
  return trainerSummary(await getUser(uid));
}

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
    if (!requireAdmin(payload)) return json({ error: 'Admin access required' }, 403);
    uid = payload.sub;
  } catch (_) {
    return json({ error: 'Invalid or expired Firebase session' }, 401);
  }
  let input;
  try {
    const text = await req.text();
    if (text.length > 4096) return json({ error: 'Body too large' }, 413);
    input = validateStaffRequest(JSON.parse(text));
  } catch (error) {
    return json({ error: error instanceof SyntaxError ? 'Invalid request' : (error as Error).message }, 400);
  }
  try {
    if (input.action === 'list') return json(await listTrainers());
    if (input.action === 'create') return json(await createTrainer(input.email, input.displayName, input.password));
    return json(await setDisabled(uid, input.uid, input.disabled));
  } catch (error) {
    if (error instanceof ApiError) return json({ error: error.message }, error.status);
    console.error('admin-staff failed', (error as Error)?.message);
    return json({ error: 'Could not complete the staff account request.' }, 500);
  }
});
