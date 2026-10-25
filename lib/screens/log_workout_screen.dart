import 'package:flutter/material.dart';
import 'workout_complete_screen.dart';
import 'manual_log_workout_screen.dart';
import 'exercise_timer_screen.dart';
import 'workout_plan_details_screen.dart';
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
  static const Color _goldLight = Color(0xFFFFD34D);
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

  // Bawat ehersisyo ay may sarili nang nakaimbak na sets, reps, duration, weight, at notes
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Push Up',
      'sets': 3,
      'reps': 10,
      'duration': 45,
      'weight': '',
      'intensity': 'Moderate',
      'completed': false,
    },
    {
      'name': 'Dumbbell Row',
      'sets': 3,
      'reps': 10,
      'duration': 45,
      'weight': '',
      'intensity': 'Moderate',
      'completed': false,
    },
    {
      'name': 'Shoulder Press',
      'sets': 3,
      'reps': 10,
      'duration': 45,
      'weight': '',
      'intensity': 'Moderate',
      'completed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
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
    _exercises[_currentExerciseIndex]['duration'] = int.tryParse(_durationController.text) ?? _duration;
    _exercises[_currentExerciseIndex]['weight'] = _weightController.text;
    _exercises[_currentExerciseIndex]['intensity'] = _intensity;
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
            fontWeight: FontWeight.w900,
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
                MaterialPageRoute(builder: (_) => const ManualLogWorkoutScreen()),
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
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                    color: ex['completed'] ? Colors.green : Colors.transparent,
                                    border: Border.all(
                                      color: ex['completed'] ? Colors.green : _gray,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ex['completed']
                                      ? const Icon(Icons.check, size: 14, color: _white)
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
                              style: const TextStyle(fontSize: 12, color: _gold, fontWeight: FontWeight.w600),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gray),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 16),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gray),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 16),
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
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gray),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const Icon(Icons.calendar_month_rounded, color: _gold),
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
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gray),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(color: _white, fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Add notes about your workout form or feel...',
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
                  
                  // Start Workout Button
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
                            _saveCurrentValues();
                            
                            List<PlanExercise> customExercises = _exercises.map((ex) {
                              return PlanExercise(
                                name: ex['name'],
                                detail: '${ex['sets']} sets • ${ex['reps']} reps • ${ex['duration']}s',
                                repsLabel: 'reps',
                                muscles: 'General', 
                                equipment: 'bodyweight',
                              );
                            }).toList();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseTimerScreen(
                                  exerciseList: customExercises,
                                  currentIndex: _currentExerciseIndex,
                                ),
                              ),
                            );
                          },
                          child: const Center(
                            child: Text(
                              'Start Workout',
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
                        side: const BorderSide(color: Colors.green, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.green.withValues(alpha: 0.1),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const WorkoutCompleteScreen()),
                        );
                      },
                      child: const Text(
                        'Finish Without Timer',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
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