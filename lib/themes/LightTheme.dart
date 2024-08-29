import 'package:cuentas_android/themes/ITheme.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColorsL implements ITheme {
  @override
  Color backgroundColor = HexColor('#fdfdff');
  @override
  Color primaryColor = HexColor('#575594');
  @override
  Color secondaryColor = HexColor('#817fb2');
  @override
  Color textColor = Colors.black;
  @override
  Color errorButtonColor = const Color.fromARGB(255, 255, 104, 104);
  @override
  Color tertiary = HSVColor.fromColor(HexColor('#a8aa6b'))
      .withSaturation(0.1)
      .toColor()
      .withOpacity(0.8);
}

ThemeData MyLightTheme = ThemeData(
  primaryColor: const Color.fromARGB(255, 229, 244, 231),
  useMaterial3: true,
  brightness: Brightness.light,
  textTheme: TextTheme(
    bodyMedium: GoogleFonts.mukta(fontSize: 15, color: Colors.black),
    bodyLarge: GoogleFonts.mukta(fontSize: 20, color: Colors.black),
    bodySmall: GoogleFonts.mukta(fontSize: 12, color: Colors.black),
    displayMedium: GoogleFonts.mukta(fontSize: 15, color: Colors.black),
    displayLarge: GoogleFonts.mukta(fontSize: 20, color: Colors.black),
    displaySmall: GoogleFonts.mukta(fontSize: 12, color: Colors.black),
  ),
);
