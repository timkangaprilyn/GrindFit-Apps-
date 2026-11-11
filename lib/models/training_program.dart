import 'workout_plan.dart';

/// Equipment a member can own. Stored on the profile as `equipment: [ids]`.
class Gear {
  Gear._();
  static const dumbbells = 'dumbbells';
  static const band = 'band';
  static const pullUpBar = 'pullup_bar';
  static const bench = 'bench';
  static const jumpRope = 'jump_rope';
  static const gym = 'gym';

  /// Choices shown to members, in display order.
  static const options = <(String, String)>[
    (dumbbells, 'Dumbbells'),
    (band, 'Resistance band'),
    (pullUpBar, 'Pull-up bar'),
    (bench, 'Bench'),
    (jumpRope, 'Jump rope'),
    (gym, 'Full gym'),
  ];

  static String label(String id) =>
      options.where((o) => o.$1 == id).firstOrNull?.$2 ?? id;

  /// Keeps only known ids.
  static Set<String> clean(Iterable<Object?> ids) => ids
      .whereType<String>()
      .where((id) => options.any((o) => o.$1 == id))
      .toSet();

  /// The gym always has everything; home and outdoor use what the member owns.
  static Set<String> effective(String environment, Set<String> owned) =>
      environment.toLowerCase().contains('gym') ? {gym} : owned;

  static bool has(Set<String> owned, String need) =>
      owned.contains(gym) || owned.contains(need);

  static String describe(Set<String> owned) {
    if (owned.contains(gym)) return 'Full gym';
    if (owned.isEmpty) return 'No equipment (bodyweight)';
    return options
        .where((o) => owned.contains(o.$1))
        .map((o) => o.$2)
        .join(', ');
  }
}

/// One movement in the library. [slots] say which part of a session it can
/// fill; [needs] lists equipment that must all be available.
class LibraryExercise {
  const LibraryExercise(
    this.name,
    this.slots,
    this.muscles, {
    this.needs = const {},
    this.loaded = false,
    this.timed = false,
    this.perSide = false,
    this.baseReps = 10,
    this.baseSeconds = 30,
    this.imageUrl,
  });

  final String name;
  final Set<String> slots;
  final String muscles;
  final Set<String> needs;

  /// Uses external load (weights, machine), preferred for strength goals.
  final bool loaded;
  final bool timed;
  final bool perSide;
  final int baseReps;

  /// Seconds for timed moves (steady cardio uses minutes worth of seconds).
  final int baseSeconds;
  final String? imageUrl;

  bool availableWith(Set<String> owned) =>
      needs.every((n) => Gear.has(owned, n));

  String get equipmentLabel => needs.isEmpty
      ? 'No equipment'
      : needs.contains(Gear.gym)
      ? 'Gym equipment'
      : needs.map(Gear.label).join(' + ');
}

/// A day in the weekly rotation, e.g. "Push Day" with its slots in order.
class DayTemplate {
  const DayTemplate(this.name, this.slots);
  final String name;
  final List<String> slots;
}

/// A concrete, dated workout produced by [TrainingProgram.sessionOn].
class ProgramSession {
  const ProgramSession({
    required this.date,
    required this.dayName,
    required this.weekNumber,
    required this.totalWeeks,
    required this.isLighterWeek,
    required this.exercises,
    this.isToday = true,
  });

  final DateTime date;
  final String dayName;

  /// 1-based week of the program.
  final int weekNumber;
  final int totalWeeks;
  final bool isLighterWeek;
  final List<PlanExercise> exercises;

  /// False when today is a rest day and this is the next scheduled session.
  final bool isToday;

  String get weekLabel => 'Week $weekNumber of $totalWeeks';
}

enum _Goal { strength, loss, endurance, general }

class TrainingProgram {
  TrainingProgram._();

  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Focus choices on the Workouts tab. [programFocus] follows the schedule.
  static const programFocus = 'Program';
  static const fullBodyFocus = 'Full Body Workout';

