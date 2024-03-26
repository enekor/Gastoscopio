import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get.dart';

TextEditingController _nombreNuevo = TextEditingController();
TextEditingController _valorNuevo = TextEditingController();
TextEditingController _ingresoNuevo = TextEditingController();
RxBool _isIngresoSeleccionado = false.obs;

String valorTotal(bool isIngreso, double gastos, double ingresos){
  return isIngreso ? (-1*gastos + ingresos).toStringAsFixed(2) : gastos.toStringAsFixed(2);
}

AppBar appBar({required List<Gasto> datos, required bool isIngreso, required Function(double) onIngresoChange, required double ingreso, required ThemeData theme}){
  return AppBar(
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex:5,
          child: Card(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text("Valor total"),
                Text("${valorTotal(isIngreso, datos.fold(0.0, (prevValue, gasto) => prevValue + gasto.valor), ingreso)}€")
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: isIngreso
            ? ingresoView(onIngresoChange: onIngresoChange, ingreso: ingreso, theme: theme)
            :Container(),
        )
      ],
    ),
  );
}

Widget bodyHasDatos({required List<Gasto> datos, required Function(String,double) onSaveValue, required Function(String,double) onDeleteValue, required ThemeData theme, required bool isIngresos, required RxDouble extras, required Function navigateExtras}){
  List<Widget> cards = [];
  int contador = 1;

  for(Gasto gasto in datos){
    cards.add(gastoView(onSaveValue, onDeleteValue, (selec)=>Values().gastoSeleccionado.value = selec, gasto.nombre, isIngresos?-1*gasto.valor:gasto.valor, contador, theme));
    contador++;
  }

  return SingleChildScrollView(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(children: cards,),
        !isIngresos
          ?Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text("Extras"),
              TextButton(onPressed: ()=>navigateExtras(), child: Text("${extras.value.toStringAsFixed(2)}€"))
            ],
          )
          : Container()
      ],
    ),
  );
}

Widget bodyHasNoDatos(){
  return Column();
}

FloatingActionButton floatingButton(){
  return FloatingActionButton(
    onPressed: Values().gastoSeleccionado.value == -2
      ? ()=> Values().gastoSeleccionado.value = -1
      : ()=> Values().gastoSeleccionado.value = -2 ,
    child: Values().gastoSeleccionado.value != -2
      ? const Icon(Icons.add)
      : const Icon(Icons.close)
  );
}

Widget createNew({required Function(String,double) onCreate, required ThemeData theme}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(child: TextField(
        controller: _nombreNuevo,
        decoration: const InputDecoration(
          labelText: "Nombre",
        ),
        autofocus: true,
      )),
      const SizedBox(width: 8,),
      Expanded(child: TextField(
        controller: _valorNuevo,
        decoration: const InputDecoration(
          labelText: "Monto"
        ),
        keyboardType: TextInputType.number,
      )),
      const SizedBox(width: 8,),
      IconButton(
        onPressed: () {
          Values().gastoSeleccionado.value = -1;
          onCreate(_nombreNuevo.text,double.parse(_valorNuevo.text));
        }, 
        icon: const Icon(Icons.check), 
        color: theme.brightness == Brightness.dark
          ?AppColorsD.okButtonColor
          :AppColorsL.okButtonColor
      )
    ],
  );
}

Widget ingresoView({required Function(double) onIngresoChange, required double ingreso, required ThemeData theme}){
  return _isIngresoSeleccionado.value
    ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text("Ingreso base", style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize),),
        const SizedBox(width: 8,),
        Expanded(
          child: TextField(
            style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize),
            autofocus: true,
            controller: _ingresoNuevo,
            decoration: const InputDecoration(labelText: "Monto"),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8,),
        IconButton(
          onPressed: (){
            _isIngresoSeleccionado.value = false;
            onIngresoChange(double.parse(_ingresoNuevo.text));
          },
          icon: const Icon(Icons.check),
          color: theme.brightness == Brightness.dark
            ? AppColorsD.okButtonColor
            : AppColorsL.okButtonColor,
          iconSize: theme.textTheme.labelLarge!.fontSize
        )
      ],
    )
    :Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
      Text("Ingreso base",style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize)),
      TextButton(child: Text("${ingreso.toStringAsFixed(2)}€",style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize)), onPressed: ()=>_isIngresoSeleccionado.value = true,)
    ],
  );
}
