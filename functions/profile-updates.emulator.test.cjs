const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { doc, setDoc, serverTimestamp } = require('firebase/firestore');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let env;

before(async () => {
  if (!enabled) return;
  env = await initializeTestEnvironment({ projectId: 'demo-grindfit-profile', firestore: { rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') } });
});
after(async () => { if (env) await env.cleanup(); });

// Profile shapes a real member account can have.
const profiles = {
  registered: { uid: 'mia', fullName: 'Mia', email: 'mia@example.com', role: 'member', setupCompleted: true, weight: 80 },
  coached: { uid: 'mia', fullName: 'Mia', role: 'member', setupCompleted: true, weight: 80, trainerUid: 'coachA' },
  noUid: { fullName: 'Mia', role: 'member', setupCompleted: true, weight: 80 },
};

for (const [name, profile] of Object.entries(profiles)) {
  test(`member can log weight progress (${name} profile)`, { skip: !enabled }, async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'users/mia'), profile));
    const db = env.authenticatedContext('mia').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/mia'), {
      weight: 78.5, startWeight: 80, weightUpdatedAt: serverTimestamp(), updatedAt: serverTimestamp(),
    }, { merge: true }));
    await assertSucceeds(setDoc(doc(db, 'users/mia'), { mealBudget: 200, equipment: ['dumbbells'], todayPlan: { date: '2026-11-11', extras: [], adjustments: {} } }, { merge: true }));
    await assertFails(setDoc(doc(db, 'users/mia'), { trainerUid: 'coachZ' }, { merge: true }));
  });
}
