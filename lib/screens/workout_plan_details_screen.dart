import 'package:flutter/material.dart';
import '../widgets/grindfit_logo.dart';
import '../models/app_state.dart';
import 'exercise_detail_screen.dart';
import 'warmup_screen.dart';

// Inline PlanExercise model para sa details screen
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

// Inline WorkoutPlan model upang maging tugma ang exercises
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

class WorkoutPlanDetailsScreen extends StatelessWidget {
  const WorkoutPlanDetailsScreen({super.key});

  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF0A0A0B);
  static const Color _card = Color(0xFF14161B);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  Widget _reveal(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: childWidget,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    final exercises = WorkoutPlan.forProfile(
      goal: state.fitnessGoal,
      environment: state.workoutEnvironment,
    );

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.16),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    children: [
                      _reveal(0, _buildSummaryCard(state.planHeaderSummary)),
                      const SizedBox(height: 24),
                      _reveal(1, _buildSectionTitle(exercises.length)),
                      const SizedBox(height: 14),
                      for (var i = 0; i < exercises.length; i++) ...[
                        _reveal(
                          i + 2,
                          _buildExerciseCard(context, i, exercises[i]),
                        ),
                        if (i != exercises.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
                _buildStartBar(context, exercises),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white,
                  size: 18,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/grindfit_logo_tight.png',
                  height: 46,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const GrindFitLogo(),
                ),
              ),
            ),
            const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.alphaBlend(_gold.withValues(alpha: 0.16), _card),
            _card,
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.38), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_goldLight, _gold],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR PLAN',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: _gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: _white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Your Exercises',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _white,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count exercises',
            style: const TextStyle(
              fontSize: 11.5,
              color: _goldBright,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumb(String? imageUrl) {
    const size = 76.0;
    Widget placeholder() => Container(
          width: size,
          height: size,
          color: const Color(0xFF1D2025),
          child: const Icon(
            Icons.fitness_center_rounded,
            color: _gold,
            size: 28,
          ),
        );

    if (imageUrl == null) return placeholder();

    return Image.network(
      imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder(),
      errorBuilder: (context, error, stackTrace) => placeholder(),
    );
  }

  Widget _buildExerciseCard(BuildContext context, int index, PlanExercise ex) {
    final bool noEquipment = ex.equipment.toLowerCase().contains('no equipment');

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border, width: 1.2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(
                exerciseName: ex.name,
                setsReps: ex.repsLabel,
                muscles: ex.muscles,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildThumb(ex.imageUrl),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: _card, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ex.detail,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _goldBright,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ex.muscles,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1D2025),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              noEquipment
                                  ? Icons.accessibility_new_rounded
                                  : Icons.fitness_center_rounded,
                              size: 12,
                              color: _gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              ex.equipment,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D2025),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.chevron_right, color: _gold, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartBar(BuildContext context, List<PlanExercise> exercises) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              color: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [_goldLight, _gold],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.28),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WarmupScreen(
                          exerciseList: exercises,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Start Workout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}