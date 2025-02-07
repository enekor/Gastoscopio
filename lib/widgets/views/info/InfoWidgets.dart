import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/charts.dart';
import 'package:cuentas_android/widgets/views/info/IngresosGastosWidgets.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget InfoHasData(
    {required Function(bool ingresos) onGastosSelected,
    required void Function(String) onNewMes,
    required Function onUser,
    required Function onSummary,
    required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(top: kToolbarHeight),
    child: SingleChildScrollView(
      child: Obx(
        () => Column(
          children: [
            GreetingsPart(onUser),
            LastInteractionsPart(context: context),
            DatePart(onNewMes: onNewMes, context: context),
            Values().cuentaRet.value!.Meses.value.firstWhereOrNull((m) =>
                        m.Anno.value == Values().anno.value &&
                        m.NMes.value == Values().mes.value) !=
                    null
                ? Column(children: [
                    TotalPart(),
                    ChartPart(context: context, onSummary: onSummary)
                  ])
                : Center(
                    child: TextButton(
                        onPressed: () => onNewMes(Values().mes.value),
                        child: Text(
                            "No hay datos para el mes ${Values().mes.value} del ${Values().anno.value}"))),
          ],
        ),
      ),
    ),
  );
}

Widget InfoHasDataLand(
    {required Function(bool ingresos) onGastosSelected,
    required void Function(String) onNewMes,
    required Function onUser,
    required Function onSummary,
    required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(top: 25),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GreetingsPart(onUser),
          Row(
            children: [
              Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      LastInteractionsPart(context: context),
                      DatePart(onNewMes: onNewMes, context: context),
                      totalPart()
                    ],
                  )),
              Expanded(
                flex: 5,
                child: ChartPart(context: context, onSummary: onSummary),
              )
            ],
          )
        ],
      ),
    ),
  );
}

Widget GreetingsPart(Function onUser) {
  return Padding(
    padding: const EdgeInsets.only(top: 30.0),
    child: Row(
      children: [
        Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: () => onUser(),
              child: SvgPicture.asset(
                height: 200,
                getImageUri(ImageUris.logosvg),
                color: HexColor(Values().cuentaRet.value!.color.value),
              ),
            )),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                GetGreeting(),
                style: const TextStyle(fontSize: 25),
              ),
              Text('${Values().cuentaRet.value!.Nombre}!',
                  style: const TextStyle(fontSize: 25))
            ],
          ),
        )
      ],
    ),
  );
}

Widget LastInteractionsPart({required BuildContext context}) {
  List<Gasto> lastInteractions =
      Values().cuentaRet.value!.GetLastInteractions();

  return Card(
      color: GetColor(ColorTypes.background, context).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(
          color: GetColor(ColorTypes.primary, context), // Borde rojo
          width: 2.0,
        ),
      ),
      margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          children: [
            const Text(
              'Ultimos movimientos',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(
              height: 12,
            ),
            Column(
              children: lastInteractions.isNotEmpty
                  ? lastInteractions
                      .map((gasto) => LastInteractionGastoView(gasto: gasto))
                      .toList()
                  : [
                      const Center(
                        child: Text('No hay nuevos movimientos'),
                      )
                    ],
            ),
          ],
        ),
      ));
}

Widget DatePart(
    {required void Function(String) onNewMes, required BuildContext context}) {
  List<String> annos =
      Values().cuentaRet.value!.GetYears().map((e) => e.toString()).toList();

  annos = annos.isEmpty ? [DateTime.now().year.toString()] : annos;

  return Card(
    color: GetColor(ColorTypes.secondary, context),
    margin: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text("Año"),
              ),
              Expanded(
                flex: 7,
                child: Obx(
                  () => ItemSelector(
                      onSelect: (anno) =>
                          Values().anno.value = int.parse(anno!),
                      items: annos,
                      defaultValue: Values().anno.value.toString()),
                ),
              )
            ],
          ),
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text("Mes"),
              ),
              Expanded(
                flex: 7,
                child: Obx(
                  () => ItemSelector(
                      onSelect: (mes) => onNewMes(mes!),
                      items: Values().nombresMes,
                      defaultValue: Values().mes.value),
                ),
              )
            ],
          )
        ],
      ),
    ),
  );
}

