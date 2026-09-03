import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/home.dart';
import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/summary_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/app_bottom_nav.dart';
import 'package:cashly/theme/widgets/month_chip.dart';
import 'package:cashly/common/month_names.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late final TabController _tabController;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  late Future<bool> _initializationFuture;
  String? _backgroundImagePath;

  void _onDestinationSelected(int index) {
    _tabController.animateTo(index);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: _selectedIndex,
    );

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedIndex = _tabController.index;
        });
      }
    });

    _initializationFuture = _initialize();
  }

  Future<bool> _initialize() async {
    final prefs = SharedPreferencesService();
    final isFirstStartup =
        await prefs.getBoolValue(SharedPreferencesKeys.isFirstStartup) ?? true;
    final backgroundImage =
        await prefs.getStringValue(SharedPreferencesKeys.backgroundImage);

    if (mounted) {
      setState(() {
        _backgroundImagePath = backgroundImage;
      });
    }

    if (!isFirstStartup) {
      await SqliteService().initializeDatabase();
      await Future.microtask(() async {
        final financeService = FinanceService.getInstance(
          SqliteService().db.monthDao,
          SqliteService().db.movementValueDao,
          SqliteService().db.fixedMovementDao,
        );
        _availableYears = await financeService.getAvailableYears();
        _availableMonths = await financeService.getAvailableMonths(_year);
        await financeService.setCurrentMonth(_month, _year);
        setState(() {});
      });
    }

    return isFirstStartup;
  }

  Future<void> _setNewDate(int month, int year) async {
    final financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    _availableMonths = await financeService.getAvailableMonths(year);
    final selectedMonth = await financeService.handleMonthSelection(
      month,
      year,
      context,
    );
    if (selectedMonth != null) {
      setState(() {
        _month = selectedMonth;
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
                    final financeService = FinanceService.getInstance(
                      SqliteService().db.monthDao,
                      SqliteService().db.movementValueDao,
                      SqliteService().db.fixedMovementDao,
                    );
                    final months = await financeService.getAvailableMonths(year);
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
      ),
    );
  }

  Future<void> _reloadConfigs() async {
    final prefs = SharedPreferencesService();
    final bg = await prefs.getStringValue(SharedPreferencesKeys.backgroundImage);
    if (mounted) {
      setState(() {
        _backgroundImagePath = bg;
      });
    }
  }

  Future<void> _openNewMovement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovementFormScreen(asScreen: true)),
    );
    if (mounted) setState(() {});
  }

  List<Widget> get _screens => [
    GastoscopioHomeScreen(
      key: const ValueKey('home'),
      year: _year,
      month: _month,
      onNavigateTab: _onDestinationSelected,
    ),
    const ActiveDebtsScreen(key: ValueKey('debts'), embedded: true),
    MovementsScreen(
      key: const ValueKey('movements'),
      year: _year,
      month: _month,
    ),
    const SummaryScreen(key: ValueKey('summary')),
  ];

  String _titleForIndex(BuildContext context, int index) {
    final l = AppLocalizations.of(context)!;
    return [l.home, l.navDebts, l.navHistory, l.navStatistics][index];
  }

  Widget _buildTopBar() {
    final financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          if (_selectedIndex != 3)
            AnimatedBuilder(
              animation: financeService,
              builder: (context, _) => MonthChip(
                label: _monthChipLabel(context, financeService),
                onTap: _showMonthSelector,
              ),
            ),
          const Spacer(),
          Text(
            _titleForIndex(context, _selectedIndex),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              await _reloadConfigs();
            },
          ),
        ],
      ),
    );
  }

  String _monthChipLabel(BuildContext context, FinanceService financeService) {
    final month = financeService.currentMonth;
    if (month == null) return '';
    return '${monthShortNames(AppLocalizations.of(context)!)[month.month - 1]} ${month.year}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: Loading(context)));
        }
        if (snapshot.data == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          });
          return Scaffold(body: Center(child: Loading(context)));
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: AppBackground(
            imagePath: _selectedIndex == 0 ? _backgroundImagePath : null,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      physics: const ClampingScrollPhysics(),
                      children: _screens,
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNav(
            selectedIndex: _selectedIndex,
            onSelected: _onDestinationSelected,
            items: [
              (
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: AppLocalizations.of(context)!.home,
              ),
              (
                icon: Icons.credit_score_outlined,
                selectedIcon: Icons.credit_score,
                label: AppLocalizations.of(context)!.navDebts,
              ),
              (
                icon: Icons.history,
                selectedIcon: Icons.history,
                label: AppLocalizations.of(context)!.navHistory,
              ),
              (
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: AppLocalizations.of(context)!.navStatistics,
              ),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: const CircleBorder(),
            onPressed: _openNewMovement,
            child: const Icon(Icons.add, size: 30),
          ),
        );
      },
    );
  }
}
