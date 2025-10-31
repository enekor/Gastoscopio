import 'package:cashly/data/models/saves.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SavesWidgets {
  static Widget AddSaveButton({
    required BuildContext context,
    required Function(double) onPressed,
  }) {
    return FilledButton.icon(
      onPressed: () => _showAddSaveFormPopUp(onPressed, context),
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Add Initial Save'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  static void _showAddSaveFormPopUp(
    Function(double) onPressed,
    BuildContext context,
  ) {
    final _formKey = GlobalKey<FormState>();
    final _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Add Initial Save'),
            ],
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter your initial savings amount to start tracking your financial progress.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    hintText: 'Enter amount...',
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text);
                  onPressed(amount);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Save'),
            ),
          ],
        );
      },
    );
  }

  static Widget LinearChart(List<Saves> values) {
    if (values.isEmpty) {
      return Container(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    List<Saves> sortedValues = List.from(values);
    sortedValues.sort((a, b) {
      if (a.isInitialValue && !b.isInitialValue) return -1;
      if (!a.isInitialValue && b.isInitialValue) return 1;
      return a.date.compareTo(b.date);
    });

    List<FlSpot> spots = [];
    for (int i = 0; i < sortedValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedValues[i].amount));
    }

    double minY = sortedValues
        .map((e) => e.amount)
        .reduce((a, b) => a < b ? a : b);
    double maxY = sortedValues
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    double range = maxY - minY;
    if (range < 1) {
      double avg = (maxY + minY) / 2;
      minY = avg - 0.5;
      maxY = avg + 0.5;
      range = 1.0;
    } else {
      minY = minY - (range * 0.1);
      maxY = maxY + (range * 0.1);
      range = maxY - minY;
    }

    double horizontalInterval = range / 5;
    if (horizontalInterval < 0.1) horizontalInterval = 0.1;

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: horizontalInterval,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedValues.length) {
                    final text = sortedValues[value.toInt()].isInitialValue
                        ? 'Initial'
                        : '${sortedValues[value.toInt()].date.month}/${sortedValues[value.toInt()].date.year}';
                    return Transform.rotate(
                      angle: -0.5,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: (maxY - minY) / 5,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          minX: 0,
          maxX: (sortedValues.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: sortedValues[index].isInitialValue
                        ? Colors.green
                        : Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
