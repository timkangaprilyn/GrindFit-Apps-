# GrindFit

GrindFit is a fitness app for gym members. It builds a workout plan and a daily
meal plan around each member's goal, body stats and food budget. Coaches and
admins use a separate web portal.

Built with Flutter, Firebase (Authentication, Firestore, Cloud Functions) and
Supabase.

## Features

### Member app (Android)

- **Onboarding:** an initial assessment of age, height, weight, fitness level,
  goal, workout days and any injuries.
- **Home:** today's workout, quick stats, a daily checklist, weekly activity
  (Sun–Sat) and goal progress.
- **Workouts:**
  - The AI workout builder writes a plan from the member's own request. When
    the AI service is unreachable, it builds an offline plan instead.
  - Form photos show the start and finish positions of each exercise.
  - The exercise timer shows the photos during the workout.
  - A daily sleep and energy check-in adjusts the plan.
  - Members can swap exercises.
- **Meal plan:**
  - Breakfast, lunch, dinner and a snack, matched to the member's calorie and
    protein targets and to their daily budget in ₱.
  - Members can set diet filters, save favorites and swap meals.
- **Log and history:** members log workouts by hand or from a completed
  session. Logging works offline and syncs when the phone is back online.
- **Analytics:**
  - Workout frequency, trends and consistency.
  - Activity forecasts based on the member's own history.
- **Notifications:**
  - An in-app inbox.
  - Phone reminders for workout and rest days, which also arrive when the app
    is closed.
- **Coaching and extras:** members can choose a coach, read coach notes, and
  use XP and levels, a monthly challenge, a voice coach and a recovery journal.
- **Profile:**
  - Personal information, a Google profile photo, health and injury notes,
    goal and workout preferences.
  - Change password and a privacy policy.
  - Delete my data.

### Staff portal (web)

| Page | For | What it does |
|---|---|---|
| `/login.html` | Staff | Signs staff in and sends each account to the right dashboard. |
| `/admin.html` | Admins | Shows all members, assigns trainers, approves coaching requests, exports reports and holds settings. |
| `/trainer.html` | Trainers | Shows only the trainer's assigned members, with coach notes, activity reports and coaching requests. |

New staff accounts must change their issued password the first time they sign
in. Staff roles come from Firebase custom claims, never from profile fields.

## Getting started

Requirements:

- Flutter (stable) with Android SDK
- Node.js 22, used for the staff portal and Cloud Functions

```powershell
flutter pub get
flutter run
```

The Android app uses Firebase project `grindfit-34b02`. Its configuration is in
`android/app/google-services.json` and `lib/firebase_options.dart`. If you
change the Android application ID, update the Firebase app registration too.

**Google sign-in:**

1. Register your computer's signing certificate in Firebase Console:
   **Project settings → Your apps → SHA-1 / SHA-256**.
2. Download the updated `google-services.json`.

**Staff portal locally:** run `npm start` and open `http://localhost:8080/`.

**Preview without signing in:** add `?preview=1` to `admin.html` or
`trainer.html` to see the dashboard with sample data.

## Project structure

```
lib/
  screens/     App screens (home, workouts, meal plan, log, analytics, profile…)
  widgets/     Shared UI pieces
  models/      App state, plans, meals, exercise photos, weekly activity
  services/    Offline storage, notifications, network status, sync
  theme/       GrindFit design tokens (black, gold, white)
web/           Staff portal (login, admin, trainer)
functions/     Firebase Cloud Functions (AI workouts, XP, challenges)
supabase/      Database migration and edge function for trends and forecasts
test/          Unit and widget tests
```

## Testing

```powershell
flutter analyze lib test
flutter test
npm test
```

## Deployment

```powershell
flutter build web
firebase deploy --only hosting,firestore:rules --project grindfit-34b02
```

Some features need their backend deployed before they work:

- **AI workouts, XP and challenges:** Cloud Functions. See
  [functions/README.md](functions/README.md).
- **Trends and forecasts:** the Supabase migration and edge function. See
  [supabase/README.md](supabase/README.md).
- **Admin and trainer access:** staff custom claims, granted from a trusted
  Firebase Admin SDK environment. The portal cannot promote accounts.

Known limitations are listed in [FEATURE_GAPS.md](FEATURE_GAPS.md).

## Credits

- Exercise photos come from
  [Free Exercise DB](https://github.com/yuhonas/free-exercise-db), which is in
  the public domain (Unlicense).
- Nutrition values are rounded from the DOST-FNRI Philippine Food Composition
  Tables and USDA FoodData Central.

GrindFit gives general fitness guidance. It is not medical advice.
