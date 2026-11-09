import { validateSnapshot } from './policy.ts';

const now = new Date('2026-11-09T12:00:00Z');
const valid = () => ({local_date: '2026-11-09', algorithm_version: 1, scheduled_days: 16,
  completed_days: 12, consistency: .75, can_forecast: true, next_week_estimate: 3,
  month_estimate: 12.75, month_completed: 3, month_target: 17, session_change: 0,
  minute_change: 0, basis: '12/16 scheduled days'});
function assert(condition: boolean) { if (!condition) throw new Error('Assertion failed'); }
function rejects(data: unknown) {
  let failed = false;
  try { validateSnapshot(data, now); } catch (_) { failed = true; }
  assert(failed);
}
Deno.test('valid metrics are allowlisted and forged owner is discarded', () => {
  const result = validateSnapshot({...valid(), firebase_uid: 'victim', email: 'private'}, now);
  assert(result.consistency === .75);
  assert(!('firebase_uid' in result));
  assert(!('email' in result));
});
Deno.test('invalid dates, attendance and estimate ranges are rejected', () => {
  rejects({...valid(), local_date: '2026-02-30'});
  rejects({...valid(), local_date: '2020-11-09'});
  rejects({...valid(), completed_days: 17});
  rejects({...valid(), consistency: .99});
  rejects({...valid(), next_week_estimate: 8});
  rejects({...valid(), month_estimate: Infinity});
  rejects({...valid(), month_completed: -1});
  rejects({...valid(), can_forecast: false});
});
Deno.test('honest insufficient-history snapshots are accepted', () => {
  const result = validateSnapshot({...valid(), scheduled_days: 0, completed_days: 0,
    consistency: null, can_forecast: false, next_week_estimate: null, month_estimate: null,
    session_change: null, minute_change: null}, now);
  assert(result.can_forecast === false);
});
