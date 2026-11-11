import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'offline_store.dart';

/// Tracks whether the app can reach the internet.
///
/// Offline, workouts and logs keep working and are saved on the device
/// ([OfflineStore]); features that need a server show as locked. When the
/// connection comes back the outbox is flushed right away so offline
/// workouts get recorded.
class NetworkStatus extends ChangeNotifier {
  NetworkStatus._();
  @visibleForTesting
  NetworkStatus.forTesting({required Future<bool> Function() this._probe});
  static final instance = NetworkStatus._();

  Future<bool> Function()? _probe;
  bool _online = true;
  bool _checking = false;
  Timer? _timer;

  /// Set when the connection returns; cleared after the banner shows it.
  DateTime? reconnectedAt;

  bool get online => _online;
  bool get offline => !_online;

  /// Starts periodic checks (faster while offline).
  void start() {
    unawaited(checkNow());
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: _online ? 30 : 8), () async {
      await checkNow();
      _schedule();
    });
  }

  static Future<bool> _defaultProbe() async {
    try {
      // Any HTTP answer from Firestore's host means the internet works.
      await http
          .head(Uri.parse('https://firestore.googleapis.com/'))
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkNow() async {
    if (_checking) return _online;
    _checking = true;
    try {
      setOnline(await (_probe ?? _defaultProbe)());
    } finally {
      _checking = false;
    }
    return _online;
  }

  /// Also called when a request fails, so the app reacts without waiting.
  void setOnline(bool value) {
    if (value == _online) return;
    _online = value;
    if (value) {
      reconnectedAt = DateTime.now();
      try {
        OfflineStore.instance.flush();
      } catch (_) {
        // Not initialized (tests); the periodic flush still runs in the app.
      }
    }
    if (_timer != null) _schedule();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