  static _Goal _goalOf(String goal) {
    final g = goal.toLowerCase();
    if (g.contains('weight loss') ||
        g.contains('fat loss') ||
        g.contains('lose')) {
      return _Goal.loss;
    }
    if (g.contains('endurance') || g.contains('cardio')) return _Goal.endurance;
    if (g.contains('muscle') || g.contains('strength') || g.contains('build')) {
      return _Goal.strength;
    }
    return _Goal.general;
  }

  // ---------------------------------------------------------------------
  // Exercise library
  // ---------------------------------------------------------------------
  static const library = <LibraryExercise>[
    // Chest
    LibraryExercise(
      'Push Up',
      {'chest'},
      'Chest, shoulders, triceps',
      baseReps: 10,
      imageUrl: 'https://images.pexels.com/photos/6975789/pexels-photo-6975789.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Incline Push Up',
      {'chest'},
      'Chest, shoulders, triceps',
      baseReps: 12,
    ),
    LibraryExercise(
      'Wide Push Up',
      {'chest'},
      'Chest, shoulders',
      baseReps: 10,
    ),
    LibraryExercise(
      'Decline Push Up',
      {'chest', 'shoulders'},
      'Upper chest, shoulders',
      baseReps: 8,
    ),
    LibraryExercise(
      'Dumbbell Floor Press',
      {'chest'},
      'Chest, triceps',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Dumbbell Bench Press',
      {'chest'},
      'Chest, shoulders, triceps',
      needs: {Gear.dumbbells, Gear.bench},
      loaded: true,
    ),
    LibraryExercise(
      'Band Chest Press',
      {'chest'},
      'Chest, triceps',
      needs: {Gear.band},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Barbell Bench Press',
      {'chest'},
      'Chest, shoulders, triceps',
      needs: {Gear.gym},
      loaded: true,
      baseReps: 8,
      imageUrl: 'https://images.pexels.com/photos/4162491/pexels-photo-4162491.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Machine Chest Fly',
      {'chest'},
      'Chest',
      needs: {Gear.gym},
      loaded: true,
      baseReps: 12,
    ),
    // Back
    LibraryExercise(
      'Superman Hold',
      {'back'},
      'Lower back, glutes',
      timed: true,
      baseSeconds: 25,
    ),
    LibraryExercise(
      'Prone Reverse Fly',
      {'back', 'shoulders'},
      'Upper back, rear shoulders',
      baseReps: 12,
    ),
    LibraryExercise(
      'Prone Y-T Raise',
      {'back'},
      'Upper back, shoulders',
      baseReps: 10,
    ),
    LibraryExercise(
      'Dumbbell Row',
      {'back'},
      'Back, biceps',
      needs: {Gear.dumbbells},
      loaded: true,
      perSide: true,
      imageUrl: 'https://images.pexels.com/photos/38641891/pexels-photo-38641891/free-photo-of-woman-exercising-with-dumbbells-in-gym.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Band Row',
      {'back'},
      'Back, biceps',
      needs: {Gear.band},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Band Pull-Apart',
      {'back', 'shoulders'},
      'Upper back, rear shoulders',
      needs: {Gear.band},
      loaded: true,
      baseReps: 15,
    ),
    LibraryExercise(
      'Pull Up',
      {'back', 'biceps'},
      'Lats, biceps',
      needs: {Gear.pullUpBar},
      loaded: true,
      baseReps: 5,
    ),
    LibraryExercise(
      'Inverted Row',
      {'back'},
      'Back, biceps',
      needs: {Gear.pullUpBar},
      loaded: true,
      baseReps: 8,
    ),
    LibraryExercise(
      'Lat Pulldown',
      {'back'},
      'Lats, biceps',
      needs: {Gear.gym},
      loaded: true,
    ),
    LibraryExercise(
      'Seated Cable Row',
      {'back'},
      'Mid back, biceps',
      needs: {Gear.gym},
      loaded: true,
    ),
    // Shoulders
    LibraryExercise(
      'Pike Push Up',
      {'shoulders'},
      'Shoulders, triceps',
      baseReps: 8,
    ),
    LibraryExercise(
      'Shoulder Press',
      {'shoulders'},
      'Shoulders, triceps',
      needs: {Gear.dumbbells},
      loaded: true,
      imageUrl: 'https://images.pexels.com/photos/7289370/pexels-photo-7289370.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Lateral Raise',
      {'shoulders'},
      'Side shoulders',
      needs: {Gear.dumbbells},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Band Overhead Press',
      {'shoulders'},
      'Shoulders, triceps',
      needs: {Gear.band},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Machine Shoulder Press',
      {'shoulders'},
      'Shoulders, triceps',
      needs: {Gear.gym},
      loaded: true,
    ),
    // Arms
    LibraryExercise(
      'Diamond Push Up',
      {'triceps'},
      'Triceps, chest',
      baseReps: 8,
    ),
    LibraryExercise(
      'Chair Dip',
      {'triceps'},
      'Triceps, shoulders',
      baseReps: 10,
    ),
    LibraryExercise(
      'Triceps Extension',
      {'triceps'},
      'Triceps',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Band Triceps Pushdown',
      {'triceps'},
      'Triceps',
      needs: {Gear.band},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Cable Triceps Pushdown',
      {'triceps'},
      'Triceps',
      needs: {Gear.gym},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Towel Curl Hold',
      {'biceps'},
      'Biceps, forearms',
      timed: true,
      baseSeconds: 20,
    ),
    LibraryExercise(
      'Dumbbell Curl',
      {'biceps'},
      'Biceps',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Hammer Curl',
      {'biceps'},
      'Biceps, forearms',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Band Curl',
      {'biceps'},
      'Biceps',
      needs: {Gear.band},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Chin Up',
      {'biceps', 'back'},
      'Biceps, lats',
      needs: {Gear.pullUpBar},
      loaded: true,
      baseReps: 5,
    ),
    LibraryExercise(
      'Cable Curl',
      {'biceps'},
      'Biceps',
      needs: {Gear.gym},
      loaded: true,
    ),
    // Legs
    LibraryExercise(
      'Bodyweight Squat',
      {'quads'},
      'Quads, glutes, hamstrings',
      baseReps: 15,
      imageUrl: 'https://images.pexels.com/photos/8032778/pexels-photo-8032778.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Reverse Lunges',
      {'quads', 'glutes'},
      'Quads, glutes, hamstrings',
      perSide: true,
    ),
    LibraryExercise('Split Squat', {'quads'}, 'Quads, glutes', perSide: true),
    LibraryExercise(
      'Step Up',
      {'quads', 'glutes'},
      'Quads, glutes',
      perSide: true,
    ),
    LibraryExercise(
      'Wall Sit',
      {'quads'},
      'Quads',
      timed: true,
      baseSeconds: 30,
    ),
    LibraryExercise(
      'Goblet Squat',
      {'quads'},
      'Quads, glutes',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Band Squat',
      {'quads'},
      'Quads, glutes',
      needs: {Gear.band},
      loaded: true,
      baseReps: 15,
    ),
    LibraryExercise(
      'Leg Press',
      {'quads'},
      'Quads, glutes',
      needs: {Gear.gym},
      loaded: true,
    ),
    LibraryExercise(
      'Barbell Back Squat',
      {'quads'},
      'Quads, glutes, core',
      needs: {Gear.gym},
      loaded: true,
      baseReps: 8,
    ),
    LibraryExercise(
      'Bodyweight Good Morning',
      {'hamstrings'},
      'Hamstrings, lower back',
      baseReps: 15,
    ),
    LibraryExercise(
      'Single-Leg Glute Bridge',
      {'hamstrings', 'glutes'},
      'Hamstrings, glutes',
      perSide: true,
    ),
    LibraryExercise(
      'Dumbbell Romanian Deadlift',
      {'hamstrings'},
      'Hamstrings, glutes',
      needs: {Gear.dumbbells},
      loaded: true,
    ),
    LibraryExercise(
      'Leg Curl Machine',
      {'hamstrings'},
      'Hamstrings',
      needs: {Gear.gym},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Glute Bridge',
      {'glutes'},
      'Glutes, hamstrings',
      baseReps: 15,
    ),
    LibraryExercise(
      'Band Lateral Walk',
      {'glutes'},
      'Side glutes',
      needs: {Gear.band},
      loaded: true,
      perSide: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Hip Thrust',
      {'glutes'},
      'Glutes',
      needs: {Gear.bench},
      loaded: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Dumbbell Hip Thrust',
      {'glutes'},
      'Glutes, hamstrings',
      needs: {Gear.dumbbells, Gear.bench},
      loaded: true,
    ),
    LibraryExercise('Standing Calf Raise', {'calves'}, 'Calves', baseReps: 15),
    LibraryExercise(
      'Dumbbell Calf Raise',
      {'calves'},
      'Calves',
      needs: {Gear.dumbbells},
      loaded: true,
      baseReps: 15,
    ),
    // Core
    LibraryExercise(
      'Plank Hold',
      {'core'},
      'Core, abs, shoulders',
      timed: true,
      baseSeconds: 30,
      imageUrl: 'https://images.pexels.com/photos/8173429/pexels-photo-8173429.jpeg?auto=compress&w=900',
    ),
    LibraryExercise(
      'Dead Bug',
      {'core'},
      'Core, abs',
      perSide: true,
      baseReps: 8,
    ),
    LibraryExercise(
      'Plank Shoulder Taps',
      {'core'},
      'Core, shoulders',
      perSide: true,
      baseReps: 10,
    ),
    LibraryExercise(
      'Bicycle Crunch',
      {'core'},
      'Abs, obliques',
      perSide: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Side Plank',
      {'core'},
      'Obliques, core',
      timed: true,
      perSide: true,
      baseSeconds: 20,
    ),
    LibraryExercise(
      'Russian Twist',
      {'core'},
      'Obliques',
      perSide: true,
      baseReps: 12,
    ),
    LibraryExercise(
      'Hanging Knee Raise',
      {'core'},
      'Lower abs, grip',
      needs: {Gear.pullUpBar},
      loaded: true,
    ),
    // Cardio intervals
    LibraryExercise(
      'Jumping Jacks',
      {'cardio'},
      'Full body, cardio',
      timed: true,
      baseSeconds: 30,
    ),
    LibraryExercise(
      'Mountain Climbers',
      {'cardio', 'core'},
      'Core, shoulders, legs, cardio',
      timed: true,
      baseSeconds: 25,
    ),
    LibraryExercise(
      'High Knees',
      {'cardio'},
      'Legs, cardio',
      timed: true,
      baseSeconds: 25,
    ),
    LibraryExercise('Burpees', {'cardio'}, 'Full body, cardio', baseReps: 8),
    LibraryExercise(
      'Squat Jumps',
      {'cardio', 'quads'},
      'Legs, glutes, cardio',
      baseReps: 10,
    ),
    LibraryExercise(
      'Skater Hops',
      {'cardio'},
      'Legs, glutes, cardio',
      timed: true,
      baseSeconds: 25,
    ),
    LibraryExercise(
      'Jump Rope',
      {'cardio'},
      'Calves, cardio',
      needs: {Gear.jumpRope},
      timed: true,
      baseSeconds: 45,
    ),
    LibraryExercise(
      'Rowing Machine Sprint',
      {'cardio'},
      'Full body, cardio',
      needs: {Gear.gym},
      timed: true,
      baseSeconds: 40,
    ),
    // Steady cardio (seconds; shown as minutes)
    LibraryExercise(
      'Brisk Walk',
      {'steady'},
      'Heart, lungs, legs',
      timed: true,
      baseSeconds: 600,
    ),
    LibraryExercise(
      'Jog in Place',
      {'steady'},
      'Heart, lungs, legs',
      timed: true,
      baseSeconds: 300,
      imageUrl: 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=900&q=80',
    ),
    LibraryExercise(
      'Easy Jump Rope',
      {'steady'},
      'Heart, lungs, calves',
      needs: {Gear.jumpRope},
      timed: true,
      baseSeconds: 300,
    ),
    LibraryExercise(
      'Treadmill Jog',
      {'steady'},
      'Heart, lungs, legs',
      needs: {Gear.gym},
      timed: true,
      baseSeconds: 600,
    ),
    LibraryExercise(
      'Stationary Bike',
      {'steady'},
      'Heart, lungs, legs',
      needs: {Gear.gym},
      timed: true,
      baseSeconds: 600,
    ),
  ];

