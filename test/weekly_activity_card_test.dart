import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/weekly_activity.dart';
import 'package:flutter_application_1/widgets/weekly_activity_card.dart';

void main() {
  final now = DateTime(2026, 11, 12, 18);
  final busyWeek = WeeklyActivity.fromWorkouts(
    [
      {'timestamp': DateTime(2026, 11, 9, 7), 'duration': 125},
      {'timestamp': DateTime(2026, 11, 10, 7), 'duration': 8},
      {'timestamp': DateTime(2026, 11, 12, 7), 'duration': 45},
    ],
    now: now,
    scheduled: ['Mon', 'Tue', 'Wed', 'Thu', 'Sat'],
  );
  final emptyWeek = WeeklyActivity.fromWorkouts(
    const [],
    now: now,
    scheduled: const [],
  );

  for (final (width, scale) in [(320.0, 1.0), (320.0, 1.6), (412.0, 2.0)]) {
    for (final (name, week) in [('busy', busyWeek), ('empty', emptyWeek)]) {
      testWidgets('$name week fits at ${width.toInt()}px, text x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 900),
                textScaler: TextScaler.linear(scale),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: WeeklyActivityCard(week: week),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
