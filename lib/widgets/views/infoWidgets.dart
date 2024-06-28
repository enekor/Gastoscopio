import 'package:cuentas_android/models/Cuenta.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/material.dart';

Widget monthSelector(
    {required ThemeData theme,
    required String mes,
    required Function(String) onSelecMes}) {
  return DropdownButtonFormField(
    dropdownColor: theme.primaryColor,
    decoration: InputDecoration(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        fillColor: theme.primaryColor),
    value: mes,
    items: Values().nombresMes.map((item) {
      return DropdownMenuItem(
        value: item,
        child: Text(item),
      );
    }).toList(),
    onChanged: (item) {
      mes = item.toString();
      Values().ChangeMes(mes);
      onSelecMes(mes);
    },
  );
}

Widget topPart(
    {required double currentMounth,
    required double currentYear,
    required String userName,
    required BuildContext context}) {
  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Column(
      children: [
        Expanded(
          flex: 4,
          child: Text(style: const TextStyle(fontSize: 130), userName),
        ),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  style: const TextStyle(
                    fontSize: 50,
                  ),
                  textAlign: TextAlign.center,
                  "${Values().GetMes()}    ${currentMounth.toStringAsFixed(2)}${Values().moneda.value}"),
              Text(
                  style: const TextStyle(fontSize: 50),
                  textAlign: TextAlign.center,
                  "${Values().anno.value.toString()}    ${currentMounth.toStringAsFixed(2)}${Values().moneda.value}"),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget middlePart(
    {required double ingreso,
    required BuildContext context,
    required Function(String) onSelecMes,
    required String mes,
    required Function onIngresoTap}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: monthSelector(
                theme: Theme.of(context), mes: mes, onSelecMes: onSelecMes),
          )),
      Expanded(
        flex: 5,
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Card(
            color: GetColor(ColorTypes.tertiary, context),
            child: GestureDetector(
              onTap: () => onIngresoTap(),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Ingresos",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        ingreso.toStringAsFixed(2) +
                            Values().moneda.value) //si falla arreglar esto
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    ],
  );
}

Widget bottomPart(
    {required Function onGastosTap,
    required Function onPricesTap,
    required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(top: 50, bottom: 50),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => onGastosTap(),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Card(
                    color: GetColor(ColorTypes.primary, context),
                    child: const Center(
                      child: Text(
                          style: TextStyle(fontWeight: FontWeight.bold),
                          "Gestión de gastos"),
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Icon(
                    Icons.attach_money_rounded,
                    size: 50,
                  ),
                )
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: GestureDetector(
            onTap: () => onPricesTap(),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 50,
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Card(
                    color: GetColor(ColorTypes.primary, context),
                    child: const Center(
                      child: Text(
                          style: TextStyle(fontWeight: FontWeight.bold),
                          "Comparación de precios"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

BottomNavigationBar bottomNavBar(
    {required Function onDeudasTap,
    required Function onRecurrentesTap,
    required Function onSummaryTap,
    required BuildContext context}) {
  void onCLick(int selected) {
    switch (selected) {
      case 0:
        onSummaryTap();
        break;
      case 1:
        onRecurrentesTap();
        break;
      case 2:
        onDeudasTap();
        break;
    }
  }

  return BottomNavigationBar(
    elevation: 0,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.summarize), label: "Resumen"),
      BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month), label: "Recurrentes"),
      BottomNavigationBarItem(
          icon: Icon(Icons.money_off_rounded), label: "Deudas")
    ],
    onTap: (index) => onCLick(index),
    currentIndex: 0,
    backgroundColor: GetColor(ColorTypes.tertiary, context),
    showUnselectedLabels: true,
    showSelectedLabels: true,
  );
}

Widget body(
    {required double ingreso,
    required String mes,
    required Function onPricesTap,
    required Function(String) onSelecMes,
    required Function onIngresoTap,
    required Function onGastosTap,
    required BuildContext context,
    required Cuenta cuenta}) {
  return Column(
    children: [
      Expanded(
        flex: 7,
        child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/images/dinero.jpg'),
                colorFilter: ColorFilter.mode(Colors.white, BlendMode.modulate),
                fit: BoxFit.cover,
              ),
            ),
            child: topPart(
                currentMounth: cuenta.Meses.where(
                        (v) => v.NMes == mes && v.Anno == Values().anno.value)
                    .first
                    .GetAhorros(),
                currentYear: cuenta.GetTotal(Values().anno.value),
                userName: cuenta.Nombre,
                context: context)),
      ),
      Expanded(
        flex: 1,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8, right: 25, left: 25),
          child: middlePart(
              ingreso: cuenta.Meses.firstWhere(
                      (v) => v.NMes == mes && v.Anno == Values().anno.value)
                  .Ingreso,
              context: context,
              onSelecMes: onSelecMes,
              mes: mes,
              onIngresoTap: onIngresoTap),
        ),
      ),
      Expanded(
        flex: 4,
        child: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: bottomPart(
              onGastosTap: onGastosTap,
              onPricesTap: onPricesTap,
              context: context),
        ),
      )
    ],
  );
}
