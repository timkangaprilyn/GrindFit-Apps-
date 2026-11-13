import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../animations/motion.dart';
import '../models/app_state.dart';
import '../models/training_program.dart';
import 'main_navigation_screen.dart';

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
  static const Color _goldLight = Color(
    0xFFF5B800,
  ); // flat brand gold: no gradients
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _red = Color(0xFFEF4444);

  bool _isGenerating = false;
  String _loadingStepText = 'Preparing your personalized plan...';
  String? _errorMessage;

  /// The first week of the program, previewed from today's date.
  late final List<ProgramSession> _firstWeek;

  @override
  void initState() {
    super.initState();
    final state = AppState.instance;
    final now = DateTime.now();
    _firstWeek = TrainingProgram.week(
      now,
      goal: state.fitnessGoal,
      days: state.workoutDays,
      owned: Gear.effective(state.workoutEnvironment, state.equipment),
      sessionDuration: state.sessionDuration,
      start: now,
      months: state.programDurationMonths,
    );
  }

  Future<void> _handleGenerateAndProceed() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _loadingStepText = 'Preparing your personalized plan...';
    });

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

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError(
          'Your login session has expired. Please sign in again.',
        );
      }

      final state = AppState.instance;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fullName': state.fullName,
        'email': user.email ?? '',
        'age': state.age,
        'height': state.heightCm,
        'weight': state.weightKg,
        'fitnessLevel': state.fitnessLevel,
        'gender': state.gender,
        'hasInjuryOrCondition': state.hasInjuryOrCondition,
        'injuryDetails': state.injuryDetails,
        'fitnessGoal': state.fitnessGoal,
        'environment': state.workoutEnvironment,
        'workoutEnvironment': state.workoutEnvironment,
        'programDurationMonths': state.programDurationMonths,
        'workoutDays': state.workoutDays,
        'daysPerWeek': state.workoutDays.length,
        'sessionDuration': state.sessionDuration,
        'setupCompleted': true,
        'equipment': state.equipment.toList()..sort(),
        // A finished setup starts a new program; weeks count from today.
        'programStartedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      state.startProgram();
    } catch (error) {
      debugPrint('Unable to save the completed GrindFit setup: $error');
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _errorMessage = _saveErrorMessage(error);
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(initialIndex: 0),
      ),
    );
  }

  String _saveErrorMessage(Object error) {
    if (error is StateError) return error.message.toString();
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Your account does not have permission to save this profile. Please sign in again.';
        case 'unauthenticated':
          return 'Your login session has expired. Please sign in again.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Could not reach GrindFit. Check that your Wi-Fi has internet access, then try again.';
        default:
          return 'Could not save your profile. Please try again.';
      }
    }
    return 'Could not save your profile. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isGenerating,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: staggered([
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isGenerating
                          ? null
                          : () => Navigator.maybePop(context),
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
                      'Your first week',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This is your starting plan. Each training day works different muscles, '
                      'reps and sets grow week by week, and every 4th week is lighter for recovery. '
                      'You can change today\'s focus or add exercises for the day on the Workouts tab.',
                      style: const TextStyle(
                        color: _gray,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final session in _firstWeek)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border, width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${TrainingProgram.weekdays[session.date.weekday - 1]} • ${session.dayName}',
                              style: const TextStyle(
                                color: _gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            for (
                              var i = 0;
                              i < session.exercises.length;
                              i++
                            ) ...[
                              if (i > 0)
                                const Divider(color: _border, height: 20),
                              _buildPreviewRow(
                                '${i + 1}. ${session.exercises[i].name}',
                                session.exercises[i].detail,
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
                    Pressable(child: _buildActionButton()),
                    const SizedBox(height: 16),
                  ]),
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
          colors: [
            _card,
            Color.alphaBlend(_gold.withValues(alpha: 0.15), _card),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.3), width: 1.2),
        boxShadow: [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: _gold, size: 22),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Personalized GrindFit Plan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Personalized Plan is Ready!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
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
            child: const Icon(
              Icons.warning_amber_rounded,
              color: _gold,
              size: 24,
            ),
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
            boxShadow: [],
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
                          Flexible(
                            child: Text(
                              hasError ? 'Try Again' : 'Go to Home Dashboard',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _bg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasError
                                ? Icons.refresh_rounded
                                : Icons.arrow_forward,
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
        Flexible(
          child: Text(
            details,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: _gold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
