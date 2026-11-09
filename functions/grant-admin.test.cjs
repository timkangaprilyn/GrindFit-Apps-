const {test} = require('node:test');
const assert = require('node:assert/strict');
const {grantAdmin} = require('./grant-admin.cjs');

test('grants admin while preserving existing custom claims and verifies the result', async () => {
  let claims = {trainer: true, customFeature: 'enabled'};
  let reads = 0;
  const result = await grantAdmin({getUser: async (uid) => {reads++; return {uid, customClaims: claims};}, setCustomUserClaims: async (uid, value) => {assert.equal(uid, 'member-a'); claims = value;}}, 'member-a');
  assert.deepEqual(claims, {trainer: true, customFeature: 'enabled', admin: true});
  assert.equal(reads, 2); assert.equal(result.admin, true);
});
test('existing admin requires no extra write; disabled users cannot be promoted', async () => {
  let writes = 0;
  await grantAdmin({getUser: async (uid) => ({uid, customClaims: {admin: true}}), setCustomUserClaims: async () => writes++}, 'a');
  assert.equal(writes, 0);
  await assert.rejects(grantAdmin({getUser: async (uid) => ({uid, disabled: true}), setCustomUserClaims: async () => writes++}, 'a'), /disabled/);
  assert.equal(writes, 0);
});
test('invalid UID and failed verification do not claim successful promotion', async () => {
  await assert.rejects(grantAdmin({}, ''), /valid/);
  await assert.rejects(grantAdmin({getUser: async (uid) => ({uid}), setCustomUserClaims: async () => {}}, 'a'), /verified/);
});
