import 'package:flutter/material.dart';
import '../widgets/grindfit_logo.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'workout_schedule_screen.dart';

class ProgramDurationScreen extends StatefulWidget {
  const ProgramDurationScreen({super.key});

  @override
  State<ProgramDurationScreen> createState() => _ProgramDurationScreenState();
}

class _ProgramDurationScreenState extends State<ProgramDurationScreen> {
  late int _selectedMonths = AppState.instance.programDurationMonths;

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
              const OnboardingStepIndicator(currentStep: 4, totalSteps: 5),
              const SizedBox(height: 20),
              const Text(
                'How many months for\nyour fitness program?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set your target timeline for progress tracking and AI adaptation.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),

              Center(
                child: Column(
                  children: [
                    Text(
                      '$_selectedMonths ${_selectedMonths == 1 ? 'Month' : 'Months'}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF5200),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFFFF5200),
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        thumbColor: const Color(0xFFFF5200),
                        overlayColor: const Color(0xFFFF5200).withValues(alpha: 0.12),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                      ),
                      child: Slider(
                        value: _selectedMonths.toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$_selectedMonths Months',
                        onChanged: (value) {
                          setState(() {
                            _selectedMonths = value.toInt();
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('1 Month', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          Text('6 Months', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          Text('12 Months', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

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
                    AppState.instance.updateDuration(_selectedMonths);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkoutScheduleScreen()),
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