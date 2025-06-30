import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTabContent extends StatelessWidget {
  final List<MovementValue> movements;

  const SummaryTabContent({Key? key, required this.movements})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) {
      return _buildEmptyState(context);
    }

    final expenses = movements.where((m) => m.isExpense).toList();
    final categoryData = _calculateCategoryPercentages(expenses);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyOverview(context, movements),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).categoryDistribution,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CategoryProgressChart(categoryData: categoryData),
            const SizedBox(height: 24),
            _buildDailySpendingChart(context, expenses),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.noDataForMonth('', 0),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            localizations.dataWillAppear,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateCategoryPercentages(
    List<MovementValue> expenses,
  ) {
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, mov) => sum + mov.amount,
    );
    final categoryData = <String, double>{};

    if (totalExpenses > 0) {
      for (final movement in expenses) {
        if (movement.category != null) {
          final category = movement.category ?? '';
          categoryData[category] =
              (categoryData[category] ?? 0) + movement.amount;
        }
      }

      categoryData.forEach((key, value) {
        categoryData[key] = (value / totalExpenses) * 100;
      });
    }

    return categoryData;
  }

  Widget _buildMonthlyOverview(
    BuildContext context,
    List<MovementValue> movements,
  ) {
    final expenses = movements
        .where((m) => m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final incomes = movements
        .where((m) => !m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final balance = incomes - expenses;
    final expenseRatio = expenses > 0 ? (expenses / incomes) * 100 : 0;
    final localizations = AppLocalizations.of(context);

    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.monthlySummary,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildOverviewRow(
              context,
              localizations.incomes,
              incomes,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildOverviewRow(
              context,
              localizations.expenses,
              expenses,
              Colors.red,
            ),
            const Divider(),
            _buildOverviewRow(
              context,
              localizations.balance,
              balance,
              balance >= 0 ? Colors.green : Colors.red,
            ),
            if (incomes > 0) ...[
              const SizedBox(height: 16),
              Text(
                localizations.youSpentPercent(
                  int.parse(expenseRatio.toStringAsFixed(1)),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: expenseRatio / 100,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  expenseRatio > 100
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '${amount.toStringAsFixed(2)}€',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDailySpendingChart(
    BuildContext context,
    List<MovementValue> expenses,
  ) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final dailyTotals = <int, double>{};
    for (var movement in expenses) {
      dailyTotals[movement.day] =
          (dailyTotals[movement.day] ?? 0) + movement.amount;
    }

    final spots =
        dailyTotals.entries
            .map((e) => FlSpot(e.key.toDouble(), e.value))
            .toList()
          ..sort((a, b) => a.x.compareTo(b.x));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).dailyExpenses,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: 100,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
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
                            '${value.toInt()}€',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (value, meta) {
                          if (value < 1 || value > 31) return const Text('');
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2.5,
                      color: Theme.of(context).colorScheme.error,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Theme.of(context).colorScheme.error,
                                  strokeWidth: 1,
                                  strokeColor: Theme.of(
                                    context,
                                  ).colorScheme.error.withOpacity(0.5),
                                ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
