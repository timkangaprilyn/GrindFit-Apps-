import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/notification_time.dart';

void main() {
  final now = DateTime(2026, 11, 12, 8, 30);

  test('sections use calendar days, not 24-hour windows', () {
    expect(notificationSection(DateTime(2026, 11, 12, 0, 5), now), 'Today');
    // 9.5 hours ago, but on the previous calendar day.
    expect(notificationSection(DateTime(2026, 11, 11, 23), now), 'Yesterday');
    expect(notificationSection(DateTime(2026, 11, 8), now), 'This week');
    expect(notificationSection(DateTime(2026, 11, 1), now), 'Earlier');
    expect(notificationSection(null, now), 'Earlier');
  });

  test('time labels are short and relative', () {
    expect(
      notificationTime(now.subtract(const Duration(seconds: 20)), now),
      'Just now',
    );
    expect(
      notificationTime(now.subtract(const Duration(minutes: 12)), now),
      '12m ago',
    );
    expect(notificationTime(DateTime(2026, 11, 12, 5, 30), now), '3h ago');
    expect(
      notificationTime(DateTime(2026, 11, 11, 23), now),
      'Yesterday · 11:00 PM',
    );
    expect(notificationTime(DateTime(2026, 10, 30), now), 'Oct 30');
    expect(notificationTime(null, now), '');
  });
}
