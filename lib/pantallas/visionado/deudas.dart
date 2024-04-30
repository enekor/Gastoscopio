import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cuentas_android/widgets/views/deudasWidget.dart';

class deudas extends StatelessWidget {
  late RxList<Gasto> debts;
  late Cuenta cuenta;

  deudas({Key? key, required this.cuenta}) : super(key: key){
    debts = cuenta.deudas.obs;
  }

  void _onCreate(String nombre, double valor){
    debts.add(Gasto(nombre: nombre, valor: valor));
  }

  void _onDelete(String nombre, double valor){
    debts.removeWhere((deuda) => deuda.nombre == nombre && deuda.valor == valor);
  }

  void _onEdit(String nombre, double valor){
    debts.firstWhere((deuda) => deuda.nombre == nombre).valor = valor;
  }

  void _pop(bool pop, BuildContext context){
    cuenta.deudas = debts.value;
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(cuenta);
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Values().cuentaRet = cuenta;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=> PopScope(
        onPopInvoked: (pop)=>_pop(pop,context),
        child: Scaffold(
          floatingActionButton: floatingButton(onCreate: _onCreate, context: context),
          resizeToAvoidBottomInset: true,
          body: CustomPaint(
            painter: MyPattern(context),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: debts.value.isNotEmpty
                    ? bodyHasDatos(deudas: debts.value, onDelete: _onDelete, onEdit: _onEdit, theme: Theme.of(context))
                    : bodyHasNoDatos(theme: Theme.of(context)),
                ),
              ),
            )
          ),
        )
      ),
    );
  }
}