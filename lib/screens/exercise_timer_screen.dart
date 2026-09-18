import 'dart:async';
import 'package:flutter/material.dart';
import 'workout_complete_screen.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final String exerciseName;
  final String setsReps;

  const ExerciseTimerScreen({
    super.key,
    required this.exerciseName,
    required this.setsReps,
  });

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  late Timer _timer;
  int _secondsElapsed = 0;
  bool _isResting = false;
  int _restSecondsRemaining = 45;
  Timer? _restTimer;
  int _currentSet = 1;
  final int _totalSets = 3;

  @override
  void initState() {
    super.initState();
    _startWorkoutTimer();
  }

  void _startWorkoutTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isResting) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = 45;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsRemaining > 0) {
        setState(() {
          _restSecondsRemaining--;
        });
      } else {
        _restTimer?.cancel();
        setState(() {
          _isResting = false;
          if (_currentSet < _totalSets) {
            _currentSet++;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          widget.exerciseName,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.white,
                child: Image.network(
                  'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=600&q=80',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalSets, (index) {
                      bool isCompleted = index + 1 < _currentSet;
                      bool isCurrent = index + 1 == _currentSet && !_isResting;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 45,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isCompleted || isCurrent ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _isResting ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFFF5200).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isResting ? 'REST PERIOD' : 'SET $_currentSet OF $_totalSets',
                            style: TextStyle(
                              color: _isResting ? Colors.blueAccent : const Color(0xFFFF5200),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isResting ? '$_restSecondsRemaining' : _formatTime(_secondsElapsed),
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _isResting ? 'seconds remaining' : 'active workout time',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Injury Prevention Note',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Keep your core tight and maintain proper form throughout the set.',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFFC2410C)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              if (!_isResting) {
                if (_currentSet < _totalSets) {
                  _startRestTimer();
                } else {
                  // Kapag tapos na ang huling set, pumunta sa Workout Complete screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                  );
                }
              } else {
                setState(() {
                  _restTimer?.cancel();
                  _isResting = false;
                  if (_currentSet < _totalSets) {
                    _currentSet++;
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                    );
                  }
                });
              }
            },
            child: Text(
              !_isResting
                  ? (_currentSet < _totalSets ? 'Complete Set & Rest (45s)' : 'Finish Exercise')
                  : 'Skip Rest',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}