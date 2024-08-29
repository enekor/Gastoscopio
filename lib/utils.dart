import 'dart:convert';
import 'dart:io';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/ITheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> writeToDownloadPath(Cuenta cuenta) async {
  final _downloadPath = "/storage/emulated/0/Download/gastoscopioBackup";
  final _jsonFile;

  try {
    _jsonFile = File("$_downloadPath/${cuenta.Nombre}Data.json");

    String data = jsonEncode(cuenta.toJson());

    await _jsonFile.create();
    await _jsonFile.writeAsString(data);

    return true;
  } on Exception catch (e) {
    return false;
  }
}

Future writeSharedPreferences(SharedPreferencesKeys key, dynamic value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (value is int) {
    prefs.setInt(
        key.toString().replaceAll("SharedPreferencesKeys.", ""), value);
  } else if (value is String) {
    prefs.setString(
        key.toString().replaceAll("SharedPreferencesKeys.", ""), value);
  } else if (value is double) {
    prefs.setDouble(
        key.toString().replaceAll("SharedPreferencesKeys.", ""), value);
  } else if (value is bool) {
    prefs.setBool(
        key.toString().replaceAll("SharedPreferencesKeys.", ""), value);
  } else if (value is List<String>) {
    prefs.setStringList(
        key.toString().replaceAll("SharedPreferencesKeys.", ""), value);
  }
}

Future<T> readSharedPreferences<T>(SharedPreferencesKeys key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  switch (T) {
    case int:
      return (prefs.getInt(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          -1) as T;
    case String:
      return (prefs.getString(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          "") as T;
    case double:
      return (prefs.getDouble(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          double.nan) as T;
    case List<String>:
      return (prefs.getStringList(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          []) as T;
    case bool:
      return (prefs.getBool(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          false) as T;
    default:
      return null as T;
  }
}

Widget getEmailIcon(String email) {
  late FaIcon ret;
  switch (email) {
    case "gastoscopio.com":
      ret = const FaIcon(FontAwesomeIcons.piggyBank);
      break;
    case "gmail.com":
      ret = const FaIcon(FontAwesomeIcons.google);
      break;
    case "hotmail.com":
      ret = const FaIcon(FontAwesomeIcons.microsoft);
      break;
    case "outlook.com":
      ret = const FaIcon(FontAwesomeIcons.envelopeOpen);
      break;
    case "yahoo.com":
      ret = const FaIcon(FontAwesomeIcons.yahoo);
      break;
    default:
      ret = const FaIcon(FontAwesomeIcons.a);
      break;
  }

  return ret;
}

String getImageUri(ImageUris image) {
  switch (image) {
    case ImageUris.logo:
      return 'lib/assets/images/logo.png';
    case ImageUris.logosvg:
      return 'lib/assets/images/logo.svg';
    case ImageUris.nuevo:
      return 'lib/assets/images/nuevo.png';
  }
}

enum SharedPreferencesKeys { fondoSimple, moneda, figuraAbajo, cuenta }

enum ImageUris { logo, logosvg, nuevo }

enum ShowingGastos { ingresos, gastos, extras, deuda, fijo }

enum ColorTypes { background, primary, secondary, tertiary, errorButton, text }

Color GetColor(ColorTypes type, BuildContext context) {
  ITheme tema = Theme.of(context).brightness == Brightness.light
      ? AppColorsL()
      : AppColorsD();
  switch (type) {
    case ColorTypes.primary:
      return tema.primaryColor;
    case ColorTypes.secondary:
      return tema.secondaryColor;
    case ColorTypes.errorButton:
      return tema.errorButtonColor;
    case ColorTypes.background:
      return tema.backgroundColor;
    case ColorTypes.text:
      return tema.textColor;
    case ColorTypes.tertiary:
      return tema.tertiary;
  }
}
