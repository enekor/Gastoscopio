import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/widgets/views/info/IngresosGastosWidgets.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/info/InfoWidgets.dart';
import 'package:cuentas_android/widgets/views/info/summaryWidgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Info extends StatelessWidget {
  Info({super.key});

  void _onNewMes(String mes) {
    if (Values()
        .cuentaRet
        .value!
        .ExistsMes(Values().anno.value, Values().mes.value)) {
      Values().mes.value = mes;
    } else {
      Values().cuentaRet.value!.NewMes(Values().anno.value, Values().mes.value);
      Values().mes.value = mes;
    }
  }

  void _onSettings(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings()))
        .then((value) {
      if (value != null) {}
    });
  }

  void _onChartTouched(int section) {
    bool verGastos = false;
    switch (section) {
      case 0:
        Values().showing.value = ShowingGastos.ingresos;
        Values().selectedScreen.value = 1;
        break;
      case 1:
        Values().showing.value = ShowingGastos.gastos;
        Values().selectedScreen.value = 1;
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    void _onNew() {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => createNew()));
    }

    void _onBack() {
      if (Values().selectedScreen.value == 0) {
        Navigator.pop(context);
      } else {
        Values().selectedScreen.value = 0;
      }

      cuentaDao().almacenarDatos(Values().cuentaRet.value!);
    }

    void _onUser() {
      Values().cuentaRet.value = null;
      writeSharedPreferences(SharedPreferencesKeys.cuenta, -1);
    }

    List<Widget> pantallas = [
      InfoHasData(
          onGastosSelected: (ingresos) => {},
          onNewMes: _onNewMes,
          onChartTouched: _onChartTouched,
          context: context),
      IngresosGastosHasData(context),
      Container(),
      summaryHasData(context),
      Container(),
    ];

    List<Widget> pantallasLand = [
      InfoHasDataLand(
          onGastosSelected: (ingresos) => {},
          onNewMes: _onNewMes,
          onChartTouched: _onChartTouched,
          context: context),
      IngresosGastosHasData(context, isLandscape: true),
      Container(),
      summaryHasData(context, isLandscape: true),
      Container(),
    ];

    return PopScope(
        child: Obx(
      () => Scaffold(
        backgroundColor: GetColor(ColorTypes.background, context),
        appBar: Values().selectedScreen.value != 1
            ? InfoAppBar(
                onBack: _onBack,
                onSettings: () => _onSettings(context),
                context: context)
            : null,
        extendBodyBehindAppBar: true,
        body: SizedBox(
          height: double.infinity,
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Values().fondo.value),
                    fit: BoxFit.cover)),
            child: OrientationBuilder(
                builder: (context, orientation) =>
                    orientation == Orientation.portrait
                        ? pantallas[Values().selectedScreen.value]
                        : pantallasLand[Values().selectedScreen.value]),
          ),
        ),
        bottomNavigationBar: InfoBottomNavigationBar(
            selected: Values().selectedScreen.value,
            onChange: (sel) => Values().selectedScreen.value = sel,
            onNew: _onNew,
            onUser: _onUser,
            context: context),
      ),
    ));
  }
}
