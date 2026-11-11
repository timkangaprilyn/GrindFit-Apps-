import {memberPage, csvCell, portalRedirect} from './admin-utils.mjs';
import {setupInterface, renderExtras} from './admin-interface.js';
import {firebaseConfig, supabaseConfig} from './admin-config.js';
import {requestAdminData, requestStaff} from './admin-cloud.mjs';
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
  signOut,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js";
import {
  Timestamp,
  collection,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  limit,
  orderBy,
  query,
  setDoc,
  addDoc,
  updateDoc,
  serverTimestamp,
  where,
  writeBatch,
  increment,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";
import {countMoves, trainerCounts, cleanTrainerProfile, sortRequests} from './admin-coaching.mjs';

const app = initializeApp(firebaseConfig);
async function callStaff(action, data = {}) {
  const token = await state.user?.getIdToken();
  return requestStaff({config: supabaseConfig, token, body: {...data, action}});
}
const auth = getAuth(app);
const db = getFirestore(app);
const $ = (id) => document.getElementById(id);
// admin.html and trainer.html share this module; body[data-portal] picks the mode.
const portal = document.body.dataset.portal === 'trainer' ? 'trainer' : 'admin';
function setField(id, property, value) {
  const element = $(id);
  if (element) element[property] = value;
}
const state = {
  user: null,
  isAdmin: false,
  members: [],
  trainers: [],
  // Public trainer profiles (trainers/{uid}) shown to members in the app.
  profiles: new Map(),
  page: 1,
  settings: { inactiveDays: 14, injuryThreshold: 3 },
};

const adminView = $("adminView");
const pageError = $("pageError");
const memberDialog = $("memberDialog");
let cloudRequestVersion = 0;
let connectionVersion = 0;

async function checkSupabase() {
  const owner = state.user?.uid;
  const version = ++connectionVersion;
  const status = $('supabaseConnection');
  if (!status) return;
  if (!state.isAdmin) {
    status.textContent = 'Admin access required · trainer view uses Firebase';
    status.removeAttribute('data-state');
    return;
  }
  status.textContent = 'Checking Supabase tables…';
  status.removeAttribute('data-state');
  try {
    const token = await state.user.getIdToken();
    const result = await requestAdminData({config: supabaseConfig, token, body: {action: 'status'}});
    if (state.user?.uid !== owner || version !== connectionVersion) return;
    const ready = result.analytics?.available === true && result.meals?.available === true;
    status.textContent = ready ? 'Connected · analytics and meal tables available' : 'Connected · some tables unavailable; check deployment';
    status.dataset.state = ready ? 'ready' : 'error';
  } catch (error) {
    if (state.user?.uid !== owner || version !== connectionVersion) return;
    status.textContent = error.message;
    status.dataset.state = 'error';
  }
}

async function loadCloudMember(uid) {
  const version = ++cloudRequestVersion;
  const owner = state.user?.uid;
  const status = $('cloudMemberStatus');
  const target = $('cloudMemberData');
  if (!status || !target) return;
  target.replaceChildren();
  $('retryCloudMember').disabled = !state.isAdmin;
  if (!state.isAdmin || !owner) {
    status.textContent = 'A verified admin account is required to read Supabase member data.';
    return;
  }
  status.textContent = 'Loading saved forecasts and meal preferences…';
  $('retryCloudMember').disabled = true;
  try {
    const token = await state.user.getIdToken();
    const data = await requestAdminData({config: supabaseConfig, token, body: {action: 'member', member_uid: uid}});
    if (version !== cloudRequestVersion || activeMemberUid !== uid || state.user?.uid !== owner) return;
    const rows = Array.isArray(data.analytics?.rows) ? data.analytics.rows : [];
    const latest = rows[0];
    const metrics = latest?.metrics || {};
    const number = (v) => Number.isFinite(v) ? v.toFixed(1) : 'Not enough history';
    const cells = [];
    if (data.analytics?.available !== true) cells.push(['Analytics', 'Table unavailable. Check Supabase deployment.']);
    else if (!latest) cells.push(['Analytics', 'No saved snapshot yet. Ask the member to open Analytics in the updated app.']);
    else {
      cells.push(['Snapshot date', latest.local_date], ['Scheduled days completed', `${metrics.completed_days ?? 0} / ${metrics.scheduled_days ?? 0}`],
        ['Next week · estimated workout days', number(metrics.next_week_estimate)], ['Month end · estimated workout days', number(metrics.month_estimate)]);
    }
    const meal = data.meals?.rows?.[0];
    const prefs = meal?.preferences;
    if (data.meals?.available !== true) cells.push(['Meal preferences', 'Table unavailable. Check Supabase deployment.']);
    else if (!prefs) cells.push(['Meal preferences', 'No saved preferences yet. The member can save them in Meal Recommendations.']);
    else {
      cells.push(['Ingredient budget per meal', `₱${prefs.budget} · illustrative estimate`], ['Meal options', prefs.plant_only ? 'Plant-based only' : 'All diets'],
        ['Excluded ingredients', Array.isArray(prefs.excluded) && prefs.excluded.length ? prefs.excluded.join(', ') : 'None selected'],
        ['Favorite meals', Array.isArray(prefs.favorites) && prefs.favorites.length ? prefs.favorites.map((id) => id.replaceAll('-', ' ')).join(', ') : 'None saved']);
    }
    target.innerHTML = `<div class="detail-grid">${cells.map(([label, value]) => `<div class="detail-cell"><span>${escapeHtml(label)}</span><strong>${escapeHtml(value)}</strong></div>`).join('')}</div>`;
    if (latest) {
      const basis = document.createElement('p'); basis.className = 'cloud-caption';
      basis.textContent = `${metrics.basis || ''} Forecasts are activity estimates, not body-composition or medical predictions.`;
      target.append(basis);
    }
    status.textContent = 'Read from Supabase · saved member data; current device-only changes may not be synced yet.';
  } catch (error) {
    if (version !== cloudRequestVersion || activeMemberUid !== uid || state.user?.uid !== owner) return;
    status.textContent = error.message;
  } finally {
    if (version === cloudRequestVersion && state.user?.uid === owner) $('retryCloudMember').disabled = false;
  }
}

$('retryCloudMember')?.addEventListener('click', () => { if (activeMemberUid) loadCloudMember(activeMemberUid); });

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;",
  })[character]);
}

