import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';

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

  const MovementCard({
    Key? key,
    required this.description,
    required this.amount,
    required this.isExpense,
    this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          '${isExpense ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
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

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final double radius;

  const CategoryPieChart({Key? key, required this.data, this.radius = 100})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    int colorIndex = 0;
    double total = data.values.fold(0, (sum, value) => sum + value);

    data.forEach((category, amount) {
      final percentage = (amount / total * 100).roundToDouble();
      sections.add(
        PieChartSectionData(
          color: colors[colorIndex % colors.length],
          value: amount,
          title: '$category\n$percentage%',
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return SizedBox(
      height: radius * 2.2,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 0,
        ),
      ),
    );
  }
}

class DailyTotalChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> data;

  const DailyTotalChart({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final spots =
        data.map((entry) {
          return FlSpot(entry.key.day.toDouble(), entry.value);
        }).toList();

    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
