import 'package:flutter/material.dart';

/// GrindFit Centralized App Theme
class AppColors {
  AppColors._();

  // Core Brand Colors (Orange & Blue Theme)
  static const Color primaryOrange = Color(0xFFFF6B00); 
  static const Color secondaryBlue = Color(0xFF1A73E8); 
  static const Color accentBlue = Color(0xFF00B2FF);    

  // Background & Surface Colors (Light Mode)
  static const Color background = Color(0xFFF8F9FA);          
  static const Color backgroundSecondary = Color(0xFFF1F5F9);
  static const Color surface = Color(0xFFFFFFFF);             
  static const Color surfaceElevated = Color(0xFFEEF2F6);     

  // Text Colors (Dark Navy palette)
  static const Color textPrimary = Color(0xFF0F172A);   
  static const Color textSecondary = Color(0xFF475569); 
  static const Color textMuted = Color(0xFF94A3B8);     

  // Legacy Aliases para walang mag-error na lumang code
  static const Color neonCyan = primaryOrange;
  static const Color neonBlue = secondaryBlue;
  static const Color glow = orangeGlow;

  // Utility & Status Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981); 
  static const Color warning = Color(0xFFF59E0B);

  // Glow & Shadow Colors
  static const Color shadow = Color(0x1A000000);     
  static const Color orangeGlow = Color(0x40FF6B00); 
}

class AppRadius {
  AppRadius._();

  static const double small = 8.0;
  static const double medium = 14.0;
  static const double large = 20.0;
  static const double pill = 100.0;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const String? fontFamily = null;

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: Colors.white,
  );

  static const TextStyle linkText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryOrange,
  );
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> orangeGlow = [
    const BoxShadow(
      color: AppColors.orangeGlow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // DITO ANG FIX: Naka-map sa orangeGlow ang neonGlow para maayos ang 5 errors
  static List<BoxShadow> neonGlow = orangeGlow;

  static List<BoxShadow> softCard = [
    const BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryOrange,
      fontFamily: AppTextStyles.fontFamily,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryOrange,
        secondary: AppColors.secondaryBlue,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.heading2,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryOrange,
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        headlineMedium: AppTextStyles.heading1,
        titleMedium: AppTextStyles.heading2,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.caption,
      ),
    );
  }
}