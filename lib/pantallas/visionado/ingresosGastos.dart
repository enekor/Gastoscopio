import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/home/homeWidgets.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/pantallas/visionado/extras.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:cuentas_android/widgets/views/ingresosGastosWidget.dart';

class IngresosGastos extends StatelessWidget {
  late Cuenta _cuenta;
  late RxList<Gasto> _datos;
  late bool _isIngresos;
  late RxDouble _ingreso;
  late String _mes;
  late RxList<Gasto> _extras;
  late RxDouble _extrasValor;

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
    _extrasValor = cuenta.Meses.where((mes) => mes.NMes == Values().GetMes() && mes.Anno == Values().anno.value).first.GetExtras().obs;
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

    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(_cuenta);
    Values().cuentaRet = _cuenta;
  }

  void onSaveValue(String nombre, double valor){
    valor = _isIngresos ? -1*valor : valor;
    _datos.value.where((gasto) => gasto.nombre == nombre).first.valor = valor;
  }

  void onDeleteValue(String nombre,double valor){
    valor = _isIngresos ? -1*valor : valor;
    _datos.value.removeWhere((gasto) => gasto.nombre == nombre && gasto.valor == valor);
  }

  void onCreate(String nombre, double valor){
    valor = _isIngresos ? -1*valor : valor;
    _datos.add(Gasto(nombre: nombre, valor: valor));
  }

  void onIngresoChange(double valor){
    _ingreso.value = valor;
  }

  void onNavigateExtra(BuildContext context){
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Navigator.of(context).push( MaterialPageRoute(builder: (context)=> Extras(cuenta: _cuenta,))).then((value) {
        _extras.value = Values().cuentaRet!.Meses.first.Extras!;
        _extrasValor.value = _extras.value.fold<double>(0.0, (previousValue, element) => previousValue + element.valor);
        _cuenta.Meses.firstWhere((c) => c.NMes == _mes && c.Anno == Values().anno).Extras = _extras.value;
      });
  }

  @override
  Widget build(BuildContext context) {
     return PopScope(
        onPopInvoked: (_)=> _pop(context),
        child:Obx(()=>Scaffold(
          resizeToAvoidBottomInset: true,
          appBar: appBar(datos: _datos.value, ingreso: _ingreso.value, isIngreso: _isIngresos, onIngresoChange: onIngresoChange,theme: Theme.of(context)),
          floatingActionButton: floatingButton(),
          body: CustomPaint(
            painter: MyPattern(context),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child:Column(
                  children: [
                    _datos.value.isNotEmpty
                      ? bodyHasDatos(datos: _datos.value, onSaveValue: onSaveValue, onDeleteValue: onDeleteValue, theme: Theme.of(context),isIngresos: _isIngresos, extras: _extrasValor,navigateExtras: ()=>onNavigateExtra(context))
                      : bodyHasNoDatos(),
                    Values().gastoSeleccionado.value == -2
                      ? createNew(onCreate: onCreate, theme: Theme.of(context))
                      : Container()
                  ],
                )    
              )
            )
          ),
        ),
      ),
    );
  }
}