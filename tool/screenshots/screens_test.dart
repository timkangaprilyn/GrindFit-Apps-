// Design review screenshots of app screens with real fonts.
//
// Run:  flutter test tool/screenshots/screens_test.dart --update-goldens
// Output: tool/screenshots/shots/<screen>.png (phone size, 390x844 logical).
// Options: SHOTS=home,login (only these), TALL=1 (full page height).
//
// Not part of the regular test suite. Screens that need a signed-in Firebase
// session render their signed-out / loading state here.
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/app_state.dart';
import 'package:flutter_application_1/screens/ai_recommendations_screen.dart';
import 'package:flutter_application_1/screens/analytics_dashboard_screen.dart';
import 'package:flutter_application_1/screens/exercise_timer_screen.dart';
import 'package:flutter_application_1/screens/fitness_goal_screen.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/goal_progress_screen.dart';
import 'package:flutter_application_1/screens/home_dashboard_screen.dart';
import 'package:flutter_application_1/screens/initial_assessment_screen.dart';
import 'package:flutter_application_1/screens/log_workout_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/manual_log_workout_screen.dart';
import 'package:flutter_application_1/screens/meal_recommendations_screen.dart';
import 'package:flutter_application_1/screens/notifications_screen.dart';
import 'package:flutter_application_1/screens/plan_ready_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/program_duration_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/screens/rest_day_screen.dart';
import 'package:flutter_application_1/screens/warmup_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:flutter_application_1/screens/workout_complete_screen.dart';
import 'package:flutter_application_1/screens/workout_environment_screen.dart';
import 'package:flutter_application_1/screens/workout_history_screen.dart';
import 'package:flutter_application_1/screens/workout_plan_detail_screen.dart';
import 'package:flutter_application_1/screens/workout_schedule_screen.dart';
import 'package:flutter_application_1/theme/grindfit_theme.dart';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  // TALL=1 renders a long canvas to review whole scrolling pages.
  final size = Size(
    390,
    Platform.environment['TALL'] == '1' ? 2400 : 844,
  );
  final only = Platform.environment['SHOTS']?.split(',').toSet();

  setUpAll(() async {
    final fonts =
        '${Platform.environment['FLUTTER_ROOT'] ?? r'C:\flutter'}'
        r'\bin\cache\artifacts\material_fonts';
    final roboto = [
      for (final w in ['regular', 'medium', 'bold', 'black', 'light'])
        '$fonts\\roboto-$w.ttf',
    ];
    // Text without a family (e.g. RichText) uses the test default font ("FlutterTest");
    // replace it with Roboto so screenshots look like a real phone.
    for (final family in ['Roboto', 'FlutterTest', 'Ahem']) {
      await _loadFont(family, roboto);
    }
    await _loadFont('MaterialIcons', ['$fonts\\materialicons-regular.otf']);
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  final plan = AppState.instance.recommendedPlan;
  final screens = <String, Widget Function()>{
    'welcome': () => const WelcomeScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'forgot_password': () => const ForgotPasswordScreen(),
    'onboard_goal': () => const FitnessGoalScreen(),
    'onboard_environment': () => const WorkoutEnvironmentScreen(),
    'onboard_schedule': () => const WorkoutScheduleScreen(),
    'onboard_duration': () => const ProgramDurationScreen(),
    'onboard_assessment': () => const InitialAssessmentScreen(),
    'plan_ready': () => const PlanReadyScreen(),
    'home': () => const HomeDashboardScreen(),
    'workouts': () => const AiRecommendationsScreen(),
    'log': () => const LogWorkoutScreen(),
    'analytics': () => const AnalyticsDashboardScreen(),
    'profile': () => const ProfileScreen(),
    'plan_detail': () => WorkoutPlanDetailScreen(exercises: plan),
    'warmup': () => WarmupScreen(exerciseList: plan),
    'timer': () => ExerciseTimerScreen(exerciseList: plan),
    'complete': () => const WorkoutCompleteScreen(),
    'manual_log': () => const ManualLogWorkoutScreen(),
    'history': () => const WorkoutHistoryScreen(),
    'goal_progress': () => const GoalProgressScreen(),
    'rest_day': () => const RestDayScreen(),
    'meals': () => const MealRecommendationsScreen(),
    'notifications': () => const NotificationsScreen(),
  };

  for (final entry in screens.entries) {
    if (only != null && !only.contains(entry.key)) continue;
    testWidgets(entry.key, (tester) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: GrindFitTheme.dark,
          home: entry.value(),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('shots/${entry.key}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    });
  }
}
