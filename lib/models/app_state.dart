import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'meal_plan.dart';
import 'meal_recommendation.dart';
import 'training_program.dart';
import 'workout_plan.dart';
import 'fitness_features.dart';

/// Iisang shared na "source of truth" para sa buong app.
///
/// Pinagsasaluhang in-memory profile at workout preferences ng mga screen.
/// Ina-hydrate at sine-save ng authentication at onboarding screens ang
/// profile na ito sa Firestore.
///
/// Gamit: `AppState.instance.fitnessGoal`, `AppState.instance.updateGoal(...)`
class AppState extends ChangeNotifier {
  AppState._internal();
  static final AppState instance = AppState._internal();

  // ---- Mula sa Initial Assessment ----
  String fullName = 'Juan Dela Cruz';
  int age = 20;
  double heightCm = 170;
  double weightKg = 62;
  String fitnessLevel = 'Intermediate';
  String? gender;
  bool hasInjuryOrCondition = false;
  String injuryDetails = '';

  // ---- Mula sa Fitness Goal screen ----
  String fitnessGoal = 'Muscle Gain / Strength';

  // ---- Mula sa Workout Environment screen ----
  String workoutEnvironment = 'Gym';
  Map<String, dynamic> workoutPlanOverrides = {};

  /// Equipment owned at home/outdoors (ids from [Gear]). The gym has everything.
  Set<String> equipment = {};

  /// When the current program started; weeks and progression count from here.
  DateTime? programStartedAt;

  /// Exercises added and values changed for one day only (date = [todayPlanDate]).
  String todayPlanDate = '';
  List<Map<String, dynamic>> todayExtras = [];
  Map<String, Map<String, int>> todayAdjustments = {};

  /// Daily food budget in pesos for the meal plan.
  int mealBudget = MealPlanner.defaultBudget;

  /// Diet filters from the meal screen (synced through Supabase there).
  MealPreferences mealPreferences = const MealPreferences();

  // ---- Mula sa Program Duration screen ----
  int programDurationMonths = 3;

  // ---- Mula sa Workout Schedule screen ----
  List<String> workoutDays = ['Mon', 'Tue', 'Wed', 'Thu'];
  String sessionDuration = '45 min';
  int currentDayIndex = 1;
  String workoutRequest = '';
  String workoutFocus = TrainingProgram.programFocus;
  int sleepHours = 8;
  int energyLevel = 3;
  String checkInDate = '';
  String lastWorkoutFeedback = '';
  String adaptationReason = '';
  final Map<String, String> exerciseSwaps = {};
  int missedWorkoutDays = 0;
  DateTime? joinedAt;
  List<PlanExercise>? generatedPlan;
  String generatedContext = '';
  String planSource = 'On-device plan';
  String get planContext =>
      '$fitnessGoal|$workoutEnvironment|$workoutFocus|$workoutRequest|$sessionDuration|${workoutDays.join(',')}';

  void useOfflineWorkout() {
    generatedPlan = null;
    generatedContext = '';
    planSource = 'On-device plan • Available offline';
    exerciseSwaps.clear();
    notifyListeners();
  }

  void setGeneratedPlan(List<PlanExercise> exercises, String source) {
    generatedPlan = exercises;
    generatedContext = planContext;
    planSource = source;
    exerciseSwaps.clear();
    notifyListeners();
  }

  void updateActivity(Iterable<DateTime> completed) {
    final result = TrainingAdaptation.calculate(
      now: DateTime.now(),
      scheduledDays: workoutDays,
      completed: completed,
      feedback: lastWorkoutFeedback,
      startedAt: joinedAt,
    );
    missedWorkoutDays = result.missedDays;
    adaptationReason = result.reason;
    notifyListeners();
  }

  void updateAssessment({
    required String fullName,
    required int age,
    required double heightCm,
    required double weightKg,
    required String fitnessLevel,
    String? gender,
    bool? hasInjuryOrCondition,
    String? injuryDetails,
  }) {
    this.fullName = fullName;
    this.age = age;
    this.heightCm = heightCm;
    this.weightKg = weightKg;
    this.fitnessLevel = fitnessLevel;
    this.gender = gender;
    this.hasInjuryOrCondition = hasInjuryOrCondition ?? false;
    this.injuryDetails = injuryDetails ?? '';
    notifyListeners();
  }

