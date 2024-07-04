import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/pantallas/settings.dart';
import 'package:cuentas_android/pantallas/summary.dart';
import 'package:cuentas_android/pantallas/visionado/deudas.dart';
import 'package:cuentas_android/pantallas/visionado/ingresosGastos.dart';
import 'package:cuentas_android/pantallas/visionado/fijos.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:cuentas_android/widgets/views/homeWidgets.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/widgets/views/infoWidgets.dart' as iw;

late Cuenta c;
late List<Cuenta> _cuentas;
String _mes = Values().GetMes();

class Info extends StatefulWidget {
  Info({Key? key, required Cuenta cuenta, required List<Cuenta> cuentas})
      : super(key: key) {
    c = cuenta;
    _cuentas = cuentas;
  }

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
//metodos
  bool _hasData(String mes) {
    if (c.Meses.isEmpty) return false;

    bool exists =
        c.Meses.where((v) => v.NMes == mes && v.Anno == Values().anno.value)
            .isNotEmpty;
    return exists;
  }

  void _navigateSettings(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings(cc: _cuentas)));
  }

  void _seleccionarMes(String mes) {
    if (!_hasData(mes)) {
      if (DateTime.now().month == Values().GetMesNumber(mes)) {
        _createMes(mes, 0);
      } else {
        showYesNoDialog(
            title: "¿Crear nuevo mes?",
            onYes: () => _createMes(mes, 0),
            context: context,
            body: const Text(
                "¿Desea crear un nuevo mes? Se crearán gastos nuevos a corde a los gastos fijos de la cuenta"));
      }
    } else {
      setState(() {
        _mes = mes;
      });
    }
  }

  void _createMes(String mes, double valor) {
    if (!_hasData(mes)) {
      c.Meses.add(Mes.complete(
          Gastos: c.fijos,
          Extras: [],
          Ingreso: valor,
          NMes: mes,
          Anno: Values().anno.value));
      setState(() {
        _mes = mes;
      });
    }
  }

  void _pop(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(c);
    Values().cuentaRet = c;
  }

  void _navigateIngresosGasto(BuildContext context, bool isIngreso) {
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(c);
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => IngresosGastos(
                cuentas: _cuentas,
                cuenta: c,
                isIngresos: isIngreso,
                mes: _mes))).then((value) {
      setState(() {
        c = Values().cuentaRet!;
      });
    });
  }

  void _navigateFijos(BuildContext context) {
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(c);
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => gastosFijos(
                  cuenta: c,
                  cuentas: _cuentas,
                ))).then((value) {
      setState(() {
        c = Values().cuentaRet!;
      });
    });
  }

  void _navigateSummary(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => SummaryPage(cuenta: c)));
  }

  void _navigateDeudas(BuildContext context) {
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(c);
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => deudas(
                  cuenta: c,
                  cuentas: _cuentas,
                ))).then((value) {
      setState(() {
        c = Values().cuentaRet!;
      });
    });
  }

//pantalla
  @override
  Widget build(BuildContext context) {
    _seleccionarMes(Values().GetMes());
    return PopScope(
        onPopInvoked: (_) => _pop(context),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: true,
          appBar: appBar(
              context: context,
              onSettings: () => _navigateSettings(context),
              withName: false),
          bottomNavigationBar: iw.bottomNavBar(
              onDeudasTap: () => _navigateDeudas(context),
              onRecurrentesTap: () => _navigateFijos(context),
              onSummaryTap: () => _navigateSummary(context),
              context: context),
          body: CustomPaint(
            painter: MyPattern(context),
            child: iw.body(
                ingreso: c.Meses.firstWhere(
                        (v) => v.NMes == _mes && v.Anno == Values().anno.value)
                    .Ingreso,
                mes: _mes,
                onPricesTap: () {},
                onSelecMes: (mes) => _seleccionarMes(mes),
                onIngresoTap: () => _navigateIngresosGasto(context, true),
                onGastosTap: () => _navigateIngresosGasto(context, false),
                context: context,
                cuenta: c),
          ),
        ));
  }
}
