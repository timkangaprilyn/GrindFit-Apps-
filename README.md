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

## Firestore access control

`firestore.rules` restricts member data to the signed-in owner. Admin access
requires the Firebase Authentication custom claim `admin: true`; a `role`
field written in a user profile is not sufficient to grant admin access.
Grant or revoke that claim only through a trusted, privileged Admin SDK
environment, never from the client app.

Review the rules against the deployed project before publishing them:

```powershell
firebase deploy --only firestore:rules --project grindfit-app
```

The admin portal is available at `/admin.html` after building the Flutter web
target. It checks the signed-in user's trusted `admin` or `trainer` custom
claim before reading member data. Add the portal's hosting domain to Firebase
Authentication's authorized domains before using it outside localhost.

Build and deploy the app and portal with:

```powershell
flutter build web
firebase deploy --only hosting,firestore:rules --project grindfit-app
```

This repository does not include a privileged staff-claim provisioning
service. Grant or revoke admin/trainer claims using a trusted Firebase Admin
SDK environment; the browser portal intentionally cannot promote accounts.
