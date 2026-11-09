import 'dart:math' as math;

class InsightWorkout {
  const InsightWorkout(this.date, this.minutes);
  final DateTime date;
  final int minutes;
}

/// Descriptive statistics and a schedule-based estimate, never a medical model.
class WorkoutInsights {
  WorkoutInsights({
    required DateTime now,
    required Iterable<InsightWorkout> workouts,
    required Set<int> scheduledWeekdays,
    DateTime? joinedAt,
  }) {
    final today = day(now);
    final records = workouts.where((w) => !w.date.isAfter(now)).toList();
    final dates = records.map((w) => day(w.date)).toSet();
    final earliest = joinedAt == null
        ? (dates.isEmpty
              ? today
              : dates.reduce((a, b) => a.isBefore(b) ? a : b))
        : day(joinedAt.toLocal());
    final cutoff = DateTime(today.year, today.month, today.day - 28);
    final start = earliest.isAfter(cutoff) ? earliest : cutoff;
    final historyDays = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;
    final schedule = scheduledWeekdays.where((d) => d >= 1 && d <= 7).toSet();
    for (var d = start; d.isBefore(today); d = next(d)) {
      if (schedule.contains(d.weekday)) {
        scheduled++;
        if (dates.contains(d)) completed++;
      }
    }
    final recentDates = dates
        .where((d) => !d.isBefore(start) && d.isBefore(today))
        .length;
    canForecast = historyDays >= 14 && scheduled >= 4 && recentDates >= 3;
    basis =
        '$completed of $scheduled scheduled days completed across $historyDays observed days. Today is excluded.';
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day + 8 - today.weekday,
    );
    final nextWeekSlots = List.generate(
      7,
      (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
    ).where((d) => schedule.contains(d.weekday)).length;
    if (canForecast) nextWeek = nextWeekSlots * completed / scheduled;
    final monthStart = DateTime(today.year, today.month);
    final monthEnd = DateTime(today.year, today.month + 1);
    monthCompleted = dates
        .where((d) => !d.isBefore(monthStart) && d.isBefore(monthEnd))
        .length;
    var remaining = 0;
    for (var d = monthStart; d.isBefore(monthEnd); d = next(d)) {
      if (schedule.contains(d.weekday)) {
        monthTarget++;
        if (!d.isBefore(today) && !dates.contains(d)) remaining++;
      }
    }
    if (canForecast) {
      monthEstimate = monthCompleted + remaining * completed / scheduled;
    }
    final recentStart = DateTime(today.year, today.month, today.day - 7);
    final previousStart = DateTime(today.year, today.month, today.day - 14);
    if (!start.isAfter(previousStart)) {
      final recent = records.where(
        (w) =>
            !day(w.date).isBefore(recentStart) && day(w.date).isBefore(today),
      );
      final previous = records.where(
        (w) =>
            !day(w.date).isBefore(previousStart) &&
            day(w.date).isBefore(recentStart),
      );
      sessionChange = recent.length - previous.length;
      minuteChange =
          recent.fold<int>(0, (sum, w) => sum + math.max(0, w.minutes)) -
          previous.fold<int>(0, (sum, w) => sum + math.max(0, w.minutes));
    }
  }

  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime next(DateTime d) => DateTime(d.year, d.month, d.day + 1);
  int scheduled = 0, completed = 0, monthCompleted = 0, monthTarget = 0;
  bool canForecast = false;
  double? nextWeek, monthEstimate;
  int? sessionChange, minuteChange;
  String basis = '';
  double? get consistency => scheduled == 0 ? null : completed / scheduled;
}
