import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_application_1/models/app_alert.dart';
import 'package:flutter_application_1/services/app_notifications.dart';
import 'package:flutter_application_1/widgets/notification_popup_host.dart';
import 'package:flutter_application_1/animations/fade_slide_in.dart';
import 'package:flutter_application_1/theme/grindfit_theme.dart';

class _BuildCounter extends StatelessWidget {
  const _BuildCounter(this.onBuild);
  final VoidCallback onBuild;
  @override
  Widget build(BuildContext context) {
    onBuild();
    return const Scaffold(body: Text('Underlying page'));
  }
}

void main() {
  test(
    'daily reminder describes the saved AI workout and session duration',
    () {
      final content = AppNotifications.dailyReminderContent({
        'workoutFocus': 'Core',
        'sessionDuration': '20 min',
        'workoutDays': ['Mon'],
        'generatedContext': 'Muscle Gain / Strength|Gym|Core||20 min|Mon',
        'generatedPlan': [
          {
            'name': 'Plank',
            'detail': '3 sets • 30s',
            'repsLabel': '1 reps',
            'muscles': 'Core',
            'equipment': 'Bodyweight',
          },
        ],
      }, workout: true);
      expect(content.title, 'Workout today: Core');
      expect(content.body, contains('20 min'));
      expect(content.body, contains('Plank'));
    },
  );

  test('rest day reminder recommends recovery instead of a workout', () {
    final content = AppNotifications.dailyReminderContent({}, workout: false);
    expect(content.title, 'Today is your rest day');
    expect(content.body, contains('Recovery day'));
  });

  final started = DateTime(2026, 11, 9, 12);
  AppAlert alert(
    String id, {
    String type = 'Updates',
    DateTime? date,
    bool read = false,
  }) => AppAlert(
    id: id,
    title: 'Workout completed',
    body: 'Your session is saved.',
    ownerUid: 'alice',
    type: type,
    createdAt: date,
    isRead: read,
  );

  test('Inbox history, read edits, duplicates and disabled categories do not replay', () {
    final gate = AlertDeliveryGate(started);
    expect(
      gate.accept(alert('history', date: started), initial: true, settings: {}),
      isFalse,
    );
    expect(
      gate.accept(
        alert('history', date: started.add(const Duration(seconds: 1))),
        initial: false,
        settings: {},
      ),
      isFalse,
    );
    expect(
      gate.accept(
        alert('old-cache', date: started.subtract(const Duration(days: 1))),
        initial: false,
        settings: {},
      ),
      isFalse,
    );
    expect(
      gate.accept(
        alert('muted', type: 'Achievements', date: started),
        initial: false,
        settings: {'achievements': false},
      ),
      isFalse,
    );
    expect(
      gate.accept(
        alert('read', date: started, read: true),
        initial: false,
        settings: {},
      ),
      isFalse,
    );
    expect(
      gate.accept(
        alert('new', date: started.add(const Duration(seconds: 1))),
        initial: false,
        settings: {},
      ),
      isTrue,
    );
    expect(
      gate.accept(
        alert('new', date: started.add(const Duration(seconds: 2))),
        initial: false,
        settings: {},
      ),
      isFalse,
    );
  });

  test('Pending server timestamps wait for resolution before delivery', () {
    final gate = AlertDeliveryGate(started);
    expect(
      gate.accept(alert('pending'), initial: false, settings: {}),
      isFalse,
    );
    expect(
      gate.accept(
        alert('pending', date: started),
        initial: false,
        settings: {},
      ),
      isTrue,
    );
  });

  test('Weekly reminders use the next future local calendar time', () {
    tzdata.initializeTimeZones();
    final manila = tz.getLocation('Asia/Manila');
    final monday = tz.TZDateTime(manila, 2026, 11, 9, 17);
    final today = AppNotifications.nextReminder(monday, DateTime.monday, 18, 0);
    expect(today, tz.TZDateTime(manila, 2026, 11, 9, 18));
    final passed = AppNotifications.nextReminder(
      tz.TZDateTime(manila, 2026, 11, 9, 19),
      DateTime.monday,
      18,
      0,
    );
    expect(passed, tz.TZDateTime(manila, 2026, 11, 16, 18));
    final ny = tz.getLocation('America/New_York');
    final beforeDst = tz.TZDateTime(ny, 2026, 10, 31, 12);
    final afterDst = AppNotifications.nextReminder(
      beforeDst,
      DateTime.sunday,
      18,
      0,
    );
    expect(afterDst.hour, 18);
    expect(afterDst.day, 1);
    expect(afterDst.timeZoneOffset, const Duration(hours: -5));
  });

  testWidgets('Pop-up animation does not rebuild the page beneath it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final events = StreamController<AppAlert?>.broadcast(sync: true);
    var builds = 0;
    AppAlert? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: GrindFitTheme.dark,
        builder: (context, child) => NotificationPopupHost(
          alerts: events.stream,
          onOpen: (a) => opened = a,
          child: child!,
        ),
        home: _BuildCounter(() => builds++),
      ),
    );
    final initialBuilds = builds;
    events.add(alert('one', date: started));
    await tester.pump();
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Workout completed'), findsOneWidget);
    expect(builds, initialBuilds);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Workout completed'));
    await tester.pumpAndSettle();
    expect(opened?.id, 'one');
    expect(find.text('Workout completed'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await events.close();
  });

  testWidgets(
    'Account reset clears queued pop-ups and reduce motion is respected',
    (tester) async {
      final events = StreamController<AppAlert?>.broadcast(sync: true);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: NotificationPopupHost(
              alerts: events.stream,
              onOpen: (_) {},
              child: child!,
            ),
          ),
          home: const Scaffold(),
        ),
      );
      events.add(alert('first'));
      events.add(alert('second'));
      await tester.pump();
      expect(tester.binding.transientCallbackCount, 0);
      events.add(null);
      await tester.pump();
      expect(find.text('Workout completed'), findsNothing);
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('Workout completed'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await events.close();
    },
  );

  testWidgets('Delayed entrance preserves layout space', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              FadeSlideIn(
                delay: Duration(seconds: 1),
                child: SizedBox(height: 100, child: Text('Card')),
              ),
              Text('Next section'),
            ],
          ),
        ),
      ),
    );
    final before = tester.getTopLeft(find.text('Next section'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getTopLeft(find.text('Next section')), before);
  });
}
