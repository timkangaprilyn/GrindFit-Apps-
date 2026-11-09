import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/workout_insights.dart';

/// Public app credentials only. Firebase ID tokens are verified by the Edge Function.
class SupabaseAnalyticsService {
  SupabaseAnalyticsService({
    http.Client? client,
    Future<String?> Function()? token,
  }) : _client = client ?? http.Client(),
       _token =
           token ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());

  static const url = 'https://fizdgkpykhcdzvdyxvej.supabase.co';
  static const publishableKey =
      'sb_publishable_yCIBon4a0IDMmfCV4PGPtg_fIG_1hzS';
  final http.Client _client;
  final Future<String?> Function() _token;

  static Map<String, dynamic> snapshot(WorkoutInsights i, DateTime now) => {
    'local_date':
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    'algorithm_version': 1,
    'scheduled_days': i.scheduled,
    'completed_days': i.completed,
    'consistency': i.consistency,
    'can_forecast': i.canForecast,
    'next_week_estimate': i.nextWeek,
    'month_estimate': i.monthEstimate,
    'month_completed': i.monthCompleted,
    'month_target': i.monthTarget,
    'session_change': i.sessionChange,
    'minute_change': i.minuteChange,
    'basis': i.basis,
  };

  Future<DateTime> save(Map<String, dynamic> snapshot) async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      throw StateError('Sign in to sync analytics.');
    }
    final response = await _client
        .post(
          Uri.parse('$url/functions/v1/analytics-snapshot'),
          headers: {
            'apikey': publishableKey,
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(snapshot),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError(
        response.statusCode == 404
            ? 'Supabase analytics setup is pending.'
            : 'Analytics could not sync. Retry when connected.',
      );
    }
    final value = jsonDecode(response.body) as Map<String, dynamic>;
    return DateTime.parse(value['updated_at'] as String).toLocal();
  }

  void dispose() => _client.close();
}
