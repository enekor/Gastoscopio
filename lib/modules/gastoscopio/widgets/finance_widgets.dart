import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';

class MonthYearSelector extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final List<int> availableYears;
  final List<int> availableMonths;
  final Function(int) onYearChanged;
  final Function(int) onMonthChanged;

  const MonthYearSelector({
    Key? key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.availableYears,
    required this.availableMonths,
    required this.onYearChanged,
    required this.onMonthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DropdownButton2<int>(
            value: selectedYear,
            items:
                availableYears.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  );
                }).toList(),
            onChanged: (value) => onYearChanged(value!),
            underline: const SizedBox(),
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: DropdownButton2<int>(
            value: selectedMonth,
            items:
                availableMonths.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(monthNames[month - 1]),
                  );
                }).toList(),
            onChanged: (value) => onMonthChanged(value!),
            underline: const SizedBox(),
            buttonStyleData: ButtonStyleData(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MovementCard extends StatelessWidget {
  final String description;
  final double amount;
  final bool isExpense;
  final String? category;
  final String moneda;

  const MovementCard({
    Key? key,
    required this.description,
    required this.amount,
    required this.isExpense,
    this.category,
    required this.moneda,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.only(right: 16, left: 16, top: 8),
        title: Text(
          description,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle:
            category != null
                ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    category!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                )
                : null,
        trailing: Text(
          '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)}${moneda}',
          style: TextStyle(
            color:
                isExpense
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class YearlyChart extends StatelessWidget {
  final int year;
  final String moneda;

  const YearlyChart({Key? key, required this.year, required this.moneda})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen anual $year',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Builder(
                builder: (context) {
                  final service = FinanceService.getInstance(
                    SqliteService().db.monthDao,
                    SqliteService().db.movementValueDao,
                    SqliteService().db.fixedMovementDao,
                  );
                  return AnimatedBuilder(
                    animation: service,
                    builder: (context, child) {
                      return FutureBuilder<List<Map<String, double>>>(
                        future: service.getYearlyData(year),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final yearlyData = snapshot.data!;
                          final monthNames = [
                            'Ene',
                            'Feb',
                            'Mar',
                            'Abr',
                            'May',
                            'Jun',
                            'Jul',
                            'Ago',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dic',
                          ];

                          return LineChart(
                            LineChartData(
                              gridData: FlGridData(
                                show: true,
                                drawHorizontalLine: true,
                                horizontalInterval: 100,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Theme.of(
                                      context,
                                    ).dividerColor.withOpacity(0.2),
                                    strokeWidth: 1,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        '${value.toInt()}${moneda}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value >= 0 &&
                                          value < monthNames.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            monthNames[value.toInt()],
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: true),
                              lineBarsData: [
                                // Línea de gastos (roja)
                                LineChartBarData(
                                  spots:
                                      yearlyData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['expenses']!,
                                        );
                                      }).toList(),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.error,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                              strokeWidth: 1,
                                              strokeColor: Theme.of(context)
                                                  .colorScheme
                                                  .error
                                                  .withOpacity(0.5),
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.1),
                                  ),
                                ),
                                // Línea de ingresos (verde)
                                LineChartBarData(
                                  spots:
                                      yearlyData.asMap().entries.map((e) {
                                        return FlSpot(
                                          e.key.toDouble(),
                                          e.value['incomes']!,
                                        );
                                      }).toList(),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.green,
                                              strokeWidth: 1,
                                              strokeColor: Colors.green
                                                  .withOpacity(0.5),
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: Theme.of(context).colorScheme.error,
                  label: 'Gastos',
                ),
                const SizedBox(width: 16),
                _LegendItem(color: Colors.green, label: 'Ingresos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