Widget TotalPart() {
  return Obx(
    () => Center(
      child: Row(
        children: [
          const Expanded(
            flex: 5,
            child: Text("Total",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 5,
            child: Text(
                '${Values().cuentaRet.value!.GetTotal(Values().anno.value, Values().mes.value).toStringAsFixed(2)}${Values().moneda.value}',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    ),
  );
}

RxBool _isIngresoChecked = false.obs;
Widget ChartPart({required BuildContext context, required Function onSummary}) {
  return Obx(
    () {
      Map<String, double> total = Values()
          .cuentaRet
          .value!
          .GetTotalChart(Values().anno.value, Values().mes.value);
      Map<String, double> gastosIngresos = Values()
          .cuentaRet
          .value!
          .GetIngresosGastosChart(Values().anno.value, Values().mes.value,
              !_isIngresoChecked.value);
      List<double> ingresos = Values()
          .cuentaRet
          .value!
          .GetIngresosTotalesChart(Values().anno.value);
      List<double> gastos =
          Values().cuentaRet.value!.GetGastosTotalesChart(Values().anno.value);
      List<String> meses =
          Values().cuentaRet.value!.GetMeses(Values().anno.value);

      PageController pController = PageController();

      return Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => pController.previousPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeIn),
                      icon: const Icon(Icons.arrow_left)),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: PageView(
                      controller: pController,
                      children: [
                        Container(child: PieChartGenerator(dataMap: total)),
                        Container(
                            child: Column(
                          children: [
                            ChangingPill(
                                text1: 'Gastos',
                                text2: 'Ingresos',
                                selected: _isIngresoChecked.value ? 1 : 0,
                                onClick: () => _isIngresoChecked.value =
                                    !_isIngresoChecked.value,
                                context: context),
                            const SizedBox(
                              height: 20,
                            ),
                            PieChartGenerator(
                              dataMap: gastosIngresos,
                            ),
                          ],
                        ))
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => pController.nextPage(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeIn),
                      icon: const Icon(Icons.arrow_right))
                ],
              ),
              LineChartGenerator(
                  expenses: gastos, incomes: ingresos, months: meses)
            ],
          ));
    },
  );
}

AppBar InfoAppBar(
    {required void Function() onSettings,
    required void Function() onBack,
    required void Function() onComparar,
    required BuildContext context}) {
  return AppBar(
    toolbarHeight: kToolbarHeight / 1.6, // Adjust the divisor as needed
    centerTitle: true,
    backgroundColor: Colors.transparent,
    leading: (Values().selectedScreen != 0)
        ? IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: onBack,
          )
        : null,
    title: Text(style: GoogleFonts.pacifico(fontSize: 20), 'Gastoscopio'),
    actions: [
      IconButton(onPressed: onSettings, icon: const Icon(Icons.settings)),
      IconButton(
          onPressed: onComparar, icon: const Icon(Icons.shopping_bag_rounded))
    ],
  );
}

Widget InfoBottomNavigationBar(
    {required int selected,
    required Function(int) onChange,
    required Function onNew,
    required BuildContext context}) {
  return NavigationBar(
    elevation: 3,
    selectedIndex: selected,
    onDestinationSelected: onChange,
    backgroundColor: GetColor(ColorTypes.background, context),
    destinations: [
      const NavigationDestination(
          label: 'Home',
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_filled)),
      const NavigationDestination(
        label: 'Info',
        icon: Icon(Icons.monetization_on_outlined),
        selectedIcon: Icon(Icons.monetization_on),
      ),
      NavigationDestination(
        label: '',
        icon: FloatingActionButton(
          backgroundColor: GetColor(ColorTypes.secondary, context),
          onPressed: () => onNew(),
          child: const Icon(Icons.add),
        ),
      ),
      const NavigationDestination(
        label: 'Resumen',
        icon: Icon(Icons.donut_small_outlined),
        selectedIcon: Icon(Icons.donut_large),
      ),
      const NavigationDestination(
        label: 'Presupuesto',
        icon: Icon(Icons.calculate_outlined),
        selectedIcon: Icon(Icons.calculate),
      ),
    ],
  );
}

String GetGreeting() {
  DateTime now = DateTime.now();
  int hour = now.hour;

  // Determinar el período del día
  if (hour >= 6 && hour < 14) {
    return '🌄¡Buenos días, ';
  } else if (hour >= 14 && hour < 20) {
    return '☀️¡Buenas tardes, ';
  } else {
    return '🌛¡Buenas noches, ';
  }
}
