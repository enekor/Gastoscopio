import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData createTheme(ColorScheme? dynamicScheme) {
    // Si no hay esquema dinámico, usar el morado como base
    final ColorScheme baseScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,

      // Superficies y fondos
      scaffoldBackgroundColor: baseScheme.background,
      cardTheme: CardThemeData(
        color: baseScheme.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: baseScheme.outlineVariant, width: 1),
        ),
      ),

      // Botones
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseScheme.primary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: baseScheme.outline),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Diálogos y snackbars
      dialogTheme: DialogThemeData(
        backgroundColor: baseScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseScheme.secondaryContainer,
        contentTextStyle: TextStyle(color: baseScheme.onSecondaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Chips y segmentos
      chipTheme: ChipThemeData(
        backgroundColor: baseScheme.surfaceVariant,
        labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
        side: BorderSide(color: baseScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return baseScheme.primaryContainer;
            }
            return baseScheme.surface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return baseScheme.onPrimaryContainer;
            }
            return baseScheme.onSurface;
          }),
        ),
      ),
    );
  }

  static ThemeData createDarkTheme(ColorScheme? dynamicScheme) {
    // Si no hay esquema dinámico, usar el morado como base
    final ColorScheme baseScheme =
        dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,

      // Superficies y fondos
      scaffoldBackgroundColor: baseScheme.background,
      cardTheme: CardThemeData(
        color: baseScheme.surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: baseScheme.outlineVariant, width: 1),
        ),
      ),

      // Botones
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseScheme.primary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide(color: baseScheme.outline),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseScheme.surfaceVariant.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: baseScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Diálogos y snackbars
      dialogTheme: DialogThemeData(
        backgroundColor: baseScheme.surface,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseScheme.secondaryContainer,
        contentTextStyle: TextStyle(color: baseScheme.onSecondaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // Chips y segmentos
      chipTheme: ChipThemeData(
        backgroundColor: baseScheme.surfaceVariant,
        labelStyle: TextStyle(color: baseScheme.onSurfaceVariant),
        side: BorderSide(color: baseScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return baseScheme.primaryContainer;
            }
            return baseScheme.surface;
          }),
          foregroundColor: MaterialStateProperty.resolveWith<Color>((
            Set<MaterialState> states,
          ) {
            if (states.contains(MaterialState.selected)) {
              return baseScheme.onPrimaryContainer;
            }
            return baseScheme.onSurface;
          }),
        ),
      ),
    );
  }
}
