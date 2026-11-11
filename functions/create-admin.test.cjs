const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createAdmin, createStaff} = require('./create-admin.cjs');
test('new trainer gets only the trainer claim and is verified', async()=>{
  let claims={}; let disabled=true;
  const auth={getUserByEmail:async()=>{throw {code:'auth/user-not-found'};},createUser:async(data)=>{assert.equal(data.displayName,'GrindFit Trainer');return {uid:'new-trainer'};},setCustomUserClaims:async(uid,value)=>{claims=value;},updateUser:async(uid,data)=>{disabled=data.disabled;},getUser:async()=>({uid:'new-trainer',customClaims:claims,disabled})};
  const result=await createStaff(auth,'trainer@example.com','A'.repeat(24),'trainer');
  assert.deepEqual(claims,{trainer:true});
  assert.equal(result.trainer,true); assert.equal(result.admin,undefined);
});
test('unknown staff roles are rejected before any write', async()=>{
  await assert.rejects(createStaff({getUserByEmail:async()=>{throw new Error('should not be called');}},'x@example.com','A'.repeat(24),'owner'),/admin or trainer/);
});
test('new admin is disabled until the admin claim is set and is verified afterwards', async()=>{
  const events=[]; let claims={}; let disabled=true;
  const auth={getUserByEmail:async()=>{throw {code:'auth/user-not-found'};},createUser:async(data)=>{events.push('create');assert.equal(data.disabled,true);return {uid:'new-admin'};},setCustomUserClaims:async(uid,value)=>{events.push('claim');claims=value;},updateUser:async(uid,data)=>{events.push('enable');disabled=data.disabled;},getUser:async()=>({uid:'new-admin',customClaims:claims,disabled})};
  assert.equal((await createAdmin(auth,'admin@example.com','A'.repeat(24))).admin,true);
  assert.deepEqual(events,['create','claim','enable']);
});
test('existing emails are never overwritten or promoted', async()=>{
  let writes=0;
  await assert.rejects(createAdmin({getUserByEmail:async()=>({uid:'member'}),createUser:async()=>writes++},'admin@example.com','A'.repeat(24)),/already exists/);
  assert.equal(writes,0);
});
test('failed claim assignment never enables the account', async()=>{
  let enabled=false;
  await assert.rejects(createAdmin({getUserByEmail:async()=>{throw {code:'auth/user-not-found'};},createUser:async()=>({uid:'a'}),setCustomUserClaims:async()=>{throw new Error('Denied');},updateUser:async()=>{enabled=true;}},'admin@example.com','A'.repeat(24)),/Denied/);
  assert.equal(enabled,false);
});