  static LibraryExercise? byName(String name) =>
      library.where((e) => e.name == name).firstOrNull;

  // ---------------------------------------------------------------------
  // Weekly rotation per goal
  // ---------------------------------------------------------------------
  static List<DayTemplate> templatesFor(String goal, int daysPerWeek) {
    switch (_goalOf(goal)) {
      case _Goal.strength:
        if (daysPerWeek <= 1) {
          return const [
            DayTemplate('Full Body Day', [
              'quads',
              'chest',
              'back',
              'shoulders',
              'core',
            ]),
          ];
        }
        if (daysPerWeek == 2) {
          return const [
            DayTemplate('Upper Body Day', [
              'chest',
              'back',
              'shoulders',
              'biceps',
              'triceps',
            ]),
            DayTemplate('Lower Body Day', [
              'quads',
              'hamstrings',
              'glutes',
              'calves',
              'core',
            ]),
          ];
        }
        return const [
          DayTemplate('Push Day', [
            'chest',
            'chest',
            'shoulders',
            'triceps',
            'core',
          ]),
          DayTemplate('Pull Day', [
            'back',
            'back',
            'biceps',
            'shoulders',
            'core',
          ]),
          DayTemplate('Leg Day', [
            'quads',
            'hamstrings',
            'glutes',
            'quads',
            'calves',
          ]),
        ];
      case _Goal.loss:
        return const [
          DayTemplate('Fat-Burn Circuit A', [
            'quads',
            'cardio',
            'chest',
            'core',
            'cardio',
          ]),
          DayTemplate('Fat-Burn Circuit B', [
            'glutes',
            'cardio',
            'back',
            'core',
            'cardio',
          ]),
          DayTemplate('Fat-Burn Circuit C', [
            'hamstrings',
            'cardio',
            'shoulders',
            'core',
            'cardio',
          ]),
        ];
      case _Goal.endurance:
        return const [
          DayTemplate('Interval Day', [
            'cardio',
            'cardio',
            'cardio',
            'core',
            'cardio',
          ]),
          DayTemplate('Steady Cardio Day', [
            'steady',
            'quads',
            'steady',
            'core',
            'calves',
          ]),
          DayTemplate('Strength-Endurance Day', [
            'quads',
            'chest',
            'back',
            'glutes',
            'core',
          ]),
        ];
      case _Goal.general:
        return const [
          DayTemplate('Full Body A', [
            'quads',
            'chest',
            'back',
            'core',
            'cardio',
          ]),
          DayTemplate('Full Body B', [
            'glutes',
            'shoulders',
            'back',
            'core',
            'cardio',
          ]),
          DayTemplate('Full Body C', [
            'hamstrings',
            'chest',
            'biceps',
            'core',
            'cardio',
          ]),
        ];
    }
  }

