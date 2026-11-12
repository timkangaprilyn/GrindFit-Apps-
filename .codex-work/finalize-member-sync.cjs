const fs=require('node:fs');
for(const directory of ['web','C:/Users/Acer/Desktop/grindfit_admin']){
 const file=directory+'/admin.js';let s=fs.readFileSync(file,'utf8');
 s=s.replace('onAuthStateChanged(auth, async (user) => {',`onAuthStateChanged(auth, async (user) => {
  stopMemberSync();
  state.user = null;
  state.isAdmin = false;
  showLogin(user ? "Verifying staff access…" : "");`);
 s=s.replace('    showAdmin();\n    await loadSettings();\n    await refreshDashboard();', `    showAdmin();
    try {
      await loadSettings();
    } catch (error) {
      showError("Signed in, but admin settings could not be loaded. Check your connection and retry.");
    }
    await refreshDashboard();`);
 s=s.replace('    if (memberDialog.open) {\n      $("detailWorkouts")', '    if (memberDialog.open && state.user && $("detailName").dataset.memberId === uid) {\n      $("detailWorkouts")');
 fs.writeFileSync(file,s);
}