function showError(message) {
  pageError.textContent = message;
  pageError.hidden = !message;
}

function formatDate(value) {
  if (!value) return "No workout recorded";
  const date = value instanceof Date ? value : value.toDate?.();
  return date ? new Intl.DateTimeFormat(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(date) : "Date unavailable";
}

function formatWeekRange(start) {
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  const startMonth = new Intl.DateTimeFormat(undefined, {
    month: "short",
  }).format(start);
  const endMonth = new Intl.DateTimeFormat(undefined, {
    month: "short",
  }).format(end);
  const startDay = new Intl.DateTimeFormat(undefined, {
    day: "numeric",
  }).format(start);
  const endDay = new Intl.DateTimeFormat(undefined, {
    day: "numeric",
  }).format(end);
  return startMonth === endMonth
    ? `${startMonth} ${startDay}–${endDay}`
    : `${startMonth} ${startDay}–${endMonth} ${endDay}`;
}

function normalizeGoalLabel(goal) {
  const normalized = String(goal ?? "").trim();
  const key = normalized.toLowerCase().replace(/[\s/_-]+/g, " ");
  if (["build muscle", "muscle building", "muscle gain", "strength"].includes(key)) {
    return "Muscle Gain / Strength";
  }
  if (["lose weight", "weight loss", "weight loss maintenance"].includes(key)) {
    return "Weight Loss / Maintenance";
  }
  return normalized || "Not set";
}

function boundedSetting(value, fallback, min, max) {
  const parsed = Number(value);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max
    ? parsed
    : fallback;
}

function workoutDate(workout) {
  const value = workout.timestamp ?? workout.completedAt;
  if (value?.toDate) return value.toDate();
  if (value instanceof Date) return value;
  if (typeof value === "string") {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }
  return null;
}

function startOfWeek(date) {
  const day = new Date(date.getFullYear(), date.getMonth(), date.getDate());
  day.setDate(day.getDate() - ((day.getDay() + 6) % 7));
  return day;
}

function toLocalDateInput(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

async function getMemberWorkouts(uid, since, until) {
  const constraints = [];
  if (since) constraints.push(where("timestamp", ">=", Timestamp.fromDate(since)));
  if (until) constraints.push(where("timestamp", "<", Timestamp.fromDate(until)));
  constraints.push(orderBy("timestamp", "desc"));
  const result = await getDocs(query(
    collection(db, "users", uid, "workouts"),
    ...constraints,
  ));
  return result.docs.map((snapshot) => ({
    id: snapshot.id,
    ...snapshot.data(),
  }));
}

async function getLatestWorkoutDate(uid, until) {
  const constraints = [];
  if (until) constraints.push(where("timestamp", "<", Timestamp.fromDate(until)));
  constraints.push(orderBy("timestamp", "desc"), limit(1));
  const result = await getDocs(query(
    collection(db, "users", uid, "workouts"),
    ...constraints,
  ));
  return result.empty ? null : workoutDate(result.docs[0].data());
}

async function loadMembers() {
  // Trainers only see members an admin assigned to them via users/{uid}.trainerUid.
  const users = await getDocs(portal === "trainer"
    ? query(collection(db, "users"), where("trainerUid", "==", state.user.uid))
    : collection(db, "users"));
  const memberProfiles = users.docs
    .map((snapshot) => ({ id: snapshot.id, ...snapshot.data() }))
    .filter((profile) => !["admin", "trainer"].includes(
      String(profile.role ?? "member").toLowerCase(),
    ));

  const now = new Date();
  const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
  const fourDaysAgo = new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000);
  const fourWeeksAgo = new Date(now.getTime() - 28 * 24 * 60 * 60 * 1000);
  const endOfNow = new Date(now.getTime() + 1);
  const weekStart = startOfWeek(now);
  return Promise.all(memberProfiles.map(async (profile) => {
    const [workouts, lastWorkout] = await Promise.all([
      getMemberWorkouts(profile.id, fourWeeksAgo, endOfNow),
      getLatestWorkoutDate(profile.id, endOfNow),
    ]);
    const datedWorkouts = workouts
      .map((workout) => ({ workout, date: workoutDate(workout) }))
      .filter((entry) => entry.date)
      .sort((a, b) => b.date - a.date);
    const weeklyCount = datedWorkouts.filter(
      (entry) => entry.date >= weekStart && entry.date <= now,
    ).length;
    const recentCount = datedWorkouts.filter(
      (entry) => entry.date >= fourteenDaysAgo && entry.date <= now,
    ).length;
    const fourDayCount = datedWorkouts.filter(
      (entry) => entry.date >= fourDaysAgo && entry.date <= now,
    ).length;
    const injuryAlert = profile.hasInjuryOrCondition === true ||
      String(profile.injuryDetails ?? "").trim().length > 0;
    return {
      ...profile,
      workouts,
      lastWorkout,
      weeklyCount,
      recentCount,
      fourDayCount,
      injuryAlert,
      recoveryAlert: fourDayCount >= state.settings.injuryThreshold,
    };
  }));
}

function renderDashboard() {
  const members = state.members;
  const active = members.filter((member) => member.recentCount > 0).length;
  const weeklyTotal = members.reduce((total, member) => total + member.weeklyCount, 0);
  $("totalMembers").textContent = String(members.length);
  $("activeMembers").textContent = String(active);
  $("retentionRate").textContent = members.length
    ? `${Math.round(active / members.length * 100)}%`
    : "0%";
  $("retentionFormula").textContent = `${active} active / ${members.length} members`;
  $("weeklyWorkouts").textContent = String(weeklyTotal);

  const now = new Date();
  const start = startOfWeek(now);
  const weeks = Array.from({ length: 4 }, (_, index) => {
    const weekStart = new Date(start);
    weekStart.setDate(start.getDate() - (3 - index) * 7);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 7);
    const count = members.reduce((total, member) => total + member.workouts.filter((workout) => {
      const date = workoutDate(workout);
      return date && date >= weekStart && date < weekEnd;
    }).length, 0);
    return { weekStart, count };
  });
  const maxCount = Math.max(4, Math.ceil(Math.max(...weeks.map((week) => week.count)) / 4) * 4);
  const ticks = [maxCount, maxCount * 0.75, maxCount * 0.5, maxCount * 0.25, 0];
  $("activityChart").setAttribute(
    "aria-label",
    `Workout sessions per week for the last four weeks. Highest weekly count: ${maxCount}.`,
  );
  $("activityChart").innerHTML = `
    <div class="chart-y-axis" aria-hidden="true">
      ${ticks.map((tick) => `<span>${Math.round(tick)}</span>`).join("")}
    </div>
    <div class="chart-series">
      ${weeks.map(({ weekStart, count }) => {
        const height = count / maxCount * 100;
        return `<div class="chart-column">
          <div class="chart-plot">
            <b class="chart-value" style="bottom:calc(${height}% + 3px)">${count}</b>
            <div class="chart-bar" style="height:${height}%"></div>
          </div>
          <span>${escapeHtml(formatWeekRange(weekStart))}</span>
        </div>`;
      }).join("")}
    </div>`;

  const risks = members.filter((member) => member.injuryAlert || member.recoveryAlert);
  $("riskSummary").innerHTML = risks.length
    ? `<div class="risk-list">${risks.map((member) => `<div class="risk-row"><strong>${escapeHtml(member.fullName || member.email || "Member")}</strong><span>${escapeHtml(member.injuryAlert ? member.injuryDetails || "Health condition noted; review profile before training." : `${member.fourDayCount} workouts in four days; recovery review threshold reached.`)}</span></div>`).join("")}</div>`
    : '<div class="empty-state">No injury, health, or high-frequency recovery alerts.</div>';
  renderMembers();
  renderExtras(members, {escapeHtml, workoutDate, formatDate, openMember, inactiveDays: state.settings.inactiveDays});
}

