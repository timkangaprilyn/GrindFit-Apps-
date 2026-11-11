# GrindFit

GrindFit is a Flutter fitness app with Firebase Authentication and Cloud
Firestore.

## Run the Android app

```powershell
flutter pub get
flutter run
```

The Android Firebase app is configured in `android/app/google-services.json`
and `lib/firebase_options.dart`. Do not change the Android application ID
without updating the Firebase app registration.

## Enable Continue with Google

The Android app uses Firebase project `grindfit-34b02` for authentication and
Firestore. Web and iOS still have their previous `grindfit-app` configuration;
obtain platform-specific Firebase configurations before migrating those targets.
Both login and registration use the same Google authentication service. Web
uses a Firebase popup; Android and iOS use the native Google sign-in plugin.

The Android `google-services.json` includes the Google web OAuth client and
Android OAuth clients for both the original signing certificate and this
workspace's debug SHA-1 below. The local debug certificate is registered.
When configuring another signing key, follow these steps:

1. Open `grindfit-34b02` in Firebase Console, then Authentication > Sign-in
   method. Enable Google and select a project support email.
2. In Project settings > Your apps, select the Android app with package name
   `com.example.flutter_application_1`. Register the signing certificate SHA-1
   and SHA-256. For this workspace's debug keystore:

   ```text
   SHA-1: B5:3A:0F:1C:51:1C:3C:4E:EA:A2:B5:9E:96:91:A6:F0:D9:02:CC:93
   SHA-256: 3A:0B:5A:AB:C4:A5:CB:93:3C:90:E8:D0:08:89:F1:A1:21:24:D2:62:44:1E:81:BB:10:A6:F3:91:12:E4:7C:2E
   ```

3. Download the updated `google-services.json` and replace
   `android/app/google-services.json`. It must include the Google web OAuth
   client (`client_type: 3`). Stop and rebuild the app after replacing it.
4. For web, add the website hostname to Authentication > Settings > Authorized
   domains, including `localhost` for local development. Allow browser popups.

