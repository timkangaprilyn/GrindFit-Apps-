import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/workout_plan.dart';

void main() {
  test('low energy produces a recovery plan', () {
    final plan = WorkoutPlan.personalized(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      lowEnergy: true,
    );
    expect(
      plan.map((exercise) => exercise.name),
      containsAll(['Gentle stretching', 'Mobility flow']),
    );
  });

  test('hard feedback reduces sets without removing all sets', () {
    final normal = WorkoutPlan.personalized(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
    );
    final adjusted = WorkoutPlan.personalized(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      feedback: 'Hard',
    );
    expect(adjusted.length, normal.length);
    expect(adjusted.first.detail, startsWith('2 sets'));
  });

  test('no equipment request excludes weights', () {
    final plan = WorkoutPlan.personalized(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      request: 'No Equipment',
    );
    expect(plan, isNotEmpty);
    expect(
      plan.every((exercise) {
        final equipment = exercise.equipment.toLowerCase();
        return equipment.contains('bodyweight') ||
            equipment.contains('no equipment');
      }),
      isTrue,
    );
  });
}
