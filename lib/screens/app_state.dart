class AppState {
  static final AppState instance = AppState._internal();
  AppState._internal();

  // User Profile Data
  String fullName = 'Adam Sky'; // Stores the user's full name
  String fitnessGoal = 'Muscle Building';
  String workoutEnvironment = 'Gym';
  int programDurationMonths = 6;
  String sessionSummary = '45 min • 3 exercises • Moderate';

  // Dynamic workout progression (Day 1 to Day 2 onwards)
  int currentDayIndex = 1;

  void completeWorkoutSession() {
    if (currentDayIndex < 5) {
      currentDayIndex++;
    } else {
      currentDayIndex = 1; // Resets cycle if it reaches the end
    }
  }

  // Method to update user profile details from onboarding
  void updateAssessment({
    required String fullName,
    required int age,
    required double heightCm,
    required double weightKg,
    required String fitnessLevel,
  }) {
    this.fullName = fullName;
    // Add additional profile fields or state storage here if needed
  }

  // Method to update workout environment
  void updateEnvironment(String environment) {
    workoutEnvironment = environment;
  }
}