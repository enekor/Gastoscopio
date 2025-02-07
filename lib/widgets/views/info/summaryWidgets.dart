import 'dart:math';

import 'package:cuentas_android/models/ChartValues.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/widgetsBasicos.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget summaryHasData(BuildContext context, {bool isLandscape = false}) {
  if (Values()
      .cuentaRet
      .value!
      .Meses
      .where((m) =>
          m.Anno.value == Values().summaryAnno.value &&
          m.NMes.value == Values().summaryMes.value)
      .isEmpty) {
    Values()
        .cuentaRet
        .value!
        .NewMes(Values().summaryAnno.value, Values().summaryMes.value);
  }

  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(top: kToolbarHeight * 2),
      child: SingleChildScrollView(
        child: Column(
          children: [
            DatePart(context),
            Values().cuentaRet.value!.Meses.firstWhereOrNull((v) =>
                        v.Anno.value == Values().summaryAnno.value &&
                        v.NMes.value == Values().summaryMes.value) !=
                    null
                ? PagePart(context, isLandscape)
                : Center(
                    child: Text(
                        'No hay datos para ${Values().summaryMes.value} de ${Values().summaryAnno.value}'),
                  ),
          ],
        ),
      ),
    ),
  );
}

Widget DatePart(BuildContext context) {
  List<String> annos =
      Values().cuentaRet.value!.GetYears().map((e) => e.toString()).toList();

  annos = annos.isEmpty ? [DateTime.now().year.toString()] : annos;

  return Card(
    color: GetColor(ColorTypes.secondary, context),
    margin: const EdgeInsets.all(15),
    child: Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Obx(
              () => ItemSelector(
                  onSelect: (anno) =>
                      Values().summaryAnno.value = int.parse(anno!),
                  items: annos,
                  defaultValue: Values().summaryAnno.value.toString()),
            ),
          ),
          Expanded(
            flex: 5,
            child: Obx(() => ItemSelector(
                  onSelect: (mes) => Values().summaryMes.value = mes!,
                  items: Values().nombresMes,
                  defaultValue: Values().summaryMes.value,
                )),
          )
        ],
      ),
    ),
  );
}

Widget PagePart(BuildContext context, bool isLandscape) {
  return Obx(() {
    PageController pController = PageController();
    Rx<Mes> mes = Values()
        .cuentaRet
        .value!
        .Meses
        .firstWhere((m) =>
            m.Anno.value == Values().summaryAnno.value &&
            m.NMes.value == Values().summaryMes.value)
        .obs;
    RxList<Chartvalues> chartValues = mes.value.GetForChart().obs;

    return SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: PageView(
            controller: pController,
            children: [
              infoPart(mes.value, context, isLandscape),
              PieChartPart(chartValues.value),
              ColumnChartPart(chartValues.value),
            ],
          ),
        ));
  });
}

Widget infoPart(Mes mes, BuildContext context, bool isLandscape) {
  return Card(
    margin: EdgeInsets.only(
        left: isLandscape ? 150 : 10,
        right: isLandscape ? 150 : 10,
        top: 10,
        bottom: 10),
    color: GetColor(ColorTypes.primary, context),
    child: Column(
      children: [
        Card(
          margin: const EdgeInsets.all(15),
          color: GetColor(ColorTypes.secondary, context),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text("Total"),
                    Text(
                        '${mes.GetTotal().toStringAsFixed(2)}${Values().moneda.value}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text("Ingreso base"),
                    Text(
                        '${mes.Ingreso.toStringAsFixed(2)}${Values().moneda.value}'),
                  ],
                ),
              ],
            ),
          ),
        ),
        showValues(
          mes.Gastos.value.where((gasto) => gasto.valor.value < 0).toList(),
          "Ingresos",
        ),
        showValues(
          mes.Gastos.value.where((gasto) => gasto.valor.value > 0).toList(),
          "Gastos",
        ),
        showValues(mes.Extras.value, "Gastos extra"),
      ],
    ),
  );
}

Widget showValues(List<Gasto> gastos, String nombre) {
  return Padding(
    padding: const EdgeInsets.only(top: 15.0),
    child: Column(
      children: [
        Center(
            child: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        )),
        Column(
          children: gastos
              .map((valor) => Row(
                    children: [
                      Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: Text(valor.nombre.value),
                          )),
                      Expanded(
                        flex: 5,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text(valor.nombre.value),
                        ),
                      )
                    ],
                  ))
              .toList(),
        ),
        const Divider()
      ],
    ),
  );
}

Widget PieChartPart(List<Chartvalues> chartValues) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: _PieChart(chartValues
              .where((v) => v.nombre.startsWith("Gastos:"))
              .toList()),
        ),
        const SizedBox(height: 20),
        AnimatedCard(
            text: "Datos de la gráfica",
            icon: const Icon(Icons.pie_chart_rounded),
            children: chartValues.map((item) {
              return Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(item.nombre),
                  const SizedBox(width: 8),
                  Text(
                      '${item.valor.toStringAsFixed(2)} ${Values().moneda.value}'),
                ],
              );
            }).toList())
      ],
    ),
  );
}

Widget _PieChart(List<Chartvalues> chartValues) {
  return PieChart(
    PieChartData(
      sectionsSpace: 0,
      centerSpaceRadius: 40,
      sections: chartValues.map((item) {
        return PieChartSectionData(
          color: item.color,
          value: item.valor.abs(),
          title: '',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
    ),
  );
}

Widget ColumnChartPart(List<Chartvalues> chartValues) {
  double totalGastos = chartValues
      .where((v) => v.nombre.startsWith("Gastos:"))
      .fold(0, (sum, item) => sum + item.valor);
  double totalIngresos = chartValues
      .where((v) => !v.nombre.startsWith("Gastos:"))
      .fold(0, (sum, item) => sum + item.valor);
  return AspectRatio(
    aspectRatio: 1.5,
    child: _ColumnChart(totalGastos, totalIngresos),
  );
}

Widget _ColumnChart(double totalGastos, double totalIngresos) {
  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.center,
      maxY: max(totalGastos, totalIngresos),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              switch (value.toInt()) {
                case 0:
                  return const Text('Gastos');
                case 1:
                  return const Text('Ingresos');
                default:
                  return const Text('');
              }
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                  '${value.toStringAsFixed(0)} ${Values().moneda.value}');
            },
          ),
        ),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      groupsSpace: 45,
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: totalGastos,
              color: Colors.red,
              width: 30,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: totalIngresos,
              color: Colors.green,
              width: 30,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
