import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/values.dart';

class Mes implements Comparable<Mes>{
  List<Gasto> Gastos = [];
  double Ingreso = 0;
  List<Gasto> Extras = [];
  String NMes;
  int Anno;
  DateTime fecha = DateTime(1,1,1);

  Mes(this.NMes,this.Anno){
    fecha = DateTime(Anno,Values().GetMesNumber(NMes),1);
  }
  Mes.complete({
    required this.Gastos,
    required this.Extras,
    required this.Ingreso,
    required this.NMes,
    required this.Anno
    }){
      fecha  = DateTime(Anno,Values().GetMesNumber(NMes),1);
    }

  factory Mes.fromJson(Map<String, dynamic> json) => Mes.complete(
        Gastos: List<Gasto>.from(json["Gastos"].map((x) => Gasto.fromJson(x))),
        Ingreso: json["Ingreso"].toDouble(),
        Extras: List<Gasto>.from(json["Extras"].map((x) => Gasto.fromJson(x))),
        NMes: json["NMes"],
        Anno: json['Anno']
      );

  Map<String, dynamic> toJson() => {
        "Gastos": List<dynamic>.from(Gastos.map((x) => x.toJson())),
        "Ingreso": Ingreso,
        "Extras": List<dynamic>.from(Extras.map((x) => x.toJson())),
        "NMes": NMes,
        "Anno":Anno
      };

  double GetExtras() {
    double ret = 0;

    for (int e = 0; e < Extras.length; e++) {
      ret += Extras[e].valor;
    }

    return ret;
  }

  double GetGastos() {
    double ret = 0;

    for (int g = 0; g < Gastos.length; g++) {
      if (Gastos[g].valor > 0) {
        ret += Gastos[g].valor;
      }
    }

    ret += GetExtras();

    return ret;
  }

  double GetIngresosExtra() {
    double ret = 0;

    for (int g = 0; g < Gastos.length; g++) {
      if (Gastos[g].valor < 0) {
        ret += -1*Gastos[g].valor;
      }
    }

    return ret;
  }

  double GetIngresos() {
    return Ingreso + GetIngresosExtra();
  }

  double GetAhorros() {
    return GetIngresos() - GetGastos();
  }

  @override
  int compareTo(Mes otro){
    return fecha.compareTo(otro.fecha);
  }
}
