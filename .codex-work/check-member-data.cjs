const root='C:/Users/Acer/AppData/Roaming/npm/node_modules/firebase-tools/lib/';
const {getGlobalDefaultAccount}=require(root+'auth');
const {requireAuth}=require(root+'requireAuth');
const {Client}=require(root+'apiv2');
(async()=>{
 await requireAuth({project:'grindfit-app',...getGlobalDefaultAccount()});
 const client=new Client({urlPrefix:'https://firestore.googleapis.com',apiVersion:'v1'});
 const result=await client.get('/projects/grindfit-app/databases/(default)/documents/users',{queryParams:{pageSize:100}});
 const docs=result.body.documents||[];
 const roles={};for(const d of docs){const role=d.fields?.role?.stringValue||'member';roles[role]=(roles[role]||0)+1;}
 console.log(JSON.stringify({profiles:docs.length,hasMore:!!result.body.nextPageToken,roles,profileFields:[...new Set(docs.flatMap(d=>Object.keys(d.fields||{})))]}));
 let withWorkouts=0;const fields=new Set();
 for(const doc of docs){const r=await client.get('/'+doc.name+'/workouts',{queryParams:{pageSize:1}});if(r.body.documents?.length){withWorkouts++;Object.keys(r.body.documents[0].fields||{}).forEach(k=>fields.add(k));}}
 console.log(JSON.stringify({profilesWithWorkouts:withWorkouts,workoutFields:[...fields]}));
})().catch(e=>{console.error(e.message);process.exitCode=1});
