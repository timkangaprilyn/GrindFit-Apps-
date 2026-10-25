import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import 'main_navigation_screen.dart';

// Inline PlanExercise model para walang import error
class PlanExercise {
  final String name;
  final String detail;
  final String repsLabel;
  final String muscles;
  final String equipment;
  final String? imageUrl;

  const PlanExercise({
    required this.name,
    required this.detail,
    required this.repsLabel,
    required this.muscles,
    required this.equipment,
    this.imageUrl,
  });
}

// Inline WorkoutPlan model
class WorkoutPlan {
  static List<PlanExercise> forProfile({
    required String goal,
    required String environment,
  }) {
    if (environment == 'Home (no equipment)') {
      return const [
        PlanExercise(
          name: 'Push Up',
          detail: '3 sets • 10-12 reps • 45s',
          repsLabel: '10-12 reps',
          muscles: 'Chest, shoulders, triceps',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=300&q=80',
        ),
        PlanExercise(
          name: 'Bodyweight Squat',
          detail: '3 sets • 12-15 reps • 45s',
          repsLabel: '12-15 reps',
          muscles: 'Quads, glutes, core',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?auto=format&fit=crop&w=300&q=80',
        ),
        PlanExercise(
          name: 'Plank Hold',
          detail: '3 sets • 45 seconds • 30s',
          repsLabel: '45s hold',
          muscles: 'Core, abs, shoulders',
          equipment: 'No Equipment',
          imageUrl: 'https://images.unsplash.com/photo-1566241142559-40e1dab266c6?auto=format&fit=crop&w=300&q=80',
        ),
      ];
    }

    return const [
      PlanExercise(
        name: 'Push Up',
        detail: '3 sets • 10-12 reps • 45s',
        repsLabel: '10-12 reps',
        muscles: 'Chest, shoulders, triceps',
        equipment: 'No Equipment',
        imageUrl: 'https://images.unsplash.com/photo-1598971639058-fab3c3109a00?auto=format&fit=crop&w=300&q=80',
      ),
      PlanExercise(
        name: 'Dumbbell Row',
        detail: '3 sets • 10-12 reps • 45s',
        repsLabel: '10-12 reps',
        muscles: 'Back, biceps',
        equipment: 'Dumbbells',
        imageUrl: 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?auto=format&fit=crop&w=300&q=80',
      ),
      PlanExercise(
        name: 'Shoulder Press',
        detail: '3 sets • 10 reps • 45s',
        repsLabel: '10 reps',
        muscles: 'Shoulders, triceps',
        equipment: 'Dumbbells',
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?auto=format&fit=crop&w=300&q=80',
      ),
    ];
  }
}

class PlanReadyScreen extends StatefulWidget {
  const PlanReadyScreen({super.key});

  @override
  State<PlanReadyScreen> createState() => _PlanReadyScreenState();
}

class _PlanReadyScreenState extends State<PlanReadyScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _red = Color(0xFFEF4444);

  bool _isGenerating = false;
  String _loadingStepText = 'Checking network connection...';
  String? _errorMessage;

  late final List<PlanExercise> _exercises;

  @override
  void initState() {
    super.initState();
    final state = AppState.instance;
    _exercises = WorkoutPlan.forProfile(
      goal: state.fitnessGoal,
      environment: state.workoutEnvironment,
    );
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleGenerateAndProceed() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _loadingStepText = 'Checking network connection...';
    });

    if (!await _hasInternet()) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage =
            'No internet connection. Please check your network and try again.';
      });
      return;
    }

    const steps = <String>[
      'Analyzing your goals & environment...',
      'Designing your workout schedule...',
      'Finalizing your custom plan...',
    ];
    for (final step in steps) {
      if (!mounted) return;
      setState(() => _loadingStepText = step);
      await Future.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(initialIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGenerating,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            Positioned(
              top: -140,
              right: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.22),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isGenerating ? null : () => Navigator.maybePop(context),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _isGenerating ? _gray : _white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildHeaderCard(),
                    const SizedBox(height: 20),
                    _buildInjuryNotice(),
                    const SizedBox(height: 24),
                    const Text(
                      'Initial Workout Preview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _exercises.length; i++) ...[
                            if (i > 0) const Divider(color: _border, height: 20),
                            _buildPreviewRow(
                              '${i + 1}. ${_exercises[i].name}',
                              _exercises[i].detail,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      _buildErrorCard(_errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    _buildActionButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_card, Color.alphaBlend(_gold.withValues(alpha: 0.15), _card)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: _gold, size: 22),
              SizedBox(width: 8),
              Text(
                'Gemini AI Generated',
                style: TextStyle(
                  color: _gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Personalized Plan is Ready!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${AppState.instance.fitnessGoal} • ${AppState.instance.workoutEnvironment} • ${AppState.instance.programDurationMonths} Months',
            style: const TextStyle(
              fontSize: 13,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInjuryNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: _gold, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Injury Prevention Notice',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Always maintain proper form and take rest intervals to prevent overexertion.',
                  style: TextStyle(fontSize: 12, color: _gray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _red.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wifi_off_rounded, color: _red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: _white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final hasError = _errorMessage != null;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_goldLight, _gold],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isGenerating ? null : _handleGenerateAndProceed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: _bg,
                              strokeWidth: 2.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _loadingStepText,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _bg,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasError ? 'Try Again' : 'Go to Home Dashboard',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _bg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasError ? Icons.refresh_rounded : Icons.arrow_forward,
                            color: _bg,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String exercise, String details) {
    return Row(
      children: [
        Expanded(
          child: Text(
            exercise,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          details,
          style: const TextStyle(
            fontSize: 13,
            color: _gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}