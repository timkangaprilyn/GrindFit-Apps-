import 'package:flutter/material.dart';
import '../widgets/grindfit_logo.dart';
import '../widgets/onboarding_step_indicator.dart';
import '../models/app_state.dart';
import 'fitness_goal_screen.dart';

class InitialAssessmentScreen extends StatefulWidget {
  const InitialAssessmentScreen({super.key});

  @override
  State<InitialAssessmentScreen> createState() => _InitialAssessmentScreenState();
}

class _InitialAssessmentScreenState extends State<InitialAssessmentScreen> {
  late final _nameController = TextEditingController(text: AppState.instance.fullName);
  late final _ageController = TextEditingController(text: AppState.instance.age.toString());
  late final _heightController = TextEditingController(text: AppState.instance.heightCm.toStringAsFixed(0));
  late final _weightController = TextEditingController(text: AppState.instance.weightKg.toStringAsFixed(0));

  late String _fitnessLevel = AppState.instance.fitnessLevel;
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleNext() {
    AppState.instance.updateAssessment(
      fullName: _nameController.text.trim().isEmpty ? AppState.instance.fullName : _nameController.text.trim(),
      age: int.tryParse(_ageController.text) ?? AppState.instance.age,
      heightCm: double.tryParse(_heightController.text) ?? AppState.instance.heightCm,
      weightKg: double.tryParse(_weightController.text) ?? AppState.instance.weightKg,
      fitnessLevel: _fitnessLevel,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FitnessGoalScreen()),
    );
  }

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepIndicator(currentStep: 1, totalSteps: 5),
              const SizedBox(height: 20),
              const Text(
                'Complete Your Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Help us personalize your experience.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Full Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('Juan Dela Cruz'),
              ),
              const SizedBox(height: 20),

              const Text(
                'Age',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('20'),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weight (cm)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('170'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weight (kg)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('62'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              const Text(
                'Fitness Level',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _fitnessLevel, // Pinalitan ang deprecated 'value' ng 'initialValue'
                items: _fitnessLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A))),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _fitnessLevel = value);
                },
                decoration: _inputDecoration(''),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),

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
                  onPressed: _handleNext,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}