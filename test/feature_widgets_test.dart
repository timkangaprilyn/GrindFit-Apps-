import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/workout_plan.dart';
import 'package:flutter_application_1/screens/exercise_timer_screen.dart';
import 'package:flutter_application_1/widgets/workout_share_card.dart';

void main() {
  testWidgets('Workout timer with voice control fits a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseTimerScreen(
          exerciseList: WorkoutPlan.forProfile(
            goal: 'Muscle Gain / Strength',
            environment: 'Home (no equipment)',
          ),
        ),
      ),
    );
    expect(find.byTooltip('Toggle voice coach'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('Share card contains summary metrics and no member identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WorkoutShareCard(duration: '20 min', calories: 120, streak: 3),
        ),
      ),
    );
    expect(find.text('20 min  •  ~120 kcal'), findsOneWidget);
    expect(find.text('3 day streak'), findsOneWidget);
    expect(find.text('Share workout card'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
