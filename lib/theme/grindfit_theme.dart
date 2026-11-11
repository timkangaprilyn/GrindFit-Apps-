import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

import '../animations/grindfit_transitions.dart';

/// Shared black, gold and neutral surfaces used by the current app screens.
class GrindFitTheme {
  GrindFitTheme._();
  static const background = Color(0xFF121212);
  static const card = Color(0xFF1C1C1E);
  static const field = Color(0xFF171719);
  static const border = Color(0xFF2E2E31);
  static const gold = Color(0xFFF5B800);
  static const gray = Color(0xFF9CA3AF);
  static const white = Colors.white;

  static ThemeData get dark {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    OutlineInputBorder inputBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
    return ThemeData(
      brightness: Brightness.dark,
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
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: background,
        secondary: gold,
        onSecondary: background,
        surface: card,
        onSurface: white,
        primaryContainer: Color(0xFF332C16),
        onPrimaryContainer: gold,
        secondaryContainer: Color(0xFF29292D),
        onSecondaryContainer: white,
        outline: border,
        surfaceTint: Colors.transparent,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
          height: 1.2,
          color: white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -.2,
          color: white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: white,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: white,
        ),
        bodyLarge: TextStyle(fontSize: 14, height: 1.5, color: white),
        bodyMedium: TextStyle(fontSize: 13, height: 1.5, color: gray),
        bodySmall: TextStyle(fontSize: 12, height: 1.4, color: gray),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -.2,
          color: white,
        ),
        iconTheme: IconThemeData(color: white, size: 22),
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: background,
              disabledBackgroundColor: border,
              disabledForegroundColor: gray,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: shape,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: .2,
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Color(0x22121212)),
            ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: shape,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              foregroundColor: gold,
              side: const BorderSide(color: border, width: 1.2),
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: shape,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Color(0x14F5B800)),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: gray, fontSize: 13),
        labelStyle: const TextStyle(color: gray, fontSize: 13),
        counterStyle: const TextStyle(color: gray, fontSize: 11),
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(gold),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: field,
        selectedColor: gold,
        checkmarkColor: background,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: WidgetStateTextStyle.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? background : white,
          ),
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: background,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: const TextStyle(
          color: white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: gray,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: border,
        linearMinHeight: 6,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gold,
        textColor: white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: TextStyle(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(color: gray, fontSize: 12, height: 1.5),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: gold,
        selectionColor: Color(0x44F5B800),
        selectionHandleColor: gold,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF2A2A2D),
        contentTextStyle: const TextStyle(color: white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x55F5B800)),
        ),
      ),
    );
  }
}
