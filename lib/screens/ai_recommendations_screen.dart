import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import 'rest_day_screen.dart';
import '../widgets/workout_image.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  int _selectedTab = 0; // 0: Today, 1: This Week, 2: Next Week

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refreshForAppStateChanges);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refreshForAppStateChanges);
    super.dispose();
  }

  void _refreshForAppStateChanges() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final int currentDay = AppState.instance.currentDayIndex;

    // Consistent default goal across screens
    final String goal = AppState.instance.fitnessGoal.isNotEmpty
        ? AppState.instance.fitnessGoal
        : "Muscle Gain / Strength";
    final exercises = WorkoutPlan.forProfile(
      goal: goal,
      environment: AppState.instance.workoutEnvironment,
      savedOverrides: AppState.instance.workoutPlanOverrides,
    );

    // Alamin kung pwede pang mag-pop (kung binuksan ito mula sa ibang screen gaya ng notification)
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        // Mag-aadjust ang leading depende kung galing sa push navigation o tab
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'AI Workout Recommendations',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _border, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -140,
            right: -120,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withValues(alpha: 0.15),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Goal: $goal',
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${WorkoutPlan.titleForGoal(goal)} is tailored to your goal and workout setting.',
                          style: const TextStyle(
                            color: _gray,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Program Progress: Day $currentDay Active',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RestDayScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.self_improvement_rounded,
                                color: _gold,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'View Rest Day / Recovery Mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: _white,
                                ),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right, color: _gold),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 0 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: _selectedTab == 0 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 1 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: _selectedTab == 1 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 2 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 2 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Next Week',
                              style: TextStyle(
                                color: _selectedTab == 2 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Day $currentDay - Your Workout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final exercise in exercises) ...[
                    _buildExerciseCard(exercise),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(PlanExercise exercise) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: WorkoutImage(
                imageUrl: exercise.imageUrl ?? '',
                backgroundColor: _bg,
                iconColor: _gold,
                iconSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercise.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.muscles} • ${exercise.equipment}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _gray),
        ],
      ),
    );
  }
}
