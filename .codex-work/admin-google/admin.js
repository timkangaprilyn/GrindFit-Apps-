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
  where,
} from "https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js";

const firebaseConfig = {
  apiKey: "AIzaSyCNyPiUv2EAd-q5clrX8nzH58LFOiuwJf0",
  authDomain: "grindfit-app.firebaseapp.com",
  projectId: "grindfit-app",
  storageBucket: "grindfit-app.firebasestorage.app",
  messagingSenderId: "868787273216",
  appId: "1:868787273216:web:e4232fc7593852e28462e5",
  measurementId: "G-FCXCLGGXSF",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const $ = (id) => document.getElementById(id);

const state = {
  user: null,
  isAdmin: false,
  members: [],
  settings: { inactiveDays: 14, injuryThreshold: 3 },
};

const loginView = $("loginView");
const adminView = $("adminView");
const pageError = $("pageError");
const memberDialog = $("memberDialog");

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
  const startMonth = new Intl.DateTimeFormat(undefined, { month: "short" }).format(start);
  const endMonth = new Intl.DateTimeFormat(undefined, { month: "short" }).format(end);
  const startDay = new Intl.DateTimeFormat(undefined, { day: "numeric" }).format(start);
  const endDay = new Intl.DateTimeFormat(undefined, { day: "numeric" }).format(end);
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
  return Number.isInteger(parsed) && parsed >= min && parsed <= max ? parsed : fallback;
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
  const result = await getDocs(query(collection(db, "users", uid, "workouts"), ...constraints));
  return result.docs.map((snapshot) => ({
    id: snapshot.id,
    ...snapshot.data(),
  }));
}

async function getLatestWorkoutDate(uid, until) {
  const constraints = [];
  if (until) constraints.push(where("timestamp", "<", Timestamp.fromDate(until)));
  constraints.push(orderBy("timestamp", "desc"), limit(1));
  const result = await getDocs(query(collection(db, "users", uid, "workouts"), ...constraints));
  return result.empty ? null : workoutDate(result.docs[0].data());
}

async function loadMembers() {
  const users = await getDocs(collection(db, "users"));
  const memberProfiles = users.docs
    .map((snapshot) => ({ id: snapshot.id, ...snapshot.data() }))
    .filter((profile) => !["admin", "trainer"].includes(String(profile.role ?? "member").toLowerCase()));

  const now = new Date();
  const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
  const fourDaysAgo = new Date(now.getTime() - 4 * 24 * 60 * 60 * 1000);
  const fourWeeksAgo = new Date(now.getTime() - 28 * 24 * 60 * 60 * 1000);
  const endOfNow = new Date(now.getTime() + 1);
  const weekStart = startOfWeek(now);

  state.members = await Promise.all(
    memberProfiles.map(async (profile) => {
      const [workouts, lastWorkout] = await Promise.all([
        getMemberWorkouts(profile.id, fourWeeksAgo, endOfNow),
        getLatestWorkoutDate(profile.id, endOfNow),
      ]);
      const datedWorkouts = workouts
        .map((workout) => ({ workout, date: workoutDate(workout) }))
        .filter((entry) => entry.date)
        .sort((a, b) => b.date - a.date);
      const weeklyCount = datedWorkouts.filter((entry) => entry.date >= weekStart && entry.date <= now).length;
      const recentCount = datedWorkouts.filter((entry) => entry.date >= fourteenDaysAgo && entry.date <= now).length;
      const fourDayCount = datedWorkouts.filter((entry) => entry.date >= fourDaysAgo && entry.date <= now).length;
      const injuryAlert =
        profile.hasInjuryOrCondition === true || String(profile.injuryDetails ?? "").trim().length > 0;
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
    })
  );
}

