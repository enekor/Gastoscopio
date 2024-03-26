import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';

Widget fijosView({required List<Gasto> gastos, required Function(String,double) onDelete, required Function(String,double) onChange, required ThemeData theme}){
  int contador = 0;
  List<Widget> gastosW = [];

  for(Gasto v in gastos){
    gastosW.add(gastoView(
      onChange, 
      onDelete, 
      (v2)=>Values().gastoSeleccionado.value = v2,
      v.nombre, 
      v.valor, 
      contador, 
      theme)
    );
      
    contador++;
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: gastosW
  );
}

Widget nuevoFijo({required Function(String,double) onCreate, required ThemeData theme}){
  String _nombre = "";
  double _valor = 0;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.only(right: 8,left: 8),
          child: 
            TextField(
              onChanged: (v)=>_nombre = v,
              decoration: const InputDecoration(
                labelText: "Nombre"
              ),
              autofocus: true,
          ),
        )
      ),
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.only(right: 8,left: 8),
          child: 
            TextField(
              onChanged: (v)=>_valor = double.parse(v),
              decoration: const InputDecoration(
                labelText: "Monto"
              ),
              autofocus: true,
              keyboardType: TextInputType.number,
          ),
        )
      ),
      Expanded(
        child: IconButton(
          onPressed: ()=>onCreate(_nombre,_valor),
          icon: const Icon(Icons.check),
          color: theme.brightness == Brightness.dark
            ? AppColorsD.okButtonColor
            : AppColorsL.okButtonColor
          )
      )
    ],
  );
}

Widget noFijos(){
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        "lib/assets/images/gatobuscando.png",
        width: 300,
        height: 300,
      ),
      Text("No tienes gastos fijos")
    ],
  );
}

FloatingActionButton crearNuevo(){
  return FloatingActionButton(
    onPressed: ()=>Values().gastoSeleccionado.value != -2
      ?Values().gastoSeleccionado.value = -2
      :Values().gastoSeleccionado.value = -1,
    child: Icon(Values().gastoSeleccionado.value == -2
        ?Icons.close
        :Icons.add
    ),
  );
}