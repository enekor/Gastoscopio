import 'dart:collection';

//import 'package:cuentas_android/dao/cuentaDao.dart';
//import 'package:cuentas_android/models/Gasto.dart';
//import 'package:cuentas_android/models/Mes.dart';
//import 'package:flutter/material.dart';

import 'package:cuentas_android/utils.dart';

import 'models/Cuenta.dart';
import 'package:get/get.dart';

class Values {
  static final Values _apiInstace = Values._internal();

  factory Values() {
    return _apiInstace;
  }
  Values._internal();

//variables
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
  Cuenta? cuentaRet = null;
  RxInt mes = RxInt(DateTime.now().month-1);
  RxInt anno = RxInt(DateTime.now().year);
  RxInt gastoSeleccionado = (-1).obs;
  RxBool mostrarGatos = false.obs;
  RxBool fondoSimple = true.obs;
  RxBool figuraAbajo = true.obs;
  RxString moneda = "€".obs;

//metodos
  String GetMes() => nombresMes[mes.value];
  int GetMesNumber(String mes)=>nombresMes.indexOf(mes)+1;

  void ChangeMes(String m)=>mes.value = nombresMes.indexOf(m);

  Future init() async{
    mostrarGatos.value = await readSharedPreferences(SharedPreferencesKeys.gatos);
    fondoSimple.value = await readSharedPreferences(SharedPreferencesKeys.fondoSimple);
    moneda.value = await readSharedPreferences(SharedPreferencesKeys.moneda);
    figuraAbajo.value = await readSharedPreferences(SharedPreferencesKeys.figuraAbajo);
  }
}