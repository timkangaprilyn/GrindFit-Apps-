import 'package:flutter/material.dart';

import '../animations/motion.dart';
import '../models/weekly_activity.dart';

/// This week's logged training, Sunday to Saturday, from real workout logs.
class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.week});

  final WeeklyActivity week;

  static const _card = Color(0xFF1C1C1E);
  static const _border = Color(0xFF2E2E31);
  static const _gold = Color(0xFFF5B800);
  static const _gray = Color(0xFF9CA3AF);
  static const _dim = Color(0xFF3F3F44);
  static const _labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _barArea = 96.0;

  @override
  Widget build(BuildContext context) {
    final scheduled = week.scheduledDays;
    final done = week.scheduledDone;
    // Keep short sessions visible without a single long one flattening the rest.
    final scale = week.maxMinutes < 30 ? 30 : week.maxMinutes;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${week.totalMinutes}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const TextSpan(
                            text: ' min',
                            style: TextStyle(
                              color: _gray,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      week.activeDays == 1
                          ? '1 active day this week'
                          : '${week.activeDays} active days this week',
                      style: const TextStyle(color: _gray, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (scheduled > 0) _ScheduleRing(done: done, total: scheduled),
            ],
          ),
          const SizedBox(height: 20),
          // Sized by its content so larger phone text sizes never overflow.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, day) in week.days.indexed)
                Expanded(
                  child: _DayColumn(
                    day: day,
                    label: _labels[i],
                    fraction: day.minutes / scale,
                    delay: Motion.step * i,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (week.totalMinutes == 0)
            Text(
              scheduled == 0
                  ? 'No workouts logged yet this week. Set your training days in your profile.'
                  : 'No workouts logged yet this week. Your next session will show up here.',
              style: const TextStyle(color: _gray, fontSize: 12),
            )
          else
            const Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(color: _gold, label: 'Done'),
                _Legend(color: _dim, label: 'Scheduled', outlined: true),
                _Legend(color: _dim, label: 'Rest day', dot: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.label,
    required this.fraction,
    required this.delay,
  });

  final ActivityDay day;
  final String label;
  final double fraction;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    const gold = WeeklyActivityCard._gold;
    const gray = WeeklyActivityCard._gray;
    const dim = WeeklyActivityCard._dim;
    const area = WeeklyActivityCard._barArea;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final done = day.status == DayStatus.done;

    final Widget bar = switch (day.status) {
      DayStatus.done => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (area * fraction).clamp(10, area)),
        duration: reduceMotion ? Duration.zero : Motion.slow + delay,
        curve: Motion.curve,
        builder: (_, height, _) => Container(
          width: 18,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: day.isToday
                  ? const [Color(0xFFE0A500), gold]
                  : [gold.withAlpha(150), gold.withAlpha(215)],
            ),
          ),
        ),
      ),
      DayStatus.missed || DayStatus.upcoming => Container(
        width: 18,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: day.status == DayStatus.upcoming && day.isToday
                ? gold.withAlpha(170)
                : dim,
            width: 1.5,
          ),
        ),
      ),
      DayStatus.rest => Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: const BoxDecoration(color: dim, shape: BoxShape.circle),
      ),
    };

    return Semantics(
      label:
          '${_weekday(day.date)}: ${done ? '${day.minutes} minutes' : _statusText(day.status)}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Always laid out (blank when empty) so every column lines up.
          Text(
            done ? '${day.minutes}' : ' ',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: day.isToday ? gold : Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: area,
            child: Align(alignment: Alignment.bottomCenter, child: bar),
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 30, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            alignment: Alignment.center,
            decoration: day.isToday
                ? BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              label,
              style: TextStyle(
                color: day.isToday ? Colors.black : gray,
                fontSize: 10.5,
                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _weekday(DateTime d) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d.weekday - 1];

  static String _statusText(DayStatus s) => switch (s) {
    DayStatus.missed => 'scheduled, not logged',
    DayStatus.upcoming => 'scheduled',
    DayStatus.rest => 'rest day',
    DayStatus.done => 'done',
  };
}

class _ScheduleRing extends StatelessWidget {
  const _ScheduleRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$done of $total scheduled workouts done',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 4.5,
                  backgroundColor: WeeklyActivityCard._dim,
                  valueColor: const AlwaysStoppedAnimation(
                    WeeklyActivityCard._gold,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$done/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'scheduled\ndays done',
            style: TextStyle(
              color: WeeklyActivityCard._gray,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    this.outlined = false,
    this.dot = false,
  });

  final Color color;
  final String label;
  final bool outlined;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dot ? 6 : 10,
          height: dot ? 6 : 10,
          decoration: BoxDecoration(
            color: outlined ? null : color,
            border: outlined ? Border.all(color: color, width: 1.5) : null,
            borderRadius: BorderRadius.circular(dot ? 3 : 3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: WeeklyActivityCard._gray, fontSize: 11),
        ),
      ],
    );
  }
}
