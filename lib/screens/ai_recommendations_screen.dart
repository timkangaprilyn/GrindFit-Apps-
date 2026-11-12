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

class AiRecommendationsScreen extends StatefulWidget {
  const AiRecommendationsScreen({super.key});

  @override
  State<AiRecommendationsScreen> createState() =>
      _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> {
  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
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
  // Black + Gold + White palette
  static const Color _bg = Color(0xFF121212); // Charcoal background
  static const Color _card = Color(0xFF1C1C1E); // Card surface
  static const Color _border = Color(0xFF2E2E31);
  static const Color _gold = Color(0xFFF5B800); // Gold highlight
  static const Color _white = Colors.white;
  static const Color _gray = Color(0xFF9CA3AF); // Secondary text

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
          backgroundColor: _card,
          title: const Text('Daily check-in', style: TextStyle(color: _white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sleep: $sleep hours',
                style: const TextStyle(color: _white),
              ),
              Slider(
                value: sleep.toDouble(),
                min: 0,
                max: 12,
                divisions: 12,
                onChanged: (v) => setDialogState(() => sleep = v.round()),
              ),
              Text(
                'Energy: $energy / 5',
                style: const TextStyle(color: _white),
              ),
              Slider(
                value: energy.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => setDialogState(() => energy = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
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
      backgroundColor: _card,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text('Replace exercise', style: TextStyle(color: _gold)),
            ),
            for (final option in choices)
              ListTile(
                title: Text(option.name, style: const TextStyle(color: _white)),
                subtitle: Text(
                  '${option.muscles} • ${option.equipment}',
                  style: const TextStyle(color: _gray),
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
    final exercises = AppState.instance.recommendedPlan;

    // Alamin kung pwede pang mag-pop (kung binuksan ito mula sa ibang screen gaya ng notification)
    final bool canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _card,
        elevation: 0,
        // Mag-aadjust ang leading depende kung galing sa push navigation o tab
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: _white,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Personalized Workout Recommendations',
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
                  _buildPersonalization(),
                  const SizedBox(height: 20),
                  _buildMealSuggestions(),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Goal: $goal',
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${WorkoutPlan.titleForGoal(goal)} is tailored to your goal and workout setting.',
                          style: const TextStyle(
                            color: _gray,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${session.weekLabel} • ${AppState.instance.durationLabel} program',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: (session.weekNumber / session.totalWeeks)
                                  .clamp(0.0, 1.0),
                            ),
                            duration: Motion.slow,
                            curve: Motion.curve,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(value: value),
                          ),
                        ),
                        if (session.isLighterWeek) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Lighter week: fewer sets and reps so your body can recover before the next, harder block.',
                            style: TextStyle(
                              color: _gold,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: AnimatedContainer(
                            duration: Motion.medium,
                            curve: Motion.curve,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 0 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: _selectedTab == 0 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: AnimatedContainer(
                            duration: Motion.medium,
                            curve: Motion.curve,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 1 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'This Week',
                              style: TextStyle(
                                color: _selectedTab == 1 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 2),
                          child: AnimatedContainer(
                            duration: Motion.medium,
                            curve: Motion.curve,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _selectedTab == 2 ? _gold : _card,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedTab == 2 ? _gold : _border,
                              ),
                            ),
                            child: Text(
                              'Next Week',
                              style: TextStyle(
                                color: _selectedTab == 2 ? _bg : _white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_selectedTab == 0) ...[
                    _buildTodayHeader(session),
                    const SizedBox(height: 12),
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
                                  child: _buildExerciseCard(exercise),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: AppState.instance.needsRecovery
                          ? null
                          : _showAddExercise,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add exercise for today'),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Added exercises are for today only. Tomorrow follows your plan again.',
                      style: TextStyle(color: _gray, fontSize: 12),
                    ),
                  ] else
                    KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: _buildWeekView(_selectedTab == 1 ? 0 : 1),
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

  // ---- Weekly program, today-only extras and equipment ----

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

  Widget _buildTodayHeader(ProgramSession session) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: _gray, fontSize: 12, height: 1.4),
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
      return const Text(
        'No training days scheduled.',
        style: TextStyle(color: _gray),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${weekOffset == 0 ? 'This week' : 'Next week'} • ${sessions.first.weekLabel}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sessions.first.isLighterWeek
              ? 'Lighter week for recovery. The next block starts harder.'
              : 'Each training day works different muscles, and the numbers grow week by week.',
          style: const TextStyle(color: _gray, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 12),
        for (final (index, session) in sessions.indexed)
          FadeSlideIn(
            delay: Motion.step * index,
            duration: Motion.slow,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isToday(session.date) ? _gold : _border,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.dayName,
                          style: const TextStyle(
                            color: _white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        isToday(session.date)
                            ? 'Today'
                            : _dateLabel(session.date),
                        style: TextStyle(
                          color: isToday(session.date) ? _gold : _gray,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final exercise in session.exercises)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                color: _white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            exercise.detail.split(' • ').take(2).join(' • '),
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

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
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .75,
        maxChildSize: .92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            const Text(
              'Add exercise for today',
              style: TextStyle(
                color: _white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Matched to your ${state.fitnessGoal} goal and ${Gear.describe(state.ownedEquipment).toLowerCase()}. For today only.',
              style: const TextStyle(color: _gray, fontSize: 12, height: 1.4),
            ),
            for (final (label, items) in groups) ...[
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 6),
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              for (final exercise in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exercise.name),
                  subtitle: Text(
                    '${exercise.muscles} • ${exercise.equipmentLabel}',
                  ),
                  trailing: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: _gold,
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
    var selected = {...state.equipment}..remove(Gear.gym);
    final saved = await showModalBottomSheet<Set<String>>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What equipment do you have?',
                style: TextStyle(
                  color: _white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Workouts only use what you select. Leave all off for bodyweight only.',
                style: TextStyle(color: _gray, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (id, label) in Gear.options)
                    if (id != Gear.gym)
                      FilterChip(
                        label: Text(label),
                        selected: selected.contains(id),
                        onSelected: (on) => setSheet(() {
                          selected = {...selected};
                          on ? selected.add(id) : selected.remove(id);
                        }),
                      ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, selected),
                  child: const Text('Save equipment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == null) return;
    state.updateEquipment(saved);
    await _savePreferences({'equipment': state.equipment.toList()..sort()});
  }

  Widget _buildExerciseCard(PlanExercise exercise) {
    final addedToday = AppState.instance.isTodayExtra(exercise.name);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 64,
              height: 64,
              child: WorkoutImage(
                imageUrl: exercise.imageUrl ?? '',
                exerciseName: exercise.name,
                backgroundColor: _bg,
                iconColor: _gold,
                iconSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercise.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _gold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${exercise.muscles} • ${exercise.equipment}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (addedToday) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Added by you • today only',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (addedToday)
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: _gray,
                  ),
                  tooltip: 'Remove from today',
                  onPressed: () => _removeTodayExtra(exercise.name),
                ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: _gold),
                tooltip: 'Log this exercise',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualLogWorkoutScreen(exercise: exercise),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: _gold),
                tooltip: 'Replace exercise',
                onPressed: () => _showSwap(exercise),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: _gray),
                tooltip: 'Form guide',
                onPressed: () => _showFormGuide(exercise),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalization() {
    final state = AppState.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build your plan',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get today\'s workout and meal plan. Uses your ${state.workoutEnvironment} setting, ${state.workoutDays.length} days/week and ${state.sessionDuration} sessions.',
            style: const TextStyle(color: _gray),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.handyman_outlined, color: _gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Equipment: ${Gear.describe(Gear.effective(state.workoutEnvironment, state.equipment))}',
                  style: const TextStyle(color: _white, fontSize: 13),
                ),
              ),
              if (!state.workoutEnvironment.toLowerCase().contains('gym'))
                TextButton(
                  onPressed: _editEquipment,
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _requestController,
            maxLength: 500,
            maxLines: 3,
            style: const TextStyle(color: _white),
            decoration: const InputDecoration(
              hintText: 'Describe your goal or limits in your own words',
            ),
          ),
          const Text(
            "Today's focus",
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Today's plan follows your weekly schedule. Pick another focus to change today's workout only.",
            style: TextStyle(color: _gray, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final focus in _focuses)
                ChoiceChip(
                  label: Text(_focusLabel(focus)),
                  selected: state.workoutFocus == focus,
                  onSelected: (_) => _saveBuilder(focus),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Food budget per day',
            style: TextStyle(
              color: _white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'For breakfast, lunch, dinner and a snack. Meals and grams are matched to your goal and this budget.',
            style: TextStyle(color: _gray, fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: _white),
            decoration: InputDecoration(
              prefixText: '₱ ',
              suffixText: 'per day',
              errorText: _budgetError,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              for (final preset in MealPlanner.budgetPresets)
                ActionChip(
                  label: Text('₱$preset'),
                  onPressed: () => setState(() {
                    _budgetController.text = '$preset';
                    _budgetError = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving
                ? null
                : () => _saveBuilder(state.workoutFocus, generate: true),
            child: Text(
              _saving
                  ? 'Building…'
                  : NetworkStatus.instance.offline
                  ? 'Generate offline workout & meal plan'
                  : 'Generate workout & meal plan',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No internet or online service unavailable? An offline workout is built automatically.',
            style: TextStyle(color: _gray, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showCheckIn,
            icon: const Icon(Icons.bedtime_outlined),
            label: Text(
              state.checkInDate ==
                      DateTime.now().toLocal().toIso8601String().substring(
                        0,
                        10,
                      )
                  ? 'Sleep ${state.sleepHours}h • Energy ${state.energyLevel}/5'
                  : 'Daily sleep and energy check-in',
            ),
          ),
          if (state.needsRecovery)
            const Text(
              'Low sleep or energy today: a gentle mobility session is recommended.',
              style: TextStyle(color: _gold),
            ),
          if (state.adaptationReason.isNotEmpty)
            Text(state.adaptationReason, style: const TextStyle(color: _gold)),
          const SizedBox(height: 6),
          Text(
            state.generatedContext == state.planContext
                ? state.planSource
                : 'On-device plan • Available offline',
            style: const TextStyle(color: _gray, fontSize: 11),
          ),
        ],
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: _gold),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Today's meal plan",
                  style: TextStyle(
                    color: _white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: _editMealBudget,
                child: Text('₱${plan.budget}/day'),
              ),
            ],
          ),
          Text(
            '${target.goal} • ${target.kcal} kcal • ${target.protein} g protein',
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          for (final slot in MealSlot.values)
            if (plan.mealFor(slot) case final meal?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${slot.label}: ${meal.recipe.name}',
                      style: const TextStyle(
                        color: _white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      meal.foods
                          .where((f) => f.food.id != 'oil')
                          .map((f) => '${f.food.name} ${f.amount}')
                          .join(' • '),
                      style: const TextStyle(color: _gray, fontSize: 12),
                    ),
                  ],
                ),
              ),
          Text(
            plan.budgetTooLow
                ? 'Budget is tight: the lowest-cost plan is about ₱${plan.cheapestCost.round()}.'
                : 'About ₱${plan.cost.round()} of your ₱${plan.budget} budget.',
            style: TextStyle(
              color: plan.budgetTooLow || plan.overBudget
                  ? Colors.orangeAccent
                  : _gray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openMealPlan,
              icon: const Icon(Icons.restaurant_outlined),
              label: const Text('Open meal plan'),
            ),
          ),
        ],
      ),
    );
  }
}
