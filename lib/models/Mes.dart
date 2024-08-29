import 'dart:math';

import 'package:flutter/material.dart';

import 'package:cuentas_android/models/ChartValues.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class Mes {
  RxList<Gasto> Gastos = RxList<Gasto>();
  RxDouble Ingreso = (0.0).obs;
  RxList<Gasto> Extras = RxList<Gasto>();
  RxString NMes;
  RxInt Anno;

  Mes(this.NMes, this.Anno) {}
  Mes.complete(
      {required this.Gastos,
      required this.Extras,
      required this.Ingreso,
      required this.NMes,
      required this.Anno});

  factory Mes.fromJson(Map<String, dynamic> json) => Mes.complete(
      Gastos:
          List<Gasto>.from(json["Gastos"].map((x) => Gasto.fromJson(x))).obs,
      Ingreso: double.parse(json["Ingreso"].toString()).obs,
      Extras:
          List<Gasto>.from(json["Extras"].map((x) => Gasto.fromJson(x))).obs,
      NMes: json["NMes"].toString().obs,
      Anno: int.parse(json["Anno"].toString()).obs);

  Map<String, dynamic> toJson() => {
        "Gastos": List<dynamic>.from(Gastos.value.map((x) => x.toJson())),
        "Ingreso": Ingreso.value,
        "Extras": List<dynamic>.from(Extras.value.map((x) => x.toJson())),
        "NMes": NMes.value,
        "Anno": Anno.value
      };

  /*Metodos de acceso a datos */

  Set<String> GetTags() {
    List<String> tags = [];

    tags.addAll(Gastos.value.map((g) => g.tag.value));
    tags.addAll(Extras.value.map((e) => e.tag.value));

    return Set.from(tags);
  }

  double GetExtras() {
    double ret = 0;

    for (int e = 0; e < Extras.length; e++) {
      ret += Extras[e].valor.value;
    }

    return ret;
  }

  double GetGastos() {
    double ret = 0;

    for (int g = 0; g < Gastos.length; g++) {
      if (Gastos[g].valor > 0) {
        ret += Gastos[g].valor.value;
      }
    }

    ret += GetExtras();

    return ret;
  }

  double GetIngresosExtra() {
    double ret = 0;

    for (int g = 0; g < Gastos.length; g++) {
      if (Gastos[g].valor < 0) {
        ret += -1 * Gastos[g].valor.value;
      }
    }

    return ret;
  }

  double GetIngresos() {
    return Ingreso.value + GetIngresosExtra();
  }

  double GetAhorros() {
    return GetIngresos() - GetGastos();
  }

  bool ExistsGasto(String nombre, int anno, int mes, int dia) {
    return Gastos.where((g) =>
        g.nombre.value == nombre &&
        g.anno.value == anno &&
        g.mes.value == mes &&
        g.dia.value == dia).isNotEmpty;
  }

  double GetTotal() {
    double ingresos = GetIngresos();
    double gastos = GetGastos();

    return ingresos - gastos;
  }

  List<Gasto> GetGastosFiltered(ShowingGastos primaryTag) {
    List<Gasto> ret = [];

    switch (primaryTag) {
      case ShowingGastos.gastos:
        ret = Gastos.where((element) => element.valor > 0).toList();
        break;
      case ShowingGastos.ingresos:
        ret = Gastos.where((element) => element.valor < 0).toList();
        break;
      case ShowingGastos.extras:
        ret = Extras;
        break;
    }
    return ret;
  }

  List<Chartvalues> GetForChart() {
    List<Chartvalues> ret = [];
    Set<String> tags = <String>{};
    List<Gasto> gastos = Gastos.value + Extras.value;

    tags.addAll(Gastos.map((g) => g.tag.value).toList());
    tags.addAll(Extras.map((e) => e.tag.value).toList());

    ret.add(Chartvalues(
        nombre: "Salario", valor: Ingreso.value, color: RandColor()));
    ret.add(Chartvalues(
        nombre: "Ingresos extra",
        valor: gastos.where((g) => g.valor.value < 0).fold(
              0,
              (previousValue, element) =>
                  previousValue + (-1 * element.valor.value),
            ),
        color: RandColor()));
    for (var t in tags) {
      ret.add(Chartvalues(
          nombre: "Gastos: ${t != "" ? t : "Sin tag"}",
          valor:
              gastos.where((g) => g.valor.value > 0 && g.tag.value == t).fold(
                    0,
                    (previousValue, element) =>
                        previousValue + (element.valor.value),
                  ),
          color: RandColor()));
    }

    return ret;
  }
}

Color RandColor() {
  return Color.fromARGB(
      255, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
}
