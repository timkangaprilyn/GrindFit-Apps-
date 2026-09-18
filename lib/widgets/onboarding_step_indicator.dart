import 'package:flutter/material.dart';

/// Progress dots na ipinapakita sa itaas ng bawat onboarding/setup screen
/// (Assessment -> Goal -> Environment -> Duration -> Schedule) para malinaw
/// sa user kung saan sya sa buong proseso.
class OnboardingStepIndicator extends StatelessWidget {
  final int currentStep; // 1-based index
  final int totalSteps;

  const OnboardingStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final bool isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFF5200) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}