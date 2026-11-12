import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import '../widgets/workout_image.dart';
import 'warmup_screen.dart';
import 'rest_day_screen.dart';
import 'exercise_timer_screen.dart';
import '../models/fitness_features.dart';
import '../services/ai_workout_service.dart';
import '../services/offline_store.dart';
import '../widgets/exercise_actions.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  const WorkoutPlanDetailScreen({super.key, required this.exercises});

  final List<PlanExercise> exercises;

  static const Color _background = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  State<WorkoutPlanDetailScreen> createState() =>
      _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  late List<PlanExercise> exercises = [...widget.exercises];
  bool _preparing = false;
  static const _background = WorkoutPlanDetailScreen._background;
  static const _card = WorkoutPlanDetailScreen._card;
  static const _border = WorkoutPlanDetailScreen._border;
  static const _gold = WorkoutPlanDetailScreen._gold;
  static const _white = WorkoutPlanDetailScreen._white;
  static const _gray = WorkoutPlanDetailScreen._gray;

  Future<void> _swap(int index) async {
    final current = exercises[index];
    final replacement = await chooseExerciseSwap(
      context,
      current,
      AppState.instance.workoutEnvironment,
    );
    if (!mounted || replacement == null) return;
    setState(() => exercises[index] = replacement);
    AppState.instance.swapExercise(current.name, replacement.name);
    try {
      await OfflineStore.instance.saveProfile({
        'exerciseSwaps': AppState.instance.exerciseSwaps,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Swap applied for this session. Could not save the preference.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _startWithPainCheck() async {
    var area = 'None';
    var severity = 1;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('May masakit ba ngayon?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: area,
                  items: PainPolicy.areas
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) => update(() => area = v!),
                ),
                if (area != 'None') ...[
                  Text('Discomfort: $severity / 10'),
                  Slider(
                    value: severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => update(() => severity = v.round()),
                  ),
                  const Text(
                    'This app cannot assess an injury. For new, severe or worsening pain, stop and seek professional advice. Only continue activity you have been cleared to do.',
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(area == 'None' ? 'Start workout' : 'Review options'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || proceed != true) return;
    if (area == 'None') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WarmupScreen(exerciseList: exercises),
        ),
      );
      return;
    }
    if (severity >= 4 || area == 'Back / neck' || area == 'Other') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestDayScreen()),
      );
      return;
    }
    // Exclude exercises using the reported area. Never label replacements as
    // medically safe or use a generic warmup that may load the affected area.
    var adjusted = PainPolicy.filter(
      WorkoutPlan.catalog(AppState.instance.workoutEnvironment),
      area,
    ).take(3).toList();
    setState(() => _preparing = true);
    try {
      final result = await AiWorkoutService().generate(painArea: area);
      adjusted = PainPolicy.filter(result.plan, area);
    } catch (_) {
      /* Conservative on-device alternatives remain available. */
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
    if (!mounted) return;
    if (adjusted.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestDayScreen()),
      );
      return;
    }
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review adjusted session'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercises loading $area were excluded. These suggestions are not injury treatment or medical clearance. Stop immediately if discomfort increases.',
              ),
              const SizedBox(height: 10),
              for (final e in adjusted) Text('• ${e.name}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Rest instead'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I am cleared for this activity'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => accepted == true
            ? ExerciseTimerScreen(
                exerciseList: adjusted,
                totalWorkoutMinutes: 10,
              )
            : const RestDayScreen(),
      ),
    );
  }

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
                      onSwap: () => _swap(index),
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
                  onPressed: exercises.isEmpty || _preparing
                      ? null
                      : _startWithPainCheck,
                  icon: const Icon(Icons.play_arrow_rounded, size: 25),
                  label: Text(
                    _preparing ? 'REVIEWING OPTIONS…' : 'START WORKOUT',
                    style: const TextStyle(
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
                exerciseName: exercise?.name,
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
  const _ExerciseCard({
    required this.number,
    required this.exercise,
    required this.onSwap,
  });

  final int number;
  final PlanExercise exercise;
  final VoidCallback onSwap;

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
                    exerciseName: exercise.name,
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
          Column(
            children: [
              IconButton(
                tooltip: 'Palitan',
                onPressed: onSwap,
                icon: const Icon(
                  Icons.swap_horiz,
                  color: WorkoutPlanDetailScreen._gold,
                ),
              ),
              IconButton(
                tooltip: 'Exercise form guide',
                onPressed: () => showExerciseForm(context, exercise),
                icon: const Icon(Icons.info_outline, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
