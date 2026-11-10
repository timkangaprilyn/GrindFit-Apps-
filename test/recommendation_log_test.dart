import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/workout_plan.dart';
import 'package:flutter_application_1/screens/manual_log_workout_screen.dart';

void main() {
  testWidgets('selected recommendation prefills the workout log', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ManualLogWorkoutScreen(
          exercise: PlanExercise(
            name: 'Recommended exercise',
            detail: '4 sets • 17 reps • 60s',
            repsLabel: '17 reps',
            muscles: 'Core',
            equipment: 'Bodyweight',
          ),
        ),
      ),
    );

    final dropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>).first,
    );
    expect(dropdown.value, 'Recommended exercise');
    expect(find.text('4'), findsOneWidget);
    expect(find.text('17'), findsOneWidget);
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.any((field) => field.controller?.text == '60'), isTrue);
    expect(tester.takeException(), isNull);
  });
}
