import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../animations/motion.dart';
import '../models/app_state.dart';
import '../models/workout_insights.dart';
import '../widgets/workout_insights_card.dart';
import '../widgets/analytics_cloud_sync.dart';
import 'workout_history_screen.dart';
import 'goal_progress_screen.dart';
import 'log_workout_screen.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  static const Color _bg = Color(0xFF121212);
  static const Color _card = Color(0xFF1C1C1E);
  static const Color _tile = Color(0xFF2A2A2D);
  static const Color _border = Color(0xFF2E2E31);
  static const Color _grid = Color(0xFF2A2A2D);
  static const Color _gold = Color(0xFFD3A72F);
  static const Color _goldBright = Color(0xFFE0BC61);
  static const Color _goldLight = Color(0xFFE8CB7A);
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF);
  static const Color _muted = Color(0xFF6B7280);

  bool _isWeekly = true;
  int? _selectedBar;
  User? _user;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _profileStream;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _workoutStream;

  @override
  void initState() {
    super.initState();
    _subscribeToWorkoutData();
  }

  void _subscribeToWorkoutData() {
    _user = FirebaseAuth.instance.currentUser;
    final user = _user;
    if (user == null) {
      _profileStream = null;
      _workoutStream = null;
      return;
    }

    final userDocument = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    _profileStream = userDocument.snapshots(includeMetadataChanges: true);
    _workoutStream = userDocument
        .collection('workouts')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            _subtractMonths(DateTime.now(), 12),
          ),
        )
        .orderBy('timestamp')
        .snapshots(includeMetadataChanges: true);
  }

  void _setPeriod(bool weekly) {
    if (_isWeekly == weekly) return;
    setState(() {
      _isWeekly = weekly;
      _selectedBar = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _user == null
            ? _buildDataState(
                title: 'Sign in to view analytics',
                message: 'Workout analytics are available for your account.',
                icon: Icons.person_outline_rounded,
              )
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _profileStream,
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.hasError) {
                    return _buildRetryState(profileSnapshot.error);
                  }
                  if (profileSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  final profile = profileSnapshot.data?.data();
                  final programMonths = _programDuration(profile);
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _workoutStream,
                    builder: (context, workoutSnapshot) {
                      if (workoutSnapshot.hasError) {
                        return _buildRetryState(workoutSnapshot.error);
                      }
                      if (workoutSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildLoadingState();
                      }

                      final workouts =
                          workoutSnapshot.data?.docs
                              .map((doc) => doc.data())
                              .toList() ??
                          const <Map<String, dynamic>>[];
                      final analytics = _buildAnalytics(
                        workouts,
                        programMonths: programMonths,
                        profile: profile,
                      );
                      final rawDays = profile?['workoutDays'];
                      final days = rawDays is List
                          ? rawDays.map((d) => d.toString())
                          : AppState.instance.workoutDays;
                      const names = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      final created = profile?['createdAt'];
                      final insights = WorkoutInsights(
                        now: DateTime.now(),
                        workouts: workouts
                            .where((w) => _workoutDate(w) != null)
                            .map(
                              (w) => InsightWorkout(
                                _workoutDate(w)!,
                                _durationInMinutes(w),
                              ),
                            ),
                        scheduledWeekdays: days
                            .map(
                              (d) =>
                                  names.indexWhere(
                                    (name) => d.toLowerCase().startsWith(
                                      name.toLowerCase(),
                                    ),
                                  ) +
                                  1,
                            )
                            .toSet(),
                        joinedAt: created is Timestamp
                            ? created.toDate()
                            : null,
                      );
                      final checkInToday =
                          profile?['checkInDate'] ==
                          DateTime.now().toIso8601String().substring(0, 10);
                      final lowRecovery =
                          checkInToday &&
                          ((profile?['sleepHours'] as num? ?? 8) < 6 ||
                              (profile?['energyLevel'] as num? ?? 3) <= 2);
                      return _buildDashboard(
                        analytics,
                        insights,
                        lowRecovery,
                        workoutSnapshot.data?.metadata.isFromCache == true ||
                            profileSnapshot.data?.metadata.isFromCache ==
                                true ||
                            workoutSnapshot.data?.metadata.hasPendingWrites ==
                                true ||
                            profileSnapshot.data?.metadata.hasPendingWrites ==
                                true,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDashboard(
    _WorkoutAnalytics analytics,
    WorkoutInsights insights,
    bool lowRecovery,
    bool fromCache,
  ) {
    final periodLabel = _isWeekly ? 'this week' : 'this month';
    final avgDuration = analytics.periodSessions == 0
        ? '—'
        : '${analytics.averageDuration.round()} min';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: staggered([
          _buildHeader(),
          const SizedBox(height: 20),
          _buildPeriodToggle(),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Total Sessions',
                  value: '${analytics.periodSessions}',
                  caption: periodLabel,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.timer_outlined,
                  label: 'Avg. Duration',
                  value: avgDuration,
                  caption: 'per session',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildFrequencyCard(analytics.frequency),
          const SizedBox(height: 18),
          if (fromCache) ...[
            const Text(
              'Offline / cached logs · estimates may change after sync',
              style: TextStyle(color: _gray, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          WorkoutInsightsCard(insights: insights, lowRecovery: lowRecovery),
          const SizedBox(height: 8),
          AnalyticsCloudSync(
            key: ValueKey(_user!.uid),
            ownerUid: _user!.uid,
            insights: insights,
            sourceCached: fromCache,
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDurationTrendCard(
                  analytics.durationTrend,
                  analytics.trendCounts,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildIntensityTrendCard(
                  analytics.intensityTrend,
                  analytics.trendCounts,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalProgressScreen()),
              );
            },
            child: _buildProgressToGoalCard(analytics),
          ),
          const SizedBox(height: 18),
          _buildAchievementsCard(analytics),
          const SizedBox(height: 18),
          if (analytics.totalWorkouts == 0)
            _buildNoWorkoutsPrompt()
          else
            _buildHistoryButton(),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: _gold));
  }

  Widget _buildRetryState(Object? error) {
    return _buildDataState(
      title: 'Analytics unavailable',
      message: 'Could not load workout data. Check your connection and retry.',
      icon: Icons.cloud_off_rounded,
      action: TextButton.icon(
        onPressed: () => setState(_subscribeToWorkoutData),
        icon: const Icon(Icons.refresh_rounded, color: _gold),
        label: const Text('Retry', style: TextStyle(color: _goldBright)),
      ),
    );
  }

  Widget _buildDataState({
    required String title,
    required String message,
    required IconData icon,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _gold),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gray, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 12), action],
          ],
        ),
      ),
    );
  }

  Widget _buildNoWorkoutsPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Icon(Icons.fitness_center_rounded, color: _gold, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Your analytics start with your first workout',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Log a session to see your real training trends and progress.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _gray, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogWorkoutScreen()),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Log a Workout'),
          ),
        ],
      ),
    );
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final monthIndex = date.year * 12 + date.month - 1 - months;
    final year = monthIndex ~/ 12;
    final month = monthIndex % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(
      year,
      month,
      math.min(date.day, lastDay),
      date.hour,
      date.minute,
      date.second,
    );
  }

  int _programDuration(Map<String, dynamic>? profile) {
    final savedDuration = profile?['programDurationMonths'];
    final months = savedDuration is num
        ? savedDuration.toInt()
        : AppState.instance.programDurationMonths;
    return const [3, 6, 12].contains(months) ? months : 3;
  }

  DateTime? _workoutDate(Map<String, dynamic> workout) {
    final timestamp = workout['timestamp'];
    if (timestamp is Timestamp) return timestamp.toDate().toLocal();
    if (timestamp is DateTime) return timestamp.toLocal();
    if (timestamp is String) return DateTime.tryParse(timestamp)?.toLocal();
    return null;
  }

  int _durationInMinutes(Map<String, dynamic> workout) {
    final duration = workout['duration'];
    if (duration is num) return math.max(0, duration.round());
    if (duration is String) {
      final hours = RegExp(
        r'(\d+)\s*h(?:ours?)?(?:\s*(\d+)\s*m(?:in(?:utes?)?)?)?',
        caseSensitive: false,
      ).firstMatch(duration);
      if (hours != null) {
        return (int.tryParse(hours.group(1)!) ?? 0) * 60 +
            (int.tryParse(hours.group(2) ?? '') ?? 0);
      }
      final match = RegExp(r'\d+').firstMatch(duration);
      if (match != null) return int.tryParse(match.group(0)!) ?? 0;
    }
    return 0;
  }

  Set<String> _exerciseNames(Map<String, dynamic> workout) {
    final names = <String>{};

    void addExercise(dynamic exercise) {
      final name = exercise is String
          ? exercise
          : exercise is Map
          ? exercise['name']?.toString() ?? exercise['exercise']?.toString()
          : null;
      if (name != null && name.trim().isNotEmpty) {
        names.add(name.trim().toLowerCase());
      }
    }

    final exercises = workout['exercises'];
    if (exercises is Iterable) {
      for (final exercise in exercises) {
        addExercise(exercise);
      }
    } else if (exercises is Map) {
      for (final exercise in exercises.values) {
        addExercise(exercise);
      }
    } else {
      final exerciseNames = workout['exerciseNames'];
      if (exerciseNames is Iterable) {
        for (final exercise in exerciseNames) {
          addExercise(exercise);
        }
      } else {
        addExercise(workout['exercise']);
      }
    }
    return names;
  }

  double _intensityValue(Map<String, dynamic> workout) {
    switch (workout['feedback']?.toString().toLowerCase()) {
      case 'easy':
        return 1;
      case 'just right':
        return 2;
      case 'hard':
        return 3;
    }

    final intensity = workout['intensity'];
    if (intensity is num) return intensity.toDouble().clamp(1, 3).toDouble();
    switch (intensity?.toString().toLowerCase()) {
      case 'low':
      case 'light':
        return 1;
      case 'high':
        return 3;
      default:
        return 2;
    }
  }

  _WorkoutAnalytics _buildAnalytics(
    List<Map<String, dynamic>> workouts, {
    required int programMonths,
    required Map<String, dynamic>? profile,
  }) {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final periodStart = _isWeekly ? weekStart : monthStart;
    final programStart = _subtractMonths(now, programMonths);
    final validWorkouts = workouts
        .map((workout) => (workout: workout, date: _workoutDate(workout)))
        .where((entry) => entry.date != null)
        .toList();
    final periodWorkouts = validWorkouts
        .where(
          (entry) =>
              !entry.date!.isBefore(periodStart) && !entry.date!.isAfter(now),
        )
        .toList();
    final programWorkouts = validWorkouts
        .where(
          (entry) =>
              !entry.date!.isBefore(programStart) && !entry.date!.isAfter(now),
        )
        .toList();

    final bucketCount = _isWeekly
        ? 7
        : DateTime(now.year, now.month + 1, 0).day;
    final frequency = List<int>.filled(bucketCount, 0);
    final durationTotals = List<double>.filled(bucketCount, 0);
    final intensityTotals = List<double>.filled(bucketCount, 0);
    final trendCounts = List<int>.filled(bucketCount, 0);

    for (final entry in periodWorkouts) {
      final date = entry.date!;
      final bucket = _isWeekly ? date.weekday - 1 : date.day - 1;
      if (bucket < 0 || bucket >= bucketCount) continue;
      frequency[bucket]++;
      durationTotals[bucket] += _durationInMinutes(entry.workout);
      intensityTotals[bucket] += _intensityValue(entry.workout);
      trendCounts[bucket]++;
    }

    final durationTrend = List<double>.generate(
      bucketCount,
      (index) => trendCounts[index] == 0
          ? 0
          : durationTotals[index] / trendCounts[index],
    );
    final intensityTrend = List<double>.generate(
      bucketCount,
      (index) => trendCounts[index] == 0
          ? 0
          : intensityTotals[index] / trendCounts[index],
    );
    final durationTotal = periodWorkouts.fold<int>(
      0,
      (total, entry) => total + _durationInMinutes(entry.workout),
    );
    final configuredDays = profile?['workoutDays'];
    final workoutDaysPerWeek =
        configuredDays is List && configuredDays.isNotEmpty
        ? configuredDays.length
        : AppState.instance.workoutDays.length;
    final programTargetSessions =
        (programMonths * 30.4375 / 7 * workoutDaysPerWeek).round();
    final workoutDates =
        validWorkouts
            .where((entry) => !entry.date!.isAfter(now))
            .map(
              (entry) => DateTime(
                entry.date!.year,
                entry.date!.month,
                entry.date!.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final distinctExercises = validWorkouts
        .expand((entry) => _exerciseNames(entry.workout))
        .toSet()
        .length;

    var streakDays = 0;
    if (workoutDates.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      final mostRecent = workoutDates.first;
      if (mostRecent == today ||
          mostRecent == today.subtract(const Duration(days: 1))) {
        var expected = mostRecent;
        for (final workoutDay in workoutDates) {
          if (workoutDay != expected) break;
          streakDays++;
          expected = expected.subtract(const Duration(days: 1));
        }
      }
    }

    return _WorkoutAnalytics(
      periodSessions: periodWorkouts.length,
      averageDuration: periodWorkouts.isEmpty
          ? 0
          : durationTotal / periodWorkouts.length,
      frequency: frequency,
      durationTrend: durationTrend,
      intensityTrend: intensityTrend,
      trendCounts: trendCounts,
      programMonths: programMonths,
      programSessions: programWorkouts.length,
      programTargetSessions: programTargetSessions,
      totalWorkouts: validWorkouts.length,
      streakDays: streakDays,
      distinctExercises: distinctExercises,
    );
  }

  Widget _buildHeader() {
    final canGoBack = Navigator.of(context).canPop();
    return Row(
      children: [
        if (canGoBack) ...[
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded, color: _white),
          ),
          const SizedBox(width: 4),
        ],
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track your training progress',
                style: TextStyle(
                  color: _gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleTab('Weekly', _isWeekly, () => _setPeriod(true)),
          ),
          Expanded(
            child: _buildToggleTab(
              'Monthly',
              !_isWeekly,
              () => _setPeriod(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? _gold : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.black : _gray,
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 20}) => BoxDecoration(
    color: _card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _border, width: 0.8),
  );

  Widget _iconTile(IconData icon, {double size = 36, double iconSize = 18}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: _gold, size: iconSize),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconTile(icon),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  softWrap: true,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _gray,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            style: const TextStyle(
              fontSize: 11.5,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyCard(List<int> values) {
    final List<String> labels = _isWeekly
        ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
        : List.generate(values.length, (index) => '${index + 1}');

    final int defaultIndex = _isWeekly
        ? DateTime.now().weekday - 1
        : DateTime.now().day - 1;
    final int selected = (_selectedBar ?? defaultIndex).clamp(
      0,
      values.length - 1,
    );

    final int maxVal = values.reduce(math.max);
    final int maxY = math.max(4, (((maxVal + 1) / 2).ceil()) * 2);
    final int step = maxY ~/ 2;
    const double plotH = 130;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout Frequency',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sessions per day',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${labels[selected]} · ${values[selected]}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            key: ValueKey('bars_$_isWeekly'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    height: plotH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (int k = 0; k <= 2; k++)
                          Positioned(
                            left: 0,
                            right: 6,
                            bottom: plotH * k / 2 - 7,
                            child: Text(
                              '${step * k}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: _muted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: plotH,
                          child: Stack(
                            children: [
                              for (int k = 0; k <= 2; k++)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: plotH * k / 2,
                                  child: Container(
                                    height: 1,
                                    color: k == 0
                                        ? const Color(0xFF3A3A3F)
                                        : _grid,
                                  ),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (int i = 0; i < values.length; i++)
                                    Expanded(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            setState(() => _selectedBar = i),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: _buildBar(
                                            height:
                                                values[i] / maxY * plotH * t,
                                            width: _isWeekly ? 18 : 5,
                                            selected: i == selected,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (int i = 0; i < labels.length; i++)
                              Expanded(
                                child: Text(
                                  _isWeekly ||
                                          i == 0 ||
                                          i == labels.length - 1 ||
                                          (i + 1) % 5 == 0
                                      ? labels[i]
                                      : '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: _isWeekly ? 11 : 8,
                                    fontWeight: FontWeight.w800,
                                    color: i == selected ? _goldBright : _muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required double height,
    required double width,
    required bool selected,
  }) {
    return Container(
      width: width,
      height: math.max(height, 0),
      decoration: BoxDecoration(
        color: selected ? _gold : _gold.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildDurationTrendCard(List<double> data, List<int> counts) {
    final populated = [
      for (var index = 0; index < counts.length; index++)
        if (counts[index] > 0) index,
    ];
    if (populated.isEmpty) {
      return _buildTrendCard(
        title: 'Duration Trend',
        valueText: '—',
        deltaText: 'No sessions yet',
        up: true,
        data: data,
        chartKey: 'duration_$_isWeekly',
        hasData: false,
      );
    }

    final first = populated.first;
    final last = populated.last;
    final diff = data[last] - data[first];
    final up = diff >= 0;
    return _buildTrendCard(
      title: 'Duration Trend',
      valueText: '${data[last].round()} min',
      deltaText: '${up ? '+' : ''}${diff.toInt()} min',
      up: diff >= 0,
      data: data,
      chartKey: 'duration_$_isWeekly',
    );
  }

  Widget _buildIntensityTrendCard(List<double> data, List<int> counts) {
    final populated = [
      for (var index = 0; index < counts.length; index++)
        if (counts[index] > 0) index,
    ];
    if (populated.isEmpty) {
      return _buildTrendCard(
        title: 'Intensity Trend',
        valueText: '—',
        deltaText: 'No sessions yet',
        up: true,
        data: data,
        chartKey: 'intensity_$_isWeekly',
        hasData: false,
      );
    }

    final totalCount = counts.fold<int>(0, (total, value) => total + value);
    final weightedTotal = List<int>.generate(
      data.length,
      (index) => index,
    ).fold<double>(0, (total, index) => total + data[index] * counts[index]);
    final avg = weightedTotal / totalCount;
    final String level = avg < 1.7
        ? 'Low'
        : avg < 2.5
        ? 'Moderate'
        : 'High';
    final diff = data[populated.last] - data[populated.first];
    return _buildTrendCard(
      title: 'Intensity Trend',
      valueText: level,
      deltaText: 'Avg ${avg.toStringAsFixed(1)}/3',
      up: diff >= 0,
      data: data,
      chartKey: 'intensity_$_isWeekly',
    );
  }

  Widget _buildTrendCard({
    required String title,
    required String valueText,
    required String deltaText,
    required bool up,
    required List<double> data,
    required String chartKey,
    bool hasData = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _gray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            valueText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 15,
                color: _goldBright,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  deltaText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 64,
            width: double.infinity,
            child: hasData
                ? TweenAnimationBuilder<double>(
                    key: ValueKey(chartKey),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => CustomPaint(
                      painter: _SmoothLinePainter(
                        data: data,
                        color: _gold,
                        gridColor: _grid,
                        progress: t,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      'No workout data',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToGoalCard(_WorkoutAnalytics analytics) {
    final progress = analytics.programTargetSessions == 0
        ? 0.0
        : (analytics.programSessions / analytics.programTargetSessions)
              .clamp(0.0, 1.0)
              .toDouble();
    final remainingSessions = math.max(
      0,
      analytics.programTargetSessions - analytics.programSessions,
    );
    final progressCaption = remainingSessions == 0
        ? '${analytics.programMonths}-month program target reached'
        : '$remainingSessions sessions to go in your ${analytics.programMonths}-month plan';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(76, 76),
                    painter: _RingPainter(
                      progress: value,
                      track: _tile,
                      start: _gold,
                      end: _goldLight,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress to Goal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${analytics.programSessions} / ${analytics.programTargetSessions} sessions',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  progressCaption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _gray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _muted, size: 26),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(_WorkoutAnalytics analytics) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAchievementItem(
                  Icons.local_fire_department_rounded,
                  '${analytics.streakDays} Day',
                  'Streak',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAchievementItem(
                  Icons.bolt_rounded,
                  '${analytics.totalWorkouts}',
                  '12-Mo Workouts',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildAchievementItem(
                  Icons.fitness_center_rounded,
                  '${analytics.distinctExercises}',
                  'Exercises',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _tile,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _gold, size: 21),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: _white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _gray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return Material(
      color: _card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _border, width: 0.8),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _iconTile(Icons.history_rounded, size: 40, iconSize: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'View Full Workout History',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _goldBright,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _goldBright,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutAnalytics {
  const _WorkoutAnalytics({
    required this.periodSessions,
    required this.averageDuration,
    required this.frequency,
    required this.durationTrend,
    required this.intensityTrend,
    required this.trendCounts,
    required this.programMonths,
    required this.programSessions,
    required this.programTargetSessions,
    required this.totalWorkouts,
    required this.streakDays,
    required this.distinctExercises,
  });

  final int periodSessions;
  final double averageDuration;
  final List<int> frequency;
  final List<double> durationTrend;
  final List<double> intensityTrend;
  final List<int> trendCounts;
  final int programMonths;
  final int programSessions;
  final int programTargetSessions;
  final int totalWorkouts;
  final int streakDays;
  final int distinctExercises;
}

class _SmoothLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color gridColor;
  final double progress;

  _SmoothLinePainter({
    required this.data,
    required this.color,
    required this.gridColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int k = 0; k < 3; k++) {
      final y = size.height * k / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double maxVal = data.reduce(math.max);
    final double minVal = data.reduce(math.min);
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);

    const double xPad = 5;
    final double topPad = size.height * 0.14;
    final double usableHeight = size.height - topPad * 2;
    final double stepX = (size.width - xPad * 2) / (data.length - 1);

    final List<Offset> pts = [
      for (int i = 0; i < data.length; i++)
        Offset(
          xPad + stepX * i,
          size.height - topPad - ((data[i] - minVal) / range) * usableHeight,
        ),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final cx = (a.dx + b.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(0, -8, size.width * progress, size.height + 16),
    );

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (progress > 0.98) {
      final end = pts.last;
      canvas.drawCircle(end, 3.5, Paint()..color = color);
      canvas.drawCircle(end, 1.6, Paint()..color = const Color(0xFF1C1C1E));
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothLinePainter old) =>
      old.data != data || old.color != color || old.progress != progress;
}

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
    const double stroke = 9;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    canvas.drawArc(
      arcRect,
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..shader = SweepGradient(
          colors: [start, end],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.start != start || old.end != end;
}
