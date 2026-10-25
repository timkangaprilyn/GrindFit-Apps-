import 'package:flutter/material.dart';
import 'app_state.dart';
import 'rest_day_screen.dart';

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() => _AiRecommendationsScreenState();
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
  Widget build(BuildContext context) {
    final int currentDay = AppState.instance.currentDayIndex;
    
    // Consistent default goal across screens
    final String goal = AppState.instance.fitnessGoal.isNotEmpty 
        ? AppState.instance.fitnessGoal 
        : "Muscle Gain / Strength";

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 18),
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
                      border: Border.all(color: _gold.withValues(alpha: 0.4), width: 1.2),
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
                            const Icon(Icons.auto_awesome, color: _gold, size: 20),
                            const SizedBox(width: 8),
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
                        MaterialPageRoute(builder: (_) => const RestDayScreen()),
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
                              Icon(Icons.self_improvement_rounded, color: _gold, size: 24),
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
                              border: Border.all(color: _selectedTab == 0 ? _gold : _border),
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
                              border: Border.all(color: _selectedTab == 1 ? _gold : _border),
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
                              border: Border.all(color: _selectedTab == 2 ? _gold : _border),
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

                  if (currentDay == 1) ...[
                    const Text(
                      'Day 1 - Upper Body Strength (Today)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _white),
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard('Push Up', '3 sets • 10-12 reps • 45s', 'Builds upper body strength'),
                    const SizedBox(height: 10),
                    _buildExerciseCard('Dumbbell Row', '3 sets • 10-12 reps • 45s', 'Improves posture & back strength'),
                    const SizedBox(height: 10),
                    _buildExerciseCard('Shoulder Press', '3 sets • 10 reps • 45s', 'Builds shoulder stability'),
                    const SizedBox(height: 24),
                    const Text(
                      'Day 2 - Lower Body (Tomorrow)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _white),
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard('Squat', '3 sets • 12 reps • 45s', 'Builds leg strength & stability'),
                    const SizedBox(height: 10),
                    _buildExerciseCard('Lunges', '3 sets • 10 reps each leg', 'Improves balance and leg definition'),
                  ] else ...[
                    const Text(
                      'Day 2 - Lower Body Power (Today)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _white),
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard('Squat', '4 sets • 10 reps • 60s', 'Builds core and leg power'),
                    const SizedBox(height: 10),
                    _buildExerciseCard('Romanian Deadlift', '3 sets • 10-12 reps • 45s', 'Targets hamstrings and glutes'),
                    const SizedBox(height: 10),
                    _buildExerciseCard('Calf Raises', '3 sets • 15 reps • 30s', 'Strengthens lower legs'),
                    const SizedBox(height: 24),
                    const Text(
                      'Day 3 - Core & Cardio (Tomorrow)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _white),
                    ),
                    const SizedBox(height: 12),
                    _buildExerciseCard('Plank', '3 sets • 45s hold', 'Core stability'),
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

  Widget _buildExerciseCard(String title, String subtitle, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: _gold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _white),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _gold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: _gray, fontWeight: FontWeight.w500),
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