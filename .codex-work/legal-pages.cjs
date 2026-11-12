const fs=require('node:fs');
const pages={
 'terms': ['Terms of Use', [
  'Draft — owner review required. Operator: [DEVELOPER / BUSINESS NAME]. Support: [SUPPORT EMAIL]. Effective date: [RELEASE DATE].',
  'GrindFit provides general fitness tracking and preset workout recommendations. It does not provide medical diagnosis, treatment, or guaranteed results. Consult a qualified professional before exercising with a health condition or injury.',
  'Keep your account secure, provide accurate information, and do not access another member’s data or bypass staff permissions. You are responsible for the workout data you submit.',
  'You can update your profile and delete your account and app-owned data from Profile. Reminders are optional and may be delayed by Android. Internet access is required for cloud-confirmed account operations and workout saves.',
  'Service availability, age eligibility, governing jurisdiction, dispute resolution, and any paid-service terms must be finalized by [DEVELOPER / BUSINESS NAME] before release. This draft does not create a paid subscription.',
 ]],
 'privacy': ['Privacy Policy', [
  'Draft — replace placeholders before publication. Operator: [DEVELOPER / BUSINESS NAME]. Support/data requests: [SUPPORT EMAIL]. Effective date: [RELEASE DATE].',
  'GrindFit stores account identity, fitness preferences, optional injury/health information, workout plans, history, progress, and notification preferences. Firebase Authentication handles sign-in and Cloud Firestore stores account data. Google passwords are not shared with GrindFit.',
  'Information supports account access, recommendations, history, and authorized staff review. Administrators and trainers can review member data. Health information pauses automatic plans and is not used to diagnose conditions.',
  'Optional Android reminders are scheduled locally on this device. Crash reporting is disabled by default; a future production configuration may enable Firebase Crashlytics after the operator finalizes crash-data disclosures. No live AI model or advertising is enabled by this update.',
  'You can update your profile, disable reminders, and delete your account and app-owned data in Profile. Device-cache behavior, backups, retention obligations, data regions, eligibility, and data-request procedures must be finalized by the operator before release. Contact [SUPPORT EMAIL].',
 ]],
};
for(const [slug,[title,paragraphs]] of Object.entries(pages)){
 fs.writeFileSync(`web/${slug}.html`, `<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>GrindFit ${title}</title><style>body{background:#121212;color:#eee;font:18px/1.7 system-ui;margin:0}main{max-width:720px;padding:32px 24px;margin:auto}a{color:#ffd34d}h1{line-height:1.2}aside{color:#ffd34d}</style><main><h1>${title}</h1><aside>Demo draft — not finalized for production</aside>${paragraphs.map(p=>`<p>${p}</p>`).join('')}<nav><a href="/terms.html">Terms of Use</a> · <a href="/privacy.html">Privacy Policy</a></nav></main></html>`);
}
