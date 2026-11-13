import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../animations/fade_slide_in.dart';
import '../animations/motion.dart';
import '../models/app_state.dart';
import '../models/meal_plan.dart';
import '../models/meal_recommendation.dart';
import '../models/training_program.dart';
import '../models/workout_plan.dart';
import 'manual_log_workout_screen.dart';
import 'meal_recommendations_screen.dart';
import '../widgets/workout_image.dart';
import '../widgets/exercise_actions.dart';
import '../services/offline_store.dart';
import '../services/ai_workout_service.dart';
import '../services/meal_preferences_store.dart';
import '../services/network_status.dart';

/// Black + Gold + White palette (same colors as before, shared by the
/// helper widgets at the bottom of this file).
class _C {
  static const Color bg = Color(0xFF121212); // Charcoal background
  static const Color card = Color(0xFF1C1C1E); // Card surface
  static const Color border = Color(0xFF2E2E31);
  static const Color gold = Color(0xFFF5B800); // Gold highlight
  static const Color white = Colors.white;
  static const Color gray = Color(0xFF9CA3AF); // Secondary text
  static const Color warn = Colors.orangeAccent; // Budget warnings
}

/// Type scale used across the screen so every section reads the same way.
class _T {
  static const overline = TextStyle(
    color: _C.gold,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
  );
  static const h1 = TextStyle(
    color: _C.white,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static const h2 = TextStyle(
    color: _C.white,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const label = TextStyle(
    color: _C.white,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const body = TextStyle(color: _C.gray, fontSize: 13, height: 1.45);
  static const caption = TextStyle(color: _C.gray, fontSize: 12, height: 1.4);
}

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final GlobalKey _workoutKey = GlobalKey();
  String? _budgetError;
  bool _saving = false;
  static final _focuses = [
    TrainingProgram.programFocus,
    TrainingProgram.fullBodyFocus,
    'Upper Body',
    'Lower Body',
    'Chest at Triceps',
    'Back at Biceps',
    'Shoulders',
    'Legs at Glutes',
    'Core',
    'Cardio',
    'No Equipment',
    'Limited Mobility',
  ];

  int _selectedTab = 0; // 0: Today, 1: This Week, 2: Next Week

  @override
  void initState() {
    super.initState();
    _requestController.text = AppState.instance.workoutRequest;
    _budgetController.text = '${AppState.instance.mealBudget}';
    AppState.instance.addListener(_refreshForAppStateChanges);
    NetworkStatus.instance.addListener(_refreshForAppStateChanges);
    _loadMealPreferences();
  }

  /// Uses the diet filters saved on this device so the meal plan below
  /// matches the Meal Plan screen.
  Future<void> _loadMealPreferences() async {
    String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return;
    }
    if (uid == null) return;
    final saved = await MealPreferencesStore.readLocal(uid);
    if (saved != null && mounted) {
      AppState.instance.setMealPreferences(saved);
    }
  }

  @override
  void dispose() {
    _requestController.dispose();
    _budgetController.dispose();
    AppState.instance.removeListener(_refreshForAppStateChanges);
    NetworkStatus.instance.removeListener(_refreshForAppStateChanges);
    super.dispose();
  }

  void _refreshForAppStateChanges() {
    if (mounted) setState(() {});
  }

  Future<void> _savePreferences(Map<String, dynamic> values) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await OfflineStore.instance.saveProfile(values);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save preferences on this device.'),
          ),
        );
      }
    }
  }

  Future<void> _saveBuilder(
    String focus, {
    bool generate = false,
    bool offline = false,
  }) async {
    if (_saving) return;
    final request = _requestController.text.trim();
    if (request.length > 500) return;
    final buildsPlan = generate || offline;
    if (buildsPlan && !await _applyBudget()) return;
    setState(() => _saving = true);
    AppState.instance.updateWorkoutRequest(request, focus);
    await _savePreferences({'workoutRequest': request, 'workoutFocus': focus});
    if (generate && NetworkStatus.instance.offline) {
      // No internet: build the on-device plan instead of waiting.
      offline = true;
      generate = false;
    }
    if (offline) await _useOfflineWorkout();
    if (generate) {
      try {
        final generated = await AiWorkoutService().generate().timeout(
          const Duration(seconds: 8),
        );
        final state = AppState.instance;
        state.setGeneratedPlan(generated.plan, 'Personalized online plan');
        await _savePreferences({
          'generatedPlan': generated.plan.map((e) => e.toMap()).toList(),
          'generatedContext': state.generatedContext,
          'planSource': state.planSource,
          'exerciseSwaps': <String, String>{},
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(generated.reason)));
        }
      } catch (_) {
        await _useOfflineWorkout(automatic: true);
      }
    }
    if (mounted) setState(() => _saving = false);
    if (buildsPlan && mounted) {
      // The builder sits above the workout, so bring the new plan into view.
      _scrollToWorkout();
      final meals = AppState.instance.todayMealPlan();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            meals.budgetTooLow
                ? 'Workout ready. Meal plan uses the cheapest options (about ₱${meals.cheapestCost.round()}/day).'
                : 'Workout and meal plan ready: about ₱${meals.cost.round()} of your ₱${meals.budget} budget.',
          ),
        ),
      );
    }
  }

  void _scrollToWorkout() {
    if (_selectedTab != 0) setState(() => _selectedTab = 0);
    final target = _workoutKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: Motion.slow,
      curve: Motion.curve,
    );
  }

  /// Reads the food budget field; returns false when it is not valid.
  Future<bool> _applyBudget() async {
    final value = int.tryParse(_budgetController.text.trim());
    if (value == null ||
        value < MealPlanner.minBudget ||
        value > MealPlanner.maxBudget) {
      setState(
        () => _budgetError =
            'Enter ₱${MealPlanner.minBudget} to ₱${MealPlanner.maxBudget}',
      );
      return false;
    }
    setState(() => _budgetError = null);
    if (value != AppState.instance.mealBudget) {
      AppState.instance.clearMealChoices();
      await saveMealBudget(value);
    }
    return true;
  }

  Future<void> _useOfflineWorkout({bool automatic = false}) async {
    final state = AppState.instance;
    state.useOfflineWorkout();
    await _savePreferences({
      'generatedPlan': <Map<String, dynamic>>[],
      'generatedContext': '',
      'planSource': state.planSource,
      'exerciseSwaps': <String, String>{},
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          automatic
              ? 'Online recommendations are unavailable. Your personalized offline workout is ready.'
              : 'Your personalized offline workout is ready. No internet needed.',
        ),
      ),
    );
  }

  Future<void> _showCheckIn() async {
    var sleep = AppState.instance.sleepHours;
    var energy = AppState.instance.energyLevel;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _C.card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Daily check-in', style: _T.h2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your sleep and energy adjust today's workout.",
                style: _T.caption,
              ),
              const SizedBox(height: 20),
              _sliderLabel('Sleep', '$sleep hours'),
              Slider(
                value: sleep.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                label: '$sleep h',
                activeColor: _C.gold,
                inactiveColor: _C.border,
                onChanged: (v) => setDialogState(() => sleep = v.round()),
              ),
              const SizedBox(height: 8),
              _sliderLabel('Energy', '$energy / 5'),
              Slider(
                value: energy.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$energy',
                activeColor: _C.gold,
                inactiveColor: _C.border,
                onChanged: (v) => setDialogState(() => energy = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _C.gray),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: _primaryStyle(height: 44),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    AppState.instance.updateCheckIn(sleep, energy);
    await _savePreferences({
      'sleepHours': sleep,
      'energyLevel': energy,
      'checkInDate': AppState.instance.checkInDate,
    });
  }

  static Widget _sliderLabel(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: _T.label),
      Text(
        value,
        style: const TextStyle(
          color: _C.gold,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Future<void> _showSwap(PlanExercise exercise) async {
    final choices = WorkoutPlan.alternativesFor(
      exercise,
      environment: AppState.instance.workoutEnvironment,
    );
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching alternative in this workout setting.'),
        ),
      );
      return;
    }
    final choice = await showModalBottomSheet<PlanExercise>(
      context: context,
      backgroundColor: _C.card,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          children: [
            const Text('Replace exercise', style: _T.h2),
            const SizedBox(height: 4),
            Text(
              'Pick an alternative for ${exercise.name}.',
              style: _T.caption,
            ),
            const SizedBox(height: 12),
            for (final option in choices)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.name, style: _T.label),
                subtitle: Text(
                  '${option.muscles} • ${option.equipment}',
                  style: _T.caption,
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: _C.gold,
                ),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    AppState.instance.swapExercise(exercise.name, choice.name);
    await _savePreferences({'exerciseSwaps': AppState.instance.exerciseSwaps});
  }

  void _showFormGuide(PlanExercise exercise) =>
      showExerciseForm(context, exercise);

  @override
  Widget build(BuildContext context) {
    final session = AppState.instance.currentSession;

    // Consistent default goal across screens
    final String goal = AppState.instance.fitnessGoal.isNotEmpty
        ? AppState.instance.fitnessGoal
        : "Muscle Gain / Strength";

    // Alamin kung pwede pang mag-pop (kung binuksan ito mula sa ibang screen gaya ng notification)
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Mag-aadjust ang leading depende kung galing sa push navigation o tab
        automaticallyImplyLeading: canPop,
        titleSpacing: canPop ? 0 : 20,
        leading: canPop
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _C.white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Personalized Workout Recommendations',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: _C.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: _C.border, height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: staggered([
              _buildPersonalization(),
              const SizedBox(height: 20),
              _buildProgramHeader(session, goal),
              const SizedBox(height: 28),
              _buildWorkoutSection(session),
              const SizedBox(height: 28),
              _buildMealSuggestions(),
            ]),
          ),
        ),
      ),
    );
  }

  // ---- Program overview ----

  Widget _buildProgramHeader(ProgramSession session, String goal) {
    final state = AppState.instance;
    final progress = (session.weekNumber / session.totalWeeks)
        .clamp(0.0, 1.0)
        .toDouble();
    final percent = (progress * 100).round();
    final onDevice = state.generatedContext != state.planContext;

    return _Surface(
      padding: const EdgeInsets.all(20),
      borderColor: _C.gold.withValues(alpha: .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GOAL • ${goal.toUpperCase()}', style: _T.overline),
          const SizedBox(height: 10),
          Text(session.weekLabel, style: _T.h1),
          const SizedBox(height: 2),
          Text('${state.durationLabel} program', style: _T.body),
          const SizedBox(height: 16),
          Semantics(
            label: 'Program progress',
            value: '$percent percent',
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: Motion.slow,
                      curve: Motion.curve,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: _C.gold,
                        backgroundColor: _C.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: _C.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${WorkoutPlan.titleForGoal(goal)} is tailored to your goal and workout setting.',
            style: _T.body,
          ),
          if (session.isLighterWeek) ...[
            const SizedBox(height: 12),
            const _Notice(
              icon: Icons.spa_outlined,
              text: 'Lighter week: fewer sets and reps so your body can recover before the next, harder block.',
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(
                icon: onDevice
                    ? Icons.phone_android_rounded
                    : Icons.cloud_done_outlined,
                label: onDevice
                    ? 'On-device plan • Available offline'
                    : state.planSource,
              ),
              if (NetworkStatus.instance.offline)
                const _StatusPill(
                  icon: Icons.wifi_off_rounded,
                  label: 'Offline',
                  color: _C.warn,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Workout: Today / This Week / Next Week ----

  Widget _buildWorkoutSection(ProgramSession session) {
    return Column(
      key: _workoutKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WORKOUT', style: _T.overline),
        const SizedBox(height: 10),
        _SegmentedTabs(
          labels: const ['Today', 'This Week', 'Next Week'],
          selected: _selectedTab,
          onChanged: (i) => setState(() => _selectedTab = i),
        ),
        const SizedBox(height: 20),
        if (_selectedTab == 0)
          ..._buildTodayView(session)
        else
          KeyedSubtree(
            key: ValueKey(_selectedTab),
            child: _buildWeekView(_selectedTab == 1 ? 0 : 1),
          ),
      ],
    );
  }

  List<Widget> _buildTodayView(ProgramSession session) {
    final state = AppState.instance;
    final exercises = state.recommendedPlan;
    final notices = [
      if (state.needsRecovery)
        'Low sleep or energy today: a gentle mobility session is recommended.',
      if (state.adaptationReason.isNotEmpty) state.adaptationReason,
    ];

    return [
      _buildTodayHeader(session, exercises.length),
      const SizedBox(height: 18),
      _buildFocusPicker(),
      const SizedBox(height: 18),
      for (final notice in notices)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _Notice(icon: Icons.bedtime_outlined, text: notice),
        ),
      if (exercises.isEmpty)
        const _EmptyState(
          icon: Icons.fitness_center_rounded,
          title: 'No exercises yet',
          message: "Generate a workout below to fill today's session.",
        )
      else
        // Re-keyed when the plan changes so new cards animate in.
        KeyedSubtree(
          key: ValueKey(exercises.map((e) => e.name).join('|')),
          child: Column(
            children: [
              for (final (index, exercise) in exercises.indexed)
                FadeSlideIn(
                  delay: Motion.step * index.clamp(0, 8),
                  duration: Motion.slow,
                  offset: const Offset(0, .06),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Pressable(
                      child: _buildExerciseCard(exercise, index),
                    ),
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 6),
      OutlinedButton.icon(
        style: _outlinedStyle(),
        onPressed: state.needsRecovery ? null : _showAddExercise,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add exercise for today'),
      ),
      const SizedBox(height: 8),
      Text(
        state.needsRecovery
            ? 'Adding exercises is paused while today is a recovery session.'
            : 'Added exercises are for today only. Tomorrow follows your plan again.',
        style: _T.caption,
      ),
    ];
  }

  static String _focusLabel(String focus) => switch (focus) {
    TrainingProgram.programFocus => "Today's plan",
    TrainingProgram.fullBodyFocus => 'Full Body',
    _ => focus.replaceAll(' at ', ' & '),
  };

  static String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${TrainingProgram.weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  Future<void> _persistTodayPlan() =>
      _savePreferences({'todayPlan': AppState.instance.todayPlanJson});

  Widget _buildTodayHeader(ProgramSession session, int count) {
    final focus = AppState.instance.workoutFocus;
    final custom = focus != TrainingProgram.programFocus;
    final title = custom
        ? 'Today • ${_focusLabel(focus)}'
        : session.isToday
        ? 'Today • ${session.dayName}'
        : 'Rest day today';
    final subtitle = custom
        ? 'A one-day change. Your weekly plan continues tomorrow.'
        : session.isToday
        ? '${session.weekLabel}${session.isLighterWeek ? ' • Lighter week' : ''}'
        : 'Next session: ${_dateLabel(session.date)} • ${session.dayName}. Want to train anyway? Here it is.';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: _T.h2),
              const SizedBox(height: 4),
              Text(subtitle, style: _T.caption),
            ],
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 12),
          _StatusPill(
            icon: Icons.format_list_numbered_rounded,
            label: '$count ${count == 1 ? 'exercise' : 'exercises'}',
          ),
        ],
      ],
    );
  }

  Widget _buildFocusPicker() {
    final state = AppState.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's focus", style: _T.label),
        const SizedBox(height: 4),
        const Text(
          "Today's plan follows your weekly schedule. Pick another focus to change today's workout only.",
          style: _T.caption,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final focus in _focuses)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _choiceChip(
                    label: _focusLabel(focus),
                    selected: state.workoutFocus == focus,
                    onSelected: _saving ? null : (_) => _saveBuilder(focus),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(int weekOffset) {
    final sessions = AppState.instance.weekSessions(weekOffset);
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;
    if (sessions.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No training days scheduled.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weekOffset == 0 ? 'This week' : 'Next week'} • ${sessions.first.weekLabel}',
          style: _T.h2,
        ),
        const SizedBox(height: 4),
        Text(
          sessions.first.isLighterWeek
              ? 'Lighter week for recovery. The next block starts harder.'
              : 'Each training day works different muscles, and the numbers grow week by week.',
          style: _T.caption,
        ),
        const SizedBox(height: 16),
        for (final (index, session) in sessions.indexed)
          FadeSlideIn(
            delay: Motion.step * index,
            duration: Motion.slow,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildDayCard(session, isToday(session.date)),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCard(ProgramSession session, bool today) {
    final weekday = TrainingProgram.weekdays[session.date.weekday - 1];
    final shortDay = weekday.length > 3 ? weekday.substring(0, 3) : weekday;
    return _Surface(
      padding: const EdgeInsets.all(14),
      borderColor: today ? _C.gold : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block: quick to scan down the week.
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: today ? _C.gold : _C.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  shortDay.toUpperCase(),
                  style: TextStyle(
                    color: today ? _C.bg : _C.gray,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.date.day}',
                  style: TextStyle(
                    color: today ? _C.bg : _C.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.dayName,
                        style: const TextStyle(
                          color: _C.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (today)
                      const Text(
                        'Today',
                        style: TextStyle(
                          color: _C.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                for (final exercise in session.exercises)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: const TextStyle(
                              color: _C.white,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          exercise.detail.split(' • ').take(2).join(' • '),
                          style: const TextStyle(
                            color: _C.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Today-only extras and equipment ----

  Future<void> _showAddExercise() async {
    final state = AppState.instance;
    final groups = TrainingProgram.addable(
      goal: state.fitnessGoal,
      owned: state.ownedEquipment,
      exclude: state.recommendedPlan.map((e) => e.name).toSet(),
    );
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _C.card,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text('Add exercise for today', style: _T.h2),
            const SizedBox(height: 4),
            Text(
              'Matched to your ${state.fitnessGoal} goal and ${Gear.describe(state.ownedEquipment).toLowerCase()}. For today only.',
              style: _T.caption,
            ),
            for (final (label, items) in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 4),
                child: Text(label.toUpperCase(), style: _T.overline),
              ),
              for (final exercise in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise.name, style: _T.label),
                  subtitle: Text(
                    '${exercise.muscles} • ${exercise.equipmentLabel}',
                    style: _T.caption,
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: _C.gold,
                  ),
                  onTap: () => Navigator.pop(context, exercise.name),
                ),
            ],
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    state.addTodayExtra(picked);
    await _persistTodayPlan();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$picked added to today\'s workout.')),
    );
  }

  Future<void> _removeTodayExtra(String name) async {
    AppState.instance.removeTodayExtra(name);
    await _persistTodayPlan();
  }

  Future<void> _editEquipment() async {
    final state = AppState.instance;
    final hadGym = state.equipment.contains(Gear.gym);
    final gymSetting = state.workoutEnvironment.toLowerCase().contains('gym');
    var selected = {...state.equipment}..remove(Gear.gym);
    final saved = await showModalBottomSheet<Set<String>>(
      context: context,
      // Scroll-controlled so a long equipment list never pushes the chips or
      // the Save button off-screen.
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _C.card,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('What equipment do you have?', style: _T.h2),
                  const SizedBox(height: 4),
                  Text(
                    selected.isEmpty
                        ? 'Nothing selected: bodyweight only.'
                        : '${selected.length} selected. Workouts only use what you select.',
                    style: _T.caption,
                  ),
                  if (gymSetting) ...[
                    const SizedBox(height: 12),
                    const _Notice(
                      icon: Icons.fitness_center_rounded,
                      text: 'Your workout setting is a gym, so gym equipment stays included.',
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: [
                      for (final (id, label) in Gear.options)
                        if (id != Gear.gym)
                          FilterChip(
                            label: Text(label),
                            selected: selected.contains(id),
                            showCheckmark: true,
                            checkmarkColor: _C.gold,
                            backgroundColor: _C.bg,
                            selectedColor: _C.gold.withValues(alpha: .16),
                            side: BorderSide(
                              color: selected.contains(id)
                                  ? _C.gold
                                  : _C.border,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 8,
                            ),
                            labelStyle: TextStyle(
                              color: selected.contains(id) ? _C.gold : _C.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                            onSelected: (on) => setSheet(() {
                              selected = {...selected};
                              on ? selected.add(id) : selected.remove(id);
                            }),
                          ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(foregroundColor: _C.gray),
                      onPressed: selected.isEmpty
                          ? null
                          : () => setSheet(() => selected = <String>{}),
                      child: const Text('Clear all (bodyweight only)'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: _primaryStyle(),
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('Save equipment'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (saved == null) return;
    // Keep the gym marker if it was there, so saving here never drops it.
    state.updateEquipment(hadGym ? {...saved, Gear.gym} : saved);
    await _savePreferences({'equipment': state.equipment.toList()..sort()});
  }

  Widget _buildExerciseCard(PlanExercise exercise, int index) {
    final addedToday = AppState.instance.isTodayExtra(exercise.name);
    return _Surface(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 4),
      borderColor: addedToday ? _C.gold.withValues(alpha: .45) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: WorkoutImage(
                      imageUrl: exercise.imageUrl ?? '',
                      exerciseName: exercise.name,
                      backgroundColor: _C.bg,
                      iconColor: _C.gold,
                      iconSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order number: the list is the order to train in.
                      Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: _C.gray,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.white,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        exercise.detail,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _C.gold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.muscles} • ${exercise.equipment}',
                        style: _T.caption,
                      ),
                      if (addedToday) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _C.gold.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Added by you • today only',
                            style: TextStyle(
                              color: _C.gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: _C.border),
          // Labeled actions are easier to find than a column of bare icons.
          Row(
            children: [
              Expanded(
                child: Wrap(
                  children: [
                    _cardAction(
                      icon: Icons.edit_note_rounded,
                      label: 'Log',
                      tooltip: 'Log this exercise',
                      primary: true,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ManualLogWorkoutScreen(exercise: exercise),
                        ),
                      ),
                    ),
                    _cardAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Swap',
                      tooltip: 'Replace exercise',
                      onPressed: () => _showSwap(exercise),
                    ),
                    _cardAction(
                      icon: Icons.info_outline_rounded,
                      label: 'Form',
                      tooltip: 'Form guide',
                      onPressed: () => _showFormGuide(exercise),
                    ),
                  ],
                ),
              ),
              if (addedToday)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: _C.gray,
                  ),
                  tooltip: 'Remove from today',
                  onPressed: () => _removeTodayExtra(exercise.name),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardAction({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onPressed,
    bool primary = false,
  }) => Tooltip(
    message: tooltip,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: primary ? _C.gold : _C.white.withValues(alpha: .85),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
  );

  // ---- Plan builder ----

  Widget _buildPersonalization() {
    final state = AppState.instance;
    final offline = NetworkStatus.instance.offline;
    final checkedIn =
        state.checkInDate ==
        DateTime.now().toLocal().toIso8601String().substring(0, 10);

    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('PLAN BUILDER', style: _T.overline),
          const SizedBox(height: 8),
          const Text('Build your plan', style: _T.h2),
          const SizedBox(height: 6),
          Text(
            'Get today\'s workout and meal plan. Uses your ${state.workoutEnvironment} setting, ${state.workoutDays.length} days/week and ${state.sessionDuration} sessions.',
            style: _T.body,
          ),
          const SizedBox(height: 18),
          _SettingTile(
            icon: Icons.handyman_outlined,
            title: 'Equipment',
            value: Gear.describe(
              Gear.effective(state.workoutEnvironment, state.equipment),
            ),
            // Always tappable so equipment can be picked in any setting.
            onTap: _editEquipment,
            trailing: const Text(
              'Edit',
              style: TextStyle(
                color: _C.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _SettingTile(
            icon: Icons.bedtime_outlined,
            title: 'Daily check-in',
            value: checkedIn
                ? 'Sleep ${state.sleepHours}h • Energy ${state.energyLevel}/5'
                : 'Daily sleep and energy check-in',
            onTap: _showCheckIn,
            trailing: const Icon(Icons.chevron_right_rounded, color: _C.gold),
          ),
          const SizedBox(height: 22),
          const Text('Goal or limits', style: _T.label),
          const SizedBox(height: 8),
          TextField(
            controller: _requestController,
            maxLength: 500,
            minLines: 3,
            maxLines: 3,
            cursorColor: _C.gold,
            style: const TextStyle(color: _C.white, fontSize: 14),
            decoration: _inputDecoration(
              hint: 'Describe your goal or limits in your own words',
            ),
          ),
          const SizedBox(height: 14),
          const Text('Food budget per day', style: _T.label),
          const SizedBox(height: 4),
          const Text(
            'For breakfast, lunch, dinner and a snack. Meals and grams are matched to your goal and this budget.',
            style: _T.caption,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            cursorColor: _C.gold,
            style: const TextStyle(
              color: _C.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            onChanged: (_) => setState(() => _budgetError = null),
            decoration: _inputDecoration(
              prefixText: '₱ ',
              suffixText: 'per day',
              errorText: _budgetError,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in MealPlanner.budgetPresets)
                _presetChip(preset),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: _primaryStyle(),
            onPressed: _saving
                ? null
                : () => _saveBuilder(state.workoutFocus, generate: true),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: _C.bg,
                    ),
                  )
                : Icon(
                    offline
                        ? Icons.cloud_off_rounded
                        : Icons.fitness_center_rounded,
                    size: 20,
                  ),
            label: Text(
              _saving
                  ? 'Building…'
                  : offline
                  ? 'Generate offline workout & meal plan'
                  : 'Generate workout & meal plan',
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: _C.gray,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No internet or online service unavailable? An offline workout is built automatically.',
                  style: _T.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(int preset) {
    final active = _budgetController.text.trim() == '$preset';
    return ActionChip(
      label: Text('₱$preset'),
      backgroundColor: active ? _C.gold.withValues(alpha: .16) : _C.bg,
      side: BorderSide(color: active ? _C.gold : _C.border),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: active ? _C.gold : _C.white,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
      onPressed: () => setState(() {
        _budgetController.text = '$preset';
        _budgetError = null;
      }),
    );
  }

  // ---- Meal plan ----

  Future<void> _openMealPlan() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MealRecommendationsScreen()),
  );

  Future<void> _editMealBudget() async {
    final value = await showMealBudgetSheet(
      context,
      AppState.instance.mealBudget,
    );
    if (value == null) return;
    AppState.instance.clearMealChoices();
    await saveMealBudget(value);
    if (mounted) setState(() => _budgetController.text = '$value');
  }

  Widget _buildMealSuggestions() {
    final state = AppState.instance;
    final plan = state.todayMealPlan();
    final target = plan.target;
    final warn = plan.budgetTooLow || plan.overBudget;

    return _Surface(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NUTRITION', style: _T.overline),
                    SizedBox(height: 8),
                    Text("Today's meal plan", style: _T.h2),
                  ],
                ),
              ),
              Tooltip(
                message: 'Change daily budget',
                child: OutlinedButton.icon(
                  onPressed: _editMealBudget,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('₱${plan.budget}/day'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _C.gold,
                    side: BorderSide(color: _C.gold.withValues(alpha: .5)),
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(icon: Icons.flag_outlined, label: target.goal),
              _StatusPill(
                icon: Icons.local_fire_department_outlined,
                label: '${target.kcal} kcal',
              ),
              _StatusPill(
                icon: Icons.egg_alt_outlined,
                label: '${target.protein} g protein',
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final slot in MealSlot.values)
            if (plan.mealFor(slot) case final meal?)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _C.border)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 84,
                      child: Text(
                        slot.label.toUpperCase(),
                        style: const TextStyle(
                          color: _C.gray,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          height: 1.6,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meal.recipe.name,
                            style: const TextStyle(
                              color: _C.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            meal.foods
                                .where((f) => f.food.id != 'oil')
                                .map((f) => '${f.food.name} ${f.amount}')
                                .join(' • '),
                            style: _T.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warn ? _C.warn.withValues(alpha: .10) : _C.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  warn ? Icons.warning_amber_rounded : Icons.payments_outlined,
                  size: 18,
                  color: warn ? _C.warn : _C.gold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    plan.budgetTooLow
                        ? 'Budget is tight: the lowest-cost plan is about ₱${plan.cheapestCost.round()}.'
                        : 'About ₱${plan.cost.round()} of your ₱${plan.budget} budget.',
                    style: TextStyle(
                      color: warn ? _C.warn : _C.white,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: _outlinedStyle(),
              onPressed: _openMealPlan,
              icon: const Icon(Icons.restaurant_outlined),
              label: const Text('Open meal plan'),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Shared styles ----

  static ButtonStyle _primaryStyle({double height = 52}) =>
      FilledButton.styleFrom(
        backgroundColor: _C.gold,
        foregroundColor: _C.bg,
        disabledBackgroundColor: _C.gold.withValues(alpha: .35),
        disabledForegroundColor: _C.bg,
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      );

  static ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
    foregroundColor: _C.white,
    iconColor: _C.gold,
    disabledForegroundColor: _C.gray.withValues(alpha: .6),
    disabledIconColor: _C.gray.withValues(alpha: .6),
    side: const BorderSide(color: _C.border, width: 1.2),
    minimumSize: const Size.fromHeight(48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  static Widget _choiceChip({
    required String label,
    required bool selected,
    ValueChanged<bool>? onSelected,
  }) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
    showCheckmark: false,
    selectedColor: _C.gold,
    backgroundColor: _C.card,
    disabledColor: _C.card,
    side: BorderSide(color: selected ? _C.gold : _C.border),
    shape: const StadiumBorder(),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    labelStyle: TextStyle(
      color: selected ? _C.bg : _C.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  static InputDecoration _inputDecoration({
    String? hint,
    String? prefixText,
    String? suffixText,
    String? errorText,
  }) {
    OutlineInputBorder outline(Color color, [double width = 1.2]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _C.gray, fontSize: 14),
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        color: _C.gold,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: _C.gray, fontSize: 13),
      errorText: errorText,
      errorStyle: const TextStyle(color: _C.warn, fontSize: 12),
      counterStyle: const TextStyle(color: _C.gray, fontSize: 11),
      filled: true,
      fillColor: _C.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: outline(_C.border),
      focusedBorder: outline(_C.gold, 1.6),
      errorBorder: outline(_C.warn),
      focusedErrorBorder: outline(_C.warn, 1.6),
    );
  }
}

// ---- Small building blocks used only by this screen ----

/// Standard card surface: one radius, one border weight, everywhere.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor ?? _C.border, width: 1.2),
    ),
    child: child,
  );
}

/// One segmented control instead of three copy-pasted tab buttons.
/// Keyboard/screen-reader friendly via InkWell + Semantics.
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _C.border, width: 1.2),
    ),
    child: Row(
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: Motion.medium,
                    curve: Motion.curve,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? _C.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: i == selected ? _C.bg : _C.gray,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Small metadata pill (plan source, offline, kcal, etc.).
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    this.color = _C.gold,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: _C.bg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _C.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color == _C.gold ? _C.white : color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Gold-tinted inline message for adaptive changes (recovery, lighter week).
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _C.gold.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _C.gold.withValues(alpha: .30)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: _C.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _C.white, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

/// Shown when a list has nothing to display.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.message});

  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    decoration: BoxDecoration(
      color: _C.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _C.border, width: 1.2),
    ),
    child: Column(
      children: [
        Icon(icon, size: 28, color: _C.gold.withValues(alpha: .8)),
        const SizedBox(height: 10),
        Text(title, style: _T.label, textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: 4),
          Text(message!, style: _T.caption, textAlign: TextAlign.center),
        ],
      ],
    ),
  );
}

/// Tappable settings row (equipment, check-in) with a 48dp+ touch target.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
    color: _C.bg,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _C.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _T.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _C.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    ),
  );
}