function renderDashboard() {
  const members = state.members;
  const active = members.filter((member) => member.recentCount > 0).length;
  const weeklyTotal = members.reduce((total, member) => total + member.weeklyCount, 0);
  $("totalMembers").textContent = String(members.length);
  $("activeMembers").textContent = String(active);
  $("retentionRate").textContent = members.length ? `${Math.round((active / members.length) * 100)}%` : "0%";
  $("retentionFormula").textContent = `${active} active / ${members.length} members`;
  $("weeklyWorkouts").textContent = String(weeklyTotal);

  const now = new Date();
  const start = startOfWeek(now);
  const weeks = Array.from({ length: 4 }, (_, index) => {
    const weekStart = new Date(start);
    weekStart.setDate(start.getDate() - (3 - index) * 7);
    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 7);
    const count = members.reduce((total, member) => {
      return (
        total +
        member.workouts.filter((workout) => {
          const date = workoutDate(workout);
          return date && date >= weekStart && date < weekEnd;
        }).length
      );
    }, 0);
    return { weekStart, count };
  });

  const maxCount = Math.max(4, Math.ceil(Math.max(...weeks.map((week) => week.count)) / 4) * 4);
  const ticks = [maxCount, maxCount * 0.75, maxCount * 0.5, maxCount * 0.25, 0];
  $("activityChart").setAttribute(
    "aria-label",
    `Workout sessions per week for the last four weeks. Highest weekly count: ${maxCount}.`
  );
  $("activityChart").innerHTML = `
    <div class="chart-y-axis" aria-hidden="true">
      ${ticks.map((tick) => `<span>${Math.round(tick)}</span>`).join("")}
    </div>
    <div class="chart-series">
      ${weeks
        .map(({ weekStart, count }) => {
          const height = (count / maxCount) * 100;
          return `<div class="chart-column">
          <div class="chart-plot">
            <b class="chart-value" style="bottom:calc(${height}% + 4px)">${count}</b>
            <div class="chart-bar" style="height:${height}%"></div>
          </div>
          <span>${escapeHtml(formatWeekRange(weekStart))}</span>
        </div>`;
        })
        .join("")}
    </div>`;

  const risks = members.filter((member) => member.injuryAlert || member.recoveryAlert);
  $("riskSummary").innerHTML = risks.length
    ? `<div class="risk-list">${risks
        .map(
          (member) =>
            `<div class="risk-row"><strong>${escapeHtml(
              member.fullName || member.email || "Member"
            )}</strong><span>${escapeHtml(
              member.injuryAlert
                ? member.injuryDetails || "Health condition noted; review profile before training."
                : `${member.fourDayCount} workouts in four days; recovery review threshold reached.`
            )}</span></div>`
        )
        .join("")}</div>`
    : '<div class="empty-state">No injury, health, or high-frequency recovery alerts.</div>';
  renderMembers();
}

function renderMembers() {
  const search = $("memberSearch").value.trim().toLowerCase();
  const filter = $("memberFilter").value;
  const sort = $("memberSort").value;
  const inactiveOption = $("inactiveFilterLabel");
  if (inactiveOption) {
    inactiveOption.textContent = `No workout in last ${state.settings.inactiveDays} days`;
  }
  let members = state.members.filter((member) => {
    if (filter === "risk" && !member.injuryAlert && !member.recoveryAlert) return false;
    if (
      filter === "inactive" &&
      member.lastWorkout &&
      member.lastWorkout >= new Date(Date.now() - state.settings.inactiveDays * 24 * 60 * 60 * 1000)
    )
      return false;
    const searchable = `${member.fullName ?? ""} ${member.email ?? ""} ${normalizeGoalLabel(
      member.fitnessGoal
    )}`.toLowerCase();
    return searchable.includes(search);
  });
  members = [...members].sort((a, b) => {
    if (sort === "name") return String(a.fullName ?? "").localeCompare(String(b.fullName ?? ""));
    if (sort === "weekly") return b.weeklyCount - a.weeklyCount;
    if (sort === "risk") {
      return Number(b.injuryAlert || b.recoveryAlert) - Number(a.injuryAlert || a.recoveryAlert);
    }
    return (b.lastWorkout?.getTime() ?? 0) - (a.lastWorkout?.getTime() ?? 0);
  });

  $("memberRows").innerHTML = members.length
    ? members
        .map(
          (member) => `<tr data-member-id="${escapeHtml(member.id)}">
        <td><div class="member-name">${escapeHtml(
          member.fullName || "Unnamed member"
        )}</div><div class="member-email">${escapeHtml(member.email || "No email")}</div></td>
        <td>${escapeHtml(normalizeGoalLabel(member.fitnessGoal))}</td>
        <td>${escapeHtml(formatDate(member.lastWorkout))}</td>
        <td>${member.weeklyCount}</td>
        <td><span class="badge ${member.injuryAlert || member.recoveryAlert ? "alert" : "clear"}">${
            member.injuryAlert || member.recoveryAlert ? "Review" : "None"
          }</span></td>
      </tr>`
        )
        .join("")
    : '<tr><td colspan="5" class="muted">No members match this filter.</td></tr>';

  $("memberRows").querySelectorAll("[data-member-id]").forEach((row) => {
    row.addEventListener("click", () => openMember(row.dataset.memberId));
  });
}

