import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget settingsBody(
    {required List<Cuenta> cuentas,
    required Function(Cuenta) saveToJson,
    required Function importFromJson,
    required BuildContext context,
    required Function onAboutUs,
    required Function(String) onChangeCurrency,
    required Function(String) onProfileColorChange,
    required Function() onNuevoPerfil,
    required Function() onLogOut,
    required bool isLandscape}) {
  return SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _generalPart(onChangeCurrency: onChangeCurrency, context: context),
          _accountPart(
              onProfileColorChange: onProfileColorChange,
              onNuevoPerfil: onNuevoPerfil,
              onLogOut: onLogOut,
              context: context),
          _backupPart(
              saveToJson: saveToJson,
              importFromJson: importFromJson,
              context: context,
              cuentas: cuentas),
          redirectSettingView(
              onTap: onAboutUs, text: "Sobre nosotros", textColor: Colors.blue),
        ],
      ),
    ),
  );
}

Widget _backupPart(
    {required Function(Cuenta) saveToJson,
    required Function importFromJson,
    required BuildContext context,
    required List<Cuenta> cuentas}) {
  return AnimatedCard(
    text: "Copia de seguridad",
    icon: const Icon(
      Icons.backup,
    ),
    children: [
      !kIsWeb
          ? Column(
              children: [
                selectableSettingView(
                    title: "Copia de seguridad",
                    values: cuentas,
                    onSelected: saveToJson,
                    width: MediaQuery.of(context).size.width),
                const Divider(),
              ],
            )
          : Container(),
      buttonSettingView(
          icono: Icons.refresh_rounded,
          text: "Restaurar copia",
          onTap: importFromJson),
    ],
  );
}

Widget _accountPart(
    {required Function(String) onProfileColorChange,
    required Function() onNuevoPerfil,
    required Function() onLogOut,
    required BuildContext context}) {
  return AnimatedCard(
      text: 'Cuenta',
      icon: const Icon(
        Icons.person,
      ),
      children: [
        Values().cuentaRet.value != null
            ? Column(
                children: [
                  const Divider(),
                  colorPickerView(
                      onChange: onProfileColorChange,
                      text: 'Color del perfil',
                      initialColor:
                          HexColor(Values().cuentaRet.value!.color.value),
                      context: context),
                ],
              )
            : Container(),
        const Divider(),
        buttonSettingView(
            icono: Icons.person_add_rounded,
            text: "Nuevo perfil",
            onTap: onNuevoPerfil),
        const Divider(),
        redirectSettingView(
            onTap: () {
              onLogOut();
              Navigator.pop(context);
            },
            text: "Cerrar sesion",
            textColor: Colors.red),
      ]);
}

Widget _generalPart(
    {required Function(String) onChangeCurrency,
    required BuildContext context}) {
  return AnimatedCard(
      text: 'General',
      icon: const Icon(
        Icons.home,
      ),
      children: [
        selectableSettingView(
          onSelected: onChangeCurrency,
          values: ['€', '\$', 'COP', '¥'],
          title: "Moneda",
          width: MediaQuery.of(context).size.width,
          initialValue:
              Values().moneda.value == "" ? null : Values().moneda.value,
        ),
      ]);
}
