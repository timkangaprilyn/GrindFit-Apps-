import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal_recommendation.dart';
import 'supabase_analytics_service.dart';

class MealPreferencesStore extends ChangeNotifier {
  MealPreferencesStore({
    required this.ownerUid,
    SharedPreferences? preferences,
    http.Client? client,
    String? Function()? currentUid,
    Future<String?> Function()? token,
  }) : _prefs = preferences,
       _client = client ?? http.Client(),
       _currentUid =
           currentUid ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _token =
           token ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());
  final String? ownerUid;
  final http.Client _client;
  final String? Function() _currentUid;
  final Future<String?> Function() _token;
  SharedPreferences? _prefs;
  MealPreferences value = const MealPreferences();
  bool loading = true, pending = false, syncing = false;
  String status = 'Loading your preferences…';
  int _revision = 0;
  bool _disposed = false;
  Timer? _timer;
  Future<void> _writes = Future.value();
  String get _key =>
      'grindfit-meals-v1-${Uri.encodeComponent(ownerUid ?? 'guest')}';
  bool get _ownsAccount => ownerUid != null && ownerUid == _currentUid();
  void _emit() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_disposed) return;
      final saved = _prefs!.getString(_key);
      if (saved != null) {
        final local = jsonDecode(saved) as Map<String, dynamic>;
        value = MealPreferences.fromJson(
          Map<String, dynamic>.from(local['preferences'] as Map),
        );
        pending = local['pending'] == true;
      }
      status = 'Saved on this device';
    } catch (_) {
      status = 'Could not restore saved preferences';
    }
    loading = false;
    _emit();
    if (!_ownsAccount || _disposed) return;
    if (pending) {
      await sync();
      return;
    }
    final revision = _revision;
    try {
      final data = await _request({'action': 'read'});
      if (_disposed || !_ownsAccount || _revision != revision) return;
      if (data['preferences'] is Map) {
        value = MealPreferences.fromJson(
          Map<String, dynamic>.from(data['preferences'] as Map),
        );
        await _persist();
      }
      status = data['preferences'] == null
          ? 'Preferences ready · save a choice to sync'
          : 'Preferences restored from Supabase';
      _emit();
    } catch (_) {
      if (!_disposed && _revision == revision) {
        status = 'On-device preferences · cloud unavailable';
        _emit();
      }
    }
  }

  Future<void> update(MealPreferences next) async {
    if (_disposed || loading || (ownerUid != null && !_ownsAccount)) return;
    value = next;
    ++_revision;
    pending = true;
    status = 'Saving preferences…';
    _emit();
    try {
      await _persist();
      if (_disposed) return;
      status = 'Saved on device · waiting to sync';
      _timer?.cancel();
      if (_ownsAccount) _timer = Timer(const Duration(milliseconds: 800), sync);
    } catch (_) {
      status = 'Could not save on this device. Try again.';
    }
    _emit();
  }

  Future<void> _persist() {
    final encoded = jsonEncode({
      'preferences': value.toJson(),
      'pending': pending,
    });
    final task = _writes.then((_) async {
      if (!await _prefs!.setString(_key, encoded)) {
        throw StateError('Local save failed');
      }
    });
    _writes = task.catchError((Object _) {});
    return task;
  }

  Future<Map<String, dynamic>> _request(Map<String, dynamic> body) async {
    if (!_ownsAccount) throw StateError('Account changed');
    final token = await _token();
    if (token == null || !_ownsAccount) throw StateError('Sign in first');
    final response = await _client
        .post(
          Uri.parse(
            '${SupabaseAnalyticsService.url}/functions/v1/meal-preferences',
          ),
          headers: {
            'apikey': SupabaseAnalyticsService.publishableKey,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw StateError('Cloud unavailable');
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  Future<void> sync() async {
    if (_disposed || !_ownsAccount || syncing || loading) return;
    final revision = _revision;
    syncing = true;
    status = 'Syncing meal preferences…';
    _emit();
    try {
      await _writes;
      if (!pending) {
        final data = await _request({'action': 'read'});
        if (!_disposed &&
            _ownsAccount &&
            _revision == revision &&
            data['preferences'] is Map) {
          value = MealPreferences.fromJson(
            Map<String, dynamic>.from(data['preferences'] as Map),
          );
          await _persist();
        }
      } else {
        final result = await _request({
          'action': 'save',
          'preferences': value.toJson(),
        });
        if (result['updated_at'] is! String) {
          throw StateError('Save unconfirmed');
        }
        if (!_disposed && _ownsAccount && _revision == revision) {
          pending = false;
          await _persist();
        }
      }
      if (!_disposed && _ownsAccount && _revision == revision) {
        status = 'Meal preferences synced with Supabase';
      }
    } catch (_) {
      if (!_disposed && _revision == revision) {
        status = 'Saved on device · cloud sync unavailable';
      }
    } finally {
      syncing = false;
      _emit();
      if (!_disposed && pending && _revision != revision) {
        _timer = Timer(const Duration(milliseconds: 800), sync);
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _client.close();
    super.dispose();
  }
}
