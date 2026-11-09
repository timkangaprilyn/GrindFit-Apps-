import 'package:flutter/material.dart';

import '../models/workout_insights.dart';

class WorkoutInsightsCard extends StatelessWidget {
  const WorkoutInsightsCard({
    super.key,
    required this.insights,
    this.lowRecovery = false,
  });
  final WorkoutInsights insights;
  final bool lowRecovery;

  @override
  Widget build(BuildContext context) {
    final i = insights;
    String signed(int n) => n > 0 ? '+$n' : '$n';
    Widget line(String title, String body) => Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF5B800),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: const TextStyle(color: Color(0xFFB8BBC2), height: 1.45),
          ),
        ],
      ),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E2E31)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your trends & forecast',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          line(
            'Consistency · recent 28 days',
            i.consistency == null
                ? 'Set workout days and log scheduled sessions to see consistency.'
                : '${(i.consistency! * 100).round()}% · ${i.completed}/${i.scheduled} scheduled days completed',
          ),
          line(
            'Progress trend',
            i.sessionChange == null
                ? 'At least 14 observed days are needed to compare two weeks.'
                : '${signed(i.sessionChange!)} sessions · ${signed(i.minuteChange!)} total minutes\nLast 7 complete days compared with the previous 7. More time does not necessarily mean better progress.',
          ),
          line(
            'Next week · estimate',
            i.canForecast
                ? 'About ${i.nextWeek!.toStringAsFixed(1)} workout days at your recent consistency.'
                : 'Not enough history. Need 14 observed days, 4 scheduled opportunities and 3 logged workout days.',
          ),
          line(
            'This month · schedule goal',
            '${i.monthCompleted} workout days logged · ${i.monthTarget} currently scheduled days${i.canForecast ? '\nEstimated month-end total: ${i.monthEstimate!.toStringAsFixed(1)} workout days.' : ''}',
          ),
          line(
            'Suggested next step',
            lowRecovery
                ? 'Your check-in shows low sleep or energy. Consider the lighter session in Workout Recommendations.'
                : i.consistency != null && i.consistency! < .6
                ? 'Consider a schedule you can sustain. Resume with your next planned session instead of adding catch-up workouts.'
                : 'Keep a sustainable routine and log how each session feels.',
          ),
          const SizedBox(height: 16),
          Text(
            '${i.basis}\nEstimates assume your current schedule stays the same. Schedule changes and unlogged workouts affect results. These are activity estimates, not muscle gain or weight forecasts.',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
