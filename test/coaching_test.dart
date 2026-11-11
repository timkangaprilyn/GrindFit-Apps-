import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/coaching.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const coach = TrainerProfile(
    uid: 't1',
    displayName: 'Coach Ana',
    active: true,
  );

  test('trainer profiles tolerate missing or invalid fields', () {
    final profile = TrainerProfile.fromMap('t1', {
      'displayName': '  ',
      'memberCount': -3,
      'active': 'yes',
      'bio': 42,
    });
    expect(profile.displayName, 'Trainer');
    expect(profile.memberCount, 0);
    expect(profile.active, isFalse);
    expect(profile.bio, '');
    expect(
      TrainerProfile.fromMap('t2', {'memberCount': 1}).memberLabel,
      '1 member',
    );
  });

  test('only active trainers are listed, sorted by name', () {
    final listed = TrainerProfile.listed([
      const TrainerProfile(uid: 'b', displayName: 'ben', active: true),
      const TrainerProfile(uid: 'h', displayName: 'Hidden'),
      const TrainerProfile(uid: 'a', displayName: 'Ana', active: true),
    ]);
    expect(listed.map((t) => t.uid), ['a', 'b']);
  });

  test('request status parsing falls back to none', () {
    expect(CoachRequest.fromMap(null).status, CoachRequestStatus.none);
    expect(
      CoachRequest.fromMap({'status': 'pending', 'trainerUid': 't1'}).isPending,
      isTrue,
    );
    expect(
      CoachRequest.fromMap({'status': 'hacked'}).status,
      CoachRequestStatus.none,
    );
  });

  test('new requests match the fields allowed by firestore.rules', () {
    final data = CoachRequest.newRequest(
      memberUid: 'm1',
      memberName: '  Juan   Dela Cruz ',
      trainer: coach,
      note: '  Gusto kong lumakas.  ',
    );
    expect(data.keys.toSet(), {
      'memberUid',
      'memberName',
      'trainerUid',
      'trainerName',
      'note',
      'status',
      'createdAt',
      'updatedAt',
    });
    expect(data['memberName'], 'Juan Dela Cruz');
    expect(data['note'], 'Gusto kong lumakas.');
    expect(data['status'], 'pending');
    expect(data['createdAt'], isA<FieldValue>());

    final noNote = CoachRequest.newRequest(
      memberUid: 'm1',
      memberName: '',
      trainer: coach,
    );
    expect(noNote.containsKey('note'), isFalse);
    expect(noNote['memberName'], 'Member');
    expect(
      () => CoachRequest.newRequest(
        memberUid: 'm1',
        memberName: 'J',
        trainer: coach,
        note: 'x' * 301,
      ),
      throwsArgumentError,
    );
  });
}
