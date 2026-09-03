import 'package:cashly/common/month_names.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:cashly/modules/saves/home_saves.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:cashly/theme/widgets/stat_tile.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';

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

  static const String _currency = '€';

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _availableYears = await _financeService.getAvailableYears();
    _availableMonths = await _financeService.getAvailableMonths(_year);
    if (mounted) setState(() {});
  }

  Future<void> _setNewDate(int month, int year) async {
    await _financeService.updateSelectedDate(month, year);
    if (mounted) {
      setState(() {
        _month = month;
        _year = year;
      });
    }
  }

  void _showMonthSelector() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                    final months = await _financeService.getAvailableMonths(year);
                    Navigator.pop(dialogContext);
                    setState(() {
                      _availableMonths = months;
                      _year = year;
                    });
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
    return AnimatedBuilder(
      animation: _financeService,
      builder: (context, child) {
        return Column(
          children: [
            _buildSubHeader(),
            Expanded(child: _buildSummaryTab()),
          ],
        );
      },
    );
  }

  Widget _buildSubHeader() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return ListTile(
      title: Text(
        "${_getMonthName(_month)} $_year",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.savings,
            icon: Icon(Icons.savings_outlined, color: scheme.primary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeSaves()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.calendar_month, color: glass.mutedText),
            onPressed: _showMonthSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return FutureBuilder<List<MovementValue>>(
      future: _financeService.getMovementsForMonth(_month, _year),
      builder: (context, snapshot) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            if (snapshot.connectionState == ConnectionState.waiting)
              SliverFillRemaining(child: Center(child: Loading(context)))
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SectionHeader(title: AppLocalizations.of(context)!.financialSummary),
                    const SizedBox(height: 8),
                    _buildMonthlyOverview(snapshot.data!),
                    const SizedBox(height: 24),
                    SectionHeader(title: AppLocalizations.of(context)!.evolution),
                    const SizedBox(height: 8),
                    _buildEvolutionChart(),
                    const SizedBox(height: 24),
                    SectionHeader(title: AppLocalizations.of(context)!.distribution),
                    const SizedBox(height: 8),
                    _buildDistribution(snapshot.data!),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: glass.mutedText),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noDataForMonth(_month.toString(), _year),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverview(List<MovementValue> movements) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final expenses = movements.where((m) => m.isExpense).fold<double>(0, (sum, mov) => sum + mov.amount);
    final incomes = movements.where((m) => !m.isExpense).fold<double>(0, (sum, mov) => sum + mov.amount);
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
                  Icon(Icons.account_balance, size: 18, color: glass.incomeColor),
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
                crossAxisAlignment: CrossAxisAlignment.center,
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
                label: AppLocalizations.of(context)!.incomes,
                amount: incomes,
                currency: _currency,
                icon: Icons.arrow_downward,
                isIncome: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: AppLocalizations.of(context)!.expenses,
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

  Widget _buildDistribution(List<MovementValue> movements) {
    return GlassCard(
      child: CategoryProgressChart(
        categoryData: _calculateCategoryPercentages(
          movements.where((m) => m.isExpense).toList(),
        ),
      ),
    );
  }

  Widget _buildEvolutionChart() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return GlassCard(
      child: FutureBuilder<List<Map<String, double>>>(
        future: _financeService.getYearlyData(_year),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data!;
          final spots = <FlSpot>[
            for (var i = 0; i < data.length; i++)
              FlSpot(
                i.toDouble(),
                (data[i]['incomes'] ?? 0) - (data[i]['expenses'] ?? 0),
              ),
          ];

          final monthLabels = monthShortNames(AppLocalizations.of(context)!);

          return SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx.isOdd || idx < 0 || idx > 11) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthLabels[idx],
                            style: TextStyle(
                              color: glass.mutedText,
                              fontSize: 11,
                            ),
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
          );
        },
      ),
    );
  }

  Map<String, double> _calculateCategoryPercentages(List<MovementValue> expenses) {
    final totals = <String, double>{};
    final total = expenses.fold<double>(0, (sum, m) => sum + m.amount);
    for (var tag in getTagList(AppLocalizations.of(context)!.localeName)) totals[tag] = 0;
    for (var m in expenses) if (m.category != null) totals[m.category!] = (totals[m.category!] ?? 0) + m.amount;

    final List<MapEntry<String, double>> entries = totals.entries
        .where((e) => e.value > 0)
        .map((e) => MapEntry(e.key, total > 0 ? (e.value / total) * 100 : 0.0))
        .toList();

    entries.sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  String _getMonthName(int month) {
    final months = [
      AppLocalizations.of(context)!.january, AppLocalizations.of(context)!.february,
      AppLocalizations.of(context)!.march, AppLocalizations.of(context)!.april,
      AppLocalizations.of(context)!.may, AppLocalizations.of(context)!.june,
      AppLocalizations.of(context)!.july, AppLocalizations.of(context)!.august,
      AppLocalizations.of(context)!.september, AppLocalizations.of(context)!.october,
      AppLocalizations.of(context)!.november, AppLocalizations.of(context)!.december,
    ];
    return months[month - 1];
  }
}
