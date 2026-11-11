import 'package:flutter_application_1/models/app_state.dart';
import 'package:flutter_application_1/models/training_program.dart';
import 'package:flutter_test/flutter_test.dart';

String _today() => DateTime.now().toIso8601String().substring(0, 10);

void main() {
  final state = AppState.instance;
  setUp(() => state.loadProfile(null));
  tearDown(() => state.loadProfile(null));

  test('an exercise added for today appears today and can be removed', () {
    state.addTodayExtra('Glute Bridge', sets: 4, reps: 20);
    final added = state.recommendedPlan.where((e) => e.name == 'Glute Bridge');
    expect(added, hasLength(1));
    expect(added.first.detail, startsWith('4 sets • 20 reps'));
    expect(state.isTodayExtra('Glute Bridge'), isTrue);
    expect(state.todayPlanJson['date'], _today());

    state.removeTodayExtra('Glute Bridge');
    expect(state.recommendedPlan.any((e) => e.name == 'Glute Bridge'), isFalse);
  });

  test('extras and adjustments saved on another day are ignored', () {
    state.loadProfile({
      'todayPlan': {
        'date': '2020-01-01',
        'extras': [
          {'name': 'Glute Bridge'},
        ],
        'adjustments': {
          'Push Up': {'sets': 9},
        },
      },
    });
    expect(state.recommendedPlan.any((e) => e.name == 'Glute Bridge'), isFalse);
    expect(
      state.recommendedPlan.any((e) => e.detail.startsWith('9 sets')),
      isFalse,
    );
    expect(state.todayExtras, isEmpty);
  });

  test("today's adjustments change values but keep time units", () {
    final timed = state.recommendedPlan.first;
    state.setTodayAdjustment(timed.name, {'sets': 5, 'reps': 40});
    final changed = state.recommendedPlan.first;
    expect(changed.detail, startsWith('5 sets • 40 '));
    final unit = RegExp(r'^\d+\s*(.*)$').firstMatch(timed.repsLabel)!.group(1);
    expect(changed.repsLabel, '40 $unit');
  });

  test('home members only get exercises for the equipment they own', () {
    state.loadProfile({
      'workoutEnvironment': 'Home (no equipment)',
      'equipment': ['dumbbells', 'not-a-real-item'],
      'workoutDays': TrainingProgram.weekdays,
    });
    expect(state.equipment, {Gear.dumbbells});
    expect(
      state.recommendedPlan.every(
        (e) => e.equipment == 'No equipment' || e.equipment == 'Dumbbells',
      ),
      isTrue,
    );
    state.updateWorkoutRequest('', 'No Equipment');
    expect(
      state.recommendedPlan.every((e) => e.equipment == 'No equipment'),
      isTrue,
    );
  });

  test("the old 'Full Body' default now follows the weekly program", () {
    state.loadProfile({'workoutFocus': 'Full Body'});
    expect(state.workoutFocus, TrainingProgram.programFocus);
    state.loadProfile({'workoutFocus': 'Core'});
    expect(state.workoutFocus, 'Core');
  });
}