  /// Slots used when a member changes today's focus on the Workouts tab.
  static List<String>? focusSlots(String focus) => switch (focus) {
    fullBodyFocus => ['quads', 'chest', 'back', 'shoulders', 'core'],
    'Upper Body' => ['chest', 'back', 'shoulders', 'biceps', 'triceps'],
    'Lower Body' => ['quads', 'hamstrings', 'glutes', 'calves', 'core'],
    'Chest at Triceps' => ['chest', 'chest', 'triceps', 'triceps', 'core'],
    'Back at Biceps' => ['back', 'back', 'biceps', 'biceps', 'core'],
    'Shoulders' => ['shoulders', 'shoulders', 'shoulders', 'core'],
    'Legs at Glutes' => ['quads', 'glutes', 'hamstrings', 'glutes', 'calves'],
    'Core' => ['core', 'core', 'core', 'core'],
    'Cardio' => ['cardio', 'cardio', 'cardio', 'steady', 'core'],
    _ => null,
  };

  /// Number of exercises for a session length such as '45 min'.
  static int exerciseCount(String sessionDuration) {
    final minutes =
        int.tryParse(
          RegExp(r'\d+').firstMatch(sessionDuration)?.group(0) ?? '',
        ) ??
        45;
    if (minutes <= 20) return 3;
    if (minutes <= 30) return 4;
    if (minutes <= 45) return 5;
    return 6;
  }

