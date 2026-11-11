import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/app_state.dart';
import 'package:flutter_application_1/models/workout_plan.dart';
import 'package:flutter_application_1/screens/log_workout_screen.dart';
import 'package:flutter_application_1/screens/warmup_screen.dart';
import 'package:flutter_application_1/screens/workout_plan_detail_screen.dart';
import 'package:flutter_application_1/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen renders GrindFit branding', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));

    expect(find.text('TRACK  •  ADAPT  •  ACHIEVE'), findsOneWidget);
  });

  testWidgets('Workout preview fits a phone screen and shows start action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutPlanDetailScreen(
          exercises: [
            PlanExercise(
              name: 'Push Up',
              detail: '3 sets • 10-12 reps • 45s',
              repsLabel: '10-12 reps',
              muscles: 'Chest, shoulders, triceps',
              equipment: 'No Equipment',
            ),
          ],
        ),
      ),
    );

    expect(find.text('Workout Preview'), findsOneWidget);
    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('START WORKOUT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warm-up timer starts automatically and can be paused', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WarmupScreen(
          exerciseList: const [
            PlanExercise(
              name: 'Push Up',
              detail: '3 sets • 10 reps • 45s',
              repsLabel: '10 reps',
              muscles: 'Chest',
              equipment: 'Bodyweight',
            ),
          ],
        ),
      ),
    );

    expect(find.text('00:30'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('00:29'), findsOneWidget);
    expect(find.text('Pause timer'), findsOneWidget);
    await tester.tap(find.text('Pause timer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('00:29'), findsOneWidget);
    expect(find.text('Resume timer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warm-up automatically rests 15 seconds then advances', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WarmupScreen(
          exerciseList: const [
            PlanExercise(
              name: 'Push Up',
              detail: '3 sets • 10 reps • 45s',
              repsLabel: '10 reps',
              muscles: 'Chest',
              equipment: 'Bodyweight',
            ),
          ],
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Rest and Recover'), findsOneWidget);
    expect(find.text('00:15'), findsOneWidget);

    await tester.pump(const Duration(seconds: 15));
    expect(find.text('Dynamic Torso Twists'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Log workout marks the selected exercise with a check', (
    WidgetTester tester,
  ) async {
    // The plan rotates by day, so read today's exercise names.
    final plan = AppState.instance.recommendedPlan;
    await tester.pumpWidget(const MaterialApp(home: LogWorkoutScreen()));

    expect(find.text('Save Workout'), findsOneWidget);
    expect(find.text('Start Workout'), findsNothing);
    expect(find.text('1. ${plan[0].name}'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, Colors.white);
    await tester.ensureVisible(find.text('2. ${plan[1].name}'));
    await tester.tap(find.text('2. ${plan[1].name}'));
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, Colors.white);
    expect(tester.takeException(), isNull);
  });

  test('Exercise photos match the selected workout environment', () {
    final gym = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
    );
    final home = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Home (no equipment)',
    );
    final outdoor = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Outdoor',
    );

    expect(gym.first.imageUrl, contains('4162491'));
    expect(gym[1].imageUrl, contains('38641891'));
    expect(gym[2].imageUrl, contains('7289370'));
    expect(home.first.imageUrl, contains('6975789'));
    expect(home[1].imageUrl, contains('8032778'));
    expect(home[2].imageUrl, contains('8173429'));
    expect(outdoor.first.imageUrl, contains('4803737'));
    expect(outdoor[1].imageUrl, contains('4803865'));
    expect(outdoor[2].imageUrl, contains('5149167'));
  });

  test('Workout recommendations are selected by fitness goal', () {
    final weightLoss = WorkoutPlan.forProfile(
      goal: 'Weight Loss',
      environment: 'Home (no equipment)',
    );
    final strength = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Home (no equipment)',
    );
    final endurance = WorkoutPlan.forProfile(
      goal: 'Endurance / Cardio',
      environment: 'Home (no equipment)',
    );
    final general = WorkoutPlan.forProfile(
      goal: 'General Fitness',
      environment: 'Home (no equipment)',
    );

    expect(
      WorkoutPlan.titleForGoal('Weight Loss'),
      'Full-Body Fat-Burning Circuit',
    );
    expect(
      WorkoutPlan.titleForGoal('Muscle Gain / Strength'),
      'Muscle-Building Strength',
    );
    expect(
      WorkoutPlan.titleForGoal('Endurance / Cardio'),
      'Cardio Endurance Circuit',
    );
    expect(
      WorkoutPlan.titleForGoal('General Fitness'),
      'Full-Body Fitness Circuit',
    );
    final strengthNames = strength.map((exercise) => exercise.name).toList();
    expect(
      weightLoss.map((exercise) => exercise.name).toList(),
      isNot(equals(strengthNames)),
    );
    expect(
      endurance.map((exercise) => exercise.name).toList(),
      isNot(equals(strengthNames)),
    );
    expect(
      general.map((exercise) => exercise.name).toList(),
      isNot(equals(strengthNames)),
    );
    expect(weightLoss, hasLength(3));
    expect(strength, hasLength(3));
    expect(endurance, hasLength(3));
    expect(general, hasLength(3));
  });

  test('Saved workout changes update the matching profile plan', () {
    final editedPlan = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      savedOverrides: {
        'Muscle Gain / Strength|Gym': {
          'Push Up': {'sets': 2, 'reps': 8, 'duration': 30},
        },
      },
    );
    final unchangedEnvironment = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Outdoor',
      savedOverrides: {
        'Muscle Gain / Strength|Gym': {
          'Push Up': {'sets': 2, 'reps': 8, 'duration': 30},
        },
      },
    );

    expect(editedPlan.first.detail, '2 sets • 8 reps • 30s');
    expect(unchangedEnvironment.first.detail, '3 sets • 10-12 reps • 45s');
  });

  test('Added exercises appear in the matching workout plan', () {
    final plan = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Gym',
      savedOverrides: {
        'Muscle Gain / Strength|Gym': {
          'customExercises': [
            {'name': 'Squats', 'sets': 2, 'reps': 12, 'duration': 40},
          ],
        },
      },
    );
    final otherEnvironmentPlan = WorkoutPlan.forProfile(
      goal: 'Muscle Gain / Strength',
      environment: 'Outdoor',
      savedOverrides: {
        'Muscle Gain / Strength|Gym': {
          'customExercises': [
            {'name': 'Squats', 'sets': 2, 'reps': 12, 'duration': 40},
          ],
        },
      },
    );

    expect(plan, hasLength(4));
    expect(plan.last.name, 'Squats');
    expect(plan.last.detail, '2 sets • 12 reps • 40s');
    expect(otherEnvironmentPlan, hasLength(3));
  });
}
