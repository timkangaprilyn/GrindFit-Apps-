import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/weekly_activity.dart';

void main() {
  // Thursday, 12 November 2026.
  final now = DateTime(2026, 11, 12, 18);

  test('adds real minutes to the right weekday and marks each day', () {
    final week = WeeklyActivity.fromWorkouts(
      [
        {'timestamp': DateTime(2026, 11, 9, 7), 'durationSeconds': 1800},
        {'timestamp': DateTime(2026, 11, 9, 19), 'duration': '15 min'},
        {'completedAt': '2026-11-12T06:00:00', 'duration': 40},
        {
          'timestamp': DateTime(2026, 11, 8),
          'duration': 50,
        }, // Sunday: first day of this week
        {'timestamp': DateTime(2026, 11, 14), 'duration': 50}, // future
        {'timestamp': DateTime(2026, 11, 7), 'duration': 50}, // last Saturday
        {'duration': 20}, // no date
      ],
      now: now,
      scheduled: ['Monday', 'Wednesday', 'Thursday', 'Sat'],
    );

    expect(week.days.map((d) => d.minutes), [50, 45, 0, 0, 40, 0, 0]);
    expect(week.days.map((d) => d.status), [
      DayStatus.done, // Sun, logged though not scheduled
      DayStatus.done, // Mon
      DayStatus.rest, // Tue
      DayStatus.missed, // Wed
      DayStatus.done, // Thu, today
      DayStatus.rest, // Fri
      DayStatus.upcoming, // Sat
    ]);
    expect(week.days[4].isToday, isTrue);
    expect(week.days[1].sessions, 2);
    expect(week.totalMinutes, 135);
    expect(week.activeDays, 3);
    expect(week.scheduledDays, 4);
    expect(week.scheduledDone, 2);
    expect(week.maxMinutes, 50);
  });

  test('a scheduled day is not missed until it has passed', () {
    final week = WeeklyActivity.fromWorkouts(
      const [],
      now: now,
      scheduled: ['Thu'],
    );
    expect(week.days[4].status, DayStatus.upcoming);
    expect(week.totalMinutes, 0);
  });

  test('duration labels convert to minutes', () {
    expect(durationInMinutes({'duration': '90 sec'}), 2);
    expect(durationInMinutes({'duration': '1 hour'}), 60);
    expect(durationInMinutes({'duration': 'none'}), 0);
  });
}
