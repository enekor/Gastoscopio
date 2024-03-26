import 'dart:collection';

//import 'package:cuentas_android/dao/cuentaDao.dart';
//import 'package:cuentas_android/models/Gasto.dart';
//import 'package:cuentas_android/models/Mes.dart';
//import 'package:flutter/material.dart';

import 'models/Cuenta.dart';
import 'package:get/get.dart';

class Values {
  static final Values _apiInstace = Values._internal();

  factory Values() {
    return _apiInstace;
  }
  Values._internal();

  final nombresMes = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  //List<Cuenta> cuentas = [];

  Cuenta? cuentaRet = null;
  //int seleccionado = -1;
  RxInt mes = RxInt(DateTime.now().month-1);
  RxInt anno = RxInt(DateTime.now().year);
  RxInt gastoSeleccionado = (-1).obs;

  /*void seleccionar(int id){
    seleccionado = cuentas.indexOf(cuentas.where((v)=>v.id==id).first);
  }*/

  String GetMes() => nombresMes[mes.value];

  void ChangeMes(String m)=>mes.value = nombresMes.indexOf(m);

  List<int> GetAnnosDisponibles(List<Cuenta> cuentas){
    int annoActual = DateTime.now().year;
    HashSet<int> ret = HashSet<int>();
    
    for(Cuenta c in cuentas){
      List<int> annos = c.Meses.map((e) => e.Anno).toList();
      ret.addAll(annos);
    }

    ret.add(annoActual);
    ret.add(annoActual+1);
    ret.add(annoActual+2);
    ret.add(annoActual+3);

    return ret.toList();
  }
  
}