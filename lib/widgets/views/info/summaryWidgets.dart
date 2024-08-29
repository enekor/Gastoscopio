import 'dart:math';

import 'package:cuentas_android/models/ChartValues.dart';
import 'package:cuentas_android/models/Gasto.dart';
import 'package:cuentas_android/models/Mes.dart';
import 'package:cuentas_android/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:cuentas_android/widgets/ItemView.dart';
import 'package:cuentas_android/widgets/indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget summaryHasData(BuildContext context, {bool isLandscape = false}) {
  Values().summaryMes.value = Values().nombresMes[DateTime.now().month - 1];
  return Obx(
    () => Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            DatePart(context),
            pagePart(context),
            Values().summaryShowChart.value
                ? ChartPart(
                    Values().cuentaRet.value!.Meses.firstWhere((m) =>
                        m.Anno.value == Values().summaryAnno.value &&
                        m.NMes.value == Values().summaryMes.value),
                    context,
                    isLandscape)
                : infoPart(
                    Values().cuentaRet.value!.Meses.firstWhere((m) =>
                        m.Anno.value == Values().summaryAnno.value &&
                        m.NMes.value == Values().summaryMes.value),
                    context,
                    isLandscape),
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
    margin: EdgeInsets.all(15),
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

Widget pagePart(BuildContext context) {
  return Obx(() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: CardButton(
              onPressed: () => Values().summaryShowChart.value = false,
              child: const Row(
                children: [Icon(Icons.summarize_rounded), Text('General')],
              ),
              context: context,
              color: Values().summaryShowChart.value
                  ? GetColor(ColorTypes.background, context)
                  : GetColor(ColorTypes.secondary, context)),
        ),
        Expanded(
          flex: 5,
          child: CardButton(
              onPressed: () => Values().summaryShowChart.value = true,
              child: const Row(
                children: [Icon(Icons.pie_chart_rounded), Text('Gráfico')],
              ),
              context: context,
              color: Values().summaryShowChart.value
                  ? GetColor(ColorTypes.secondary, context)
                  : GetColor(ColorTypes.background, context)),
        ),
      ],
    );
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
          margin: EdgeInsets.all(15),
          color: GetColor(ColorTypes.secondary, context),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("Total"),
                    Text(
                        '${mes.GetTotal().toStringAsFixed(2)}${Values().moneda.value}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text("Ingreso base"),
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
                          child: Text(
                              '${valor.valor.value < 0 ? (-1 * valor.valor.value).toStringAsFixed(2) : valor.valor.value.toStringAsFixed(2)}${Values().moneda.value}'),
                        ),
                      )
                    ],
                  ))
              .toList(),
        ),
        Divider()
      ],
    ),
  );
}

Widget ChartPart(Mes mes, BuildContext context, bool isLandscape) {
  return Obx(
    () {
      List<Chartvalues> valores = Values()
          .cuentaRet
          .value!
          .Meses
          .firstWhere((m) =>
              m.Anno.value == Values().summaryAnno.value &&
              m.NMes.value == Values().summaryMes.value)
          .GetForChart();
      return isLandscape
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 15),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: PieChart(PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections: createPieChartSections(valores, context))),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Card(
                    color: GetColor(ColorTypes.primary, context),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: GetIndicators(valores)),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 15),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: PieChart(PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 40,
                        sections: createPieChartSections(valores, context))),
                  ),
                ),
                Card(
                  color: GetColor(ColorTypes.primary, context),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: GetIndicators(valores)),
                  ),
                ),
              ],
            );
    },
  );
}

List<PieChartSectionData> createPieChartSections(
    List<Chartvalues> data, BuildContext context) {
  return data.map((entry) {
    double valor = entry.valor;
    return PieChartSectionData(
        color: entry.color,
        value: valor,
        title: '${valor.toStringAsFixed(2)}${Values().moneda.value}',
        titlePositionPercentageOffset: 0.5,
        radius: 60,
        showTitle: false,
        badgePositionPercentageOffset: 1.5);
  }).toList();
}

Color RandColor() {
  return Color.fromARGB(
      255, Random().nextInt(255), Random().nextInt(255), Random().nextInt(255));
}

List<Widget> GetIndicators(List<Chartvalues> data) {
  return data
      .map((v) => Column(
            children: [
              Indicator(
                  color: v.color,
                  nombre: v.nombre,
                  valor:
                      '${v.valor.toStringAsFixed(2)}${Values().moneda.value}',
                  isSquare: true),
              const SizedBox(
                height: 4,
              ),
            ],
          ))
      .toList();
}
