import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';

AppBar appBar(
    {required List<Gasto> debts,
    required BuildContext context,
    required Function onSettings}) {
  return AppBar(
    backgroundColor: GetColor(ColorTypes.card, context),
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Text(
          "Valor total",
        ),
        Text(
          "${debts.fold(0.0, (previousValue, fijo) => previousValue + fijo.valor).toStringAsFixed(2)}${Values().moneda.value}",
        ),
      ],
    ),
    actions: [
      IconButton(
          iconSize: 40,
          onPressed: () => onSettings(),
          icon: const Icon(Icons.settings))
    ],
  );
}

Widget bodyHasDatos(
    {required List<Gasto> deudas,
    required Function(String, double) onDelete,
    required Function(String, double) onEdit,
    required ThemeData theme,
    required BuildContext context}) {
  List<Widget> debts = deudasList(
      deudas: deudas,
      onDelete: onDelete,
      onEdit: onEdit,
      theme: theme,
      context: context);
  return ListView.builder(
    itemBuilder: (context, index) => debts[index],
    itemCount: debts.length,
  );
}

Widget bodyHasNoDatos({required ThemeData theme}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Image.asset(
        getImageUri(ImageUris.ok),
        height: 300,
        width: 300,
      ),
      Text(
        "No tienes deudas ¡Genial!",
        style: theme.textTheme.bodyLarge,
      )
    ],
  );
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
    {required Function onClick, required BuildContext context}) {
  return FloatingActionButton.extended(
    onPressed: () => onClick(),
    label: Text(style: TextStyle(color: Colors.black), "Nueva deuda"),
    icon: Icon(color: Colors.black, Icons.add),
  );
}

TextEditingController _nombre = TextEditingController();
TextEditingController _valor = TextEditingController();
Widget nuevaDeuda(
    {required Function(String, double) onCreate,
    required ThemeData theme,
    required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(right: 15.0, left: 15),
    child: Row(
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
          onPressed: () => onCreate(_nombre.text, double.parse(_valor.text)),
          icon: const Icon(Icons.check),
        ))
      ],
    ),
  );
}
