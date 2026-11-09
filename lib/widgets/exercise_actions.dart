import '../theme/grindfit_theme.dart';

import 'package:flutter/material.dart';

import '../models/fitness_features.dart';
import '../models/workout_plan.dart';

void showExerciseForm(BuildContext context, PlanExercise exercise) {
  final guide = FormGuide.forExercise(exercise.name);
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(exercise.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < guide.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text('${i + 1}. ${guide.steps[i]}'),
              ),
            Text(
              'Common mistake: ${guide.mistake}',
              style: const TextStyle(color: GrindFitTheme.gold),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<PlanExercise?> chooseExerciseSwap(
  BuildContext context,
  PlanExercise exercise,
  String environment,
) async {
  final options = WorkoutPlan.alternativesFor(
    exercise,
    environment: environment,
  );
  return showModalBottomSheet<PlanExercise>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .6,
        child: ListView(
          children: [
            const ListTile(
              title: Text('Palitan ang exercise'),
              subtitle: Text(
                'Same muscle focus. Choose equipment available to you.',
              ),
            ),
            if (options.isEmpty)
              const ListTile(
                title: Text('No matching alternatives available.'),
              ),
            for (final option in options)
              ListTile(
                title: Text(option.name),
                subtitle: Text('${option.muscles} • ${option.equipment}'),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    ),
  );
}
