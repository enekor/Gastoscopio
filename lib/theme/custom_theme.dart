import 'package:flutter/material.dart';
import 'package:cashly/theme/app_theme_variant.dart';
import 'package:cashly/theme/app_glass.dart';

class CustomTheme {
  static ThemeData build(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.etherealLedger => _ethereal(),
      AppThemeVariant.obsidian => _obsidian(),
    };
  }

  static ThemeData _ethereal() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF10B981),
      onPrimary: Color(0xFF04231A),
      primaryContainer: Color(0xFF0E3D2E),
      onPrimaryContainer: Color(0xFF6FFBBE),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF00311F),
      surface: Color(0xFF131315),
      onSurface: Color(0xFFE4E2E4),
      surfaceContainerLowest: Color(0xFF0E0E10),
      surfaceContainerLow: Color(0xFF1B1B1D),
      surfaceContainer: Color(0xFF1F1F21),
      surfaceContainerHigh: Color(0xFF2A2A2B),
      surfaceContainerHighest: Color(0xFF353436),
      onSurfaceVariant: Color(0xFFC6C6CD),
      outline: Color(0xFF45464D),
      outlineVariant: Color(0xFF2A2A2E),
      error: Color(0xFFFB7185),
      onError: Color(0xFF3B0512),
    );
    return _baseFrom(scheme, AppGlass.ethereal, const Color(0xFF0F172A));
  }

  static ThemeData _obsidian() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFA78BFA),
      onPrimary: Color(0xFF20124D),
      primaryContainer: Color(0xFF2A2440),
      onPrimaryContainer: Color(0xFFCDBEFF),
      secondary: Color(0xFF34D399),
      onSecondary: Color(0xFF00291B),
      tertiary: Color(0xFF34D399),
      surface: Color(0xFF0C0C0F),
      onSurface: Color(0xFFFAFAFA),
      surfaceContainerLowest: Color(0xFF09090B),
      surfaceContainerLow: Color(0xFF121215),
      surfaceContainer: Color(0xFF18181B),
      surfaceContainerHigh: Color(0xFF1F1F23),
      surfaceContainerHighest: Color(0xFF27272A),
      onSurfaceVariant: Color(0xFFA1A1AA),
      outline: Color(0xFF27272A),
      outlineVariant: Color(0xFF27272A),
      error: Color(0xFFEF4444),
      onError: Color(0xFF2A0606),
    );
    return _baseFrom(scheme, AppGlass.obsidian, const Color(0xFF09090B));
  }

  static ThemeData _baseFrom(ColorScheme scheme, AppGlass glass, Color bg) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      extensions: <ThemeExtension<dynamic>>[glass],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glass.cardRadius),
          side: BorderSide(color: glass.glassBorder, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(glass.pillRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: glass.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(glass.pillRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: glass.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glass.cardRadius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        side: BorderSide(color: glass.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
