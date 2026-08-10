import 'package:flutter/material.dart';

class AppColors {
  // Common Accents
  static const Color primaryAccent = Color(0xFF38BDF8);
  static const Color secondaryAccent = Color(0xFF818CF8);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Dark Theme
  static const Color darkBg = Color(0xFF0B1120);
  static const Color darkSecondaryBg = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Light Theme
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSecondaryBg = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightBorder = Color(0xFFCBD5E1);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,
      canvasColor: AppColors.darkSecondaryBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBg,
        error: AppColors.error,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
      ),
      textTheme: const TextTheme(
        // App title (24–28px, bold)
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.darkTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Page title (20–24px, semibold)
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Section title (16–18px, semibold)
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.darkTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Body (14–16px)
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextPrimary,
          fontFamily: 'sans-serif',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextSecondary,
          fontFamily: 'sans-serif',
        ),
        // Supporting text (12–14px)
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.darkTextSecondary,
          fontFamily: 'sans-serif',
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.darkBorder),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 0,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      canvasColor: AppColors.lightSecondaryBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryAccent,
        secondary: AppColors.secondaryAccent,
        surface: AppColors.lightSecondaryBg,
        background: AppColors.lightBg,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
      ),
      textTheme: const TextTheme(
        // App title (24–28px, bold)
        displayLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.lightTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Page title (20–24px, semibold)
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Section title (16–18px, semibold)
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.lightTextPrimary,
          fontFamily: 'sans-serif',
        ),
        // Body (14–16px)
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          color: AppColors.lightTextPrimary,
          fontFamily: 'sans-serif',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.lightTextSecondary,
          fontFamily: 'sans-serif',
        ),
        // Supporting text (12–14px)
        bodySmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.normal,
          color: AppColors.lightTextSecondary,
          fontFamily: 'sans-serif',
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.lightBorder),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        elevation: 0,
      ),
    );
  }
}
