import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/app_state.dart';
import 'package:flutter_application_1/models/workout_plan.dart';

void main() {
  final state = AppState.instance;

  setUp(() => state.loadProfile(null));
  tearDown(() => state.loadProfile(null));

  test(
    'offline mode replaces an existing AI plan using current preferences',
    () {
      state.setGeneratedPlan([
        const PlanExercise(
          name: 'Old online exercise',
          detail: '3 sets',
          repsLabel: '10 reps',
          muscles: 'Chest',
          equipment: 'Weights',
        ),
      ], 'Personalized online plan');
      state.updateWorkoutRequest('No Equipment', 'Full Body');
      state.useOfflineWorkout();

      expect(state.generatedPlan, isNull);
      expect(state.planSource, contains('offline'));
      expect(state.recommendedPlan, isNotEmpty);
      expect(
        state.recommendedPlan.any((e) => e.name == 'Old online exercise'),
        isFalse,
      );
      expect(
        state.recommendedPlan.every((e) {
          final equipment = e.equipment.toLowerCase();
          return equipment.contains('bodyweight') ||
              equipment.contains('no equipment');
        }),
        isTrue,
      );
    },
  );

  test('offline recommendation still responds to low energy check-in', () {
    state.useOfflineWorkout();
    state.updateCheckIn(4, 1);
    expect(
      state.recommendedPlan.map((e) => e.name),
      containsAll(['Gentle stretching', 'Mobility flow']),
    );
  });
}