async function openMember(uid) {
  const member = state.members.find((item) => item.id === uid);
  if (!member) return;
  $("detailName").textContent = member.fullName || member.email || "Member";
  $("detailSummary").innerHTML = [
    ["Fitness goal", normalizeGoalLabel(member.fitnessGoal)],
    ["Workout environment", member.workoutEnvironment || member.environment || "Not set"],
    ["Program duration", member.programDurationMonths ? `${member.programDurationMonths} months` : "Not set"],
    ["Workouts this week", member.weeklyCount],
    ["Last workout", formatDate(member.lastWorkout)],
    ["Injury / health info", member.injuryDetails || (member.injuryAlert ? "Reported" : "None reported")],
    ["Workouts in last 4 days", member.fourDayCount],
  ]
    .map(
      ([label, value]) =>
        `<div class="detail-cell"><span>${escapeHtml(label)}</span><strong>${escapeHtml(value)}</strong></div>`
    )
    .join("");
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
      new Date(Date.now() + 1)
    );
    if (!memberDialog.open) return;
    $("detailWorkouts").innerHTML = workouts.length
      ? workouts
          .map((workout) => {
            const exerciseList = Array.isArray(workout.exercises)
              ? workout.exercises
                  .map((exercise) => {
                    if (typeof exercise === "string") return exercise;
                    return `${exercise.name ?? "Exercise"} (${exercise.sets ?? 0} sets × ${exercise.reps ?? 0} reps${
                      exercise.weight ? `, ${exercise.weight} kg` : ""
                    })`;
                  })
                  .join(", ")
              : "Exercise details unavailable";
            return `<article class="detail-workout"><strong>${escapeHtml(
              workout.title || workout.workoutName || "Workout session"
            )}</strong><p>${escapeHtml(formatDate(workoutDate(workout)))} · ${escapeHtml(
              workout.duration || "Duration unavailable"
            )} · ${escapeHtml(workout.intensity || "Intensity unavailable")}</p><p>${escapeHtml(
              exerciseList
            )}</p></article>`;
          })
          .join("")
      : '<div class="empty-state">No workout sessions recorded in the last 90 days.</div>';
  } catch (error) {
    if (memberDialog.open) {
      $("detailWorkouts").innerHTML = `<div class="error">${escapeHtml(
        error.message || "Could not load workout details."
      )}</div>`;
    }
  }
}

