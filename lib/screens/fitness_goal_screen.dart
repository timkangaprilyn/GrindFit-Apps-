import 'package:flutter/material.dart';
import '../widgets/grindfit_logo.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'workout_environment_screen.dart';

class FitnessGoalScreen extends StatefulWidget {
  const FitnessGoalScreen({super.key});

  @override
  State<FitnessGoalScreen> createState() => _FitnessGoalScreenState();
}

class _FitnessGoalScreenState extends State<FitnessGoalScreen> {
  late String _selectedGoal = AppState.instance.fitnessGoal;

  final List<Map<String, dynamic>> _goals = [
    {
      'title': 'Weight Loss',
      'subtitle': 'Get leaner and healthier',
      'icon': Icons.directions_run,
      'bgColor': const Color(0xFFEFF6FF),
      'iconColor': const Color(0xFF3B82F6),
    },
    {
      'title': 'Muscle Gain / Strength',
      'subtitle': 'Build muscle and get stronger',
      'icon': Icons.fitness_center,
      'bgColor': const Color(0xFFFFECD2),
      'iconColor': const Color(0xFFFF5200),
    },
    {
      'title': 'Endurance / Cardio',
      'subtitle': 'Improve stamina and endurance',
      'icon': Icons.favorite,
      'bgColor': const Color(0xFFE2F6F0),
      'iconColor': const Color(0xFF22C55E),
    },
    {
      'title': 'General Fitness',
      'subtitle': 'Maintain a healthy lifestyle',
      'icon': Icons.emoji_flags,
      'bgColor': const Color(0xFFEFE9F7),
      'iconColor': const Color(0xFFA855F7),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: const GrindFitLogo(),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepIndicator(currentStep: 2, totalSteps: 5),
              const SizedBox(height: 20),
              const Text(
                "What's your goal?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your primary fitness goal.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedGoal == goal['title'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedGoal = goal['title'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1.2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFFFF5200).withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: goal['bgColor'],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  goal['icon'],
                                  color: goal['iconColor'],
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFFFF5200) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    goal['subtitle'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5200),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    AppState.instance.updateGoal(_selectedGoal);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkoutEnvironmentScreen()),
                    );
                  },
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}