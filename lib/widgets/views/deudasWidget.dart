import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:cuentas_android/widgets/dialog.dart';
import 'package:flutter/material.dart';

AppBar appBar() {
  return AppBar(
    backgroundColor: Colors.transparent,
  );
}

List<Widget> bodyHasDatos(
    {required List<Gasto> deudas,
    required Function(String, double) onDelete,
    required Function(String, double) onEdit,
    required ThemeData theme,
    required BuildContext context}) {
  return deudasList(
      deudas: deudas,
      onDelete: onDelete,
      onEdit: onEdit,
      theme: theme,
      context: context);
}

List<Widget> bodyHasNoDatos({required ThemeData theme}) {
  return [
    Image.asset(
      getImageUri(ImageUris.ok),
      height: 300,
      width: 300,
    ),
    Text(
      "No tienes deudas ¡Genial!",
      style: theme.textTheme.bodyLarge,
    )
  ];
}

List<Widget> deudasList(
    {required List<Gasto> deudas,
    required Function(String, double) onDelete,
    required Function(String, double) onEdit,
    required ThemeData theme,
    required BuildContext context}) {
  List<Widget> deudasW = [];

  int posicion = 0;
  for (Gasto deuda in deudas) {
    deudasW.add(gastoView(
        onEdit,
        onDelete,
        (pos) => Values().gastoSeleccionado.value = pos,
        deuda.nombre,
        deuda.valor,
        posicion,
        theme,
        context));

    posicion++;
  }

  return deudasW;
}

FloatingActionButton floatingButton(
    {required Function(String, double) onCreate,
    required BuildContext context,
    required ScrollController scrollController}) {
  return FloatingActionButton.extended(
    onPressed: () => nuevaDeuda(context: context, onCreate: onCreate),
    label: Text("Nueva deuda"),
    icon: Icon(Icons.add),
  );
}

TextEditingController _nombre = TextEditingController();
TextEditingController _valor = TextEditingController();
void nuevaDeuda(
    {required Function(String, double) onCreate,
    required BuildContext context}) {
  showYesNoDialog(
      context: context,
      body: Row(
        children: [
          Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _nombre,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
              )),
          Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: _valor,
                  decoration: const InputDecoration(labelText: "Monto"),
                ),
              ))
        ],
      ),
      onYes: () {
        onCreate(_nombre.text, double.parse(_valor.text));
        Navigator.pop(context);
      },
      yesButton: "Guardar",
      noButton: "Cancelar",
      title: "Nueva deuda");
}
