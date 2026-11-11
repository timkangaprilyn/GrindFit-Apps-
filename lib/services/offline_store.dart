import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable per-account outbox. Stable document paths make reconnect/restart retries
/// idempotent. A newer edit is kept when an older write is acknowledged.
class OfflineStore extends ChangeNotifier {
  OfflineStore._();
  @visibleForTesting
  OfflineStore.forTesting({
    required SharedPreferences preferences,
    required String? Function() userId,
    required this._sender,
  }) : _prefs = preferences,
       _uidProvider = userId {
    _restore();
  }
  static final instance = OfflineStore._();
  String? Function()? _uidProvider;
  Future<void> Function(String, Map<String, dynamic>, bool)? _sender;
  SharedPreferences? _prefs;
  final Map<String, Map<String, dynamic>> _pending = {};
  final Set<String> _sending = {};
  final Map<String, String> _errors = {};
  Future<void> _storageTail = Future.value();
  String? get uid => _uidProvider != null
      ? _uidProvider!()
      : FirebaseAuth.instance.currentUser?.uid;
  int get pendingCount => _pending.keys
      .where((p) => p == 'users/$uid' || p.startsWith('users/$uid/'))
      .length;
  bool get hasError =>
      _errors.keys.any((p) => p == 'users/$uid' || p.startsWith('users/$uid/'));

  /// This account's unsynced saves with the last error from the server, if any.
  List<({String path, String? error, Map<String, dynamic> data})>
  get pendingItems {
    final current = uid;
    return [
      for (final entry in _pending.entries)
        if (entry.key == 'users/$current' ||
            entry.key.startsWith('users/$current/'))
          (
            path: entry.key,
            error: _errors[entry.key],
            data: Map<String, dynamic>.from(entry.value['data'] as Map),
          ),
    ];
  }

  /// Drops one unsynced save that the server keeps rejecting.
  Future<void> discard(String path) async {
    _pending.remove(path);
    _errors.remove(path);
    await _persist();
    notifyListeners();
  }

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _restore();
    FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
      flush();
    });
    Timer.periodic(const Duration(seconds: 15), (_) => flush());
    flush();
  }

  void _restore() {
    final saved = _prefs!.getString('grindfit-outbox-v1');
    if (saved != null) {
      final entries = jsonDecode(saved) as Map<String, dynamic>;
      for (final entry in entries.entries) {
        _pending[entry.key] = Map<String, dynamic>.from(entry.value as Map);
      }
    }
  }

  Future<void> write(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    if (uid == null ||
        !(path == 'users/$uid' || path.startsWith('users/$uid/'))) {
      throw StateError('Sign in before saving.');
    }
    final previous = _pending[path];
    _pending[path] = {
      'data': merge && previous != null
          ? {
              ...Map<String, dynamic>.from(previous['data'] as Map),
              ..._encode(data),
            }
          : _encode(data),
      'merge': merge && previous == null ? true : previous?['merge'] ?? merge,
      'revision': DateTime.now().microsecondsSinceEpoch,
    };
    await _persist();
    notifyListeners();
    flush();
  }

  static Map<String, dynamic> _encode(Map<String, dynamic> data) => data.map(
    (k, v) => MapEntry(
      k,
      v is Timestamp
          ? {'__timestamp': v.millisecondsSinceEpoch}
          : v is DateTime
          ? {'__timestamp': v.millisecondsSinceEpoch}
          : v is Map
          ? _encode(Map<String, dynamic>.from(v))
          : v is List
          ? v
                .map(
                  (e) => e is Map ? _encode(Map<String, dynamic>.from(e)) : e,
                )
                .toList()
          : v,
    ),
  );
  static dynamic _decode(dynamic v) {
    if (v is Map) {
      if (v.keys.length == 1 && v['__timestamp'] is num) {
        return Timestamp.fromMillisecondsSinceEpoch(
          (v['__timestamp'] as num).toInt(),
        );
      }
      return v.map((k, value) => MapEntry(k.toString(), _decode(value)));
    }
    if (v is List) return v.map(_decode).toList();
    return v;
  }

  Future<void> _persist() {
    final json = jsonEncode(_pending);
    final next = _storageTail.then((_) async {
      final success = await _prefs!.setString('grindfit-outbox-v1', json);
      if (!success) throw StateError('Could not save on this device.');
    });
    _storageTail = next.catchError((Object _) {});
    return next;
  }

  void flush() {
    final current = uid;
    if (current == null) return;
    for (final entry in _pending.entries.toList()) {
      if (!(entry.key == 'users/$current' ||
              entry.key.startsWith('users/$current/')) ||
          !_sending.add(entry.key)) {
        continue;
      }
      unawaited(_send(entry.key, entry.value));
    }
  }

  Future<void> _send(String path, Map<String, dynamic> value) async {
    try {
      final data = Map<String, dynamic>.from(_decode(value['data']) as Map);
      if (_sender != null) {
        await _sender!(path, data, value['merge'] == true);
      } else {
        await FirebaseFirestore.instance
            .doc(path)
            .set(data, SetOptions(merge: value['merge'] == true));
      }
      if (_pending[path]?['revision'] == value['revision']) {
        _pending.remove(path);
      }
      _errors.remove(path);
      await _persist();
    } catch (error) {
      _errors[path] = error.toString();
    } finally {
      _sending.remove(path);
      notifyListeners();
      if (_pending[path] != null &&
          _pending[path]?['revision'] != value['revision']) {
        flush();
      }
    }
  }

  Future<void> saveProfile(Map<String, dynamic> values) =>
      write('users/$uid', values, merge: true);
}
