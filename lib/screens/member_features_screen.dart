import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/animations/motion.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/coaching.dart';
import '../models/fitness_features.dart';
import '../services/offline_store.dart';
import '../services/voice_coach.dart';
import '../theme/grindfit_theme.dart';
import '../widgets/online_only.dart';
import 'choose_coach_screen.dart';
import 'meal_recommendations_screen.dart';

class MemberFeaturesScreen extends StatefulWidget {
  const MemberFeaturesScreen({super.key});
  @override
  State<MemberFeaturesScreen> createState() => _MemberFeaturesScreenState();
}

class _MemberFeaturesScreenState extends State<MemberFeaturesScreen> {
  final _alias = TextEditingController();
  final _recoveryNote = TextEditingController();
  bool _busy = false;
  String _stage = 'Rest and monitor';
  int _discomfort = 0;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  DocumentReference<Map<String, dynamic>> get _profile =>
      FirebaseFirestore.instance.doc('users/$_uid');
  String get _month => localDay(DateTime.now().toUtc()).substring(0, 7);
  @override
  void dispose() {
    _alias.dispose();
    _recoveryNote.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _challenge(bool join) async {
    if (join &&
        (_alias.text.trim().length < 3 || _alias.text.trim().length > 24)) {
      _message('Choose a public nickname with 3–24 characters.');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFunctions.instance
          .httpsCallable('setMonthlyChallenge')
          .call({'join': join, 'alias': _alias.text.trim()});
      _message(
        join
            ? 'You joined this month’s challenge.'
            : 'You left the challenge. Your public entry was removed.',
      );
    } on FirebaseFunctionsException catch (error) {
      _message(
        error.code == 'not-found'
            ? 'Monthly challenges need the Firebase backend activated first.'
            : error.message ?? 'Could not update challenge. Try again online.',
      );
    } catch (_) {
      _message('Could not update challenge. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: GrindFitTheme.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  switch (title) {
                    'XP and levels' => Icons.local_fire_department_rounded,
                    'Monthly member challenge' => Icons.emoji_events_outlined,
                    'Coach notes' => Icons.chat_bubble_outline_rounded,
                    'Your coach' => Icons.sports_rounded,
                    'Voice coach' => Icons.volume_up_outlined,
                    'Pinoy meal planner' => Icons.restaurant_rounded,
                    _ => Icons.self_improvement_rounded,
                  },
                  color: GrindFitTheme.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your member tools.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your GrindFit tools'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: GrindFitTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: staggered([
          _section('XP and levels', [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profile
                  .collection('progress')
                  .doc('rewards')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Text(
                    'XP needs the updated Firebase rules and rewards service.',
                  );
                }
                final xp = (snap.data?.data()?['xp'] as num?)?.toInt() ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${FitnessRank.name(xp)} • Level ${FitnessRank.level(xp)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$xp XP • Next milestone: ${FitnessRank.nextRank(xp)} XP',
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (xp % 250) / 250),
                    const SizedBox(height: 8),
                    const Text(
                      '50 XP per completed workout of at least one minute, up to three workouts per UTC day. XP appears after syncing and server verification.',
                    ),
                  ],
                );
              },
            ),
          ]),
          _section('Monthly member challenge', [
            const Text(
              'Optional. Only your public nickname and workout count appear on the leaderboard. No email, injury details or weight. Each month starts fresh (UTC).',
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profile
                  .collection('challenge')
                  .doc('current')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Text(
                    'Challenge access is unavailable. The updated Firebase backend and rules must be deployed.',
                  );
                }
                final membership = snap.data?.data();
                final joined =
                    membership?['month'] == _month &&
                    membership?['optedIn'] == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!joined)
                      TextField(
                        controller: _alias,
                        maxLength: 24,
                        decoration: const InputDecoration(
                          labelText: 'Public nickname (not your full name)',
                        ),
                      ),
                    OnlineOnly(
                      feature: 'The monthly challenge',
                      child: FilledButton(
                        onPressed: _busy ? null : () => _challenge(!joined),
                        child: Text(
                          _busy
                              ? 'Saving…'
                              : joined
                              ? 'Leave challenge and remove my entry'
                              : 'I agree — join this month',
                        ),
                      ),
                    ),
                    if (joined) ...[
                      Text('Joined as ${membership?['alias']} • $_month'),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('monthly_challenges/$_month/entries')
                            .orderBy('score', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, scores) {
                          if (scores.hasError) {
                            return const Text(
                              'Could not load the leaderboard. Try again online.',
                            );
                          }
                          final entries = scores.data?.docs ?? [];
                          if (entries.isEmpty) {
                            return const Text(
                              'No scores yet. Finish and sync a workout to start.',
                            );
                          }
                          return Column(
                            children: [
                              for (var i = 0; i < entries.length; i++)
                                ListTile(
                                  leading: Text('#${i + 1}'),
                                  title: Text(
                                    entries[i].data()['alias']?.toString() ??
                                        'Member',
                                  ),
                                  trailing: Text(
                                    '${entries[i].data()['score']} workouts',
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ]),
          _section('Your coach', [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _profile.snapshots(),
              builder: (context, profileSnap) {
                final coachUid =
                    profileSnap.data?.data()?['trainerUid'] as String? ?? '';
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .doc('trainer_requests/$_uid')
                      .snapshots(),
                  builder: (context, requestSnap) {
                    final request = CoachRequest.fromMap(
                      requestSnap.data?.data(),
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (coachUid.isEmpty)
                          const Text(
                            'You do not have a coach yet. Choose one who fits your goal.',
                          )
                        else
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .doc('trainers/$coachUid')
                                .snapshots(),
                            builder: (context, coachSnap) {
                              final coach = TrainerProfile.fromMap(
                                coachUid,
                                coachSnap.data?.data(),
                              );
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.verified_rounded,
                                  color: GrindFitTheme.gold,
                                ),
                                title: Text(coach.displayName),
                                subtitle: Text(
                                  coach.specialty.isEmpty
                                      ? 'Your assigned coach'
                                      : coach.specialty,
                                ),
                              );
                            },
                          ),
                        if (request.isPending)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Request to ${request.trainerName} is waiting for approval.',
                              style: const TextStyle(color: GrindFitTheme.gold),
                            ),
                          )
                        else if (request.status == CoachRequestStatus.declined)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${request.trainerName} could not take your request. You can choose another coach.',
                            ),
                          ),
                        const SizedBox(height: 12),
                        OnlineOnly(
                          feature: 'Choosing a coach',
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChooseCoachScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.groups_rounded),
                            label: Text(
                              coachUid.isEmpty
                                  ? 'Choose a coach'
                                  : 'Change coach',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ]),
          _section('Coach notes', [
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _profile
                  .collection('coach_notes')
                  .orderBy('updatedAt', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Text(
                    'Coach notes could not load. Ask your trainer to check access.',
                  );
                }
                final notes = snap.data?.docs ?? [];
                if (notes.isEmpty) {
                  return const Text(
                    'Notes from your trainer will appear here.',
                  );
                }
                return Column(
                  children: [
                    for (final doc in notes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(doc.data()['text']?.toString() ?? ''),
                        subtitle: Text(
                          'Coach • ${_displayDate(doc.data()['updatedAt'])}',
                        ),
                      ),
                  ],
                );
              },
            ),
          ]),
          _section('Voice coach', [
            ListenableBuilder(
              listenable: VoiceCoach.instance,
              builder: (context, _) {
                final voice = VoiceCoach.instance;
                return Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Spoken workout and rest cues'),
                      value: voice.enabled,
                      onChanged: (v) => voice.configure(on: v),
                    ),
                    Slider(
                      value: voice.volume,
                      onChanged: (v) => voice.configure(loudness: v),
                      label: 'Voice volume',
                    ),
                    OutlinedButton(
                      onPressed: () => voice.say(
                        'Ready, Grinder. Move with control and breathe.',
                      ),
                      child: const Text('Test voice'),
                    ),
                    if (voice.error != null) Text(voice.error!),
                  ],
                );
              },
            ),
          ]),
          _section('Pinoy meal planner', [
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MealRecommendationsScreen(),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Open Meal Recommendations'),
            ),
            const Text(
              'Breakfast, lunch, dinner and snack ideas with saved preferences and favorites.',
            ),
          ]),
          if (AppState.instance.hasInjuryOrCondition)
            _section('Recovery journal', [
              Text('Profile note: ${AppState.instance.injuryDetails}'),
              const Text(
                'Track how you feel; this does not diagnose an injury or predict healing. Progress stages only according to your clinician’s advice.',
              ),
              DropdownButtonFormField<String>(
                initialValue: _stage,
                items:
                    [
                          'Rest and monitor',
                          'Clinician-cleared mobility',
                          'Gradual return',
                          'Usual activity',
                        ]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => _stage = v!),
              ),
              const SizedBox(height: 12),
              const Text(
                'Activity guide for this stage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(switch (_stage) {
                'Clinician-cleared mobility' => 'Use only movements your clinician has cleared, such as gentle range-of-motion exercises. Follow their range, repetitions and restrictions; do not force a stretch.',
                'Gradual return' => 'If cleared, reintroduce your prescribed exercises with reduced effort. Walking or light resistance may be options only when approved for your injury. Follow your clinician\'s progression plan.',
                'Usual activity' => 'Resume your usual exercises only when cleared. Keep any remaining restrictions and record how you feel during and after activity.',
                _ => 'Pause exercises that stress the injury. Record symptoms and your clinician\'s instructions here before choosing a mobility or return-to-activity stage.',
              }),
              const Text(
                'These stages are a journal, not clearance to exercise. Stop activity that causes pain or worsening symptoms and contact your clinician. Recovery has no automatic deadline.',
              ),
              const SizedBox(height: 12),
              Text('Discomfort: $_discomfort / 10'),
              Slider(
                value: _discomfort.toDouble(),
                max: 10,
                divisions: 10,
                onChanged: (v) => setState(() => _discomfort = v.round()),
              ),
              TextField(
                controller: _recoveryNote,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / clinician-approved activity',
                ),
              ),
              FilledButton(
                onPressed: () async {
                  final id = _profile.collection('recovery').doc().id;
                  try {
                    await OfflineStore.instance.write(
                      'users/$_uid/recovery/$id',
                      {
                        'stage': _stage,
                        'discomfort': _discomfort,
                        'note': _recoveryNote.text.trim(),
                        'timestamp': DateTime.now(),
                      },
                    );
                    _recoveryNote.clear();
                    _message('Recovery check-in saved on this device.');
                  } catch (_) {
                    _message('Could not save the recovery check-in.');
                  }
                },
                child: const Text('Save recovery check-in'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Recovery timeline · newest first',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListenableBuilder(
                listenable: OfflineStore.instance,
                builder: (context, _) {
                  final pending =
                      OfflineStore.instance.pendingItems
                          .where(
                            (item) =>
                                item.path.startsWith('users/$_uid/recovery/'),
                          )
                          .toList()
                        ..sort((a, b) {
                          int time(Map<String, dynamic> data) {
                            final stamp = data['timestamp'];
                            return stamp is Map
                                ? (stamp['__timestamp'] as num?)?.toInt() ?? 0
                                : 0;
                          }

                          return time(b.data).compareTo(time(a.data));
                        });
                  return Column(
                    children: [
                      for (final item in pending)
                        ListTile(
                          leading: const Icon(Icons.cloud_upload_outlined),
                          title: Text(
                            '${item.data['stage']} · ${item.data['discomfort']}/10',
                          ),
                          subtitle: Text(
                            'Saved on device · ${item.error == null ? 'waiting to sync' : 'sync will retry'}\n${item.data['note'] ?? ''}',
                          ),
                        ),
                    ],
                  );
                },
              ),
              ListenableBuilder(
                listenable: OfflineStore.instance,
                builder: (context, _) =>
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _profile
                          .collection('recovery')
                          .orderBy('timestamp', descending: true)
                          .limit(15)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return const Text('Could not load recovery history.');
                        }
                        if (snap.connectionState == ConnectionState.waiting &&
                            !snap.hasData) {
                          return const LinearProgressIndicator();
                        }
                        if (snap.data?.docs.isEmpty ?? true) {
                          return const Text(
                            'Synced recovery check-ins will appear here.',
                          );
                        }
                        return Column(
                          children: [
                            for (final d
                                in snap.data?.docs ??
                                    <
                                      QueryDocumentSnapshot<
                                        Map<String, dynamic>
                                      >
                                    >[])
                              if (!OfflineStore.instance.pendingItems.any(
                                (item) => item.path == d.reference.path,
                              ))
                                ListTile(
                                  leading: const Icon(Icons.timeline),
                                  title: Text(
                                    '${d.data()['stage']} • ${d.data()['discomfort']}/10',
                                  ),
                                  subtitle: Text(
                                    '${_displayDate(d.data()['timestamp'])}\n${d.data()['note'] ?? ''}',
                                  ),
                                ),
                          ],
                        );
                      },
                    ),
              ),
            ]),
        ]),
      ),
    );
  }

  String _displayDate(dynamic value) =>
      value is Timestamp ? localDay(value.toDate().toLocal()) : 'Pending sync';
}
