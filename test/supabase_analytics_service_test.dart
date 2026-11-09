import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/models/workout_insights.dart';
import 'package:flutter_application_1/services/supabase_analytics_service.dart';

void main() {
  test('snapshot contains activity metrics and no account identifiers or health notes', () {
    final now = DateTime(2026, 11, 9);
    final data = SupabaseAnalyticsService.snapshot(
      WorkoutInsights(now: now, workouts: [], scheduledWeekdays: {}),
      now,
    );
    expect(data['local_date'], '2026-11-09');
    expect(data['can_forecast'], false);
    expect(data['next_week_estimate'], null);
    expect(data.keys, isNot(contains('firebase_uid')));
    expect(data.keys, isNot(contains('email')));
    expect(data.keys, isNot(contains('sleepHours')));
  });
  test(
    'sends current Firebase token and requires database save confirmation',
    () async {
      final service = SupabaseAnalyticsService(
        token: () async => 'firebase-token',
        client: MockClient((request) async {
          expect(request.url.host, 'fizdgkpykhcdzvdyxvej.supabase.co');
          expect(request.headers['Authorization'], 'Bearer firebase-token');
          expect(
            request.headers['apikey'],
            SupabaseAnalyticsService.publishableKey,
          );
          expect(jsonDecode(request.body)['algorithm_version'], 1);
          return http.Response('{"updated_at":"2026-11-09T01:00:00Z"}', 200);
        }),
      );
      addTearDown(service.dispose);
      expect(
        await service.save({'algorithm_version': 1}),
        DateTime.utc(2026, 11, 9, 1).toLocal(),
      );
    },
  );
  test('signed-out requests never reach Supabase', () async {
    var requests = 0;
    final service = SupabaseAnalyticsService(
      token: () async => null,
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.dispose);
    await expectLater(service.save({}), throwsStateError);
    expect(requests, 0);
  });
  test(
    'undeployed function and failed storage do not report success',
    () async {
      for (final status in [401, 404, 503]) {
        final service = SupabaseAnalyticsService(
          token: () async => 'token',
          client: MockClient((_) async => http.Response('{}', status)),
        );
        await expectLater(service.save({}), throwsStateError);
        service.dispose();
      }
    },
  );
}
