import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'workout_complete_screen.dart';

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
  final String _intensity = 'Moderate';
  
  // Optional Weight input controller
  final TextEditingController _weightController = TextEditingController();

  // Workout Timer & Pause State
  int _secondsElapsed = 0;
  late Timer _workoutTimer;
  bool _isPaused = false;

  // Rest Timer State
  bool _isResting = false;
  int _restSecondsRemaining = 45;
  Timer? _restTimer;

  final List<Map<String, dynamic>> _exercises = [
    {'name': '1. Push Up', 'completed': true},
    {'name': '2. Dumbbell Row', 'completed': false},
    {'name': '3. Shoulder Press', 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused && !_isResting) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _workoutTimer.cancel();
    _restTimer?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    HapticFeedback.lightImpact();
  }

  void _skipExercise() {
    HapticFeedback.mediumImpact();
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _exercises[_currentExerciseIndex]['completed'] = true;
        _currentExerciseIndex++;
        _weightController.clear();
      });
    } else {
      _finishWorkout();
    }
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = 45;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        timer.cancel();
        HapticFeedback.vibrate();
        setState(() {
          _isResting = false;
        });
      }
    });
  }

  void _finishWorkout() {
    _workoutTimer.cancel();
    _restTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
    );
  }

  // GrindFit Theme Colors (Black, Gold, White)
  static const Color _bg = Color(0xFF0A0A0B);
  static const Color _card = Color(0xFF14161B);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _white),
        title: Text(
          _exercises[_currentExerciseIndex]['name'].replaceFirst(RegExp(r'^\d+\.\s*'), ''),
          style: const TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: _gold,
            ),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Resume Workout' : 'Pause Workout',
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.orangeAccent),
            onPressed: _skipExercise,
            tooltip: 'Skip Exercise',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_currentExerciseIndex + 1} / ${_exercises.length}',
                style: const TextStyle(
                  color: _gold,
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
            // Live Timer / Rest Timer Status Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPaused ? Colors.redAccent : (_isResting ? Colors.blueAccent : _border),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isPaused
                            ? 'WORKOUT PAUSED'
                            : (_isResting ? 'REST PERIOD COUNTDOWN' : 'ACTIVE WORKOUT TIME'),
                        style: TextStyle(
                          color: _isPaused ? Colors.redAccent : (_isResting ? Colors.blueAccent : _gold),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isResting
                            ? '00:${_restSecondsRemaining.toString().padLeft(2, '0')}'
                            : _formatTime(_secondsElapsed),
                        style: const TextStyle(
                          color: _white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (_isResting)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _gold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        _restTimer?.cancel();
                        setState(() {
                          _isResting = false;
                        });
                      },
                      child: const Text('Skip Rest', style: TextStyle(color: _gold, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Exercise List Checklist Cards
            ..._exercises.asMap().entries.map((entry) {
              int idx = entry.key;
              var ex = entry.value;
              bool isSelected = idx == _currentExerciseIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? _gold : _border,
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
                              color: ex['completed'] ? Colors.green : _gray,
                              width: 1.5,
                            ),
                          ),
                          child: ex['completed']
                              ? const Icon(Icons.check, size: 14, color: _white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ex['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? _white : _gray,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isSelected ? Icons.keyboard_arrow_down : Icons.chevron_right,
                      color: _gray,
                      size: 20,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Optional Weight Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 1.2),
              ),
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: _white, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Weight (Optional / kg)',
                  labelStyle: TextStyle(color: _gray, fontSize: 13),
                  hintText: 'e.g., 10 kg',
                  hintStyle: TextStyle(color: Color(0xFF4B5563)),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.fitness_center_rounded, color: _gold, size: 20),
                ),
              ),
            ),
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
                color: _gray,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _intensity,
                  isExpanded: true,
                  dropdownColor: _card,
                  icon: const Icon(Icons.keyboard_arrow_down, color: _gray),
                  items: ['Low', 'Moderate', 'High'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _white,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      // Intensity state update
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
        color: _card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _exercises[_currentExerciseIndex]['completed'] = true;
                      _startRestTimer();

                      if (_currentExerciseIndex < _exercises.length - 1) {
                        _currentExerciseIndex++;
                        _weightController.clear();
                      } else {
                        _finishWorkout();
                      }
                    });
                  },
                  child: Text(
                    _currentExerciseIndex < _exercises.length - 1 ? 'Complete & Rest (45s)' : 'Finish Workout',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
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
                    side: const BorderSide(color: _border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _finishWorkout,
                  child: const Text(
                    'Finish Now',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBox(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _gray,
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
                  color: _white,
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
                        color: const Color(0xFF1F222B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 16, color: _gray),
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
                        color: const Color(0xFF1F222B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 16, color: _gray),
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