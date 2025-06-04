import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late FinanceService _financeService;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _financeService = Provider.of<FinanceService>(context, listen: false);
    _availableYears = await _financeService.getAvailableYears();
    _availableMonths = await _financeService.getAvailableMonths(_year);
    setState(() {}); // Update UI with loaded data
  }

  Future<void> _setNewDate(int month, int year) async {
    await _financeService.updateSelectedDate(month, year);
    setState(() {
      _month = month;
      _year = year;
    });
  }

  void _showMonthSelector() {
    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MonthGridSelector(
                          availableMonths: _availableMonths,
                          availableYears: _availableYears,
                          selectedMonth: _month,
                          selectedYear: _year,
                          onMonthChanged: (month) async {
                            await _setNewDate(month, _year);
                            Navigator.pop(dialogContext);
                          },
                          onYearChanged: (year) async {
                            final months = await _financeService
                                .getAvailableMonths(year);

                            // Cerrar el diálogo actual
                            Navigator.pop(dialogContext);

                            // Actualizar ambos estados de forma sincronizada
                            setState(() {
                              _availableMonths = months;
                              _year = year;
                            });

                            // Manejar el cambio de mes si es necesario
                            if (!months.contains(_month)) {
                              await _setNewDate(months.last, year);
                            } else {
                              await _setNewDate(_month, year);
                            }

                            // Mostrar el diálogo actualizado
                            _showMonthSelector();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${_getMonthName(_month)} $_year"),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthSelector,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<FinanceService>(
              builder: (context, financeService, _) {
                return FutureBuilder<List<MovementValue>>(
                  future: financeService.getMovementsForMonth(_month, _year),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    final movements = snapshot.data!;
                    final expenses =
                        movements.where((m) => m.isExpense).toList();
                    final categoryData = _calculateCategoryPercentages(
                      expenses,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMonthlyOverview(movements),
                          const SizedBox(height: 24),
                          Text(
                            'Distribución de Gastos por Categoría',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          CategoryProgressChart(categoryData: categoryData),
                          const SizedBox(height: 24),
                          _buildDailySpendingChart(expenses),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No hay datos para ${_getMonthName(_month)} $_year',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Los datos aparecerán aquí cuando agregues movimientos',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverview(List<MovementValue> movements) {
    final expenses = movements
        .where((m) => m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final incomes = movements
        .where((m) => !m.isExpense)
        .fold<double>(0, (sum, mov) => sum + mov.amount);
    final balance = incomes - expenses;
    final expenseRatio = expenses > 0 ? (expenses / incomes) * 100 : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Mes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildOverviewRow('Ingresos', incomes, Colors.green),
            const SizedBox(height: 8),
            _buildOverviewRow('Gastos', expenses, Colors.red),
            const Divider(),
            _buildOverviewRow(
              'Balance',
              balance,
              balance >= 0 ? Colors.green : Colors.red,
            ),
            if (incomes > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Has gastado el ${expenseRatio.toStringAsFixed(1)}% de tus ingresos',
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

  Widget _buildOverviewRow(String label, double amount, Color color) {
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

  Widget _buildDailySpendingChart(List<MovementValue> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();

    final dailyTotals = <int, double>{};
    for (var movement in expenses) {
      dailyTotals[movement.day] =
          (dailyTotals[movement.day] ?? 0) + movement.amount;
    }

    final spots =
        dailyTotals.entries.map((e) {
            return FlSpot(e.key.toDouble(), e.value);
          }).toList()
          ..sort((a, b) => a.x.compareTo(b.x));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gastos Diarios', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
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
                            '${value.toInt()}€', // TODO: Use moneda variable instead of hardcoded €
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
                        interval: 2, // Mostrar cada dos días
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

  Map<String, double> _calculateCategoryPercentages(
    List<MovementValue> expenses,
  ) {
    final categoryTotals = <String, double>{};
    final total = expenses.fold<double>(
      0,
      (sum, movement) => sum + movement.amount,
    );

    // Initialize all categories to 0
    for (var tag in TagList) {
      categoryTotals[tag] = 0;
    }

    // Calculate totals for each category
    for (var movement in expenses) {
      if (movement.category != null) {
        categoryTotals[movement.category!] =
            (categoryTotals[movement.category!] ?? 0) + movement.amount;
      }
    }

    // Convert to percentages
    final percentages = <String, double>{};
    categoryTotals.forEach((category, amount) {
      percentages[category] = total > 0 ? (amount / total) * 100 : 0;
    });

    return Map.fromEntries(
      percentages.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  String _getMonthName(int month) {
    final months = [
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
    return months[month - 1];
  }
}
