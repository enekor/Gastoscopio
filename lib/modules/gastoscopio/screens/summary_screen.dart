import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FinanceService _financeService;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _aiAnalysis = '';
  bool _isLoadingAnalysis = false;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _availableYears = await _financeService.getAvailableYears();
    _availableMonths = await _financeService.getAvailableMonths(_year);
    _hasData = await _financeService.getMonthMovementsCount(_month, _year) > 5;
    if (mounted) setState(() {});
  }

  Future<void> _loadAiAnalysis() async {
    setState(() => _isLoadingAnalysis = true);
    final movements = await _financeService.getMovementsForMonth(_month, _year);
    final value = await GroqService().generateSummary(movements, Month(_month, _year), context);
    if (mounted) {
      setState(() {
        _aiAnalysis = value;
        _isLoadingAnalysis = false;
      });
    }
  }

  Future<void> _setNewDate(int month, int year) async {
    await _financeService.updateSelectedDate(month, year);
    _hasData = await _financeService.getMonthMovementsCount(month, year) > 5;
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildAiAnalysisTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubHeader() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            title: Text(
              "${_getMonthName(_month)} $_year",
              style: const TextStyle(fontFamily: 'Pacifico', fontSize: 18),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthSelector,
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.summary),
              Tab(text: AppLocalizations.of(context)!.aiAnalysis),
            ],
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
                    _buildMonthlyOverview(snapshot.data!),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.categoryDistribution,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    CategoryProgressChart(
                      categoryData: _calculateCategoryPercentages(
                        snapshot.data!.where((m) => m.isExpense).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDailySpendingChart(
                      snapshot.data!.where((m) => m.isExpense).toList(),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAiAnalysisTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.aiAnalysisTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _loadAiAnalysis,
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(AppLocalizations.of(context)!.generate),
                ),
              ],
            ),
          ),
        ),
        if (!_hasData)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState())
        else if (_isLoadingAnalysis)
          SliverFillRemaining(child: Center(child: Loading(context)))
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Card(
                color: Theme.of(context).colorScheme.secondary.withAlpha(25),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: MarkdownBody(
                    data: _aiAnalysis.isEmpty
                        ? AppLocalizations.of(context)!.generateAnalysisHint
                        : _aiAnalysis,
                  ),
                ),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.secondary),
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
    final expenses = movements.where((m) => m.isExpense).fold<double>(0, (sum, mov) => sum + mov.amount);
    final incomes = movements.where((m) => !m.isExpense).fold<double>(0, (sum, mov) => sum + mov.amount);
    final balance = incomes - expenses;

    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.monthlySummary, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildOverviewRow(AppLocalizations.of(context)!.income, incomes, Colors.green),
            const SizedBox(height: 8),
            _buildOverviewRow(AppLocalizations.of(context)!.expenses, expenses, Colors.red),
            const Divider(),
            _buildOverviewRow(AppLocalizations.of(context)!.balance, balance, balance >= 0 ? Colors.green : Colors.red),
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
        Text('${amount.toStringAsFixed(2)}€', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDailySpendingChart(List<MovementValue> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final dailyTotals = <int, double>{};
    for (var m in expenses) dailyTotals[m.day] = (dailyTotals[m.day] ?? 0) + m.amount;
    final spots = dailyTotals.entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()..sort((a, b) => a.x.compareTo(b.x));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.dailyExpenses, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Theme.of(context).colorScheme.error, belowBarData: BarAreaData(show: true, color: Theme.of(context).colorScheme.error.withOpacity(0.1)))],
            titlesData: FlTitlesData(topTitles: const AxisTitles(), rightTitles: const AxisTitles()),
          )),
        ),
      ],
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
