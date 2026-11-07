import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import '../widgets/workout_image.dart';
import 'warmup_screen.dart';

class WorkoutPlanDetailScreen extends StatelessWidget {
  const WorkoutPlanDetailScreen({super.key, required this.exercises});

  final List<PlanExercise> exercises;

  static const Color _background = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text(
          'Workout Preview',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _WorkoutHero(
                    exercise: exercises.isEmpty ? null : exercises.first,
                    goal: state.fitnessGoal,
                    environment: state.workoutEnvironment,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PlanStat(
                          icon: Icons.timer_outlined,
                          label: 'DURATION',
                          value: state.sessionDuration,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PlanStat(
                          icon: Icons.calendar_month_rounded,
                          label: 'SCHEDULE',
                          value: '${state.workoutDays.length} days/week',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PlanStat(
                          icon: Icons.fitness_center_rounded,
                          label: 'EXERCISES',
                          value: '${exercises.length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S SESSION",
                              style: TextStyle(
                                color: _gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Your workout',
                              style: TextStyle(
                                color: _white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${exercises.length} exercises',
                        style: const TextStyle(
                          color: _gray,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < exercises.length; index++) ...[
                    _ExerciseCard(
                      number: index + 1,
                      exercise: exercises[index],
                    ),
                    if (index != exercises.length - 1)
                      const SizedBox(height: 10),
                  ],
                  if (exercises.isEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'No exercises are available for this plan yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: _gray),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: _background,
                    disabledBackgroundColor: _border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: exercises.isEmpty
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WarmupScreen(exerciseList: exercises),
                          ),
                        ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 25),
                  label: const Text(
                    'START WORKOUT',
                    style: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({
    required this.exercise,
    required this.goal,
    required this.environment,
  });

  final PlanExercise? exercise;
  final String goal;
  final String environment;

  @override
  Widget build(BuildContext context) {
    final imageUrl = exercise?.imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: WorkoutPlanDetailScreen._card,
          border: Border.all(color: WorkoutPlanDetailScreen._border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 170,
              child: WorkoutImage(
                imageUrl: imageUrl ?? '',
                backgroundColor: WorkoutPlanDetailScreen._background,
                iconColor: WorkoutPlanDetailScreen._gold,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    environment.toUpperCase(),
                    style: const TextStyle(
                      color: WorkoutPlanDetailScreen._gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    goal,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WorkoutPlanDetailScreen._white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanStat extends StatelessWidget {
  const _PlanStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: WorkoutPlanDetailScreen._card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: WorkoutPlanDetailScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: WorkoutPlanDetailScreen._gold, size: 15),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WorkoutPlanDetailScreen._gray,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: WorkoutPlanDetailScreen._white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.number, required this.exercise});

  final int number;
  final PlanExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: WorkoutPlanDetailScreen._card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WorkoutPlanDetailScreen._border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WorkoutImage(
                    imageUrl: exercise.imageUrl ?? '',
                    backgroundColor: WorkoutPlanDetailScreen._background,
                    iconColor: WorkoutPlanDetailScreen._gold,
                    iconSize: 30,
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: WorkoutPlanDetailScreen._gold,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$number',
                        style: const TextStyle(
                          color: WorkoutPlanDetailScreen._background,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WorkoutPlanDetailScreen._white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  exercise.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WorkoutPlanDetailScreen._gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${exercise.muscles} • ${exercise.equipment}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WorkoutPlanDetailScreen._gray,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: WorkoutPlanDetailScreen._gray,
            size: 20,
          ),
        ],
      ),
    );
  }
}
