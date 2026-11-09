'use strict';

const projectId = 'grindfit-34b02';

async function grantAdmin(auth, uid) {
  if (typeof uid !== 'string' || !uid.length || uid.length > 128 || /[\x00-\x1f]/.test(uid)) throw new Error('Enter a valid Firebase user UID.');
  const user = await auth.getUser(uid);
  if (user.disabled) throw new Error('This user is disabled. Review the account in Firebase Authentication first.');
  if (user.customClaims?.admin !== true) {
    await auth.setCustomUserClaims(uid, {...user.customClaims, admin: true});
  }
  const verified = await auth.getUser(uid);
  if (verified.customClaims?.admin !== true) throw new Error('Admin claim could not be verified. Check the account before retrying.');
  return {uid: verified.uid, admin: true};
}

async function main() {
  // Use the installed CLI's own credential refresh, never print or copy tokens.
  const cliAuth = require('firebase-tools/lib/auth');
  const account = cliAuth.getGlobalDefaultAccount();
  if (process.argv[2] === '--check-auth') {
    if (!account) { process.exitCode = 2; return; }
    console.log('Firebase CLI account is available.');
    return;
  }
  if (!account) throw new Error('Sign in with the Firebase CLI using a project owner/admin Google account first.');
  const uid = process.argv[2];
  if (!uid) throw new Error('Usage: node functions/grant-admin.cjs <Firebase UID>');
  const {initializeApp} = require('firebase-admin/app');
  const {getAuth} = require('firebase-admin/auth');
  const app = initializeApp({projectId, credential: {
    async getAccessToken() {
      const token = await cliAuth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
      return {access_token: token.access_token, expires_in: token.expires_in || 3600};
    },
  }});
  const result = await grantAdmin(getAuth(app), uid);
  console.log(`Verified admin access: ${result.uid} in ${projectId}.`);
  console.log('Sign out of the admin website, then sign in again using this account\'s email and password.');
}

if (require.main === module) main().catch((error) => {
  // Avoid outputting credential objects or HTTP headers from SDK errors.
  if (error.code === 'auth/user-not-found') console.error('The UID was not found in grindfit-34b02. Check Firebase Authentication.');
  else if (/permission|credential|unauthorized|insufficient/i.test(error.message || '')) console.error('Firebase access was denied. Sign in with a Google account allowed to manage Authentication users in grindfit-34b02.');
  else console.error(error.message || 'Admin setup failed.');
  process.exitCode = 1;
});

module.exports = {grantAdmin};
