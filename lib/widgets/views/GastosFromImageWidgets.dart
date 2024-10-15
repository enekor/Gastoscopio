import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Widget ImageHasData(
    {required Map<List<String>, List<double>> datos,
    required BuildContext context,
    required void Function(Gasto) onAddRemove}) {
  List<Gasto> gastosToInsert = [];

  void saveGasto(Gasto gasto) {
    gastosToInsert.add(gasto);
    onAddRemove(gasto);
  }

  void deleteGasto(Gasto gasto) {
    gastosToInsert.remove(gasto);
    onAddRemove(gasto);
  }

  return SizedBox(
    height: MediaQuery.of(context).size.height,
    width: MediaQuery.of(context).size.width,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: ListView.builder(
          itemCount: datos.values.first.length,
          itemBuilder: (context, index) => MiniGastoView(
              nombres: datos.keys.first,
              onDelete: deleteGasto,
              onSave: saveGasto,
              valor: datos.values.first[index])),
    ),
  );
}
