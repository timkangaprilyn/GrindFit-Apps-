const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, serverTimestamp, Timestamp } = require('firebase/firestore');
const { getFirestore: adminFirestore, Timestamp: AdminTimestamp } = require('firebase-admin/firestore');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let env;
before(async () => {
  if (!enabled) return;
  env = await initializeTestEnvironment({ projectId: 'demo-grindfit', firestore: { rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') } });
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice'), { role: 'member', trainerUid: 'coach' });
    await setDoc(doc(ctx.firestore(), 'users/bob'), { role: 'member' });
  });
});
after(async () => { if (env) await env.cleanup(); });

test('Members cannot forge rewards, staff notes, consent or trainer assignment', { skip: !enabled }, async () => {
  const db = env.authenticatedContext('alice').firestore();
  await assertFails(setDoc(doc(db, 'users/alice/progress/rewards'), { xp: 999999 }));
  await assertFails(setDoc(doc(db, 'users/alice/xp_ledger/fake'), { xp: 50 }));
  await assertFails(setDoc(doc(db, 'users/alice/challenge/current'), { optedIn: true }));
  await assertFails(setDoc(doc(db, 'users/alice/coach_notes/fake'), { text: 'Forged', authorUid: 'alice', createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, 'users/alice'), { trainerUid: 'alice' }));
});
test('Only assigned trainers can write notes and members can read their notes', { skip: !enabled }, async () => {
  const coach = env.authenticatedContext('coach', { trainer: true }).firestore();
  const other = env.authenticatedContext('other-coach', { trainer: true }).firestore();
  const note = { text: 'Keep a controlled pace.', authorUid: 'coach', createdAt: serverTimestamp(), updatedAt: serverTimestamp() };
  await assertFails(setDoc(doc(other, 'users/alice/coach_notes/one'), { ...note, authorUid: 'other-coach' }));
  await assertSucceeds(setDoc(doc(coach, 'users/alice/coach_notes/one'), note));
  await assertSucceeds(getDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice/coach_notes/one')));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice/coach_notes/one')));
});
test('Workout metrics are immutable while feedback remains editable', { skip: !enabled }, async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'users/alice/workouts/member-workout');
  await assertSucceeds(setDoc(ref, { durationSeconds: 300, timestamp: Timestamp.now(), exercises: [{ sets: 2 }], feedback: 'Just right' }));
  await assertSucceeds(updateDoc(ref, { feedback: 'Hard' }));
  await assertFails(updateDoc(ref, { durationSeconds: 9999 }));
});
test('Rewards are idempotent, daily-capped and challenges require consent', { skip: !enabled }, async () => {
  const { awardWorkoutXp, setMonthlyChallenge } = require('./index');
  const db = adminFirestore();
  const user = 'reward-member';
  const month = new Date().toISOString().slice(0, 7);
  await db.doc(`users/${user}`).set({ role: 'member' });
  await setMonthlyChallenge.run({ auth: { uid: user }, data: { join: true, alias: 'Grinder One' } });
  for (let i = 0; i < 4; i++) {
    const ref = db.doc(`users/${user}/workouts/session-${i}`);
    await ref.set({ durationSeconds: 600, timestamp: AdminTimestamp.fromMillis(Date.now() - 1000), exercises: [{ sets: 3 }] });
    const event = { params: { uid: user, workoutId: `session-${i}` }, data: await ref.get() };
    await Promise.all([awardWorkoutXp.run(event), awardWorkoutXp.run(event)]);
  }
  assert.equal((await db.doc(`users/${user}/progress/rewards`).get()).data().xp, 150);
  const membership = (await db.doc(`users/${user}/challenge/current`).get()).data();
  const entry = db.doc(`monthly_challenges/${month}/entries/${membership.entryId}`);
  assert.deepEqual((await entry.get()).data(), { alias: 'Grinder One', score: 3 });
  await assertSucceeds(getDoc(doc(env.authenticatedContext(user).firestore(), entry.path)));
  await assertFails(getDoc(doc(env.authenticatedContext('bob').firestore(), entry.path)));
  await setMonthlyChallenge.run({ auth: { uid: user }, data: { join: false } });
  assert.equal((await entry.get()).exists, false);
  await assertFails(getDoc(doc(env.authenticatedContext(user).firestore(), entry.path)));
});
