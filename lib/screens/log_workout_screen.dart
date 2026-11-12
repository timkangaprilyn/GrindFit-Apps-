import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../animations/motion.dart';
import '../models/app_state.dart';
import '../models/workout_plan.dart';
import 'manual_log_workout_screen.dart';
import 'main_navigation_screen.dart';

import 'package:intl/intl.dart';

class LogWorkoutScreen extends StatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _goldLight = Color(
    0xFFF5B800,
  ); // flat brand gold: no gradients
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

  int _currentExerciseIndex = 0;

  // Kasalukuyang values para sa pinipiling ehersisyo
  int _sets = 3;
  int _reps = 10;
  int _duration = 45;
  String _intensity = 'Moderate';
  final List<String> _intensities = ['Low', 'Moderate', 'High'];

  // Controllers para sa Duration, Weight, at Notes
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSavingPlan = false;

  // Bawat ehersisyo ay may sarili nang nakaimbak na sets, reps, duration, weight, at notes
  late final List<Map<String, dynamic>> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = AppState.instance.recommendedPlan.map((exercise) {
      final sets =
          int.tryParse(
            RegExp(
                  r'(\d+)\s*sets?',
                  caseSensitive: false,
                ).firstMatch(exercise.detail)?.group(1) ??
                '',
          ) ??
          3;
      final reps =
          int.tryParse(
            RegExp(r'(\d+)').firstMatch(exercise.repsLabel)?.group(1) ?? '',
          ) ??
          10;
      final duration =
          int.tryParse(
            RegExp(
                  r'(\d+)\s*(?:s|sec|secs|second|seconds)\b',
                  caseSensitive: false,
                ).firstMatch(exercise.detail)?.group(1) ??
                '',
          ) ??
          45;
      return <String, dynamic>{
        'name': exercise.name,
        'sets': sets,
        'reps': reps,
        'duration': duration,
        'weight': '',
        'intensity': 'Moderate',
        'completed': false,
        'imageUrl': exercise.imageUrl,
      };
    }).toList();
    _loadExerciseValues(_currentExerciseIndex);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadExerciseValues(int index) {
    setState(() {
      _currentExerciseIndex = index;
      _sets = _exercises[index]['sets'];
      _reps = _exercises[index]['reps'];
      _duration = _exercises[index]['duration'];
      _durationController.text = _duration.toString();
      _weightController.text = _exercises[index]['weight'] ?? '';
      _intensity = _exercises[index]['intensity'];
    });
  }

  void _saveCurrentValues() {
    _exercises[_currentExerciseIndex]['sets'] = _sets;
    _exercises[_currentExerciseIndex]['reps'] = _reps;
    _exercises[_currentExerciseIndex]['duration'] =
        int.tryParse(_durationController.text) ?? _duration;
    _exercises[_currentExerciseIndex]['weight'] = _weightController.text;
    _exercises[_currentExerciseIndex]['intensity'] = _intensity;
  }

  Map<String, Map<String, int>> _planOverrides() {
    _saveCurrentValues();
    return {
      for (final exercise in _exercises)
        exercise['name'] as String: {
          'sets': exercise['sets'] as int,
          'reps': exercise['reps'] as int,
          'duration': exercise['duration'] as int,
        },
    };
  }

  Future<void> _savePlanChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showMessage('Sign in before saving workout plan changes.');
      return;
    }

    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration < 1) {
      _showMessage('Enter a valid duration of at least 1 second.');
      return;
    }

    setState(() => _isSavingPlan = true);
    try {
      final state = AppState.instance;
      // Changes apply to today's workout only; the program keeps progressing
      // on its own from tomorrow.
      state.setTodayAdjustments(_planOverrides());
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'todayPlan': state.todayPlanJson,
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Saved for today's workout."),
          backgroundColor: Colors.green,
        ),
      );
      MainNavigationScreen.of(context)?.goToTab(1);
    } on FirebaseException catch (error) {
      _showMessage(
        error.message ?? 'Could not save your workout plan. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSavingPlan = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _gold,
              onPrimary: _bg,
              surface: _card,
              onSurface: _white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _white),
        title: Text(
          _exercises[_currentExerciseIndex]['name'],
          style: const TextStyle(
            color: _white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _border, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: _gold, size: 26),
            tooltip: 'Manual Log',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManualLogWorkoutScreen(
                    exercise: PlanExercise(
                      name: _exercises[_currentExerciseIndex]['name'] as String,
                      detail: '$_sets sets • ${_durationController.text}s',
                      repsLabel: '$_reps reps',
                      muscles: '',
                      equipment: '',
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_currentExerciseIndex + 1} / ${_exercises.length}',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: staggered([
                  ..._exercises.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var ex = entry.value;
                    bool isSelected = idx == _currentExerciseIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _saveCurrentValues();
                          _loadExerciseValues(idx);
                        });
                      },
                      child: AnimatedContainer(
                        duration: Motion.medium,
                        curve: Motion.curve,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? _card : const Color(0xFF171719),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? _gold : _border,
                            width: isSelected ? 1.6 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? Colors.green : _gray,
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${idx + 1}. ${ex['name']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? _white : _gray,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${ex['sets']} sets • ${ex['duration']}s',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _gold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStepperBox('Sets', _sets, (val) {
                          setState(() {
                            _sets = val;
                            _saveCurrentValues();
                          });
                        }),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStepperBox('Reps', _reps, (val) {
                          setState(() {
                            _reps = val;
                            _saveCurrentValues();
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Duration bilang Number Input Field
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Duration (sec)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Enter seconds',
                            hintStyle: TextStyle(color: Color(0xFF4B5563)),
                          ),
                          onChanged: (val) {
                            _saveCurrentValues();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weight (kg) Field
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weight (Optional / kg)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'e.g. 10 kg',
                            hintStyle: TextStyle(color: Color(0xFF4B5563)),
                          ),
                          onChanged: (val) {
                            _saveCurrentValues();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Field
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border, width: 1.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workout Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: _white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: _gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes Field
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border, width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gray,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(color: _white, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText:
                                'Add notes about your workout form or feel...',
                            hintStyle: TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 8),
                  Row(
                    children: _intensities.map((item) {
                      bool isSelected = _intensity == item;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _intensity = item;
                                _saveCurrentValues();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? _gold : _card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? _gold : _border,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? _bg : _white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Save your changes to update this workout plan. Open Workouts to review the saved plan and start a session.',
                    style: TextStyle(color: _gray, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  // Save plan edits here; start sessions from the Workouts tab.
                  SizedBox(
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
                          onTap: _isSavingPlan ? null : _savePlanChanges,
                          child: Center(
                            child: _isSavingPlan
                                ? const CircularProgressIndicator(color: _bg)
                                : const Text(
                                    'Save Workout',
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
                  const SizedBox(height: 30),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Stepper box helper method
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
                  fontWeight: FontWeight.w800,
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
                  const SizedBox(width: 12),
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
