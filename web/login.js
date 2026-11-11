import {firebaseConfig} from './admin-config.js';
import {staffHome} from './admin-utils.mjs';

const $ = (id) => document.getElementById(id);
const params = new URLSearchParams(location.search);

$('togglePassword').addEventListener('click', () => {
  const show = $('password').type === 'password';
  $('password').type = show ? 'text' : 'password';
  $('togglePassword').textContent = show ? 'Hide' : 'Show';
  $('togglePassword').setAttribute('aria-label', show ? 'Hide password' : 'Show password');
  $('togglePassword').setAttribute('aria-pressed', String(show));
});

if (params.get('denied') === '1') {
  $('loginError').textContent = 'This account does not have admin or trainer access.';
}

function loginMessage(error) {
  switch (error.code) {
    case 'auth/invalid-credential':
    case 'auth/wrong-password':
    case 'auth/user-not-found':
      return 'Hindi tama ang email o password, o wala pang account na may ganitong email sa Firebase Authentication.';
    case 'auth/invalid-email':
      return 'Pakisuri ang email address.';
    case 'auth/too-many-requests':
      return 'Masyadong maraming pagtatangka. Maghintay muna bago subukan ulit.';
    case 'auth/network-request-failed':
      return 'Walang koneksyon sa Firebase. Suriin ang internet at subukan ulit.';
    default:
      return error.message || 'Hindi makapag-sign in. Subukan ulit.';
  }
}

try {
  const [{initializeApp}, {getAuth, onAuthStateChanged, signInWithEmailAndPassword, signOut}] = await Promise.all([
    import('https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js'),
    import('https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js'),
  ]);
  const auth = getAuth(initializeApp(firebaseConfig));

  // Already signed in, or just signed in: send staff to the dashboard for their role.
  onAuthStateChanged(auth, async (user) => {
    if (!user) return;
    try {
      const token = await user.getIdTokenResult(true);
      if (auth.currentUser?.uid !== user.uid) return;
      const home = staffHome(token.claims);
      if (home) {
        location.replace(`./${home}`);
        return;
      }
      await signOut(auth);
      $('loginError').textContent = 'This account does not have admin or trainer access.';
    } catch (error) {
      $('loginError').textContent = error.message || 'Could not verify staff access.';
    }
  });

  $('loginForm').addEventListener('submit', async (event) => {
    event.preventDefault();
    $('loginButton').disabled = true;
    $('loginError').textContent = '';
    try {
      await signInWithEmailAndPassword(auth, $('email').value.trim(), $('password').value);
    } catch (error) {
      $('loginError').textContent = loginMessage(error);
      $('password').value = '';
    } finally {
      $('loginButton').disabled = false;
    }
  });
} catch (_) {
  $('loginButton').disabled = true;
  $('bootStatus').textContent = 'Could not load sign in. Check your connection and refresh this page.';
}
