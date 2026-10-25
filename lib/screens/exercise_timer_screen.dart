import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'workout_complete_screen.dart';
import 'workout_plan_details_screen.dart';

class ExerciseTimerScreen extends StatefulWidget {
  final List<PlanExercise> exerciseList;
  final int currentIndex;
  final int totalWorkoutMinutes; // Halimbawa: 15 minutes total workout time

  const ExerciseTimerScreen({
    super.key,
    required this.exerciseList,
    this.currentIndex = 0,
    this.totalWorkoutMinutes = 15,
  });

  @override
  State<ExerciseTimerScreen> createState() => _ExerciseTimerScreenState();
}

class _ExerciseTimerScreenState extends State<ExerciseTimerScreen> {
  late int _currentIndex;
  late PlanExercise _currentExercise;
  
  // Total Workout Countdown Timer (e.g., 15 minutes = 900 seconds)
  late int _totalTimeRemaining;
  Timer? _workoutTimer;
  
  // Set management & Timers
  int _currentSet = 1;
  int _setSecondsRemaining = 45; 
  Timer? _activeTimer;
  
  // Rest State & Timer
  bool _isResting = false;
  int _restSecondsRemaining = 45;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _totalTimeRemaining = widget.totalWorkoutMinutes * 60;
    
    // Total Session Countdown Timer
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_totalTimeRemaining > 0) {
        setState(() {
          _totalTimeRemaining--;
        });
      } else {
        timer.cancel();
        _activeTimer?.cancel();
        _restTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
        );
      }
    });

    _loadCurrentExercise();
  }

  void _loadCurrentExercise() {
    _currentExercise = widget.exerciseList[_currentIndex];
    _currentSet = 1;
    _startSetActivePhase();
  }

  // Awtomatikong kinukuha ang eksaktong bilang ng sets mula sa AI plan detail (e.g., "3 sets")
  int get _totalSets {
    final regExp = RegExp(r'(\d+)\s*set', caseSensitive: false);
    final match = regExp.firstMatch(_currentExercise.detail);
    if (match != null && match.group(1) != null) {
      return int.parse(match.group(1)!);
    }
    return 3;
  }

  // Awtomatikong kinukuha ang eksaktong seconds mula sa AI plan detail (e.g., "45s")
  int get _setDurationSeconds {
    final regExp = RegExp(r'(?<![a-zA-Z])(\d+)\s*(?:s|sec|secs|second|seconds)\b', caseSensitive: false);
    final match = regExp.firstMatch(_currentExercise.detail);
    if (match != null && match.group(1) != null) {
      return int.parse(match.group(1)!);
    }
    return 45; // Default fallback kung walang nakasaad na seconds
  }

  // Pagsisimula ng Active Set Countdown Timer
  void _startSetActivePhase() {
    _activeTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _setSecondsRemaining = _setDurationSeconds;
    });

    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_setSecondsRemaining > 0) {
          _setSecondsRemaining--;
        }
      });

      // Kapag umabot ng 0, awtomatiko at agad na pumasok sa Rest mode
      if (_setSecondsRemaining <= 0) {
        timer.cancel();
        HapticFeedback.vibrate();
        _triggerRestOrNext();
      }
    });
  }

  // Pagsisimula ng Rest Phase
  void _startRestPhase() {
    _activeTimer?.cancel();
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = _setDurationSeconds; 
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        }
      });

      // Kapag tapos na ang rest, awtomatikong pumunta sa susunod na set o exercise
      if (_restSecondsRemaining <= 0) {
        timer.cancel();
        HapticFeedback.vibrate();
        _advanceAfterRest();
      }
    });
  }

  // Trigger para lumipat sa Rest o tapusin ang workout
  void _triggerRestOrNext() {
    if (_currentSet < _totalSets || _currentIndex < widget.exerciseList.length - 1) {
      _startRestPhase();
    } else {
      _finishWorkout();
    }
  }

  // Manual button click kapag pinindot ang "Complete Set"
  void _completeSetManually() {
    HapticFeedback.mediumImpact();
    _activeTimer?.cancel();
    _triggerRestOrNext();
  }

  void _advanceAfterRest() {
    _restTimer?.cancel();
    if (_currentSet < _totalSets) {
      setState(() {
        _currentSet++;
      });
      _startSetActivePhase();
    } else {
      if (_currentIndex < widget.exerciseList.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _loadCurrentExercise();
      } else {
        _finishWorkout();
      }
    }
  }

  void _skipRest() {
    HapticFeedback.mediumImpact();
    _restTimer?.cancel();
    _advanceAfterRest();
  }

  void _finishWorkout() {
    _workoutTimer?.cancel();
    _activeTimer?.cancel();
    _restTimer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
    );
  }

  // Eksaktong tumpak na larawan para sa bawat ehersisyo
  String _getImageUrlForExercise(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('push')) {
      return 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('squat')) {
      return 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('plank')) {
      return 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('row') || lower.contains('dumbbell row')) {
      return 'https://images.unsplash.com/photo-1581009137042-c5e2e4f85016?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('shoulder') || lower.contains('press')) {
      return 'https://images.unsplash.com/photo-1541534741688-6078c6bfb5c5?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('bicep') || lower.contains('curl')) {
      return 'https://images.unsplash.com/photo-1581009231458-f3d9943f8e57?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('tricep')) {
      return 'https://images.unsplash.com/photo-1530822847156-5df68865ffb0?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('lunge')) {
      return 'https://images.unsplash.com/photo-1434682881907-b43d6017bafa?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('chest') || lower.contains('bench')) {
      return 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('deadlift')) {
      return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1200&q=85';
    } else if (lower.contains('pull')) {
      return 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?auto=format&fit=crop&w=1200&q=85';
    }
    return 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=1200&q=85';
  }

  String _getGuideForExercise(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('push')) {
      return '• Keep body in a straight line\n• Lower chest close to floor\n• Keep elbows at 45 degrees';
    } else if (lower.contains('squat')) {
      return '• Feet shoulder-width apart\n• Chest up, core tight\n• Sit back and down, drive through heels';
    } else if (lower.contains('plank')) {
      return '• Align elbows under shoulders\n• Engage core and glutes\n• Keep back flat';
    } else if (lower.contains('row')) {
      return '• Keep back straight and hinge at hips\n• Pull dumbbell toward hip\n• Squeeze shoulder blades at the top';
    }
    return '• Maintain proper posture\n• Focus on controlled breathing\n• Execute full range of motion';
  }

  String _getInjuryPreventionForExercise(String exerciseName) {
    final lower = exerciseName.toLowerCase();
    if (lower.contains('push')) {
      return 'Avoid sagging hips or flaring elbows too wide.';
    } else if (lower.contains('squat')) {
      return 'Prevent knees from caving inward; keep spine neutral.';
    } else if (lower.contains('plank')) {
      return 'Do not let lower back sag to prevent lumbar strain.';
    } else if (lower.contains('row')) {
      return 'Avoid rounding your lower back; keep your core braced to protect your spine.';
    }
    return 'Stop immediately if you experience sharp or unusual joint pain.';
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static const Color _bg = Color(0xFF0A0A0B);
  static const Color _card = Color(0xFF14161B);
  static const Color _border = Color(0xFF2C2F36);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9AA3AE);

  void _prevExercise() {
    HapticFeedback.mediumImpact();
    _activeTimer?.cancel();
    _restTimer?.cancel();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadCurrentExercise();
    }
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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _card,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: _white, size: 20),
                    ),
                  ),
                  Text(
                    _isResting ? 'RESTING' : 'Set $_currentSet / $_totalSets',
                    style: TextStyle(
                      color: _isResting ? Colors.blueAccent : _gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // Main Content: Conditional kung nagre-rest ba o nag-eehersisyo
            Expanded(
              child: _isResting
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'REST',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '00:${_restSecondsRemaining.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: _white,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Next: Set $_currentSet of ${_currentExercise.name}',
                              style: const TextStyle(
                                color: _gray,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              _currentExercise.name,
                              style: const TextStyle(
                                color: _white,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tumpak na Larawan na may errorBuilder para iwas red box error sakaling magka-issue sa network
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Image.network(
                                _getImageUrlForExercise(_currentExercise.name),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: _card,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fitness_center_rounded,
                                        color: _gold,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.fitness_center_rounded, color: _gold, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _currentExercise.detail, 
                                    style: const TextStyle(
                                      color: _gold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Timer & Status Block (Total Time Left & Set Timer)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatTime(_totalTimeRemaining),
                                      style: const TextStyle(
                                        color: _gold,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'TOTAL TIME LEFT',
                                      style: TextStyle(
                                        color: _gray,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '00:${_setSecondsRemaining.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        color: _white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'SET TIMER',
                                      style: TextStyle(
                                        color: _gray,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.menu_book_rounded, color: _gold, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'How to Perform',
                                      style: TextStyle(
                                        color: _gold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getGuideForExercise(_currentExercise.name),
                                  style: const TextStyle(
                                    color: _white,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.security_rounded, color: Colors.orangeAccent, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Injury Prevention Tip',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _getInjuryPreventionForExercise(_currentExercise.name),
                                  style: const TextStyle(
                                    color: _white,
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _card,
                border: Border(top: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: (_currentIndex > 0 && !_isResting) ? _prevExercise : null,
                      child: const Text(
                        'PREV',
                        style: TextStyle(color: _white, fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isResting ? Colors.blueAccent : _gold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isResting ? _skipRest : _completeSetManually,
                      child: Text(
                        _isResting ? 'Skip Rest' : 'Complete Set',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
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