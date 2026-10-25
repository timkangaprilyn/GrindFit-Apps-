import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
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
  // Timers para sa Automatic Progression
  int _activeSecondsRemaining = 30; // 30 segundo bawat active set
  Timer? _activeTimer;
  
  bool _isResting = false;
  int _restSecondsRemaining = 45; // 45 segundo rest period
  Timer? _restTimer;

  int _currentSet = 1;
  final int _totalSets = 3;

  // Video Player Controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _startActiveSetTimer();
  }

  void _initializeVideo() {
    String videoUrl = _getVideoUrlForExercise(widget.exerciseName);
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.setLooping(true);
          _videoController?.play();
        }
      });
  }

  String _getVideoUrlForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push')) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-man-doing-push-ups-in-a-gym-42999-large.mp4';
    } else if (lower.contains('squat')) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-woman-doing-squats-with-weights-41551-large.mp4';
    } else if (lower.contains('plank')) {
      return 'https://assets.mixkit.co/videos/preview/mixkit-woman-doing-exercises-on-a-mat-42998-large.mp4';
    }
    return 'https://assets.mixkit.co/videos/preview/mixkit-man-doing-push-ups-in-a-gym-42999-large.mp4';
  }

  // 3 Hakbang para sa Tamang Porma (Dynamic batay sa ehersisyo)
  List<String> _getStepsForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('push')) {
      return [
        'Panatilihing tuwid ang katawan mula ulo hanggang sakong.',
        'Ilagay ang mga kamay nang medyo mas malawak kaysa sa balikat.',
        'Ibaba ang dibdib malapit sa sahig, pagkatapos ay itulak paitaas.'
      ];
    } else if (lower.contains('squat')) {
      return [
        'Ihiwalay ang mga paa ayon sa lapad ng balikat, i-tighten ang core.',
        'Umupo pabalik at pababa nang nakadikit ang mga sakong sa sahig.',
        'Itulak ang katawan pataas gamit ang mga sakong para bumalik sa simula.'
      ];
    } else if (lower.contains('plank')) {
      return [
        'Ihanay ang mga siko nang direkta sa ilalim ng mga balikat.',
        'I-engage ang core at glutes para hindi lumubog ang likod.',
        'Huminga nang tuloy-tuloy sa buong tagal ng paghawak.'
      ];
    } else if (lower.contains('row')) {
      return [
        'I-hinge ang balakang pabalik at panatilihing tuwid ang likod.',
        'Hilahin ang bigat patungo sa balakang habang pinipiga ang likod.',
        'Ibaba nang may kontrol pabalik sa panimulang posisyon.'
      ];
    }
    return [
      'Posisyonan ang katawan sa tamang simula at panatilihin ang tikas.',
      'Isagawa ang galaw nang may kontrol at wastong paghinga.',
      'Tapusin ang buong range of motion nang ligtas.'
    ];
  }

  // Automatic Active Set Timer
  void _startActiveSetTimer() {
    setState(() {
      _isResting = false;
      _activeSecondsRemaining = 30;
    });

    _activeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSecondsRemaining > 0) {
        setState(() {
          _activeSecondsRemaining--;
        });
      } else {
        _activeTimer?.cancel();
        HapticFeedback.mediumImpact();
        _startRestTimer();
      }
    });
  }

  // Automatic Rest Timer
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
        HapticFeedback.vibrate();

        if (_currentSet < _totalSets) {
          setState(() {
            _currentSet++;
          });
          _startActiveSetTimer();
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _restTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
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
    final instructions = _getStepsForExercise(widget.exerciseName);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        iconTheme: const IconThemeData(color: _white),
        title: Text(
          widget.exerciseName,
          style: const TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Player Banner
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _border),
                  ),
                  child: _isVideoInitialized && _videoController != null
                      ? FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: _gold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.exerciseName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _white,
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
              // Automatic Timer & Progress Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border, width: 1.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_totalSets, (index) {
                        bool isCompleted = index + 1 < _currentSet;
                        bool isCurrent = index + 1 == _currentSet;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent ? _gold : _border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isResting ? Colors.blue.withValues(alpha: 0.15) : _gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isResting ? 'REST PERIOD' : 'SET $_currentSet OF $_totalSets (ACTIVE)',
                        style: TextStyle(
                          color: _isResting ? Colors.blueAccent : _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isResting ? '$_restSecondsRemaining s' : '${_activeSecondsRemaining}s',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    Text(
                      _isResting ? 'rest countdown (auto-progress)' : 'active workout countdown',
                      style: const TextStyle(color: _gray, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '3 Hakbang para sa Tamang Porma',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              const SizedBox(height: 8),
              // Dynamic 3 Instructions Steps
              ...instructions.asMap().entries.map((entry) {
                int idx = entry.key;
                String text = entry.value;
                return _buildInstructionStep('${idx + 1}', text);
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMetricBox('Sets', '$_currentSet/$_totalSets')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Reps', widget.setsReps)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Weight', 'Bodyweight')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMetricBox('Duration', '30s')),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: _card,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: () {
              if (!_isResting) {
                _activeTimer?.cancel();
                _startRestTimer();
              } else {
                _restTimer?.cancel();
                if (_currentSet < _totalSets) {
                  setState(() {
                    _currentSet++;
                  });
                  _startActiveSetTimer();
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                  );
                }
              }
            },
            child: Text(
              !_isResting ? 'Skip Active Set / Rest Now' : 'Skip Rest Now',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
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
        color: _card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _white,
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _gold),
          ),
          Expanded(
            child: Text(
              instructionText,
              style: const TextStyle(fontSize: 13, color: _gray),
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
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _gray, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: _white),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}