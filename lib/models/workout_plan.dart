class PlanExercise {
  final String name;
  final String detail;
  final String repsLabel;
  final String muscles;
  final String equipment;
  final String? imageUrl;

  const PlanExercise({
    required this.name,
    required this.detail,
    required this.repsLabel,
    required this.muscles,
    required this.equipment,
    this.imageUrl,
  });
}

class WorkoutPlan {
  static const _weightLossTitle = 'Full-Body Fat-Burning Circuit';
  static const _strengthTitle = 'Muscle-Building Strength';
  static const _enduranceTitle = 'Cardio Endurance Circuit';
  static const _generalTitle = 'Full-Body Fitness Circuit';

  static String titleForGoal(String goal) {
    final normalizedGoal = goal.toLowerCase();
    if (normalizedGoal.contains('weight loss') ||
        normalizedGoal.contains('fat loss')) {
      return _weightLossTitle;
    }
    if (normalizedGoal.contains('muscle') ||
        normalizedGoal.contains('strength') ||
        normalizedGoal.contains('build')) {
      return _strengthTitle;
    }
    if (normalizedGoal.contains('endurance') ||
        normalizedGoal.contains('cardio')) {
      return _enduranceTitle;
    }
    return _generalTitle;
  }

  static String focusForGoal(String goal) {
    final normalizedGoal = goal.toLowerCase();
    if (normalizedGoal.contains('weight loss') ||
        normalizedGoal.contains('fat loss')) {
      return 'Full-body conditioning';
    }
    if (normalizedGoal.contains('muscle') ||
        normalizedGoal.contains('strength') ||
        normalizedGoal.contains('build')) {
      return 'Progressive strength training';
    }
    if (normalizedGoal.contains('endurance') ||
        normalizedGoal.contains('cardio')) {
      return 'Cardiovascular endurance';
    }
    return 'Balanced full-body training';
  }

  static List<PlanExercise> forProfile({
    required String goal,
    required String environment,
    Map<String, dynamic>? savedOverrides,
  }) {
    final normalizedGoal = goal.toLowerCase();
    final normalizedEnvironment = environment.toLowerCase();
    final isOutdoor = normalizedEnvironment.contains('outdoor');
    final isHome = normalizedEnvironment.contains('home');

    late final List<PlanExercise> exercises;
    if (normalizedGoal.contains('weight loss') ||
        normalizedGoal.contains('fat loss')) {
      exercises = _conditioningPlan(isOutdoor: isOutdoor, isHome: isHome);
    } else if (normalizedGoal.contains('endurance') ||
        normalizedGoal.contains('cardio')) {
      exercises = _endurancePlan(isOutdoor: isOutdoor, isHome: isHome);
    } else if (normalizedGoal.contains('muscle') ||
        normalizedGoal.contains('strength') ||
        normalizedGoal.contains('build')) {
      exercises = _strengthPlan(isOutdoor: isOutdoor, isHome: isHome);
    } else {
      exercises = _generalFitnessPlan(isOutdoor: isOutdoor, isHome: isHome);
    }

    final rawOverrides = savedOverrides?['$goal|$environment'];
    if (rawOverrides is! Map) return exercises;

    final adjustedExercises = exercises.map((exercise) {
      final rawExerciseOverride = rawOverrides[exercise.name];
      if (rawExerciseOverride is! Map) return exercise;

      final sets = (rawExerciseOverride['sets'] as num?)?.toInt();
      final reps = (rawExerciseOverride['reps'] as num?)?.toInt();
      final duration = (rawExerciseOverride['duration'] as num?)?.toInt();
      return _applyExerciseValues(
        exercise,
        sets: sets,
        reps: reps,
        duration: duration,
      );
    }).toList();

    final customExercises = rawOverrides['customExercises'];
    if (customExercises is List) {
      for (final rawCustomExercise in customExercises.whereType<Map>()) {
        final custom = Map<String, dynamic>.from(rawCustomExercise);
        final name = custom['name'];
        if (name is! String || name.trim().isEmpty) continue;

        final exercise = _customExercise(
          name: name,
          environment: environment,
          sets: (custom['sets'] as num?)?.toInt() ?? 3,
          reps: (custom['reps'] as num?)?.toInt() ?? 10,
          duration: (custom['duration'] as num?)?.toInt() ?? 45,
        );
        final existingIndex = adjustedExercises.indexWhere(
          (existing) =>
              _normalizeExerciseName(existing.name) ==
              _normalizeExerciseName(exercise.name),
        );
        if (existingIndex == -1) {
          adjustedExercises.add(exercise);
        } else {
          adjustedExercises[existingIndex] = exercise;
        }
      }
    }

    return adjustedExercises;
  }

