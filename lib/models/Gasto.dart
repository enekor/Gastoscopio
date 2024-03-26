class Gasto{
    String nombre;
    double valor;

    Gasto({
        required this.nombre,
        required this.valor,
    });

    factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
        nombre: json["nombre"],
        valor: json["valor"]?.toDouble(),
    );

    Map<String, dynamic> toJson() => {
        "nombre": nombre,
        "valor": valor,
    };
}