function renderMembers() {
  const search = $("memberSearch").value.trim().toLowerCase();
  const filter = $("memberFilter").value;
  const sort = $("memberSort").value;
  const inactiveOption = $("inactiveFilterLabel");
  if (inactiveOption) {
    inactiveOption.textContent = `No workout in last ${state.settings.inactiveDays} days`;
  }
  const result = memberPage(state.members.map((m) => ({...m, fitnessGoal: normalizeGoalLabel(m.fitnessGoal)})), {
    search, filter, sort, page: state.page, inactiveDays: state.settings.inactiveDays,
  });
  state.page = result.page;
  const members = result.items;
  $("memberCount").textContent = result.total ? `Showing ${(result.page - 1) * result.pageSize + 1}–${Math.min(result.page * result.pageSize, result.total)} of ${result.total} matching members` : 'No matching members';
  $("pageNumber").textContent = `Page ${result.page} of ${result.pages}`;
  $("previousPage").disabled = result.page <= 1;
  $("nextPage").disabled = result.page >= result.pages;
  $("memberRows").innerHTML = members.length
    ? members.map((member) => `<tr data-member-id="${escapeHtml(member.id)}">
        <td><button type="button" class="member-open"><div class="member-name">${escapeHtml(member.fullName || "Unnamed member")}</div><div class="member-email">${escapeHtml(member.email || "No email")}</div></button></td>
        <td>${escapeHtml(normalizeGoalLabel(member.fitnessGoal))}</td>
        <td>${escapeHtml(formatDate(member.lastWorkout))}</td>
        <td>${member.weeklyCount}</td>
        <td><span class="badge ${member.injuryAlert || member.recoveryAlert ? "alert" : "clear"}">${member.injuryAlert || member.recoveryAlert ? "Review" : "None"}</span></td>
      </tr>`).join("")
    : '<tr><td colspan="5" class="muted">No members match this filter.</td></tr>';

  $("memberRows").querySelectorAll("[data-member-id]").forEach((row) => {
    row.addEventListener("click", () => openMember(row.dataset.memberId));
  });
}

