import {requireAdmin, validateStaffRequest, parseClaims, withTrainerClaim, isManagedTrainer, trainerSummary} from './policy.ts';

const rejects = (data: unknown) => {
  try { validateStaffRequest(data); } catch (_) { return true; }
  return false;
};

Deno.test('only the verified boolean admin claim may manage trainers', () => {
  if (!requireAdmin({admin: true})) throw new Error('Admin denied');
  for (const claims of [{}, {trainer: true}, {admin: 'true'}, {role: 'admin'}, {admin: false}]) {
    if (requireAdmin(claims)) throw new Error('Untrusted role accepted');
  }
});

Deno.test('create requests are normalized and weak input is rejected', () => {
  const ok = validateStaffRequest({action: 'create', email: ' Coach@Example.com ', displayName: ' Coach   Ana ', password: 'StrongPass123', admin: true});
  if (ok.action !== 'create' || ok.email !== 'coach@example.com' || ok.displayName !== 'Coach Ana') throw new Error('Not normalized');
  for (const bad of [
    {action: 'create', email: 'nope', displayName: 'Coach', password: 'StrongPass123'},
    {action: 'create', email: 'a@b.co', displayName: 'A', password: 'StrongPass123'},
    {action: 'create', email: 'a@b.co', displayName: 'Coach', password: 'short1'},
    {action: 'create', email: 'a@b.co', displayName: 'Coach', password: 'onlylettershere'},
    {action: 'set-disabled', uid: '', disabled: true},
    {action: 'set-disabled', uid: 'a', disabled: 'yes'},
    {action: 'grant-admin', uid: 'a'},
    null, [],
  ]) if (!rejects(bad)) throw new Error(`Accepted ${JSON.stringify(bad)}`);
});

Deno.test('trainer claim never grants or keeps admin, and admins are not managed', () => {
  if (withTrainerClaim({admin: true, team: 'a'}) !== '{"team":"a","trainer":true}') throw new Error('Admin kept');
  if (parseClaims('{"trainer":true}').trainer !== true || Object.keys(parseClaims('not json')).length) throw new Error('Claims parse');
  if (!isManagedTrainer({trainer: true}) || isManagedTrainer({trainer: true, admin: true}) || isManagedTrainer({})) throw new Error('Managed check');
  const summary = trainerSummary({localId: 'u1', email: 'a@b.co', createdAt: '1762819200000', passwordHash: 'secret'});
  if (summary.uid !== 'u1' || summary.createdAt !== '2025-11-11T00:00:00.000Z' || 'passwordHash' in summary) throw new Error('Summary');
});
