import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_plan.dart';
import '../models/app_state.dart';
import '../widgets/workout_image.dart';
import '../services/voice_coach.dart';
import 'exercise_timer_screen.dart';

class WarmupScreen extends StatefulWidget {
  final List<PlanExercise> exerciseList;

  const WarmupScreen({super.key, required this.exerciseList});

  @override
  State<WarmupScreen> createState() => _WarmupScreenState();
}

class _WarmupScreenState extends State<WarmupScreen> {
  static const int _restDurationSeconds = 15;

  int _currentStep = 0;
  Timer? _stepTimer;
  late int _secondsRemaining = _stepDuration;
  bool _isTimerRunning = false;
  bool _isResting = false;

  final List<Map<String, dynamic>> _warmupSteps = [
    {
      'title': 'Arm Circles',
      'durationSeconds': 30,
      'instruction': 'Stand tall and make small circles with your arms, gradually increasing the circle size to warm up shoulder joints.',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?auto=format&fit=max&w=900&q=80',
    },
    {
      'title': 'Dynamic Torso Twists',
      'durationSeconds': 30,
      'instruction': 'Gently twist your torso from side to side to loosen up your spine and core muscles.',
      'image': 'https://images.unsplash.com/photo-1518310383802-640c2de311b2?auto=format&fit=max&w=900&q=80',
    },
    {
      'title': 'Light Jog in Place',
      'durationSeconds': 45,
      'instruction': 'Jog lightly on the spot to elevate your heart rate and prepare your lower body.',
      'image': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=max&w=900&q=80',
    },
  ];

  int get _stepDuration => _warmupSteps[_currentStep]['durationSeconds'] as int;

  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);

  @override
  void dispose() {
    VoiceCoach.instance.stop();
    _stepTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    VoiceCoach.instance.say(
      _isResting
          ? 'Rest for fifteen seconds.'
          : 'Warm up. ${_warmupSteps[_currentStep]['title']}.',
    );
    _stepTimer?.cancel();
    _isTimerRunning = true;
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        if (_isResting) {
          _advanceAfterRest();
        } else {
          _beginRest();
        }
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _pauseOrResumeTimer() {
    if (_isTimerRunning) {
      _stepTimer?.cancel();
      setState(() => _isTimerRunning = false);
      return;
    }
    setState(() => _isTimerRunning = true);
    _startCountdown();
  }

  void _resetTimer() {
    _stepTimer?.cancel();
    setState(() {
      _secondsRemaining = _stepDuration;
      _isTimerRunning = false;
      _isResting = false;
    });
    _startCountdown();
  }

  void _beginRest() {
    setState(() {
      _isResting = true;
      _secondsRemaining = _restDurationSeconds;
      _isTimerRunning = true;
    });
    _startCountdown();
  }

  void _advanceAfterRest() {
    _stepTimer?.cancel();
    if (_currentStep == _warmupSteps.length - 1) {
      _startMainWorkout();
      return;
    }
    setState(() {
      _currentStep++;
      _secondsRemaining = _stepDuration;
      _isResting = false;
      _isTimerRunning = true;
    });
    _startCountdown();
  }

  void _startMainWorkout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseTimerScreen(
          exerciseList: widget.exerciseList,
          currentIndex: 0,
          totalWorkoutMinutes:
              (int.tryParse(
                        RegExp(r'\d+')
                                .firstMatch(AppState.instance.sessionDuration)
                                ?.group(0) ??
                            '',
                      ) ??
                      30)
                  .clamp(5, 120),
        ),
      ),
    );
  }

  String _formatTime(int seconds) => '00:${seconds.toString().padLeft(2, '0')}';

  Widget _buildTimerCard() {
    final totalSeconds = _isResting ? _restDurationSeconds : _stepDuration;
    final progress = 1 - (_secondsRemaining / totalSeconds);
    final actionLabel = _isTimerRunning ? 'Pause timer' : 'Resume timer';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _border,
                    valueColor: const AlwaysStoppedAnimation<Color>(_gold),
                  ),
                ),
                Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    color: _white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isResting ? 'Rest and recover' : 'Move at your pace',
                  style: const TextStyle(
                    color: _white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isResting
                      ? 'The next step starts automatically.'
                      : 'A $_restDurationSeconds-second rest follows automatically.',
                  style: const TextStyle(color: _gray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _pauseOrResumeTimer,
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _bg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        _isTimerRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                      ),
                      label: Text(
                        actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: _resetTimer,
                      tooltip: 'Reset timer',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.replay_rounded, color: _gray),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _white,
            size: 18,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _isResting
              ? 'Rest (${_currentStep + 1}/${_warmupSteps.length})'
              : 'Warm-up (${_currentStep + 1}/${_warmupSteps.length})',
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
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
                    margin: EdgeInsets.symmetric(
                      horizontal: index == 0 ? 0 : 4,
                    ),
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
                _isResting ? 'Rest and Recover' : step['title'] as String,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isResting
                    ? '$_restDurationSeconds seconds'
                    : '${step['durationSeconds']} second guided warm-up',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _gold,
                ),
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
                child: WorkoutImage(
                  imageUrl: step['image']!,
                  backgroundColor: _card,
                  iconColor: _gold,
                  iconSize: 50,
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildTimerCard(),
            const SizedBox(height: 20),

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
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step['instruction']!,
                    style: const TextStyle(
                      color: _gray,
                      fontSize: 14,
                      height: 1.4,
                    ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: _isResting ? _advanceAfterRest : _beginRest,
            child: Text(
              _isResting ? 'Skip Rest' : 'Skip to Rest',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
