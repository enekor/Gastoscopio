import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

Widget selectYear(
    {required List<Cuenta> cc,
    required double width,
    required ThemeData theme,
    required List<int> annosDisponibles}) {
  RxBool _selecSummary = false.obs;
  return SizedBox(
    width: width / 2,
    child: Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          DropdownButtonFormField(
            dropdownColor: theme.primaryColor,
            decoration: InputDecoration(
                filled: true,
                constraints: BoxConstraints(maxWidth: width / 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                fillColor: theme.primaryColor,
                contentPadding: EdgeInsets.all(8)),
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

void nuevoUsuario(
    {required BuildContext context,
    required Function(String) onChange,
    required Function onPressed}) {
  showDialog(
      context: context,
      builder: (context) => Padding(
            padding: const EdgeInsets.all(15.0),
            child: AlertDialog(
              title: const Text("Nuevo usuario"),
              content: Expanded(
                  child: TextField(
                onChanged: onChange,
                autofocus: true,
                decoration: const InputDecoration(labelText: "Nombre"),
              )),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancelar")),
                TextButton(
                    onPressed: () {
                      onPressed();
                      Navigator.pop(context);
                    },
                    child: const Text("Crear"))
              ],
            ),
          ));
}

Widget hasData(
    {required BuildContext context,
    required List<Cuenta> cuentas,
    required double width,
    required double height,
    required Function(dynamic) vuelto,
    required Function(Cuenta) navigateInfo,
    required Function(Cuenta) delete,
    required Function logout,
    required List<int> annosDisponibles}) {
  return Obx(() => Center(
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              Expanded(
                  flex: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(100.0),
                    child: Image.asset(getImageUri(ImageUris.hola)),
                  )),
              Expanded(
                flex: 1,
                child: selectYear(
                    cc: cuentas,
                    width: MediaQuery.of(context).size.width,
                    theme: Theme.of(context),
                    annosDisponibles: annosDisponibles),
              ),
              Expanded(
                flex: 8,
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: cuentas.length >= 2
                      ? GridView.count(
                          childAspectRatio: 2,
                          crossAxisCount: 2,
                          children: cuentas
                              .map((cuenta) => ItemCard(cuenta.Nombre,
                                  cuenta.GetTotal(Values().anno.value),
                                  delete: () => delete(cuenta),
                                  open: () => navigateInfo(cuenta),
                                  context: context))
                              .toList(),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(60.0),
                          child: ListView.builder(
                              itemCount: cuentas.length,
                              itemBuilder: (context, index) => ItemCard(
                                  cuentas[index].Nombre,
                                  cuentas[index].GetTotal(Values().anno.value),
                                  delete: () => delete(cuentas[index]),
                                  open: () => navigateInfo(cuentas[index]),
                                  context: context)),
                        ),
                ),
              )
            ],
          ),
        ),
      ));
}

BottomNavigationBar navigationBar(
    {required Function onLogOut,
    required Function onNewCuenta,
    required ThemeData theme,
    required BuildContext context}) {
  bool oscuro = theme.brightness != Brightness.light;
  void onTap(int pos) {
    switch (pos) {
      case 0:
        onNewCuenta();
        break;
      case 1:
        onLogOut();
        break;
      default:
    }
  }

  return BottomNavigationBar(
    selectedLabelStyle:
        const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
    unselectedLabelStyle: const TextStyle(color: Colors.black),
    elevation: 0,
    items: [
      BottomNavigationBarItem(
          icon: Icon(
            Icons.person_add,
            color: Values().figuraAbajo.value
                ? Colors.black
                : oscuro
                    ? Colors.white
                    : Colors.black,
          ),
          label: "Nueva cuenta"),
      BottomNavigationBarItem(
          icon: Icon(
            Icons.logout,
            color: Values().figuraAbajo.value
                ? Colors.black
                : oscuro
                    ? Colors.white
                    : Colors.black,
          ),
          label: "Cerrar sesión"),
    ],
    onTap: onTap,
    currentIndex: 0,
    backgroundColor: GetColor(ColorTypes.tertiary, context),
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );
}

AppBar appBar({required Function onSettings, bool withName = true}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    title: withName ? const Text("Gastoscopio") : const Text(""),
    actions: [
      IconButton(
          iconSize: 40,
          color: Colors.black,
          onPressed: () => onSettings(),
          icon: const Icon(Icons.settings))
    ],
  );
}
