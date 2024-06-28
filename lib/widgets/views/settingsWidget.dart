import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget settingsBody({required List<Cuenta> cuentas, required Function(Cuenta) saveToJson, required Function importFromJson, required BuildContext context, required Function(bool) onChangeStyle, required Function(bool) onChangeTheme, required Function onAboutUs, required Function(String) onChangeCurrency, required Function(bool) onChangeFiguraAbajo}){
  return Obx(()=> Center(
      child: Padding(
        padding: const EdgeInsets.all(50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
           !kIsWeb
            ?Column(
              children: [
                selectableSettingView(title: "Copia de seguridad", values: cuentas, onSelected: saveToJson, width: MediaQuery.of(context).size.width),
                const Divider(),
              ],
            )
            :Container(),
            buttonSettingView(text: "Restaurar copia", onTap: importFromJson),
            const Divider(),
            switchSettingView(onChange: onChangeStyle, text: "Estilos informales", inicial: Values().mostrarGatos.value),
            const Divider(),
            switchSettingView(onChange: onChangeTheme, text: "Fondo simple", inicial: Values().fondoSimple.value),
            const Divider(),
            switchSettingView(onChange: onChangeFiguraAbajo, text: "Ola inferior", inicial: Values().figuraAbajo.value),
            const Divider(),
            textBoxSettingView(title: "Moneda", placeholder: "Divisa", onClick: onChangeCurrency),
            const Divider(),
            redirectSettingView(onTap: onAboutUs, text: "Sobre nosotros")
          ],
        ),
      ),
    ),
  );
}