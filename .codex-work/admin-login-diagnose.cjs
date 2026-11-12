const root = 'C:/Users/Acer/AppData/Roaming/npm/node_modules/firebase-tools/lib/';
const {getGlobalDefaultAccount} = require(root+'auth');
const {requireAuth} = require(root+'requireAuth');
const {Client} = require(root+'apiv2');
(async()=>{
  await requireAuth({project:'grindfit-app',...getGlobalDefaultAccount()});
  const client=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'v1'});
  const response=await client.post('/projects/grindfit-app/accounts:lookup',{email:['admin@test.com']});
  console.log(JSON.stringify({accounts:(response.body.users||[]).map(u=>({uid:u.localId,email:u.email,disabled:!!u.disabled,claims:u.customAttributes?JSON.parse(u.customAttributes):{},passwordEnabled:!!u.passwordHash,providers:(u.providerUserInfo||[]).map(p=>p.providerId)}))}));
  const configClient=new Client({urlPrefix:'https://identitytoolkit.googleapis.com',apiVersion:'admin/v2'});
  const config=await configClient.get('/projects/grindfit-app/config');
  console.log(JSON.stringify({emailPasswordEnabled:config.body.signIn?.email?.enabled,passwordRequired:config.body.signIn?.email?.passwordRequired}));
})().catch(e=>{console.error(e.message);process.exitCode=1});