async function refreshDashboard() {
  showError("");
  $("refreshButton").disabled = true;
  try {
    await loadMembers();
    renderDashboard();
  } catch (error) {
    showError(error.message || "Unable to load member data. Verify admin access and retry.");
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
  $("adminAccountInfo").textContent = `Signed in as ${
    state.user.email || "staff account"
  }. Verification status: Admin access active.`;
}

async function saveSettings() {
  const inactiveDays = Number($("inactiveDays").value);
  const injuryThreshold = Number($("injuryThreshold").value);
  if (
    !Number.isInteger(inactiveDays) ||
    inactiveDays < 1 ||
    inactiveDays > 365 ||
    !Number.isInteger(injuryThreshold) ||
    injuryThreshold < 1 ||
    injuryThreshold > 14
  ) {
    $("settingsStatus").textContent = "Enter valid values within the displayed ranges.";
    return;
  }
  $("settingsStatus").textContent = "Saving…";
  try {
    const updatedSettings = { inactiveDays, injuryThreshold };
    await setDoc(
      doc(db, "admin_settings", "global"),
      {
        ...updatedSettings,
        updatedAt: Timestamp.now(),
        updatedBy: state.user.uid,
      },
      { merge: true }
    );
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
    const memberWorkouts = await Promise.all(
      state.members.map(async (member) => ({
        member,
        workouts: await getMemberWorkouts(member.id, fromDate, untilDate),
      }))
    );
    for (const { member, workouts } of memberWorkouts) {
      for (const workout of workouts) {
        const exercises = Array.isArray(workout.exercises)
          ? workout.exercises
              .map((item) => (typeof item === "string" ? item : item.name || "Exercise"))
              .join("; ")
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
    const csv = rows
      .map((row) => row.map((field) => `"${String(field ?? "").replaceAll('"', '""')}"`).join(","))
      .join("\r\n");
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

  const email = state.user?.email || "";
  const adminNameEl = $("adminName");
  const adminEmailEl = $("adminEmail");
  const userAvatarEl = $("userAvatar");

  if (adminNameEl) adminNameEl.textContent = state.user?.displayName || (state.isAdmin ? "Administrator" : "Trainer");
  if (adminEmailEl) adminEmailEl.textContent = email;
  if (userAvatarEl) userAvatarEl.textContent = (email[0] || "A").toUpperCase();
}

function showLogin(message = "") {
  adminView.hidden = true;
  loginView.hidden = false;
  $("loginError").textContent = message;
}

// Only trusted Firebase token claims authorize staff access.
onAuthStateChanged(auth, async (user) => {
  if (!user) {
    state.user = null;
    state.isAdmin = false;
    state.members = [];
    memberDialog.close();
    showLogin();
    return;
  }
  try {
    const token = await user.getIdTokenResult(true);
    const hasAccess = token.claims.admin === true || token.claims.trainer === true;
    const isAdminRole = token.claims.admin === true;

    if (!hasAccess) {
      state.isAdmin = false;
      await signOut(auth);
      showLogin("This account has no staff access. Ask your administrator to grant admin or trainer access, then sign in again.");
      return;
    }

    state.user = user;
    state.isAdmin = isAdminRole;
    showAdmin();
    await loadSettings();
    await refreshDashboard();
  } catch (error) {
    state.user = null;
    state.isAdmin = false;
    state.members = [];
    showLogin(error.message || "Could not verify staff access.");
  }
});

let authBusy = false;
function setAuthBusy(busy) {
  authBusy = busy;
  $("loginButton").disabled = busy;
  $("loginForm").setAttribute("aria-busy", String(busy));
}

$("loginForm").addEventListener("submit", async (event) => {
  event.preventDefault();
  if (authBusy) return;
  setAuthBusy(true);
  $("loginError").textContent = "Signing in...";
  
  const emailVal = $("email").value.trim();
  const passVal = $("password").value;

  try {
    await signInWithEmailAndPassword(auth, emailVal, passVal);
  } catch (error) {
    let friendlyMessage = error.message;
    if (error.code === "auth/invalid-credential" || error.code === "auth/wrong-password" || error.code === "auth/user-not-found") {
      friendlyMessage = "Incorrect email or password. Please check your credentials.";
    }
    $("loginError").textContent = friendlyMessage;
  } finally {
    setAuthBusy(false);
  }
});

$("logoutButton").addEventListener("click", () => signOut(auth));
$("refreshButton").addEventListener("click", refreshDashboard);
$("memberSearch").addEventListener("input", renderMembers);
$("memberFilter").addEventListener("change", renderMembers);
$("memberSort").addEventListener("change", renderMembers);
$("saveSettingsButton").addEventListener("click", saveSettings);
$("exportButton").addEventListener("click", exportReport);
$("closeDialog").addEventListener("click", () => memberDialog.close());
document.querySelectorAll(".nav-button").forEach((button) => {
  button.addEventListener("click", () => {
    document.querySelectorAll(".nav-button").forEach((item) => item.classList.remove("active"));
    document.querySelectorAll(".page-view").forEach((view) => {
      view.hidden = true;
    });
    button.classList.add("active");
    $(button.dataset.view).hidden = false;
  });
});

const reportTo = new Date();
const reportFrom = new Date();
reportFrom.setDate(reportTo.getDate() - 29);
$("reportFrom").value = toLocalDateInput(reportFrom);
$("reportTo").value = toLocalDateInput(reportTo);