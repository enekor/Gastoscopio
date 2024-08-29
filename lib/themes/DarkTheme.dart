import 'package:cuentas_android/themes/ITheme.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColorsD implements ITheme {
  @override
  Color backgroundColor = HexColor('#0f0022');
  @override
  Color primaryColor = HexColor('#311357');
  @override
  Color secondaryColor = HexColor('#5f4182');
  @override
  Color textColor = Colors.white;
  @override
  Color errorButtonColor = Color.fromARGB(255, 255, 128, 128);
  @override
  Color tertiary = HSVColor.fromColor(HexColor('#ceeca8'))
      .withSaturation(0.1)
      .toColor()
      .withOpacity(0.8);
}

ThemeData MyDarkTheme = ThemeData(
  primaryColor: const Color.fromARGB(255, 137, 201, 184),
  useMaterial3: true,
  brightness: Brightness.dark,
  textTheme:  TextTheme(
    bodyMedium: GoogleFonts.mukta(fontSize: 15, color: Colors.white),
    bodyLarge: GoogleFonts.mukta(fontSize: 20, color: Colors.white),
    bodySmall: GoogleFonts.mukta(fontSize: 12, color: Colors.white),
    displayMedium: GoogleFonts.mukta(fontSize: 15, color: Colors.black),
    displayLarge: GoogleFonts.mukta(fontSize: 20, color: Colors.black),
    displaySmall: GoogleFonts.mukta(fontSize: 12, color: Colors.black),
  ),
);
