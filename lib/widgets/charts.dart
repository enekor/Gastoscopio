import 'dart:math';

import 'package:cuentas_android/models/presupuesto.dart';
import 'package:cuentas_android/utils/utils.dart';
import 'package:cuentas_android/values.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

List<Color> colors = const [
  Color(0xffa8dadc), // Azul claro
  Color(0xffe63946), // Rojo
  Color(0xff457b9d), // Azul
  Color(0xff1d3557), // Azul oscuro
  Color(0xff2a9d8f), // Verde
  Color(0xffe9c46a), // Amarillo
  Color(0xfff4a261), // Naranja
  Color(0xffe76f51), // Rojo anaranjado
  Color(0xff264653), // Verde oscuro
  Color(0xff6a4c93), // Púrpura
  Color(0xfff3722c), // Naranja brillante
  Color(0xff90be6d), // Verde claro
  Color(0xff43aa8b), // Verde medio
  Color(0xff577590), // Azul grisáceo
  Color(0xffff6f61), // Coral
  Color(0xffd4a5a5), // Rosa pálido
  Color(0xffbc6c25), // Marrón
  Color(0xff8d99ae), // Gris azulado
  Color(0xffffb703), // Amarillo brillante
  Color(0xff023047), // Azul muy oscuro
];

class LineChartGenerator extends StatefulWidget {
  final List<double> expenses;
  final List<double> incomes;
  final List<String> months;

  const LineChartGenerator(
      {super.key,
      required this.expenses,
      required this.incomes,
      required this.months});

  @override
  State<LineChartGenerator> createState() => _LineChartGeneratorState();
}

class _LineChartGeneratorState extends State<LineChartGenerator> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  String formatNumber(double value) {
    return '${value.toStringAsFixed(2)} ${Values().moneda.value}';
  }

  double getMaxY() {
    return max(widget.expenses.reduce(max), widget.incomes.reduce(max));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                                title: Text("Información de la gráfica"),
                                content: Text(
                                    "La gráfica de abajo representa los ahorros y gastos del año seleccionado. El color azul representa los ahorros y el rojo los gastos."),
                              ));
                    },
                    icon: const Icon(Icons.help)),
              ],
            )),
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.expenses
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: ColorTween(
                            begin: gradientColors[0], end: gradientColors[1])
                        .lerp(0.2)!,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: gradientColors[0],
                    ),
                  ),
                  LineChartBarData(
                    spots: widget.incomes
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(
                      show: false,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                ],
                minY: 0,
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: bottomTitleWidgets,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: getMaxY() / 5,
                      getTitlesWidget: leftTitleWidgets,
                      reservedSize: 42,
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Color(0xff4e4965), width: 4),
                    left: BorderSide(color: Color(0xff4e4965), width: 4),
                    right: BorderSide(color: Colors.transparent),
                    top: BorderSide(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    TextStyle style = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 9,
    );

    String text = formatNumber(value);
    return Text(text, style: style, textAlign: TextAlign.left);
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    TextStyle style = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 9,
    );

    int index = value.toInt();
    if (index >= 0 && index < widget.months.length) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        angle: 24.3,
        space: 10, // Aumenta este valor para más separación
        child: Text(widget.months[index].toString(), style: style),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class PieChartGenerator extends StatefulWidget {
  final Map<String, double> dataMap;

  const PieChartGenerator({
    super.key,
    required this.dataMap,
  });

  @override
  State<StatefulWidget> createState() => PieChart2State();
}

class PieChart2State extends State<PieChartGenerator> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          sectionsSpace: 0,
          centerSpaceRadius: 40,
          sections: showingSections(widget.dataMap),
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections(Map<String, double> dataMap) {
    return List.generate(dataMap.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 16.0 : 9.0;
      final radius = isTouched ? 60.0 : 50.0;
      var value = dataMap.values.elementAt(i);
      if (value < 0) {
        value *= -1;
      }
      var key = dataMap.keys.elementAt(i);

      print('Value for $key: $value');

      return PieChartSectionData(
          color: colors[i >= colors.length ? colors.length - i : i],
          value: value,
          title: '$key \n ${value.toStringAsFixed(2)}${Values().moneda.value}',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
          titlePositionPercentageOffset: 1.5);
    });
  }
}

class BudgetPieChart extends StatelessWidget {
  final List<Presupuesto> budgetItems;
  const BudgetPieChart({super.key, required this.budgetItems});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: budgetItems.asMap().entries.map((entry) {
          int index = entry.key;
          Presupuesto item = entry.value;
          return PieChartSectionData(
            color: colors[
                index % colors.length], // Asigna un color según la posición
            value: item.percentage.toDouble(),
            title: item.description,
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
      ),
    );
  }
}
