import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:cashly/theme/widgets/stat_tile.dart';
import 'package:fl_chart/fl_chart.dart';

class SummaryTabContent extends StatelessWidget {
  final List<MovementValue> movements;

  static const String _currency = '€';

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
            SectionHeader(title: AppLocalizations.of(context)!.financialSummary),
            const SizedBox(height: 8),
            _buildMonthlyOverview(context, movements),
            const SizedBox(height: 24),
            SectionHeader(title: AppLocalizations.of(context)!.distribution),
            const SizedBox(height: 8),
            GlassCard(child: CategoryProgressChart(categoryData: categoryData)),
            const SizedBox(height: 24),
            SectionHeader(title: AppLocalizations.of(context)!.evolution),
            const SizedBox(height: 8),
            _buildDailySpendingChart(context, expenses),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: glass.mutedText),
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
    final glass = Theme.of(context).extension<AppGlass>()!;
    final expenses = movements
        .where((m) => m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final incomes = movements
        .where((m) => !m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final balance = incomes - expenses;
    final ratio = incomes > 0 ? (balance / incomes) * 100 : 0.0;

    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    size: 18,
                    color: glass.incomeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.netSavings.toUpperCase(),
                    style: TextStyle(
                      color: glass.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AmountText(
                        amount: balance.abs(),
                        currency: _currency,
                        isExpense: balance < 0,
                        signed: true,
                        fontSize: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildRatioBadge(ratio, glass),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: AppLocalizations.of(context).incomes,
                amount: incomes,
                currency: _currency,
                icon: Icons.arrow_downward,
                isIncome: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: AppLocalizations.of(context).expenses,
                amount: expenses,
                currency: _currency,
                icon: Icons.arrow_upward,
                isIncome: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatioBadge(double ratio, AppGlass glass) {
    final positive = ratio >= 0;
    final color = positive ? glass.incomeColor : glass.expenseColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(glass.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${positive ? '+' : ''}${ratio.toStringAsFixed(0)}%',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySpendingChart(
    BuildContext context,
    List<MovementValue> expenses,
  ) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

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

    return GlassCard(
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 5,
                  getTitlesWidget: (value, meta) {
                    if (value < 1 || value > 31) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        value.toInt().toString(),
                        style: TextStyle(color: glass.mutedText, fontSize: 11),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 2,
                color: scheme.primary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withValues(alpha: 0.35),
                      scheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
