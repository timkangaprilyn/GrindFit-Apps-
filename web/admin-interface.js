import {reportRange} from './admin-utils.mjs';
import {communityInsights, localDayKey} from './admin-insights.mjs';

export function navigate(viewId) {
  document.querySelectorAll('.nav-button').forEach((button) => {
    const active = button.dataset.view === viewId;
    button.classList.toggle('active', active);
    if (active) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  });
  document.querySelectorAll('.page-view').forEach((view) => { view.hidden = view.id !== viewId; });
  const heading = document.querySelector(`#${viewId} h1`);
  if (heading) { heading.tabIndex = -1; heading.focus({preventScroll: true}); }
}

export function setupInterface({onPage = () => {}, onClear = () => {}} = {}) {
  const $ = (id) => document.getElementById(id);
  $('dashboardDate').textContent = new Intl.DateTimeFormat('en-PH', {weekday: 'long', month: 'long', day: 'numeric', year: 'numeric'}).format(new Date());
  document.querySelectorAll('.nav-button').forEach((button) => button.addEventListener('click', () => navigate(button.dataset.view)));
  document.querySelectorAll('[data-go]').forEach((button) => button.addEventListener('click', () => navigate(button.dataset.go)));
  document.querySelectorAll('[data-detail-anchor]').forEach((button) => button.addEventListener('click', () => {
    const section = $(button.dataset.detailAnchor);
    if (!section || section.hidden) return;
    section.scrollIntoView({block:'start',behavior:'instant'});
    section.tabIndex = -1; section.focus({preventScroll:true});
  }));
  $('togglePassword').addEventListener('click', () => {
    const show = $('password').type === 'password';
    $('password').type = show ? 'text' : 'password';
    $('togglePassword').textContent = show ? 'Hide' : 'Show';
    $('togglePassword').setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    $('togglePassword').setAttribute('aria-pressed', String(show));
  });
  $('clearFilters').addEventListener('click', () => {
    $('memberSearch').value = ''; $('memberFilter').value = 'all'; $('memberSort').value = 'recent'; onClear();
  });
  $('previousPage').addEventListener('click', () => onPage(-1));
  $('nextPage').addEventListener('click', () => onPage(1));
  document.querySelectorAll('[data-range]').forEach((button) => button.addEventListener('click', () => {
    document.querySelectorAll('[data-range]').forEach((b) => b.setAttribute('aria-pressed', String(b === button)));
    const range = reportRange(button.dataset.range);
    $('reportFrom').value = range.from; $('reportTo').value = range.to;
    $('reportStatus').textContent = 'Date range updated. Export CSV to download recorded sessions.';
  }));
}