async function openMember(uid) {
  const owner = state.user?.uid;
  if (!owner) return;
  const member = state.members.find((item) => item.id === uid);
  if (!member) return;
  activeMemberUid = uid;
  loadCloudMember(uid);
  editingNoteId = null;
  $("coachNoteText").value = "";
  $("cancelCoachEditButton").hidden = true;
  $("coachNoteStatus").textContent = "";
  $("coachAssignment").hidden = !state.isAdmin;
  fillTrainerSelect(member.trainerUid || "");
  $("saveCoachNoteButton").disabled = !state.isAdmin && member.trainerUid !== state.user?.uid;
  loadCoachNotes(uid);
  $("detailName").textContent = member.fullName || member.email || "Member";
  $("detailSummary").innerHTML = [
    ["Fitness goal", normalizeGoalLabel(member.fitnessGoal)],
    ["Workout environment", member.workoutEnvironment || member.environment || "Not set"],
    ["Program duration", member.programDurationMonths ? `${member.programDurationMonths} months` : "Not set"],
    ["Workouts this week", member.weeklyCount],
    ["Last workout", formatDate(member.lastWorkout)],
    ["Injury / health info", member.injuryDetails || (member.injuryAlert ? "Reported" : "None reported")],
    ["Workouts in last 4 days", member.fourDayCount],
  ].map(([label, value]) => `<div class="detail-cell"><span>${escapeHtml(label)}</span><strong>${escapeHtml(value)}</strong></div>`).join("");
  const alerts = [];
  if (member.injuryAlert) alerts.push(member.injuryDetails || "Review health details before training.");
  if (member.recoveryAlert) alerts.push(`${member.fourDayCount} workouts in four days; recovery review threshold reached.`);
  $("detailAlerts").innerHTML = alerts.length
    ? alerts.map((alert) => `<span class="badge alert">${escapeHtml(alert)}</span>`).join(" ")
    : '<span class="badge clear">No injury or recovery alert recorded.</span>';
  $("detailWorkouts").innerHTML = '<div class="muted">Loading sessions…</div>';
  memberDialog.showModal();
  try {
    const workouts = await getMemberWorkouts(
      uid,
      new Date(Date.now() - 90 * 24 * 60 * 60 * 1000),
      new Date(Date.now() + 1),
    );
    if (!memberDialog.open || activeMemberUid !== uid || state.user?.uid !== owner) return;
    $("detailWorkouts").innerHTML = workouts.length
      ? workouts.map((workout) => {
        const exerciseList = Array.isArray(workout.exercises)
          ? workout.exercises.map((exercise) => {
            if (typeof exercise === "string") return exercise;
            return `${exercise.name ?? "Exercise"} (${exercise.sets ?? 0} sets × ${exercise.reps ?? 0} reps${exercise.weight ? `, ${exercise.weight} kg` : ""})`;
          }).join(", ")
          : "Exercise details unavailable";
        return `<article class="detail-workout"><strong>${escapeHtml(workout.title || workout.workoutName || "Workout session")}</strong><p>${escapeHtml(formatDate(workoutDate(workout)))} · ${escapeHtml(workout.duration || "Duration unavailable")} · ${escapeHtml(workout.intensity || "Intensity unavailable")}</p><p>${escapeHtml(exerciseList)}</p></article>`;
      }).join("")
      : '<div class="empty-state">No workout sessions recorded in the last 90 days.</div>';
  } catch (error) {
    if (memberDialog.open && activeMemberUid === uid && state.user?.uid === owner) {
      $("detailWorkouts").innerHTML = `<div class="error">${escapeHtml(error.message || "Could not load workout details.")}</div>`;
    }
  }
}

async function refreshDashboard() {
  if (!state.user) return;
  const owner = state.user.uid;
  showError("");
  $("refreshButton").disabled = true;
  $("lastUpdated").textContent = 'Refreshing member activity…';
  try {
    const members = await loadMembers();
    if (state.user?.uid !== owner) return;
    state.members = members;
    renderDashboard();
    await syncTrainerCounts();
    renderTrainers();
    $("firebaseConnection").textContent = 'Connected · latest member data loaded';
    $("firebaseConnection").dataset.state = 'ready';
    checkSupabase();
    $("lastUpdated").textContent = `Last refreshed ${new Intl.DateTimeFormat('en-PH', {hour: 'numeric', minute: '2-digit'}).format(new Date())} · Manual refresh`;
  } catch (error) {
    if (state.user?.uid !== owner) return;
    showError(error.message || "Unable to load member data. Verify admin access and retry.");
    $("firebaseConnection").textContent = 'Could not refresh · check staff access and connection';
    $("firebaseConnection").dataset.state = 'error';
    $("lastUpdated").textContent = 'Refresh failed · previously loaded data may be out of date';
  } finally {
    $("refreshButton").disabled = false;
  }
}

async function loadSettings() {
  const settingsSnapshot = await getDoc(doc(db, "admin_settings", "global"));
  const settings = settingsSnapshot.exists() ? settingsSnapshot.data() : {};
  if (settingsSnapshot.exists()) {
    state.settings = {
      inactiveDays: boundedSetting(settings.inactiveDays, 14, 1, 365),
      injuryThreshold: boundedSetting(settings.injuryThreshold, 3, 1, 14),
    };
  }
  setField("inactiveDays", "value", state.settings.inactiveDays);
  setField("injuryThreshold", "value", state.settings.injuryThreshold);
  setField("saveSettingsButton", "hidden", !state.isAdmin);
  setField("settingsAccessNotice", "hidden", state.isAdmin);
  setField("inactiveDays", "readOnly", !state.isAdmin);
  setField("injuryThreshold", "readOnly", !state.isAdmin);
  setField("adminAccountInfo", "textContent",
    `Signed in as ${state.user.email || "staff account"}. This account's access is verified using Firebase Authentication custom claims. Claims for other accounts cannot be listed or changed here; use a trusted Firebase Admin SDK environment.`);
}

