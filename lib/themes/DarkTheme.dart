import 'package:flutter/material.dart';

class AppColorsD{
  static Color primaryColor = Colors.purple[400]!;
  static const Color secondaryColor1 =  Color.fromARGB(249, 255, 199, 199);
  static const Color secondaryColor2 =  Color.fromARGB(255, 247, 137, 183);
  static const Color secondaryColor3 =  Color.fromARGB(255, 149, 94, 185);
  static const Color secondaryColor4 =  Color.fromARGB(255, 100, 85, 180);
  static const Color secondaryColor5 =  Color.fromARGB(255, 149, 123, 245);
  static const Color okButtonColor = Color.fromRGBO(29, 115, 29,1);
  static const Color errorButtonColor = Color.fromRGBO(	225, 11, 0,1);
  static const Color textColor = Colors.white70;
}

ThemeData MyDarkTheme = ThemeData(
  primaryColor: AppColorsD.primaryColor,
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 15,color:AppColorsD.textColor),
    bodyLarge: TextStyle(fontSize: 20,color:AppColorsD.textColor),
    bodySmall: TextStyle(fontSize: 12,color:AppColorsD.textColor),
  ),
);