import '../theme/grindfit_theme.dart';

import 'package:flutter/material.dart';

import '../services/offline_store.dart';

class SyncStatus extends StatelessWidget {
  const SyncStatus({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: OfflineStore.instance,
    builder: (context, _) {
      final store = OfflineStore.instance;
      if (store.pendingCount == 0) return const SizedBox.shrink();
      return Material(
        color: GrindFitTheme.card,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListTile(
            dense: true,
            leading: Icon(
              store.hasError
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_upload_outlined,
              color: GrindFitTheme.gold,
            ),
            title: Text(
              '${store.pendingCount} change(s) saved on this device',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            subtitle: const Text(
              'Syncs when connected. Keep this account signed in.',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            trailing: IconButton(
              tooltip: 'Retry sync',
              onPressed: store.flush,
              icon: const Icon(Icons.refresh),
            ),
          ),
        ),
      );
    },
  );
}
