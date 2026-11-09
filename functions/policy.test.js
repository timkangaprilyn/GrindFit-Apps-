const test = require('node:test');
const assert = require('node:assert/strict');
const { eligibleCatalog, validatePlan, workoutCredit, publicAlias } = require('./policy');
const timestamp = (date) => ({ toDate: () => new Date(date) });
test('Home and no-equipment requests cannot include gym equipment', () => {
  assert.ok(eligibleCatalog('Home (no equipment)').every(([, , gym]) => !gym));
  assert.ok(eligibleCatalog('Gym', 'None', true).every(([, , gym]) => !gym));
});
test('Pain exclusion removes affected muscle groups; general pain stops suggestions', () => {
  assert.ok(eligibleCatalog('Gym', 'Knee / leg').every(([, m]) => !/leg|quad|glute|hamstring|calf|cardio|full body/i.test(m)));
  assert.deepEqual(eligibleCatalog('Gym', 'Back / neck'), []);
});
test('AI output rejects unknown, repeated and excessive-load exercises', () => {
  const allowed = eligibleCatalog('Gym');
  const exercise = { name: 'Push Up', sets: 3, reps: 10, seconds: 45 };
  assert.equal(validatePlan({ exercises: [exercise] }, allowed).exercises.length, 1);
  for (const invalid of [[{ ...exercise, name: 'Invented' }], [exercise, exercise], [{ ...exercise, sets: 100 }], []]) {
    assert.throws(() => validatePlan({ exercises: invalid }, allowed));
  }
});
test('XP rejects short, future, skipped, and stale workouts', () => {
  const now = new Date('2026-11-09T10:00:00Z');
  const workout = { durationSeconds: 600, timestamp: timestamp('2026-11-09T09:00:00Z'), exercises: [{ sets: 3 }] };
  assert.deepEqual(workoutCredit(workout, now), { xp: 50, day: '2026-11-09', month: '2026-11' });
  for (const invalid of [{ ...workout, durationSeconds: 0 }, { ...workout, exercises: [{ sets: 0, skipped: true }] }, { ...workout, timestamp: timestamp('2027-01-01') }, { ...workout, timestamp: timestamp('2026-01-01') }]) assert.equal(workoutCredit(invalid, now), null);
});
test('Public nicknames cannot contain email addresses or markup', () => {
  assert.equal(publicAlias(' Grinder 7 '), 'Grinder 7');
  for (const value of ['ab', 'a@b.com', '<script>', 'a'.repeat(25)]) assert.throws(() => publicAlias(value));
});
test('AI plans cannot exceed the saved session duration', () => {
  const value = { exercises: [{ name: 'Push Up', sets: 5, reps: 10, seconds: 90 }] };
  assert.throws(() => validatePlan(value, eligibleCatalog('Gym'), 5));
  assert.equal(validatePlan(value, eligibleCatalog('Gym'), 15).exercises.length, 1);
});
