import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

import 'workout_plan.dart';

String localDay(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class TrainingAdaptation {
  const TrainingAdaptation(this.missedDays, this.reason);
  final int missedDays;
  final String reason;

  static TrainingAdaptation calculate({
    required DateTime now,
    required List<String> scheduledDays,
    required Iterable<DateTime> completed,
    required String feedback,
    DateTime? startedAt,
  }) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dates = completed.map((date) => localDay(date.toLocal())).toSet();
    var missed = 0;
    // Ignore today, future sessions and dates before the member joined.
    for (var ago = 1; ago <= 7; ago++) {
      final day = DateTime(now.year, now.month, now.day - ago);
      if (startedAt == null ||
          day.isBefore(
            DateTime(startedAt.year, startedAt.month, startedAt.day),
          )) {
        continue;
      }
      if (scheduledDays.contains(weekdays[day.weekday - 1]) &&
          !dates.contains(localDay(day))) {
        missed++;
      }
    }
    if (missed > 0) {
      return TrainingAdaptation(
        missed,
        '$missed scheduled session${missed == 1 ? '' : 's'} missed in the last week. Restart with fewer sets; no extra catch-up sessions.',
      );
    }
    return TrainingAdaptation(0, switch (feedback.toLowerCase()) {
      'easy' => 'Your last session felt easy. Add one set, within five sets per exercise.',
      'hard' => 'Your last session felt hard. Reduce one set and keep a comfortable pace.',
      _ => 'Keep a steady workload. Recovery and consistency come first.',
    });
  }
}

class FitnessRank {
  static String name(int xp) => xp >= 3000
      ? 'Beast'
      : xp >= 1000
      ? 'Grinder'
      : 'Rookie';
  static int level(int xp) => xp ~/ 250 + 1;
  static int nextRank(int xp) => xp < 1000
      ? 1000
      : xp < 3000
      ? 3000
      : (level(xp) * 250);

  static const int xpPerWorkout = 50;
  static const int creditedWorkoutsPerDay = 3;

  /// XP earned from the member's saved workouts, using the same rules as the
  /// `awardWorkoutXp` Cloud Function: 50 XP for a workout of 1 minute to 6
  /// hours with at least one completed, non-skipped set, up to three credited
  /// workouts per UTC day. Lets XP and levels work before (or without) the
  /// rewards backend being deployed.
  static int xpFromWorkouts(Iterable<Map<String, dynamic>> workouts) {
    final perDay = <String, int>{};
    for (final workout in workouts) {
      final day = _creditDay(workout);
      if (day == null) continue;
      perDay[day] = (perDay[day] ?? 0) + 1;
    }
    return perDay.values.fold<int>(
      0,
      (total, count) =>
          total +
          (count < creditedWorkoutsPerDay ? count : creditedWorkoutsPerDay) *
              xpPerWorkout,
    );
  }

  static String? _creditDay(Map<String, dynamic> workout) {
    final duration = workout['durationSeconds'];
    if (duration is! num || duration < 60 || duration > 21600) return null;
    final raw = workout['timestamp'];
    final DateTime? time = raw is DateTime
        ? raw
        : raw is Timestamp
        ? raw.toDate()
        // Offline outbox entries encode dates as {'__timestamp': millis}.
        : raw is Map && raw['__timestamp'] is num
        ? DateTime.fromMillisecondsSinceEpoch(
            (raw['__timestamp'] as num).toInt(),
          )
        : null;
    if (time == null || time.isAfter(DateTime.now().add(_clockSkew))) {
      return null;
    }
    final exercises = workout['exercises'];
    if (exercises is! List ||
        !exercises.any(
          (e) =>
              e is Map &&
              e['sets'] is num &&
              e['sets'] > 0 &&
              e['skipped'] != true,
        )) {
      return null;
    }
    return time.toUtc().toIso8601String().substring(0, 10);
  }

  static const Duration _clockSkew = Duration(minutes: 5);
}

