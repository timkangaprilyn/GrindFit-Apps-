import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/exercise_images.dart';
import 'package:flutter_application_1/models/workout_plan.dart';

void main() {
  test('catalog exercises map to bundled start and finish photos', () {
    final names = <String>{
      for (final environment in ['Gym', 'Home (no equipment)', 'Outdoor'])
        ...WorkoutPlan.catalog(environment).map((e) => e.name),
    };
    final withPhotos = names.where((n) => ExerciseImages.forName(n).isNotEmpty);
    expect(withPhotos, isNotEmpty);
    for (final name in withPhotos) {
      final paths = ExerciseImages.forName(name);
      expect(paths, hasLength(2), reason: name);
      for (final path in paths) {
        expect(File(path).existsSync(), isTrue, reason: '$name → $path');
      }
    }
  });

  test('lookup ignores case and spacing, and unknown names have no photos', () {
    expect(ExerciseImages.forName('  push UP '), hasLength(2));
    expect(ExerciseImages.forName('Plank Shoulder Taps'), isEmpty);
    expect(ExerciseImages.forName('Dumbbell Floor Press'), hasLength(2));
    expect(ExerciseImages.forName(null), isEmpty);
  });
}
