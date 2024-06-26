import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';

Widget fijosView(
    {required List<Gasto> gastos,
    required Function(String, double) onDelete,
    required Function(String, double) onChange,
    required ThemeData theme,
    required ScrollController scrollController}) {
  return ListView.builder(
    controller: scrollController,
    itemBuilder: (context, index) => gastoView(
        onChange,
        onDelete,
        (v2) => Values().gastoSeleccionado.value = v2,
        gastos[index].nombre,
        gastos[index].valor,
        index,
        theme,
        context),
    itemCount: gastos.length,
  );
}

TextEditingController _nombre = TextEditingController();
TextEditingController _valor = TextEditingController();
Widget nuevoFijo(
    {required Function(String, double) onCreate,
    required ThemeData theme,
    required BuildContext context}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: "Nombre"),
              autofocus: true,
            ),
          )),
      Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: TextField(
              controller: _valor,
              decoration: const InputDecoration(labelText: "Monto"),
              autofocus: true,
              keyboardType: TextInputType.number,
            ),
          )),
      Expanded(
          child: IconButton(
              onPressed: () =>
                  onCreate(_nombre.text, double.parse(_valor.text)),
              icon: const Icon(Icons.check),
              color: GetColor(ColorTypes.secondary, context)))
    ],
  );
}

Widget noFijos() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        getImageUri(ImageUris.buscando),
        width: 300,
        height: 300,
      ),
      const Text("No tienes gastos fijos")
    ],
  );
}

FloatingActionButton crearNuevo(bool nuevo,
    {required Function onChange, required ScrollController scrollController}) {
  return FloatingActionButton.extended(
      onPressed: () => onChange(),
      icon: Icon(!nuevo ? Icons.add : Icons.close),
      label: Text(nuevo ? "Cancelar" : "Crear nuevo"));
}

AppBar fijosAppBar({required List<Gasto> fijos, required double size}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    title: SizedBox(
      width: size / 1.5,
      child: Card(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text(
              "Valor total",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
                "${fijos.fold(0.0, (previousValue, fijo) => previousValue + fijo.valor).toStringAsFixed(2)}${Values().moneda.value}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}
