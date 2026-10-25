import 'package:flutter/material.dart';
import 'exercise_timer_screen.dart';
import 'workout_plan_details_screen.dart'; // Kung saan naroon ang PlanExercise model

class WarmupScreen extends StatefulWidget {
  final List<PlanExercise> exerciseList;

  const WarmupScreen({
    super.key,
    required this.exerciseList,
  });

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  int _currentStep = 0;

  final List<Map<String, String>> _warmupSteps = [
    {
      'title': 'Arm Circles',
      'duration': '30 Seconds',
      'instruction': 'Stand tall and make small circles with your arms, gradually increasing the circle size to warm up shoulder joints.',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Dynamic Torso Twists',
      'duration': '30 Seconds',
      'instruction': 'Gently twist your torso from side to side to loosen up your spine and core muscles.',
      'image': 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=crop&w=800&q=80',
    },
    {
      'title': 'Light Jog in Place',
      'duration': '45 Seconds',
      'instruction': 'Jog lightly on the spot to elevate your heart rate and prepare your lower body.',
      'image': 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?auto=format&fit=crop&w=800&q=80',
    },
  ];

  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  void _nextStep() {
    setState(() {
      if (_currentStep < _warmupSteps.length - 1) {
        _currentStep++;
      } else {
        // Kapag tapos na ang warmup, pumunta na sa ExerciseTimerScreen dalang ang buong exercise list!
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseTimerScreen(
              exerciseList: widget.exerciseList,
              currentIndex: 0,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = _warmupSteps[_currentStep];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Warm-up (${_currentStep + 1}/${_warmupSteps.length})',
          style: const TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator Bar
            Row(
              children: List.generate(_warmupSteps.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: index <= _currentStep ? _gold : _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            Center(
              child: Text(
                step['title']!,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                step['duration']!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _gold),
              ),
            ),
            const SizedBox(height: 20),

            // Warmup Image Illustration
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _card,
                  border: Border.all(color: _border),
                ),
                child: Image.network(
                  step['image']!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.fitness_center, color: _gold, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Instructions Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(color: _gold, fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['instruction']!,
                    style: const TextStyle(color: _gray, fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: _card,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _nextStep,
            child: Text(
              _currentStep < _warmupSteps.length - 1 ? 'Next Warm-up Step' : 'Start Main Workout',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}