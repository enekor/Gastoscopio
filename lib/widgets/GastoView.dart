import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget gastoView(
    void Function(String, double) onSave,
    void Function(String, double) onDelete,
    void Function(int) onSelect,
    String nombre,
    double valor,
    int contador,
    ThemeData theme) {
  
  double _nuevoValor = valor;
  RxBool borrado = false.obs;
  return Obx(()=>Values().gastoSeleccionado.value == contador
    ? Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(nombre),
              Expanded(
                child: TextField(
                  autofocus: true,
                  onChanged: (v)=>_nuevoValor = double.parse(v),
                  decoration: const InputDecoration(
                    labelText: "Monto"
                  ),
                  keyboardType: TextInputType.number
                ),
              ),
              IconButton(
                onPressed: () {
                  Values().gastoSeleccionado.value = -1;
                  onSave(nombre,_nuevoValor);
                }, 
                icon: const Icon(Icons.check),
                color: theme.brightness == Brightness.dark
                  ? AppColorsD.okButtonColor
                  : AppColorsL.okButtonColor
              ),
              IconButton(
                onPressed: () {
                  Values().gastoSeleccionado.value = -1;
                  onDelete(nombre,valor);
                  borrado.value = true;
                }, 
                icon: const Icon(Icons.delete),
                color: theme.brightness == Brightness.dark
                  ? AppColorsD.errorButtonColor
                  : AppColorsL.errorButtonColor
              )
            ],
          ),
        )
      ),
    )
    : borrado.value == false
      ?Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(nombre),
                Text("${valor.toStringAsFixed(2)}€"),
                IconButton(
                  onPressed: () {
                    Values().gastoSeleccionado.value = -1;
                    onSelect(contador);
                  }, 
                  icon: const Icon(Icons.edit),
                  color: theme.hintColor,
                ),
              ],
            ),
          ),
        ),
      )
      :deletedView(onSave,Gasto(nombre: nombre, valor: valor))
  );
}

Widget deletedView(
  void Function(String,double) onRestore,
  Gasto gasto){

  return Card(
    child: Padding(
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(gasto.nombre),
          IconButton(
            onPressed: ()=>onRestore(gasto.nombre,gasto.valor), 
            icon: const Icon(Icons.restore),
            color: Colors.blue,
          )
        ],
      ),
    ),
  );
}