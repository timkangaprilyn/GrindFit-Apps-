import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/workout_insights.dart';
import 'package:flutter_application_1/widgets/workout_insights_card.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  test('empty and new accounts withhold forecasts', () {
    final result = WorkoutInsights(
      now: now,
      workouts: [],
      scheduledWeekdays: {1, 2, 3, 4},
    );
    expect(result.canForecast, false);
    expect(result.consistency, null);
    expect(result.nextWeek, null);
  });
  test('75 percent attendance forecasts three days on a four day schedule', () {
    final logs = <InsightWorkout>[];
    for (
      var d = DateTime(2026, 10, 12);
      d.isBefore(WorkoutInsights.day(now));
      d = WorkoutInsights.next(d)
    ) {
      if ({1, 2, 3}.contains(d.weekday)) logs.add(InsightWorkout(d, 30));
    }
    // Extra sessions on one day must not inflate attendance.
    logs.add(InsightWorkout(DateTime(2026, 10, 12, 19), 10));
    // Today's unfinished opportunity and future entries are excluded.
    logs.add(InsightWorkout(DateTime(2026, 11, 10), 30));
    final result = WorkoutInsights(
      now: now,
      workouts: logs,
      scheduledWeekdays: {1, 2, 3, 4},
      joinedAt: DateTime(2026, 10, 12),
    );
    expect(result.scheduled, 16);
    expect(result.completed, 12);
    expect(result.consistency, .75);
    expect(result.nextWeek, 3);
    expect(result.monthTarget, 17);
    expect(result.monthCompleted, 3);
    expect(result.monthEstimate, 12.75);
    expect(result.sessionChange, 0);
  });
  test('signup truncates history; empty schedule never forecasts', () {
    final logs = [InsightWorkout(DateTime(2026, 10, 1), 20)];
    final result = WorkoutInsights(
      now: now,
      workouts: logs,
      scheduledWeekdays: {},
      joinedAt: DateTime(2026, 11, 8),
    );
    expect(result.scheduled, 0);
    expect(result.canForecast, false);
    expect(result.sessionChange, null);
  });
  test('week and month boundaries use calendar dates', () {
    final result = WorkoutInsights(
      now: DateTime(2026, 3, 1),
      workouts: [],
      scheduledWeekdays: {1, 2, 3, 4, 5, 6, 7},
      joinedAt: DateTime(2026, 1, 1),
    );
    expect(result.scheduled, 28);
    expect(result.monthTarget, 31);
    expect(result.nextWeek, null);
  });
  testWidgets(
    'insights fit narrow screens and large text with honest empty state',
    (tester) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final result = WorkoutInsights(
        now: now,
        workouts: [],
        scheduledWeekdays: {},
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutInsightsCard(insights: result, lowRecovery: true),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Your trends & forecast'), findsOneWidget);
      expect(find.textContaining('Not enough history.'), findsOneWidget);
      expect(find.textContaining('lighter session'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
