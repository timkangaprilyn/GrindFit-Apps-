import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_state.dart';
import '../models/workout_plan.dart';
import 'notifications_screen.dart';
import 'workout_plan_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _checkBorder = Color(0xFF3F3F44);
  static const Color _gold = Color(0xFFF5B800);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _good = Color(0xFF22C55E);

  // Today's checklist
  final Map<String, bool> _checklist = {
    'Warm-up': false,
    'Workout': false,
    'Stretching': false,
  };

  double _currentWeight = AppState.instance.weightKg;
  double _initialWeight = AppState.instance.weightKg;
  double _targetWeight = AppState.instance.weightKg;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_refreshForAppStateChanges);
    _loadWeightProgress();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_refreshForAppStateChanges);
    super.dispose();
  }

  void _refreshForAppStateChanges() {
    if (mounted) setState(() {});
  }

  Future<void> _loadWeightProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null || !mounted) return;
      setState(() {
        _currentWeight =
            (data['weight'] as num?)?.toDouble() ?? AppState.instance.weightKg;
        _initialWeight =
            (data['startWeight'] as num?)?.toDouble() ?? _currentWeight;
        _targetWeight =
            (data['targetWeight'] as num?)?.toDouble() ?? _currentWeight;
      });
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Could not load weight progress.'),
        ),
      );
    }
  }

  Future<void> _startWorkout() async {
    final state = AppState.instance;
    if (state.hasInjuryOrCondition) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Health and injury reminder',
            style: TextStyle(color: _white, fontWeight: FontWeight.w900),
          ),
          content: Text(
            state.injuryDetails.trim().isEmpty
                ? 'You reported an injury or health condition in your profile. Stop exercising if you feel pain or discomfort, and consult a health professional if needed.'
                : 'Your profile notes: ${state.injuryDetails}. Stop exercising if you feel pain or discomfort, and consult a health professional if needed.',
            style: const TextStyle(color: _gray, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: _gray)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _bg,
              ),
              child: const Text('Continue carefully'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final exercises = WorkoutPlan.forProfile(
      goal: state.fitnessGoal,
      environment: state.workoutEnvironment,
      savedOverrides: state.workoutPlanOverrides,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlanDetailScreen(exercises: exercises),
      ),
    );
  }

  void _viewPlan() {
    final state = AppState.instance;
    final exercises = WorkoutPlan.forProfile(
      goal: state.fitnessGoal,
      environment: state.workoutEnvironment,
      savedOverrides: state.workoutPlanOverrides,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutPlanDetailScreen(exercises: exercises),
      ),
    );
  }

  // Navigation papuntang Recovery kapag pinindot ang Safety Status
  Future<void> _navigateToRecovery() async {
    var recentWorkoutDays = <String>{};
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final since = DateTime.now().subtract(const Duration(days: 3));
        final recent = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('workouts')
            .where(
              'timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(since),
            )
            .get();
        recentWorkoutDays = recent.docs
            .map((doc) {
              final timestamp = doc.data()['timestamp'];
              if (timestamp is! Timestamp) return null;
              final date = timestamp.toDate();
              return DateFormat('yyyy-MM-dd').format(date);
            })
            .whereType<String>()
            .toSet();
      } on FirebaseException catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Could not load recovery details.'),
          ),
        );
        return;
      }
    }

    final workoutCount = recentWorkoutDays.length;
    final reason = workoutCount >= 3
        ? '$workoutCount workouts in the past 4 days.'
        : '$workoutCount workout in the past 4 days.';
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.healing_rounded, color: _gold),
            SizedBox(width: 8),
            Text(
              'Recovery & Safety Center',
              style: TextStyle(
                color: _white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workoutCount >= 3 ? 'Rest day recommended' : 'Recovery check-in',
              style: const TextStyle(
                color: _gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Reason: $reason',
              style: const TextStyle(
                color: _white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use today to recover with enough sleep, hydration, and gentle stretching.',
              style: TextStyle(color: _gray, fontSize: 13.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog para sa manual weight update
  void _showUpdateWeightDialog() {
    final TextEditingController controller = TextEditingController(
      text: _currentWeight.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Progress (Update Weight)',
          style: TextStyle(
            color: _white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: _white),
          decoration: InputDecoration(
            labelText: 'Current Weight (kg)',
            labelStyle: const TextStyle(color: _gray),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: _gold),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _gray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: _bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              final parsed = double.tryParse(controller.text);
              final user = FirebaseAuth.instance.currentUser;
              if (parsed == null || parsed <= 0 || user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid weight and sign in.'),
                  ),
                );
                return;
              }
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                      'weight': parsed,
                      'startWeight': _initialWeight,
                      'weightUpdatedAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                if (!context.mounted) return;
                setState(() => _currentWeight = parsed);
                Navigator.pop(context);
              } on FirebaseException catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.message ?? 'Could not save your weight.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Save',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String todayString = DateFormat('E').format(DateTime.now());

    final String fullName = AppState.instance.fullName.trim();
    final String firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : 'Athlete';

    final String summary = AppState.instance.sessionSummary.isNotEmpty
        ? AppState.instance.sessionSummary
        : '45 min • Strength Focus';

    final int doneCount = _checklist.values.where((v) => v).length;

    final double initialWeight = _initialWeight;
    double totalDiff = initialWeight - _targetWeight;
    double currentLost = initialWeight - _currentWeight;
    double progressValue = totalDiff > 0
        ? (currentLost / totalDiff).clamp(0.0, 1.0)
        : 0.0;
    double remainingKg = (_currentWeight - _targetWeight).clamp(0.0, 99.0);

    return Scaffold(
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
                  colors: [_gold.withAlpha(40), _gold.withAlpha(0)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(firstName),
                  const SizedBox(height: 18),
                  _buildStatsCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'AI RECOMMENDED WORKOUT',
                    action: 'View plan',
                    onAction: _viewPlan,
                  ),
                  const SizedBox(height: 10),
                  _buildWorkoutCard(summary),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: _buildChecklistCard(doneCount)),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 10,
                        child: Column(children: [_buildSafetyCard()]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildManualGoalProgressCard(
                    progressValue: progressValue,
                    remainingKg: remainingKg,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Weekly Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyChart(todayString),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName! 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Let's crush your goals today.",
                style: TextStyle(
                  fontSize: 13.5,
                  color: _gray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _card,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: _white,
                  size: 22,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _buildUnreadNotificationBadge(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnreadNotificationBadge() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'Unable to load the unread notification badge: ${snapshot.error}',
          );
          return const SizedBox.shrink();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildStatsContent(minutes: 0, workouts: 0, streak: 0);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(days: 60)),
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: const Text(
              'Could not load workout statistics. Check your connection and try again.',
              style: TextStyle(color: _gray, fontSize: 13),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 88,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: const Center(child: CircularProgressIndicator(color: _gold)),
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(
          Duration(days: today.weekday - DateTime.monday),
        );
        final workoutDates = <DateTime>[];
        var minutesThisWeek = 0;

        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final rawDate =
              data['timestamp'] ?? data['completedAt'] ?? data['date'];
          final DateTime? date = switch (rawDate) {
            Timestamp value => value.toDate(),
            DateTime value => value,
            String value => DateTime.tryParse(value),
            _ => null,
          };
          if (date == null) continue;

          final workoutDay = DateTime(date.year, date.month, date.day);
          workoutDates.add(workoutDay);
          if (!workoutDay.isBefore(weekStart) && !workoutDay.isAfter(today)) {
            minutesThisWeek += _durationInMinutes(data);
          }
        }

        final scheduledDays = AppState.instance.workoutDays
            .map(
              (day) =>
                  (day.length >= 3 ? day.substring(0, 3) : day).toLowerCase(),
            )
            .toSet();
        var streak = 0;
        for (var offset = 0; offset < 60; offset++) {
          final day = today.subtract(Duration(days: offset));
          final dayLabel = DateFormat('E').format(day).toLowerCase();
          if (!scheduledDays.contains(dayLabel)) continue;
          final completed = workoutDates.any((workoutDay) => workoutDay == day);
          if (day == today && !completed) continue;
          if (!completed) break;
          streak++;
        }

        final workoutsThisWeek = workoutDates
            .where((date) => !date.isBefore(weekStart) && !date.isAfter(today))
            .map((date) => DateFormat('yyyy-MM-dd').format(date))
            .toSet()
            .length;

        return _buildStatsContent(
          minutes: minutesThisWeek,
          workouts: workoutsThisWeek,
          streak: streak,
        );
      },
    );
  }

  int _durationInMinutes(Map<String, dynamic> data) {
    final seconds = data['durationSeconds'];
    if (seconds is num) return (seconds / 60).round();

    final rawDuration = data['duration'];
    if (rawDuration is num) return rawDuration.round();
    if (rawDuration is! String) return 0;

    final value = rawDuration.toLowerCase();
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(value);
    if (match == null) return 0;
    final amount = double.tryParse(match.group(0)!) ?? 0;
    if (value.contains('sec') || value.endsWith('s')) {
      return (amount / 60).round();
    }
    if (value.contains('hour') || value.contains('hr') || value.endsWith('h')) {
      return (amount * 60).round();
    }
    return amount.round();
  }

  Widget _buildStatsContent({
    required int minutes,
    required int workouts,
    required int streak,
  }) {
    final scheduledCount = AppState.instance.workoutDays.length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          _stat(Icons.timer_rounded, 'Total Mins', '${minutes}m', 'This Week'),
          _verticalDivider(),
          _stat(
            Icons.fitness_center_rounded,
            'Workouts',
            '$workouts/$scheduledCount',
            'This Week',
          ),
          _verticalDivider(),
          _stat(Icons.bolt_rounded, 'Streak', '$streak', 'Scheduled Days'),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 56, color: _border);

  Widget _stat(IconData icon, String label, String value, String sub) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _gold, size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _gray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? action,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: _gray,
            ),
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: _gold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkoutCard(String summary) {
    final goal = AppState.instance.fitnessGoal;
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _gold.withAlpha(90), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _gold.withAlpha(30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _card,
                      Color.alphaBlend(_gold.withAlpha(38), _card),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 170,
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.45],
                ).createShader(rect),
                child: Image.asset(
                  'assets/images/goal_hero.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: FractionallySizedBox(
                widthFactor: 0.66,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          WorkoutPlan.titleForGoal(goal),
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          WorkoutPlan.focusForGoal(goal),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: _gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: _gold,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                summary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: _bg,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _startWorkout,
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Start Workout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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

  Widget _buildChecklistCard(int doneCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S CHECKLIST",
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w800,
              color: _gray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$doneCount/${_checklist.length} Completed',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _gold,
            ),
          ),
          const SizedBox(height: 10),
          ..._checklist.entries.map((entry) {
            final done = entry.value;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _checklist[entry.key] = !done),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: done ? _gold : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done ? _gold : _checkBorder,
                          width: 1.6,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: _bg,
                              size: 14,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: done ? _white : _gray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSafetyCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _navigateToRecovery,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withAlpha(70), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SAFETY STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w800,
                    color: _gray,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: _gold, size: 12),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _good.withAlpha(35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: _good,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _good,
                        ),
                      ),
                      Text(
                        'Tap for Recovery',
                        style: TextStyle(
                          fontSize: 11,
                          color: _gray,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualGoalProgressCard({
    required double progressValue,
    required double remainingKg,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FITNESS GOAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _gray,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: _showUpdateWeightDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withAlpha(100)),
                  ),
                  child: const Text(
                    'Log Progress',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _gold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '🏃 Weight Loss',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_currentWeight.toStringAsFixed(1)} kg → ${_targetWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _white,
                ),
              ),
              Text(
                '${remainingKg.toStringAsFixed(1)} kg remaining',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: const Color(0xFF2A2A2D),
              valueColor: const AlwaysStoppedAnimation<Color>(_gold),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Progress: ${(progressValue * 100).toStringAsFixed(1)}% (Manually updated)',
            style: const TextStyle(
              fontSize: 11.5,
              color: _gray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(String todayString) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBarItem('Mon', 40, isHighlight: todayString == 'Mon'),
          _buildBarItem('Tue', 70, isHighlight: todayString == 'Tue'),
          _buildBarItem('Wed', 60, isHighlight: todayString == 'Wed'),
          _buildBarItem('Thu', 100, isHighlight: todayString == 'Thu'),
          _buildBarItem('Fri', 75, isHighlight: todayString == 'Fri'),
          _buildBarItem('Sat', 50, isHighlight: todayString == 'Sat'),
          _buildBarItem('Sun', 70, isHighlight: todayString == 'Sun'),
        ],
      ),
    );
  }

  Widget _buildBarItem(
    String day,
    double heightFactor, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 100,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 14,
            height: heightFactor,
            decoration: BoxDecoration(
              color: isHighlight ? _gold : _gold.withAlpha(77),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight ? _gold : _gray,
          ),
        ),
      ],
    );
  }
}
