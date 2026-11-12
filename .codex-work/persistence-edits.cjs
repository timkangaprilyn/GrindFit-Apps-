const fs = require('node:fs');
const file='lib/screens/workout_complete_screen.dart';
let s=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
s=s.replace("import '../models/app_state.dart';", "import '../models/app_state.dart';\nimport '../services/workout_repository.dart';");
s=s.replace('  DocumentReference<Map<String, dynamic>>? _notificationDocument;', '  bool _saved = false;');
s=s.replace('  Future<void> _saveWorkout() async {', '  Future<void> _saveWorkout() async {\n    if (_saved) return;\n    if (mounted) setState(() { _isSaving = true; _saveError = null; });');
const start=s.indexOf('      final profileDoc = await userRef.get();');
const end=s.indexOf('      if (mounted) setState(() => _isSaving = false);',start);
if(start<0||end<0) throw Error('Save block mismatch');
s=s.slice(0,start)+`      _workoutDocument ??= userRef.collection('workouts').doc();
      final nextDay = await WorkoutRepository(FirebaseFirestore.instance).complete(
        uid: user.uid, sessionId: _workoutDocument!.id, session: session,
      );
      _saved = true;
      AppState.instance.setProgramDay(nextDay);
`+s.slice(end);
fs.writeFileSync(file,s);
