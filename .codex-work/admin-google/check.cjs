const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const js = fs.readFileSync(`${__dirname}/admin.js`, 'utf8');
const html = fs.readFileSync(`${__dirname}/admin.html`, 'utf8');
assert.match(html, /id="googleLoginButton"[^>]*type="button"/);
assert.ok(!js.includes('user.email === "admin@test.com"'));
const observer = js.slice(js.indexOf('onAuthStateChanged(auth, async'), js.indexOf('$("loginForm").addEventListener'));
const elements = new Map();
let listener;
let googleHandler;
let loads = 0;
let message;
let popupError;
let popupCalls = 0;
let googleParameters;
const state = { user: null, isAdmin: false, members: [] };
const context = {
  auth: {}, state, location: { protocol: 'https:' },
  $: id => {
    if (!elements.has(id)) elements.set(id, { textContent: '', disabled: false, setAttribute() {}, addEventListener(event, handler) { googleHandler = handler; } });
    return elements.get(id);
  },
  memberDialog: { close() {} },
  onAuthStateChanged: (auth, handler) => { listener = handler; },
  signOut: async () => { await listener(null); },
  showLogin: value => { message = value; }, showAdmin() {},
  loadSettings: async () => { loads++; }, refreshDashboard: async () => {},
  GoogleAuthProvider: class { setCustomParameters(value) { googleParameters = value; } },
  signInWithPopup: async () => { popupCalls++; if (popupError) throw popupError; },
};
vm.runInNewContext(observer, context);
(async () => {
  const user = claims => ({ email: 'admin@test.com', getIdTokenResult: async () => ({ claims }) });
  await listener(user({ admin: true }));
  assert.equal(state.isAdmin, true);
  await listener(user({ trainer: true }));
  assert.equal(state.isAdmin, false);
  assert.ok(state.user);
  await listener(user({}));
  assert.equal(state.user, null);
  assert.match(message, /no staff access/);
  assert.equal(loads, 2, 'Unauthorized users must not load staff data');
  await listener({ getIdTokenResult: async () => { throw Error('Token failure'); } });
  assert.equal(state.user, null);
  assert.equal(state.isAdmin, false);
  assert.equal(message, 'Token failure');
  await googleHandler();
  assert.equal(googleParameters.prompt, 'select_account');
  popupError = { code: 'auth/popup-closed-by-user' };
  await googleHandler();
  assert.equal(elements.get('loginError').textContent, '');
  popupError = { code: 'auth/unauthorized-domain' };
  await googleHandler();
  assert.match(elements.get('loginError').textContent, /authorized domains/);
  assert.equal(elements.get('googleLoginButton').disabled, false);
  context.location.protocol = 'file:';
  await googleHandler();
  assert.equal(popupCalls, 3);
  assert.match(elements.get('loginError').textContent, /localhost or HTTPS/);
  console.log('Passed: staff claims, denied access, token failure, Google picker, cancel, domain errors, and file URL handling.');
})().catch(error => { console.error(error); process.exitCode = 1; });
