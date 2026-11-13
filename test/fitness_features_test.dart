import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/fitness_features.dart';
import 'package:flutter_application_1/models/workout_plan.dart';
import 'package:flutter_application_1/models/app_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  test(
    'Easy feedback cannot override a missed-session reduction explanation',
    () {
      final state = AppState.instance;
      state.loadProfile({
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 8)),
        ),
        'workoutDays': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      });
      state.updateActivity([]);
      state.updateFeedback('Easy');
      expect(state.missedWorkoutDays, 7);
      expect(state.adaptationReason, contains('fewer sets'));
    },
  );
  test(
    'Missed-day adaptation excludes today and dates before registration',
    () {
      final result = TrainingAdaptation.calculate(
        now: DateTime(2026, 11, 9),
        startedAt: DateTime(2026, 11, 5),
        scheduledDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        completed: [DateTime(2026, 11, 5)],
        feedback: 'Easy',
      );
      expect(result.missedDays, 1); // Friday only; Monday is today.
      expect(result.reason, contains('fewer sets'));
    },
  );
  test('Completing scheduled sessions keeps steady progression', () {
    final result = TrainingAdaptation.calculate(
      now: DateTime(2026, 11, 9),
      startedAt: DateTime(2026, 11, 5),
      scheduledDays: ['Thu', 'Fri'],
      completed: [DateTime(2026, 11, 5), DateTime(2026, 11, 6)],
      feedback: 'Easy',
    );
    expect(result.missedDays, 0);
    expect(result.reason, contains('Add one set'));
  });
  test('New members do not inherit missed sessions', () {
    expect(
      TrainingAdaptation.calculate(
        now: DateTime(2026, 11, 9),
        scheduledDays: ['Mon'],
        completed: [],
        feedback: '',
      ).missedDays,
      0,
    );
  });
  test('Pain exclusions remove the reported area and general pain stops suggestions', () {
    final catalog = WorkoutPlan.catalog('Gym');
    expect(PainPolicy.filter(catalog, 'Back / neck'), isEmpty);
    expect(
      PainPolicy.filter(
        catalog,
        'Knee / leg',
      ).any((e) => e.name == 'Bodyweight Squat'),
      isFalse,
    );
    expect(
      PainPolicy.filter(
        catalog,
        'Shoulder / arm',
      ).any((e) => e.name == 'Push Up'),
      isFalse,
    );
  });
  test('Every focus can draw from the library rather than only the default three exercises', () {
    for (final focus in [
      'Upper Body',
      'Lower Body',
      'Core',
      'Back at Biceps',
      'Shoulders',
    ]) {
      final plan = WorkoutPlan.personalized(
        goal: 'Muscle Gain / Strength',
        environment: 'Gym',
        focus: focus,
      );
      expect(plan, isNotEmpty, reason: focus);
    }
    final core = WorkoutPlan.personalized(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      focus: 'Core',
    );
    expect(
      core.every(
        (e) =>
            e.muscles.toLowerCase().contains('core') ||
            e.muscles.toLowerCase().contains('abs'),
      ),
      isTrue,
    );
  });
  test('Swaps offer a no-equipment exercise for the same muscle group', () {
    final row = WorkoutPlan.catalog('Gym')
        .firstWhere((e) => e.name == 'Dumbbell Row');
    final alternatives = WorkoutPlan.alternativesFor(row, environment: 'Gym');
    expect(alternatives.any((e) => e.name == 'Prone Reverse Fly'), isTrue);
  });
  test('Meal ideas respect budgets and ingredient exclusions', () {
    final ideas = PinoyMeals.forBudget(50, {'egg', 'soy'}, plantOnly: true);
    expect(ideas, isNotEmpty);
    expect(
      ideas.every(
        (m) =>
            m.estimatedPesos <= 50 &&
            !m.tags.contains('egg') &&
            !m.tags.contains('soy'),
      ),
      isTrue,
    );
    expect(PinoyMeals.forBudget(20, {}), isEmpty);
  });
  test('Rank boundaries and levels match XP milestones', () {
    expect(FitnessRank.name(999), 'Rookie');
    expect(FitnessRank.name(1000), 'Grinder');
    expect(FitnessRank.name(3000), 'Beast');
    expect(FitnessRank.level(250), 2);
  });
  test('XP from saved workouts follows the server crediting rules', () {
    Map<String, dynamic> workout(
      DateTime at, {
      int seconds = 600,
      int sets = 3,
      bool skipped = false,
    }) => {
      'durationSeconds': seconds,
      'timestamp': at,
      'exercises': [
        {'name': 'Push Up', 'sets': sets, 'skipped': skipped},
      ],
    };
    final day = DateTime.utc(2026, 11, 10, 8);
    expect(
      FitnessRank.xpFromWorkouts([
        // Four on one UTC day: only three are credited.
        for (var i = 0; i < 4; i++) workout(day.add(Duration(hours: i))),
        workout(day.add(const Duration(days: 1))),
        workout(day, seconds: 30), // too short
        workout(day, sets: 0), // nothing completed
        workout(day, skipped: true), // skipped
        {
          // Offline outbox encoding.
          'durationSeconds': 120,
          'timestamp': {
            '__timestamp': day
                .add(const Duration(days: 2))
                .millisecondsSinceEpoch,
          },
          'exercises': [
            {'sets': 1},
          ],
        },
      ]),
      250,
    );
    expect(FitnessRank.xpFromWorkouts(const []), 0);
  });
  test('Form guidance differs for rows, squats and planks', () {
    expect(FormGuide.forExercise('Dumbbell Row').mistake, contains('back'));
    expect(
      FormGuide.forExercise('Bodyweight Squat').mistake,
      contains('knees'),
    );
    expect(FormGuide.forExercise('Plank Hold').mistake, contains('breath'));
  });
}
