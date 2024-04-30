import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get.dart';

TextEditingController _nombreNuevo = TextEditingController();
String _nombreNuevoDropdown = "";
TextEditingController _valorNuevo = TextEditingController();
TextEditingController _ingresoNuevo = TextEditingController();
RxBool _isIngresoSeleccionado = false.obs;
RxBool _extraSelected = false.obs;

String valorTotal(bool isIngreso, double gastos, double extras, double ingresos){
  return isIngreso ? (-1*gastos + ingresos).toStringAsFixed(2) : (gastos+extras).toStringAsFixed(2);
}

AppBar appBar({required List<Gasto> datos,required List<Gasto> extras, required bool isIngreso, required double ingreso, required ThemeData theme}){
  return AppBar(
    title: Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text("Valor total"),
          Text("${valorTotal(isIngreso, datos.fold(0.0, (prevValue, gasto) => prevValue + gasto.valor), extras.fold<double>(0, (previousValue, extra) => previousValue+extra.valor),ingreso)}€")
        ],
      ),
    ),
  );
}

Widget bodyHasDatos({required List<Gasto> gastos, required RxList<Gasto> extras,required Function(String,double) onSaveValue, required Function(String,double) onDeleteValue, required ThemeData theme, required bool isIngresos, required Function(String,double) onSaveExtra,required Function(String,double) onDeleteExtra, required bool isIngreso, required Function(double) onIngresoChange, required double ingreso,}){
  List<Widget> cards = [];
  List<Widget> extraCards = [];
  int contador = 1;
  double valorExtras = extras.fold<double>(0.0, (previousValue, gasto) => previousValue+gasto.valor);

  if(gastos.isNotEmpty){
    for(Gasto gasto in gastos){
      cards.add(gastoView(onSaveValue, onDeleteValue, (selec)=>Values().gastoSeleccionado.value = selec, gasto.nombre, isIngresos?-1*gasto.valor:gasto.valor, contador, theme));
      contador++;
    }
  }else{
    _extraSelected.value = true;
  }

  for(Gasto extra in extras){
    extraCards.add(gastoView(onSaveExtra, onDeleteExtra, (pos)=>Values().gastoSeleccionado.value = pos, extra.nombre, extra.valor, contador, theme));
    contador++;
  }

  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      isIngreso
          ? ingresoView(onIngresoChange: onIngresoChange, ingreso: ingreso, theme: theme)
          :Container(),
      Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(isIngreso ? "Ingresos extra" : "Gastos"),
                Text("${gastos.fold<double>(0.0, (previousValue, gasto) => previousValue+gasto.valor).toStringAsFixed(2)}€")
              ],
            ),
            Column(children: cards,)
          ]
        ),
      !isIngresos
        ? Divider()
        : Container(),
      !isIngresos
        ?Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text("Extras"),
            TextButton(onPressed: ()=>_extraSelected.value = !_extraSelected.value, child: Text("${valorExtras.toStringAsFixed(2)}€"))
          ],
        )
        : Container(),
      !isIngreso
        ? _extraSelected.value
          ? extras.isNotEmpty
            ? Column( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: extraCards,
            )
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  getImageUri(ImageUris.ok),
                  height: 200,
                  width: 200
                ),
                const Text("¡Que bien! no hay extras")
              ],
            )
          : Container()
        :Container()
    ],
  );
}

Widget bodyHasNoDatos({  required RxList<Gasto> extras,required bool isIngreso, required Function(double) onIngresoChange, required double ingreso, required ThemeData theme,required Function(String,double) onSaveExtra,required Function(String,double) onDeleteExtra}){
  List<Widget> extraCards = [];
  int contador = 1;

  for(Gasto extra in extras){
    extraCards.add(gastoView(onSaveExtra, onDeleteExtra, (pos)=>Values().gastoSeleccionado.value = pos, extra.nombre, extra.valor, contador, theme));
    contador++;
  }
  
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        isIngreso
          ?ingresoView(onIngresoChange: onIngresoChange, ingreso: ingreso, theme: theme)
          :Container(),
        Image.asset(
            getImageUri(ImageUris.RascandoCabeza),
            height: 200,
            width: 200,
          ),
          const Text("Esto está muy vacio"),
          _extraSelected.value
        ? extras.isNotEmpty
          ? Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: extraCards,
          )
          : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                getImageUri(ImageUris.ok),
                height: 200,
                width: 200
              ),
              const Text("¡Que bien! no hay extras")
            ],
          )
        : Container()
      ],
    ),
  );
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