async function saveSettings() {
  const inactiveDays = Number($("inactiveDays").value);
  const injuryThreshold = Number($("injuryThreshold").value);
  if (!Number.isInteger(inactiveDays) || inactiveDays < 1 || inactiveDays > 365 ||
      !Number.isInteger(injuryThreshold) || injuryThreshold < 1 || injuryThreshold > 14) {
    $("settingsStatus").textContent = "Enter valid values within the displayed ranges.";
    return;
  }
  $("settingsStatus").textContent = "Saving…";
  try {
    const updatedSettings = { inactiveDays, injuryThreshold };
    await setDoc(doc(db, "admin_settings", "global"), {
      ...updatedSettings,
      updatedAt: Timestamp.now(),
      updatedBy: state.user.uid,
    }, { merge: true });
    state.settings = updatedSettings;
    await refreshDashboard();
    $("settingsStatus").textContent = "Settings saved.";
  } catch (error) {
    $("settingsStatus").textContent = error.message || "Could not save settings.";
  }
}

async function exportReport() {
  const from = $("reportFrom").value;
  const to = $("reportTo").value;
  const status = $("reportStatus");
  if (!from || !to || from > to) {
    status.textContent = "Choose a valid date range.";
    return;
  }
  $("exportButton").disabled = true;
  status.textContent = "Preparing report…";
  try {
    const fromDate = new Date(`${from}T00:00:00`);
    const untilDate = new Date(`${to}T00:00:00`);
    untilDate.setDate(untilDate.getDate() + 1);
    const rows = [["date", "goal", "environment", "duration", "intensity", "exercises", "feedback"]];
    const memberWorkouts = await Promise.all(state.members.map(async (member) => ({
      member,
      workouts: await getMemberWorkouts(member.id, fromDate, untilDate),
    })));
    for (const { member, workouts } of memberWorkouts) {
      for (const workout of workouts) {
        const exercises = Array.isArray(workout.exercises)
          ? workout.exercises.map((item) => typeof item === "string" ? item : item.name || "Exercise").join("; ")
          : "";
        rows.push([
          workoutDate(workout)?.toISOString() ?? "",
          member.fitnessGoal || "",
          workout.category || "",
          workout.duration || "",
          workout.intensity || "",
          exercises,
          workout.feedback || "",
        ]);
      }
    }
    const csv = rows.map((row) => row.map(csvCell).join(",")).join("\r\n");
    const link = document.createElement("a");
    link.href = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
    link.download = `grindfit-workouts-${from}-to-${to}.csv`;
    link.click();
    URL.revokeObjectURL(link.href);
    status.textContent = `${rows.length - 1} workout sessions exported without member identifiers.`;
  } catch (error) {
    status.textContent = error.message || "Could not export the report.";
  } finally {
    $("exportButton").disabled = false;
  }
}

function showAdmin() {
  adminView.hidden = false;
  $("adminEmail").textContent = state.user.email || "";
  $("staffRole").textContent = portal === "trainer" ? "Trainer" : "Admin";
}

// Sign-in lives on login.html. This page only runs for a verified staff session.
onAuthStateChanged(auth, async (user) => {
  if (!user) {
    state.user = null;
    adminView.hidden = true;
    location.replace("./login.html");
    return;
  }
  try {
    const token = await user.getIdTokenResult(true);
    if (auth.currentUser?.uid !== user.uid) return;
    const redirect = portalRedirect(portal, token.claims);
    if (redirect) {
      if (redirect.startsWith("login.html")) await signOut(auth);
      location.replace(`./${redirect}`);
      return;
    }
    state.user = user;
    state.isAdmin = token.claims.admin === true;
    showAdmin();
    await loadSettings();
    await loadTrainerProfiles();
    if (state.isAdmin && $("trainerList")) loadTrainers();
    loadRequests();
    await refreshDashboard();
  } catch (error) {
    adminView.hidden = false;
    showError(error.message || "Could not verify staff access.");
  }
});

$("logoutButton").addEventListener("click", () => signOut(auth));
$("refreshButton").addEventListener("click", () => { loadRequests(); refreshDashboard(); });
function resetMemberPage() { state.page = 1; renderMembers(); }
$("memberSearch").addEventListener("input", resetMemberPage);
$("memberFilter").addEventListener("change", resetMemberPage);
$("memberSort").addEventListener("change", resetMemberPage);
$("saveSettingsButton")?.addEventListener("click", saveSettings);
$("exportButton").addEventListener("click", exportReport);
$("closeDialog").addEventListener("click", () => memberDialog.close());
setupInterface({onPage: (delta) => { state.page += delta; renderMembers(); }, onClear: resetMemberPage});

const reportTo = new Date();
const reportFrom = new Date();
reportFrom.setDate(reportTo.getDate() - 29);
$("reportFrom").value = toLocalDateInput(reportFrom);
$("reportTo").value = toLocalDateInput(reportTo);

