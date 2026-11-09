const day = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
export const localDayKey = (d) => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
export function profileDate(value) {
  const parsed = value?.toDate ? value.toDate() : value instanceof Date ? value : typeof value === 'string' ? new Date(value) : null;
  return parsed && Number.isFinite(parsed.getTime()) ? parsed : null;
}

export function communityInsights(members, {now = new Date(), workoutDate = (w) => profileDate(w.timestamp), inactiveDays = 14} = {}) {
  const today = day(now);
  const seven = new Date(today.getFullYear(),today.getMonth(),today.getDate()-7);
  const fourteen = new Date(today.getFullYear(),today.getMonth(),today.getDate()-14);
  const start = new Date(today.getFullYear(),today.getMonth(),today.getDate()-27);
  const days = Array.from({length:28},(_,i)=>({date:new Date(start.getFullYear(),start.getMonth(),start.getDate()+i),sessions:[],count:0}));
  const byDay = new Map(days.map((d)=>[localDayKey(d.date),d]));
  let recent = 0, previous = 0;
  const regulars = [];
  members.forEach((member)=>{
    const distinct = new Set();
    (member.workouts || []).forEach((workout)=>{
      const date = workoutDate(workout);
      if (!date || !Number.isFinite(date.getTime()) || date > now) return;
      if (date >= seven && date < today) recent++;
      else if (date >= fourteen && date < seven) previous++;
      const bucket = byDay.get(localDayKey(date));
      if (bucket) {bucket.count++;bucket.sessions.push({member,workout});distinct.add(localDayKey(date));}
    });
    if (distinct.size) regulars.push({member,days:distinct.size});
  });
  regulars.sort((a,b)=>b.days-a.days || String(a.member.fullName||'').localeCompare(String(b.member.fullName||'')));
  const cutoff = new Date(now.getTime()-inactiveDays*86400000);
  const followUps = members.filter((m)=>{
    const last = profileDate(m.lastWorkout);
    if (last) return last < cutoff;
    const joined = profileDate(m.createdAt);
    return !joined || joined < cutoff;
  }).sort((a,b)=>(profileDate(a.lastWorkout)?.getTime()||0)-(profileDate(b.lastWorkout)?.getTime()||0));
  const monthAgo = new Date(today.getFullYear(),today.getMonth(),today.getDate()-29);
  const joiners = members.map((member)=>({member,joined:profileDate(member.createdAt)})).filter((m)=>m.joined && m.joined >= monthAgo && m.joined <= now).sort((a,b)=>b.joined-a.joined);
  return {recent,previous,change:recent-previous,days,regulars,followUps,joiners,
    loggedDays:regulars.reduce((sum,m)=>sum+m.days,0),sessions:days.reduce((sum,d)=>sum+d.count,0)};
}