  static PlanExercise _applyExerciseValues(
    PlanExercise exercise, {
    int? sets,
    int? reps,
    int? duration,
  }) {
    final detailParts = exercise.detail.split(' • ');
    if (detailParts.length < 3) return exercise;
    final repsText = reps == null ? detailParts[1] : '$reps reps';
    final durationText = duration == null ? detailParts[2] : '${duration}s';
    return PlanExercise(
      name: exercise.name,
      detail:
          '${sets ?? _parseLeadingNumber(detailParts[0])} sets • $repsText • $durationText',
      repsLabel: reps == null ? exercise.repsLabel : '$reps reps',
      muscles: exercise.muscles,
      equipment: exercise.equipment,
      imageUrl: exercise.imageUrl,
    );
  }

  static PlanExercise _customExercise({
    required String name,
    required String environment,
    required int sets,
    required int reps,
    required int duration,
  }) {
    final normalizedEnvironment = environment.toLowerCase();
    final imageUrl = name.toLowerCase().contains('squat')
        ? normalizedEnvironment.contains('outdoor')
              ? 'https://images.pexels.com/photos/4803865/pexels-photo-4803865.jpeg?auto=compress&w=900'
              : 'https://images.pexels.com/photos/8032778/pexels-photo-8032778.jpeg?auto=compress&w=900'
        : null;
    return PlanExercise(
      name: name,
      detail: '$sets sets • $reps reps • ${duration}s',
      repsLabel: '$reps reps',
      muscles: name.toLowerCase().contains('squat')
          ? 'Quads, glutes, hamstrings'
          : 'Full body',
      equipment:
          normalizedEnvironment.contains('home') ||
              normalizedEnvironment.contains('outdoor')
          ? 'No equipment'
          : 'Gym equipment',
      imageUrl: imageUrl,
    );
  }

