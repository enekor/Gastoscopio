import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/fijosWidget.dart';
import 'package:flutter/material.dart';

late Cuenta _cuenta;
bool nuevo = false;
ScrollController _scrollController = ScrollController();

class gastosFijos extends StatefulWidget {
  gastosFijos({Key? key, required Cuenta cuenta}) : super(key: key) {
    _cuenta = cuenta;
  }

  @override
  State<gastosFijos> createState() => _gastosFijosState();
}

class _gastosFijosState extends State<gastosFijos> {
  void _onDelete(String nombre, double valor) {
    setState(() {
      _cuenta.fijos.removeWhere(
          (element) => element.nombre == nombre && element.valor == valor);
    });
  }

  void _onChange(String nombre, double valor) {
    setState(() {
      _cuenta.fijos.where((element) => element.nombre == nombre).first.valor =
          valor;
    });
  }

  void _onCreate(String nombre, double valor) {
    _cuenta.fijos.add(Gasto(nombre: nombre, valor: valor));
    setState(() {
      Values().gastoSeleccionado.value = -1;
      nuevo = !nuevo;
    });
  }

  void _pop(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(_cuenta);
    Values().cuentaRet = _cuenta;
  }

  void _changeNuevo() {
    setState(() {
      nuevo = !nuevo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (_) => _pop(context),
      child: Scaffold(
        backgroundColor: GetColor(ColorTypes.background, context),
        resizeToAvoidBottomInset: true,
        floatingActionButton: crearNuevo(nuevo,
            onChange: _changeNuevo, scrollController: _scrollController),
        appBar: fijosAppBar(
            fijos: _cuenta.fijos, size: MediaQuery.of(context).size.width),
        body: CustomPaint(
          painter: MyPattern(context),
          child: Center(
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: nuevo
                          ? nuevoFijo(
                              onCreate: _onCreate,
                              theme: Theme.of(context),
                              context: context)
                          : Container(),
                    ),
                    Expanded(
                      flex: 10,
                      child: _cuenta.fijos.isNotEmpty
                          ? fijosView(
                              gastos: _cuenta.fijos,
                              onDelete: _onDelete,
                              onChange: _onChange,
                              theme: Theme.of(context),
                              scrollController: _scrollController)
                          : noFijos(),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
