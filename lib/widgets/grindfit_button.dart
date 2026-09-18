import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable primary button used across GrindFit.
///
/// Usage:
/// ```dart
/// GrindFitButton(
///   text: 'LOGIN',
///   onPressed: _handleLogin,
///   isLoading: _isLoading,
/// )
/// ```
class GrindFitButton extends StatelessWidget {
  const GrindFitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.height = 52,
  });

  /// Button label text.
  final String text;

  /// Called when the button is tapped. Set to null to disable the button.
  final VoidCallback? onPressed;

  /// Shows a spinner and disables tap when true.
  final bool isLoading;

  /// Whether the button stretches to fill available width.
  final bool fullWidth;

  /// Optional leading icon.
  final IconData? icon;

  final Color? backgroundColor;
  final Color? textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = isLoading || onPressed == null;

    final Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.black,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: textColor ?? Colors.black),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: AppTextStyles.buttonText.copyWith(
                  color: textColor ?? Colors.black,
                ),
              ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.neonCyan,
        disabledBackgroundColor:
            (backgroundColor ?? AppColors.neonCyan).withValues(alpha: 0.5),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        elevation: 0,
      ),
      child: child,
    );

    final sizedButton = SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: button,
    );

    // Subtle neon glow behind the button.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: isDisabled ? [] : AppShadows.neonGlow,
      ),
      child: sizedButton,
    );
  }
}