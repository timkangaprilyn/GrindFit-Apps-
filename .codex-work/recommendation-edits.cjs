const fs=require('node:fs');
for(const name of fs.readdirSync('lib/screens').filter(n=>n.endsWith('.dart'))){
 const file='lib/screens/'+name;
 let s=fs.readFileSync(file,'utf8');
 s=s.replace(/savedOverrides: (AppState\.instance|state)\.workoutPlanOverrides,/g, (_,base)=>`savedOverrides: ${base}.workoutPlanOverrides,
      fitnessLevel: ${base}.fitnessLevel,
      sessionDuration: ${base}.sessionDuration,
      hasInjuryOrCondition: ${base}.hasInjuryOrCondition,
      sessionIndex: ${base}.currentDayIndex - 1,`);
 s=s.replaceAll('AI Workout Recommendations','Workout Recommendations')
 .replaceAll('AI RECOMMENDED WORKOUT','RECOMMENDED WORKOUT')
 .replaceAll('AI adaptation','workout planning')
 .replaceAll('tailored AI-powered recommendations designed for your body','workout recommendations based on your preferences')
 .replaceAll('Injury Alert: We will adjust your workout recommendations accordingly for your safety.','Injury or condition reported: guided workouts require professional review. Automatic plans will be paused.')
 .replaceAll('Share relevant conditions so your workout recommendations can account for them.','Report relevant conditions. Automatic plans are paused while you seek professional guidance.');
 fs.writeFileSync(file,s);
}
