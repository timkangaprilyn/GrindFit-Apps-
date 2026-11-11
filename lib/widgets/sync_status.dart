import '../theme/grindfit_theme.dart';

import 'package:flutter/material.dart';

import '../services/network_status.dart';
import '../services/offline_store.dart';

class SyncStatus extends StatelessWidget {
  const SyncStatus({super.key});

  static String _label(String path, Map<String, dynamic> data) {
    final parts = path.split('/');
    if (parts.length <= 2) {
      final keys = data.keys.take(4).join(', ');
      return 'Profile settings ($keys${data.length > 4 ? ', …' : ''})';
    }
    return switch (parts[2]) {
      'workouts' =>
        'Workout: ${data['title'] ?? data['workoutName'] ?? 'session'}',
      'notifications' => 'Notification: ${data['title'] ?? 'read status'}',
      'recovery' => 'Recovery check-in',
      final other => '${other[0].toUpperCase()}${other.substring(1)} item',
    };
  }

  static String _reason(String error) {
    final code = RegExp(r'\[[^\]/]+/([a-z-]+)\]').firstMatch(error)?.group(1);
    return switch (code) {
      'permission-denied' => 'The server refused this save (permission denied). Retrying will not fix it.',
      'unavailable' || 'deadline-exceeded' =>
        'Server not reachable yet. It will retry automatically.',
      null => error.length > 160 ? '${error.substring(0, 160)}…' : error,
      _ => 'Server error: $code',
    };
  }

  Future<void> _details(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => ListenableBuilder(
      listenable: OfflineStore.instance,
      builder: (ctx, _) {
        final items = OfflineStore.instance.pendingItems;
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Not synced yet', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                'These saves are on this phone and have not reached your account yet.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty) const Text('Everything is synced.'),
              for (final item in items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _label(item.path, item.data),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.error == null
                              ? 'Waiting to send…'
                              : _reason(item.error!),
                          style: TextStyle(
                            color: item.error == null
                                ? Colors.white70
                                : Colors.orangeAccent,
                            fontSize: 12,
                          ),
                        ),
                        if (item.error != null)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: ctx,
                                  builder: (d) => AlertDialog(
                                    title: const Text('Discard this save?'),
                                    content: const Text(
                                      'It will be removed from this phone and will not be sent to your account.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(d, false),
                                        child: const Text('Keep'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(d, true),
                                        child: const Text('Discard'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await OfflineStore.instance.discard(
                                    item.path,
                                  );
                                }
                              },
                              child: const Text('Discard'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: OfflineStore.instance.flush,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry sync'),
              ),
            ],
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      OfflineStore.instance,
      NetworkStatus.instance,
    ]),
    builder: (context, _) {
      final store = OfflineStore.instance;
      if (store.pendingCount == 0 || NetworkStatus.instance.offline) {
        return const SizedBox.shrink();
      }
      return Material(
        color: GrindFitTheme.card,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListTile(
            dense: true,
            onTap: () => _details(context),
            leading: Icon(
              store.hasError
                  ? Icons.cloud_off_outlined
                  : Icons.cloud_upload_outlined,
              color: GrindFitTheme.gold,
            ),
            title: Text(
              '${store.pendingCount} change(s) not synced yet',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            subtitle: Text(
              store.hasError
                  ? 'The server did not accept a save. Tap for details.'
                  : 'Sending to your account… Tap for details.',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
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
