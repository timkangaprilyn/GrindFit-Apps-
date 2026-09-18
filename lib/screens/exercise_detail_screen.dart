import 'dart:async';
import 'package:flutter/material.dart';
import 'workout_complete_screen.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName;
  final String setsReps;
  final String muscles;

  const ExerciseDetailScreen({
    super.key,
    this.exerciseName = 'Push Up',
    this.setsReps = '10-12 reps',
    this.muscles = 'Chest, shoulders, triceps',
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
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
        automaticallyImplyLeading: true,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
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
              Text(
                widget.exerciseName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTag('Upper Body'),
                  const SizedBox(width: 8),
                  _buildTag('Beginner'),
                  const SizedBox(width: 8),
                  _buildTag('No Equipment'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalSets, (index) {
                        bool isCompleted = index + 1 < _currentSet;
                        bool isCurrent = index + 1 == _currentSet && !_isResting;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isResting ? Colors.blue.withValues(alpha: 0.1) : const Color(0xFFFF5200).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isResting ? 'REST PERIOD' : 'SET $_currentSet OF $_totalSets',
                        style: TextStyle(
                          color: _isResting ? Colors.blueAccent : const Color(0xFFFF5200),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isResting ? '$_restSecondsRemaining s' : _formatTime(_secondsElapsed),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      _isResting ? 'rest countdown' : 'active workout time',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              _buildInstructionStep('1', 'Keep your body in a straight line.'),
              _buildInstructionStep('2', 'Hands slightly wider than shoulders.'),
              _buildInstructionStep('3', 'Lower your chest, then push back up.'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMetricBox('Sets', '$_currentSet/$_totalSets')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Reps', widget.setsReps)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Weight', '5 kg')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Duration', '45s')),
                ],
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
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Safety Note',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Keep your core tight and avoid sagging your hips.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFC2410C)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (!_isResting) {
                if (_currentSet < _totalSets) {
                  _startRestTimer();
                } else {
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instructionText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              instructionText,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}