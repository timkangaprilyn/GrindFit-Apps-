const fs=require('node:fs');const file='lib/screens/profile_screen.dart';
let s=fs.readFileSync(file,'utf8');
s="import 'privacy_screen.dart';\n"+s;
const a=s.indexOf('  Future<void> _showPrivacyPolicy()');
const b=s.indexOf('  Widget _buildHeaderCard(',a);
if(a<0||b<0) throw Error('Privacy route mismatch');
s=s.slice(0,a)+`  Future<void> _showPrivacyPolicy() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));
  }

`+s.slice(b);
const c=s.indexOf('class _PrivacySection extends');
if(c>=0) s=s.slice(0,c);
fs.writeFileSync(file,s);
