import 'dart:convert';
import 'dart:io';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/ITheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> writeToDownloadPath(Cuenta cuenta) async {
  const downloadPath = "/storage/emulated/0/Download/gastoscopioBackup";
  final File jsonFile;

  try {
    jsonFile = File("$downloadPath/${cuenta.Nombre}Data.json");

    String data = jsonEncode(cuenta.toJson());

    await jsonFile.create();
    await jsonFile.writeAsString(data);

    return true;
  } on Exception {
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
    case bool:
      return (prefs.getBool(
              key.toString().replaceAll("SharedPreferencesKeys.", "")) ??
          false) as T;
    default:
      return null as T;
  }
}

String getImageUri(ImageUris image) {
  switch (image) {
    case ImageUris.logo:
      return 'lib/assets/images/logo.png';
    case ImageUris.logosvg:
      return 'lib/assets/images/logo.svg';
    case ImageUris.nuevo:
      return 'lib/assets/images/nuevo.png';
    case ImageUris.loading:
      return 'lib/assets/images/loading.gif';
  }
}

enum SharedPreferencesKeys { fondoSimple, moneda, figuraAbajo, cuenta }

enum ImageUris { logo, logosvg, nuevo, loading }

enum ShowingGastos { ingresos, gastos, extras, deuda, fijo }

enum ColorTypes { background, primary, secondary, tertiary, errorButton, text }

enum OrderByTypes { dateAsc, dateDesc, name, value }
