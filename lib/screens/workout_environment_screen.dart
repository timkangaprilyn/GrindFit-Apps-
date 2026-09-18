import 'package:flutter/material.dart';
import '../widgets/grindfit_logo.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'program_duration_screen.dart';

class WorkoutEnvironmentScreen extends StatefulWidget {
  const WorkoutEnvironmentScreen({super.key});

  @override
  State<WorkoutEnvironmentScreen> createState() => _WorkoutEnvironmentScreenState();
}

class _WorkoutEnvironmentScreenState extends State<WorkoutEnvironmentScreen> {
  late String _selectedEnvironment = AppState.instance.workoutEnvironment;

  final List<Map<String, dynamic>> _environments = [
    {
      'title': 'Indoor',
      'subtitle': 'Workout at home or in a gym',
      'icon': Icons.fitness_center,
      'bgColor': const Color(0xFFFFECD2),
      'iconColor': const Color(0xFFFF5200),
    },
    {
      'title': 'Outdoor',
      'subtitle': 'Enjoy fresh air and open spaces',
      'icon': Icons.park,
      'bgColor': const Color(0xFFE2F6F0),
      'iconColor': const Color(0xFF22C55E),
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
              const OnboardingStepIndicator(currentStep: 3, totalSteps: 5),
              const SizedBox(height: 20),
              const Text(
                'Where do you prefer\nto work out?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your workout environment.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.builder(
                  itemCount: _environments.length,
                  itemBuilder: (context, index) {
                    final env = _environments[index];
                    final isSelected = _selectedEnvironment == env['title'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedEnvironment = env['title'];
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
                                color: env['bgColor'],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  env['icon'],
                                  color: env['iconColor'],
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
                                    env['title'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFFFF5200) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    env['subtitle'],
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
                    AppState.instance.updateEnvironment(_selectedEnvironment);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgramDurationScreen()),
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