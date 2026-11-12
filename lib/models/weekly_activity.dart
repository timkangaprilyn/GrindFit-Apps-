import 'package:cloud_firestore/cloud_firestore.dart';

/// How one day of the current week looks in the Weekly Activity card.
enum DayStatus { done, missed, upcoming, rest }

class ActivityDay {
  const ActivityDay({
    required this.date,
    required this.minutes,
    required this.sessions,
    required this.scheduled,
    required this.isToday,
    required this.status,
  });

  final DateTime date;
  final int minutes;
  final int sessions;
  final bool scheduled;
  final bool isToday;
  final DayStatus status;
}

/// Sunday-to-Saturday summary of logged workouts for the current week.
class WeeklyActivity {
  const WeeklyActivity(this.days);

  final List<ActivityDay> days;

  int get totalMinutes => days.fold(0, (total, d) => total + d.minutes);
  int get activeDays => days.where((d) => d.sessions > 0).length;
  int get scheduledDays => days.where((d) => d.scheduled).length;
  int get scheduledDone =>
      days.where((d) => d.scheduled && d.sessions > 0).length;
  int get maxMinutes =>
      days.fold(0, (max, d) => d.minutes > max ? d.minutes : max);

  /// [scheduled] holds weekday names such as "Monday" or "Mon".
  factory WeeklyActivity.fromWorkouts(
    Iterable<Map<String, dynamic>> workouts, {
    required DateTime now,
    required Iterable<String> scheduled,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    // DateTime.weekday is 1 (Mon) to 7 (Sun); the week starts on Sunday.
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    final minutes = List<int>.filled(7, 0);
    final sessions = List<int>.filled(7, 0);
    for (final data in workouts) {
      final date = workoutDate(data);
      if (date == null) continue;
      final day = DateTime(date.year, date.month, date.day);
      final index = day.difference(sunday).inDays;
      if (index < 0 || index > 6 || day.isAfter(today)) continue;
      minutes[index] += durationInMinutes(data);
      sessions[index]++;
    }
    final scheduledIndexes = <int>{
      for (final name in scheduled) ?_weekdayIndex(name),
    };
    return WeeklyActivity([
      for (var i = 0; i < 7; i++)
        () {
          final date = sunday.add(Duration(days: i));
          final isScheduled = scheduledIndexes.contains(i);
          final isFuture = date.isAfter(today);
          final status = sessions[i] > 0
              ? DayStatus.done
              : !isScheduled
              ? DayStatus.rest
              : isFuture || date == today
              ? DayStatus.upcoming
              : DayStatus.missed;
          return ActivityDay(
            date: date,
            minutes: minutes[i],
            sessions: sessions[i],
            scheduled: isScheduled,
            isToday: date == today,
            status: status,
          );
        }(),
    ]);
  }

  static int? _weekdayIndex(String name) {
    const names = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final key = name.trim().toLowerCase();
    if (key.length < 3) return null;
    final index = names.indexOf(key.substring(0, 3));
    return index < 0 ? null : index;
  }
}

/// When a logged workout happened, from whichever date field it carries.
DateTime? workoutDate(Map<String, dynamic> data) {
  final raw = data['timestamp'] ?? data['completedAt'] ?? data['date'];
  return switch (raw) {
    Timestamp value => value.toDate(),
    DateTime value => value,
    String value => DateTime.tryParse(value),
    _ => null,
  };
}

/// Logged workout length in minutes, from seconds or a "45 min" style label.
int durationInMinutes(Map<String, dynamic> data) {
  final seconds = data['durationSeconds'];
  if (seconds is num) return (seconds / 60).round();

  final rawDuration = data['duration'];
  if (rawDuration is num) return rawDuration.round();
  if (rawDuration is! String) return 0;

  final value = rawDuration.toLowerCase();
  final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(value);
  if (match == null) return 0;
  final amount = double.tryParse(match.group(0)!) ?? 0;
  if (value.contains('sec') || value.endsWith('s')) {
    return (amount / 60).round();
  }
  if (value.contains('hour') || value.contains('hr') || value.endsWith('h')) {
    return (amount * 60).round();
  }
  return amount.round();
}
