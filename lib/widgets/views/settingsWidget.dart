import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget settingsBody(
    {required List<Cuenta> cuentas,
    required Function(Cuenta) saveToJson,
    required Function importFromJson,
    required BuildContext context,
    required Function(bool) onChangeTheme,
    required Function onAboutUs,
    required Function(String) onChangeCurrency,
    required Function(String) onProfileColorChange,
    required Function() onNuevoPerfil,
    required Function() onLogOut,
    required bool isLandscape}) {
  return Obx(
    () => Center(
      child: Padding(
        padding: EdgeInsets.only(
            left: isLandscape ? 150 : 10,
            right: isLandscape ? 150 : 10,
            top: 10,
            bottom: 10),
        child: Card(
          color: GetColor(ColorTypes.primary, context).withOpacity(0.94),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const Divider(),
                switchSettingView(
                    onChange: onChangeTheme,
                    text: "Fondo dinamico",
                    inicial: Values().mostrarFondoDinamico.value),
                const Divider(),
                textBoxSettingView(
                    title: "Moneda",
                    placeholder: "Divisa",
                    onClick: onChangeCurrency),
                Values().cuentaRet.value != null
                    ? Column(
                        children: [
                          const Divider(),
                          colorPickerView(
                              onChange: onProfileColorChange,
                              text: 'Color del perfil',
                              initialColor: HexColor(
                                  Values().cuentaRet.value!.color.value),
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
                    onTap: onAboutUs,
                    text: "Sobre nosotros",
                    textColor: Colors.blue),
                const Divider(),
                redirectSettingView(
                    onTap: () {
                      onLogOut();
                      Navigator.pop(context);
                    },
                    text: "Cerrar sesion",
                    textColor: Colors.red),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
