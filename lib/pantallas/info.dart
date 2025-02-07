import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/pantallas/compararPrecios/compararPrecios.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/pantallas/presupuestos/budget.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/info/InfoWidgets.dart';
import 'package:cuentas_android/widgets/views/info/IngresosGastosWidgets.dart';
import 'package:cuentas_android/widgets/views/info/summaryWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  void _onNewMes(String mes) {
    if (Values().cuentaRet.value != null &&
        Values().cuentaRet.value!.ExistsMes(Values().anno.value, mes)) {
      setState(() {
        Values().mes.value = mes;
      });
    } else {
      _newMesGenerator(mes);
    }
  }

  void _newMesGenerator(String mes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Crear nuevo mes?'),
        content: Text(
            'Se generará $mes de ${Values().anno.value} y se aplicaran los gastos almacenados en "Gastos fijos"'),
        actions: [
          IconButton(
              onPressed: () {
                if (Values().cuentaRet.value != null) {
                  Values().cuentaRet.value!.NewMes(Values().anno.value, mes);
                }

                setState(() {
                  Values().mes.value = mes;
                  Navigator.pop(context);
                });
              },
              icon: Icon(
                Icons.check_circle,
                color: GetColor(ColorTypes.primary, context),
              )),
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.cancel_rounded,
                color: GetColor(ColorTypes.errorButton, context),
              ))
        ],
      ),
    );
  }

  void _onSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings()))
        .then((value) {
      setState(() {});
    });
  }

  void _onComparar(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => CompararPrecios()))
        .then((_) => setState(() {}));
  }

  void _onSummary() {
    Values().selectedScreen = 3;
  }

  @override
  Widget build(BuildContext context) {
    void onNew() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => createNew()))
          .then((_) => setState(() {}));
    }

    void onBack() {
      if (Values().selectedScreen == 0) {
        SystemNavigator.pop(animated: true);
      } else {
        setState(() {
          Values().selectedScreen = 0;
        });
      }

      if (Values().cuentaRet.value != null) {
        cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
      }
    }

    void onUser() {
      if (Values().cuentaRet.value != null) {
        setState(() {
          Values().cuentaRet.value = null;
        });
        writeSharedPreferences(SharedPreferencesKeys.cuenta, -1);
      }
    }

    List<Widget> pantallas = [
      InfoHasData(
          onGastosSelected: (ingresos) => {},
          onNewMes: _onNewMes,
          onUser: onUser,
          onSummary: _onSummary,
          context: context),
      IngresosGastosHasData(context),
      Container(),
      summaryHasData(context),
      const BudgetPage()
    ];

    List<Widget> pantallasLand = [
      InfoHasDataLand(
          onGastosSelected: (ingresos) => {},
          onNewMes: _onNewMes,
          onUser: onUser,
          onSummary: () => _onSummary(),
          context: context),
      IngresosGastosHasData(context, isLandscape: true),
      Container(),
      summaryHasData(context, isLandscape: true),
      const BudgetPage()
    ];

    return PopScope(
      child: Scaffold(
        backgroundColor: GetColor(ColorTypes.background, context),
        appBar: Values().selectedScreen != 1
            ? InfoAppBar(
                onBack: onBack,
                onSettings: () => _onSettings(context),
                onComparar: () => _onComparar(context),
                context: context)
            : null,
        extendBodyBehindAppBar: true,
        body: SizedBox(
          height: double.infinity,
          child: OrientationBuilder(
              builder: (context, orientation) =>
                  orientation == Orientation.portrait
                      ? pantallas[Values().selectedScreen]
                      : pantallasLand[Values().selectedScreen]),
        ),
        bottomNavigationBar: InfoBottomNavigationBar(
            selected: Values().selectedScreen,
            onChange: (sel) => setState(() {
                  Values().selectedScreen = sel;
                }),
            onNew: onNew,
            context: context),
      ),
    );
  }
}
