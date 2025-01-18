import 'dart:math';

import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  RxBool inicioMinimalista = false.obs;
  RxString fondo = ''.obs;
//metodos
  int GetMesNumber(String mes) => nombresMes.indexOf(mes) + 1;

  Future init(bool isWeb, BuildContext context) async {
    moneda.value =
        await readSharedPreferences<String>(SharedPreferencesKeys.moneda) ??
            '€';

    moneda.value = moneda.value.isEmpty ? '€' : moneda.value;

    // figuraAbajo.value =
    //     await readSharedPreferences(SharedPreferencesKeys.figuraAbajo);
    anno.value = kIsWeb ? 2024 : DateTime.now().year;
    mes.value = kIsWeb ? nombresMes[8] : nombresMes[DateTime.now().month - 1];
    int cuenta = await readSharedPreferences<int>(SharedPreferencesKeys.cuenta);
    if (cuenta != -1) {
      await cuentaDao().getDatos(isWeb);

      if (cuentas.value.isNotEmpty) {
        cuentaRet.value = cuentas.value[cuenta];
      }
    }

    mostrarFondoDinamico.value =
        await readSharedPreferences<bool>(SharedPreferencesKeys.fondoSimple);

    ponerFondo(context);

    print('---- inicio minimalista: $inicioMinimalista} -----');
    inicioMinimalista.value =
        await readSharedPreferences<bool>(SharedPreferencesKeys.minimalista) ??
            false;
  }

  void ponerFondo(BuildContext context) {
    int random = Random().nextInt(1000);
    int valor = random % 4 == 0 ? 1 : 2;
    DateTime now = DateTime.now();
    int hour = now.hour;

    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      fondo.value = 'lib/assets/images/background/oscuro$valor.jpg';
    } else {
      fondo.value = 'lib/assets/images/background/claro$valor.jpg';
    }
  }
}
