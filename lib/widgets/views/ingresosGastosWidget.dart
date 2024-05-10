import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/GastoView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/Get.dart';
import 'package:get/get.dart';

TextEditingController _nombreNuevo = TextEditingController();
String _nombreNuevoDropdown = "";
TextEditingController _valorNuevo = TextEditingController();
TextEditingController _ingresoNuevo = TextEditingController();
RxBool _isIngresoSeleccionado = false.obs;

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

Widget bodyHasDatos({required List<Gasto> gastos,required Function(String,double) onSaveValue, required Function(String,double) onDeleteValue, required ThemeData theme, required bool isIngresos}){
  List<Widget> cards = [];
  int contador = 1;

  for(Gasto gasto in gastos){
    cards.add(gastoView(onSaveValue, onDeleteValue, (selec)=>Values().gastoSeleccionado.value = selec, gasto.nombre, isIngresos?-1*gasto.valor:gasto.valor, contador, theme));
    contador++;
  }

  return gastos.isNotEmpty
  ? Column(
      children:[
        Expanded(
          flex:1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(isIngresos ? "Ingresos extra" : "Gastos básicos"),
              Text("${gastos.fold<double>(0.0, (previousValue, gasto) => isIngresos ? previousValue+(-1*gasto.valor) : previousValue+gasto.valor).toStringAsFixed(2)}€")
            ],
          ),
        ),
        Expanded(
          flex:9,
          child: ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) => cards[index],
          ),
        )
      ]
    )
  : bodyHasNoDatos();
}

Widget extrasListView ({ required List<Gasto> extras, required Function(String,double,bool) onCreate, required Function(String,double) onSaveExtra, required Function(String,double) onDeleteExtra, required, required ThemeData theme}){
  List<Widget> extraCards = [];

  int contador = 0;
  for(Gasto extra in extras){
    extraCards.add(gastoView(onSaveExtra, onDeleteExtra, (pos)=>Values().gastoSeleccionado.value = pos, extra.nombre, extra.valor, contador, theme));
    contador++;
  }

  return extras.isNotEmpty
    ? ListView( 
      children: extraCards,
    )
    : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            getImageUri(ImageUris.ok),
            height: 200,
            width: 200
          ),
          const Text("¡Que bien! no hay extras")
        ],
      ),
    );
}

Widget bodyHasNoDatos(){
  
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          getImageUri(ImageUris.buscando),
          height: 200,
          width: 200,
        ),
        const Text("Esto está muy vacio"),
      ],
    ),
  );
}

FloatingActionButton floatingButton(bool nuevo, {required Function onChange}){
  return FloatingActionButton.extended(
    onPressed: ()=>onChange(),
    icon: !nuevo
      ? const Icon(Icons.add)
      : const Icon(Icons.close),
    label: nuevo
      ?const Text("Cancelar")
      :const Text("Nuevo fijo"),
  );
}

Widget showExtras({required double valorExtras, required Function(bool) checkExtras, required bool extrasChecked}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Text("Ver extras (${valorExtras.toStringAsFixed(2)}€)"),
      Switch(value: extrasChecked, onChanged: checkExtras)
    ],
  );
}

Widget createNew({required bool extraSelected, required Function(String,double,bool) onCreateGasto,required ThemeData theme, required bool IsIngresos, required List<Gasto> gastos, required List<Gasto> extras}){
  RxBool _yaExistente = false.obs;
  List<String> datos = extraSelected
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
                  onCreateGasto(!_yaExistente.value?_nombreNuevo.text:_nombreNuevoDropdown,double.parse(_valorNuevo.text),extraSelected);
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
                  autofillHints: extraSelected ? extras.map((e) => e.nombre).toList() :gastos.map((e) => e.nombre).toList(),
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
  return Obx(()=> Card(
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
    ),
  );
}