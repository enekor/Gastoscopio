import 'package:cuentas_android/dao/cuentaDao.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
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

  Cuenta(
      {required this.id,
      required this.Nombre,
      required this.Meses,
      required this.posicion,
      required this.fijos,
      required this.deudas,
      required this.color,
      required this.tags});

  factory Cuenta.empty() => Cuenta(
      id: ''.obs,
      Nombre: ''.obs,
      Meses: RxList<Mes>(),
      color: ''.obs,
      deudas: RxList<Gasto>(),
      fijos: RxList<Gasto>(),
      posicion: RxInt(-1),
      tags: RxList<String>());

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
          : RxList<String>());

  Map<String, dynamic> toJson() => {
        "id": id.value,
        "Nombre": Nombre.value,
        "Meses": List<dynamic>.from(Meses.value.map((x) => x.toJson())),
        "posicion": posicion.value,
        "fijos": List<dynamic>.from(fijos.value.map((e) => e.toJson())),
        "deudas": List<dynamic>.from(deudas.value.map((e) => e.toJson())),
        "color": color.value,
        "tags": tags.value,
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
      ShowingGastos tipo, Gasto gasto, bool editing, int anno, String mes) {
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

        cuentaDao().almacenarDatos(this);
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

        cuentaDao().almacenarDatos(this);
        break;
      case ShowingGastos.ingresos:
        gasto.valor.value = -1 * gasto.valor.value;

        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
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
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Gastos
              .add(gasto);
        }

        cuentaDao().almacenarDatos(this);
        break;
      case ShowingGastos.gastos:
        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Gastos
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
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
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Gastos
              .add(gasto);
        }

        cuentaDao().almacenarDatos(this);
        break;

      case ShowingGastos.extras:
        if (editing) {
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Extras
              .value
              .firstWhere((d) =>
                  d.nombre.value == gasto.nombre.value &&
                  d.anno.value == gasto.anno.value &&
                  d.mes.value == gasto.mes.value &&
                  d.dia.value == gasto.dia.value)
              .tag
              .value = gasto.tag.value;
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
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
          Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
              .Extras
              .add(gasto);
        }

        cuentaDao().almacenarDatos(this);
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
      String mes, String filterByWord, DateTime? fecha) {
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
      datos =
          datos.where((gasto) => gasto.nombre.contains(filterByWord)).toList();
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

    return datos;
  }

  double GetGastos(int anno, String mes) {
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
    fijos.forEach((element) {
      element.nombre.value = element.nombre.value.endsWith(" ")
          ? element.nombre.value.substring(0, element.nombre.value.length - 1)
          : element.nombre.value;
    });

    Meses.add(Mes(mes.obs, anno.obs));
    Meses.firstWhere((m) => m.Anno.value == anno && m.NMes.value == mes)
        .Gastos
        .value
        .addAll(fijos);
  }
}
