import 'package:cuentas_android/themes/hexColor.dart';
import 'package:flutter/material.dart';

class AppColorsC {
  static Color backgroundColor = HexColor('#F1FDF3');
  static Color appBarColor = HexColor('#99CDA9');
  static Color cardColor = HexColor('#D1E9D2');
  static Color primaryColor = HexColor('#A0ECBC');
  static Color errorButtonColor = HexColor('#FF3131');
  static Color switchBackColor = HexColor('#A0ECBC');
  static Color switchCircleColor = HexColor('#F1FDF3');
  static Color switchHoverColor = HexColor('#D1E9D2');
  static const Color textColor = Colors.black;
}

ThemeData MyCustomTheme = ThemeData(
  useMaterial3: true,
  primaryColor: AppColorsC.primaryColor,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 15, color: AppColorsC.textColor),
    bodyLarge: TextStyle(fontSize: 20, color: AppColorsC.textColor),
    bodySmall: TextStyle(fontSize: 12, color: AppColorsC.textColor),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStatePropertyAll(AppColorsC.switchCircleColor),
    trackColor: MaterialStatePropertyAll(AppColorsC.switchBackColor),
    overlayColor: MaterialStatePropertyAll(AppColorsC.switchHoverColor),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    focusColor: Colors.black,
    fillColor: Colors.black,
    hoverColor: Colors.black,
    labelStyle: TextStyle(color: Colors.black),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedLabelStyle:
          const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(color: Colors.black),
      backgroundColor: AppColorsC.appBarColor,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      enableFeedback: false),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColorsC.appBarColor,
    extendedTextStyle: const TextStyle(color: Colors.black),
  ),
  cardTheme: CardTheme(color: AppColorsC.cardColor),
  colorScheme: ColorScheme(
      background: AppColorsC.backgroundColor,
      brightness: Brightness.dark,
      primary: AppColorsC.primaryColor,
      onPrimary: AppColorsC.primaryColor,
      secondary: AppColorsC.cardColor,
      onSecondary: AppColorsC.cardColor,
      error: AppColorsC.errorButtonColor,
      onError: AppColorsC.errorButtonColor,
      onBackground: AppColorsC.backgroundColor,
      surface: Colors.black,
      onSurface: Colors.black),
);
