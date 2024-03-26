import 'package:flutter/material.dart';

class AppColorsL{
  static Color primaryColor = Colors.pink[50]!;
  static const Color secondaryColor1 = Color.fromRGBO(255, 230, 230, 1);
  static const Color secondaryColor2 = Color.fromRGBO(255, 175, 209, 1);
  static const Color secondaryColor3 = Color.fromRGBO(173, 136, 198, 1);
  static const Color secondaryColor4 = Color.fromRGBO(116, 105, 182, 1);
  static const Color secondaryColor5 = Color.fromRGBO(190, 173, 250, 1);
  static const Color okButtonColor = Color.fromRGBO(119, 221, 119,1);
  static const Color errorButtonColor = Color.fromRGBO(255, 105, 97,1);
  static const Color textColor = Colors.black87;
}

ThemeData MyLightTheme = ThemeData(
  primaryColor: AppColorsL.primaryColor,
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 15,color:AppColorsL.textColor),
    bodyLarge: TextStyle(fontSize: 20,color:AppColorsL.textColor),
    bodySmall: TextStyle(fontSize: 12,color:AppColorsL.textColor),
  ),
);