  static List<String> _fitSlots(List<String> slots, int count, _Goal goal) {
    if (slots.length >= count) return slots.take(count).toList();
    final extra = goal == _Goal.strength ? 'core' : 'cardio';
    return [
      ...slots,
      for (var i = slots.length; i < count; i++) i.isEven ? extra : 'core',
    ];
  }

  // ---------------------------------------------------------------------
  // Choosing exercises and progressing them
  // ---------------------------------------------------------------------

  /// Picks one exercise per slot. Choices stay the same within a 4-week block
  /// (so progress is comparable) and rotate to new variations each block.
  static List<LibraryExercise> pick(
    List<String> slots, {
    required Set<String> owned,
    required String goal,
    int block = 0,
    int variant = 0,
  }) {
    final kind = _goalOf(goal);
    final used = <String>{};
    final picked = <LibraryExercise>[];
    for (var i = 0; i < slots.length; i++) {
      var candidates = library
          .where(
            (e) =>
                e.slots.contains(slots[i]) &&
                e.availableWith(owned) &&
                !used.contains(e.name),
          )
          .toList();
      // Strength days favour loaded moves, except core and cardio where
      // bodyweight variations give more variety.
      if (kind == _Goal.strength &&
          !const {'core', 'cardio', 'steady'}.contains(slots[i])) {
        final loaded = candidates.where((e) => e.loaded).toList();
        if (loaded.isNotEmpty) candidates = loaded;
      }
      if (candidates.isEmpty) continue;
      final choice = candidates[(block + i + variant) % candidates.length];
      used.add(choice.name);
      picked.add(choice);
    }
    return picked;
  }

