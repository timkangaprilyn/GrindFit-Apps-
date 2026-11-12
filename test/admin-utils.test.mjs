import {test} from 'node:test';
import assert from 'node:assert/strict';
import {memberPage, csvCell, reportRange, staffHome, portalRedirect} from '../web/admin-utils.mjs';
import {requestAdminData, requestStaff} from '../web/admin-cloud.mjs';
import {countMoves, trainerCounts, cleanTrainerProfile, sortRequests} from '../web/admin-coaching.mjs';

test('moving a member updates only trainers with public profiles', () => {
  const profiles = new Set(['a', 'b']);
  assert.deepEqual(countMoves('', 'a', profiles), [{uid: 'a', delta: 1}]);
  assert.deepEqual(countMoves('a', 'b', profiles), [{uid: 'a', delta: -1}, {uid: 'b', delta: 1}]);
  assert.deepEqual(countMoves('a', 'a', profiles), []);
  assert.deepEqual(countMoves('ghost', 'a', profiles), [{uid: 'a', delta: 1}]);
  assert.deepEqual(countMoves('a', '', profiles), [{uid: 'a', delta: -1}]);
  const counts = trainerCounts([{trainerUid: 'a'}, {trainerUid: 'a'}, {trainerUid: 'ghost'}, {}], profiles);
  assert.equal(counts.get('a'), 2); assert.equal(counts.get('b'), 0); assert.equal(counts.has('ghost'), false);
});

test('trainer profiles are trimmed and bounded', () => {
  assert.deepEqual(cleanTrainerProfile({displayName: '  Coach   Ana ', specialty: ' Strength ', bio: ' Hi ', active: true}), {displayName: 'Coach Ana', specialty: 'Strength', bio: 'Hi', active: true});
  assert.equal(cleanTrainerProfile({displayName: 'Coach', active: 'yes'}).active, false);
  assert.throws(() => cleanTrainerProfile({displayName: 'A'}), /name/);
  assert.throws(() => cleanTrainerProfile({displayName: 'Coach', bio: 'x'.repeat(401)}), /bio/);
  const at = (ms) => ({toMillis: () => ms});
  assert.deepEqual(sortRequests([{id: 2, createdAt: at(2)}, {id: 1, createdAt: at(1)}, {id: 0}]).map((r) => r.id), [0, 1, 2]);
});

test('trainer management calls admin-staff and surfaces server messages', async () => {
  const config = {url: 'https://example.supabase.co', publishableKey: 'public'};
  const ok = await requestStaff({config, token: 'firebase-token', body: {action: 'list'}, fetcher: async (url, options) => {
    assert.ok(url.endsWith('/functions/v1/admin-staff'));
    assert.equal(options.headers.Authorization, 'Bearer firebase-token');
    assert.equal(JSON.parse(options.body).action, 'list');
    return {ok: true, json: async () => ({trainers: []})};
  }});
  assert.deepEqual(ok, {trainers: []});
  const fail = (status, body) => async () => ({ok: false, status, json: async () => body});
  await assert.rejects(requestStaff({config, token: 't', body: {}, fetcher: fail(404, {})}), /not deployed/);
  await assert.rejects(requestStaff({config, token: 't', body: {}, fetcher: fail(409, {error: 'An account with this email already exists.'})}), /already exists/);
  await assert.rejects(requestStaff({config, token: 't', body: {}, fetcher: fail(403, {})}), /Only admin/);
  await assert.rejects(requestStaff({config, token: null, body: {}}), /Sign in/);
});

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

test('staff are sent to the dashboard their custom claims allow', () => {
  assert.equal(staffHome({admin: true, trainer: true}), 'admin.html');
  assert.equal(staffHome({trainer: true}), 'trainer.html');
  assert.equal(staffHome({role: 'admin'}), null);
  assert.equal(portalRedirect('admin', {admin: true}), null);
  assert.equal(portalRedirect('admin', {trainer: true}), 'trainer.html');
  assert.equal(portalRedirect('trainer', {trainer: true}), null);
  assert.equal(portalRedirect('trainer', {admin: true}), 'admin.html');
  assert.equal(portalRedirect('trainer', {admin: true, trainer: true}), null);
  assert.equal(portalRedirect('admin', {}), 'login.html?denied=1');
  assert.equal(portalRedirect('trainer', {admin: 'true'}), 'login.html?denied=1');
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

test('staff must replace the password they were given', async () => {
  const {mustChangePassword, newPasswordProblem} = await import('../web/admin-utils.mjs');
  const pw = [{providerId: 'password'}];
  assert.equal(mustChangePassword({providerUserInfo: pw, createdAt: '1000', passwordUpdatedAt: 1500}), true);
  assert.equal(mustChangePassword({providerUserInfo: pw, createdAt: '1000'}), true);
  assert.equal(mustChangePassword({providerUserInfo: pw, createdAt: '1000', passwordUpdatedAt: 1000 + 11 * 60000}), false);
  assert.equal(mustChangePassword({providerUserInfo: [{providerId: 'google.com'}], createdAt: '1000', passwordUpdatedAt: 1000}), false);
  assert.equal(mustChangePassword(null), false);
  assert.match(newPasswordProblem('short1', 'short1'), /12/);
  assert.match(newPasswordProblem('abcdefghijklm', 'abcdefghijklm'), /number/);
  assert.match(newPasswordProblem('abcdefghijk1', 'abcdefghijk1', 'abcdefghijk1'), /different/);
  assert.match(newPasswordProblem('abcdefghijk1', 'abcdefghijk2'), /match/);
  assert.equal(newPasswordProblem('abcdefghijk1', 'abcdefghijk1', 'old'), '');
});
