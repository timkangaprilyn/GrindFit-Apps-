// Trainer account management. Only a verified Firebase `admin: true` claim may call it.
export type StaffRequest =
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