let activeMemberUid = null;
let editingNoteId = null;
async function loadCoachNotes(uid) {
  $("coachNotes").textContent = "Loading notes…";
  try {
    const result = await getDocs(query(collection(db, "users", uid, "coach_notes"), orderBy("updatedAt", "desc"), limit(20)));
    if (activeMemberUid !== uid) return;
    $("coachNotes").replaceChildren();
    if (result.empty) $("coachNotes").textContent = "No coach notes yet.";
    for (const snapshot of result.docs) {
      const note = snapshot.data();
      const row = document.createElement("article");
      row.className = "detail-workout";
      const text = document.createElement("p");
      text.textContent = note.text || "";
      row.append(text);
      if (state.isAdmin || note.authorUid === state.user?.uid) {
        const edit = document.createElement("button");
        edit.type = "button";
        edit.className = "button subtle";
        edit.textContent = "Edit note";
        edit.addEventListener("click", () => {
          editingNoteId = snapshot.id;
          $("coachNoteText").value = note.text || "";
          $("cancelCoachEditButton").hidden = false;
        });
        row.append(edit);
      }
      $("coachNotes").append(row);
    }
  } catch (error) {
    if (activeMemberUid === uid) $("coachNotes").textContent = "Notes unavailable. Check trainer assignment and deployed rules.";
  }
}
$("saveCoachNoteButton").addEventListener("click", async () => {
  const uid = activeMemberUid;
  const text = $("coachNoteText").value.trim();
  if (!uid || !text || text.length > 2000) return;
  $("saveCoachNoteButton").disabled = true;
  try {
    if (editingNoteId) await updateDoc(doc(db, "users", uid, "coach_notes", editingNoteId), { text, updatedAt: serverTimestamp() });
    else await addDoc(collection(db, "users", uid, "coach_notes"), { text, authorUid: state.user.uid, createdAt: serverTimestamp(), updatedAt: serverTimestamp() });
    if (activeMemberUid !== uid) return;
    editingNoteId = null;
    $("coachNoteText").value = "";
    $("cancelCoachEditButton").hidden = true;
    $("coachNoteStatus").textContent = "Note saved. The member can read it in the app.";
    await loadCoachNotes(uid);
  } catch (error) { $("coachNoteStatus").textContent = error.message || "Could not save note."; }
  finally { $("saveCoachNoteButton").disabled = false; }
});
$("cancelCoachEditButton").addEventListener("click", () => {
  editingNoteId = null;
  $("coachNoteText").value = "";
  $("cancelCoachEditButton").hidden = true;
});
$("assignTrainerButton").addEventListener("click", async () => {
  if (!state.isAdmin || !activeMemberUid) return;
  const uid = activeMemberUid;
  $("assignTrainerButton").disabled = true;
  try {
    const trainerUid = $("trainerUid").value.trim();
    const member = state.members.find((item) => item.id === uid);
    const previous = member?.trainerUid || "";
    const batch = writeBatch(db);
    batch.update(doc(db, "users", uid), { trainerUid });
    addCountMoves(batch, uid, previous, trainerUid);
    await batch.commit();
    applyCountMoves(previous, trainerUid);
    if (member) member.trainerUid = trainerUid;
    renderTrainers();
    $("coachNoteStatus").textContent = "Trainer assignment saved.";
  } catch (error) { $("coachNoteStatus").textContent = error.message || "Could not save assignment."; }
  finally { $("assignTrainerButton").disabled = false; }
});

// ---- Trainer profiles and member counts (trainers/{uid}). Firestore rules only
// let staff move a count by one when the same batch moves that member.
async function loadTrainerProfiles() {
  try {
    const snapshot = await getDocs(collection(db, "trainers"));
    state.profiles = new Map(snapshot.docs.map((item) => [item.id, item.data()]));
  } catch (_) {
    state.profiles = new Map();
  }
}

function addCountMoves(batch, memberUid, previousUid, nextUid) {
  for (const {uid, delta} of countMoves(previousUid, nextUid, new Set(state.profiles.keys()))) {
    batch.update(doc(db, "trainers", uid), { memberCount: increment(delta), lastChange: memberUid, updatedAt: serverTimestamp() });
  }
}

function applyCountMoves(previousUid, nextUid) {
  for (const {uid, delta} of countMoves(previousUid, nextUid, new Set(state.profiles.keys()))) {
    const profile = state.profiles.get(uid);
    profile.memberCount = Math.max(0, (profile.memberCount ?? 0) + delta);
  }
}

// Admins re-sync stored counts with actual assignments (self-healing).
async function syncTrainerCounts() {
  if (!state.isAdmin || portal !== "admin" || !state.profiles.size) return;
  const counts = trainerCounts(state.members, new Set(state.profiles.keys()));
  const batch = writeBatch(db);
  let changed = 0;
  for (const [uid, count] of counts) {
    const profile = state.profiles.get(uid);
    if (profile.memberCount === count) continue;
    batch.update(doc(db, "trainers", uid), { memberCount: count, updatedAt: serverTimestamp() });
    profile.memberCount = count;
    changed++;
  }
  if (changed) await batch.commit().catch(() => {});
}

// ---- Coaching requests from the app (trainer_requests/{memberUid}).
async function loadRequests() {
  const list = $("requestList");
  if (!list || !state.user) return;
  const owner = state.user.uid;
  const mine = portal === "trainer" || !state.isAdmin;
  const constraints = [where("status", "==", "pending")];
  if (mine) constraints.unshift(where("trainerUid", "==", owner));
  try {
    const snapshot = await getDocs(query(collection(db, "trainer_requests"), ...constraints));
    if (state.user?.uid !== owner) return;
    renderRequests(sortRequests(snapshot.docs.map((item) => ({id: item.id, ...item.data()}))), mine);
  } catch (error) {
    if (state.user?.uid !== owner) return;
    $("requestCount").textContent = "Unavailable";
    list.innerHTML = `<div class="empty-state">${escapeHtml(error.code === "permission-denied" ? "Requests need the latest Firestore rules. Deploy firestore.rules, then refresh." : error.message || "Could not load requests.")}</div>`;
  }
}

