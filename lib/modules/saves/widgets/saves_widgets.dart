import 'package:cashly/data/models/saves.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SavesWidgets {
  static Widget AddSaveButton({
    required BuildContext context,
    required Function(double) onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _showAddSaveFormPopUp(onPressed, context),
      icon: Icon(Icons.add),
      label: Text('Add Initial Save'),
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
          title: Text('Add Initial Save'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Amount'),
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
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text);
                  onPressed(amount);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Add'),
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

    // Ordenar los datos: primero el que tiene isInitialValue, luego el resto por fecha
    List<Saves> sortedValues = List.from(values);
    sortedValues.sort((a, b) {
      // Si uno es initialValue y el otro no, el initialValue va primero
      if (a.isInitialValue && !b.isInitialValue) return -1;
      if (!a.isInitialValue && b.isInitialValue) return 1;

      // Si ambos son initialValue o ambos no lo son, ordenar por fecha
      return a.date.compareTo(b.date);
    });

    // Crear los puntos para el gráfico
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedValues.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedValues[i].amount));
    }

    // Calcular el rango de valores para el eje Y
    double minY = sortedValues
        .map((e) => e.amount)
        .reduce((a, b) => a < b ? a : b);
    double maxY = sortedValues
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    // Agregar un poco de margen al rango
    double range = maxY - minY;
    minY = minY - (range * 0.1);
    maxY = maxY + (range * 0.1);

    return Container(
      height: 200,
      padding: EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxY - minY) / 5,
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
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < sortedValues.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        sortedValues[value.toInt()].isInitialValue
                            ? 'Initial'
                            : '${sortedValues[value.toInt()].date.year}/${sortedValues[value.toInt()].date.month}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    );
                  }
                  return Text('');
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
