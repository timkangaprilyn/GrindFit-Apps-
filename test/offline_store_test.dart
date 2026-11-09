import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/offline_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 20));

  test(
    'Offline writes survive restart with the same document ID and timestamp',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final blocked = Completer<void>();
      final first = OfflineStore.forTesting(
        preferences: prefs,
        userId: () => 'alice',
        sender: (_, _, _) => blocked.future,
      );
      await first.write('users/alice/workouts/stable-id', {
        'timestamp': DateTime(2026, 11, 9),
        'durationSeconds': 120,
      });
      expect(first.pendingCount, 1);
      final sent = <String>[];
      final restarted = OfflineStore.forTesting(
        preferences: prefs,
        userId: () => 'alice',
        sender: (path, data, merge) async {
          sent.add(path);
          expect(
            (data['timestamp'] as Timestamp).toDate(),
            DateTime(2026, 11, 9),
          );
        },
      );
      restarted.flush();
      await settle();
      expect(sent, ['users/alice/workouts/stable-id']);
      expect(restarted.pendingCount, 0);
      restarted.flush();
      await settle();
      expect(sent, hasLength(1));
    },
  );

  test(
    'A queued feedback edit is kept when an older write gets acknowledged',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final firstAck = Completer<void>();
      final sends = <Map<String, dynamic>>[];
      final store = OfflineStore.forTesting(
        preferences: prefs,
        userId: () => 'alice',
        sender: (_, data, _) {
          sends.add(data);
          return sends.length == 1 ? firstAck.future : Future.value();
        },
      );
      await store.write('users/alice/workouts/one', {
        'durationSeconds': 60,
        'feedback': 'Just right',
      });
      await store.write('users/alice/workouts/one', {
        'feedback': 'Hard',
      }, merge: true);
      expect(sends, hasLength(1));
      firstAck.complete();
      await settle();
      expect(sends, hasLength(2));
      expect(sends.last['feedback'], 'Hard');
      expect(sends.last['durationSeconds'], 60);
      expect(store.pendingCount, 0);
    },
  );

  test(
    'Pending data for another member is never submitted by the current member',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final blocked = Completer<void>();
      final alice = OfflineStore.forTesting(
        preferences: prefs,
        userId: () => 'alice',
        sender: (_, _, _) => blocked.future,
      );
      await alice.write('users/alice/workouts/one', {'durationSeconds': 60});
      final sent = <String>[];
      final bob = OfflineStore.forTesting(
        preferences: prefs,
        userId: () => 'bob',
        sender: (path, _, _) async {
          sent.add(path);
        },
      );
      bob.flush();
      await settle();
      expect(sent, isEmpty);
      expect(bob.pendingCount, 0);
      await expectLater(
        bob.write('users/alice/workouts/two', {}),
        throwsStateError,
      );
    },
  );
}
