import {memberPage, reportRange} from './admin-utils.mjs';
import {setupInterface, renderExtras} from './admin-interface.js';

// This module never imports Firebase or contacts a member-data API.
const $ = (id) => document.getElementById(id);
const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (c) => ({'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'}[c]));
const now = new Date();
const formatDate = (d) => d ? new Intl.DateTimeFormat('en-PH', {month: 'short', day: 'numeric'}).format(d) : 'No workout';
const goals = ['Muscle Gain / Strength', 'Weight Loss / Maintenance', 'General Fitness'];
const members = Array.from({length: 20}, (_, i) => {
  const workouts = Array.from({length: 3}, (_, w) => ({title: ['Full body session', 'Upper body strength', 'Mobility & recovery'][w], timestamp: new Date(now.getFullYear(), now.getMonth(), now.getDate() - (i + w * 5) % 28, 8)}));
  const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (now.getDay() + 6) % 7);
  return {id: `sample-${i}`, fullName: `Sample Member ${String(i + 1).padStart(2, '0')}`, email: `member${i + 1}@example.com`, fitnessGoal: goals[i % goals.length], createdAt: new Date(now.getFullYear(),now.getMonth(),now.getDate()-i*3), workouts, lastWorkout: workouts[0].timestamp, weeklyCount: workouts.filter((w) => w.timestamp >= monday).length, injuryAlert: i % 7 === 0, recoveryAlert: false};
});
let page = 1;
function openMember(id) {
  const member = members.find((m) => m.id === id);
  $('detailName').textContent = member.fullName;
  $('detailSummary').innerHTML = `<div class="detail-cell"><span>Sample goal</span><strong>${escapeHtml(member.fitnessGoal)}</strong></div><div class="detail-cell"><span>This week</span><strong>${member.weeklyCount} sample sessions</strong></div>`;
  $('detailAlerts').textContent = 'Fictional sample profile. No live member data is loaded.';
  $('coachPanel').hidden = true;
  $('cloudMemberPanel').hidden = true;
  $('detailWorkouts').innerHTML = member.workouts.map((w) => `<div class="detail-workout"><strong>${w.title}</strong><p>${formatDate(w.timestamp)} · Sample session</p></div>`).join('');
  $('memberDialog').showModal();
}
function renderMembers() {
  const result = memberPage(members, {page, search: $('memberSearch').value, filter: $('memberFilter').value, sort: $('memberSort').value});
  page = result.page;
  $('memberRows').innerHTML = result.items.map((m) => `<tr data-id="${m.id}"><td><button class="member-open"><div class="member-name">${m.fullName}</div><div class="member-email">${m.email}</div></button></td><td>${m.fitnessGoal}</td><td>${formatDate(m.lastWorkout)}</td><td>${m.weeklyCount}</td><td><span class="badge ${m.injuryAlert ? 'alert' : 'clear'}">${m.injuryAlert ? 'Review' : 'None'}</span></td></tr>`).join('') || '<tr><td colspan="5">No matching sample members.</td></tr>';
  $('memberRows').querySelectorAll('[data-id]').forEach((row) => row.addEventListener('click', () => openMember(row.dataset.id)));
  $('memberCount').textContent = `${result.total} matching sample members`;
  $('pageNumber').textContent = `Page ${page} of ${result.pages}`;
  $('previousPage').disabled = page <= 1; $('nextPage').disabled = page >= result.pages;
}
function renderDashboard() {
  const active = members.filter((m) => now - m.lastWorkout < 14 * 86400000).length;
  $('totalMembers').textContent = members.length;
  $('activeMembers').textContent = active;
  $('retentionRate').textContent = `${Math.round(active / members.length * 100)}%`;
  $('retentionFormula').textContent = `${active} active / ${members.length} sample members`;
  $('weeklyWorkouts').textContent = members.reduce((sum, m) => sum + m.weeklyCount, 0);
  const monday = new Date(now.getFullYear(), now.getMonth(), now.getDate() - (now.getDay() + 6) % 7);
  const weeks = Array.from({length: 4}, (_, i) => {
    const start = new Date(monday); start.setDate(start.getDate() - (3 - i) * 7);
    const end = new Date(start); end.setDate(end.getDate() + 7);
    return {start, count: members.flatMap((m) => m.workouts).filter((w) => w.timestamp >= start && w.timestamp < end).length};
  });
  const max = Math.max(4, ...weeks.map((w) => w.count));
  $('activityChart').innerHTML = `<div class="chart-y-axis"><span>${max}</span><span>${Math.round(max / 2)}</span><span>0</span></div><div class="chart-series">${weeks.map((w) => `<div class="chart-column"><div class="chart-plot"><b class="chart-value" style="bottom:calc(${w.count / max * 100}% + 3px)">${w.count}</b><div class="chart-bar" style="height:${w.count / max * 100}%"></div></div><span>Week of ${formatDate(w.start)}</span></div>`).join('')}</div>`;
  $('riskSummary').innerHTML = '<div class="risk-list"><div class="risk-row"><strong>Sample Member 01</strong><span>Sample profile has a health note for staff review.</span></div><div class="risk-row"><strong>Sample Member 08</strong><span>Sample profile has a health note for staff review.</span></div></div>';
  $('lastUpdated').textContent = 'Design preview · fictional sample data';
  renderExtras(members, {escapeHtml, workoutDate: (w) => w.timestamp, formatDate, openMember});
  renderMembers();
}
const reset = () => { page = 1; renderMembers(); };
setupInterface({onPage: (delta) => {page += delta; renderMembers();}, onClear: reset});
$('loginView').hidden = true; $('adminView').hidden = false; $('previewBanner').hidden = false;
$('firebaseConnection').textContent = 'Design preview · no live connection';
$('supabaseConnection').textContent = 'Design preview · no live connection';
$('adminEmail').textContent = 'Design preview'; $('staffRole').textContent = 'Preview';
$('logoutButton').textContent = 'Exit preview'; $('logoutButton').addEventListener('click', () => {location.href = './admin.html';});
$('refreshButton').textContent = 'Refresh preview'; $('refreshButton').addEventListener('click', renderDashboard);
$('memberSearch').addEventListener('input', reset); $('memberFilter').addEventListener('change', reset); $('memberSort').addEventListener('change', reset);
$('closeDialog').addEventListener('click', () => $('memberDialog').close());
['exportButton', 'saveSettingsButton', 'inactiveDays', 'injuryThreshold'].forEach((id) => {$ (id).disabled = true; $(id).title = 'Available after signing in with staff access';});
$('inactiveDays').value = 14; $('injuryThreshold').value = 3;
$('settingsAccessNotice').hidden = false; $('settingsAccessNotice').textContent = 'Preview only. Settings changes are disabled.';
$('adminAccountInfo').textContent = 'Sample staff workspace. No authenticated session or live database connection.';
$('reportStatus').textContent = 'CSV export is available after signing in. No live data is loaded in preview.';
const range = reportRange('30'); $('reportFrom').value = range.from; $('reportTo').value = range.to;
renderDashboard();
