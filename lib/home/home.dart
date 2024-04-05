import 'dart:collection';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/dao/userDao.dart';
import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/pantallas/info.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:cuentas_android/pattern/pattern.dart';
import 'package:get/Get.dart';
import 'package:cuentas_android/widgets/views/homeWidgets.dart' as hw;

import '../pantallas/settings.dart';

class Home extends StatelessWidget {
  Home({Key? key}) : super(key: key);

  RxList<Cuenta> _cuentas = RxList([]);
  RxBool _vuelto = false.obs;
  RxBool _cargado = false.obs;

  String nuevoNombre = "";

  Future _getCuentas()async{
    if(!_vuelto.value){
      _cuentas.value = await cuentaDao().getDatos();
    }
    
    _cargado.value = true;
    _vuelto.value = true;
  }

  Future _logout() async{
    await Auth().signOut();
  }

  Future _createUser(BuildContext context)async{
    var cuenta = await cuentaDao().crearNuevaCuenta(nuevoNombre,_cuentas.length+1);
    _cuentas.add(cuenta);
    _vuelto.value = true;
    Navigator.pop(context);
  }

  void _navigateInfo(BuildContext context, Cuenta cuenta){
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => Info(cuenta:cuenta))
    ).then((value) {
      _cuentas.value.where((c) => c.id == cuenta.id).toList().first = Values().cuentaRet!;
      Values().anno.value = DateTime.now().year;
    });
  }

  void _navigateSettings(BuildContext context, List<Cuenta> cuentas){
    positions().ChangePositions(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => Settings(cc:cuentas))
    ).then((value) => _vuelto.value = false);
  }

  void _deleteCuenta(Cuenta cuenta)async {
    _cuentas.value.remove(cuenta);
    await cuentaDao().deleteCuenta(cuenta);
  }

   List<int> GetAnnosDisponibles(){
    int annoActual = DateTime.now().year;
    HashSet<int> ret = HashSet<int>();
    
    for(Cuenta c in _cuentas.value){
      List<int> annos = c.Meses.map((e) => e.Anno).toList();
      ret.addAll(annos);
    }

    ret.add(annoActual);
    ret.add(annoActual+1);
    ret.add(annoActual+2);
    ret.add(annoActual+3);

    return ret.toList();
  }

  @override
  Widget build(BuildContext context) {
    _getCuentas();
    return Obx(()=>_cargado.value
      ?Scaffold(
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: hw.navigationBar(
          onLogOut: ()=>_logout(),
          onNewCuenta: ()=>hw.nuevoUsuario(context: context, onChange: (nombre)=>nuevoNombre =nombre, onPressed: ()=>_createUser(context)),
          onSettings: ()=>_navigateSettings(context, _cuentas.value),
          theme: Theme.of(context)
        ),
        body: CustomPaint(
          painter: MyPattern(context),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder(
              future: _getCuentas(),
              builder:(c,s)=> s.connectionState == ConnectionState.done
              ? hw.hasData(
                context:context,
                cuentas: _cuentas,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                vuelto:(value)=>_vuelto.value = true,
                navigateInfo: (cuenta)=>_navigateInfo(context,cuenta),
                delete: (cuenta)=>_deleteCuenta(cuenta),
                logout: _logout,
                annosDisponibles: GetAnnosDisponibles()
              )
              :Center(
                child: CircularProgressIndicator(color:Theme.of(context).primaryColor),
              )
            ),
          ),
        ),
      )
      :CircularProgressIndicator(color: Theme.of(context).primaryColor,)
    );
  }
}
