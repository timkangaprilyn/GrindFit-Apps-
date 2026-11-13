import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/workout_plan.dart';
import 'package:flutter_application_1/screens/ai_recommendation_update_screen.dart';
import 'package:flutter_application_1/screens/ai_recommendations_screen.dart';
import 'package:flutter_application_1/screens/analytics_dashboard_screen.dart';
import 'package:flutter_application_1/screens/choose_coach_screen.dart';
import 'package:flutter_application_1/screens/exercise_timer_screen.dart';
import 'package:flutter_application_1/screens/fitness_goal_screen.dart';
import 'package:flutter_application_1/screens/forgot_password_screen.dart';
import 'package:flutter_application_1/screens/goal_progress_screen.dart';
import 'package:flutter_application_1/screens/initial_assessment_screen.dart';
import 'package:flutter_application_1/screens/log_workout_screen.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/manual_log_workout_screen.dart';
import 'package:flutter_application_1/screens/meal_recommendations_screen.dart';
import 'package:flutter_application_1/screens/member_features_screen.dart';
import 'package:flutter_application_1/screens/notifications_screen.dart';
import 'package:flutter_application_1/screens/plan_ready_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/screens/program_duration_screen.dart';
import 'package:flutter_application_1/screens/register_screen.dart';
import 'package:flutter_application_1/screens/rest_day_screen.dart';
import 'package:flutter_application_1/screens/warmup_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';
import 'package:flutter_application_1/screens/workout_environment_screen.dart';
import 'package:flutter_application_1/screens/workout_history_screen.dart';
import 'package:flutter_application_1/screens/workout_plan_detail_screen.dart';
import 'package:flutter_application_1/screens/workout_schedule_screen.dart';

const _ex = PlanExercise(
  name: 'Dumbbell Romanian Deadlift With Pause',
  detail: '3 sets • 10-12 reps • 45s',
  repsLabel: '10-12 reps',
  muscles: 'Hamstrings, glutes, lower back, core',
  equipment: 'Dumbbells',
);

final _screens = <String, Widget Function()>{
  'AiRecommendationUpdate': () => const AiRecommendationUpdateScreen(),
  'AiRecommendations': () => const AiRecommendationsScreen(),
  'AnalyticsDashboard': () => const AnalyticsDashboardScreen(),
  'ChooseCoach': () => const ChooseCoachScreen(),
  'ExerciseTimer': () => ExerciseTimerScreen(exerciseList: const [_ex, _ex]),
  'FitnessGoal': () => const FitnessGoalScreen(),
  'ForgotPassword': () => const ForgotPasswordScreen(),
  'GoalProgress': () => const GoalProgressScreen(),
  'InitialAssessment': () => const InitialAssessmentScreen(),
  'LogWorkout': () => const LogWorkoutScreen(),
  'Login': () => const LoginScreen(),
  'ManualLogWorkout': () => const ManualLogWorkoutScreen(),
  'MealRecommendations': () => const MealRecommendationsScreen(),
  'MemberFeatures': () => const MemberFeaturesScreen(),
  'Notifications': () => const NotificationsScreen(),
  'PlanReady': () => const PlanReadyScreen(),
  'Profile': () => const ProfileScreen(),
  'ProgramDuration': () => const ProgramDurationScreen(),
  'Register': () => const RegisterScreen(),
  'RestDay': () => const RestDayScreen(),
  'Warmup': () => const WarmupScreen(exerciseList: [_ex]),
  'Welcome': () => const WelcomeScreen(),
  'WorkoutEnvironment': () => const WorkoutEnvironmentScreen(),
  'WorkoutHistory': () => const WorkoutHistoryScreen(),
  'WorkoutPlanDetail': () => const WorkoutPlanDetailScreen(exercises: [_ex]),
  'WorkoutSchedule': () => const WorkoutScheduleScreen(),
};

/// Opens every screen that can render without a live Firebase backend on a
/// small phone, with and without larger system text, and fails on any
/// RenderFlex overflow. (Home and Workout Complete read Firebase while
/// building, so they are not covered here.)
void main() {
  for (final size in const [Size(320, 640), Size(360, 740)]) {
    for (final scale in const [1.0, 1.3]) {
      for (final entry in _screens.entries) {
        testWidgets(
          '${entry.key} @ ${size.width.toInt()}x${size.height.toInt()} x$scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final overflows = <String>[];
            final previous = FlutterError.onError;
            FlutterError.onError = (details) {
              final text = details.toString();
              if (text.contains('overflowed')) {
                final lines = text.split('\n');
                final head = lines.firstWhere(
                  (l) => l.contains('overflowed'),
                  orElse: () => lines.first,
                );
                final where = lines
                    .where(
                      (l) =>
                          l.contains('lib/screens') ||
                          l.contains('lib/widgets') ||
                          l.contains('file:///'),
                    )
                    .take(3)
                    .join(' | ');
                overflows.add('$head :: $where');
              } else {
                previous?.call(details);
              }
            };
            try {
              await tester.pumpWidget(
                MaterialApp(
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: entry.value(),
                ),
              );
              tester.takeException();
              for (var i = 0; i < 6; i++) {
                await tester.pump(const Duration(milliseconds: 400));
                tester.takeException();
              }
            } catch (_) {}
            FlutterError.onError = previous;
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(seconds: 5));
            expect(overflows.toSet(), isEmpty);
          },
        );
      }
    }
  }
}
