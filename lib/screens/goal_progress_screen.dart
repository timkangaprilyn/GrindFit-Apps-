import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'main_navigation_screen.dart';

class GoalProgressScreen extends StatefulWidget {
  const GoalProgressScreen({super.key});

  @override
  State<GoalProgressScreen> createState() => _GoalProgressScreenState();
}

class _GoalProgressScreenState extends State<GoalProgressScreen> {
  // Black + Gold + White + Gray palette
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _goldBright = Color(0xFFFFCC1A);
  static const Color _goldLight = Color(0xFFFFD34D);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  // Sub-page index para sa bottom navigation
  final int _currentIndex = 3;

  // State Variables
  String _goalTitle = 'Weight Loss / Maintenance';
  double _startWeight = 75.0; // Simula
  double _currentWeight = 62.0; // Kasalukuyan
  double _targetWeight = 60.0; // Target
  DateTime _lastUpdatedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserGoalsFromFirestore();
  }

  // TAMANG FORMULA: (kasalukuyan - simula) / (target - simula)
  double get _progressValue {
    if (_targetWeight == _startWeight) return 0.0;
    final double progress =
        (_currentWeight - _startWeight) / (_targetWeight - _startWeight);
    return progress.clamp(0.0, 1.0);
  }

  // Kunin ang tunay na data mula sa Firebase Firestore
  Future<void> _fetchUserGoalsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null && mounted) {
            setState(() {
              if (data['fitnessGoal'] != null) {
                _goalTitle = data['fitnessGoal'].toString();
              }
              if (data['startWeight'] is num) {
                _startWeight = (data['startWeight'] as num).toDouble();
              } else if (data['weight'] is num) {
                _startWeight = (data['weight'] as num).toDouble();
              }
              if (data['weight'] is num) {
                _currentWeight = (data['weight'] as num).toDouble();
              }
              if (data['targetWeight'] is num) {
                _targetWeight = (data['targetWeight'] as num).toDouble();
              }
              if (data['updatedAt'] is Timestamp) {
                _lastUpdatedDate = (data['updatedAt'] as Timestamp).toDate();
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching goals: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // I-save ang bagong timbang o goal sa Firestore
  Future<void> _saveUserDataToFirestore({
    double? newWeight,
    double? newStart,
    double? newTarget,
    String? newGoal,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final Map<String, dynamic> updateData = {
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (newWeight != null) updateData['weight'] = newWeight;
        if (newStart != null) updateData['startWeight'] = newStart;
        if (newTarget != null) updateData['targetWeight'] = newTarget;
        if (newGoal != null) updateData['fitnessGoal'] = newGoal;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(updateData, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving data to Firestore: $e');
    }
  }

  // History points para sa Weight Chart
  List<double> get _weightHistory {
    final double dir = _targetWeight >= _startWeight ? 1 : -1;
    final double step = (_currentWeight - _startWeight).abs() / 3;
    return [
      _startWeight,
      _startWeight + (dir * step * 1),
      _startWeight + (dir * step * 2),
      _currentWeight,
    ];
  }

  // Totoong petsa labels (nakaraang mga linggo patungong kasalukuyan)
  List<String> get _dateLabels {
    return List.generate(4, (index) {
      final date = _lastUpdatedDate.subtract(Duration(days: (3 - index) * 7));
      return DateFormat('MMM d').format(date);
    });
  }

  // ───────────────────────── Build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leadingWidth: 68,
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: _white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              )
            : null,
        title: const Text(
          'Goal Progress',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -150,
            right: -130,
            child: IgnorePointer(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _gold.withValues(alpha: 0.16),
                      _gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGoalCard(),
                      const SizedBox(height: 18),
                      _buildWeightChartCard(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildUpdateWeightButton()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildUpdateGoalButton()),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ───────────────────────── Goal Card ─────────────────────────

  Widget _buildGoalCard() {
    final double remaining = (_targetWeight - _currentWeight).abs();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(_gold.withValues(alpha: 0.14), _card),
            _card,
          ],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_goldLight, _gold],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.fitness_center_rounded,
                    color: Colors.black, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _goalTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Updated: ${DateFormat('MMM dd, yyyy').format(_lastUpdatedDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _gray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weightColumn('Start', _startWeight, CrossAxisAlignment.start),
              TweenAnimationBuilder<double>(
                key: ValueKey(_progressValue),
                tween: Tween(begin: 0, end: _progressValue),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(112, 112),
                        painter: _RingPainter(
                          progress: value,
                          track: _tile,
                          start: _gold,
                          end: _goldLight,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(value * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Text(
                            'of goal',
                            style: TextStyle(
                              fontSize: 11,
                              color: _gray,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _weightColumn('Target', _targetWeight, CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _gold.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag_rounded, color: _goldBright, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1)} kg to go (${_currentWeight.toStringAsFixed(1)} kg now)',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightColumn(String label, double kg, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1)} kg',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: _white,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Weight Chart Card ─────────────────────────

  Widget _buildWeightChartCard() {
    final data = _weightHistory;
    final double change = data.last - data.first;
    final bool up = change >= 0;
    final labels = _dateLabels;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Weight Progress (kg)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _gold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      up
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: _goldBright,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${up ? '+' : ''}${change.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _goldBright,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_currentWeight + _targetWeight + _startWeight),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => CustomPaint(
                painter: _WeightChartPainter(
                  data: data,
                  progress: t,
                  gold: _gold,
                  grid: _tile,
                  labelColor: _muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38, right: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  labels.map((lbl) => Text(lbl, style: _axisStyle)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _axisStyle = TextStyle(
    fontSize: 11,
    color: _muted,
    fontWeight: FontWeight.w800,
  );

  // ───────────────────────── Action Buttons ─────────────────────────

  Widget _buildUpdateWeightButton() {
    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_goldLight, _gold],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showUpdateWeightModal(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monitor_weight_outlined,
                    color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text(
                  'Update Weight',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateGoalButton() {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _gold, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: _card,
        ),
        onPressed: () => _showUpdateGoalModal(context),
        icon: const Icon(Icons.edit_rounded, color: _goldBright, size: 18),
        label: const Text(
          'Edit Goal',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _goldBright,
          ),
        ),
      ),
    );
  }

  // ───────────────────────── Bottom Navigation ─────────────────────────

  Widget _buildBottomNav() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MainNavigationScreen(initialIndex: index)),
          );
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: _goldBright,
        unselectedItemColor: _muted,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workouts'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded), label: 'Log'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  // ───────────────────────── Input Decoration Helper ─────────────────────────

  InputDecoration _fieldDecoration({String? hint, IconData? icon}) {
    OutlineInputBorder border(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 15),
      filled: true,
      fillColor: _bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: _gold, size: 22),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_gold, width: 1.5),
    );
  }

  // ───────────────────────── Update Weight Modal ─────────────────────────

  void _showUpdateWeightModal(BuildContext context) {
    final TextEditingController weightController =
        TextEditingController(text: _currentWeight.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 4,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Current Weight',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Log your current weight to recalculate your goal percentage.',
                style: TextStyle(
                  fontSize: 13.5,
                  color: _gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Current Weight (kg)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                cursorColor: _gold,
                style: const TextStyle(
                  fontSize: 16,
                  color: _white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _fieldDecoration(
                  hint: 'e.g. 62.5',
                  icon: Icons.monitor_weight_outlined,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final double? newW = double.tryParse(weightController.text);
                    if (newW != null && newW > 0) {
                      setState(() {
                        _currentWeight = newW;
                        _lastUpdatedDate = DateTime.now();
                      });
                      // Isinasama ang startWeight para hindi ito mag-reset
                      // sa susunod na load.
                      await _saveUserDataToFirestore(
                        newWeight: newW,
                        newStart: _startWeight,
                      );
                    }
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                  },
                  child: const Text(
                    'Save Weight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────────────── Update Goal Modal ─────────────────────────

  void _showUpdateGoalModal(BuildContext context) {
    final TextEditingController targetWeightController =
        TextEditingController(text: _targetWeight.toStringAsFixed(0));
    final TextEditingController startWeightController =
        TextEditingController(text: _startWeight.toStringAsFixed(0));

    final List<String> categories = [
      'Build Muscle',
      'Muscle Gain / Strength',
      'Weight Loss / Maintenance',
      'Maintain Fitness',
    ];
    // Siguraduhing nasa listahan ang kasalukuyang goal (galing Firestore)
    if (!categories.contains(_goalTitle)) {
      categories.add(_goalTitle);
    }
    String selectedCategory = _goalTitle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 4,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Your Fitness Goal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Set a target that keeps you motivated.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: _gray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Goal Category',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: _card,
                      iconEnabledColor: _gold,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _white,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _fieldDecoration(icon: Icons.flag_rounded),
                      items: categories
                          .map((c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Starting Weight (kg)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: startWeightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: _gold,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _white,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'e.g. 75',
                        icon: Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Target Weight (kg)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: targetWeightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      cursorColor: _gold,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _white,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: _fieldDecoration(
                        hint: 'e.g. 60',
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          final double? newStart =
                              double.tryParse(startWeightController.text);
                          final double? newTarget =
                              double.tryParse(targetWeightController.text);

                          final bool validStart = newStart != null && newStart > 0;
                          final bool validTarget =
                              newTarget != null && newTarget > 0;

                          setState(() {
                            _goalTitle = selectedCategory;
                            if (validStart) _startWeight = newStart;
                            if (validTarget) _targetWeight = newTarget;
                            _lastUpdatedDate = DateTime.now();
                          });

                          await _saveUserDataToFirestore(
                            newGoal: selectedCategory,
                            newStart: validStart ? newStart : null,
                            newTarget: validTarget ? newTarget : null,
                          );

                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          'Save Goal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ───────────────────────── Ring Painter ─────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color start;
  final Color end;

  _RingPainter({
    required this.progress,
    required this.track,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 10;
    final Offset center = size.center(Offset.zero);
    final double radius = (math.min(size.width, size.height) - stroke) / 2;
    final Rect arcRect = Rect.fromCircle(center: center, radius: radius);

    final Paint trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final Paint arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: [start, end],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(arcRect);

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.start != start ||
      old.end != end;
}

// ───────────────────────── Weight Chart Painter ─────────────────────────

class _WeightChartPainter extends CustomPainter {
  final List<double> data;
  final double progress;
  final Color gold;
  final Color grid;
  final Color labelColor;

  _WeightChartPainter({
    required this.data,
    required this.progress,
    required this.gold,
    required this.grid,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    const double leftPad = 38;
    const double rightPad = 12;
    const double topPad = 8;
    const double bottomPad = 8;

    final double chartW = size.width - leftPad - rightPad;
    final double chartH = size.height - topPad - bottomPad;

    double minV = data.reduce(math.min);
    double maxV = data.reduce(math.max);
    if ((maxV - minV).abs() < 0.001) {
      minV -= 1;
      maxV += 1;
    }
    final double pad = (maxV - minV) * 0.15;
    minV -= pad;
    maxV += pad;
    final double range = maxV - minV;

    // Grid lines + y labels
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    const int lines = 4;
    for (int i = 0; i < lines; i++) {
      final double y = topPad + chartH * i / (lines - 1);
      canvas.drawLine(
          Offset(leftPad, y), Offset(leftPad + chartW, y), gridPaint);

      final double value = maxV - range * i / (lines - 1);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 10,
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 8, y - tp.height / 2));
    }

    // Points
    final List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      final double x = leftPad + chartW * i / (data.length - 1);
      final double y = topPad + chartH * (1 - (data[i] - minV) / range);
      points.add(Offset(x, y));
    }

    // Animated reveal: clip from left to right
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(
        0, 0, leftPad + chartW * progress + rightPad, size.height));

    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final Offset prev = points[i - 1];
      final Offset curr = points[i];
      final double midX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(midX, prev.dy, midX, curr.dy, curr.dx, curr.dy);
    }

    // Fill sa ilalim ng line
    final Path fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, topPad + chartH)
      ..lineTo(points.first.dx, topPad + chartH)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            gold.withValues(alpha: 0.25),
            gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
    );

    // Line
    canvas.drawPath(
      linePath,
      Paint()
        ..color = gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    final Paint dotFill = Paint()..color = gold;
    final Paint dotRing = Paint()
      ..color = const Color(0xFF1C1C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final Offset p in points) {
      canvas.drawCircle(p, 5, dotFill);
      canvas.drawCircle(p, 5, dotRing);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.gold != gold ||
      old.grid != grid ||
      old.labelColor != labelColor;
}