import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Consistent GrindFit success/error feedback (Phase 2 spec, Sections
/// 27 & 28). Uses a floating, rounded, icon-led [SnackBar] so it
/// animates in, stays briefly, and animates out without blocking the
/// user — same call sites as before, just nicer and consistent.
class GrindFitFeedback {
  GrindFitFeedback._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      color: AppColors.success,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String actionLabel = 'TRY AGAIN',
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      color: AppColors.error,
      actionLabel: onAction != null ? actionLabel : null,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceElevated,
        elevation: 6,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        ),
        content: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: color,
                onPressed: onAction ?? () {},
              )
            : null,
      ),
    );
  }
}
