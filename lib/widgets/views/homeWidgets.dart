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
                    padding: const EdgeInsets.all(50.0),
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
                          childAspectRatio: 1.2,
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

Widget hasDataLand(
    {required BuildContext context,
    required List<Cuenta> cuentas,
    required double width,
    required double height,
    required Function(dynamic) vuelto,
    required Function(Cuenta) navigateInfo,
    required Function(Cuenta) delete,
    required Function logout,
    required List<int> annosDisponibles,
    required Function onLogOut,
    required Function onNewCuenta,
    required Function onSettings}) {
  return Obx(() => Row(
        children: [
          Expanded(
            flex: 1,
            child: Card.filled(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(40),
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(40))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                      onPressed: () => onSettings(),
                      icon: Icon(Icons.settings)),
                  IconButton(
                      onPressed: () => onNewCuenta(),
                      icon: Icon(Icons.person_add)),
                  IconButton(
                      onPressed: () => onLogOut(), icon: Icon(Icons.logout)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      flex: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(50.0),
                        child: Image.asset(getImageUri(ImageUris.hola)),
                      )),
                  Expanded(
                    flex: 2,
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
                      child: cuentas.length >= 0.3
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(left: 60, right: 60),
                              child: Center(
                                child: GridView.count(
                                  childAspectRatio: 2,
                                  crossAxisCount:
                                      cuentas.length >= 4 ? 4 : cuentas.length,
                                  children: cuentas
                                      .map((cuenta) => ItemCard(cuenta.Nombre,
                                          cuenta.GetTotal(Values().anno.value),
                                          delete: () => delete(cuenta),
                                          open: () => navigateInfo(cuenta),
                                          context: context))
                                      .toList(),
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(60.0),
                              child: ListView.builder(
                                  itemCount: cuentas.length,
                                  itemBuilder: (context, index) => ItemCard(
                                      cuentas[index].Nombre,
                                      cuentas[index]
                                          .GetTotal(Values().anno.value),
                                      delete: () => delete(cuentas[index]),
                                      open: () => navigateInfo(cuentas[index]),
                                      context: context)),
                            ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ));
}

BottomNavigationBar navigationBar(
    {required Function onLogOut,
    required Function onNewCuenta,
    required ThemeData theme,
    required BuildContext context}) {
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
    elevation: 0,
    items: const [
      BottomNavigationBarItem(
          icon: Icon(
            Icons.person_add,
          ),
          label: "Nueva cuenta"),
      BottomNavigationBarItem(
          icon: Icon(
            Icons.logout,
          ),
          label: "Cerrar sesión"),
    ],
    onTap: onTap,
    currentIndex: 0,
    showSelectedLabels: true,
    showUnselectedLabels: true,
  );
}

AppBar appBar(
    {required Function onSettings,
    bool withName = true,
    required BuildContext context}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    title: withName
        ? const Text(
            "Gastoscopio",
          )
        : const Text(""),
    actions: [
      IconButton(
          iconSize: 40,
          onPressed: () => onSettings(),
          icon: const Icon(Icons.settings))
    ],
  );
}
