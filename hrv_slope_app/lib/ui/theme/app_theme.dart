/// App theme — Premium dark Material 3 design system for HRV Slope App.
library;

import 'package:flutter/material.dart';

/// HRV Slope App color palette.
abstract final class AppColors {
  static const primary = Color(0xFF4FC3F7); // Light blue
  static const primaryDark = Color(0xFF0288D1);
  static const secondary = Color(0xFF80CBC4); // Teal accent
  static const tertiary = Color(0xFFFFAB40); // Amber accent
  static const error = Color(0xFFEF5350);
  static const warning = Color(0xFFFFB74D);
  static const success = Color(0xFF66BB6A);

  static const surfaceDark = Color(0xFF121218);
  static const surfaceContainer = Color(0xFF1E1E2A);
  static const surfaceContainerHigh = Color(0xFF282838);
  static const surfaceContainerHighest = Color(0xFF333348);
  static const cardBorder = Color(0xFF3A3A50);

  static const textPrimary = Color(0xFFF0F0F8);
  static const textSecondary = Color(0xFFB0B0C0);
  static const textHint = Color(0xFF707088);

  // Classification colors
  static const classVeryHigh = Color(0xFFEF5350);
  static const classHighMod = Color(0xFFFFB74D);
  static const classExpected = Color(0xFF66BB6A);
  static const classLowFast = Color(0xFF4FC3F7);
}

/// Build the app's ThemeData.
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: Color(0xFF003355),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF003333),
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    ),
    scaffoldBackgroundColor: AppColors.surfaceDark,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      color: AppColors.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 0.5),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceContainer,
      indicatorColor: AppColors.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          );
        }
        return const TextStyle(fontSize: 12, color: AppColors.textSecondary);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF003355),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainerHigh,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerColor: AppColors.cardBorder,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceContainerHighest,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
