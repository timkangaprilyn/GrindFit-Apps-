const fs = require('node:fs');
const path = require('node:path');
const file = path.join(__dirname, 'admin.js');
let js = fs.readFileSync(file, 'utf8').replaceAll('\r\n', '\n');
js = js.replace('  getAuth,', '  getAuth,\n  GoogleAuthProvider,\n  signInWithPopup,');
// Use the exact web config already registered in the mobile repository.
const options = fs.readFileSync(path.join(__dirname, '../..', 'lib/firebase_options.dart'), 'utf8');
const web = options.slice(options.indexOf('static const FirebaseOptions web'));
js = js.replace(/apiKey: "[^"]+"/, `apiKey: "${web.match(/apiKey: '([^']+)'/)[1]}"`);
js = js.replace('// Global Auth State Observer with Direct Admin Bypass', '// Only trusted Firebase token claims authorize staff access.');
const start = js.indexOf('    // Direct bypass for admin@test.com');
const end = js.indexOf('    if (!hasAccess) {\n      state.isAdmin = false;', start);
if (start < 0 || end < 0) throw Error('Auth observer did not match');
js = js.slice(0, start) + `    const token = await user.getIdTokenResult(true);
    const hasAccess = token.claims.admin === true || token.claims.trainer === true;
    const isAdminRole = token.claims.admin === true;

` + js.slice(end);
js = js.replace('Access denied: Account is not marked as admin or trainer.', 'This account has no staff access. Ask your administrator to grant admin or trainer access, then sign in again.');
js = js.replace('    state.isAdmin = false;\n    showLogin();', '    state.isAdmin = false;\n    state.members = [];\n    memberDialog.close();\n    showLogin();');
js = js.replace('    showError(error.message || "Could not verify staff access.");', '    state.user = null;\n    state.isAdmin = false;\n    state.members = [];');
js = js.replace('if (adminNameEl) adminNameEl.textContent = "System Administrator";', 'if (adminNameEl) adminNameEl.textContent = state.user?.displayName || (state.isAdmin ? "Administrator" : "Trainer");');
js = js.replace('email === "admin@test.com" ? "admin@grindfit.app" : email', 'email');
js = js.replace('$("loginButton").disabled = true;', 'if (authBusy) return;\n  setAuthBusy(true);');
js = js.replace('$("loginButton").disabled = false;', 'setAuthBusy(false);');
const anchor = '$("loginForm").addEventListener';
const helpers = `let authBusy = false;
function setAuthBusy(busy) {
  authBusy = busy;
  $("loginButton").disabled = busy;
  $("googleLoginButton").disabled = busy;
  $("loginForm").setAttribute("aria-busy", String(busy));
}

function googleSignInError(error) {
  const messages = {
    "auth/popup-closed-by-user": "",
    "auth/cancelled-popup-request": "",
    "auth/popup-blocked": "Allow pop-ups for this website, then try again.",
    "auth/unauthorized-domain": "This website domain must be added to Firebase Authentication's authorized domains.",
    "auth/operation-not-allowed": "Google sign-in must be enabled in Firebase Authentication.",
    "auth/account-exists-with-different-credential": "This email uses another sign-in method. Sign in with that method first.",
    "auth/network-request-failed": "Check your internet connection and try again.",
    "auth/user-disabled": "This account has been disabled. Contact your administrator.",
  };
  return messages[error.code] ?? "Could not sign in with Google. Please try again.";
}

$("googleLoginButton").addEventListener("click", async () => {
  if (authBusy) return;
  if (location.protocol === "file:") {
    $("loginError").textContent = "Open this website through localhost or HTTPS to sign in.";
    return;
  }
  setAuthBusy(true);
  $("loginError").textContent = "";
  try {
    const provider = new GoogleAuthProvider();
    provider.setCustomParameters({ prompt: "select_account" });
    await signInWithPopup(auth, provider);
  } catch (error) {
    $("loginError").textContent = googleSignInError(error);
  } finally {
    setAuthBusy(false);
  }
});

`;
js = js.replace(anchor, helpers + anchor);
fs.writeFileSync(file, js);
const htmlPath = path.join(__dirname, 'admin.html');
let html = fs.readFileSync(htmlPath, 'utf8');
html = html.replace('Staff access requires a trusted Firebase admin or trainer claim.', 'Sign in with your staff account to continue.');
html = html.replace('<p id="loginError" class="error" role="alert">', '<p id="loginError" class="error" role="alert" aria-live="polite">');
html = html.replace('>Sign in</button>', '>Sign in</button>\n        <button id="googleLoginButton" class="button subtle" type="button">Continue with Google</button>');
fs.writeFileSync(htmlPath, html);
