import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:cuentas_android/widgets/views/ingresosGastosWidget.dart';

class IngresosGastos extends StatelessWidget {
  late RxList<Gasto> _datos;
  late RxList<Gasto> _extras;
  late RxDouble _ingreso;

  late Cuenta _cuenta;
  late bool _isIngresos;
  late String _mes;

  IngresosGastos({Key? key, required Cuenta cuenta, required String mes, required bool isIngresos}) : super(key: key){
    _cuenta = cuenta;
    Mes mesCompleto = cuenta.Meses.firstWhere((m) => m.NMes == mes && m.Anno == Values().anno.value);
    _isIngresos = isIngresos;
    _datos = isIngresos
      ? mesCompleto.Gastos.where((gasto)=>gasto.valor<0).toList().obs
      : mesCompleto.Gastos.where((gasto)=>gasto.valor>0).toList().obs;
    _ingreso = cuenta.Meses.where((mes) => mes.NMes == Values().GetMes() && mes.Anno == Values().anno.value).first.Ingreso.obs;
    _mes = mes;
    _extras = cuenta.Meses.where((mes) => mes.NMes == Values().GetMes() && mes.Anno == Values().anno.value).first.Extras.obs;
  }

   void _pop(BuildContext context) {
    if(_isIngresos){
      _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value).first.Gastos.removeWhere((gasto)=>gasto.valor<0);
    }
    else{
      _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value).first.Gastos.removeWhere((gasto)=>gasto.valor>0);
    }
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value).first.Gastos.addAll(_datos.value);
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value).first.Ingreso = _ingreso.value;
    _cuenta.Meses.where((m) => m.NMes == _mes && m.Anno == Values().anno.value).first.Extras = _extras.value;

    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(_cuenta);
    Values().cuentaRet = _cuenta;
  }

  void _onSaveValue(String nombre, double valor){
    valor = _isIngresos ? -1*valor : valor;
    _datos.value.where((gasto) => gasto.nombre == nombre).first.valor = valor;
  }

  void _onSaveExtra(String nombre, double valor){
    _extras.value.firstWhere((extra) => extra.nombre == nombre).valor = valor;
  }

  void _onDeleteValue(String nombre,double valor){
    valor = _isIngresos ? -1*valor : valor;
    _datos.value.removeWhere((gasto) => gasto.nombre == nombre && gasto.valor == valor);
  }

  void _onDeleteExtra(String nombre, double valor){
    _extras.value.removeWhere((extra) => extra.nombre == nombre && extra.valor == valor);
  }

  void _onCreate(String nombre, double valor){
    valor = _isIngresos ? -1*valor : valor;
    if(_datos.where((gasto) => gasto.nombre == nombre).isNotEmpty){
      _datos.value.firstWhere((gasto) => gasto.nombre == nombre).valor += valor;
    }else{
      _datos.value.add(Gasto(nombre: nombre, valor: valor));
    }
  }

  void _onCreateExtra(String nombre, double valor){
    if(_extras.value.where((extra) => extra.nombre == nombre).isNotEmpty){
      _extras.value.firstWhere((extra) => extra.nombre == nombre).valor += valor;
    }
    else{
      _extras.value.add(Gasto(nombre: nombre, valor: valor));
    }
  }

  void _onIngresoChange(double valor){
    _ingreso.value = valor;
  }

  @override
  Widget build(BuildContext context) {
     return PopScope(
        onPopInvoked: (_)=> _pop(context),
        child:Obx(()=>Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: appBar(datos: _datos.value, extras: _extras.value,ingreso: _ingreso.value, isIngreso: _isIngresos,theme: Theme.of(context)),
          floatingActionButton: floatingButton(),
          body: CustomPaint(
            painter: MyPattern(context),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child:Column(
                    children: [
                      _datos.value.isNotEmpty
                        ? bodyHasDatos(gastos: _datos.value, onSaveValue: _onSaveValue, onDeleteValue: _onDeleteValue, theme: Theme.of(context),isIngresos: _isIngresos, extras: _extras,onSaveExtra: _onSaveExtra,onDeleteExtra: _onDeleteExtra,ingreso: _ingreso.value, isIngreso: _isIngresos, onIngresoChange: _onIngresoChange)
                        : bodyHasNoDatos(ingreso: _ingreso.value, isIngreso: _isIngresos, onIngresoChange: _onIngresoChange,theme: Theme.of(context),extras: _extras,onSaveExtra: _onSaveExtra,onDeleteExtra: _onDeleteExtra),
                      Values().gastoSeleccionado.value == -2
                        ? createNew(onCreateGasto: _onCreate, theme: Theme.of(context),onCreateExtra: _onCreateExtra,IsIngresos: _isIngresos, gastos: _datos, extras: _extras)
                        : Container()
                    ],
                  )    
                )
              ),
            )
          ),
        ),
      ),
    );
  }
}