Widget createNew({required Function(String,double) onCreateGasto, required Function(String,double) onCreateExtra, required ThemeData theme, required bool IsIngresos, required RxList<Gasto> gastos, required RxList<Gasto> extras}){
  RxBool _yaExistente = false.obs;
  List<String> datos = _extraSelected.value
            ?extras.map((e) => e.nombre).toList()
            :gastos.where((gasto) => IsIngresos ? gasto.valor<0 : gasto.valor>0).map((e) => e.nombre).toList();

  return Obx(()=>Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex:2,
              child: IconButton(
                onPressed: () {
                  Values().gastoSeleccionado.value = -1;
                  if(_extraSelected.value && !IsIngresos){
                    onCreateExtra(!_yaExistente.value?_nombreNuevo.text:_nombreNuevoDropdown,double.parse(_valorNuevo.text));
                  }else{
                    onCreateGasto(!_yaExistente.value?_nombreNuevo.text:_nombreNuevoDropdown,double.parse(_valorNuevo.text));
                  }
                  _nombreNuevo.clear();
                  _valorNuevo.clear();
                }, 
                icon: const Icon(Icons.check), 
                color: theme.brightness == Brightness.dark
                  ?AppColorsD.okButtonColor
                  :AppColorsL.okButtonColor
              ),
            ),
            Expanded(
              flex:5,
              child: _yaExistente.value
                ?DropdownButtonFormField(
                  items: datos.map((e) => DropdownMenuItem(value: e,child: Text(e),)).toList(),
                  onChanged: (selected)=>_nombreNuevoDropdown = selected!,
                  value: datos.first,
                  iconSize: 1,
                  )
                :TextField(
                  autofillHints: _extraSelected.value ? extras.map((e) => e.nombre).toList() :gastos.map((e) => e.nombre).toList(),
                  controller: _nombreNuevo,
                  decoration: const InputDecoration(labelText: "Nombre"),
                  autofocus: true,
                )
            ),
            Expanded(
              flex: 3,
              child: TextField(
              controller: _valorNuevo,
              decoration: const InputDecoration(
                labelText: "Monto"
              ),
              keyboardType: TextInputType.number,
            )),
          ],
        ),
        datos.isNotEmpty
          ?Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Switch(value: _yaExistente.value, onChanged: (value)=>_yaExistente.value = value),
              const Text("Aumentar a uno ya existente")
            ],
          )
          :Container()
      ],
    ),
  );
}

Widget ingresoView({required Function(double) onIngresoChange, required double ingreso, required ThemeData theme}){
  return Card(
    color: theme.brightness == Brightness.dark ? AppColorsD.okButtonColor : AppColorsL.okButtonColor,
    child: _isIngresoSeleccionado.value
      ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            onPressed: (){
              _isIngresoSeleccionado.value = false;
              onIngresoChange(double.parse(_ingresoNuevo.text));
            },
            icon: const Icon(Icons.check),
            iconSize: theme.textTheme.labelLarge!.fontSize
          ),
          const SizedBox(width: 8,),
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
        ],
      )
      :Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
        Text("Ingreso base",style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize)),
        TextButton(child: Text("${ingreso.toStringAsFixed(2)}€",style: TextStyle(fontSize: theme.textTheme.labelLarge!.fontSize)), onPressed: ()=>_isIngresoSeleccionado.value = true,)
      ],
    ),
  );
}