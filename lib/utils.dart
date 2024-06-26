import 'dart:convert';
import 'dart:io';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  String type = Values().mostrarGatos.value ? "gato" : "persona";

  return 'lib/assets/images/$type${image.toString().replaceAll("ImageUris.", "")}.png';
}

enum SharedPreferencesKeys { gatos, fondoSimple, moneda, figuraAbajo }

enum ImageUris { ok, apunta, buscando, hola, RascandoCabeza }

enum ColorTypes { primary, secondary, tertiary, background, icono, error }

Color GetColor(ColorTypes type, BuildContext context) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;

  switch (type) {
    case ColorTypes.primary:
      return isDark ? AppColorsD.primaryColor : AppColorsL.primaryColor;

    case ColorTypes.secondary:
      return isDark ? AppColorsD.secondaryColor : AppColorsL.secondaryColor;

    case ColorTypes.tertiary:
      return isDark ? AppColorsD.tertiaryColor : AppColorsL.tertiaryColor;

    case ColorTypes.background:
      return isDark ? AppColorsD.backgroundColor : AppColorsL.backgroundColor;
    case ColorTypes.icono:
      return const Color.fromARGB(255, 135, 206, 234);
    case ColorTypes.error:
      return isDark ? AppColorsD.errorButtonColor : AppColorsL.errorButtonColor;
  }
}
