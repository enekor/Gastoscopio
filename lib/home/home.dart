import 'dart:collection';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/homeWidgets.dart' as hw;
import 'package:cuentas_android/widgets/views/homeWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pantallas/settings.dart';

class Home extends StatelessWidget {
  Home({super.key});

  final Rx<Cuenta?> _insertarC = Cuenta.empty().obs;
  Future _logout() async {
    await Auth().signOut();
  }

  void _navigateInfo(BuildContext context, Cuenta cuenta) {
    Values().cuentaRet.value = cuenta;
    writeSharedPreferences(
        SharedPreferencesKeys.cuenta, Values().cuentas.value.indexOf(cuenta));
  }

  void _navigateSettings(
    BuildContext context,
  ) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings()))
        .then((value) {
      if (value != null) {
        int insertar = value["insertar"];
        Cuenta cuenta = value["obj"];
        _insertarC.value = cuenta;

        if (insertar == 1) {
          cuentaDao().almacenarDatos(cuenta, kIsWeb);
        }
      }
    });
  }

  void onDelete(Cuenta cuenta, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text('Desea borrar el perfil ${cuenta.Nombre.value}'),
            IconButton(
                onPressed: () {
                  Values().cuentaRet.value = null;
                  Values().cuentas.value.remove(cuenta);

                  cuentaDao().deleteCuenta(cuenta, kIsWeb);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                icon: Icon(
                  Icons.delete_forever,
                  color: GetColor(ColorTypes.text, context),
                )),
            IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                icon: Icon(
                  Icons.cancel_rounded,
                  color: GetColor(ColorTypes.errorButton, context),
                ))
          ],
        ),
      ),
    );
  }

  List<int> GetAnnosDisponibles() {
    int annoActual = DateTime.now().year;
    HashSet<int> ret = HashSet<int>();

    for (Cuenta c in Values().cuentas.value) {
      RxList<int> annos = c.Meses.map((e) => e.Anno.value).toList().obs;
      ret.addAll(annos.value);
    }

    ret.add(annoActual);
    ret.add(annoActual + 1);
    ret.add(annoActual + 2);
    ret.add(annoActual + 3);

    return ret.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (Values().cuentas.value.isEmpty) {
      if (kIsWeb) {
        cuentaDao().getDatosJson().then((v) => Values().cuentas.value = v);
      } else {
        cuentaDao().getDatos(kIsWeb);
      }
    }

    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        extendBody: orientation == Orientation.landscape,
        appBar: orientation == Orientation.portrait
            ? appBar(
                context: context, onSettings: () => _navigateSettings(context))
            : null,
        body: Padding(
            padding: const EdgeInsets.only(top: 25.0),
            child: hw.hasData(
                orientation: orientation,
                context: context,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                navigateInfo: (cuenta) => _navigateInfo(context, cuenta),
                onDelete: (c) => onDelete(c, context))),
      ),
    );
  }
}
