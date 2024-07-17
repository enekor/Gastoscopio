import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

RxString _month = "".obs;
RxInt _year = DateTime.now().year.obs;
RxList<String> _months = RxList.empty();

Widget summaryView({required Cuenta cuenta, required BuildContext context}) {
  _months.value = cuenta.Meses.where((mes)=>mes.Anno == _year.value).map((mes)=>mes.NMes).toSet().toList();
  _month.value = _months.value.last;
  return Obx(
    ()=> Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex:2,
          child: filters(cuenta: cuenta, context: context) ,
        ),
        Expanded(
          flex:8,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: body(cuenta: cuenta, context: context),
            ),
          ),
        )
      ],
    ),
  );
}

Widget monthSelector({required BuildContext context}) {
  return DropdownButtonFormField(
    dropdownColor: GetColor(ColorTypes.primary, context),
    decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        fillColor: GetColor(ColorTypes.primary, context)),
    value: _months.value.last,
    items: _months.value.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: (item) {
      _month.value = item.toString();
    },
  );
}

Widget yearSelector({required BuildContext context, required Cuenta cuenta}){
  List<int> annos = cuenta.Meses.map((mes)=>mes.Anno).toSet().toList();
  return DropdownButtonFormField(
    dropdownColor: GetColor(ColorTypes.primary, context),
    decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        fillColor: GetColor(ColorTypes.primary, context)),
    value: _year.value,
    items: annos.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item.toString()),
      );
    }).toList(),
    onChanged: (item) {
      _year.value = int.parse(item.toString());
    },
  );
}


Widget filters({required Cuenta cuenta, required BuildContext context}){
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Expanded(
        flex:5,
        child: yearSelector(context: context, cuenta: cuenta),
      ),
      Expanded(
        flex:5,
        child: monthSelector(context: context),
      )
    ],
  );
}
Widget total(Cuenta cuenta, BuildContext context)=>Obx(
  ()=>Card(
    color: GetColor(ColorTypes.appBar, context),
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total"),
              Text("${cuenta.Meses.firstWhere((mes)=>mes.NMes == _month.value && mes.Anno == _year.value).GetAhorros().toStringAsFixed(2)}${Values().moneda.value}")
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Ingresos base"),
              Text("${cuenta.Meses.firstWhere((mes)=>mes.NMes == _month.value && mes.Anno == _year.value).Ingreso.toStringAsFixed(2)}${Values().moneda.value}")
            ],
          )
        ],
      ),
    ),
  ),
);

Widget muestreo(String tipo, Cuenta cuenta, bool isIngreso, bool isExtra) {
  List<String> aMostrar = [];
  if(isIngreso){
    List<Gasto> ingresos = cuenta.Meses.firstWhere((mes)=>mes.Anno == _year.value && mes.NMes == _month.value).Gastos.where((gasto)=>gasto.valor<0).toList();

    aMostrar = ingresos.map((valor) => (-1*valor.valor).toStringAsFixed(2)).toList();
  }
  else{
    if(isExtra){
          List<Gasto> extras = cuenta.Meses.firstWhere((mes)=>mes.Anno == _year.value && mes.NMes == _month.value).Extras;

          aMostrar = extras.map((valor) => valor.valor.toStringAsFixed(2)).toList();
    }
    else{
      List<Gasto> gastos = cuenta.Meses.firstWhere((mes)=>mes.Anno == _year.value && mes.NMes == _month.value).Gastos.where((gasto)=>gasto.valor>0).toList();

      aMostrar = gastos.map((valor) => valor.valor.toStringAsFixed(2)).toList();
    }
  }

  return aMostrar.isNotEmpty
  ? Padding(
    padding: const EdgeInsets.all(15.0),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(tipo),
      Column(
        children: aMostrar.map((value)=>Text("$value${Values().moneda.value}")).toList(),
      )
    ],
    ),
  )
: Container();
}

Widget body({required Cuenta cuenta, required BuildContext context}){
  return Padding(padding: EdgeInsets.all(15),
  child: Column(children: [
    total(cuenta,context),
    muestreo("Gastos", cuenta,false,false),
    muestreo("Gastos extra", cuenta,false,true),
    muestreo("Ingresos", cuenta,true,false),
  ],),);
}