class FormGuide {
  const FormGuide(this.steps, this.mistake);
  final List<String> steps;
  final String mistake;
  static FormGuide forExercise(String name) {
    final n = name.toLowerCase();
    if (n.contains('squat')) {
      return const FormGuide([
        'Stand with feet about shoulder width apart.',
        'Sit your hips back while knees follow your toes.',
        'Keep heels down and stand with control.',
      ], 'Letting knees collapse inward or lifting heels.');
    }
    if (n.contains('lunge') || n.contains('step up')) {
      return const FormGuide([
        'Stand tall beside a stable support if needed.',
        'Step with control and keep your knee following your toes.',
        'Push through the whole foot and return slowly.',
      ], 'Dropping quickly or pushing through knee pain.');
    }
    if (n.contains('row')) {
      return const FormGuide([
        'Brace your trunk and keep a neutral back.',
        'Draw elbows back toward your hips.',
        'Lower slowly without twisting your torso.',
      ], 'Rounding your back or swinging the weight.');
    }
    if (n.contains('press') && !n.contains('bench')) {
      return const FormGuide([
        'Start with hands at shoulder level.',
        'Brace your trunk and press within a comfortable range.',
        'Lower slowly without arching your back.',
      ], 'Leaning backward or shrugging into discomfort.');
    }
    if (n.contains('push') || n.contains('bench')) {
      return const FormGuide([
        'Place hands slightly wider than shoulders.',
        'Keep your body aligned and lower with control.',
        'Press up while keeping elbows comfortably angled.',
      ], 'Sagging your hips or flaring elbows excessively.');
    }
    if (n.contains('plank') || n.contains('dead bug')) {
      return const FormGuide([
        'Brace your abdomen and keep a neutral spine.',
        'Keep shoulders supported and move only as instructed.',
        'Breathe throughout; stop before your form breaks.',
      ], 'Holding your breath or letting the lower back arch.');
    }
    if (n.contains('bridge')) {
      return const FormGuide([
        'Lie on your back with knees bent and feet flat.',
        'Gently brace and lift your hips using your glutes.',
        'Lower slowly without arching your back.',
      ], 'Overextending the lower back.');
    }
    if (n.contains('curl')) {
      return const FormGuide([
        'Stand tall with elbows close to your sides.',
        'Bend elbows without moving your upper arms.',
        'Lower slowly through a comfortable range.',
      ], 'Swinging your trunk to lift the weight.');
    }
    if (n.contains('walk') || n.contains('jog') || n.contains('march')) {
      return const FormGuide([
        'Stand tall and look ahead.',
        'Take comfortable steps and let arms move naturally.',
        'Choose a pace where you can still speak.',
      ], 'Increasing speed despite pain or dizziness.');
    }
    if (n.contains('jump') || n.contains('jack')) {
      return const FormGuide([
        'Use a clear, level surface.',
        'Land softly with knees following your toes.',
        'Use a stepping version if impact is uncomfortable.',
      ], 'Landing stiff-legged or continuing through joint pain.');
    }
    return const FormGuide([
      'Start in a stable, supported position.',
      'Use a slow, comfortable range and breathe steadily.',
      'Stop if you feel pain; ask a trainer for a form check.',
    ], 'Rushing, holding your breath, or forcing a painful range.');
  }
}

class PainPolicy {
  static const areas = [
    'None',
    'Knee / leg',
    'Shoulder / arm',
    'Back / neck',
    'Other',
  ];
  static List<PlanExercise> filter(List<PlanExercise> plan, String area) {
    if (area == 'None') return plan;
    final blocked = switch (area) {
      'Knee / leg' => [
        'leg',
        'quad',
        'glute',
        'hamstring',
        'calf',
        'cardio',
        'full body',
      ],
      'Shoulder / arm' => [
        'shoulder',
        'chest',
        'back',
        'tricep',
        'bicep',
        'arm',
        'full body',
      ],
      _ => <String>[],
    };
    if (blocked.isEmpty) return [];
    return plan
        .where(
          (exercise) => !blocked.any(
            (word) => exercise.muscles.toLowerCase().contains(word),
          ),
        )
        .toList();
  }
}

class MealIdea {
  const MealIdea(this.name, this.ingredients, this.estimatedPesos, this.tags);
  final String name;
  final String ingredients;
  final int estimatedPesos;
  final List<String> tags;
}

class PinoyMeals {
  // Illustrative ingredient budgets, editable by the member; not live prices.
  static const meals = [
    MealIdea('Egg, rice and banana', '2 eggs, 1 serving rice, 1 banana', 45, [
      'egg',
    ]),
    MealIdea('Tokwa and pechay bowl', 'Tokwa, pechay, rice, garlic', 50, [
      'soy',
      'plant',
    ]),
    MealIdea(
      'Chicken tinola',
      'Chicken, sayote, malunggay, ginger, rice',
      75,
      [],
    ),
    MealIdea('Ginisang monggo', 'Monggo, malunggay, tomato, rice', 40, [
      'plant',
    ]),
    MealIdea(
      'Sardines with vegetables',
      'Sardines, tomato, cabbage, rice',
      55,
      ['fish'],
    ),
    MealIdea(
      'Oatmeal and banana',
      'Oats, banana, water, optional cinnamon',
      30,
      ['plant'],
    ),
  ];
  static List<MealIdea> forBudget(
    int budget,
    Set<String> excluded, {
    bool plantOnly = false,
  }) => meals
      .where(
        (m) =>
            m.estimatedPesos <= budget &&
            !m.tags.any(excluded.contains) &&
            (!plantOnly || m.tags.contains('plant')),
      )
      .toList();
}
