import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/views/deudasWidget.dart';
import 'package:flutter/material.dart';

late List<Gasto> _debts;
late Cuenta _cuenta;
class deudas extends StatefulWidget {

  deudas({Key? key, required Cuenta cuenta}) : super(key: key){
    _debts = cuenta.deudas;
    _cuenta = cuenta;
  }

  @override
  State<deudas> createState() => _deudasState();
}

class _deudasState extends State<deudas> {
  void _onCreate(String nombre, double valor){
    if(_debts.where((deuda) => deuda.nombre==nombre).isNotEmpty){
      _debts.firstWhere((deuda) => deuda.nombre == nombre).valor += valor;
    }
    else{
      _debts.add(Gasto(nombre: nombre, valor: valor));
    }

    setState(() {
      
    });
  }

  void _onDelete(String nombre, double valor){
    setState(() {
      _debts.removeWhere((deuda) => deuda.nombre == nombre && deuda.valor == valor);
    });
  }

  void _onEdit(String nombre, double valor){
    setState(() {
      _debts.firstWhere((deuda) => deuda.nombre == nombre).valor = valor;
    });
  }

  void _pop(bool pop, BuildContext context){
    _cuenta.deudas = _debts;
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(_cuenta);
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Values().cuentaRet = _cuenta;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
                  children: _debts.isNotEmpty
                    ? bodyHasDatos(deudas: _debts, onDelete: _onDelete, onEdit: _onEdit, theme: Theme.of(context))
                    : bodyHasNoDatos(theme: Theme.of(context)),
                ),
              ),
            )
          ),
        )
    );
  }
}