import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';

class AiWorkoutService {
  Future<({List<PlanExercise> plan, String reason})> generate({
    String painArea = 'None',
  }) async {
    final state = AppState.instance;
    final response = await FirebaseFunctions.instance
        .httpsCallable(
          'generateWorkoutPlan',
          options: HttpsCallableOptions(timeout: const Duration(seconds: 35)),
        )
        .call({
          'request': state.workoutRequest,
          'focus': state.workoutFocus,
          'painArea': painArea,
          'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
        });
    final value = Map<String, dynamic>.from(response.data as Map);
    final raw = value['exercises'];
    if (raw is! List || raw.isEmpty || raw.length > 8) {
      throw const FormatException('Invalid workout response');
    }
    final noEquipment = RegExp(
      'no equipment|walang equipment',
      caseSensitive: false,
    ).hasMatch('${state.workoutFocus} ${state.workoutRequest}');
    final catalog = WorkoutPlan.catalog(
      noEquipment ? 'Home (no equipment)' : state.workoutEnvironment,
    );
    final result = <PlanExercise>[];
    for (final item in raw.whereType<Map>()) {
      final name = item['name'];
      final matching = catalog.where((e) => e.name == name);
      if (matching.isEmpty) throw const FormatException('Unknown exercise');
      final exercise = matching.first;
      final sets = (item['sets'] as num).toInt().clamp(1, 5);
      final reps = (item['reps'] as num).toInt().clamp(1, 30);
      final seconds = (item['seconds'] as num).toInt().clamp(15, 90);
      result.add(
        PlanExercise(
          name: exercise.name,
          detail: '$sets sets • $reps reps • ${seconds}s',
          repsLabel: '$reps reps',
          muscles: exercise.muscles,
          equipment: exercise.equipment,
          imageUrl: exercise.imageUrl,
        ),
      );
    }
    if (result.isEmpty) throw const FormatException('Empty workout response');
    return (
      plan: result,
      reason:
          value['reason']?.toString() ??
          'Plan based on your request and saved setup.',
    );
  }
}
