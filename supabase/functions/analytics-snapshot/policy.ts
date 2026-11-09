export function validateSnapshot(input: unknown, now = new Date()): Record<string, unknown> {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid body');
  const v = input as Record<string, unknown>;
  const date = typeof v.local_date === 'string' ? v.local_date : '';
  const parsed = new Date(`${date}T00:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) ||
      parsed.toISOString().slice(0, 10) !== date ||
      Math.abs(parsed.getTime() - now.getTime()) > 2 * 86400000) throw new Error('Invalid local date');
  const integer = (key: string, min: number, max: number, nullable = false) => {
    const x = v[key];
    if (nullable && x === null) return null;
    if (typeof x !== 'number' || !Number.isInteger(x) || x < min || x > max) throw new Error(`Invalid ${key}`);
    return x;
  };
  const decimal = (key: string, min: number, max: number) => {
    const x = v[key];
    if (x === null) return null;
    if (typeof x !== 'number' || !Number.isFinite(x) || x < min || x > max) throw new Error(`Invalid ${key}`);
    return x;
  };
  if (v.algorithm_version !== 1 || typeof v.can_forecast !== 'boolean') throw new Error('Invalid version or forecast flag');
  const scheduled = integer('scheduled_days', 0, 28)!;
  const completed = integer('completed_days', 0, scheduled)!;
  const consistency = decimal('consistency', 0, 1);
  if ((scheduled === 0 && consistency !== null) || (scheduled > 0 &&
      (consistency === null || Math.abs(consistency - completed / scheduled) > 1e-9))) throw new Error('Invalid consistency');
  const next = decimal('next_week_estimate', 0, 7);
  const month = decimal('month_estimate', 0, 31);
  if ((!v.can_forecast && (next !== null || month !== null)) ||
      (v.can_forecast && (scheduled < 4 || next === null || month === null))) throw new Error('Invalid forecast');
  if (typeof v.basis !== 'string' || v.basis.length > 300) throw new Error('Invalid basis');
  // Allowlist fields: never accept a caller-supplied owner, timestamp or extra PII.
  return {
    local_date: date, algorithm_version: 1,
    scheduled_days: scheduled, completed_days: completed, consistency,
    can_forecast: v.can_forecast, next_week_estimate: next, month_estimate: month,
    month_completed: integer('month_completed', 0, 31), month_target: integer('month_target', 0, 31),
    session_change: integer('session_change', -100000, 100000, true),
    minute_change: integer('minute_change', -10000000, 10000000, true), basis: v.basis,
  };
}
