# GrindFit feature backend

Targets Firebase project `grindfit-34b02`. Nothing in this directory is deployed
automatically. Local UI and offline logging work independently of deployment.

Install Node.js 22 and the Firebase CLI, then:

```powershell
cd functions
npm ci
npm test
cd ..
firebase login
firebase functions:secrets:set GEMINI_API_KEY --project grindfit-34b02
firebase deploy --only functions,firestore:rules --project grindfit-34b02
```

Cloud Functions requires an eligible billing plan. Enable the Gemini API for
the key you store in Secret Manager. `GEMINI_MODEL` defaults to
`gemini-2.5-flash`; configure a supported model at deployment when prompted.
Never put the Gemini key in Flutter, web assets, git, or chat.

- `generateWorkoutPlan`: authenticated callable; ten attempts per UTC day.
  Reads saved profile settings, sends only fitness context (not name, email,
  weight or detailed injury history), accepts up to 500 characters, selects
  from a fixed exercise catalog and validates names and load bounds. It
  declines unknown/general pain requests. The app keeps its offline plan
  when the function is unavailable. AI suggestions are not injury treatment.
- `awardWorkoutXp`: Firestore create trigger with retry and transaction ledger.
  A workout of at least 60 seconds with a non-skipped completed set earns
  50 XP, up to three credited sessions per UTC day. Duplicate event delivery
  cannot award twice. Client logs are self-reported, not proof of exercise.
  Records more than 60 days old and future timestamps earn no XP.
- `setMonthlyChallenge`: explicit opt-in and public nickname, UTC month,
  random public entry ID, server-controlled count. Scores count eligible
  credited workouts in the current month (including before joining). Leaving
  removes the current public entry. Joining a later month removes the member's
  previous public entry. No UID, email, weight or injury details are public.

Coach notes use Firestore directly. Give staff trusted `trainer` or `admin`
custom claims using a privileged Admin SDK. Admins assign a trainer UID to
a member in the admin portal; members cannot assign or promote themselves.
Notes are visible to the member and staff according to the rules. Update the
admin portal's web API key restrictions/authorized domains if your project
restricts the supplied key to Android, and configure a registered web app
before using Analytics or other services that require a web app ID.

Before production, run the emulator rules tests, verify deployed rules on the
target project, configure App Check for callable abuse protection, set budget
alerts, and test signing in with member, assigned trainer, unassigned trainer
and admin accounts. Deployment and live account tests require project access;
the downloaded public `google-services.json` is not administrative access.
# Grant a staff admin claim

## Create a separate email/password admin

From the project root, after Firebase CLI project-owner login:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\functions\create-admin.ps1 -Email YOUR_ADMIN_EMAIL
```

Creates a new Firebase Authentication account with a generated password, applies
the admin claim while the account is disabled, enables it and verifies the claim.
Existing emails are rejected; their passwords and roles are never changed.
This creates a Firebase login, not a Gmail mailbox.
The password is stored only in `.dart_tool/private/admin-login.credential.xml`,
encrypted using Windows DPAPI for the current Windows user and ignored by Git.
Run `functions/show-admin-login.ps1` in your own terminal to reveal it privately.
The wrapper refuses to overwrite an existing local credential file. If a
network operation fails, retain that file and review the Firebase account before
retrying; any incompletely configured new account is left disabled.

The admin login page has no password-reset button. Firebase project owners can
still manage account recovery through Firebase. Admin access remains enforced
by trusted claims and backend rules, not by hiding login controls.

## Promote an existing UID

Run from the project root in your own interactive terminal:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\functions\grant-admin.ps1 -Uid YOUR_FIREBASE_UID
```

The helper opens Firebase CLI login when no account is available. Sign in with
a Google account authorized to manage Firebase Authentication users in
`grindfit-34b02`. It uses the installed CLI credential refresh and Firebase
Admin SDK, preserves existing claims, sets `admin: true`, then reads the user
again to confirm. It cannot grant access without project IAM permissions.
It does not create a user, change a password, enable a disabled user, or expose
credential tokens. Do not add this privileged helper to browser code.
After success, sign out of the website and back in to refresh the ID token.
