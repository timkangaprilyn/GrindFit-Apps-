import {requireAdmin, validateAdminRequest} from './policy.ts';
Deno.test('only the verified boolean admin claim grants cross-member reads', () => {
  if (!requireAdmin({admin: true})) throw new Error('Admin denied');
  for (const claims of [{}, {trainer: true}, {admin: 'true'}, {role: 'admin'}, {admin: false}]) {
    if (requireAdmin(claims)) throw new Error('Untrusted role accepted');
  }
});
Deno.test('requests allow bounded member reads and reject write operations', () => {
  if (validateAdminRequest({action: 'member', member_uid: 'member-a', admin: true}).memberUid !== 'member-a') throw new Error('Member missing');
  if (validateAdminRequest({action: 'status'}).action !== 'status') throw new Error('Status missing');
  for (const data of [{action:'save',member_uid:'a'}, {action:'member', member_uid:''}, {action:'member', member_uid:'a'.repeat(129)}, {action:'member',member_uid:'a\n'}, null]) {
    let rejected = false;
    try { validateAdminRequest(data); } catch (_) { rejected = true; }
    if (!rejected) throw new Error('Unsafe request accepted');
  }
});
