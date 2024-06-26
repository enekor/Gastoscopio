import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';

class Cuenta{
  String id;
  String Nombre;
  List<Mes> Meses;
  int posicion;
  List<Gasto> fijos = [];
  List<Gasto> deudas = [];

  Cuenta({required this.id,required this.Nombre,required this.Meses, required this.posicion, this.fijos = const [], this.deudas = const []});

  factory Cuenta.fromJson(Map<String, dynamic> json) => Cuenta(
    id: json["id"].toString(),
    Nombre: json["Nombre"],
    Meses: List<Mes>.from(json["Meses"].map((x) => Mes.fromJson(x))),
    posicion: json["posicion"],
    fijos: json["fijos"]!=null ? List<Gasto>.from(json["fijos"].map((x)=>Gasto.fromJson(x))) : [],
    deudas: json["deudas"]!=null ? List<Gasto>.from(json["deudas"].map((x)=>Gasto.fromJson(x))) : []
  );

    Map<String, dynamic> toJson() => {
        "id": id,
        "Nombre": Nombre,
        "Meses": List<dynamic>.from(Meses.map((x) => x.toJson())),
        "posicion":posicion,
        "fijos":List<dynamic>.from(fijos.map((e) => e.toJson())),
        "deudas":List<dynamic>.from(deudas.map((e) => e.toJson()))
    };

  double GetGastosTotales(int anno){
    double ret = 0;
    for(Mes mes in Meses.where((v)=>v.Anno == anno)){
      ret+=mes.GetGastos();
    }

    return ret;
  }

  double GetTotal(int anno){
    double ret = 0;

    for(Mes mes in Meses.where((v)=>v.Anno == anno)){
      ret+=mes.GetAhorros();
    }

    return ret;
  }

  double GetDeudaTotal(){
    double ret = 0;

    for (Gasto deuda in deudas) {
      ret+=deuda.valor;
    }

    return ret;
  }
  @override String toString() {
    return Nombre;
  }
}