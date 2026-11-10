import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import 'main_navigation_screen.dart';
import '../services/offline_store.dart';

class ManualLogWorkoutScreen extends StatefulWidget {
  const ManualLogWorkoutScreen({super.key, this.exercise});

  final PlanExercise? exercise;

  @override
  State<ManualLogWorkoutScreen> createState() => _ManualLogWorkoutScreenState();
}

class _ManualLogWorkoutScreenState extends State<ManualLogWorkoutScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  String _selectedExercise = 'Push Up';
  int _sets = 3;
  int _reps = 10;
  final TextEditingController _durationController = TextEditingController(
    text: '45',
  );
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _workoutDate = DateTime.now();
  String _intensity = 'Moderate';
  String _environment = AppState.instance.workoutEnvironment;
  bool _isSaving = false;
  String? _workoutId;
  bool _isAddingToPlan = false;

  final List<String> _exercises = [
    'Push Up',
    'Dumbbell Row',
    'Shoulder Press',
    'Squats',
  ];

  @override
  void initState() {
    super.initState();
    final recommendations = AppState.instance.recommendedPlan;
    for (final exercise in recommendations) {
      if (!_exercises.contains(exercise.name)) _exercises.add(exercise.name);
    }
    final exercise = widget.exercise;
    if (exercise == null) return;
    if (!_exercises.contains(exercise.name)) _exercises.add(exercise.name);
    _selectedExercise = exercise.name;
    _sets =
        int.tryParse(
          RegExp(
                r'(\d+)\s*sets?',
                caseSensitive: false,
              ).firstMatch(exercise.detail)?.group(1) ??
              '',
        ) ??
        3;
    _reps =
        int.tryParse(
          RegExp(r'\d+').firstMatch(exercise.repsLabel)?.group(0) ?? '',
        ) ??
        10;
    _durationController.text =
        RegExp(
          r'(\d+)\s*(?:s|sec|secs|second|seconds)\b',
          caseSensitive: false,
        ).firstMatch(exercise.detail)?.group(1) ??
        '45';
  }

  @override
  void dispose() {
    _durationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _workoutDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null && mounted) {
      setState(() => _workoutDate = selected);
    }
  }

  Future<void> _addExerciseToPlan() async {
    final user = FirebaseAuth.instance.currentUser;
    final durationSeconds = int.tryParse(_durationController.text.trim());
    if (user == null) {
      _showMessage('Sign in before updating your workout plan.');
      return;
    }
    if (durationSeconds == null || durationSeconds < 1) {
      _showMessage('Enter a valid workout duration of at least 1 second.');
      return;
    }

    setState(() => _isAddingToPlan = true);
    try {
      final state = AppState.instance;
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final profileDoc = await userRef.get();
      final storedOverrides = profileDoc.data()?['workoutPlanOverrides'];
      final planOverrides = storedOverrides is Map
          ? Map<String, dynamic>.from(storedOverrides)
          : Map<String, dynamic>.from(state.workoutPlanOverrides);
      final scope = '${state.fitnessGoal}|${state.workoutEnvironment}';
      final scopeData = planOverrides[scope] is Map
          ? Map<String, dynamic>.from(planOverrides[scope] as Map)
          : <String, dynamic>{};
      final values = {
        'sets': _sets,
        'reps': _reps,
        'duration': durationSeconds,
      };

      String normalize(String name) => name
          .toLowerCase()
          .replaceAll('bodyweight', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '')
          .replaceAll(RegExp(r's$'), '');

      final normalizedSelection = normalize(_selectedExercise);
      final baseExercises = WorkoutPlan.forProfile(
        goal: state.fitnessGoal,
        environment: state.workoutEnvironment,
      );
      final matchingBaseExercise = baseExercises.where(
        (exercise) => normalize(exercise.name) == normalizedSelection,
      );

      if (matchingBaseExercise.isNotEmpty) {
        scopeData[matchingBaseExercise.first.name] = values;
      } else {
        final customExercises =
            (scopeData['customExercises'] as List?)
                ?.whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList() ??
            <Map<String, dynamic>>[];
        final matchingCustomIndex = customExercises.indexWhere(
          (exercise) =>
              exercise['name'] is String &&
              normalize(exercise['name'] as String) == normalizedSelection,
        );
        final customExercise = {'name': _selectedExercise, ...values};
        if (matchingCustomIndex == -1) {
          customExercises.add(customExercise);
        } else {
          customExercises[matchingCustomIndex] = customExercise;
        }
        scopeData['customExercises'] = customExercises;
      }

      planOverrides[scope] = scopeData;
      await userRef.set({
        'workoutPlanOverrides': planOverrides,
      }, SetOptions(merge: true));
      state.replaceWorkoutPlanOverrides(planOverrides);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedExercise added to your workout plan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(initialIndex: 1),
        ),
        (route) => false,
      );
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ??
            'Could not update your workout plan. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isAddingToPlan = false);
    }
  }

  Future<void> _saveWorkout() async {
    final user = FirebaseAuth.instance.currentUser;
    final durationSeconds = int.tryParse(_durationController.text.trim());
    if (user == null) {
      _showMessage('Sign in before saving a workout.');
      return;
    }
    if (durationSeconds == null || durationSeconds < 1) {
      _showMessage('Enter a valid workout duration in seconds.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final date = DateTime(
        _workoutDate.year,
        _workoutDate.month,
        _workoutDate.day,
      );
      final exercises = [
        {
          'name': _selectedExercise,
          'sets': _sets,
          'reps': _reps,
          'durationSeconds': durationSeconds,
          'weight': _weightController.text.trim(),
        },
      ];
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      _workoutId ??= userRef.collection('workouts').doc().id;
      await OfflineStore.instance.write(
        'users/${user.uid}/workouts/$_workoutId',
        {
          'title': _selectedExercise,
          'workoutName': _selectedExercise,
          'category': _environment,
          'durationSeconds': durationSeconds,
          'duration': '${(durationSeconds / 60).ceil()} min',
          'intensity': _intensity,
          'exercises': exercises,
          'notes': _notesController.text.trim(),
          'timestamp': date,
          'createdAt': DateTime.now(),
          'manual': true,
        },
      );
      await OfflineStore.instance.write(
        'users/${user.uid}/notifications/workout-$_workoutId',
        {
          'title': 'Workout logged',
          'subtitle': 'Your workout is saved on this device and will sync when connected.',
          'type': 'Updates',
          'route': 'history',
          'isRead': false,
          'timestamp': DateTime.now(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout saved on this device. Syncs when connected.'),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(initialIndex: 3),
        ),
        (route) => false,
      );
    } catch (_) {
      _showMessage('Could not save the workout on this device. Please retry.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _white),
        title: const Text(
          'Log Workout',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _border, height: 1.0),
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
                    _gold.withValues(alpha: 0.15),
                    _gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exercise',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _gray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedExercise,
                        isExpanded: true,
                        dropdownColor: _card,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: _gray,
                        ),
                        items: _exercises.map((String value) {
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
                            setState(() => _selectedExercise = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add to Workout Plan adds this exercise to your recommended session. Log Completed Workout saves it as a finished session in Analytics.',
                    style: TextStyle(color: _gray, fontSize: 12, height: 1.4),
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
                  const Text(
                    'Duration (sec)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _gray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: _white),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 45',
                        hintStyle: TextStyle(color: _gray),
                        border: InputBorder.none,
                        suffixText: 'seconds',
                        suffixStyle: TextStyle(color: _gray),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldTitle('Workout Date'),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today, color: _gold),
                    label: Text(
                      DateFormat('MMM d, yyyy').format(_workoutDate),
                      style: const TextStyle(color: _white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _border),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldTitle('Weight (optional, kg)'),
                  _textEntry(_weightController, hint: 'e.g. 10'),
                  const SizedBox(height: 16),
                  _fieldTitle('Notes'),
                  _textEntry(
                    _notesController,
                    hint: 'Add notes about this workout',
                    maxLines: 3,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: _gray,
                        ),
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
                            setState(() => _intensity = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Environment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _gray,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _environment,
                        isExpanded: true,
                        dropdownColor: _card,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: _gray,
                        ),
                        items: ['Gym', 'Home (no equipment)', 'Outdoor'].map((
                          String value,
                        ) {
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
                            setState(() => _environment = newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isAddingToPlan || _isSaving
                          ? null
                          : _addExerciseToPlan,
                      icon: _isAddingToPlan
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: _bg,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.playlist_add_rounded),
                      label: const Text(
                        'Add to Workout Plan',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Save a completed session separately for history and analytics.
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
                          onTap: _isSaving || _isAddingToPlan
                              ? null
                              : _saveWorkout,
                          child: Center(
                            child: _isSaving
                                ? const CircularProgressIndicator(color: _bg)
                                : const Text(
                                    'Log Completed Workout',
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: _gray,
      ),
    ),
  );

  Widget _textEntry(
    TextEditingController controller, {
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: _white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _gray),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildStepperBox(String label, int value, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.remove, size: 16, color: _white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      onChanged(value + 1);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, size: 16, color: _white),
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
