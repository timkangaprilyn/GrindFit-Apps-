import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

import '../animations/grindfit_transitions.dart';

/// GrindFit design tokens and the app-wide dark theme.
///
/// Direction: a training log, not a poster. Near-black surfaces, one brand
/// accent (gold) used for actions and progress only, flat fills instead of
/// gradients and glows, and a restrained type scale where weight is earned.
class GrindFitTheme {
  GrindFitTheme._();

  // Surfaces, darkest to lightest.
  static const background = Color(0xFF121212);
  static const card = Color(0xFF1C1C1E);
  static const raised = Color(0xFF242427);
  static const field = Color(0xFF171719);
  static const border = Color(0xFF2E2E31);
  static const borderStrong = Color(0xFF3F3F44);

  // Brand accent: actions, selection and progress.
  static const gold = Color(0xFFF5B800);
  static const goldPressed = Color(0xFFDCA600);
  static const goldTint = Color(0xFF2B2510); // gold at ~12% on card

  // Text.
  static const white = Colors.white;
  static const textPrimary = Color(0xFFF4F4F5);
  static const gray = Color(0xFF9CA3AF);
  static const muted = Color(0xFF6B7280);

  // Status.
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFF87171);

  // Shape and spacing.
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;
  static const gutter = 20.0;

  /// Named explicitly so every text style, including component styles that
  /// do not inherit from the ambient text style, renders in the same face.
  static const fontFamily = 'Roboto';

  static const _text = TextStyle(fontFamily: fontFamily, color: textPrimary);

  static ThemeData get dark {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusMd),
    );
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: color, width: width),
        );
    return ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: GrindFitTransitions(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: GrindFitTransitions(),
          TargetPlatform.macOS: GrindFitTransitions(),
          TargetPlatform.linux: GrindFitTransitions(),
        },
      ),
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,
      splashColor: const Color(0x1FF5B800),
      highlightColor: const Color(0x0DF5B800),
      visualDensity: VisualDensity.standard,
      canvasColor: card,
      dividerColor: border,
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: background,
        secondary: gold,
        onSecondary: background,
        surface: card,
        onSurface: textPrimary,
        onSurfaceVariant: gray,
        primaryContainer: goldTint,
        onPrimaryContainer: gold,
        secondaryContainer: raised,
        onSecondaryContainer: textPrimary,
        error: danger,
        outline: border,
        outlineVariant: border,
        surfaceTint: Colors.transparent,
      ),
      textTheme: TextTheme(
        displaySmall: _text.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
          height: 1.15,
        ),
        headlineSmall: _text.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
          height: 1.2,
        ),
        titleLarge: _text.copyWith(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        titleMedium: _text.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        titleSmall: _text.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: _text.copyWith(fontSize: 15, height: 1.5),
        bodyMedium: _text.copyWith(fontSize: 14, height: 1.45, color: gray),
        bodySmall: _text.copyWith(fontSize: 12.5, height: 1.4, color: gray),
        labelLarge: _text.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: _text.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: gray,
        ),
        labelSmall: _text.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _text.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: background,
              disabledBackgroundColor: raised,
              disabledForegroundColor: muted,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: shape,
              textStyle: _text.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: .1,
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Color(0x22121212)),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          disabledBackgroundColor: raised,
          disabledForegroundColor: muted,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: shape,
          textStyle: _text.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: textPrimary,
              disabledForegroundColor: muted,
              side: const BorderSide(color: borderStrong),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: shape,
              textStyle: _text.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Color(0x14F5B800)),
              iconColor: const WidgetStatePropertyAll(gold),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          minimumSize: const Size(0, 44),
          textStyle: _text.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: _text.copyWith(color: muted, fontSize: 14),
        labelStyle: _text.copyWith(color: gray, fontSize: 14),
        floatingLabelStyle: _text.copyWith(color: gold, fontSize: 14),
        helperStyle: _text.copyWith(color: gray, fontSize: 12),
        errorStyle: _text.copyWith(color: danger, fontSize: 12),
        counterStyle: _text.copyWith(color: muted, fontSize: 11),
        prefixIconColor: gray,
        suffixIconColor: gray,
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(gold, 1.5),
        errorBorder: inputBorder(danger),
        focusedErrorBorder: inputBorder(danger, 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: card,
        selectedColor: gold,
        disabledColor: field,
        checkmarkColor: background,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => _text.copyWith(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? background
                : textPrimary,
          ),
        ),
        secondaryLabelStyle: _text.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: background,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? gold : card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? background : textPrimary,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          textStyle: WidgetStatePropertyAll(
            _text.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg + 2),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: _text.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: _text.copyWith(
          color: gray,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: border,
        thumbColor: gold,
        overlayColor: Color(0x22F5B800),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? background : gray,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? gold : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(background),
        side: const BorderSide(color: borderStrong, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? gold : borderStrong,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: border,
        circularTrackColor: border,
        linearMinHeight: 6,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: gold,
        textColor: textPrimary,
        minVerticalPadding: 12,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: _text.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: _text.copyWith(
          color: gray,
          fontSize: 13,
          height: 1.45,
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: raised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        textStyle: _text.copyWith(fontSize: 12),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: gold,
        selectionColor: Color(0x44F5B800),
        selectionHandleColor: gold,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: raised,
        contentTextStyle: _text.copyWith(fontSize: 14),
        actionTextColor: gold,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderStrong),
        ),
      ),
    );
  }
}
