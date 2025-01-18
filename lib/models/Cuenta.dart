import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/models/presupuesto.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class Cuenta {
  RxString id;
  RxString Nombre;
  RxList<Mes> Meses;
  RxInt posicion;
  RxList<Gasto> fijos = RxList<Gasto>();
  RxList<Gasto> deudas = RxList<Gasto>();
  RxString color;
  RxList<String> tags = RxList<String>();
  RxList<Presupuesto> presupuestos = RxList<Presupuesto>();

  Cuenta(
      {required this.id,
      required this.Nombre,
      required this.Meses,
      required this.posicion,
      required this.fijos,
      required this.deudas,
      required this.color,
      required this.tags,
      required this.presupuestos});

  factory Cuenta.empty() => Cuenta(
      id: ''.obs,
      Nombre: ''.obs,
      Meses: RxList<Mes>(),
      color: ''.obs,
      deudas: RxList<Gasto>(),
      fijos: RxList<Gasto>(),
      posicion: RxInt(-1),
      tags: RxList<String>(),
      presupuestos: [
        Presupuesto(
            description: 'Ahorro', percentage: 15, amount: null, tags: []),
        Presupuesto(
            description: 'Compras', percentage: 20, amount: null, tags: []),
        Presupuesto(
            description: 'Salidas', percentage: 15, amount: null, tags: [])
      ].obs);

  factory Cuenta.fromJson(Map<String, dynamic> json) => Cuenta(
      id: json["id"].toString().obs,
      Nombre: json["Nombre"].toString().obs,
      Meses: List<Mes>.from(json["Meses"].map((x) => Mes.fromJson(x))).obs,
      posicion: int.parse(json["posicion"].toString()).obs,
      fijos: json["fijos"] != null
          ? List<Gasto>.from(json["fijos"].map((x) => Gasto.fromJson(x))).obs
          : RxList<Gasto>(),
      deudas: json["deudas"] != null
          ? List<Gasto>.from(json["deudas"].map((x) => Gasto.fromJson(x))).obs
          : RxList<Gasto>(),
      color:
          json["color"] != null ? json["color"].toString().obs : "#000000".obs,
      tags: json["tags"] != null
          ? List<String>.from(json["tags"].map((x) => x.toString())).obs
          : RxList<String>(),
      presupuestos: json["presupuestos"] != null
          ? List<Presupuesto>.from(
              json["presupuestos"].map((x) => Presupuesto.fromJson(x))).obs
          : [
              Presupuesto(
                  description: 'Ahorro',
                  percentage: 15,
                  amount: null,
                  tags: []),
              Presupuesto(
                  description: 'Compras',
                  percentage: 20,
                  amount: null,
                  tags: []),
              Presupuesto(
                  description: 'Salidas',
                  percentage: 15,
                  amount: null,
                  tags: [])
            ].obs);

  Map<String, dynamic> toJson() => {
        "id": id.value,
        "Nombre": Nombre.value,
        "Meses": List<dynamic>.from(Meses.value.map((x) => x.toJson())),
        "posicion": posicion.value,
        "fijos": List<dynamic>.from(fijos.value.map((e) => e.toJson())),
        "deudas": List<dynamic>.from(deudas.value.map((e) => e.toJson())),
        "color": color.value,
        "tags": tags.value,
        "presupuestos":
            List<dynamic>.from(presupuestos.value.map((e) => e.toJson()))
      };

/* Metodos de acceso a datos */
  double GetGastosTotales(int anno) {
    double ret = 0;
    for (Mes mes in Meses.where((v) => v.Anno == anno)) {
      ret += mes.GetGastos();
    }

    return ret;
  }

  double GetDeudaTotal() {
    double ret = 0;

    for (Gasto deuda in deudas) {
      ret += deuda.valor.value;
    }

    return ret;
  }

  @override
  String toString() {
    return Nombre.value;
  }

  void addUpdateValues(
      ShowingGastos tipo, Gasto gasto, bool editing, String mes) {
    switch (tipo) {
      case ShowingGastos.deuda:
        if (editing) {
          deudas.value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          deudas.value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .valor
              .value = gasto.valor.value;
        } else {
          deudas.add(gasto);
        }

        break;
      case ShowingGastos.fijo:
        if (editing) {
          fijos.value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          fijos.value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .valor
              .value = gasto.valor.value;
        } else {
          fijos.add(gasto);
        }

        break;
      case ShowingGastos.ingresos:
        gasto.valor.value = -1 * gasto.valor.value;

        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .valor
              .value = gasto.valor.value;
        } else {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .add(gasto);
        }

        break;
      case ShowingGastos.gastos:
        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .valor
              .value = gasto.valor.value;
        } else {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Gastos
              .add(gasto);
        }

        break;

      case ShowingGastos.extras:
        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Extras
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Extras
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .valor
              .value = gasto.valor.value;
        } else {
          Meses.firstWhere((m) => m.Anno.value == gasto.anno.value && m.NMes.value == mes)
              .Extras
              .add(gasto);
        }

        break;
    }
  }

  List<int> GetYears() {
    Set<int> annos =
        Set<int>.from(Meses.value.map((e) => e.Anno.value).toList()).obs;

    return annos.toList();
  }

  double GetTotal(int anno, String mes) {
    if (ExistsMes(anno, mes)) {
      return Meses.firstWhere(
          (m) => m.Anno.value == anno && m.NMes.value == mes).GetTotal();
    } else {
      NewMes(anno, mes);
      return 0;
    }
  }

  List<Gasto> GetGastosToShow(ShowingGastos primaryTag, String tag, int anno,
      String mes, String filterByWord, DateTime? fecha, OrderByTypes orderBy) {
    if (Meses.where((m) => m.Anno.value == anno && m.NMes.value == mes)
        .isEmpty) {
      NewMes(anno, mes);
    }
    List<Gasto> datos = [];

    if (primaryTag != ShowingGastos.deuda && primaryTag != ShowingGastos.fijo) {
      datos =
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .GetGastosFiltered(primaryTag);
    } else if (primaryTag == ShowingGastos.fijo) {
      datos = fijos.value;
    } else if (primaryTag == ShowingGastos.deuda) {
      datos = deudas.value;
    }

    if (tag.isNotEmpty) {
      datos = datos.where((g) => g.tag.value == tag).toList();
    }

    if (filterByWord.isNotEmpty) {
      datos = datos
          .where((gasto) =>
              gasto.nombre.toLowerCase().contains(filterByWord.toLowerCase()))
          .toList();
    }

    if (primaryTag == ShowingGastos.ingresos) {
      List<Gasto> ingresos = [];
      for (Gasto dato in datos) {
        ingresos.add(Gasto(
            nombre: dato.nombre,
            valor: (-1 * dato.valor.value).obs,
            fecha: DateTime(dato.anno.value, dato.mes.value, dato.dia.value),
            tag: dato.tag.value));
      }

      datos = ingresos;
    }

    if (fecha != null) {
      datos = datos
          .where((g) =>
              g.anno.value == fecha.year &&
              g.mes.value == fecha.month &&
              g.dia.value == fecha.day)
          .toList();
    }

    switch (orderBy) {
      case OrderByTypes.dateAsc:
        datos.sort((a, b) => DateTime(b.anno.value, b.mes.value, b.dia.value)
            .compareTo(DateTime(a.anno.value, a.mes.value, a.dia.value)));
        break;
      case OrderByTypes.dateDesc:
        datos.sort((a, b) => DateTime(b.anno.value, b.mes.value, b.dia.value)
            .compareTo(DateTime(a.anno.value, a.mes.value, a.dia.value)));
        datos = datos.reversed.toList();
        break;
      case OrderByTypes.name:
        datos.sort((a, b) => b.nombre.value.compareTo(a.nombre.value));
        break;
      case OrderByTypes.value:
        datos.sort((a, b) => b.valor.value.compareTo(a.valor.value));
        break;
    }

    return datos;
  }

  double GetGastos(int anno, String mes) {
    if (Meses.where((m) => m.Anno.value == anno && m.NMes.value == mes)
        .isEmpty) {
      NewMes(anno, mes);
    }
    var dato =
        Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
                .GetGastos() -
            Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
                .GetExtras();

    return dato;
  }

  double GetIngresos(int anno, String mes) {
    var dato =
        Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
            .GetIngresos();

    return dato;
  }

  double GetExtras(int anno, String mes) {
    var dato =
        Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
            .GetExtras();

    return dato;
  }

  bool ExistsMes(int anno, String mes) {
    return Meses.where((m) => m.Anno.value == anno && m.NMes.value == mes)
        .isNotEmpty;
  }

  void NewMes(int anno, String mes) {
    List<Gasto> gastosIniciales = [];

    for (Gasto element in fijos.value) {
      element.nombre.value = element.nombre.value.endsWith(" ")
          ? element.nombre.value.substring(0, element.nombre.value.length - 1)
          : element.nombre.value;

      gastosIniciales.add(element);
    }

    Meses.add(Mes(mes.obs, anno.obs));
    Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
        .Gastos
        .value
        .addAll(gastosIniciales);
  }

  bool DeleteValue(Gasto gasto, int anno, String mes, ShowingGastos tipo) {
    switch (tipo) {
      case ShowingGastos.deuda:
        return deudas.value.remove(gasto);
      case ShowingGastos.fijo:
        return fijos.value.remove(gasto);
      case ShowingGastos.extras:
        return Meses.value
            .firstWhere((g) => g.Anno.value == anno && g.NMes.value == mes)
            .Extras
            .value
            .remove(gasto);
      case ShowingGastos.gastos:
      case ShowingGastos.ingresos:
        return Meses.value
            .firstWhere((g) => g.Anno.value == anno && g.NMes.value == mes)
            .Gastos
            .value
            .remove(gasto);
    }
  }

  List<Gasto> GetLastInteractions() {
    Mes ultimoMes = Meses.value.last;
    List<Gasto> lastInteraction = [];
    List<Gasto> allFromMes = ultimoMes.Gastos.value + ultimoMes.Extras.value;
    allFromMes.sort((a, b) => DateTime(a.anno.value, a.mes.value, a.dia.value)
        .compareTo(DateTime(b.anno.value, b.mes.value, b.dia.value)));
    allFromMes = allFromMes.reversed.toList();

    if (allFromMes.length >= 5) {
      for (int i = 0; i <= 5; i++) {
        lastInteraction.add(allFromMes[i]);
      }
    } else {
      lastInteraction = allFromMes;
    }

    return lastInteraction;
  }

  double CalcularTotalPorTagFecha(List<String> tags, String month, int year) {
    Mes mes = Meses.firstWhere(
        (expense) => expense.NMes.value == month && expense.Anno.value == year);

    List<Gasto> datos = mes.Gastos.value
            .where((gasto) => tags.contains(gasto.tag.value))
            .toList() +
        mes.Extras.value
            .where((extra) => tags.contains(extra.tag.value))
            .toList();
    var ret = datos
        .map((gasto) => gasto.valor.value)
        .fold(0.0, (sum, expense) => sum + expense);

    return ret;
  }

  double GetLastIngreso() {
    double ret =
        kIsWeb ? Meses[0].Ingreso.value : Meses[Meses.length - 1].Ingreso.value;

    return ret;
  }

  /* para charts */
  Map<String, double> GetIngresosGastosChart(
      int anno, String mes, bool isGasto) {
    List<String> tags = [];
    Mes mes0 = Meses.value
        .firstWhere((v) => v.Anno.value == anno && v.NMes.value == mes);

    List<Gasto> values = [];
    Map<String, double> ret = {};

    if (isGasto) {
      values =
          mes0.Gastos.where((v) => v.valor > 0).toList() + mes0.Extras.toList();
    } else {
      values = mes0.Gastos.where((v) => v.valor < 0).toList();
    }

    tags = values.map((v) => v.tag.value).toSet().toList();

    for (String tag in tags) {
      ret[tag == "" ? 'sin tag' : tag] = values
          .where((v) => v.tag.value == tag)
          .map((v) => v.valor.value)
          .toList()
          .reduce((a, b) => a + b);

      if (ret[tag == "" ? 'sin tag' : tag]! < 0) {
        print('inicio de cambio');
        ret[tag == "" ? 'sin tag' : tag] =
            ret[tag == "" ? 'sin tag' : tag]! * -1;
        print('fin de cambio');
      }

      print(ret.toString());
    }

    print(ret);
    return ret;
  }

  Map<String, double> GetTotalChart(int anno, String mes) {
    Map<String, double> ret = {};

    ret['Ingresos'] = Meses.value
        .firstWhere((v) => v.Anno.value == anno && v.NMes.value == mes)
        .GetAhorros();

    ret['Gastos'] = Meses.value
        .firstWhere((v) => v.Anno.value == anno && v.NMes.value == mes)
        .GetGastos();

    return ret;
  }

  List<String> GetMeses(int anno) {
    List<String> meses = Meses.value
        .where((v) => v.Anno.value == anno)
        .map((v) => v.NMes.value)
        .toSet()
        .toList();

    return meses;
  }

  List<double> GetIngresosTotalesChart(int anno) {
    List<String> meses = GetMeses(anno);
    List<double> ret = [];

    for (String mes in meses) {
      double total = Meses.value
          .where((v) => v.Anno.value == anno && v.NMes.value == mes)
          .map((v) => v.GetAhorros())
          .reduce((a, b) => a + b);

      ret.add(total);
    }

    return ret;
  }

  List<double> GetGastosTotalesChart(int anno) {
    List<String> meses = GetMeses(anno);
    List<double> ret = [];

    for (String mes in meses) {
      double total = Meses.value
          .where((v) => v.Anno.value == anno && v.NMes.value == mes)
          .map((v) => v.GetGastos())
          .reduce((a, b) => a + b);

      ret.add(total);
    }

    return ret;
  }
}
