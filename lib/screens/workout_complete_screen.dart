import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import 'main_navigation_screen.dart';

class WorkoutCompleteScreen extends StatefulWidget {
  const WorkoutCompleteScreen({super.key, this.sessionData});

  final Map<String, dynamic>? sessionData;

  @override
  State<WorkoutCompleteScreen> createState() => _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends State<WorkoutCompleteScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  // State para sa adaptive feedback question
  String _selectedFeedback = 'Just right';
  bool _isSaving = true;
  String? _saveError;
  DocumentReference<Map<String, dynamic>>? _workoutDocument;
  DocumentReference<Map<String, dynamic>>? _notificationDocument;

  @override
  void initState() {
    super.initState();
    _saveWorkout();
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Sign in to save this workout to your history.';
        });
      }
      return;
    }

    try {
      final session = <String, dynamic>{
        ...?widget.sessionData,
        'title': widget.sessionData?['title'] ?? 'Workout Session',
        'workoutName': widget.sessionData?['workoutName'] ?? 'Workout Session',
        'category':
            widget.sessionData?['category'] ??
            AppState.instance.workoutEnvironment,
        'duration': widget.sessionData?['duration'] ?? '0 min',
        'intensity': widget.sessionData?['intensity'] ?? 'Moderate',
        'exercises': widget.sessionData?['exercises'] ?? <dynamic>[],
        'fitnessGoal': AppState.instance.fitnessGoal,
        'feedback': _selectedFeedback,
        'timestamp': widget.sessionData?['timestamp'] is DateTime
            ? Timestamp.fromDate(widget.sessionData!['timestamp'] as DateTime)
            : FieldValue.serverTimestamp(),
      };
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final profileDoc = await userRef.get();
      final rawNotificationSettings = profileDoc
          .data()?['notificationSettings'];
      final notificationSettings = rawNotificationSettings is Map
          ? rawNotificationSettings
          : const <String, dynamic>{};
      final achievementsEnabled = notificationSettings['achievements'] is bool
          ? notificationSettings['achievements'] as bool
          : true;
      final existingWorkoutCount = achievementsEnabled
          ? (await userRef.collection('workouts').count().get()).count ?? 0
          : 0;
      _workoutDocument ??= userRef.collection('workouts').doc();
      _notificationDocument ??= userRef.collection('notifications').doc();
      final batch = FirebaseFirestore.instance.batch()
        ..set(_workoutDocument!, session)
        ..set(_notificationDocument!, {
          'title': 'Workout completed',
          'subtitle':
              'Your ${session['duration']} session is in workout history.',
          'type': 'Updates',
          'route': 'history',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      final totalWorkouts = existingWorkoutCount + 1;
      if (achievementsEnabled &&
          const [1, 5, 10, 25, 50, 100].contains(totalWorkouts)) {
        final achievementRef = userRef
            .collection('notifications')
            .doc('milestone-$totalWorkouts');
        batch.set(achievementRef, {
          'title': 'Workout milestone',
          'subtitle': totalWorkouts == 1
              ? 'You completed your first workout.'
              : 'You have completed $totalWorkouts workouts.',
          'type': 'Achievements',
          'route': 'analytics',
          'isRead': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      AppState.instance.completeWorkoutSession();
      if (mounted) setState(() => _isSaving = false);
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError =
              error.message ?? 'Could not save the workout. Please try again.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'Could not save the workout: $error';
        });
      }
    }
  }

  Future<void> _selectFeedback(String feedback) async {
    setState(() => _selectedFeedback = feedback);
    final document = _workoutDocument;
    if (document == null) return;
    try {
      await document.update({'feedback': feedback});
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not save workout feedback.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save workout feedback: $error')),
      );
    }
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kunin ang pangalan nang direkta mula sa profile / AppState
    final String fullName = AppState.instance.fullName.trim();
    final String firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : 'Athlete';
    final exercises =
        (widget.sessionData?['exercises'] as List<dynamic>?)
            ?.whereType<Map>()
            .map((exercise) => Map<String, dynamic>.from(exercise))
            .toList() ??
        <Map<String, dynamic>>[];
    final totalSets = exercises.fold<int>(
      0,
      (total, exercise) => total + ((exercise['sets'] as num?)?.toInt() ?? 0),
    );
    final totalReps = exercises.fold<int>(0, (total, exercise) {
      final sets = (exercise['sets'] as num?)?.toInt() ?? 0;
      final reps = (exercise['reps'] as num?)?.toInt() ?? 0;
      return total + sets * reps;
    });
    final duration = widget.sessionData?['duration']?.toString() ?? '0 min';
    final title = widget.sessionData?['title']?.toString() ?? 'Workout Session';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _white),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                _goHome();
              }
            },
          ),
        ),
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
                      _gold.withValues(alpha: 0.2),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 10.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        size: 56,
                        color: _gold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Workout Complete!',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Great job, $firstName!',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _gray,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  color: _gold,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$duration • ${exercises.length} exercises',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _gray,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: _border, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMetricItem('Total Sets', '$totalSets'),
                              Container(height: 30, width: 1, color: _border),
                              _buildMetricItem('Total Reps', '$totalReps'),
                              Container(height: 30, width: 1, color: _border),
                              _buildMetricItem('Feedback', _selectedFeedback),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ADAPTIVE FEEDBACK SECTION (Easy, Just right o Hard?)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'How did this workout feel?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Easy, Just right, or Hard? Your answer will be saved with this workout to help adapt your next plan.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _gray,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _buildFeedbackChip('Easy'),
                              const SizedBox(width: 8),
                              _buildFeedbackChip('Just right'),
                              const SizedBox(width: 8),
                              _buildFeedbackChip('Hard'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isSaving)
                      const CircularProgressIndicator(color: _gold)
                    else if (_saveError != null)
                      Column(
                        children: [
                          Text(
                            _saveError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSaving = true;
                                _saveError = null;
                              });
                              _saveWorkout();
                            },
                            child: const Text(
                              'Try again',
                              style: TextStyle(color: _gold),
                            ),
                          ),
                        ],
                      )
                    else
                      const Text(
                        'Workout and feedback saved to your history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: _gray,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    const SizedBox(height: 32),

                    // View Details Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: _card,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                builder: (context) => Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Workout Summary Breakdown',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: _white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (exercises.isEmpty)
                                        const Text(
                                          'No exercise details are available for this session.',
                                          style: TextStyle(color: _gray),
                                        )
                                      else
                                        for (
                                          var index = 0;
                                          index < exercises.length;
                                          index++
                                        ) ...[
                                          _buildDetailRow(
                                            exercises[index]['name']
                                                    ?.toString() ??
                                                'Exercise ${index + 1}',
                                            '${exercises[index]['sets'] ?? 0} sets • '
                                            '${exercises[index]['reps'] ?? 0} reps • '
                                            '${exercises[index]['weight']?.toString().isNotEmpty == true ? '${exercises[index]['weight']} kg' : 'Bodyweight'}'
                                            '${exercises[index]['skipped'] == true ? ' • Skipped' : ''}',
                                          ),
                                          if (index != exercises.length - 1)
                                            const SizedBox(height: 8),
                                        ],
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _gold,
                                            foregroundColor: _bg,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            'Close',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: const Center(
                              child: Text(
                                'View Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _bg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: _card,
                        ),
                        onPressed: _goHome,
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER METHODS
  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _gray,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: _white,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackChip(String label) {
    bool isSelected = _selectedFeedback == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectFeedback(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _gold : const Color(0xFF252830),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? _gold : _border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? _bg : _white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String exercise, String details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171719),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            exercise,
            style: const TextStyle(fontWeight: FontWeight.bold, color: _white),
          ),
          Text(details, style: const TextStyle(color: _gray, fontSize: 12)),
        ],
      ),
    );
  }
}
