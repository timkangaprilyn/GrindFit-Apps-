import 'package:flutter/material.dart';

import '../theme/grindfit_theme.dart';

/// Progress segments na ipinapakita sa itaas ng bawat onboarding/setup screen
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
    return Semantics(
      label: 'Step $currentStep of $totalSteps',
      excludeSemantics: true,
      child: Row(
        children: List.generate(totalSteps, (index) {
          final bool isActive = index < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
              height: 4,
              decoration: BoxDecoration(
                color: isActive ? GrindFitTheme.gold : GrindFitTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
