import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable text input used across GrindFit forms (login, register, etc.)
///
/// Usage:
/// ```dart
/// GrindFitTextField(
///   label: 'Email',
///   hint: 'Enter your email',
///   controller: _emailController,
///   keyboardType: TextInputType.emailAddress,
///   prefixIcon: Icons.email_outlined,
///   validator: (value) {
///     if (value == null || value.isEmpty) {
///       return 'Please enter a valid email address.';
///     }
///     return null;
///   },
/// )
/// ```
class GrindFitTextField extends StatefulWidget {
  const GrindFitTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onSuffixTap,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;

  @override
  State<GrindFitTextField> createState() => _GrindFitTextFieldState();
}

class _GrindFitTextFieldState extends State<GrindFitTextField> {
  late bool _obscure;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If this field is a password field and no explicit suffix icon was
    // given, automatically show a visibility toggle.
    final bool isPasswordField = widget.obscureText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.xs),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.25),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: isPasswordField ? _obscure : false,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            validator: widget.validator,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? AppColors.neonCyan : AppColors.textMuted,
                      size: 20,
                    )
                  : null,
              suffixIcon: isPasswordField
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : (widget.suffixIcon != null
                      ? IconButton(
                          icon: Icon(widget.suffixIcon,
                              color: AppColors.textMuted, size: 20),
                          onPressed: widget.onSuffixTap,
                        )
                      : null),
            ),
          ),
        ),
      ],
    );
  }
}