export function renderExtras(members, {escapeHtml, workoutDate, formatDate, openMember, inactiveDays = 14}) {
  const $ = (id) => document.getElementById(id);
  const goals = new Map();
  members.forEach((m) => { const goal = m.fitnessGoal || 'Not set'; goals.set(goal, (goals.get(goal) || 0) + 1); });
  $('goalBreakdown').innerHTML = goals.size ? [...goals].sort((a, b) => b[1] - a[1]).map(([goal, count]) => `
    <div class="goal-item"><div class="goal-label"><span>${escapeHtml(goal)}</span><strong>${count} · ${Math.round(count / members.length * 100)}%</strong></div><div class="goal-track"><span style="width:${count / members.length * 100}%"></span></div></div>`).join('') : '<div class="empty-state">Member goals will appear after members complete their profiles.</div>';
  const recent = members.flatMap((member) => (member.workouts || []).map((workout) => ({member, workout, date: workoutDate(workout)}))).filter((entry) => entry.date && entry.date <= new Date()).sort((a, b) => b.date - a.date).slice(0, 5);
  $('recentActivity').innerHTML = recent.length ? recent.map(({member, workout, date}) => `
    <div class="recent-row"><span class="member-avatar" aria-hidden="true">${escapeHtml((member.fullName || 'M').trim().slice(0, 2).toUpperCase())}</span><div class="recent-info"><button class="member-open text-link" data-recent-member="${escapeHtml(member.id)}">${escapeHtml(member.fullName || 'Member')}</button><p>${escapeHtml(workout.title || workout.workoutName || 'Workout session')}</p></div><span class="recent-time">${escapeHtml(formatDate(date))}</span></div>`).join('') : '<div class="empty-state">No workouts recorded in the last 28 days.</div>';
  $('recentActivity').querySelectorAll('[data-recent-member]').forEach((button) => button.addEventListener('click', () => openMember(button.dataset.recentMember)));
  const insights = communityInsights(members, {workoutDate, inactiveDays});
  $('pulseSessions').textContent = insights.recent;
  $('pulseChange').textContent = insights.previous ? `${insights.change >= 0 ? '+' : ''}${insights.change} sessions vs previous 7 days (${Math.round(insights.change / insights.previous * 100)}%)` : insights.recent ? 'Previous 7 days: 0 sessions · no percentage baseline' : 'No sessions in either 7-day period';
  $('pulseDays').textContent = insights.loggedDays;
  $('pulseFollowUps').textContent = insights.followUps.length;
  $('pulseFollowUpLabel').textContent = `No workout in ${inactiveDays} days, or no history on an older/undated profile`;
  const empty = (text) => `<div class="empty-state">${escapeHtml(text)}</div>`;
  const memberRow = (member, caption, tag='Review profile') => `<div class="recent-row"><span class="member-avatar" aria-hidden="true">${escapeHtml((member.fullName||'M').slice(0,2).toUpperCase())}</span><div class="recent-info"><strong>${escapeHtml(member.fullName||'Member')}</strong><p>${escapeHtml(caption)}</p></div><button class="text-link" type="button" data-insight-member="${escapeHtml(member.id)}">${escapeHtml(tag)} →</button></div>`;
  $('followUpList').innerHTML = insights.followUps.length ? insights.followUps.slice(0,5).map((m)=>memberRow(m,m.lastWorkout ? `Last workout: ${formatDate(m.lastWorkout)}` : 'No workout history recorded')).join('') : empty('No members currently match the follow-up rule.');
  $('consistentMembers').innerHTML = insights.regulars.length ? insights.regulars.slice(0,5).map(({member,days},i)=>memberRow(member,`${days} logged workout ${days === 1 ? 'day' : 'days'} · rank ${i+1}`,'View progress')).join('') : empty('Consistency highlights appear after members log their workouts.');
  $('newMemberList').innerHTML = insights.joiners.length ? insights.joiners.slice(0,6).map(({member,joined})=>`<div class="new-member-card">${memberRow(member,`Joined ${formatDate(joined)}`,'Welcome')}</div>`).join('') : empty('No dated member profiles were created in the last 30 days.');
  const max = Math.max(1,...insights.days.map((d)=>d.count));
  $('trainingCalendar').innerHTML = insights.days.map((d,i)=>{
    const level = d.count ? Math.max(1,Math.ceil(d.count/max*3)) : 0;
    return `<button type="button" class="heat-day heat-${level}" data-calendar-day="${i}" aria-label="${escapeHtml(formatDate(d.date))}: ${d.count} sessions" aria-pressed="false"><span>${d.date.getDate()}</span><small>${['Su','Mo','Tu','We','Th','Fr','Sa'][d.date.getDay()]}</small></button>`;
  }).join('');
  $('calendarDetails').hidden = true;
  $('calendarDetails').replaceChildren();
  const bindMembers = (container) => container.querySelectorAll('[data-insight-member]').forEach((button)=>button.addEventListener('click',()=>openMember(button.dataset.insightMember)));
  ['followUpList','consistentMembers','newMemberList'].forEach((id)=>bindMembers($(id)));
  $('trainingCalendar').querySelectorAll('[data-calendar-day]').forEach((button)=>button.addEventListener('click',()=>{
    $('trainingCalendar').querySelectorAll('button').forEach((b)=>b.setAttribute('aria-pressed',String(b===button)));
    const d=insights.days[Number(button.dataset.calendarDay)];
    const target=$('calendarDetails');target.hidden=false;
    target.innerHTML=`<h3>${escapeHtml(localDayKey(d.date))} · ${d.count} logged sessions</h3>`+(d.count ? d.sessions.slice(0,10).map(({member,workout})=>memberRow(member,workout.title||workout.workoutName||'Workout session','Open member')).join('') : empty('No workouts logged on this day.'))+(d.count>10?'<p class="muted">Showing the first 10 sessions. Export a report for the full date range.</p>':'');
    bindMembers(target);
  }));
}
