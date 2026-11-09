import {test} from 'node:test';
import assert from 'node:assert/strict';
import {communityInsights} from '../web/admin-insights.mjs';
const now = new Date(2026,10,9,12);
const workout = (d,h=10)=>({timestamp:new Date(2026,10,d,h)});
test('weekly comparison excludes partial today and future logs',()=>{
  const result=communityInsights([{workouts:[workout(2),workout(2,11),workout(8),workout(9),workout(10),workout(1)]}],{now});
  assert.equal(result.recent,3);assert.equal(result.previous,1);assert.equal(result.change,2);
  assert.equal(result.sessions,5);assert.equal(result.regulars[0].days,4);
  assert.equal(result.days.at(-1).count,1);
});
test('follow ups use configured threshold and give new profiles time to start',()=>{
  const result=communityInsights([{id:'new',createdAt:new Date(2026,10,8)},{id:'old',createdAt:new Date(2026,9,1)},{id:'undated'},{id:'recent',lastWorkout:new Date(2026,10,8)},{id:'inactive',lastWorkout:new Date(2026,9,1)}],{now,inactiveDays:14});
  assert.deepEqual(result.followUps.map((m)=>m.id).sort(),['inactive','old','undated']);
  assert.deepEqual(result.joiners.map((m)=>m.member.id),['new']);
});
test('calendar has 28 real calendar days across a year boundary',()=>{
  const result=communityInsights([],{now:new Date(2026,0,3)});
  assert.equal(result.days.length,28);assert.equal(result.days[0].date.getFullYear(),2025);
  assert.equal(result.days.at(-1).date.getDate(),3);assert.equal(result.loggedDays,0);
  assert.deepEqual(result.regulars,[]);
});
test('invalid timestamps and future signup dates do not create activity',()=>{
  const result=communityInsights([{createdAt:new Date(2027,0,1),workouts:[{timestamp:'bad-date'}]}],{now});
  assert.equal(result.sessions,0);assert.equal(result.joiners.length,0);
});
