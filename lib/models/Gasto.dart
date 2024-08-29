import 'package:get/get_rx/src/rx_types/rx_types.dart';

class Gasto {
  RxString nombre;
  RxDouble valor;
  RxInt anno = DateTime.now().year.obs;
  RxInt mes = DateTime.now().month.obs;
  RxInt dia = DateTime.now().day.obs;
  RxString tag = "".obs;

  Gasto(
      {required this.nombre,
      required this.valor,
      DateTime? fecha,
      String? tag}) {
    if (fecha != null) {
      anno.value = fecha.year;
      mes.value = fecha.month;
      dia.value = fecha.day;
    }

    this.tag.value = tag ?? "";
  }

  factory Gasto.empty() =>
      Gasto(nombre: "".obs, valor: 0.0.obs, fecha: DateTime.now(), tag: "");

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
      nombre: json["nombre"].toString().obs,
      valor: double.parse(json["valor"].toString()).obs,
      fecha: DateTime(
          json["anno"] ?? DateTime.now().year,
          json["mes"] ?? DateTime.now().month,
          json["dia"] ?? DateTime.now().day),
      tag: json["tag"] ?? "");

  Map<String, dynamic> toJson() => {
        "nombre": nombre.value,
        "valor": valor.value,
        "anno": anno.value,
        "mes": mes.value,
        "dia": dia.value,
        "tag": tag.value
      };
}
