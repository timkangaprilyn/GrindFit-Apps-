import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/fitness_features.dart';
import '../services/offline_store.dart';

/// Rebuilds with the member's current XP.
///
/// Uses the server rewards ledger (`users/{uid}/progress/rewards`) when the
/// rewards backend has credited workouts; otherwise XP is computed from the
/// member's saved and still-syncing workouts with the same rules
/// ([FitnessRank.xpFromWorkouts]), so levels move even before the Cloud
/// Functions are deployed. The larger of the two wins.
class XpBuilder extends StatelessWidget {
  const XpBuilder({super.key, required this.uid, required this.builder});

  final String uid;
  final Widget Function(BuildContext context, int xp, bool loading) builder;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseFirestore.instance.doc('users/$uid');
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user.collection('progress').doc('rewards').snapshots(),
      builder: (context, rewards) {
        final serverXp = rewards.hasError
            ? 0
            : (rewards.data?.data()?['xp'] as num?)?.toInt() ?? 0;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: user
              .collection('workouts')
              .orderBy('timestamp', descending: true)
              .limit(1000)
              .snapshots(),
          builder: (context, workouts) => ListenableBuilder(
            listenable: OfflineStore.instance,
            builder: (context, _) {
              final saved = <String, Map<String, dynamic>>{
                for (final doc
                    in workouts.data?.docs ??
                        const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  doc.reference.path: doc.data(),
              };
              for (final item in OfflineStore.instance.pendingItems) {
                if (item.path.startsWith('users/$uid/workouts/')) {
                  saved[item.path] = item.data;
                }
              }
              final localXp = FitnessRank.xpFromWorkouts(saved.values);
              final xp = serverXp > localXp ? serverXp : localXp;
              final loading =
                  workouts.connectionState == ConnectionState.waiting &&
                  !workouts.hasData;
              return builder(context, xp, loading);
            },
          ),
        );
      },
    );
  }
}
