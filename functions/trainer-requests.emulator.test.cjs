const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, updateDoc, writeBatch, increment, serverTimestamp, collection, query, where, getDocs } = require('firebase/firestore');
const enabled = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
let env;

before(async () => {
  if (!enabled) return;
  env = await initializeTestEnvironment({ projectId: 'demo-grindfit-requests', firestore: { rules: fs.readFileSync(path.join(__dirname, '../firestore.rules'), 'utf8') } });
});
after(async () => { if (env) await env.cleanup(); });

async function seed() {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/mia'), { role: 'member', fullName: 'Mia' });
    await setDoc(doc(db, 'users/ben'), { role: 'member', fullName: 'Ben', trainerUid: 'coachB' });
    await setDoc(doc(db, 'trainers/coachA'), { displayName: 'Coach A', specialty: 'Strength', bio: 'Lifts.', active: true, memberCount: 0 });
    await setDoc(doc(db, 'trainers/coachB'), { displayName: 'Coach B', active: true, memberCount: 1 });
    await setDoc(doc(db, 'trainers/retired'), { displayName: 'Retired', active: false, memberCount: 0 });
  });
}
const member = (uid) => env.authenticatedContext(uid).firestore();
const trainer = (uid) => env.authenticatedContext(uid, { trainer: true }).firestore();
const admin = () => env.authenticatedContext('boss', { admin: true }).firestore();
const request = (memberUid, trainerUid, extra = {}) => ({ memberUid, memberName: 'Mia', trainerUid, trainerName: 'Coach', status: 'pending', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra });

function approve(db, deciderUid, memberUid, trainerUid, previousTrainer) {
  const batch = writeBatch(db);
  batch.update(doc(db, `trainer_requests/${memberUid}`), { status: 'approved', decidedBy: deciderUid, updatedAt: serverTimestamp() });
  batch.update(doc(db, `users/${memberUid}`), { trainerUid });
  batch.update(doc(db, `trainers/${trainerUid}`), { memberCount: increment(1), lastChange: memberUid, updatedAt: serverTimestamp() });
  if (previousTrainer) batch.update(doc(db, `trainers/${previousTrainer}`), { memberCount: increment(-1), lastChange: memberUid, updatedAt: serverTimestamp() });
  return batch.commit();
}

test('members see the trainer directory but cannot edit it', { skip: !enabled }, async () => {
  await seed();
  await assertSucceeds(getDocs(collection(member('mia'), 'trainers')));
  await assertFails(updateDoc(doc(member('mia'), 'trainers/coachA'), { bio: 'hacked' }));
  await assertFails(updateDoc(doc(trainer('coachA'), 'trainers/coachA'), { bio: 'self-edit' }));
  await assertSucceeds(updateDoc(doc(admin(), 'trainers/coachA'), { bio: 'Updated by admin', updatedAt: serverTimestamp() }));
  await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'trainers')));
});

test('members request active trainers only, for themselves, and can cancel', { skip: !enabled }, async () => {
  await seed();
  await assertFails(setDoc(doc(member('mia'), 'trainer_requests/ben'), request('ben', 'coachA')));
  await assertFails(setDoc(doc(member('mia'), 'trainer_requests/mia'), request('mia', 'retired')));
  await assertFails(setDoc(doc(member('mia'), 'trainer_requests/mia'), request('mia', 'coachA', { status: 'approved' })));
  await assertSucceeds(setDoc(doc(member('mia'), 'trainer_requests/mia'), request('mia', 'coachA', { note: 'Gusto kong lumakas.' })));
  await assertFails(updateDoc(doc(member('mia'), 'trainer_requests/mia'), { status: 'approved', decidedBy: 'mia', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(member('mia'), 'users/mia'), { trainerUid: 'coachA' }));
  await assertSucceeds(updateDoc(doc(member('mia'), 'trainer_requests/mia'), { status: 'cancelled', updatedAt: serverTimestamp() }));
  await assertFails(getDoc(doc(member('ben'), 'trainer_requests/mia')));
});

test('only the requested trainer or an admin can see and decide a request', { skip: !enabled }, async () => {
  await seed();
  await assertSucceeds(setDoc(doc(member('mia'), 'trainer_requests/mia'), request('mia', 'coachA')));
  await assertSucceeds(getDocs(query(collection(trainer('coachA'), 'trainer_requests'), where('trainerUid', '==', 'coachA'), where('status', '==', 'pending'))));
  await assertFails(getDoc(doc(trainer('coachB'), 'trainer_requests/mia')));
  // Another trainer can neither approve nor hijack the member.
  await assertFails(approve(trainer('coachB'), 'coachB', 'mia', 'coachB'));
  // Approval without assigning the member is rejected; so is assigning without approval.
  await assertFails(updateDoc(doc(trainer('coachA'), 'trainer_requests/mia'), { status: 'approved', decidedBy: 'coachA', updatedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(trainer('coachA'), 'users/mia'), { trainerUid: 'coachA' }));
  await assertSucceeds(approve(trainer('coachA'), 'coachA', 'mia', 'coachA'));
  const assigned = await getDoc(doc(admin(), 'users/mia'));
  if (assigned.data().trainerUid !== 'coachA') throw new Error('Member was not assigned');
  const count = await getDoc(doc(admin(), 'trainers/coachA'));
  if (count.data().memberCount !== 1) throw new Error('Count not incremented');
  // A decided request cannot be decided again.
  await assertFails(updateDoc(doc(trainer('coachA'), 'trainer_requests/mia'), { status: 'declined', decidedBy: 'coachA', updatedAt: serverTimestamp() }));
});

test('trainers decline, and switching trainers moves both counts', { skip: !enabled }, async () => {
  await seed();
  await assertSucceeds(setDoc(doc(member('ben'), 'trainer_requests/ben'), request('ben', 'coachA', { memberName: 'Ben' })));
  await assertSucceeds(updateDoc(doc(trainer('coachA'), 'trainer_requests/ben'), { status: 'declined', decidedBy: 'coachA', updatedAt: serverTimestamp() }));
  await assertSucceeds(setDoc(doc(member('ben'), 'trainer_requests/ben'), request('ben', 'coachA', { memberName: 'Ben' })));
  // Cannot inflate a count without moving a member.
  await assertFails(updateDoc(doc(trainer('coachA'), 'trainers/coachA'), { memberCount: increment(1), lastChange: 'mia', updatedAt: serverTimestamp() }));
  await assertSucceeds(approve(trainer('coachA'), 'coachA', 'ben', 'coachA', 'coachB'));
  const [a, b] = await Promise.all([getDoc(doc(admin(), 'trainers/coachA')), getDoc(doc(admin(), 'trainers/coachB'))]);
  if (a.data().memberCount !== 1 || b.data().memberCount !== 0) throw new Error('Counts did not move');
});

test('admins can approve any pending request', { skip: !enabled }, async () => {
  await seed();
  await assertSucceeds(setDoc(doc(member('mia'), 'trainer_requests/mia'), request('mia', 'coachB')));
  await assertSucceeds(approve(admin(), 'boss', 'mia', 'coachB'));
});