  /// Sets, reps or time for a week of the program.
  /// Weeks 1–3 of each 4-week block build up; week 4 is lighter for recovery.
  /// Each new block starts a little harder than the last.
  static PlanExercise prescribe(
    LibraryExercise exercise, {
    required String goal,
    int weekIndex = 0,
  }) {
    final kind = _goalOf(goal);
    final block = weekIndex ~/ 4;
    final week = weekIndex % 4;
    final lighter = week == 3;

    var sets = switch (kind) {
      _Goal.endurance => 2,
      _ => 3,
    };
    var rest = switch (kind) {
      _Goal.strength => exercise.loaded ? 75 : 60,
      _Goal.general => 45,
      _ => 30,
    };
    if (week == 2) sets += 1;
    if (lighter) sets -= 1;
    if (block >= 2 && !lighter) sets += 1;
    sets = sets.clamp(2, 5);

    String amount;
    if (exercise.timed) {
      final steady = exercise.slots.contains('steady');
      final step = steady ? 60 : 5;
      var seconds =
          exercise.baseSeconds +
          step * (lighter ? -2 : week) +
          (steady ? 120 : 10) * block;
      seconds = seconds.clamp(steady ? 180 : 15, steady ? 2400 : 90);
      if (steady) {
        sets = lighter ? 1 : 2;
        rest = 60;
      }
      amount = seconds >= 120 && seconds % 60 == 0
          ? '${seconds ~/ 60} min'
          : '$seconds sec';
    } else {
      final base = switch (kind) {
        _Goal.strength => exercise.loaded ? 8 : exercise.baseReps,
        _Goal.loss => exercise.baseReps + 2,
        _Goal.endurance => exercise.baseReps + 5,
        _Goal.general => exercise.baseReps,
      };
      var reps = base + (lighter ? -2 : week) + block * 2;
      reps = reps.clamp(4, exercise.loaded && kind == _Goal.strength ? 12 : 25);
      amount = '$reps reps${exercise.perSide ? ' per side' : ''}';
    }
    return PlanExercise(
      name: exercise.name,
      detail: '$sets sets • $amount • ${rest}s',
      repsLabel: amount,
      muscles: exercise.muscles,
      equipment: exercise.equipmentLabel,
      imageUrl: exercise.imageUrl,
    );
  }

