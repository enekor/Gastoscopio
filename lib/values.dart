import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'models/Cuenta.dart';

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
//metodos
  int GetMesNumber(String mes) => nombresMes.indexOf(mes) + 1;

  Future init(bool isWeb) async {
    moneda.value = await readSharedPreferences(SharedPreferencesKeys.moneda);
    mes.value = kIsWeb ? nombresMes[8] : nombresMes[DateTime.now().month - 1];
    anno.value = kIsWeb ? 2024 : DateTime.now().year;
    int cuenta = await readSharedPreferences(SharedPreferencesKeys.cuenta);
    if (cuenta != -1) {
      await cuentaDao().getDatos(isWeb);
    }
  }
}
