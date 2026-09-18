import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Two-step progress indicator used across Profile Setup and Fitness
/// Goal ("STEP 1 OF 2" / "STEP 2 OF 2", Phase 2 spec Section 10 & 16).
///
/// Renders: `Profile ●━━━━ Goal ○` — the completed segment fills in
/// smoothly with an [AnimatedContainer] whenever [currentStep] changes.
class StepProgressIndicator extends StatelessWidget {
  const StepProgressIndicator({super.key, required this.currentStep});

  /// 1 = Profile Setup, 2 = Fitness Goal.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $currentStep OF 2',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.neonCyan,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildDot(filled: true),
            _buildBar(filled: currentStep >= 2),
            _buildDot(filled: currentStep >= 2),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: const [
            Text('Profile', style: AppTextStyles.caption),
            Spacer(),
            Text('Goal', style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildDot({required bool filled}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.neonCyan : AppColors.border,
        boxShadow: filled ? AppShadows.neonGlow : null,
      ),
    );
  }

  Widget _buildBar({required bool filled}) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: filled ? AppColors.neonCyan : AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
    );
  }
}
