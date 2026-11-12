import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Black + Gold + White palette (flat brand gold: no gradients)
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text
  static const Color _hint = Color(0xFF4B5563);

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
    // Guard: an empty plan used to crash here (index 0 of an empty list).
    if (_exercises.isNotEmpty) _loadExerciseValues(_currentExerciseIndex);
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
    if (_exercises.isEmpty) return;
    _exercises[_currentExerciseIndex]['sets'] = _sets;
    _exercises[_currentExerciseIndex]['reps'] = _reps;
    _exercises[_currentExerciseIndex]['duration'] =
        int.tryParse(_durationController.text) ?? _duration;
    _exercises[_currentExerciseIndex]['weight'] = _weightController.text;
    _exercises[_currentExerciseIndex]['intensity'] = _intensity;
  }

  void _selectExercise(int index) {
    if (index < 0 || index >= _exercises.length) return;
    setState(() {
      _saveCurrentValues();
      _loadExerciseValues(index);
    });
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

  void _openManualLog() {
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
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasExercises = _exercises.isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: _white),
        title: const Text(
          "Adjust today's workout",
          style: TextStyle(
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
          if (hasExercises)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: _gold, size: 26),
              tooltip: 'Manual Log',
              onPressed: _openManualLog,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: hasExercises ? _buildEditor() : _buildEmptyState()),
      // Save stays reachable at the bottom instead of the end of a long form.
      bottomNavigationBar: hasExercises ? _buildSaveBar() : null,
    );
  }

  Widget _buildEditor() {
    final current = _exercises[_currentExerciseIndex];
    final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: staggered([
          _sectionLabel(
            'TODAY\'S EXERCISES',
            trailing: '${_currentExerciseIndex + 1} / ${_exercises.length}',
          ),
          _buildExerciseList(),
          const SizedBox(height: 24),

          // Editor for the selected exercise.
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EDITING',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: Motion.medium,
                      child: Text(
                        current['name'] as String,
                        key: ValueKey(_currentExerciseIndex),
                        style: const TextStyle(
                          color: _white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _navButton(
                Icons.chevron_left_rounded,
                'Previous exercise',
                _currentExerciseIndex > 0
                    ? () => _selectExercise(_currentExerciseIndex - 1)
                    : null,
              ),
              const SizedBox(width: 6),
              _navButton(
                Icons.chevron_right_rounded,
                'Next exercise',
                _currentExerciseIndex < _exercises.length - 1
                    ? () => _selectExercise(_currentExerciseIndex + 1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _fieldBox(
                  label: 'Duration',
                  icon: Icons.timer_outlined,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor: _gold,
                    style: _valueStyle,
                    decoration: _bareInput(hint: 'Seconds', suffix: 'sec'),
                    onChanged: (val) {
                      _saveCurrentValues();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _fieldBox(
                  label: 'Weight (optional)',
                  icon: Icons.fitness_center_rounded,
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    cursorColor: _gold,
                    style: _valueStyle,
                    decoration: _bareInput(hint: 'e.g. 10', suffix: 'kg'),
                    onChanged: (val) {
                      _saveCurrentValues();
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Intensity',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _gray,
            ),
          ),
          const SizedBox(height: 8),
          _buildIntensityPicker(),
          const SizedBox(height: 28),

          // Session-wide details.
          _sectionLabel('SESSION DETAILS'),
          Material(
            color: _card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: _border, width: 1.2),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _selectDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: _gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Workout Date', style: _labelStyle),
                          const SizedBox(height: 2),
                          Text(formattedDate, style: _valueStyle),
                        ],
                      ),
                    ),
                    const Text(
                      'Change',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _fieldBox(
            label: 'Notes (optional)',
            icon: Icons.sticky_note_2_outlined,
            child: TextField(
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              cursorColor: _gold,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: _white, fontSize: 14, height: 1.4),
              decoration: _bareInput(
                hint: 'Add notes about your workout form or feel...',
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.info_outline_rounded, size: 16, color: _gray),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Save your changes to update this workout plan. Open Workouts to review the saved plan and start a session.',
                  style: TextStyle(color: _gray, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ───────────────────────── Pieces ─────────────────────────

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: _gray,
  );

  static const TextStyle _valueStyle = TextStyle(
    color: _white,
    fontWeight: FontWeight.w800,
    fontSize: 16,
  );

  InputDecoration _bareInput({String? hint, String? suffix}) => InputDecoration(
    isDense: true,
    border: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(vertical: 4),
    hintText: hint,
    hintStyle: const TextStyle(color: _hint, fontWeight: FontWeight.w500),
    suffixText: suffix,
    suffixStyle: const TextStyle(color: _gray, fontSize: 13),
  );

  Widget _sectionLabel(String text, {String? trailing}) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1.4,
              color: _gray,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
      ],
    ),
  );

  /// All exercises in one grouped card. The selected row is marked with a
  /// gold number badge (the old green check read as "completed").
  Widget _buildExerciseList() {
    return Material(
      color: _card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border, width: 1.2),
      ),
      child: Column(
        children: [
          for (final (idx, ex) in _exercises.indexed) ...[
            if (idx != 0)
              const Divider(height: 1, thickness: 1, color: _border),
            _exerciseRow(idx, ex),
          ],
        ],
      ),
    );
  }

  Widget _exerciseRow(int idx, Map<String, dynamic> ex) {
    final isSelected = idx == _currentExerciseIndex;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Exercise ${idx + 1}, ${ex['name']}',
      child: InkWell(
        onTap: () => _selectExercise(idx),
        child: AnimatedContainer(
          duration: Motion.medium,
          curve: Motion.curve,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _gold.withValues(alpha: 0.08) : null,
            border: Border(
              left: BorderSide(
                color: isSelected ? _gold : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Motion.medium,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _gold : _tile,
                ),
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _bg : _gray,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${ex['name']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? _white : _gray,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${ex['sets']} × ${ex['reps']} • ${ex['duration']}s',
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? _gold : _gray,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navButton(IconData icon, String tooltip, VoidCallback? onPressed) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: _card,
        foregroundColor: _white,
        disabledForegroundColor: _hint,
        disabledBackgroundColor: _card,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _border),
        ),
      ),
    );
  }

  Widget _fieldBox({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: _gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _labelStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildIntensityPicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: _intensities.map((item) {
          final isSelected = _intensity == item;
          return Expanded(
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '$item intensity',
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _intensity = item;
                      _saveCurrentValues();
                    });
                  },
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.curve,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? _bg : _gray,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Stepper box helper method (44dp buttons for easy tapping)
  Widget _buildStepperBox(String label, int value, Function(int) onChanged) {
    Widget stepButton(IconData icon, String tip, VoidCallback? onTap) =>
        IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: _tile,
            foregroundColor: _white,
            disabledForegroundColor: _hint,
            disabledBackgroundColor: _tile,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: '$label: $value',
                  liveRegion: true,
                  child: Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _white,
                    ),
                  ),
                ),
              ),
              stepButton(
                Icons.remove,
                'Decrease $label',
                value > 1 ? () => onChanged(value - 1) : null,
              ),
              const SizedBox(width: 6),
              stepButton(
                Icons.add,
                'Increase $label',
                () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isSavingPlan ? null : _savePlanChanges,
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _bg,
                disabledBackgroundColor: _gold.withValues(alpha: 0.5),
                disabledForegroundColor: _bg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: _isSavingPlan
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: _bg,
                        strokeWidth: 2.6,
                      ),
                    )
                  : const Text('Save Workout'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withValues(alpha: 0.10),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: _gold,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No exercises to adjust',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Generate today's workout first, then come back to change sets, reps and duration.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _gray, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
