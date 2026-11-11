import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/network_status.dart';
import 'package:flutter_application_1/services/offline_store.dart';
import 'package:flutter_application_1/widgets/online_only.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reconnecting is detected and remembered for the banner', () async {
    var reachable = false;
    final network = NetworkStatus.forTesting(probe: () async => reachable);
    expect(await network.checkNow(), isFalse);
    expect(network.offline, isTrue);
    expect(network.reconnectedAt, isNull);
    reachable = true;
    expect(await network.checkNow(), isTrue);
    expect(network.reconnectedAt, isNotNull);
    network.dispose();
  });

  testWidgets('online-only features are locked offline and unlock online', (
    tester,
  ) async {
    final network = NetworkStatus.forTesting(probe: () async => false);
    await network.checkNow();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnlineOnly(
            feature: 'Choosing a coach',
            status: network,
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('Choose a coach'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Choosing a coach needs internet'), findsOneWidget);
    await tester.tap(find.text('Choose a coach'), warnIfMissed: false);
    expect(taps, 0);

    network.setOnline(true);
    await tester.pump();
    expect(find.text('Choosing a coach needs internet'), findsNothing);
    await tester.tap(find.text('Choose a coach'));
    expect(taps, 1);
    network.dispose();
  });

  testWidgets('banner shows offline saves, then the synced message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final sent = <String>[];
    var connected = false;
    final store = OfflineStore.forTesting(
      preferences: prefs,
      userId: () => 'member-1',
      sender: (path, data, merge) async {
        if (!connected) throw StateError('offline');
        sent.add(path);
      },
    );
    final network = NetworkStatus.forTesting(probe: () async => connected);
    await network.checkNow();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OfflineBanner(status: network, store: store),
        ),
      ),
    );
    await tester.runAsync(
      () => store.write('users/member-1/workouts/w1', {'durationSeconds': 60}),
    );
    await tester.pump();
    expect(find.text('Offline mode'), findsOneWidget);
    expect(
      find.textContaining('1 change(s) saved on this phone'),
      findsOneWidget,
    );

    connected = true;
    network.setOnline(true);
    await tester.runAsync(() async {
      store.flush();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(sent, ['users/member-1/workouts/w1']);
    expect(find.text('Back online'), findsOneWidget);
    expect(
      find.text('Your offline workouts are synced and recorded.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 7));
    expect(find.text('Back online'), findsNothing);
    network.dispose();
  });
}
