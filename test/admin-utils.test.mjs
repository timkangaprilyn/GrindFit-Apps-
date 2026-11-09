import {test} from 'node:test';
import assert from 'node:assert/strict';
import {memberPage, csvCell, reportRange} from '../web/admin-utils.mjs';
import {requestAdminData} from '../web/admin-cloud.mjs';

test('member filters and pagination share the same matching set', () => {
  const members = Array.from({length: 26}, (_, i) => ({fullName: `Member ${i}`, fitnessGoal: 'Strength', weeklyCount: i, lastWorkout: new Date(2026, 10, 8), injuryAlert: i % 2 === 0}));
  const result = memberPage(members, {filter: 'risk', sort: 'weekly', page: 2});
  assert.equal(result.total, 13); assert.equal(result.items.length, 1); assert.equal(result.items[0].weeklyCount, 0);
  assert.equal(memberPage(members, {page: 99}).page, 3);
  assert.equal(memberPage(members, {search: 'missing', page: 99}).page, 1);
  assert.equal(memberPage(members, {search: 'STRENGTH'}).total, 26);
});
test('inactive filter includes never trained and old profiles, excluding recent ones', () => {
  const result = memberPage([{fullName: 'Never'}, {fullName: 'Old', lastWorkout: new Date(2026, 9, 1)}, {fullName: 'Recent', lastWorkout: new Date(2026, 10, 8)}], {filter: 'inactive', now: new Date(2026, 10, 9)});
  assert.deepEqual(result.items.map((m) => m.fullName).sort(), ['Never', 'Old']);
});
test('CSV protects formula cells and preserves quoted or multiline data', () => {
  assert.equal(csvCell('=SUM(1,2)'), '"\'=SUM(1,2)"');
  assert.equal(csvCell(' @formula'), '"\' @formula"');
  assert.equal(csvCell('a"b\nc'), '"a""b\nc"');
  assert.equal(csvCell(null), '""'); assert.equal(csvCell(30), '"30"');
});
test('report presets span calendar boundaries and include today', () => {
  assert.deepEqual(reportRange('7', new Date(2026, 0, 3)), {from: '2025-12-28', to: '2026-01-03'});
  assert.deepEqual(reportRange('month', new Date(2026, 10, 9)), {from: '2026-11-01', to: '2026-11-09'});
});

test('cloud reads use Firebase tokens with only public app credentials', async () => {
  const result = await requestAdminData({config:{url:'https://example.supabase.co',publishableKey:'public-key'},token:'firebase-token',body:{action:'member',member_uid:'member-a'},fetcher:async (url, options) => {
    assert.ok(url.endsWith('/functions/v1/admin-member-data'));
    assert.equal(options.headers.Authorization,'Bearer firebase-token');
    assert.equal(options.headers.apikey,'public-key');
    assert.equal(JSON.parse(options.body).member_uid,'member-a');
    return {ok:true,json:async()=>({analytics:{available:true,rows:[]}})};
  }});
  assert.equal(result.analytics.available,true);
});

test('cloud errors distinguish role, session and undeployed backend', async () => {
  for (const [status, message] of [[401,/session/],[403,/admin role/],[404,/not deployed/],[503,/Could not load/]]) {
    await assert.rejects(requestAdminData({config:{url:'https://example.supabase.co',publishableKey:'public'},token:'token',body:{action:'status'},fetcher:async()=>({ok:false,status})}),message);
  }
  await assert.rejects(requestAdminData({config:{},token:null,body:{}}),/Sign in/);
});
