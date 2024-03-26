import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget GetExtras({required List<Gasto> extras, required Function(String,double) onChangeExtra,required Function(String,double) onDeleteExtra, required ThemeData theme}) {
  List<Widget> ret = [];
  int contador = 1;

  for (Gasto gasto in extras) {
    ret.add(
      gastoView(
        onChangeExtra,
        onDeleteExtra,
        (posicion)=>Values().gastoSeleccionado.value = posicion,
        gasto.nombre,
        gasto.valor,
        contador,
        theme
      )
    );
    contador++;
  }

  return SingleChildScrollView(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ret,
    ),
  );
}

Widget extrasHasNoData(){
  return Center(
    child: Column(
      children: [
        Image.asset(
          "lib/assets/images/gatook.png",
          height: 300,
          width: 300,
        ),
        const Text("Parece que no tienes extras, bien hecho")
      ],
    ),
  );
}

TextEditingController _nombreNuevo = TextEditingController();
TextEditingController  _valorNuevo = TextEditingController();
Widget crearNuevo({required Function(String,double) onCreateExtra }){

  return Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceAround,
    children: [
      Expanded(
        child: IconButton(
          icon: const Icon(Icons.check),
          onPressed:()=> onCreateExtra(_nombreNuevo.text,double.parse(_valorNuevo.text)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextField(
          decoration: const InputDecoration(
              labelText: "Nombre"),
          controller: _nombreNuevo,
        ),
      ),
      const SizedBox(
        width: 10,
      ),
      Expanded(
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: "Monto"),
          controller: _valorNuevo,
        ),
      )
    ],
  );
}