import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/workout_insights.dart';
import '../services/supabase_analytics_service.dart';

/// Debounced, per-account sync; retries on changed inputs, app resume or user action.
class AnalyticsCloudSync extends StatefulWidget {
  const AnalyticsCloudSync({
    super.key,
    required this.insights,
    required this.sourceCached,
    required this.ownerUid,
  });
  final WorkoutInsights insights;
  final bool sourceCached;
  final String ownerUid;

  @override
  State<AnalyticsCloudSync> createState() => _AnalyticsCloudSyncState();
}

class _AnalyticsCloudSyncState extends State<AnalyticsCloudSync>
    with WidgetsBindingObserver {
  final _service = SupabaseAnalyticsService();
  Timer? _timer;
  int _revision = 0;
  String? _signature;
  String _status = 'Preparing Supabase sync…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedule();
  }

  @override
  void didUpdateWidget(covariant AnalyticsCloudSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _schedule(force: true));
    }
  }

  void _schedule({bool force = false}) {
    final payload = SupabaseAnalyticsService.snapshot(
      widget.insights,
      DateTime.now(),
    );
    final signature =
        '${widget.ownerUid}|${widget.sourceCached}|${jsonEncode(payload)}';
    if (!force && signature == _signature) return;
    _signature = signature;
    _timer?.cancel();
    final revision = ++_revision;
    _failed = false;
    if (widget.sourceCached) {
      _status =
          'On-device analytics · waiting for fresh logs before Supabase sync';
      return;
    }
    _status = 'Syncing analytics to Supabase…';
    _timer = Timer(const Duration(milliseconds: 800), () async {
      final owner = widget.ownerUid;
      if (FirebaseAuth.instance.currentUser?.uid != owner) return;
      try {
        final savedAt = await _service.save(payload);
        if (!mounted ||
            revision != _revision ||
            FirebaseAuth.instance.currentUser?.uid != owner) {
          return;
        }
        setState(
          () => _status =
              'Saved to Supabase · ${TimeOfDay.fromDateTime(savedAt).format(context)}',
        );
      } catch (_) {
        if (!mounted ||
            revision != _revision ||
            FirebaseAuth.instance.currentUser?.uid != owner) {
          return;
        }
        setState(() {
          _failed = true;
          _status = 'On-device analytics · Supabase sync unavailable';
        });
      }
    });
  }

  @override
  void dispose() {
    ++_revision;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        _failed ? Icons.cloud_off_outlined : Icons.cloud_outlined,
        color: const Color(0xFFF5B800),
        size: 18,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          _status,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
      ),
      if (_failed)
        TextButton(
          onPressed: () => setState(() => _schedule(force: true)),
          child: const Text('Retry'),
        ),
    ],
  );
}
