import 'dart:developer';

import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/pantallas/info.dart';
import 'package:cuentas_android/pantallas/summary.dart';
import 'package:cuentas_android/pattern/positions.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

 Widget selectYear({required List<Cuenta> cc,required double width,required ThemeData theme, required bool Function() selecSummary}) {
  RxBool _selecSummary = false.obs;
  return SizedBox(
    width: width/2,
    child: Padding(
      padding: const EdgeInsets.only(top:8.0,left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            flex:8,
            child: DropdownButtonFormField(
              dropdownColor: theme.primaryColor,
              decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  fillColor: theme.primaryColor,
                  contentPadding: EdgeInsets.all(8)
                ),
              value: Values().anno.value,
              items: Values().GetAnnosDisponibles(cc).map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item.toString()),
                );
              }).toList(),
              onChanged: (item) {
                Values().anno.value = item!;
              },
            ),
          ),
          Expanded(
            flex:2,
            child: IconButton(
              onPressed: (){
                _selecSummary.value = selecSummary();
              },
              color: _selecSummary.value
              ?theme.brightness == Brightness.dark
                ? AppColorsD.errorButtonColor
                :AppColorsL.errorButtonColor
              :theme.brightness == Brightness.dark
                ? AppColorsD.okButtonColor
                :AppColorsL.okButtonColor,
              icon: const Icon(Icons.manage_search),
              ),
          )
        ],
      ),
    ),
  );
 }

void nuevoUsuario({required BuildContext context, required Function(String) onChange,required Function onPressed}){
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          const Text("Nuevo usuario"),
          Expanded(
            child: TextField(
              onChanged: onChange,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Nombre"
              ),
            )
          ),
          FloatingActionButton(
            onPressed: ()async=> await onPressed(),
            child: const Icon(Icons.person_add),
          )
        ],
      ),
    )
  );
}

Widget hasData({required BuildContext context,required RxBool seleccionarSummary,required RxList<Cuenta> cuentas,required double width, required double height, required Function(dynamic) vuelto, required Function(Cuenta) navigateInfo}){
    return Obx(()=>Center(
        child:Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            seleccionarSummary.value
              ? const Text("Selecciona una cuenta para ver el historial")
              : const SizedBox(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: cuentas.value.map<Widget>((cuenta) => GestureDetector(
                  onTap: ()=>navigateInfo(cuenta),
                  child: SizedBox(
                    height: width/4,
                    width:  width/4,
                    child: Center(
                      child: ItemCard(cuenta.Nombre,
                          cuenta.GetTotal(Values().anno.value)),
                    ),
                  )))
                  .toList()
              ),
            ),
          ],
        ),
      ),
    );
  }