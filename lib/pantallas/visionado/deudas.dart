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
    //debts = cuenta.deudas;
  }

  void _pop(bool pop, BuildContext context){
    //cuenta.deudas = debts.value;
    Values().gastoSeleccionado.value = -1;
    cuentaDao().almacenarDatos(cuenta);
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Values().cuentaRet = cuenta;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (pop)=>_pop(pop,context),
      child: Scaffold(
        //appBar: appBar(),
        body: CustomPaint(
          painter: MyPattern(context),
          child:  //debts.value.isNotEmpty
          /*?^*/ bodyHasDatos()
          //: bodyHasNoDatos()
      ),
      )
    );
  }
}