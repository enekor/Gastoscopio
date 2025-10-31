import 'package:cashly/data/models/saves.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SavesWidgets {
  static Widget GoalProgressCard({
    required BuildContext context,
    required double currentAmount,
    required double goalAmount,
    required VoidCallback onEditGoal,
  }) {
    final progress = (currentAmount / goalAmount).clamp(0.0, 1.0);
    final percentageComplete = (progress * 100).toStringAsFixed(1);
    final remaining = goalAmount - currentAmount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Savings Goal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: onEditGoal,
                  tooltip: 'Edit Goal',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${currentAmount.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${goalAmount.toStringAsFixed(2)}€',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentAmount >= goalAmount
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentageComplete% Complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (remaining > 0)
                  Text(
                    '${remaining.toStringAsFixed(2)}€ to go',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Goal Achieved! 🎉',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMetricRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  static Widget KeyMetricsCard({
    required BuildContext context,
    required Future<List<dynamic>> Function() metricsFunction,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Key Metrics',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<dynamic>>(
              future: metricsFunction(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final average = snapshot.data?[0] as double? ?? 0.0;
                final bestMonth = snapshot.data?[1] as Saves?;
                final worstMonth = snapshot.data?[2] as Saves?;

                return Column(
                  children: [
                    _buildMetricRow(
                      context,
                      Icons.trending_up,
                      'Monthly Average',
                      '${average.toStringAsFixed(2)}€',
                    ),
                    if (bestMonth != null) ...[
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        context,
                        Icons.emoji_events,
                        'Best Month',
                        '${bestMonth.amount.toStringAsFixed(2)}€',
                        subtitle:
                            '${bestMonth.date.month}/${bestMonth.date.year}',
                      ),
                    ],
                    if (worstMonth != null) ...[
                      const SizedBox(height: 12),
                      _buildMetricRow(
                        context,
                        Icons.trending_down,
                        'Worst Month',
                        '${worstMonth.amount.toStringAsFixed(2)}€',
                        subtitle:
                            '${worstMonth.date.month}/${worstMonth.date.year}',
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget ViewSelectionCard({
    required BuildContext context,
    required bool viewByYear,
    required Function(bool) onViewChanged,
    required int currentYear,
    required Future<List<int>> Function() yearsFunction,
    required Function(int) onYearChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  viewByYear ? Icons.calendar_today : Icons.calendar_month,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    viewByYear ? 'Yearly View' : 'Monthly View',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(value: viewByYear, onChanged: onViewChanged),
              ],
            ),
            if (viewByYear) ...[
              const SizedBox(height: 16),
              FutureBuilder<List<int>>(
                future: yearsFunction(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final years = snapshot.data ?? [];
                  if (years.isEmpty) {
                    return const Text('No data available');
                  }

                  return DropdownButton<int>(
                    value: years.contains(currentYear)
                        ? currentYear
                        : years.first,
                    isExpanded: true,
                    items: years
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (selectedYear) {
                      if (selectedYear != null) {
                        onYearChanged(selectedYear);
                      }
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget OverviewCard({
    required BuildContext context,
    required bool isLoading,
    required List<Saves> saves,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Savings Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Total: ${saves.fold<double>(0, (sum, save) => sum + save.amount).toStringAsFixed(2)}€',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearChart(saves),
                ],
              ),
      ),
    );
  }

  static Widget DeleteInitialSaveButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.delete_outline, size: 20),
      label: const Text('Delete Initial Save'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

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
