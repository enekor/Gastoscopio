import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/widgets/views/settingsWidget.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class settings extends StatelessWidget {
  late Rx<Cuenta> cuenta;
  settings({Key? key, required Cuenta cuenta}) : super(key: key) {
    this.cuenta = cuenta.obs;
  }

  void _onDelete(String nombre, double valor) {
    cuenta.value.fijos.removeWhere(
        (element) => element.nombre == nombre && element.valor == valor);
  }

  void _onChange(String nombre, double valor) {
    cuenta.value.fijos
        .where((element) => element.nombre == nombre)
        .first
        .valor = valor;
  }

  void _onCreate(String nombre, double valor) {
    cuenta.value.fijos.add(Gasto(nombre: nombre, valor: valor));
    Values().gastoSeleccionado.value = -1;
  }

  void _pop(BuildContext context) {
    positions().ChangePositions(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(cuenta.value);
    Values().cuentaRet = cuenta.value;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        onPopInvoked: (_) => _pop(context),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          floatingActionButton:
              crearNuevo(),
          body: Center(
            child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    cuenta.value.fijos.isNotEmpty
                      ?fijosView(
                        gastos: cuenta.value.fijos,
                        onDelete: _onDelete,
                        onChange: _onChange,
                        theme: Theme.of(context))
                      :noFijos(),
                    Values().gastoSeleccionado.value == -2
                        ? nuevoFijo(
                            onCreate: _onCreate, theme: Theme.of(context))
                        : Container()
                  ],
                )),
          ),
        ),
      ),
    );
  }
}
