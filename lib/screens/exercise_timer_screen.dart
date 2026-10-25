import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/workout_plan.dart';
import 'workout_complete_screen.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final List<PlanExercise> exerciseList;
  final int currentIndex;
  final int totalWorkoutMinutes;

  const ExerciseTimerScreen({
    super.key,
    required this.exerciseList,
    this.currentIndex = 0,
    this.totalWorkoutMinutes = 15,
  }) : assert(exerciseList.length > 0);

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  static const Color _background = Color(0xFF0A0A0B);
  static const Color _card = Color(0xFF14161B);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  late int _currentIndex;
  late int _totalTimeRemaining;
  int _currentSet = 1;
  int _setSecondsRemaining = 45;
  int _restSecondsRemaining = 45;
  bool _isResting = false;
  bool _hasFinished = false;

  Timer? _workoutTimer;
  Timer? _activeTimer;
  Timer? _restTimer;

  PlanExercise get _currentExercise => widget.exerciseList[_currentIndex];

  int get _totalSets {
    final match = RegExp(
      r'(\d+)\s*sets?',
      caseSensitive: false,
    ).firstMatch(_currentExercise.detail);
    return int.tryParse(match?.group(1) ?? '') ?? 3;
  }

  int get _setDurationSeconds {
    final match = RegExp(
      r'(\d+)\s*(?:s|sec|secs|second|seconds)\b',
      caseSensitive: false,
    ).firstMatch(_currentExercise.detail);
    return int.tryParse(match?.group(1) ?? '') ?? 45;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex.clamp(
      0,
      widget.exerciseList.length - 1,
    );
    _totalTimeRemaining = widget.totalWorkoutMinutes * 60;
    _setSecondsRemaining = _setDurationSeconds;
    _startWorkoutTimer();
    _startActiveTimer();
  }

  void _startWorkoutTimer() {
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasFinished) {
        timer.cancel();
        return;
      }
      if (_totalTimeRemaining <= 1) {
        setState(() => _totalTimeRemaining = 0);
        _finishWorkout();
        return;
      }
      setState(() => _totalTimeRemaining--);
    });
  }

  void _startActiveTimer() {
    _activeTimer?.cancel();
    _restTimer?.cancel();
    _isResting = false;
    _setSecondsRemaining = _setDurationSeconds;
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasFinished) {
        timer.cancel();
        return;
      }
      if (_setSecondsRemaining <= 1) {
        setState(() => _setSecondsRemaining = 0);
        timer.cancel();
        HapticFeedback.vibrate();
        _startRestOrAdvance();
        return;
      }
      setState(() => _setSecondsRemaining--);
    });
  }

  void _startRestOrAdvance() {
    if (_currentSet < _totalSets ||
        _currentIndex < widget.exerciseList.length - 1) {
      _startRestTimer();
    } else {
      _finishWorkout();
    }
  }

  void _startRestTimer() {
    _activeTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = _setDurationSeconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _hasFinished) {
        timer.cancel();
        return;
      }
      if (_restSecondsRemaining <= 1) {
        setState(() => _restSecondsRemaining = 0);
        timer.cancel();
        HapticFeedback.vibrate();
        _advanceAfterRest();
        return;
      }
      setState(() => _restSecondsRemaining--);
    });
  }

  void _advanceAfterRest() {
    _restTimer?.cancel();
    if (_currentSet < _totalSets) {
      setState(() {
        _currentSet++;
        _isResting = false;
      });
      _startActiveTimer();
    } else if (_currentIndex < widget.exerciseList.length - 1) {
      setState(() {
        _currentIndex++;
        _currentSet = 1;
        _isResting = false;
      });
      _startActiveTimer();
    } else {
      _finishWorkout();
    }
  }

  void _completeSet() {
    HapticFeedback.mediumImpact();
    _activeTimer?.cancel();
    _startRestOrAdvance();
  }

  void _skipRest() {
    HapticFeedback.mediumImpact();
    _restTimer?.cancel();
    _advanceAfterRest();
  }

  void _previousExercise() {
    if (_currentIndex == 0 || _isResting) return;
    HapticFeedback.mediumImpact();
    _activeTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _currentIndex--;
      _currentSet = 1;
    });
    _startActiveTimer();
  }

  void _finishWorkout() {
    if (_hasFinished || !mounted) return;
    _hasFinished = true;
    _workoutTimer?.cancel();
    _activeTimer?.cancel();
    _restTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getGuide(String name) {
    final exercise = name.toLowerCase();
    if (exercise.contains('push')) {
      return 'Keep your body in a straight line, lower your chest with control, '
          'and keep your elbows at about 45 degrees.';
    }
    if (exercise.contains('squat')) {
      return 'Keep your feet shoulder-width apart and chest up. Sit back and '
          'down, then drive through your heels.';
    }
    if (exercise.contains('plank')) {
      return 'Keep your elbows under your shoulders, engage your core, and '
          'maintain a flat back.';
    }
    if (exercise.contains('row')) {
      return 'Hinge at your hips with a straight back. Pull toward your hip '
          'and squeeze your shoulder blades.';
    }
    return 'Maintain good posture, breathe steadily, and use a controlled '
        'range of motion.';
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _activeTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _currentExercise;
    final remaining = _isResting ? _restSecondsRemaining : _setSecondsRemaining;
    final totalPhaseSeconds = _setDurationSeconds;
    final progress = totalPhaseSeconds > 0
        ? (1 - remaining / totalPhaseSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: _white),
                  ),
                  const Spacer(),
                  const Text(
                    'WORKOUT SESSION',
                    style: TextStyle(
                      color: _gray,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(_totalTimeRemaining),
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'EXERCISE ${_currentIndex + 1} OF ${widget.exerciseList.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _gray,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: 1.65,
                        child: exercise.imageUrl == null
                            ? const ColoredBox(
                                color: _card,
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: _gold,
                                  size: 56,
                                ),
                              )
                            : Image.network(
                                exercise.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const ColoredBox(
                                  color: _card,
                                  child: Icon(
                                    Icons.fitness_center_rounded,
                                    color: _gold,
                                    size: 56,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      exercise.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.detail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _gray, fontSize: 14),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _card,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isResting
                                ? 'REST'
                                : 'SET $_currentSet OF $_totalSets',
                            style: TextStyle(
                              color: _isResting
                                  ? Colors.lightBlueAccent
                                  : _gold,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: 176,
                            height: 176,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 9,
                                    strokeCap: StrokeCap.round,
                                    backgroundColor: _border,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _isResting
                                          ? Colors.lightBlueAccent
                                          : _gold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatTime(remaining),
                                  style: const TextStyle(
                                    color: _white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isResting
                                ? 'Catch your breath before the next set'
                                : 'Stay controlled and focus on your form',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: _gray, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'TARGET MUSCLES',
                      content: exercise.muscles,
                      icon: Icons.bolt_rounded,
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      title: 'EQUIPMENT',
                      content: exercise.equipment,
                      icon: Icons.fitness_center_rounded,
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      title: 'HOW TO PERFORM',
                      content: _getGuide(exercise.name),
                      icon: Icons.menu_book_rounded,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentIndex > 0 && !_isResting
                          ? _previousExercise
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _white,
                        side: const BorderSide(color: _border),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('PREV'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isResting ? _skipRest : _completeSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isResting ? Colors.blueAccent : _gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(_isResting ? 'SKIP REST' : 'COMPLETE SET'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14161B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2F36)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF5B800), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF5B800),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
