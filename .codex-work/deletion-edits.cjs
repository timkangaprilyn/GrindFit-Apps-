const fs=require('node:fs'); const file='lib/screens/profile_screen.dart';
let s=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
s="import '../services/account_data_repository.dart';\n"+s;
const a=s.indexOf('  Future<void> _deleteUserFirestoreData(');
const b=s.indexOf('  String _deleteErrorMessage(',a);
if(a<0||b<0) throw Error('Deletion block missing');
s=s.slice(0,a)+`  Future<void> _deleteUserFirestoreData(String uid) =>
      AccountDataRepository(FirebaseFirestore.instance, () => _user?.uid).delete(uid);

`+s.slice(b);
fs.writeFileSync(file,s);
