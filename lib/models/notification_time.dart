import 'package:intl/intl.dart';

/// Calendar days between two moments, ignoring the time of day.
int calendarDaysBetween(DateTime earlier, DateTime later) {
  final a = DateTime(earlier.year, earlier.month, earlier.day);
  final b = DateTime(later.year, later.month, later.day);
  return b.difference(a).inHours ~/ 24;
}

/// Section heading for a notification: Today, Yesterday, This week, Earlier.
String notificationSection(DateTime? date, DateTime now) {
  if (date == null) return 'Earlier';
  final days = calendarDaysBetween(date, now);
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  if (days < 7) return 'This week';
  return 'Earlier';
}

/// Short time label such as "Just now", "12m ago", "3h ago", "Yesterday".
String notificationTime(DateTime? date, DateTime now) {
  if (date == null) return '';
  final diff = now.difference(date);
  final days = calendarDaysBetween(date, now);
  if (days <= 0) {
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
  if (days == 1) return 'Yesterday · ${DateFormat('h:mm a').format(date)}';
  if (days < 7) return DateFormat('EEEE · h:mm a').format(date);
  return DateFormat('MMM d').format(date);
}
