import 'package:flutter/material.dart';

class AppColorsD {
  static Color backgroundColor = const Color.fromARGB(255, 9, 37, 50);
  static Color primaryColor = const Color.fromARGB(255, 137, 201, 184);
  static Color secondaryColor = const Color.fromARGB(255, 199, 226, 178);
  static const Color tertiaryColor = Color.fromARGB(255, 225, 255, 194);
  static const Color textColor = Colors.white;
  static const Color errorButtonColor = Color.fromARGB(255, 255, 128, 128);
}

ThemeData MyDarkTheme = ThemeData(
  primaryColor: AppColorsD.primaryColor,
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 15, color: AppColorsD.textColor),
    bodyLarge: TextStyle(fontSize: 20, color: AppColorsD.textColor),
    bodySmall: TextStyle(fontSize: 12, color: AppColorsD.textColor),
  ),
);
