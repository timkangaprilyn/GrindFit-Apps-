import 'package:flutter/material.dart';
import 'workout_complete_screen.dart';
import 'home_dashboard_screen.dart';
import 'ai_recommendations_screen.dart';

class ActiveWorkoutSessionScreen extends StatefulWidget {
  const ActiveWorkoutSessionScreen({super.key});

  @override
  State<ActiveWorkoutSessionScreen> createState() => _ActiveWorkoutSessionScreenState();
}

class _ActiveWorkoutSessionScreenState extends State<ActiveWorkoutSessionScreen> {
  int _currentExerciseIndex = 0;
  int _sets = 3;
  int _reps = 10;
  int _duration = 45;
  String _intensity = 'Moderate';

  final List<Map<String, dynamic>> _exercises = [
    {'name': '1. Push Up', 'completed': true},
    {'name': '2. Dumbbell Row', 'completed': false},
    {'name': '3. Shoulder Press', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          _exercises[_currentExerciseIndex]['name'].replaceFirst(RegExp(r'^\d+\.\s*'), ''),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Center(
              child: Text(
                '${_currentExerciseIndex + 1} / ${_exercises.length}',
                style: const TextStyle(
                  color: Color(0xFFFF5200),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._exercises.asMap().entries.map((entry) {
              int idx = entry.key;
              var ex = entry.value;
              bool isSelected = idx == _currentExerciseIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ex['completed'] ? Colors.green : Colors.transparent,
                            border: Border.all(
                              color: ex['completed'] ? Colors.green : const Color(0xFF94A3B8),
                              width: 1.5,
                            ),
                          ),
                          child: ex['completed']
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ex['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isSelected ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStepperBox('Sets', _sets, (val) {
                    setState(() => _sets = val);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStepperBox('Reps', _reps, (val) {
                    setState(() => _reps = val);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepperBox('Duration (sec)', _duration, (val) {
              setState(() => _duration = val);
            }),
            const SizedBox(height: 16),
            const Text(
              'Intensity',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _intensity,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                  items: ['Low', 'Moderate', 'High'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _intensity = newValue);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          _exercises[_currentExerciseIndex]['completed'] = true;
                          if (_currentExerciseIndex < _exercises.length - 1) {
                            _currentExerciseIndex++;
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                            );
                          }
                        });
                      },
                      child: Text(
                        _currentExerciseIndex < _exercises.length - 1 ? 'Next Exercise' : 'Finish Workout',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                        );
                      },
                      child: const Text(
                        'Finish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen()));
                } else if (index == 1) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AiRecommendationsScreen()));
                } else {
                  // Para sa iba pang tabs (Progress / Profile), pansamantalang ibinabalik sa Home o gagawan natin ng screens kapag kinakailangan
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This section is coming soon!')),
                  );
                }
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFFFF5200),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workouts'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperBox(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (value > 1) onChanged(value - 1);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      onChanged(value + 1);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 16, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}