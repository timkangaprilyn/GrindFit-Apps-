import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Selectable card representing a single fitness goal option on the
/// Fitness Goal screen (e.g. "Build Muscle", "Lose Weight").
///
/// Normal: dark card with a subtle border.
/// Selected: neon cyan border + subtle glow.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.icon = Icons.flag_outlined,
  });

  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  /// Icon shown in the leading badge (Phase 2 spec, Section 17).
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: isSelected ? AppColors.neonCyan : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? AppShadows.neonGlow : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.neonCyan.withValues(alpha: 0.15)
                      : AppColors.backgroundSecondary,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  key: ValueKey(isSelected),
                  color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
