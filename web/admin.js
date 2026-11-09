import {memberPage, csvCell} from './admin-utils.mjs';
import {setupInterface, renderExtras} from './admin-interface.js';
import {firebaseConfig, supabaseConfig} from './admin-config.js';
import {requestAdminData} from './admin-cloud.mjs';
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js";
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
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
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const $ = (id) => document.getElementById(id);
const state = {
  user: null,
  isAdmin: false,
  members: [],
  page: 1,
  settings: { inactiveDays: 14, injuryThreshold: 3 },
};

const loginView = $("loginView");
const adminView = $("adminView");
const pageError = $("pageError");
const memberDialog = $("memberDialog");
let cloudRequestVersion = 0;
let connectionVersion = 0;

async function checkSupabase() {
  const owner = state.user?.uid;
  const version = ++connectionVersion;
  const status = $('supabaseConnection');
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

$('retryCloudMember').addEventListener('click', () => { if (activeMemberUid) loadCloudMember(activeMemberUid); });

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
  const users = await getDocs(collection(db, "users"));
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
  $("trainerUid").value = member.trainerUid || "";
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
  $("inactiveDays").value = state.settings.inactiveDays;
  $("injuryThreshold").value = state.settings.injuryThreshold;
  $("saveSettingsButton").hidden = !state.isAdmin;
  $("settingsAccessNotice").hidden = state.isAdmin;
  $("inactiveDays").readOnly = !state.isAdmin;
  $("injuryThreshold").readOnly = !state.isAdmin;
  $("adminAccountInfo").textContent =
    `Signed in as ${state.user.email || "staff account"}. This account's access is verified using Firebase Authentication custom claims. Claims for other accounts cannot be listed or changed here; use a trusted Firebase Admin SDK environment.`;
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
  loginView.hidden = true;
  adminView.hidden = false;
  $("adminEmail").textContent = state.user.email || "";
  $("staffRole").textContent = state.isAdmin ? 'Admin' : 'Trainer';
}

function showLogin(message = "") {
  adminView.hidden = true;
  loginView.hidden = false;
  $("loginError").textContent = message;
}

onAuthStateChanged(auth, async (user) => {
  if (!user) {
    state.user = null;
    state.isAdmin = false;
    state.members = [];
    activeMemberUid = null;
    editingNoteId = null;
    memberDialog.close();
    $("password").value = '';
    $("coachNoteText").value = '';
    cloudRequestVersion++;
    connectionVersion++;
    $("cloudMemberData").replaceChildren();
    $("firebaseConnection").textContent = 'Sign in to verify connection';
    $("supabaseConnection").textContent = 'Sign in with admin access to verify';
    $("firebaseConnection").removeAttribute('data-state');
    $("supabaseConnection").removeAttribute('data-state');
    renderDashboard();
    $("lastUpdated").textContent = 'Sign in to load member data';
    showLogin();
    return;
  }
  try {
    const token = await user.getIdTokenResult(true);
    if (auth.currentUser?.uid !== user.uid) return;
    if (token.claims.admin !== true && token.claims.trainer !== true) {
      state.isAdmin = false;
      await signOut(auth);
      showLogin("This account does not have admin or trainer access.");
      return;
    }
    state.user = user;
    state.isAdmin = token.claims.admin === true;
    showAdmin();
    await loadSettings();
    await refreshDashboard();
  } catch (error) {
    showError(error.message || "Could not verify staff access.");
    showLogin(error.message || "Could not verify staff access.");
  }
});

$("loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  $("loginButton").disabled = true;
  $("loginError").textContent = "";
  try {
    await signInWithEmailAndPassword(auth, $("email").value.trim(), $("password").value);
  } catch (error) {
    $("loginError").textContent = error.code === "auth/invalid-credential" ||
        error.code === "auth/wrong-password" ||
        error.code === "auth/user-not-found"
      ? "Hindi tama ang email o password, o wala pang account na may ganitong email sa Firebase Authentication."
      : error.code === "auth/invalid-email"
        ? "Pakisuri ang email address."
        : error.code === "auth/too-many-requests"
          ? "Masyadong maraming pagtatangka. Maghintay muna bago subukan ulit."
          : error.code === "auth/network-request-failed"
            ? "Walang koneksyon sa Firebase. Suriin ang internet at subukan ulit."
            : error.message || "Hindi makapag-sign in. Subukan ulit.";
  } finally {
    $("loginButton").disabled = false;
  }
});

$("logoutButton").addEventListener("click", () => signOut(auth));
$("refreshButton").addEventListener("click", refreshDashboard);
function resetMemberPage() { state.page = 1; renderMembers(); }
$("memberSearch").addEventListener("input", resetMemberPage);
$("memberFilter").addEventListener("change", resetMemberPage);
$("memberSort").addEventListener("change", resetMemberPage);
$("saveSettingsButton").addEventListener("click", saveSettings);
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
    await updateDoc(doc(db, "users", uid), { trainerUid });
    const member = state.members.find((item) => item.id === uid);
    if (member) member.trainerUid = trainerUid;
    $("coachNoteStatus").textContent = "Trainer assignment saved.";
  } catch (error) { $("coachNoteStatus").textContent = error.message || "Could not save assignment."; }
  finally { $("assignTrainerButton").disabled = false; }
});
