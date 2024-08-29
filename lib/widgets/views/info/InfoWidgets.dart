import 'package:cuentas_android/themes/hexColor.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:cuentas_android/widgets/views/info/IngresosGastosWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

Widget InfoHasData(
    {required Function(bool ingresos) onGastosSelected,
    required void Function(String) onNewMes,
    required Function(int) onChartTouched,
    required BuildContext context}) {
  return Padding(
    padding: const EdgeInsets.only(top: 25.0),
    child: SingleChildScrollView(
      child: Column(
        children: [
          GreetingsPart(),
          DatePart(onNewMes: onNewMes, context: context),
          TotalPart(),
          ChartPart(context: context)
        ],
      ),
    ),
  );
}

Widget InfoHasDataLand(
    {required Function(bool ingresos) onGastosSelected,
    required void Function(String) onNewMes,
    required Function(int) onChartTouched,
    required BuildContext context}) {
  return Padding(
    padding: EdgeInsets.only(top: 25),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GreetingsPart(),
          Row(
            children: [
              Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      DatePart(onNewMes: onNewMes, context: context),
                      totalPart()
                    ],
                  )),
              Expanded(
                flex: 5,
                child: ChartPart(context: context),
              )
            ],
          )
        ],
      ),
    ),
  );
}

Widget GreetingsPart() {
  return Row(
    children: [
      Expanded(
          flex: 4,
          child: SvgPicture.asset(
            height: 200,
            getImageUri(ImageUris.logosvg),
            color: HexColor(Values().cuentaRet.value!.color.value),
          )),
      Expanded(
        flex: 6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              GetGreeting(),
              style: TextStyle(fontSize: 25),
            ),
            Text('${Values().cuentaRet.value!.Nombre}!',
                style: TextStyle(fontSize: 25))
          ],
        ),
      )
    ],
  );
}

Widget DatePart(
    {required void Function(String) onNewMes, required BuildContext context}) {
  List<String> annos =
      Values().cuentaRet.value!.GetYears().map((e) => e.toString()).toList();

  annos = annos.isEmpty ? [DateTime.now().year.toString()] : annos;

  return Card(
    color: GetColor(ColorTypes.secondary, context),
    margin: EdgeInsets.all(15),
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
              Expanded(
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

Widget ChartPart({required BuildContext context}) {
  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 15),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: PieChart(PieChartData(
            sectionsSpace: 0,
            centerSpaceRadius: 40,
            sections: showingSections(context))),
      ),
    ),
  );
}

List<PieChartSectionData> showingSections(BuildContext context) {
  double ingresos = Values()
      .cuentaRet
      .value!
      .Meses
      .firstWhere((mes) =>
          mes.Anno.value == Values().anno.value &&
          mes.NMes.value == Values().mes.value)
      .GetIngresos();
  double gastos = Values()
      .cuentaRet
      .value!
      .Meses
      .firstWhere((mes) =>
          mes.Anno.value == Values().anno.value &&
          mes.NMes.value == Values().mes.value)
      .GetGastos();
  return [
    PieChartSectionData(
      color: GetColor(ColorTypes.primary, context),
      value: ingresos,
      title: '${ingresos.toStringAsFixed(2)}${Values().moneda.value}',
      titlePositionPercentageOffset: 1.5,
      badgeWidget: Text("Ingresos"),
      radius: 60,
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
    PieChartSectionData(
      color: GetColor(ColorTypes.errorButton, context),
      value: gastos,
      title: '${gastos.toStringAsFixed(2)}${Values().moneda.value}',
      titlePositionPercentageOffset: 1.5,
      radius: 60,
      badgeWidget: Text("Gastos"),
      titleStyle: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),
  ];
}

AppBar InfoAppBar(
    {required void Function() onSettings,
    required void Function() onBack,
    required BuildContext context}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back,
      ),
      onPressed: onBack,
    ),
    title: Text(style: GoogleFonts.pacifico(), 'Gastoscopio'),
    actions: [
      IconButton(onPressed: onSettings, icon: const Icon(Icons.settings))
    ],
  );
}

Widget InfoBottomNavigationBar(
    {required int selected,
    required Function(int) onChange,
    required Function onNew,
    required Function onUser,
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
          child: Icon(Icons.add),
        ),
      ),
      const NavigationDestination(
        label: 'Resumen',
        icon: Icon(Icons.donut_small_outlined),
        selectedIcon: Icon(Icons.donut_large),
      ),
      NavigationDestination(
        label: '',
        icon: GestureDetector(
          onTap: () => onUser(),
          child: SvgPicture.asset(
            getImageUri(ImageUris.logosvg),
            color: HexColor(Values().cuentaRet.value!.color.value),
            height: 50,
          ),
        ),
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
