import 'package:cashly/common/tag_list.dart' show getTagList;
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/summary_tab_content.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {}); // Update UI with loaded data
  }

  Future<void> _loadAiAnalysis() async {
    setState(() => _isLoadingAnalysis = true);
    try {
      final movements = await _financeService.getMovementsForMonth(
        _month,
        _year,
      );
      final analysis = await GeminiService().generateSummary(
        movements,
        Month(_month, _year),
        context,
      );
      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAnalysis = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAnalysis = false;
        _aiAnalysis = AppLocalizations.of(context).noResponseGenerated;
      });
    }
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
          (dialogContext) => Dialog(
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
                      final months = await _financeService.getAvailableMonths(
                        year,
                      );
                      Navigator.pop(dialogContext);
                      setState(() {
                        _availableMonths = months;
                        _year = year;
                      });
                      if (!months.contains(_month)) {
                        await _setNewDate(months.last, year);
                      } else {
                        await _setNewDate(_month, year);
                      }
                      _showMonthSelector();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _getMonthName(int month) {
    final localizations = AppLocalizations.of(context);
    switch (month) {
      case 1:
        return localizations.january;
      case 2:
        return localizations.february;
      case 3:
        return localizations.march;
      case 4:
        return localizations.april;
      case 5:
        return localizations.may;
      case 6:
        return localizations.june;
      case 7:
        return localizations.july;
      case 8:
        return localizations.august;
      case 9:
        return localizations.september;
      case 10:
        return localizations.october;
      case 11:
        return localizations.november;
      case 12:
        return localizations.december;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${_getMonthName(_month)} $_year",
              style: GoogleFonts.pacifico(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: _showMonthSelector,
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.analytics), text: localizations.summary),
            Tab(
              icon: const Icon(Icons.auto_awesome),
              text: localizations.aiAnalysis,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<MovementValue>>(
            future: _financeService.getMovementsForMonth(_month, _year),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.errorLoadingMovements(
                            snapshot.error.toString(),
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              return SummaryTabContent(movements: snapshot.data ?? []);
            },
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      localizations.aiAnalysisTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _loadAiAnalysis,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(localizations.generate),
                    ),
                  ],
                ),
              ),
              if (_isLoadingAnalysis)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withAlpha(25),
                    margin: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBody(
                        data:
                            _aiAnalysis.isEmpty
                                ? localizations.generateAnalysisHint
                                : _aiAnalysis,
                        styleSheet: MarkdownStyleSheet(
                          h1: Theme.of(context).textTheme.titleLarge,
                          h2: Theme.of(context).textTheme.titleMedium,
                          p: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                          listBullet: Theme.of(context).textTheme.bodyMedium,
                          strong: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        selectable: true,
                        softLineBreak: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
