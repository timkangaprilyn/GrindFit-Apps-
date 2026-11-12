const fs=require('node:fs');
const file='test/widget_test.dart'; let s=fs.readFileSync(file,'utf8').replaceAll('\r\n','\n');
const a=s.indexOf("  testWidgets('Warm-up timer starts automatically");
const b=s.indexOf("  testWidgets('Log workout",a);
if(a<0||b<0) throw Error('Old warmup tests missing');
s=s.slice(0,a)+`  testWidgets('Warm-up waits for Start, pauses, extends, and skips without auto advance', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: WarmupScreen(exerciseList: [
      PlanExercise(name: 'Push Up', detail: '3 sets • 10 reps • 45s',
        repsLabel: '10 reps', muscles: 'Chest', equipment: 'None'),
    ])));
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('00:30'), findsOneWidget);
    await tester.ensureVisible(find.text('Start timer'));
    await tester.tap(find.text('Start timer')); await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:29'), findsOneWidget);
    await tester.tap(find.text('Pause timer')); await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('00:29'), findsOneWidget);
    await tester.ensureVisible(find.text('+15 seconds'));
    await tester.tap(find.text('+15 seconds')); await tester.pump();
    expect(find.text('00:44'), findsOneWidget);
    await tester.tap(find.text('Start timer')); await tester.pump();
    await tester.pump(const Duration(seconds: 44));
    expect(find.text('00:00'), findsOneWidget);
    expect(find.text('Arm Circles'), findsOneWidget);
    await tester.tap(find.text('Next / Skip step')); await tester.pump();
    expect(find.text('Dynamic Torso Twists'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('00:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

`+s.slice(b);
fs.writeFileSync(file,s);
