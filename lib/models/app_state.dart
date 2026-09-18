import 'package:flutter/foundation.dart';

/// Iisang shared na "source of truth" para sa buong app.
///
/// Wala pa tayong backend/Firestore sync dito — ito muna ang gagamitin
/// para consistent lahat ng screens (Fitness Goal, Duration, Indoor/Outdoor,
/// Schedule, atbp). Kapag ready na ang Firestore integration, dito na lang
/// ilalagay ang read/write calls — hindi na kailangan galawin ang ibang
/// screens dahil sila lang ay basta bumabasa/sumusulat dito.
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

  // ---- Mula sa Fitness Goal screen ----
  String fitnessGoal = 'Muscle Gain / Strength';

  // ---- Mula sa Workout Environment screen ----
  String workoutEnvironment = 'Indoor'; // 'Indoor' o 'Outdoor'

  // ---- Mula sa Program Duration screen ----
  int programDurationMonths = 3;

  // ---- Mula sa Workout Schedule screen ----
  List<String> workoutDays = ['Mon', 'Tue', 'Wed', 'Thu'];
  String sessionDuration = '45 min';

  void updateAssessment({
    required String fullName,
    required int age,
    required double heightCm,
    required double weightKg,
    required String fitnessLevel,
  }) {
    this.fullName = fullName;
    this.age = age;
    this.heightCm = heightCm;
    this.weightKg = weightKg;
    this.fitnessLevel = fitnessLevel;
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

  /// 'Indoor' -> 'Indoor Gym', 'Outdoor' -> 'Outdoor'
  String get environmentLabel =>
      workoutEnvironment == 'Indoor' ? 'Indoor Gym' : 'Outdoor';

  /// e.g. '45 min • Indoor Gym'
  String get sessionSummary => '$sessionDuration • $environmentLabel';

  /// e.g. 'Intermediate • 45 min • Indoor Gym'
  String get planHeaderSummary => '$fitnessLevel • $sessionDuration • $environmentLabel';

  /// e.g. '3 Months' / '1 Month'
  String get durationLabel =>
      '$programDurationMonths ${programDurationMonths == 1 ? 'Month' : 'Months'}';
}