function renderRequests(requests, mine) {
  $("requestCount").textContent = `${requests.length} pending`;
  $("requestStatus").textContent = "";
  if (!requests.length) {
    $("requestList").innerHTML = `<div class="empty-state">${mine ? "No members are waiting for you right now." : "No pending coaching requests."}</div>`;
    return;
  }
  $("requestList").innerHTML = requests.map((request) => `<div class="recent-row">
      <span class="member-avatar" aria-hidden="true">${escapeHtml((request.memberName || "M").trim().slice(0, 2).toUpperCase())}</span>
      <div class="recent-info"><strong>${escapeHtml(request.memberName || "Member")}</strong>
        <p>${mine ? "" : `Requested <b>${escapeHtml(request.trainerName || "a trainer")}</b> · `}${escapeHtml(formatDate(request.createdAt))}</p>
        ${request.note ? `<p class="request-note">“${escapeHtml(request.note)}”</p>` : ""}</div>
      <div class="request-actions">
        <button class="button primary" type="button" data-request="${escapeHtml(request.id)}" data-decision="approved">Approve</button>
        <button class="button subtle" type="button" data-request="${escapeHtml(request.id)}" data-decision="declined">Decline</button>
      </div>
    </div>`).join("");
  $("requestList").querySelectorAll("[data-request]").forEach((button) => button.addEventListener("click", () => {
    decideRequest(requests.find((item) => item.id === button.dataset.request), button.dataset.decision);
  }));
}

async function decideRequest(request, decision) {
  if (!request) return;
  const status = $("requestStatus");
  $("requestList").querySelectorAll("button").forEach((button) => { button.disabled = true; });
  status.textContent = decision === "approved" ? "Approving…" : "Declining…";
  try {
    const requestRef = doc(db, "trainer_requests", request.id);
    const decided = { status: decision, decidedBy: state.user.uid, updatedAt: serverTimestamp() };
    if (decision === "declined") {
      await updateDoc(requestRef, decided);
    } else {
      // Approve and assign in one batch, as firestore.rules requires.
      const memberSnapshot = await getDoc(doc(db, "users", request.memberUid));
      if (!memberSnapshot.exists()) throw new Error("This member profile no longer exists.");
      const previous = memberSnapshot.data().trainerUid || "";
      const batch = writeBatch(db);
      batch.update(requestRef, decided);
      batch.update(doc(db, "users", request.memberUid), { trainerUid: request.trainerUid });
      addCountMoves(batch, request.memberUid, previous, request.trainerUid);
      await batch.commit();
      applyCountMoves(previous, request.trainerUid);
    }
    status.textContent = decision === "approved"
      ? `${request.memberName || "Member"} is now assigned to ${request.trainerName || "the trainer"}.`
      : `Request from ${request.memberName || "member"} declined.`;
    await loadRequests();
    if (decision === "approved") await refreshDashboard();
  } catch (error) {
    status.textContent = error.code === "permission-denied"
      ? "Not allowed. The request may have been cancelled or already decided. Refresh and try again."
      : error.message || "Could not update the request.";
    $("requestList").querySelectorAll("button").forEach((button) => { button.disabled = false; });
  }
}

// ---- Trainers page (admin only). Accounts are created by the Supabase
// admin-staff function, which verifies the Firebase admin claim itself.
function staffErrorMessage(error) {
  return error?.message || "Could not complete the request.";
}

function trainerLabel(trainer) {
  return trainer.displayName ? `${trainer.displayName} · ${trainer.email}` : trainer.email || trainer.uid;
}

function fillTrainerSelect(selectedUid) {
  const select = $("trainerUid");
  if (!select) return;
  if (select.tagName !== "SELECT") { select.value = selectedUid; return; }
  const options = [new Option("Not assigned", "")];
  for (const trainer of state.trainers) {
    options.push(new Option(`${trainerLabel(trainer)}${trainer.disabled ? " (disabled)" : ""}`, trainer.uid));
  }
  // Keep an assignment visible even if the trainer list could not be loaded.
  if (selectedUid && !state.trainers.some((trainer) => trainer.uid === selectedUid)) {
    options.push(new Option(`Unknown trainer · ${selectedUid}`, selectedUid));
  }
  select.replaceChildren(...options);
  select.value = selectedUid;
}

function renderTrainers() {
  const list = $("trainerList");
  if (!list) return;
  if (!state.trainers.length) {
    list.innerHTML = '<div class="empty-state">No trainer accounts yet. Create one using the form.</div>';
    return;
  }
  list.innerHTML = state.trainers.map((trainer) => {
    const assigned = state.members.filter((member) => member.trainerUid === trainer.uid).length;
    const profile = state.profiles.get(trainer.uid);
    const appBadge = !profile
      ? '<span class="badge alert">Not in app</span>'
      : profile.active ? '<span class="badge gold">Shown in app</span>' : '<span class="badge clear">Hidden in app</span>';
    return `<div class="trainer-row">
      <div><strong>${escapeHtml(profile?.displayName || trainer.displayName || "Trainer")}</strong>
        <p>${escapeHtml(trainer.email)} · ${assigned} assigned ${assigned === 1 ? "member" : "members"}${profile?.specialty ? ` · ${escapeHtml(profile.specialty)}` : ""}</p>
        ${profile ? "" : '<p>Add a profile so members can request this trainer in the app.</p>'}
        <p><code>${escapeHtml(trainer.uid)}</code></p></div>
      <div class="trainer-actions">
        ${appBadge}
        <span class="badge ${trainer.disabled ? "alert" : "clear"}">${trainer.disabled ? "Login disabled" : "Login active"}</span>
        <button class="button subtle" type="button" data-trainer-profile="${escapeHtml(trainer.uid)}">${profile ? "Edit profile" : "Add profile"}</button>
        <button class="button subtle" type="button" data-trainer-toggle="${escapeHtml(trainer.uid)}" data-disable="${trainer.disabled ? "false" : "true"}">${trainer.disabled ? "Enable" : "Disable"}</button>
      </div>
    </div>`;
  }).join("");
  list.querySelectorAll("[data-trainer-toggle]").forEach((button) => button.addEventListener("click", () => toggleTrainer(button)));
  list.querySelectorAll("[data-trainer-profile]").forEach((button) => button.addEventListener("click", () => openTrainerProfile(button.dataset.trainerProfile)));
}

