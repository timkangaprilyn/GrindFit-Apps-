'use strict';

const STAFF_ROLES = {admin: 'GrindFit Admin', trainer: 'GrindFit Trainer'};

async function createStaff(auth, email, password, role = 'admin', {displayName = STAFF_ROLES[role], minPasswordLength = 20} = {}) {
  if (!Object.hasOwn(STAFF_ROLES, role)) throw new Error('Role must be admin or trainer.');
  if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('Invalid email.');
  if (typeof password !== 'string' || password.length < minPasswordLength) throw new Error('A strong generated password is required.');
  // Never reset credentials or promote an existing email implicitly.
  try {
    await auth.getUserByEmail(email);
    throw new Error('This email already exists. No account or password was changed.');
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  const user = await auth.createUser({email, password, disabled: true, displayName, emailVerified: false});
  // Leave a partially configured account disabled if either privileged step fails.
  await auth.setCustomUserClaims(user.uid, {[role]: true});
  await auth.updateUser(user.uid, {disabled: false});
  const verified = await auth.getUser(user.uid);
  if (verified.customClaims?.[role] !== true || verified.disabled) throw new Error('Account creation was not fully verified. Review Firebase Authentication.');
  return {uid: user.uid, role, [role]: true};
}

const createAdmin = (auth, email, password) => createStaff(auth, email, password, 'admin');

async function main() {
  const cliAuth = require('firebase-tools/lib/auth');
  const account = cliAuth.getGlobalDefaultAccount();
  if (!account) throw new Error('Sign in with the Firebase CLI project-owner account first.');
  const {initializeApp} = require('firebase-admin/app');
  const {getAuth} = require('firebase-admin/auth');
  const app = initializeApp({projectId:'grindfit-34b02',credential:{
    async getAccessToken() {
      const token = await cliAuth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform','https://www.googleapis.com/auth/firebase']);
      return {access_token:token.access_token,expires_in:token.expires_in || 3600};
    },
  }});
  let input = '';
  for await (const chunk of process.stdin) {
    input += chunk;
    if (input.length > 4096) throw new Error('Input too large.');
  }
  const credentials = JSON.parse(input.replace(/^\uFEFF/, ''));
  const result = await createStaff(getAuth(app), credentials.email, credentials.password, credentials.role ?? 'admin');
  console.log(JSON.stringify(result));
}

if (require.main === module) main().catch((error) => {
  if (/already exists/.test(error.message || '')) console.error(error.message);
  else if (/permission|credential|unauthorized|insufficient/i.test(error.message || '')) console.error('Firebase denied account creation. Use an account with Authentication administration access.');
  else console.error('Staff account setup failed or is incomplete. Check Firebase Authentication; credentials were not printed.');
  process.exitCode = 1;
});
module.exports = {createAdmin, createStaff};
