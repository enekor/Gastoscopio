import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/pantallas/visionado/ingresosGastos.dart';
import 'package:cuentas_android/pantallas/visionado/settings.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:get/Get.dart';
import 'package:cuentas_android/widgets/views/infoWidgets.dart' as iw;

class Info extends StatelessWidget {
  Info({Key? key,required Cuenta cuenta}) : super(key: key){
    c = cuenta.obs;
  }

  late Rx<Cuenta> c;
  RxString _mes = Values().GetMes().obs;
  RxList<Gasto> _toDelete = RxList<Gasto>([]);
  RxBool _hasMesData = false.obs;

//metodos
  bool _hasData(String mes) {
    bool exists = c.value.Meses.where((v) => v.NMes == _mes.value && v.Anno == Values().anno.value).isNotEmpty;
    return exists;
  }

  void _seleccionarMes(String mes){
    _mes.value = mes;
    if(_hasData(mes)){
      _hasMesData.value = true;
    }
    else{
      _createMes(mes,0);
      _hasMesData.value = false;
    }
  }

  void _createMes(String mes, double valor){
    if(_hasData(mes)){
      c.value.Meses.where((element) => element.NMes == mes && element.Anno == Values().anno).first.Ingreso = valor;
    }else{
      c.value.Meses.add(Mes.complete(Gastos: c.value.fijos, Extras: [], Ingreso: valor, NMes: mes, Anno: Values().anno.value));
    }

  }

  void _pop(BuildContext context) {
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    cuentaDao().almacenarDatos(c.value);
    Values().cuentaRet = c.value;
  }

  void _navigateIngresosGasto(BuildContext context, bool isIngreso) {
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(c.value);
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Navigator.push(
      context, MaterialPageRoute(builder: (context) => IngresosGastos(cuenta: c.value,isIngresos: isIngreso,mes: _mes.value))).then((value) {
        c.value = Values().cuentaRet!;
      });
  }

  void _navigateSettings(BuildContext context){
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(c.value);
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Navigator.push(
      context, MaterialPageRoute(builder: (context) => settings(cuenta: c.value,))).then((value) {
        c.value = Values().cuentaRet!;
      });
  }

//pantalla
  @override
  Widget build(BuildContext context) {
    _seleccionarMes(Values().GetMes());
    return PopScope(
        onPopInvoked: (_)=> _pop(context),
    child:Obx(()=>Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0.0,
        title:  c.value.Meses.where((element) => element.NMes == _mes.value && element.Anno == Values().anno.value).first.Ingreso != 0
            ? iw.appBarMesExists(
              mes: _mes.value,
              c: c.value,
              width: MediaQuery.of(context).size.width,
              navigateSettings: ()=>_navigateSettings(context)
            )
            : const Text("Inicio de mes"),
      ),
      body: CustomPaint(
        painter: MyPattern(context),
        child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: iw.bodyMesExists(
                  context: context,
                  mes: _mes.value,
                  cuenta: c,
                  theme: Theme.of(context),
                  onSelected: (v)=>Values().gastoSeleccionado.value = v,
                  deleted: _toDelete,
                  onSelecMes: _seleccionarMes,
                  onIngresoGastosPressed: (isIngreso)=>_navigateIngresosGasto(context,isIngreso)
                )
              )
            ),
          ),
        ),
      ),
    );
  }
}
