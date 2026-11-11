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
