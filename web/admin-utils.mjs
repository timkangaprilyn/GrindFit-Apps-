export function memberPage(members, {search = '', filter = 'all', sort = 'recent', inactiveDays = 14, page = 1, pageSize = 12, now = new Date()} = {}) {
  const cutoff = now.getTime() - inactiveDays * 86400000;
  const matching = members.filter((m) => {
    if (filter === 'risk' && !m.injuryAlert && !m.recoveryAlert) return false;
    if (filter === 'inactive' && m.lastWorkout && m.lastWorkout.getTime() >= cutoff) return false;
    return `${m.fullName ?? ''} ${m.email ?? ''} ${m.fitnessGoal ?? ''}`.toLowerCase().includes(search.trim().toLowerCase());
  }).sort((a, b) => {
    if (sort === 'name') return String(a.fullName ?? '').localeCompare(String(b.fullName ?? ''));
    if (sort === 'weekly') return b.weeklyCount - a.weeklyCount;
    if (sort === 'risk') return Number(!!(b.injuryAlert || b.recoveryAlert)) - Number(!!(a.injuryAlert || a.recoveryAlert));
    return (b.lastWorkout?.getTime() ?? 0) - (a.lastWorkout?.getTime() ?? 0);
  });
  const pages = Math.max(1, Math.ceil(matching.length / pageSize));
  const current = Math.max(1, Math.min(pages, page));
  return {items: matching.slice((current - 1) * pageSize, current * pageSize), total: matching.length, page: current, pages, pageSize};
}

// Where a signed-in account belongs, based on trusted Firebase custom claims.
export function staffHome(claims = {}) {
  if (claims.admin === true) return 'admin.html';
  if (claims.trainer === true) return 'trainer.html';
  return null;
}

// null when the account may stay on this portal; otherwise the page to go to.
export function portalRedirect(portal, claims = {}) {
  if (portal === 'admin' && claims.admin === true) return null;
  if (portal === 'trainer' && claims.trainer === true) return null;
  return staffHome(claims) ?? 'login.html?denied=1';
}

export function csvCell(value) {
  let field = String(value ?? '');
  if (/^[\s]*[=+\-@]/u.test(field) || /^[\t\r\n]/u.test(field)) field = `'${field}`;
  return `"${field.replaceAll('"', '""')}"`;
}

export function reportRange(preset, now = new Date()) {
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const start = new Date(end);
  if (preset === 'month') start.setDate(1);
  else start.setDate(start.getDate() - (Number(preset) - 1));
  const local = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  return {from: local(start), to: local(end)};
}

// A password still equal to the one set when the account was created
// (by create-admin.ps1 or the Trainers page) must be replaced before use.
// `account` is an Identity Toolkit accounts:lookup user record.
export const INITIAL_PASSWORD_WINDOW_MS = 10 * 60 * 1000;
export function mustChangePassword(account) {
  if (!account || !Array.isArray(account.providerUserInfo)) return false;
  if (!account.providerUserInfo.some((p) => p?.providerId === 'password')) return false;
  const created = Number(account.createdAt);
  const updated = Number(account.passwordUpdatedAt);
  if (!Number.isFinite(created) || created <= 0) return false;
  if (!Number.isFinite(updated) || updated <= 0) return true;
  return updated - created < INITIAL_PASSWORD_WINDOW_MS;
}

// Returns an error message, or '' when the new password is acceptable.
export function newPasswordProblem(next, confirm, current = '') {
  if (typeof next !== 'string' || next.length < 12) return 'Use at least 12 characters.';
  if (next.length > 128) return 'Use at most 128 characters.';
  if (!/[A-Za-z]/.test(next) || !/\d/.test(next)) return 'Include at least one letter and one number.';
  if (next === current) return 'Choose a password different from the one you were given.';
  if (next !== confirm) return 'The new passwords do not match.';
  return '';
}

const escapeAvatarText = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));

/** Up to two initials from a member's name (or email), e.g. "Juan Dela Cruz" → "JD". */
export function memberInitials(name) {
  const parts = String(name ?? '').trim().split(/[\s@._-]+/).filter(Boolean);
  if (!parts.length) return 'M';
  return (parts.length > 1 ? parts[0][0] + parts[1][0] : parts[0].slice(0, 2)).toUpperCase();
}

/**
 * Avatar for a member: their Google profile photo when the app saved one
 * (users/{uid}.photoUrl, https only), over their initials, which stay visible
 * if the photo is missing or fails to load.
 */
export function memberAvatarHtml(member = {}, {size = '', name} = {}) {
  const label = name ?? member.fullName ?? member.memberName ?? member.email ?? 'Member';
  const initials = escapeAvatarText(memberInitials(label));
  const photo = typeof member.photoUrl === 'string' && /^https:\/\//i.test(member.photoUrl) ? member.photoUrl : '';
  const image = photo
    ? `<img src="${escapeAvatarText(photo)}" alt="" loading="lazy" referrerpolicy="no-referrer" onerror="this.remove()">`
    : '';
  return `<span class="member-avatar${size ? ` ${size}` : ''}${photo ? ' has-photo' : ''}" aria-hidden="true"><span>${initials}</span>${image}</span>`;
}