  void loadProfile(Map<String, dynamic>? data, {String? fallbackName}) {
    final profile = data ?? const <String, dynamic>{};
    final savedName = profile['fullName'];
    final fallback = fallbackName?.trim();
    final savedFitnessLevel = profile['fitnessLevel'];
    final savedGender = profile['gender'];
    final savedInjuryDetails = profile['injuryDetails'];
    final rawEnvironment =
        profile['workoutEnvironment'] ?? profile['environment'];
    final savedDays = profile['workoutDays'];
    final parsedDays = savedDays is List
        ? savedDays.whereType<String>().toList()
        : <String>[];

    updateAssessment(
      fullName: savedName is String && savedName.trim().isNotEmpty
          ? savedName.trim()
          : fallback != null && fallback.isNotEmpty
          ? fallback
          : 'Athlete',
      age: (profile['age'] as num?)?.toInt() ?? 20,
      heightCm: (profile['height'] as num?)?.toDouble() ?? 170,
      weightKg: (profile['weight'] as num?)?.toDouble() ?? 62,
      fitnessLevel: savedFitnessLevel is String
          ? savedFitnessLevel
          : 'Intermediate',
      gender: savedGender is String ? savedGender : null,
      hasInjuryOrCondition: profile['hasInjuryOrCondition'] is bool
          ? profile['hasInjuryOrCondition'] as bool
          : false,
      injuryDetails: savedInjuryDetails is String ? savedInjuryDetails : '',
    );

    final savedGoal = profile['fitnessGoal'];
    fitnessGoal = savedGoal is String && savedGoal.isNotEmpty
        ? savedGoal
        : 'Muscle Gain / Strength';
    workoutEnvironment = switch (rawEnvironment?.toString().toLowerCase()) {
      'indoor' || 'gym' => 'Gym',
      'home' || 'home (no equipment)' => 'Home (no equipment)',
      'outdoor' => 'Outdoor',
      final String environment => environment,
      _ => 'Gym',
    };
    final savedWorkoutPlanOverrides = profile['workoutPlanOverrides'];
    workoutPlanOverrides = savedWorkoutPlanOverrides is Map
        ? Map<String, dynamic>.from(savedWorkoutPlanOverrides)
        : <String, dynamic>{};
    programDurationMonths =
        (profile['programDurationMonths'] as num?)?.toInt() ?? 3;
    workoutDays = parsedDays.isNotEmpty
        ? parsedDays
        : ['Mon', 'Tue', 'Wed', 'Thu'];
    final savedSessionDuration = profile['sessionDuration'];
    sessionDuration =
        savedSessionDuration is String && savedSessionDuration.isNotEmpty
        ? savedSessionDuration
        : '45 min';
    currentDayIndex = 1;
    workoutRequest = profile['workoutRequest']?.toString() ?? '';
    final savedFocus = profile['workoutFocus']?.toString();
    // 'Full Body' used to mean "follow the plan"; it now maps to the program.
    workoutFocus =
        savedFocus == null || savedFocus.isEmpty || savedFocus == 'Full Body'
        ? TrainingProgram.programFocus
        : savedFocus;
    equipment = Gear.clean(
      profile['equipment'] is List ? profile['equipment'] as List : const [],
    );
    final started = profile['programStartedAt'];
    programStartedAt = started is Timestamp
        ? started.toDate().toLocal()
        : started is String
        ? DateTime.tryParse(started)?.toLocal()
        : null;
    _loadTodayPlan(profile['todayPlan']);
    mealBudget =
        ((profile['mealBudget'] as num?)?.toInt() ?? MealPlanner.defaultBudget)
            .clamp(MealPlanner.minBudget, MealPlanner.maxBudget);
    mealPreferences = const MealPreferences();
    _mealChoices = const {};
    sleepHours = (profile['sleepHours'] as num?)?.toInt() ?? 8;
    energyLevel = (profile['energyLevel'] as num?)?.toInt() ?? 3;
    checkInDate = profile['checkInDate']?.toString() ?? '';
    lastWorkoutFeedback = profile['lastWorkoutFeedback']?.toString() ?? '';
    adaptationReason = profile['adaptationReason']?.toString() ?? '';
    final created = profile['createdAt'];
    joinedAt = created is Timestamp ? created.toDate().toLocal() : null;
    missedWorkoutDays = 0;
    generatedPlan = null;
    generatedContext = profile['generatedContext']?.toString() ?? '';
    final savedSource = profile['planSource']?.toString() ?? 'On-device plan';
    // Plans saved before the wording change still carry the old label.
    planSource = savedSource == 'AI-generated plan'
        ? 'Personalized online plan'
        : savedSource;
    final savedPlan = profile['generatedPlan'];
    if (savedPlan is List) {
      try {
        generatedPlan = savedPlan
            .whereType<Map>()
            .map((e) => PlanExercise.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {
        generatedPlan = null;
      }
    }
    exerciseSwaps.clear();
    final savedSwaps = profile['exerciseSwaps'];
    if (savedSwaps is Map) {
      for (final entry in savedSwaps.entries) {
        if (entry.key is String && entry.value is String) {
          exerciseSwaps[entry.key as String] = entry.value as String;
        }
      }
    }
    notifyListeners();
  }

  void updateCheckIn(int sleep, int energy) {
    sleepHours = sleep;
    energyLevel = energy;
    checkInDate = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    notifyListeners();
  }

  void updateWorkoutRequest(String request, String focus) {
    workoutRequest = request.trim();
    workoutFocus = focus;
    notifyListeners();
  }

  void updateFeedback(String feedback) {
    lastWorkoutFeedback = feedback;
    adaptationReason = missedWorkoutDays > 0
        ? '$missedWorkoutDays scheduled session(s) missed recently. Return with fewer sets instead of increasing the load.'
        : switch (feedback.toLowerCase()) {
            'easy' =>
              'Your last workout felt easy, so the next session adds a set.',
            'hard' => 'Your last workout felt hard, so the next session uses fewer sets.',
            _ => 'Your last workout felt just right, so the plan stays steady.',
          };
    notifyListeners();
  }

  void swapExercise(String original, String replacement) {
    final source =
        exerciseSwaps.entries
            .where((entry) => entry.value == original)
            .firstOrNull
            ?.key ??
        original;
    exerciseSwaps[source] = replacement;
    notifyListeners();
  }

  bool get needsRecovery {
    final today = DateTime.now().toLocal().toIso8601String().substring(0, 10);
    return checkInDate == today && (sleepHours < 6 || energyLevel <= 2);
  }

  // ---- Training program (rotation, progression, equipment) ----

  static String _todayKey([DateTime? now]) =>
      (now ?? DateTime.now()).toLocal().toIso8601String().substring(0, 10);

  void _loadTodayPlan(Object? saved) {
    todayPlanDate = '';
    todayExtras = [];
    todayAdjustments = {};
    if (saved is! Map || saved['date'] != _todayKey()) return;
    todayPlanDate = _todayKey();
    final extras = saved['extras'];
    if (extras is List) {
      todayExtras = [
        for (final e in extras.whereType<Map>())
          if (e['name'] is String) Map<String, dynamic>.from(e),
      ];
    }
    final adjustments = saved['adjustments'];
    if (adjustments is Map) {
      for (final entry in adjustments.entries) {
        final values = entry.value;
        if (entry.key is! String || values is! Map) continue;
        todayAdjustments[entry.key as String] = {
          for (final v in values.entries)
            if (v.key is String && v.value is num)
              v.key as String: (v.value as num).toInt(),
        };
      }
    }
  }

  /// Equipment used to build workouts: everything at the gym, otherwise what
  /// the member owns. The "No Equipment" focus forces bodyweight for today.
  Set<String> get ownedEquipment => workoutFocus == 'No Equipment'
      ? const {}
      : Gear.effective(workoutEnvironment, equipment);

  DateTime get programStart => programStartedAt ?? joinedAt ?? DateTime.now();

  int get currentWeekIndex =>
      TrainingProgram.weekIndexOf(DateTime.now(), programStart);

  /// Today's scheduled workout, or the next one when today is a rest day.
  ProgramSession get currentSession => TrainingProgram.upcoming(
    DateTime.now(),
    goal: fitnessGoal,
    days: workoutDays,
    owned: ownedEquipment,
    sessionDuration: sessionDuration,
    start: programStart,
    months: programDurationMonths,
  );

  /// Sessions this week (offset 0) or a later week (offset 1 = next week).
  List<ProgramSession> weekSessions(int weekOffset) => TrainingProgram.week(
    DateTime.now().add(Duration(days: 7 * weekOffset)),
    goal: fitnessGoal,
    days: workoutDays,
    owned: ownedEquipment,
    sessionDuration: sessionDuration,
    start: programStart,
    months: programDurationMonths,
  );

  bool get _todayPlanActive => todayPlanDate == _todayKey();

  bool isTodayExtra(String name) =>
      _todayPlanActive && todayExtras.any((e) => e['name'] == name);

  List<PlanExercise> get recommendedPlan {
    final useGenerated =
        generatedPlan != null && generatedContext == planContext;
    final focusPlan = TrainingProgram.focusSession(
      workoutFocus,
      goal: fitnessGoal,
      owned: ownedEquipment,
      sessionDuration: sessionDuration,
      weekIndex: currentWeekIndex,
    );
    var plan = WorkoutPlan.personalized(
      goal: fitnessGoal,
      environment: workoutEnvironment,
      focus: useGenerated ? workoutFocus : '',
      request: workoutRequest,
      lowEnergy: needsRecovery || workoutFocus == 'Limited Mobility',
      feedback: missedWorkoutDays > 0 ? 'hard' : lastWorkoutFeedback,
      swaps: exerciseSwaps,
      basePlan: useGenerated
          ? generatedPlan
          : focusPlan ?? currentSession.exercises,
    );
    if (!_todayPlanActive || needsRecovery) return plan;
    plan = [
      for (final exercise in plan)
        todayAdjustments[exercise.name] == null
            ? exercise
            : _withValues(exercise, todayAdjustments[exercise.name]!),
    ];
    for (final extra in todayExtras) {
      final name = extra['name'] as String;
      if (plan.any((e) => e.name == name)) continue;
      final known = TrainingProgram.byName(name);
      final base = known != null
          ? TrainingProgram.prescribe(
              known,
              goal: fitnessGoal,
              weekIndex: currentWeekIndex,
            )
          : PlanExercise(
              name: name,
              detail: '3 sets • 10 reps • 45s',
              repsLabel: '10 reps',
              muscles: 'Added by you',
              equipment: 'Your choice',
            );
      plan.add(
        _withValues(base, {
          for (final key in ['sets', 'reps', 'duration'])
            if (extra[key] is num) key: (extra[key] as num).toInt(),
        }),
      );
    }
    return plan;
  }

  /// Applies today-only sets/reps/rest while keeping units (reps, sec, min).
  static PlanExercise _withValues(PlanExercise e, Map<String, int> values) {
    if (values.isEmpty) return e;
    final parts = e.detail.split(' • ');
    final sets =
        values['sets'] ??
        int.tryParse(RegExp(r'\d+').firstMatch(parts.first)?.group(0) ?? '') ??
        3;
    var amount = e.repsLabel;
    final reps = values['reps'];
    if (reps != null) {
      final unit =
          RegExp(r'^\d+\s*(.*)$').firstMatch(e.repsLabel)?.group(1) ?? '';
      amount = '$reps ${unit.isEmpty ? 'reps' : unit}';
    }
    final duration = values['duration'];
    final rest = duration != null
        ? '${duration}s'
        : parts.length >= 3
        ? parts[2]
        : '45s';
    return PlanExercise(
      name: e.name,
      detail: '$sets sets • $amount • $rest',
      repsLabel: amount,
      muscles: e.muscles,
      equipment: e.equipment,
      imageUrl: e.imageUrl,
    );
  }

  void _startTodayPlan() {
    if (_todayPlanActive) return;
    todayPlanDate = _todayKey();
    todayExtras = [];
    todayAdjustments = {};
  }

  /// Adds an exercise to today's workout only. It is gone tomorrow.
  void addTodayExtra(String name, {int? sets, int? reps, int? duration}) {
    _startTodayPlan();
    todayExtras = [
      for (final e in todayExtras)
        if (e['name'] != name) e,
      {'name': name, 'sets': ?sets, 'reps': ?reps, 'duration': ?duration},
    ];
    notifyListeners();
  }

  void removeTodayExtra(String name) {
    _startTodayPlan();
    todayExtras = [
      for (final e in todayExtras)
        if (e['name'] != name) e,
    ];
    notifyListeners();
  }

  /// Sets/reps/duration changed on the Log tab, kept for today only.
  void setTodayAdjustments(Map<String, Map<String, int>> values) {
    _startTodayPlan();
    todayAdjustments = {
      for (final entry in values.entries)
        entry.key: Map<String, int>.from(entry.value),
    };
    notifyListeners();
  }

  /// Changes one exercise's values for today, keeping today's other changes.
  void setTodayAdjustment(String name, Map<String, int> values) {
    _startTodayPlan();
    todayAdjustments = {
      ...todayAdjustments,
      name: Map<String, int>.from(values),
    };
    notifyListeners();
  }

  /// Saved on the profile as `todayPlan`; ignored on any other date.
  Map<String, dynamic> get todayPlanJson => {
    'date': todayPlanDate,
    'extras': todayExtras,
    'adjustments': todayAdjustments,
  };

  void updateEquipment(Set<String> ids) {
    equipment = Gear.clean(ids);
    notifyListeners();
  }

  NutritionTarget get nutritionTarget => MealPlanner.target(
    goal: fitnessGoal,
    weightKg: weightKg,
    heightCm: heightCm,
    age: age,
    gender: gender,
    daysPerWeek: workoutDays.length,
  );

  DailyMealPlan todayMealPlan() => MealPlanner.plan(
    target: nutritionTarget,
    budget: mealBudget,
    prefs: mealPreferences,
    chosen: todayMealChoices,
  );

  /// Meals the member swapped in; they only last for the day they were picked.
  Map<MealSlot, String> _mealChoices = const {};
  String _mealChoicesDate = '';
  Map<MealSlot, String> get todayMealChoices =>
      _mealChoicesDate == _dayKey(DateTime.now()) ? _mealChoices : const {};

  void chooseMeals(Map<MealSlot, String> choices) {
    _mealChoices = Map.unmodifiable(choices);
    _mealChoicesDate = _dayKey(DateTime.now());
    notifyListeners();
  }

  void clearMealChoices() {
    _mealChoices = const {};
    notifyListeners();
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void updateMealBudget(int pesos) {
    mealBudget = pesos.clamp(MealPlanner.minBudget, MealPlanner.maxBudget);
    notifyListeners();
  }

  void setMealPreferences(MealPreferences prefs) {
    if (identical(prefs, mealPreferences)) return;
    mealPreferences = prefs;
    notifyListeners();
  }

  void startProgram([DateTime? at]) {
    programStartedAt = at ?? DateTime.now();
    notifyListeners();
  }

  void updateGoal(String goal) {
    fitnessGoal = goal;
    notifyListeners();
  }

  void updateEnvironment(String environment) {
    workoutEnvironment = environment;
    notifyListeners();
  }

  void updateWorkoutPlanOverrides({
    required String goal,
    required String environment,
    required Map<String, Map<String, int>> overrides,
  }) {
    final scope = '$goal|$environment';
    workoutPlanOverrides = {
      ...workoutPlanOverrides,
      scope: overrides.map(
        (exercise, values) => MapEntry(exercise, Map<String, int>.from(values)),
      ),
    };
    notifyListeners();
  }

  void replaceWorkoutPlanOverrides(Map<String, dynamic> overrides) {
    workoutPlanOverrides = Map<String, dynamic>.from(overrides);
    notifyListeners();
  }

  void updateDuration(int months) {
    programDurationMonths = months;
    notifyListeners();
  }

  void updateSchedule(List<String> days, String duration) {
    workoutDays = List<String>.from(days);
    sessionDuration = duration;
    notifyListeners();
  }

  // ---- Mga helper para sa display, para hindi na mag-compute paisa-isa ang bawat screen ----

  String get environmentLabel => workoutEnvironment;

  /// e.g. '45 min • Gym'
  String get sessionSummary => '$sessionDuration • $environmentLabel';

  /// e.g. 'Intermediate • 45 min • Gym'
  String get planHeaderSummary =>
      '$fitnessLevel • $sessionDuration • $environmentLabel';

  /// e.g. '3 Months' / '1 Month'
  String get durationLabel =>
      '$programDurationMonths ${programDurationMonths == 1 ? 'Month' : 'Months'}';

  void completeWorkoutSession() {
    currentDayIndex = currentDayIndex < 5 ? currentDayIndex + 1 : 1;
    notifyListeners();
  }
}
