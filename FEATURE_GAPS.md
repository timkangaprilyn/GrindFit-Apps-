# GrindFit document implementation

Source: `Mga idadagdag.docx`, supplied 9 November 2026.

## Implemented in app

- Workout builder accepts up to 500 characters and all requested focus chips.
  Firebase callable integration generates validated catalog-based plans. Without
  an active backend or internet, the app clearly uses its on-device plan.
- Adaptation uses Easy / Just right / Hard and missed scheduled days during
  the last seven local calendar days, excluding today and dates before signup.
  Missed sessions reduce load instead of adding catch-up sessions; reasons show
  in the Workouts tab. Low sleep or energy takes precedence over progression.
- Daily sleep (0–12 hours) and energy (1–5) check-in; low recovery switches the
  recommended plan to gentle activity for that local day.
- Pre-workout pain area/severity review. Higher/general pain routes to recovery.
  For mild localized discomfort, affected muscle groups are excluded from
  catalog/AI options and the member must review and confirm prior clearance.
  Suggestions do not diagnose, treat injuries or promise medical safety.
- Exercise swaps in both recommendations and workout preview; equipment and
  muscle-group matching, with no-equipment alternatives and saved choices.
- Form guides with movement-specific steps and common mistakes. A generic
  controlled-movement guide remains for uncategorized/custom exercises.
- Home > Your GrindFit tools: XP/levels, monthly challenge, coach notes, voice
  settings, Pinoy meals and a recovery journal for members reporting an injury.
- Pinoy meal ideas include ingredient budget estimates, egg/soy/fish exclusions,
  plant-based filtering and goal guidance. Prices are illustrative, not live
  store prices, and no personalized nutrition prescription is claimed.
- Voice coach controls (default off), volume and test speech; warm-up, exercise,
  set, rest and countdown cues. Uses the device's installed TTS engine.
- Shareable PNG workout card with duration, estimated calories and actual cached
  streak. Native share sheet, no name, email or health details in the image.
- Week/Month analytics: per-day bars in both views, including 28–31-day months.
- Recovery journal: user/clinician-directed stage, discomfort, notes and dated
  history. Does not infer healing or automatically prescribe recovery stages.
- Durable offline outbox for completed/manual workout logs, feedback, workout
  preferences and recovery entries. Stable document IDs, per-account sync,
  newer-edit preservation, restart recovery and visible pending-sync status.
  Cached plans remain usable; first sign-in, AI and public challenge actions
  need connectivity. Pending data is retained on the device until acknowledged.

## Backend source complete; activation requires Firebase project access

`functions/` contains authenticated callable AI generation, challenge consent
and Firestore-triggered XP. See `functions/README.md` for deployment commands.

- AI key stays in Secret Manager. Requests have a 500-character limit and a
  per-user daily quota; model output must use the fixed catalog and load bounds.
- XP: idempotent transaction ledger, 50 XP per eligible completed workout,
  up to three credited workouts per UTC day. Self-reported sessions are not
  independent proof of exercise. Levels: 250 XP; ranks: Rookie, Grinder, Beast.
- Monthly challenge: opt-in, public nickname and workout count only, random
  public IDs, server-controlled scores, member-only leaderboard and removal
  on opt-out. A new month requires fresh opt-in. Months use UTC.
- Coach-note authoring/editing and trainer assignment in `web/admin.html`.
  Trusted staff claims are required; admins assign trainers. Assigned trainers
  can write their members' notes; members cannot forge notes or assign staff.
- Updated Firestore rules protect notes, reward ledgers, usage quotas, consent
  and scores. Workouts allow feedback edits but not post-credit metric edits.

Deployment has not been performed by editing local source. Firebase console
access, a billing-eligible Functions project and a server Gemini key are needed.
The Android app targets `grindfit-34b02`; Flutter web/iOS still need their own
registered app configurations for this project. The admin portal's auth/Firestore
configuration targets `grindfit-34b02` and may need web API key restrictions set
appropriately in the console.

## Validation

See test output from the implementation session for executed checks. Unit and
widget tests cover adaptation, focus selection, swaps, pain filtering, meal
filters, ranks, form guides, offline restart/edit/account isolation and layouts.
Node policy tests cover AI validation, equipment/pain exclusions, XP eligibility
and public nickname validation. Emulator integration tests exercise Firestore
permissions, duplicate XP events, daily caps, consent and opt-out privacy.
Live AI responses, real staff accounts, device speech/share targets and deployed
Firestore rules require testing against the configured services and accounts.

Executed validation: Flutter analyzer passed; 33 Flutter unit/widget tests passed
(32-test full suite plus the added missed-feedback regression test), six Node
policy tests passed, and four Firestore emulator integration tests passed.
The final Android debug APK built successfully after pinning Firebase Core
4.13.0 and Cloud Functions 6.3.6 to match Firebase Auth's native Android API.