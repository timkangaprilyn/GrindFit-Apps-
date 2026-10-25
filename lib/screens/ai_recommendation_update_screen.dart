import 'package:flutter/material.dart';
import 'app_state.dart';
import 'ai_recommendations_screen.dart';

class AiRecommendationUpdateScreen extends StatelessWidget {
  const AiRecommendationUpdateScreen({super.key});

  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final String userGoal = state.fitnessGoal.isNotEmpty 
        ? state.fitnessGoal 
        : 'Muscle Gain / Strength';

    // Natural-sounding reasons based on the user's goal
    String goalReason = "We made a few minor adjustments to keep you moving smoothly toward your target.";
    final goalLower = userGoal.toLowerCase();
    
    if (goalLower.contains('muscle gain') || goalLower.contains('strength')) {
      goalReason = "We tweaked the intensity and progression since your primary focus is building solid strength and muscle mass.";
    } else if (goalLower.contains('lose weight') || goalLower.contains('weight loss')) {
      goalReason = "To support your weight loss goal, we've optimized the pacing to keep your active calorie burn efficient.";
    } else if (goalLower.contains('endurance')) {
      goalReason = "We adjusted the rest intervals slightly to help improve your overall stamina and cardiovascular endurance.";
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Updated for You',
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
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Active Goal: $userGoal',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Based on your recent activity, we've fine-tuned your routine to match your progress.",
                    style: TextStyle(
                      fontSize: 13,
                      color: _gray,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Main Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "What's Changed?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildChangeItem("Adjusted exercise parameters for $userGoal"),
                        const SizedBox(height: 12),
                        _buildChangeItem("Optimized set pacing and overall volume"),
                        const SizedBox(height: 12),
                        _buildChangeItem("Fine-tuned recovery windows between sets"),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(color: _border, height: 1),
                        ),

                        // Why Section
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _gold.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_outline, color: _gold, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start, // Itinama sa maliit na titik ang c
                                children: [
                                  const Text(
                                    "Why?",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: _white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    goalReason,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _gray,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // View New Plan Button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
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
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const AiRecommendationsScreen()),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'View New Plan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _bg,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeItem(String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _white,
            ),
          ),
        ),
      ],
    );
  }
}