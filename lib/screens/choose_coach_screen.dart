import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/coaching.dart';
import '../theme/grindfit_theme.dart';

/// Lets a member browse trainers and request one as their coach.
/// A trainer or admin approves the request on the staff website.
class ChooseCoachScreen extends StatefulWidget {
  const ChooseCoachScreen({super.key});

  @override
  State<ChooseCoachScreen> createState() => _ChooseCoachScreenState();
}

class _ChooseCoachScreenState extends State<ChooseCoachScreen> {
  bool _busy = false;
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _memberName() {
    final name = AppState.instance.fullName.trim();
    final authName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    return name.isNotEmpty && name != 'Juan Dela Cruz' ? name : authName;
  }

  Future<void> _request(TrainerProfile trainer) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GrindFitTheme.card,
      builder: (_) => _RequestSheet(trainer: trainer),
    );
    if (note == null || _uid == null) return;
    setState(() => _busy = true);
    try {
      await _db
          .doc('trainer_requests/$_uid')
          .set(
            CoachRequest.newRequest(
              memberUid: _uid!,
              memberName: _memberName(),
              trainer: trainer,
              note: note,
            ),
          );
      _message(
        'Request sent to ${trainer.displayName}. You will see them here once approved.',
      );
    } on FirebaseException catch (error) {
      _message(
        error.code == 'permission-denied'
            ? 'This coach is not accepting requests right now.'
            : 'Could not send the request. Check your connection and try again.',
      );
    } on ArgumentError catch (error) {
      _message(error.message.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_uid == null) return;
    setState(() => _busy = true);
    try {
      await _db.doc('trainer_requests/$_uid').update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _message('Request cancelled.');
    } on FirebaseException catch (_) {
      _message('Could not cancel. It may already have been answered.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to choose a coach.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your coach')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _db.doc('users/$uid').snapshots(),
        builder: (context, profileSnap) {
          final currentCoach =
              profileSnap.data?.data()?['trainerUid'] as String? ?? '';
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _db.doc('trainer_requests/$uid').snapshots(),
            builder: (context, requestSnap) {
              final request = CoachRequest.fromMap(requestSnap.data?.data());
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _db
                    .collection('trainers')
                    .where('active', isEqualTo: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return const _Notice(
                      'Coaches could not load. Check your connection and try again.',
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final trainers = TrainerProfile.listed(
                    snap.data!.docs.map(
                      (d) => TrainerProfile.fromMap(d.id, d.data()),
                    ),
                  );
                  if (trainers.isEmpty) {
                    return const _Notice(
                      'No coaches are available yet. Check back soon.',
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      const Text(
                        'Pick a coach who fits your goal. Your request goes to the coach, and they or a GrindFit admin will approve it.',
                        style: TextStyle(
                          color: GrindFitTheme.gray,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final trainer in trainers)
                        _TrainerCard(
                          trainer: trainer,
                          isCurrent: trainer.uid == currentCoach,
                          isRequested:
                              request.isPending &&
                              request.trainerUid == trainer.uid,
                          busy: _busy,
                          onRequest: () => _request(trainer),
                          onCancel: _cancel,
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: GrindFitTheme.gray),
      ),
    ),
  );
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({
    required this.trainer,
    required this.isCurrent,
    required this.isRequested,
    required this.busy,
    required this.onRequest,
    required this.onCancel,
  });

  final TrainerProfile trainer;
  final bool isCurrent;
  final bool isRequested;
  final bool busy;
  final VoidCallback onRequest;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final initials = trainer.displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrent ? GrindFitTheme.gold : GrindFitTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: GrindFitTheme.gold.withValues(alpha: .15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: GrindFitTheme.gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainer.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trainer.memberLabel,
                        style: const TextStyle(
                          color: GrindFitTheme.gray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  const Chip(
                    label: Text('Your coach'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (trainer.specialty.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: GrindFitTheme.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trainer.specialty,
                  style: const TextStyle(
                    color: GrindFitTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (trainer.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(trainer.bio, style: const TextStyle(height: 1.5)),
            ],
            const SizedBox(height: 14),
            if (isCurrent)
              const Text(
                'You are training with this coach.',
                style: TextStyle(color: GrindFitTheme.gray),
              )
            else if (isRequested)
              Row(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 18,
                    color: GrindFitTheme.gold,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Request pending approval')),
                  TextButton(
                    onPressed: busy ? null : onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : onRequest,
                  child: const Text('Request this coach'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.trainer});
  final TrainerProfile trainer;
  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Request ${widget.trainer.displayName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Optional: tell your coach your goal. Sending a new request replaces any earlier one.',
          style: TextStyle(color: GrindFitTheme.gray),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _note,
          maxLength: CoachRequest.maxNoteLength,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Gusto kong lumakas para sa basketball',
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.pop(context, _note.text),
            child: const Text('Send request'),
          ),
        ),
      ],
    ),
  );
}
