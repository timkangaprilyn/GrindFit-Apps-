import 'package:flutter/foundation.dart';

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

  // ---- Mula sa Program Duration screen ----
  int programDurationMonths = 3;

  // ---- Mula sa Workout Schedule screen ----
  List<String> workoutDays = ['Mon', 'Tue', 'Wed', 'Thu'];
  String sessionDuration = '45 min';
  int currentDayIndex = 1;

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
