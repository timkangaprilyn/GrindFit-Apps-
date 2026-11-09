"use strict";

const catalog = [
  ['Push Up', 'Chest, shoulders, triceps', false],
  ['Wall Push Up', 'Chest, shoulders, triceps', false],
  ['Dumbbell Row', 'Back, biceps', true],
  ['Shoulder Press', 'Shoulders, triceps', true],
  ['Dumbbell Curl', 'Biceps, arms', true],
  ['Triceps Extension', 'Triceps, arms', true],
  ['Bodyweight Squat', 'Quads, glutes, hamstrings', false],
  ['Glute Bridge', 'Glutes, hamstrings', false],
  ['Standing Calf Raise', 'Calves, legs', false],
  ['Dead Bug', 'Core, abs', false],
  ['Plank Hold', 'Core, abs, shoulders', false],
  ['Prone Reverse Fly', 'Back, shoulders', false],
  ['Reverse Lunges', 'Quads, glutes, hamstrings', false],
  ['Jumping Jacks', 'Full body, cardiovascular system', false],
  ['Mountain Climbers', 'Core, shoulders, legs', false],
];
function eligibleCatalog(environment, painArea = 'None', noEquipment = false) {
  const blocked = painArea === 'Knee / leg' ? /leg|quad|glute|hamstring|calf|cardio|full body/i
    : painArea === 'Shoulder / arm' ? /shoulder|chest|back|tricep|bicep|arm|full body/i : null;
  if (!['None', 'Knee / leg', 'Shoulder / arm'].includes(painArea)) return [];
  return catalog.filter(([, muscles, needsGym]) =>
    (!needsGym || (!noEquipment && String(environment).toLowerCase().includes('gym'))) &&
    (!blocked || !blocked.test(muscles)));
}
function validatePlan(value, allowed, minutes = 120) {
  if (!value || !Array.isArray(value.exercises) || value.exercises.length < 1 || value.exercises.length > 8) throw new Error('Invalid plan size');
  const names = new Set(allowed.map(([name]) => name));
  const used = new Set();
  const exercises = value.exercises.map((exercise) => {
    if (!names.has(exercise.name) || used.has(exercise.name)) throw new Error('Invalid exercise');
    used.add(exercise.name);
    for (const [key, min, max] of [['sets', 1, 5], ['reps', 1, 30], ['seconds', 15, 90]]) {
      if (!Number.isInteger(exercise[key]) || exercise[key] < min || exercise[key] > max) throw new Error('Invalid exercise load');
    }
    return { name: exercise.name, sets: exercise.sets, reps: exercise.reps, seconds: exercise.seconds };
  });
  // Include a conservative 30-second rest allowance between sets. Refuse plans
  // that cannot fit the member's available time instead of silently extending it.
  const estimatedSeconds = exercises.reduce((sum, e) => sum + e.sets * (e.seconds + 30), 0);
  if (estimatedSeconds > minutes * 60) throw new Error('Plan exceeds available time');
  return { exercises, reason: 'Built from your request, workout setting, schedule and recent check-in. Adjust or stop if anything feels uncomfortable.' };
}
function workoutCredit(workout, now = new Date()) {
  const duration = workout.durationSeconds;
  const timestamp = workout.timestamp?.toDate?.();
  if (!Number.isInteger(duration) || duration < 60 || duration > 21600 || !(timestamp instanceof Date) ||
      timestamp > now || timestamp < new Date(now.getTime() - 60 * 86400000) ||
      !Array.isArray(workout.exercises) || !workout.exercises.some((e) => Number.isInteger(e.sets) && e.sets > 0 && e.skipped !== true)) return null;
  return { xp: 50, day: timestamp.toISOString().slice(0, 10), month: timestamp.toISOString().slice(0, 7) };
}
function publicAlias(value) {
  if (typeof value !== 'string' || value.trim().length < 3 || value.trim().length > 24 || /[\r\n<>@]/.test(value)) throw new Error('Use a public nickname with 3–24 characters, without email addresses or markup.');
  return value.trim();
}
module.exports = { eligibleCatalog, validatePlan, workoutCredit, publicAlias };
