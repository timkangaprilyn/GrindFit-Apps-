# GrindFit analytics in Supabase

Target project: `fizdgkpykhcdzvdyxvej`.

## Admin website access

`web/admin-config.js` contains public Firebase and Supabase project settings.
The staff website reads profiles/workouts from Firebase and shows saved
Supabase forecasts and meal preferences inside each member's detail dialog.
It verifies connectivity with a signed-in request, not a hardcoded live badge.

Deploy the read-only cross-member endpoint using:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\deploy-live.ps1 -AdminDashboard
```

This idempotently applies the two restricted table migrations and deploys
`admin-member-data`. The function verifies Firebase JWT signature, expiry,
issuer and audience, then requires the boolean `admin: true` claim. A trainer
claim alone is denied. The browser never receives the service-role key.
Allowed operations are connectivity status and one-member reads (up to seven
analytics rows and one meal-preference row); no admin writes are added.
This does not deploy the member-side `meal-preferences` write function.

Run the updated website via Live Server, sign in as an admin and check both
connection cards. Missing deployment is explicitly reported. Existing admin
account provisioning still requires your trusted Firebase Admin environment.
Manual single-file source: `dashboard/admin-member-data.ts`.
Firebase login and workout logs remain in `grindfit-34b02`.
Supabase stores **derived daily analytics/forecast snapshots**, not a migration
of all workout logs. The calculations run on the device; Gemini is not used.

## Meal recommendations

Home → Meal Recommendations (also linked from Your GrindFit tools) offers
breakfast, lunch, dinner and snack ideas from a 16-recipe Pinoy catalog.
Budget, plant-only and ingredient-exclusion filters apply to every swap and
the favorites view. Protein-source recipes sort first for muscle/strength
goals. These are recipe ideas, not a complete daily nutritional prescription;
ingredient prices are illustrative and calories/macros are not fabricated.
General food-group reference: [DOST-FNRI adult guide](https://www.fnri.dost.gov.ph/images/sources/PinggangPinoy-Adult.pdf).

Preferences and favorite IDs save locally per Firebase account, including
pending changes across restart. Cloud changes restore when no local changes
are pending; pending edits win and retry on opening the screen, resuming, or
pressing Sync. Across devices, the last successful save wins. Meal selections
after Swap are session-only; favorites persist. Recipe ingredients are fixed;
packaged products and cross-contact must still be checked by the member.

Activate meal cloud storage separately (existing analytics stays deployed):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\deploy-live.ps1 -MealPreferences
```

This applies `202611090002_meal_preferences.sql` and deploys `meal-preferences`.
It verifies Firebase tokens using the same pattern as analytics. RLS blocks
direct client table access. The server accepts only budget, plant-only,
exclusions and known favorite IDs, and derives owner from the verified JWT.
No meal cloud activation is claimed until deployment and a signed-in save
are confirmed. Manual deployment source is `dashboard/meal-preferences.ts`.
Account-deletion cleanup must include `meal_preferences` in the trusted cleanup
process, alongside `analytics_snapshots` described below.

## Dashboard setup (no plugin needed)

For automatic live deployment, run this in the project terminal:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\supabase\deploy-live.ps1
```

Create an account Personal Access Token at
https://supabase.com/dashboard/account/tokens and enter it only in the hidden
terminal prompt. The script verifies project access, applies this migration,
deploys the function with Firebase JWT verification in its handler, then checks
that the live endpoint rejects unsigned requests. It does not save the token.
No CLI, Docker, database password or plugin is required. The account/token needs
database query access and Edge Function write access for this project.
`-ValidateOnly` checks source files without requesting credentials or deploying.

Manual alternative:

1. Open your Supabase project → **SQL Editor** → **New query**.
   Paste and run `migrations/202611090001_analytics_snapshots.sql`.
2. Open **Edge Functions** → **Deploy a new function** → **Via Editor**.
   Name the function exactly `analytics-snapshot`. Paste the complete contents
   of `dashboard/analytics-snapshot.ts` into `index.ts`, then deploy it.
3. In the function settings, turn **Verify JWT with legacy secret** OFF.
   This handler verifies Firebase-signed RS256 tokens itself (issuer and audience
   fixed to `grindfit-34b02`). The legacy Supabase JWT checker cannot accept them.
   Requests without a valid Firebase token are rejected by the handler.
4. Run the updated Flutter app, sign in, and open Analytics. After logs finish
   syncing, look for **Saved to Supabase** below the forecast card. Check
   **Table Editor → analytics_snapshots** to see the row for that account/date.

The standard Edge Function environment provides `SUPABASE_URL` and
`SUPABASE_SERVICE_ROLE_KEY`. The privileged key stays on the server and must
never be pasted into the Flutter app or shared in chat. No Firebase admin
credentials, Firebase custom role claims, or second user login are required.

## CLI alternative

After installing the Supabase CLI and authenticating your own account:

```powershell
supabase login
supabase link --project-ref fizdgkpykhcdzvdyxvej
supabase db push
supabase functions deploy analytics-snapshot --project-ref fizdgkpykhcdzvdyxvej
```

Review pending migrations before `db push` in a project with existing migrations.
The SQL only creates the new analytics table and restricts access to that table.

## Data and access

- Primary key `(firebase_uid, local_date)` updates one snapshot per account/day.
  Rows include attendance, session/minute changes, monthly schedule goal and
  estimated workout days, with algorithm version 1 and an explanatory basis.
- Names, email, pain notes, sleep and energy are not uploaded. The verified
  Firebase UID links the metrics to the account and is personal account data.
- RLS enabled with no public client policies; table access goes through the
  function. The owner always comes from the verified token, not request JSON.
- Payload size and metric ranges are validated; dates are restricted to the
  current local day (allowing time zone differences). These are self-reported
  activity metrics, not independently verified workouts or clinical forecasts.
- Sync is debounced on Analytics input changes, with Retry and resume retry.
  Cached or pending Firestore data waits for server confirmation. There is no
  separate durable analytics outbox: reopening Analytics recomputes and retries.
- Existing snapshots are historical summaries. The app currently renders the
  current Firestore-derived calculations; it does not load charts from Supabase
  or backfill past daily snapshots. Account deletion must also clean up these
  rows through a trusted server before production data-retention rollout.
- Revoked Firebase sessions are not checked against Firebase Admin on every
  request; cryptographic validation accepts valid ID tokens until they expire.

The app reports successful sync only after the database acknowledges a save.
Until the SQL and function are deployed, the screen explicitly shows that
Supabase sync is unavailable; it does not claim cloud storage is active.

## Validation

```powershell
flutter analyze lib test
flutter test
deno test supabase/functions/analytics-snapshot/policy_test.ts
deno check supabase/functions/analytics-snapshot/index.ts
```

`dashboard/analytics-snapshot.ts` is a single-file deployment copy combining
`policy.ts` and `index.ts`, for the dashboard editor. Regenerate after edits.
