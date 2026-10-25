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
  static List<PlanExercise> forProfile({
    required String goal,
    required String environment,
  }) {
    if (environment == 'Home (no equipment)') {
      return const [
        PlanExercise(
          name: 'Push Up',
          detail: '3 sets • 10-12 reps • 45s',
          repsLabel: '10-12 reps',
          muscles: 'Chest, shoulders, triceps',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=300&q=80',
        ),
        PlanExercise(
          name: 'Bodyweight Squat',
          detail: '3 sets • 12-15 reps • 45s',
          repsLabel: '12-15 reps',
          muscles: 'Quads, glutes, core',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=300&q=80',
        ),
        PlanExercise(
          name: 'Plank Hold',
          detail: '3 sets • 45 seconds • 30s',
          repsLabel: '45s hold',
          muscles: 'Core, abs, shoulders',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=300&q=80',
        ),
      ];
    }

    return const [
      PlanExercise(
        name: 'Push Up',
        detail: '3 sets • 10-12 reps • 45s',
        repsLabel: '10-12 reps',
        muscles: 'Chest, shoulders, triceps',
        equipment: 'No Equipment',
        imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=300&q=80',
      ),
      PlanExercise(
        name: 'Dumbbell Row',
        detail: '3 sets • 10-12 reps • 45s',
        repsLabel: '10-12 reps',
        muscles: 'Back, biceps',
        equipment: 'Dumbbells',
        imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=300&q=80',
      ),
      PlanExercise(
        name: 'Shoulder Press',
        detail: '3 sets • 10 reps • 45s',
        repsLabel: '10 reps',
        muscles: 'Shoulders, triceps',
        equipment: 'Dumbbells',
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=300&q=80',
      ),
    ];
  }
}
