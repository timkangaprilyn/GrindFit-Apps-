/// Start and finish position photos for exercises, bundled in the app so
/// they also show offline.
///
/// Source: Free Exercise DB (github.com/yuhonas/free-exercise-db), released
/// into the public domain under the Unlicense. Some photos are the closest
/// available variation (noted below).
class ExerciseImages {
  const ExerciseImages._();

  static const Map<String, String> _photoByName = {
    'push up': 'pushups',
    'bodyweight squat': 'bodyweight_squat',
    'plank hold': 'plank',
    'mountain climbers': 'mountain_climbers',
    // Same body position as a wall push up, using a box instead of a wall.
    'wall push up': 'incline_push_up',
    'triceps extension': 'standing_dumbbell_triceps_extension',
    // Shown with dumbbells; the movement is the same without them.
    'standing calf raise': 'standing_dumbbell_calf_raise',
    'shoulder press': 'dumbbell_shoulder_press',
    // Shown with dumbbells; the movement is the same without them.
    'reverse lunges': 'dumbbell_rear_lunge',
    // Shown lying on a bench with dumbbells.
    'prone reverse fly': 'lying_rear_delt_raise',
    'glute bridge': 'butt_lift_bridge',
    'dumbbell row': 'one_arm_dumbbell_row',
    'dumbbell curl': 'dumbbell_bicep_curl',
    'dead bug': 'dead_bug',
    'mobility flow': 'worlds_greatest_stretch',

    // Weekly training program library.
    'incline push up': 'incline_push_up',
    'wide push up': 'push_up_wide',
    'decline push up': 'push_ups_with_feet_elevated',
    'diamond push up': 'push_ups_close_triceps_position',
    'dumbbell floor press': 'dumbbell_floor_press',
    'dumbbell bench press': 'dumbbell_bench_press',
    'barbell bench press': 'barbell_bench_press_medium_grip',
    'machine chest fly': 'butterfly',
    'chair dip': 'bench_dips',
    'pull up': 'pullups',
    'chin up': 'chin_up',
    'inverted row': 'inverted_row',
    'lat pulldown': 'wide_grip_lat_pulldown',
    'seated cable row': 'seated_cable_rows',
    'band pull-apart': 'band_pull_apart',
    'lateral raise': 'side_lateral_raise',
    'machine shoulder press': 'machine_shoulder_military_press',
    'band overhead press': 'shoulder_press_with_bands',
    'hammer curl': 'hammer_curls',
    'cable curl': 'standing_biceps_cable_curl',
    'cable triceps pushdown': 'triceps_pushdown',
    'goblet squat': 'goblet_squat',
    'split squat': 'split_squats',
    'barbell back squat': 'barbell_full_squat',
    'band squat': 'squats_with_bands',
    'squat jumps': 'freehand_jump_squat',
    'leg press': 'leg_press',
    'leg curl machine': 'lying_leg_curls',
    'dumbbell romanian deadlift': 'stiff_legged_dumbbell_deadlift',
    // Shown with a barbell; same hip thrust position.
    'dumbbell hip thrust': 'barbell_hip_thrust',
    'hip thrust': 'barbell_hip_thrust',
    'single-leg glute bridge': 'single_leg_glute_bridge',
    // Shown with dumbbells; the movement is the same without them.
    'step up': 'dumbbell_step_ups',
    'dumbbell calf raise': 'standing_dumbbell_calf_raise',
    'band lateral walk': 'monster_walk',
    'side plank': 'side_bridge',
    'russian twist': 'russian_twist',
    'bicycle crunch': 'air_bike',
    'superman hold': 'superman',
    // Closest match: legs straight instead of bent.
    'hanging knee raise': 'hanging_leg_raise',
    // Closest match: a star jump uses the same open-close motion.
    'jumping jacks': 'star_jump',
    'jump rope': 'rope_jumping',
    'easy jump rope': 'rope_jumping',
    'skater hops': 'lateral_bound',
    'stationary bike': 'bicycling_stationary',
    'rowing machine sprint': 'rowing_stationary',
    'treadmill jog': 'jogging_treadmill',
  };

  /// Asset paths for the start and finish positions, or an empty list when
  /// no photo is bundled for this exercise.
  static List<String> forName(String? name) {
    final photo = _photoByName[name?.trim().toLowerCase()];
    if (photo == null) return const [];
    return [
      'assets/exercises/${photo}_0.jpg',
      'assets/exercises/${photo}_1.jpg',
    ];
  }
}
