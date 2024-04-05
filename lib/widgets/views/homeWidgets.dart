import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

 Widget selectYear({required List<Cuenta> cc,required double width,required ThemeData theme, required List<int> annosDisponibles}) {
  RxBool _selecSummary = false.obs;
  return SizedBox(
    width: width/2,
    child: Padding(
      padding: const EdgeInsets.only(top:8.0,left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          DropdownButtonFormField(
            dropdownColor: theme.primaryColor,
            decoration: InputDecoration(
                filled: true,
                constraints: BoxConstraints(maxWidth: width/4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                fillColor: theme.primaryColor,
                contentPadding: EdgeInsets.all(8)
              ),
            value: Values().anno.value,
            items: annosDisponibles.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item.toString()),
              );
            }).toList(),
            onChanged: (item) {
              Values().anno.value = item!;
            },
          )
        ],
      ),
    ),
  );
 }

void nuevoUsuario({required BuildContext context, required Function(String) onChange,required Function onPressed}){
  showDialog(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(15.0),
      child: AlertDialog(
        title: const Text("Nuevo usuario"),
        content: TextField(
          onChanged: onChange,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Nombre"
          ),
        ),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () {
              onPressed();
              Navigator.pop(context);
            }, 
            child: const Text("Crear")
          ) 
        ],
      ),
    )
  );
}

Widget hasData({required BuildContext context,required RxList<Cuenta> cuentas,required double width, required double height, required Function(dynamic) vuelto, required Function(Cuenta) navigateInfo, required Function(Cuenta) delete, required Function logout, required List<int> annosDisponibles}){
  return Obx(()=>Center(
    child:Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        selectYear(
          cc: cuentas.value, 
          width: MediaQuery.of(context).size.width, 
          theme: Theme.of(context),
          annosDisponibles: annosDisponibles
        ),
        const SizedBox(height: 80,),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: cuentas.value.map<Widget>((cuenta) => SizedBox(
              width:  width/4,
              child: Center(
                child: ItemCard(cuenta.Nombre,cuenta.GetTotal(Values().anno.value),delete: ()=>delete(cuenta),open: ()=>navigateInfo(cuenta)),
              ),
            ))
              .toList()
          ),
        ),
      ],
    ),
  ));
}

BottomNavigationBar navigationBar({required Function onLogOut, required Function onSettings, required Function onNewCuenta, required ThemeData theme}){
  bool oscuro = theme.brightness != Brightness.light;
  void onTap(int pos){
    switch (pos) {
      case 0:
        onNewCuenta();
        break;
      case 1:
        onSettings();
        break;
      case 2:
        onLogOut();
        break;
      default:
    }
  }

  return BottomNavigationBar(
    type: BottomNavigationBarType.shifting,
    elevation: 0,
    items: [
      BottomNavigationBarItem(icon: const Icon(Icons.person_add), label: "Nueva cuenta", backgroundColor: oscuro?AppColorsL.secondaryColor5:AppColorsD.secondaryColor5),
      BottomNavigationBarItem(icon: const Icon(Icons.settings), label: "Ajustes", backgroundColor: oscuro?AppColorsL.secondaryColor5:AppColorsD.secondaryColor5),
      BottomNavigationBarItem(icon: const Icon(Icons.logout),label: "Cerrar sesión", backgroundColor:oscuro?AppColorsL.secondaryColor5:AppColorsD.secondaryColor5 )
    ],
    onTap: onTap,
    currentIndex: 0,
    backgroundColor: Colors.red,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );
}