Other computers and production signing keys have different fingerprints;
register their certificates too. For iOS, download this project's
`GoogleService-Info.plist`, add it to the Runner target, and configure its
`CLIENT_ID` and `REVERSED_CLIENT_ID` URL scheme as described in the
[Google sign-in iOS setup](https://pub.dev/packages/google_sign_in_ios#ios-integration).
The current iOS runner does not include that Google configuration yet.

Verify on a device with Google Play services: tap Continue with Google,
choose an account, and check that a new member reaches the assessment while
a member with `setupCompleted: true` reaches the main screen. Cancelling the
picker should leave the login screen usable. Supabase is not part of this
app's existing authentication flow.

## Firestore access control

`firestore.rules` restricts member data to the signed-in owner. Admin access
requires the Firebase Authentication custom claim `admin: true`; a `role`
field written in a user profile is not sufficient to grant admin access.
Grant or revoke that claim only through a trusted, privileged Admin SDK
environment, never from the client app.

Review the rules against the deployed project before publishing them:

```powershell
firebase deploy --only firestore:rules --project grindfit-34b02
```

The staff portal has three pages, available after building the Flutter web
target:

- `/login.html` — staff sign-in. It reads the trusted Firebase custom claims and
  sends `admin` accounts to `/admin.html` and `trainer` accounts to
  `/trainer.html`. Other accounts are signed out.
- `/admin.html` — admin workspace for all members, settings and trainer
  assignment.
- `/trainer.html` — trainer dashboard limited to members whose `trainerUid`
  matches the trainer's Firebase UID, with coach notes and activity reports.

Members choose a coach in the app (**Your GrindFit tools → Your coach**). The
app lists active profiles from `trainers/{uid}` (name, specialty, bio, member
count) and writes one pending request to `trainer_requests/{memberUid}`. The
requested trainer (trainer dashboard) or any admin (admin dashboard) approves
or declines it under **Coaching requests**. Approval assigns `trainerUid` and
moves member counts in one batch; `firestore.rules` rejects approval without
assignment, assignment without approval, and count changes that do not match a
real move. Admins publish or hide trainer profiles from **Trainers → Edit
profile**. Rules tests: `functions/trainer-requests.emulator.test.cjs`.

Both dashboards redirect to `/login.html` without a session, and to the other
dashboard when the account's claims do not match. Add the portal's hosting
domain to Firebase Authentication's authorized domains before using it outside
localhost.

For local review, run `npm start` from the repo root (Node.js 22) and open
`http://localhost:8080/`, or open `web/login.html` with VS Code Live Server.
Append `?preview=1` to `admin.html` or `trainer.html` to inspect either
dashboard with fictional sample data. Preview loads no Firebase SDK
or member-data API and disables exports, settings changes and coaching writes.
Normal sign-in still requires staff claims and deployed Firestore rules.

The portal includes goal distribution, recent workout links, member search,
filters, sorting and pagination, report date shortcuts, refresh timestamps,
coach notes and trainer assignment. The 14-day percentage is labeled **active
member share**, not cohort retention. CSV output escapes spreadsheet formulas.
Recent activity and goal distribution come from the loaded Firestore member
profiles and workout logs. Admin-only member dialogs also read saved Supabase
forecasts and meal preferences through `admin-member-data`; see
[deployment instructions](supabase/README.md). Backend status cards show real
read results and explicit deployment errors. The site uses the existing
GrindFit logo and solid backgrounds without CSS gradients.

Verify browser-independent admin helpers with `npm test`.

Build and deploy the app and portal with:

```powershell
flutter build web
firebase deploy --only hosting,firestore:rules --project grindfit-34b02
```

This repository does not include a privileged staff-claim provisioning
service. Grant or revoke admin/trainer claims using a trusted Firebase Admin
SDK environment; the browser portal intentionally cannot promote accounts.

## Member feature additions

Phone pop-ups: open **Profile > Notification Settings** to allow/test phone
alerts, preview the in-app banner and choose a reminder time (default: around
6 PM in the device's local timezone). Workout/rest switches control weekly
phone reminders, including while the app is closed. Android schedules are
inexact to avoid requiring exact-alarm access; delivery follows OS permission,
Do Not Disturb and battery restrictions. Completed workouts suppress today's
remaining workout reminder. Signing out cancels this account's local alerts.

New inbox updates show a bounded slide/fade banner while the app is open.
Old inbox history does not replay on sign-in or reconnect. Server-originated
updates while the app process is killed require a separate FCM push deployment;
the local reminder scheduler does not require that backend. Animation uses
short transforms/opacity, honors Reduce Motion, and pauses hidden-tab tickers.
The performance regression test checks that the underlying page does not rebuild
on popup animation ticks; this is not a guarantee of a fixed FPS on every device.

Open **Home > Your GrindFit tools** for XP/levels, the optional monthly member
challenge, coach notes, voice settings, budget meal ideas and the recovery
journal. The Workouts tab includes the 500-character builder, daily sleep and
energy check-in, adaptive explanations, swaps and form guides. Both workout
completion and manual logging use a persistent per-account offline outbox.
The completion screen can export a workout summary image without identity or
health details.

`FEATURE_GAPS.md` records the implementation and live-service limitations.
`functions/README.md` explains deployment of the AI, XP and challenge services.
Those services and the updated Firestore rules must be deployed to activate
shared features; local source edits do not change the Firebase console.
Before publishing Flutter web, replace its old `grindfit-app` Firebase options
with the web registration for `grindfit-34b02`. The admin portal uses the new
project for authentication, coach-note writing and trainer assignment.

Validation:

```powershell
flutter analyze lib test
flutter test
cd functions
npm ci
npm test
cd ..
.\functions\node_modules\.bin\firebase.cmd emulators:exec --project demo-grindfit --only firestore "node --test functions/emulator.test.cjs"
flutter build apk --debug
```
# Workout trends and forecasts

Analytics displays a black/gold insights card below Workout Frequency using
the signed-in member's existing Firestore workout stream. Daily derived metrics
and forecast snapshots sync to Supabase after fresh logs are confirmed.
See [Supabase setup](supabase/README.md) to activate storage; local calculations
remain available while setup is pending or the network is unavailable.

- Consistency: unique completed scheduled days / scheduled opportunities over
  up to 28 complete local calendar days, excluding today and pre-signup days.
  With no signup timestamp, observation begins at the earliest available log.
- Next week: current scheduled days multiplied by recent attendance rate.
- Month end: actual unique workout days this month plus expected attendance
  on remaining scheduled days. The monthly schedule goal counts the actual
  weekdays in that calendar month; extra sessions on a day do not inflate it.
- Forecasts require 14 observed days, four scheduled opportunities and three
  logged workout days. Without that history the card explains what is missing.
- Trends compare sessions and total logged minutes over the last seven full
  days with the preceding seven. Same-day check-ins inform the next-step hint.

Forecasts are transparent activity estimates, not trained ML predictions or
medical/body-composition forecasts. The current schedule is assumed throughout
the observation window because historical schedule versions are not stored.
Cached Firestore snapshots are labeled; unsynced outbox entries appear once
they reach the workout stream. Unlogged sessions affect the estimate.
The Supabase public app key is configured. The database migration and Edge
Function must still be deployed; a public key cannot manage project schema.
