import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/home/minimalistHome.dart';
import 'package:cuentas_android/pantallas/presupuestos/budget.dart';
import 'package:cuentas_android/pantallas/compararPrecios/compararPrecios.dart';
import 'package:cuentas_android/pantallas/createNew.dart';
import 'package:cuentas_android/widgets/views/home/IngresosGastosWidgets.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/home/home/homeWidgets.dart';
import 'package:cuentas_android/widgets/views/home/summaryWidgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

      cuentaDao().almacenarDatos(Values().cuentaRet.value!, kIsWeb);
    }

    void onUser() {
      setState(() {
        Values().cuentaRet.value = null;
      });
      writeSharedPreferences(SharedPreferencesKeys.cuenta, -1);
    }

    void onCancelMinimalist() {
      setState(() {
        Values().inicioMinimalista.value = false;
      });
    }

    void onChangeOptionInMinimalist(int option) {
      setState(() {
        Values().selectedScreen = option;
      });
    }

    List<Widget> pantallas = [
      Values().inicioMinimalista.value
          ? MinimalistHome(
              onMoreDetails: onCancelMinimalist,
              onOption: onChangeOptionInMinimalist,
              onSettings: () => _onSettings(context),
              onNew: onNew)
          : HomeHasData(
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
      Values().inicioMinimalista.value
          ? MinimalistHome(
              onMoreDetails: onCancelMinimalist,
              onOption: onChangeOptionInMinimalist,
              onSettings: () => _onSettings(context),
              onNew: onNew)
          : HomeHasDataLand(
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
        appBar:
            (Values().selectedScreen == 0 && Values().inicioMinimalista.value)
                ? null
                : InfoAppBar(
                    onBack: onBack,
                    onSettings: () => _onSettings(context),
                    onComparar: () => _onComparar(context),
                    context: context),
        extendBodyBehindAppBar: true,
        body: SizedBox(
          height: double.infinity,
          child: Container(
            decoration: Values().mostrarFondoDinamico.value
                ? BoxDecoration(
                    image: DecorationImage(
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3), BlendMode.darken),
                        image: AssetImage(Values().fondo.value),
                        fit: BoxFit.cover))
                : null,
            child: Padding(
              padding: const EdgeInsets.only(top:kToolbarHeight, bottom: kBottomNavigationBarHeight*1.75),
              child: OrientationBuilder(
                  builder: (context, orientation) =>
                      orientation == Orientation.portrait
                          ? pantallas[Values().selectedScreen]
                          : pantallasLand[Values().selectedScreen]),
            ),
          ),
        ),
        extendBody: true,
        bottomNavigationBar:
            (Values().selectedScreen == 0 && Values().inicioMinimalista.value)
                ? null
                : InfoBottomNavigationBar(
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
