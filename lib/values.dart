import 'dart:math';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/foundation.dart';

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
  RxString fondo = ''.obs;
  RxBool mostrarFondoDinamico = true.obs;
  bool primerInicio = true;
  RxList<Cuenta> cuentas = RxList<Cuenta>();
  Rx<Cuenta?> cuentaRet = Rx<Cuenta?>(null);
  RxString mes = "".obs;
  RxInt anno = RxInt(DateTime.now().year);
  RxInt gastoSeleccionado = (-1).obs;
  RxString moneda = "€".obs;
  RxBool editing = false.obs;
  Rx<ShowingGastos> showing = ShowingGastos.gastos.obs;
  RxBool summaryShowChart = false.obs;
  RxInt summaryAnno = DateTime.now().year.obs;
  RxString summaryMes = "".obs;
  int selectedScreen = 0;
  Rx<OrderByTypes> orderBy = OrderByTypes.dateDesc.obs;
//metodos
  int GetMesNumber(String mes) => nombresMes.indexOf(mes) + 1;

  Future init(bool isWeb) async {
    moneda.value = await readSharedPreferences(SharedPreferencesKeys.moneda);
    // figuraAbajo.value =
    //     await readSharedPreferences(SharedPreferencesKeys.figuraAbajo);
    mes.value = kIsWeb ? nombresMes[8] : nombresMes[DateTime.now().month - 1];
    int cuenta = await readSharedPreferences(SharedPreferencesKeys.cuenta);
    if (cuenta != -1) {
      await cuentaDao().getDatos(isWeb);

      if (cuentas.value.isNotEmpty) {
        cuentaRet.value = cuentas.value[cuenta];
      }
    }

    mostrarFondoDinamico.value =
        await readSharedPreferences(SharedPreferencesKeys.fondoSimple);
    if (mostrarFondoDinamico.value) {
      ponerFondo();
    }
  }

  void ponerFondo() {
    int random = Random().nextInt(1000);
    int valor = random % 2 == 0 ? 1 : 2;
    DateTime now = DateTime.now();
    int hour = now.hour;

    // Determinar el período del día
    if (hour >= 6 && hour < 14) {
      fondo.value = 'lib/assets/images/background/dia$valor.jpeg';
    } else if (hour >= 14 && hour < 20) {
      fondo.value = 'lib/assets/images/background/tarde$valor.jpeg';
    } else {
      fondo.value = 'lib/assets/images/background/noche$valor.jpeg';
    }
  }
}