  static String _normalizeExerciseName(String name) => name
      .toLowerCase()
      .replaceAll('bodyweight', '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '')
      .replaceAll(RegExp(r's$'), '');

  static int _parseLeadingNumber(String value) =>
      int.tryParse(RegExp(r'\d+').firstMatch(value)?.group(0) ?? '') ?? 3;

  static List<PlanExercise> _strengthPlan({
    required bool isOutdoor,
    required bool isHome,
  }) {
    if (isOutdoor || isHome) {
      final pushUpImage = isOutdoor
          ? 'https://images.pexels.com/photos/4803737/pexels-photo-4803737.jpeg?auto=compress&w=900'
          : 'https://images.pexels.com/photos/6975789/pexels-photo-6975789.jpeg?auto=compress&w=900';
      final squatImage = isOutdoor
          ? 'https://images.pexels.com/photos/4803865/pexels-photo-4803865.jpeg?auto=compress&w=900'
          : 'https://images.pexels.com/photos/8032778/pexels-photo-8032778.jpeg?auto=compress&w=900';
      final coreImage = isOutdoor
          ? 'https://images.pexels.com/photos/5149167/pexels-photo-5149167.jpeg?auto=compress&w=900'
          : 'https://images.pexels.com/photos/8173429/pexels-photo-8173429.jpeg?auto=compress&w=900';
      return [
        _exercise(
          name: 'Push Up',
          detail: '3 sets • 10-12 reps • 45s',
          reps: '10-12 reps',
          muscles: 'Chest, shoulders, triceps',
          equipment: 'No equipment',
          imageUrl: pushUpImage,
        ),
        _exercise(
          name: 'Bodyweight Squat',
          detail: '3 sets • 12-15 reps • 45s',
          reps: '12-15 reps',
          muscles: 'Quads, glutes, hamstrings',
          equipment: 'No equipment',
          imageUrl: squatImage,
        ),
        _exercise(
          name: 'Plank Hold',
          detail: '3 sets • 30-45 seconds • 30s',
          reps: '30-45 sec hold',
          muscles: 'Core, abs, shoulders',
          equipment: 'No equipment',
          imageUrl: coreImage,
        ),
      ];
    }

    return [
      _exercise(
        name: 'Push Up',
        detail: '3 sets • 10-12 reps • 45s',
        reps: '10-12 reps',
        muscles: 'Chest, shoulders, triceps',
        equipment: 'Bodyweight',
        imageUrl:
            'https://images.pexels.com/photos/4162491/pexels-photo-4162491.jpeg?auto=compress&w=900',
      ),
      _exercise(
        name: 'Dumbbell Row',
        detail: '3 sets • 10-12 reps • 45s',
        reps: '10-12 reps',
        muscles: 'Back, biceps',
        equipment: 'Dumbbells',
        imageUrl:
            'https://images.pexels.com/photos/38641891/pexels-photo-38641891/free-photo-of-woman-exercising-with-dumbbells-in-gym.jpeg?auto=compress&w=900',
      ),
      _exercise(
        name: 'Shoulder Press',
        detail: '3 sets • 10 reps • 45s',
        reps: '10 reps',
        muscles: 'Shoulders, triceps',
        equipment: 'Dumbbells',
        imageUrl:
            'https://images.pexels.com/photos/7289370/pexels-photo-7289370.jpeg?auto=compress&w=900',
      ),
    ];
  }

  static List<PlanExercise> _conditioningPlan({
    required bool isOutdoor,
    required bool isHome,
  }) {
    final imageSet = _environmentImages(isOutdoor: isOutdoor, isHome: isHome);
    return [
      _exercise(
        name: isHome || isOutdoor ? 'Squat Jumps' : 'Dumbbell Thruster',
        detail: '3 sets • 12 reps • 45s',
        reps: '12 reps',
        muscles: 'Legs, glutes, shoulders',
        equipment: isHome || isOutdoor ? 'No equipment' : 'Dumbbells',
        imageUrl: imageSet[0],
      ),
      _exercise(
        name: 'Mountain Climbers',
        detail: '3 sets • 30 seconds • 45s',
        reps: '30 sec',
        muscles: 'Core, shoulders, legs',
        equipment: 'No equipment',
        imageUrl: imageSet[1],
      ),
      _exercise(
        name: 'Reverse Lunges',
        detail: '3 sets • 12 reps per leg • 45s',
        reps: '12 reps per leg',
        muscles: 'Quads, glutes, hamstrings',
        equipment: isHome || isOutdoor ? 'No equipment' : 'Dumbbells',
        imageUrl: imageSet[2],
      ),
    ];
  }

  static List<PlanExercise> _endurancePlan({
    required bool isOutdoor,
    required bool isHome,
  }) {
    final imageSet = _environmentImages(isOutdoor: isOutdoor, isHome: isHome);
    return [
      _exercise(
        name: isHome
            ? 'Jog in Place'
            : isOutdoor
            ? 'Steady-Pace Jog'
            : 'Treadmill Jog',
        detail: '3 sets • 2 minutes • 60s',
        reps: '2 min',
        muscles: 'Heart, lungs, legs',
        equipment: isOutdoor || isHome ? 'No equipment' : 'Treadmill',
        imageUrl:
            'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=900&q=80',
      ),
      _exercise(
        name: 'Jumping Jacks',
        detail: '3 sets • 45 seconds • 45s',
        reps: '45 sec',
        muscles: 'Full body, cardiovascular system',
        equipment: 'No equipment',
        imageUrl: imageSet[0],
      ),
      _exercise(
        name: 'Mountain Climbers',
        detail: '3 sets • 30 seconds • 45s',
        reps: '30 sec',
        muscles: 'Core, shoulders, legs',
        equipment: 'No equipment',
        imageUrl: imageSet[1],
      ),
    ];
  }

  static List<PlanExercise> _generalFitnessPlan({
    required bool isOutdoor,
    required bool isHome,
  }) {
    final imageSet = _environmentImages(isOutdoor: isOutdoor, isHome: isHome);
    return [
      _exercise(
        name: 'Push Up',
        detail: '3 sets • 8-12 reps • 45s',
        reps: '8-12 reps',
        muscles: 'Chest, shoulders, triceps',
        equipment: 'No equipment',
        imageUrl: imageSet[0],
      ),
      _exercise(
        name: 'Bodyweight Squat',
        detail: '3 sets • 12 reps • 45s',
        reps: '12 reps',
        muscles: 'Quads, glutes, hamstrings',
        equipment: 'No equipment',
        imageUrl: imageSet[1],
      ),
      _exercise(
        name: 'Plank Shoulder Taps',
        detail: '3 sets • 10 taps per side • 30s',
        reps: '10 taps per side',
        muscles: 'Core, shoulders',
        equipment: 'No equipment',
        imageUrl: imageSet[2],
      ),
    ];
  }

  static List<String> _environmentImages({
    required bool isOutdoor,
    required bool isHome,
  }) {
    if (isOutdoor) {
      return const [
        'https://images.pexels.com/photos/4803737/pexels-photo-4803737.jpeg?auto=compress&w=900',
        'https://images.pexels.com/photos/4803865/pexels-photo-4803865.jpeg?auto=compress&w=900',
        'https://images.pexels.com/photos/5149167/pexels-photo-5149167.jpeg?auto=compress&w=900',
      ];
    }
    if (isHome) {
      return const [
        'https://images.pexels.com/photos/6975789/pexels-photo-6975789.jpeg?auto=compress&w=900',
        'https://images.pexels.com/photos/8173429/pexels-photo-8173429.jpeg?auto=compress&w=900',
        'https://images.pexels.com/photos/8032778/pexels-photo-8032778.jpeg?auto=compress&w=900',
      ];
    }
    return const [
      'https://images.pexels.com/photos/4162491/pexels-photo-4162491.jpeg?auto=compress&w=900',
      'https://images.pexels.com/photos/38641891/pexels-photo-38641891/free-photo-of-woman-exercising-with-dumbbells-in-gym.jpeg?auto=compress&w=900',
      'https://images.pexels.com/photos/7289370/pexels-photo-7289370.jpeg?auto=compress&w=900',
    ];
  }

  static PlanExercise _exercise({
    required String name,
    required String detail,
    required String reps,
    required String muscles,
    required String equipment,
    required String imageUrl,
  }) {
    return PlanExercise(
      name: name,
      detail: detail,
      repsLabel: reps,
      muscles: muscles,
      equipment: equipment,
      imageUrl: imageUrl,
    );
  }
}
