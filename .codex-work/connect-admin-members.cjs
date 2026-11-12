const fs=require('node:fs');
const locations=['C:/Users/Acer/Desktop/grindfit_admin','web'];
for(const directory of locations){
 const file=directory+'/admin.js';let s=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
 s='import { createMemberSync } from "./member-sync.mjs";\n'+s;
 s=s.replace('  getFirestore,','  getFirestore,\n  onSnapshot,');
 const start=s.indexOf('async function loadMembers() {');
 const end=s.indexOf('function renderDashboard()',start);
 if(start<0||end<0)throw Error('Member loader missing');
 s=s.slice(0,start)+`let membersSync = null;
function stopMemberSync() {
  membersSync?.stop();
  membersSync = null;
  state.members = [];
  if (memberDialog.open) memberDialog.close();
  $("memberRows").innerHTML = '<tr><td colspan="5" class="muted">Sign in to load members.</td></tr>';
}

async function loadMembers() {
  if (!state.user) return;
  if (!membersSync) {
    membersSync = createMemberSync({
      settings: () => state.settings,
      subscribeProfiles: (next,error) => onSnapshot(collection(db,"users"), snapshot => {
        next(snapshot.docs.map(doc => ({...doc.data(),id:doc.id})));
      },error),
      subscribeActivity: (uid,next,error) => {
        let recent = null;
        let latest = null;
        const publish = () => { if (recent !== null && latest !== null) next({workouts:recent,lastWorkout:latest[0] ? workoutDate(latest[0]) : null}); };
        const stopRecent = onSnapshot(query(collection(db,"users",uid,"workouts"),
          where("timestamp",">=",Timestamp.fromDate(new Date(Date.now()-28*86400000))), orderBy("timestamp","desc")), snapshot => {
            recent=snapshot.docs.map(doc=>({...doc.data(),id:doc.id})); publish();
          },error);
        const stopLatest = onSnapshot(query(collection(db,"users",uid,"workouts"),orderBy("timestamp","desc"),limit(1)),snapshot=>{
          latest=snapshot.docs.map(doc=>doc.data()); publish();
        },error);
        return () => { stopRecent(); stopLatest(); };
      },
      onChange: members => { state.members=members; renderDashboard(); },
      onStatus: message => { $("membersStatus").textContent=message; },
      onError: error => showError(error.code === "permission-denied"
        ? "Member data access was denied. Sign out and sign in again with your staff account."
        : "Could not sync member data. Check your connection, then click Reconnect."),
    });
  }
  let timer;
  try {
    await Promise.race([membersSync.ready,new Promise((_,reject)=>{
      timer=setTimeout(()=>reject(new Error("Member connection timed out. Check your internet and click Reconnect.")),15000);
    })]);
  } finally { clearTimeout(timer); }
}

`+s.slice(end);
 s=s.replace('  if (!user) {\n    state.user', '  if (!user) {\n    stopMemberSync();\n    state.user');
 s=s.replace('  $("memberRows").innerHTML = members.length', '  $("memberRows").innerHTML = members.length');
 s=s.replace('escapeHtml(formatDate(member.lastWorkout))','escapeHtml(member.activityError ? "Unavailable" : formatDate(member.lastWorkout))');
 s=s.replace('${member.weeklyCount}</td>', '${member.activityError ? "Unavailable" : member.weeklyCount}</td>');
 s=s.replace('    ["Workouts this week", member.weeklyCount],', `    ["Fitness level", member.fitnessLevel || "Not set"],
    ["Workout schedule", Array.isArray(member.workoutDays) ? member.workoutDays.join(", ") : "Not set"],
    ["Session duration", member.sessionDuration || "Not set"],
    ["Program day", member.currentDayIndex || 1],
    ["Workouts this week", member.activityError ? "Unavailable" : member.weeklyCount],`);
 s=s.replace('    if (!memberDialog.open) return;', '    if (!memberDialog.open || !state.user || $("detailName").dataset.memberId !== uid) return;');
 s=s.replace('  $("detailName").textContent =', '  $("detailName").dataset.memberId = uid;\n  $("detailName").textContent =');
 s+=`\n$("reconnectMembersButton").addEventListener("click", async () => {
  stopMemberSync();
  $("reconnectMembersButton").disabled=true;
  try { await refreshDashboard(); } finally { $("reconnectMembersButton").disabled=false; }
});\n`;
 fs.writeFileSync(file,s);
 const html=directory+'/admin.html';let h=fs.readFileSync(html,'utf8');
 h=h.replace('<div class="toolbar">','<p id="membersStatus" class="muted" role="status" aria-live="polite">Connecting to member data…</p>\n            <button id="reconnectMembersButton" class="button subtle" type="button">Reconnect</button>\n            <div class="toolbar">');
 h=h.replace('placeholder="Search name or goal"','placeholder="Search name, email or goal"');
 fs.writeFileSync(html,h);
 if(directory!=='web')fs.copyFileSync('web/member-sync.mjs',directory+'/member-sync.mjs');
}
