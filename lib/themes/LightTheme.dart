import 'package:flutter/material.dart';

class AppColorsL {
  static Color backgroundColor = const Color.fromARGB(255, 241, 253, 243);
  static Color primaryColor = const Color.fromARGB(255, 229, 244, 231);
  static Color secondaryColor = const Color.fromARGB(255, 209, 233, 210);
  static Color tertiaryColor = const Color.fromARGB(255, 153, 205, 169);
  static Color textColor = Colors.black;
  static const Color errorButtonColor = Color.fromARGB(255, 255, 104, 104);
}

ThemeData MyLightTheme = ThemeData(
  primaryColor: AppColorsL.primaryColor,
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: TextTheme(
    bodyMedium: TextStyle(fontSize: 15, color: AppColorsL.textColor),
    bodyLarge: TextStyle(fontSize: 20, color: AppColorsL.textColor),
    bodySmall: TextStyle(fontSize: 12, color: AppColorsL.textColor),
  ),
);
