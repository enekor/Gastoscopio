import 'dart:convert';
import 'dart:io';
import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/toast.dart';
import 'package:cuentas_android/widgets/views/settingsWidget.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class Settings extends StatelessWidget {
  bool _cambiado = false;
  late List<Cuenta> cuentas = [Cuenta.empty()];
  Settings({super.key}) {
    cuentas.addAll(Values().cuentas.value);
  }

  Future _logout() async {
    await Auth().signOut();
    Values().cuentas.value.clear();
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
      Cuenta c =
          await cuentaDao().importFromJson(jsonMap, cuentas.length, kIsWeb);
      showToast(text: "Importado correctamente ${c.Nombre}");
    } else {
      // El usuario canceló la selección de archivos.
      return null;
    }
  }

  void _setFondoSimple() {
    Values().mostrarFondoDinamico.value = !Values().mostrarFondoDinamico.value;
    writeSharedPreferences(
        SharedPreferencesKeys.fondoSimple, Values().mostrarFondoDinamico.value);

    showToast(
        text: Values().mostrarFondoDinamico.value
            ? "Se muestra un bonito paisaje de fondo"
            : "No hay mas que soledad");
  }

  void _onAboutUs() async {
    Uri url = Uri.parse('https://www.youtube.com/watch?v=xvFZjo5PgG0');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _onChangeCurrency(String? currency) {
    writeSharedPreferences(SharedPreferencesKeys.moneda, currency);
    Values().moneda.value = currency ?? 'SM';
    showToast(text: "Ahora tu moneda es ${Values().moneda.value}");
  }

  void _onProfileColorChange(String newColor) {
    Values().cuentaRet.value!.color.value = newColor;
    cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
  }

  void _onNuevoPerfil(BuildContext context) {
    TextEditingController nombre = TextEditingController();
    String color = "#ffffff";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Color del perfil'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nombre,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                ColorPicker(
                    pickerColor: HexColor(color),
                    onColorChanged: (c) {
                      color = '#${c.value.toRadixString(16).padLeft(8, '0')}';
                      _cambiado = true;
                    }),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                cuentaDao().crearNuevaCuenta(
                    nombre.text, cuentaDao.count + 1, color, kIsWeb);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _onAdministrarTags(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();
        final tagController = TextEditingController();
        return AlertDialog(
          title: const Text('Manage Tags'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Form(
                key: formKey,
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: tagController,
                        decoration: const InputDecoration(
                          labelText: 'New Tag',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a tag';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              Values()
                                  .cuentaRet
                                  .value!
                                  .tags
                                  .value
                                  .add(tagController.text);
                            });
                            tagController.clear();
                          }
                        },
                        child: const Text('Add Tag'),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount:
                              Values().cuentaRet.value!.tags.value.length,
                          itemBuilder: (context, index) {
                            final tag =
                                Values().cuentaRet.value!.tags.value[index];
                            return ListTile(
                              title: Text(tag != "" ? tag : "Sin tag"),
                              trailing: tag != ""
                                  ? IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        setState(() {
                                          Values()
                                              .cuentaRet
                                              .value!
                                              .tags
                                              .value
                                              .removeAt(index);
                                        });
                                      },
                                    )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _onInicioMinimalista() {
    Values().inicioMinimalista.value = !Values().inicioMinimalista.value;
    writeSharedPreferences(
        SharedPreferencesKeys.minimalista, Values().inicioMinimalista.value);

    showToast(
        text: Values().inicioMinimalista.value
            ? "El home ahora es minimalista"
            : "El home da más información");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        child: OrientationBuilder(
      builder: (context, orientation) => Obx(
        () => Scaffold(
          backgroundColor: GetColor(ColorTypes.background, context),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text("Ajustes"),
            centerTitle: true,
            backgroundColor: Colors.transparent,
          ),
          resizeToAvoidBottomInset: true,
          body: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Container(
              decoration: Values().mostrarFondoDinamico.value
                  ? BoxDecoration(
                      image: DecorationImage(
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.3), BlendMode.darken),
                          image: AssetImage(Values().fondo.value),
                          fit: BoxFit.cover))
                  : null,
              child: Center(
                child: settingsBody(
                    isLandscape: orientation == Orientation.landscape,
                    cuentas: cuentas,
                    saveToJson: saveToJson,
                    importFromJson: importFromJson,
                    context: context,
                    onChangeTheme: _setFondoSimple,
                    onAboutUs: _onAboutUs,
                    onChangeCurrency: _onChangeCurrency,
                    onProfileColorChange: _onProfileColorChange,
                    onNuevoPerfil: () => _onNuevoPerfil(context),
                    onLogOut: _logout,
                    onAdminTags: () => _onAdministrarTags(context),
                    onMinimalista: _onInicioMinimalista),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
