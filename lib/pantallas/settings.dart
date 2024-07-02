import 'dart:convert';
import 'dart:io';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:cuentas_android/widgets/views/settingsWidget.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatelessWidget {
  late List<Cuenta> cuentas = [
    Cuenta(id: "", Nombre: "Seleccionar cuenta", Meses: [], posicion: -1)
  ];
  Settings({super.key, required List<Cuenta> cc}) {
    cuentas.addAll(cc);
  }

  Future saveToJson(Cuenta cuenta) async {
    if (cuenta.posicion != -1) {
      bool saved = await writeToDownloadPath(cuenta);
      if (saved) {
        showToast(text: "Guardado correctamente en la carpeta de descargas");
      }
    }
  }

  Future importFromJson() async {
    late Map<String, dynamic> jsonMap;
    late Cuenta cuenta;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      File json = File(result.files.single.path!);
      String jsonString = await json.readAsString();
      jsonMap = jsonDecode(jsonString);
      Cuenta c = await cuentaDao().importFromJson(jsonMap, cuentas.length);
      showToast(text: "Importado correctamente ${c.Nombre}");
    } else {
      // El usuario canceló la selección de archivos.
      return null;
    }
  }

  void _setImageStyle(bool gatos) async {
    writeSharedPreferences(SharedPreferencesKeys.gatos, gatos);
    Values().mostrarGatos.value = gatos;
    showToast(
        text: gatos
            ? "Ahora las imagenes serán gatos"
            : "Ahora las imagenes serán personas");
  }

  void _setFondoSimple(bool simple) async {
    writeSharedPreferences(SharedPreferencesKeys.fondoSimple, simple);
    Values().fondoSimple.value = simple;
    showToast(
        text: !simple
            ? "El fondo tiene circulos aleatorios"
            : "No hay mas que soledad");
  }

  void _onAboutUs() async {
    Uri url = Uri.parse('https://www.youtube.com/watch?v=xvFZjo5PgG0');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _onChangeCurrency(String currency) {
    writeSharedPreferences(SharedPreferencesKeys.moneda, currency);
    Values().moneda.value = currency;
    showToast(text: "Ahora tu moneda es ${Values().moneda.value}");
  }

  void _onChangeFiguraAbajo(bool active) {
    writeSharedPreferences(SharedPreferencesKeys.figuraAbajo, active);
    Values().figuraAbajo.value = active;
    showToast(
        text: active
            ? "Ahora se muestra un ola en la parte de abajo"
            : "Parece que hay sequía");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: CustomPaint(
            painter: MyPattern(context),
            child: SingleChildScrollView(
                child: settingsBody(
                    cuentas: cuentas,
                    saveToJson: saveToJson,
                    importFromJson: importFromJson,
                    context: context,
                    onChangeStyle: _setImageStyle,
                    onChangeTheme: _setFondoSimple,
                    onAboutUs: _onAboutUs,
                    onChangeCurrency: _onChangeCurrency,
                    onChangeFiguraAbajo: _onChangeFiguraAbajo))),
      ),
    );
  }
}
