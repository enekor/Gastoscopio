import 'dart:collection';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/pantallas/info.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/homeWidgets.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/widgets/views/homeWidgets.dart' as hw;

import '../pantallas/settings.dart';

List<Cuenta> _cuentas = [];
bool _vuelto = false;
bool _cargado = false;
String nuevoNombre = "";

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Future _getCuentas() async {
    if (!_vuelto) {
      _cuentas = await cuentaDao().getDatos();
    }

    _cargado = true;
    setState(() {
      _vuelto = true;
    });
  }

  Future _logout() async {
    await Auth().signOut();
  }

  Future _createUser(BuildContext context) async {
    var cuenta =
        await cuentaDao().crearNuevaCuenta(nuevoNombre, _cuentas.length + 1);
    _cuentas.add(cuenta);
    setState(() {
      _vuelto = true;
    });
  }

  void _navigateInfo(BuildContext context, Cuenta cuenta) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (context) => Info(
                  cuenta: cuenta,
                  cuentas: _cuentas,
                )))
        .then((value) {
      _cuentas.where((c) => c.id == cuenta.id).toList().first =
          Values().cuentaRet!;
      Values().anno.value = DateTime.now().year;
      setState(() {});
    });
  }

  void _navigateSettings(BuildContext context, List<Cuenta> cuentas) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => Settings(cc: cuentas)))
        .then((value) => setState(() {
              _vuelto = false;
            }));
  }

  void _deleteCuenta(Cuenta cuenta) async {
    setState(() {
      _cuentas.remove(cuenta);
    });
    await cuentaDao().deleteCuenta(cuenta);
  }

  List<int> GetAnnosDisponibles() {
    int annoActual = DateTime.now().year;
    HashSet<int> ret = HashSet<int>();

    for (Cuenta c in _cuentas) {
      List<int> annos = c.Meses.map((e) => e.Anno).toList();
      ret.addAll(annos);
    }

    ret.add(annoActual);
    ret.add(annoActual + 1);
    ret.add(annoActual + 2);
    ret.add(annoActual + 3);

    return ret.toList();
  }

  @override
  Widget build(BuildContext context) {
    _getCuentas();
    return Scaffold(
      backgroundColor: GetColor(ColorTypes.background, context),
      resizeToAvoidBottomInset: true,
      appBar: appBar(onSettings: () => _navigateSettings(context, _cuentas)),
      bottomNavigationBar: hw.navigationBar(
          onLogOut: () => _logout(),
          onNewCuenta: () => hw.nuevoUsuario(
              context: context,
              onChange: (nombre) => nuevoNombre = nombre,
              onPressed: () => _createUser(context)),
          theme: Theme.of(context),
          context: context),
      body: CustomPaint(
        painter: MyPattern(context),
        child: FutureBuilder(
            future: _getCuentas(),
            builder: (c, s) => s.connectionState == ConnectionState.done
                ? hw.hasData(
                    context: context,
                    cuentas: _cuentas,
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    vuelto: (value) => _vuelto = true,
                    navigateInfo: (cuenta) => _navigateInfo(context, cuenta),
                    delete: (cuenta) => _deleteCuenta(cuenta),
                    logout: _logout,
                    annosDisponibles: GetAnnosDisponibles())
                : Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
                  )),
      ),
    );
  }
}
