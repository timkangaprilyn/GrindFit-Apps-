import 'package:flutter_application_1/models/training_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 2 Nov 2026 is the program start; Mon/Wed/Fri schedule.
  final start = DateTime(2026, 11, 2);
  const days = ['Mon', 'Wed', 'Fri'];

  List<String> names(
    DateTime date, {
    String goal = 'Muscle Gain / Strength',
    Set<String> owned = const {Gear.gym},
  }) => TrainingProgram.sessionOn(
    date,
    goal: goal,
    days: days,
    owned: owned,
    sessionDuration: '45 min',
    start: start,
  )!.exercises.map((e) => e.name).toList();

  test('each training day in a week is a different workout', () {
    final week = TrainingProgram.week(
      start,
      goal: 'Muscle Gain / Strength',
      days: days,
      owned: {Gear.gym},
      sessionDuration: '45 min',
      start: start,
    );
    expect(week.map((s) => s.dayName), ['Push Day', 'Pull Day', 'Leg Day']);
    final sets = week
        .map((s) => s.exercises.map((e) => e.name).toSet())
        .toList();
    expect(sets[0].intersection(sets[1]), isEmpty);
    expect(sets[1].intersection(sets[2]), isEmpty);
    for (final goal in [
      'Weight Loss',
      'Endurance / Cardio',
      'General Fitness',
    ]) {
      final w = TrainingProgram.week(
        start,
        goal: goal,
        days: days,
        owned: const {},
        sessionDuration: '45 min',
        start: start,
      );
      expect(w.map((s) => s.dayName).toSet(), hasLength(3), reason: goal);
    }
  });

  test('rest days have no session and the next session is offered', () {
    final tuesday = DateTime(2026, 11, 3);
    expect(
      TrainingProgram.sessionOn(
        tuesday,
        goal: 'General Fitness',
        days: days,
        owned: const {},
        sessionDuration: '45 min',
        start: start,
      ),
      isNull,
    );
    final next = TrainingProgram.upcoming(
      tuesday,
      goal: 'General Fitness',
      days: days,
      owned: const {},
      sessionDuration: '45 min',
      start: start,
    );
    expect(next.isToday, isFalse);
    expect(next.date, DateTime(2026, 11, 4));
  });

  test('home workouts only use equipment the member owns', () {
    for (final date in [start, DateTime(2026, 11, 4), DateTime(2026, 11, 6)]) {
      final bodyweight = TrainingProgram.sessionOn(
        date,
        goal: 'Muscle Gain / Strength',
        days: days,
        owned: const {},
        sessionDuration: '60 min',
        start: start,
      )!;
      expect(bodyweight.exercises, isNotEmpty);
      expect(
        bodyweight.exercises.every((e) => e.equipment == 'No equipment'),
        isTrue,
      );
      final dumbbells = TrainingProgram.sessionOn(
        date,
        goal: 'Muscle Gain / Strength',
        days: days,
        owned: {Gear.dumbbells},
        sessionDuration: '60 min',
        start: start,
      )!;
      expect(
        dumbbells.exercises.every(
          (e) => e.equipment == 'No equipment' || e.equipment == 'Dumbbells',
        ),
        isTrue,
      );
      expect(
        dumbbells.exercises.any((e) => e.equipment == 'Dumbbells'),
        isTrue,
      );
    }
    expect(Gear.effective('Gym', const {}), {Gear.gym});
    expect(Gear.effective('Home (no equipment)', {Gear.band}), {Gear.band});
  });

  test(
    'weeks 1-3 build up, week 4 is lighter, and the next block is harder',
    () {
      final squat = TrainingProgram.byName('Bodyweight Squat')!;
      int reps(int week) => int.parse(
        RegExp(r'(\d+) reps')
            .firstMatch(
              TrainingProgram.prescribe(
                squat,
                goal: 'General Fitness',
                weekIndex: week,
              ).detail,
            )!
            .group(1)!,
      );
      int sets(int week) => int.parse(
        RegExp(r'(\d+) sets')
            .firstMatch(
              TrainingProgram.prescribe(
                squat,
                goal: 'General Fitness',
                weekIndex: week,
              ).detail,
            )!
            .group(1)!,
      );
      expect(reps(1), greaterThan(reps(0)));
      expect(reps(2), greaterThan(reps(1)));
      expect(sets(2), greaterThan(sets(0)));
      expect(reps(3), lessThan(reps(2)));
      expect(sets(3), lessThan(sets(2)));
      expect(reps(4), greaterThan(reps(0)));
      final session = TrainingProgram.sessionOn(
        DateTime(2026, 11, 23),
        goal: 'General Fitness',
        days: days,
        owned: const {},
        sessionDuration: '45 min',
        start: start,
      )!;
      expect(session.weekNumber, 4);
      expect(session.isLighterWeek, isTrue);
    },
  );

  test(
    'exercise choices stay fixed in a block and rotate in the next block',
    () {
      final week1 = names(start);
      final week2 = names(start.add(const Duration(days: 7)));
      final week5 = names(start.add(const Duration(days: 28)));
      expect(week2, week1);
      expect(week5, isNot(equals(week1)));
    },
  );

  test('session length controls the number of exercises', () {
    int count(String duration) => TrainingProgram.sessionOn(
      start,
      goal: 'Weight Loss',
      days: days,
      owned: const {},
      sessionDuration: duration,
      start: start,
    )!.exercises.length;
    expect(count('20 min'), 3);
    expect(count('30 min'), 4);
    expect(count('45 min'), 5);
    expect(count('60 min'), 6);
  });

  test('add-today choices match equipment, skip current exercises and lead with the goal', () {
    final groups = TrainingProgram.addable(
      goal: 'Weight Loss',
      owned: const {},
      exclude: {'Push Up'},
    );
    expect(groups.first.$1, 'Cardio');
    final all = groups.expand((g) => g.$2).toList();
    expect(all.every((e) => e.needs.isEmpty), isTrue);
    expect(all.any((e) => e.name == 'Push Up'), isFalse);
    expect(all.map((e) => e.name).toSet().length, all.length);
  });

  test('schedule days are normalized and ordered', () {
    expect(TrainingProgram.orderedDays(['Friday', 'mon', 'Wed']), [
      'Mon',
      'Wed',
      'Fri',
    ]);
    expect(TrainingProgram.orderedDays([]), ['Mon', 'Wed', 'Fri']);
  });

  test('focus override builds a matching session from owned equipment', () {
    final upper = TrainingProgram.focusSession(
      'Upper Body',
      goal: 'Muscle Gain / Strength',
      owned: const {},
      sessionDuration: '45 min',
    )!;
    expect(upper, hasLength(5));
    expect(upper.every((e) => e.equipment == 'No equipment'), isTrue);
    expect(
      TrainingProgram.focusSession(
        TrainingProgram.programFocus,
        goal: 'Weight Loss',
        owned: const {},
        sessionDuration: '45 min',
      ),
      isNull,
    );
  });
}
