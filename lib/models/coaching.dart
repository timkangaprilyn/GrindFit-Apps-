import 'package:cloud_firestore/cloud_firestore.dart';

/// A trainer listed in the public `trainers/{uid}` directory.
class TrainerProfile {
  const TrainerProfile({
    required this.uid,
    required this.displayName,
    this.specialty = '',
    this.bio = '',
    this.active = false,
    this.memberCount = 0,
  });

  final String uid;
  final String displayName;
  final String specialty;
  final String bio;
  final bool active;
  final int memberCount;

  factory TrainerProfile.fromMap(String uid, Map<String, dynamic>? data) {
    final map = data ?? const {};
    String text(String key) =>
        map[key] is String ? (map[key] as String).trim() : '';
    final count = map['memberCount'];
    return TrainerProfile(
      uid: uid,
      displayName: text('displayName').isEmpty
          ? 'Trainer'
          : text('displayName'),
      specialty: text('specialty'),
      bio: text('bio'),
      active: map['active'] == true,
      memberCount: count is num && count >= 0 ? count.toInt() : 0,
    );
  }

  String get memberLabel =>
      memberCount == 1 ? '1 member' : '$memberCount members';

  /// Active trainers sorted by name, as shown to members.
  static List<TrainerProfile> listed(Iterable<TrainerProfile> trainers) {
    final list = trainers.where((t) => t.active).toList()
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return list;
  }
}

enum CoachRequestStatus { none, pending, approved, declined, cancelled }

/// The member's current request in `trainer_requests/{memberUid}`.
class CoachRequest {
  const CoachRequest({
    required this.status,
    this.trainerUid = '',
    this.trainerName = '',
  });

  static const empty = CoachRequest(status: CoachRequestStatus.none);

  final CoachRequestStatus status;
  final String trainerUid;
  final String trainerName;

  bool get isPending => status == CoachRequestStatus.pending;

  factory CoachRequest.fromMap(Map<String, dynamic>? data) {
    if (data == null) return empty;
    final status = switch (data['status']) {
      'pending' => CoachRequestStatus.pending,
      'approved' => CoachRequestStatus.approved,
      'declined' => CoachRequestStatus.declined,
      'cancelled' => CoachRequestStatus.cancelled,
      _ => CoachRequestStatus.none,
    };
    return CoachRequest(
      status: status,
      trainerUid: data['trainerUid'] is String ? data['trainerUid'] : '',
      trainerName: data['trainerName'] is String ? data['trainerName'] : '',
    );
  }

  static const maxNoteLength = 300;
  static const _maxNameLength = 80;

  static String _bounded(String value, int max) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.length > max ? clean.substring(0, max) : clean;
  }

  /// Fields for a new pending request, matching firestore.rules.
  static Map<String, dynamic> newRequest({
    required String memberUid,
    required String memberName,
    required TrainerProfile trainer,
    String note = '',
  }) {
    final cleanNote = note.trim();
    if (cleanNote.length > maxNoteLength) {
      throw ArgumentError('Keep your message under $maxNoteLength characters.');
    }
    final name = _bounded(memberName, _maxNameLength);
    return {
      'memberUid': memberUid,
      'memberName': name.isEmpty ? 'Member' : name,
      'trainerUid': trainer.uid,
      'trainerName': _bounded(trainer.displayName, _maxNameLength),
      if (cleanNote.isNotEmpty) 'note': cleanNote,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
