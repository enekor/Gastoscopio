import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/pantallas/compararPrecios/compararPrecios.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/widgets/views/info/IngresosGastosWidgets.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/info/InfoWidgets.dart';
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
    if (Values().cuentaRet.value!.ExistsMes(Values().anno.value, mes)) {
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
                Values().cuentaRet.value!.NewMes(Values().anno.value, mes);

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

  void _onChartTouched(int section) {
    bool verGastos = false;
    switch (section) {
      case 0:
        setState(() {
          Values().showing.value = ShowingGastos.ingresos;
          Values().selectedScreen = 1;
        });
        break;
      case 1:
        setState(() {
          Values().showing.value = ShowingGastos.gastos;
          Values().selectedScreen = 1;
        });
        break;
      default:
        break;
    }
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

      cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
    }

    void onUser() {
      setState(() {
        Values().cuentaRet.value = null;
      });
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
          child: Container(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage(Values().fondo.value),
                    fit: BoxFit.cover)),
            child: OrientationBuilder(
                builder: (context, orientation) =>
                    orientation == Orientation.portrait
                        ? pantallas[Values().selectedScreen]
                        : pantallasLand[Values().selectedScreen]),
          ),
        ),
        bottomNavigationBar: InfoBottomNavigationBar(
            selected: Values().selectedScreen,
            onChange: (sel) => setState(() {
                  Values().selectedScreen = sel;
                }),
            onNew: onNew,
            onUser: onUser,
            context: context),
      ),
    );
  }
}
