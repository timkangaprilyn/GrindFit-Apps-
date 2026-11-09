export function requireAdmin(claims: Record<string, unknown>): boolean {
  return claims.admin === true;
}

export function validateAdminRequest(input: unknown): {action: string; memberUid?: string} {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid request');
  const v = input as Record<string, unknown>;
  if (v.action === 'status') return {action: 'status'};
  if (v.action !== 'member' || typeof v.member_uid !== 'string' || !v.member_uid.length || v.member_uid.length > 128 || /[\x00-\x1f]/.test(v.member_uid)) throw new Error('Invalid member');
  return {action: 'member', memberUid: v.member_uid};
}
