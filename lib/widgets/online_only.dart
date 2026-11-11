import 'dart:async';

import 'package:flutter/material.dart';

import '../services/network_status.dart';
import '../services/offline_store.dart';
import '../theme/grindfit_theme.dart';

/// Shows [child] normally online. Offline, it is dimmed, cannot be tapped and
/// is labelled as needing internet.
class OnlineOnly extends StatelessWidget {
  const OnlineOnly({super.key, required this.child, this.feature, this.status});
  final Widget child;

  /// For example "Coach requests".
  final String? feature;

  /// Defaults to [NetworkStatus.instance]; tests pass their own.
  final NetworkStatus? status;

  @override
  Widget build(BuildContext context) {
    final network = status ?? NetworkStatus.instance;
    return ListenableBuilder(
      listenable: network,
      builder: (context, _) {
        if (network.online) return child;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            LockedLabel(feature: feature),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: AbsorbPointer(child: Opacity(opacity: 0.4, child: child)),
            ),
          ],
        );
      },
    );
  }
}

class LockedLabel extends StatelessWidget {
  const LockedLabel({super.key, this.feature});
  final String? feature;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_outline, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            feature == null ? 'Needs internet' : '$feature needs internet',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

/// Returns true when online; otherwise tells the member why the action is
/// locked.
bool requireOnline(BuildContext context, String feature) {
  if (NetworkStatus.instance.online) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        '$feature needs internet. Offline workouts and logs still work.',
      ),
    ),
  );
  return false;
}

/// Top banner: "Offline mode" while disconnected, then a short
/// "Back online" message while saved workouts sync.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key, this.status, this.store});
  final NetworkStatus? status;
  final OfflineStore? store;
  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _hide;
  bool _showBack = false;
  bool _wasOffline = false;

  NetworkStatus get _network => widget.status ?? NetworkStatus.instance;
  OfflineStore get _store => widget.store ?? OfflineStore.instance;

  @override
  void initState() {
    super.initState();
    _wasOffline = _network.offline;
    _network.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      if (_network.online && _wasOffline) {
        _showBack = true;
        _hide?.cancel();
        _hide = Timer(const Duration(seconds: 6), () {
          if (mounted) setState(() => _showBack = false);
        });
      }
      _wasOffline = _network.offline;
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _network.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final offline = _network.offline;
      if (!offline && !_showBack) return const SizedBox.shrink();
      int pending;
      try {
        pending = _store.pendingCount;
      } catch (_) {
        pending = 0;
      }
      final (icon, title, subtitle) = offline
          ? (
              Icons.wifi_off_rounded,
              'Offline mode',
              pending == 0
                  ? 'Offline workouts and logs still work. They save on this phone and sync when you are back online.'
                  : '$pending change(s) saved on this phone. They sync when you are back online.',
            )
          : (
              Icons.cloud_done_outlined,
              'Back online',
              pending == 0
                  ? 'Your offline workouts are synced and recorded.'
                  : 'Syncing $pending saved change(s)…',
            );
      return AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: Material(
          color: offline ? const Color(0xFF2A2A2D) : GrindFitTheme.card,
          child: SafeArea(
            top: false,
            bottom: false,
            child: ListTile(
              dense: true,
              leading: Icon(icon, color: GrindFitTheme.gold),
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
              trailing: offline
                  ? IconButton(
                      tooltip: 'Check connection',
                      onPressed: _network.checkNow,
                      icon: const Icon(Icons.refresh),
                    )
                  : null,
            ),
          ),
        ),
      );
    },
  );
}
