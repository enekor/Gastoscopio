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
          child: Text(
              style: TextStyle(
                fontSize: 130,
              ),
              userName),
        ),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  style: TextStyle(
                    fontSize: 50,
                  ),
                  textAlign: TextAlign.center,
                  "${Values().GetMes()}    ${currentMounth.toStringAsFixed(2)}${Values().moneda.value}"),
              Text(
                  style: TextStyle(
                    fontSize: 50,
                  ),
                  textAlign: TextAlign.center,
                  "${Values().anno.value.toString()}    ${currentYear.toStringAsFixed(2)}${Values().moneda.value}"),
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
        flex: 3,
        child: SizedBox(
          child: Padding(
            padding: const EdgeInsets.only(left: 10, top: 15, bottom: 15),
            child: GestureDetector(
              onTap: () => onIngresoTap(),
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Ingresos",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
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
            child: const Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(25),
                              bottomRight: Radius.circular(25))),
                      child: Center(
                        child: Text(
                            style: TextStyle(fontWeight: FontWeight.bold),
                            "Gestión de gastos"),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Icon(
                    color: Colors.black,
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
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Icon(
                    color: Colors.black,
                    Icons.shopping_cart_rounded,
                    size: 50,
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(25),
                              bottomLeft: Radius.circular(25))),
                      child: Center(
                        child: Text(
                            style: TextStyle(fontWeight: FontWeight.bold),
                            "Comparación de precios"),
                      ),
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
        flex: 3,
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
        flex: 5,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 50),
          child: bottomPart(
              onGastosTap: onGastosTap,
              onPricesTap: onPricesTap,
              context: context),
        ),
      )
    ],
  );
}

Widget bodyLand(
    {required double ingreso,
    required String mes,
    required Function onPricesTap,
    required Function(String) onSelecMes,
    required Function onIngresoTap,
    required Function onGastosTap,
    required BuildContext context,
    required Cuenta cuenta,
    required Function onDeudasTap,
    required Function onRecurrentesTap,
    required Function onSummaryTap,
    required Function onSettingsTap}) {
  return Row(
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
                  onPressed: () => onSettingsTap(),
                  icon: const Icon(Icons.settings)),
              IconButton(
                  onPressed: () => onSummaryTap(),
                  icon: const Icon(Icons.summarize)),
              IconButton(
                  onPressed: () => onRecurrentesTap(),
                  icon: const Icon(Icons.calendar_month)),
              IconButton(
                  onPressed: () => onDeudasTap(),
                  icon: const Icon(Icons.money_off_rounded)),
            ],
          ),
        ),
      ),
      Expanded(
        flex: 6,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 140, bottom: 140),
                child: middlePart(
                    ingreso: ingreso,
                    context: context,
                    onSelecMes: onSelecMes,
                    mes: mes,
                    onIngresoTap: onIngresoTap),
              ),
            ),
            Expanded(
              child: bottomPart(
                  onGastosTap: onGastosTap,
                  onPricesTap: onPricesTap,
                  context: context),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 6,
        child: Container(
            margin: EdgeInsets.only(left: 10),
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
      )
    ],
  );
}