let editingProfileUid = null;
function openTrainerProfile(uid) {
  const trainer = state.trainers.find((item) => item.uid === uid);
  const profile = state.profiles.get(uid);
  editingProfileUid = uid;
  $("profileAccount").textContent = trainer ? `Login: ${trainer.email}` : "";
  $("profileName").value = profile?.displayName || trainer?.displayName || "";
  $("profileSpecialty").value = profile?.specialty || "";
  $("profileBio").value = profile?.bio || "";
  $("profileActive").checked = profile ? profile.active === true : !trainer?.disabled;
  $("profileStatus").textContent = "";
  $("trainerProfileDialog").showModal();
}

async function saveTrainerProfile(uid, fields) {
  const clean = cleanTrainerProfile(fields);
  const count = state.members.filter((member) => member.trainerUid === uid).length;
  const data = { ...clean, memberCount: count, updatedAt: serverTimestamp() };
  await setDoc(doc(db, "trainers", uid), data, { merge: true });
  state.profiles.set(uid, { ...(state.profiles.get(uid) || {}), ...clean, memberCount: count });
}

if ($("trainerProfileForm")) {
  $("closeProfileDialog").addEventListener("click", () => $("trainerProfileDialog").close());
  $("trainerProfileForm").addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!state.isAdmin || !editingProfileUid) return;
    $("saveProfileButton").disabled = true;
    $("profileStatus").textContent = "Saving…";
    try {
      await saveTrainerProfile(editingProfileUid, {
        displayName: $("profileName").value, specialty: $("profileSpecialty").value,
        bio: $("profileBio").value, active: $("profileActive").checked,
      });
      $("trainerProfileDialog").close();
      $("trainerListStatus").textContent = "Trainer profile saved. Members see the change in the app right away.";
      renderTrainers();
    } catch (error) {
      $("profileStatus").textContent = error.message || "Could not save the profile.";
    } finally {
      $("saveProfileButton").disabled = false;
    }
  });
}

async function loadTrainers() {
  if (!state.isAdmin || !$("trainerList")) return;
  const owner = state.user?.uid;
  $("trainerListStatus").textContent = "Loading trainers…";
  $("refreshTrainersButton").disabled = true;
  try {
    const result = await callStaff("list");
    if (state.user?.uid !== owner) return;
    state.trainers = Array.isArray(result?.trainers) ? result.trainers : [];
    $("trainerListStatus").textContent = `${state.trainers.length} trainer ${state.trainers.length === 1 ? "account" : "accounts"}. Assign members from each member profile.`;
    renderTrainers();
  } catch (error) {
    if (state.user?.uid !== owner) return;
    $("trainerListStatus").textContent = staffErrorMessage(error);
  } finally {
    $("refreshTrainersButton").disabled = false;
  }
}

async function toggleTrainer(button) {
  const uid = button.dataset.trainerToggle;
  const disabled = button.dataset.disable === "true";
  const trainer = state.trainers.find((item) => item.uid === uid);
  if (disabled && !confirm(`Disable ${trainer ? trainerLabel(trainer) : "this trainer"}? They will be signed out and cannot sign in until enabled again.`)) return;
  button.disabled = true;
  try {
    const updated = await callStaff("set-disabled", {uid, disabled});
    state.trainers = state.trainers.map((item) => item.uid === uid ? updated : item);
    // A disabled login is hidden from the app so members cannot request it.
    const profile = state.profiles.get(uid);
    if (profile && disabled && profile.active) {
      await updateDoc(doc(db, "trainers", uid), { active: false, updatedAt: serverTimestamp() });
      profile.active = false;
    }
    $("trainerListStatus").textContent = `${trainerLabel(updated)} is now ${updated.disabled ? "disabled" : "active"}.`;
    renderTrainers();
  } catch (error) {
    $("trainerListStatus").textContent = staffErrorMessage(error);
    button.disabled = false;
  }
}

function generatePassword() {
  const letters = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
  const digits = "23456789";
  const all = letters + digits;
  const bytes = crypto.getRandomValues(new Uint32Array(16));
  let password = "";
  for (const value of bytes) password += all[value % all.length];
  // Guarantee at least one letter and one digit.
  return letters[bytes[0] % letters.length] + password.slice(2) + digits[bytes[1] % digits.length];
}

if ($("trainerForm")) {
  $("generatePassword").addEventListener("click", () => {
    $("trainerPassword").value = generatePassword();
    $("trainerPassword").select();
  });
  $("refreshTrainersButton").addEventListener("click", loadTrainers);
  $("trainerForm").addEventListener("submit", async (event) => {
    event.preventDefault();
    if (!state.isAdmin) return;
    const status = $("trainerFormStatus");
    $("createTrainerButton").disabled = true;
    status.textContent = "Creating trainer account…";
    try {
      const created = await callStaff("create", {
        displayName: $("trainerName").value,
        email: $("trainerEmail").value,
        password: $("trainerPassword").value,
      });
      let profileNote = " They are now listed in the app for members to request.";
      try {
        await saveTrainerProfile(created.uid, {
          displayName: created.displayName, specialty: $("trainerSpecialty").value, bio: $("trainerBio").value, active: true,
        });
      } catch (_) {
        profileNote = " The app profile could not be saved yet; use Add profile in the list.";
      }
      status.textContent = `Trainer account created for ${created.email}. Give them the password privately; they sign in at the staff login page.${profileNote}`;
      $("trainerForm").reset();
      await loadTrainers();
    } catch (error) {
      status.textContent = staffErrorMessage(error);
    } finally {
      $("createTrainerButton").disabled = false;
    }
  });
}
