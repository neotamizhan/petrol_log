import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF0D968B);
  static const primaryDark = Color(0xFF0A756C);
  static const accentAmber = Color(0xFFF59E0B);
  static const accentBlue = Color(0xFF38BDF8);
  static const accentPurple = Color(0xFF8B5CF6);

  static const backgroundLight = Color(0xFFF6F8F8);
  static const backgroundDark = Color(0xFF102220);

  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF162E2B);
  static const surfaceDarkElevated = Color(0xFF1C3835);

  static const outlineLight = Color(0xFFE2E8F0);
  static const outlineDark = Color(0xFF234845);
}

class AppTheme {
  static ThemeData light() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );
    final scheme = baseScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentAmber,
      onSecondary: const Color(0xFF231606),
      tertiary: AppColors.accentPurple,
      onTertiary: Colors.white,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
      background: AppColors.backgroundLight,
      onBackground: const Color(0xFF0F172A),
      surface: AppColors.surfaceLight,
      onSurface: const Color(0xFF0F172A),
      outline: AppColors.outlineLight,
      outlineVariant: const Color(0xFFCBD5E1),
      surfaceVariant: const Color(0xFFF1F5F9),
      surfaceTint: AppColors.primary,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );
    final scheme = baseScheme.copyWith(
      primary: AppColors.primary,
      onPrimary: const Color(0xFF0B1F1E),
      secondary: AppColors.accentAmber,
      onSecondary: const Color(0xFF1E1405),
      tertiary: AppColors.accentPurple,
      onTertiary: const Color(0xFF140E2A),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF2A0E0E),
      background: AppColors.backgroundDark,
      onBackground: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: Colors.white,
      outline: AppColors.outlineDark,
      outlineVariant: const Color(0xFF1F3F3C),
      surfaceVariant: AppColors.surfaceDarkElevated,
      surfaceTint: AppColors.primary,
    );

    final textTheme = GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme)
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