  // ---------------------------------------------------------------------
  // Calendar
  // ---------------------------------------------------------------------
  static List<String> orderedDays(List<String> days) {
    final keys =
        days
            .map(
              (d) => d.trim().length >= 3 ? d.trim().substring(0, 3) : d.trim(),
            )
            .map(
              (d) => d.isEmpty
                  ? d
                  : d[0].toUpperCase() + d.substring(1).toLowerCase(),
            )
            .where(weekdays.contains)
            .toSet()
            .toList()
          ..sort((a, b) => weekdays.indexOf(a).compareTo(weekdays.indexOf(b)));
    return keys.isEmpty ? const ['Mon', 'Wed', 'Fri'] : keys;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _monday(DateTime d) =>
      _day(d).subtract(Duration(days: d.weekday - 1));

  static int totalWeeks(int months) =>
      (months.clamp(1, 24) * 30.44 / 7).round();

  /// Program week (0-based) that [date] falls in, counted from the Monday of
  /// the week the program started.
  static int weekIndexOf(DateTime date, DateTime start) {
    final days = _monday(date).difference(_monday(start)).inDays;
    return days < 0 ? 0 : days ~/ 7;
  }

  /// The workout scheduled on [date], or null on a rest day.
  static ProgramSession? sessionOn(
    DateTime date, {
    required String goal,
    required List<String> days,
    required Set<String> owned,
    required String sessionDuration,
    required DateTime start,
    int months = 3,
  }) {
    final schedule = orderedDays(days);
    final index = schedule.indexOf(weekdays[date.weekday - 1]);
    if (index < 0) return null;
    final kind = _goalOf(goal);
    final week = weekIndexOf(date, start);
    final templates = templatesFor(goal, schedule.length);
    final counter = week * schedule.length + index;
    final templateIndex = counter % templates.length;
    final template = templates[templateIndex];
    final slots = _fitSlots(
      template.slots,
      exerciseCount(sessionDuration),
      kind,
    );
    final exercises = pick(
      slots,
      owned: owned,
      goal: goal,
      block: week ~/ 4,
      variant: templateIndex,
    ).map((e) => prescribe(e, goal: goal, weekIndex: week)).toList();
    return ProgramSession(
      date: _day(date),
      dayName: template.name,
      weekNumber: week + 1,
      totalWeeks: totalWeeks(months),
      isLighterWeek: week % 4 == 3,
      exercises: exercises,
    );
  }

  /// Today's workout, or the next scheduled one when today is a rest day.
  static ProgramSession upcoming(
    DateTime now, {
    required String goal,
    required List<String> days,
    required Set<String> owned,
    required String sessionDuration,
    required DateTime start,
    int months = 3,
  }) {
    for (var offset = 0; offset < 8; offset++) {
      final date = _day(now).add(Duration(days: offset));
      final session = sessionOn(
        date,
        goal: goal,
        days: days,
        owned: owned,
        sessionDuration: sessionDuration,
        start: start,
        months: months,
      );
      if (session != null) {
        return offset == 0
            ? session
            : ProgramSession(
                date: session.date,
                dayName: session.dayName,
                weekNumber: session.weekNumber,
                totalWeeks: session.totalWeeks,
                isLighterWeek: session.isLighterWeek,
                exercises: session.exercises,
                isToday: false,
              );
      }
    }
    // Unreachable: orderedDays never returns an empty schedule.
    throw StateError('No training days scheduled');
  }

  /// All sessions in the week containing [anyDay].
  static List<ProgramSession> week(
    DateTime anyDay, {
    required String goal,
    required List<String> days,
    required Set<String> owned,
    required String sessionDuration,
    required DateTime start,
    int months = 3,
  }) {
    final monday = _monday(anyDay);
    final sessions = <ProgramSession>[];
    for (var i = 0; i < 7; i++) {
      final session = sessionOn(
        monday.add(Duration(days: i)),
        goal: goal,
        days: days,
        owned: owned,
        sessionDuration: sessionDuration,
        start: start,
        months: months,
      );
      if (session != null) sessions.add(session);
    }
    return sessions;
  }

  /// A one-off session for a focus chosen on the Workouts tab.
  static List<PlanExercise>? focusSession(
    String focus, {
    required String goal,
    required Set<String> owned,
    required String sessionDuration,
    int weekIndex = 0,
  }) {
    final slots = focusSlots(focus);
    if (slots == null) return null;
    final fitted = _fitSlots(
      slots,
      exerciseCount(sessionDuration),
      _goalOf(goal),
    );
    return pick(
      fitted,
      owned: owned,
      goal: goal,
      block: weekIndex ~/ 4,
    ).map((e) => prescribe(e, goal: goal, weekIndex: weekIndex)).toList();
  }

  /// Exercises a member may add for today, grouped by body area. Groups that
  /// match the goal come first.
  static List<(String, List<LibraryExercise>)> addable({
    required String goal,
    required Set<String> owned,
    Set<String> exclude = const {},
  }) {
    const groups = <(String, Set<String>)>[
      ('Chest', {'chest'}),
      ('Back', {'back'}),
      ('Shoulders', {'shoulders'}),
      ('Arms', {'biceps', 'triceps'}),
      ('Legs', {'quads', 'hamstrings', 'calves'}),
      ('Glutes', {'glutes'}),
      ('Core', {'core'}),
      ('Cardio', {'cardio', 'steady'}),
    ];
    final priority = switch (_goalOf(goal)) {
      _Goal.strength => [
        'Chest',
        'Back',
        'Legs',
        'Shoulders',
        'Arms',
        'Glutes',
        'Core',
        'Cardio',
      ],
      _Goal.loss => [
        'Cardio',
        'Legs',
        'Glutes',
        'Core',
        'Chest',
        'Back',
        'Shoulders',
        'Arms',
      ],
      _Goal.endurance => [
        'Cardio',
        'Legs',
        'Core',
        'Glutes',
        'Back',
        'Chest',
        'Shoulders',
        'Arms',
      ],
      _Goal.general => [
        'Legs',
        'Chest',
        'Back',
        'Core',
        'Cardio',
        'Glutes',
        'Shoulders',
        'Arms',
      ],
    };
    final seen = <String>{...exclude};
    final result = <(String, List<LibraryExercise>)>[];
    for (final label in priority) {
      final slots = groups.firstWhere((g) => g.$1 == label).$2;
      final items = library
          .where(
            (e) =>
                e.availableWith(owned) &&
                e.slots.any(slots.contains) &&
                seen.add(e.name),
          )
          .toList();
      if (items.isNotEmpty) result.add((label, items));
    }
    return result;
  }
}
