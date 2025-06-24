import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/home.dart';
import 'package:cashly/modules/gastoscopio/screens/movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/summary_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isOpaqueBottomNav = false;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_outlined),
      selectedIcon: Icon(Icons.list),
      label: '',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: '',
    ),
  ];

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
      length: 3,
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
    final isFirstStartup =
        await SharedPreferencesService().getBoolValue(
          SharedPreferencesKeys.isFirstStartup,
        ) ??
        true;

    // Load bottom navigation style configuration
    final isOpaqueBottomNav =
        await SharedPreferencesService().getBoolValue(
          SharedPreferencesKeys.isOpaqueBottomNav,
        ) ??
        false;

    if (mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaqueBottomNav;
      });
    }

    if (!isFirstStartup) {
      await SqliteService().initializeDatabase();
      // Esperamos al siguiente frame para asegurarnos de que el singleton está listo
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
                            final financeService = FinanceService.getInstance(
                              SqliteService().db.monthDao,
                              SqliteService().db.movementValueDao,
                              SqliteService().db.fixedMovementDao,
                            );
                            final months = await financeService
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

  Future<void> _reloadBottomNavConfig() async {
    final isOpaqueBottomNav =
        await SharedPreferencesService().getBoolValue(
          SharedPreferencesKeys.isOpaqueBottomNav,
        ) ??
        false;

    if (mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaqueBottomNav;
      });
    }
  }

  List<Widget> get _screens => [
    GastoscopioHomeScreen(
      key: const ValueKey('home'),
      year: _year,
      month: _month,
    ),
    MovementsScreen(
      key: const ValueKey('movements'),
      year: _year,
      month: _month,
    ),
    const SummaryScreen(key: ValueKey('summary')),
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          // Programar la navegación para después del frame actual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          });
          // Mientras tanto, mostrar una pantalla de carga
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          extendBody: _selectedIndex != 2,
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Gastoscopio',
              style: GoogleFonts.pacifico(fontSize: 24, letterSpacing: 1.2),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  // Reload configuration when returning from settings
                  await _reloadBottomNavConfig();
                },
              ),
              if (_selectedIndex != 2)
                IconButton(
                  onPressed: _showMonthSelector,
                  icon: const Icon(Icons.calendar_today),
                ),
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            physics: const ClampingScrollPhysics(),
            children: _screens,
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: _selectedIndex != 2 ? 75.0 : 24.0,
              bottom: 16.0,
            ),
            child: Card(
              color:
                  _isOpaqueBottomNav
                      ? Theme.of(context).colorScheme.primary.withAlpha(200)
                      : Theme.of(context).colorScheme.secondary.withAlpha(25),
              elevation: _isOpaqueBottomNav ? 4 : 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side:
                    _isOpaqueBottomNav
                        ? BorderSide.none
                        : BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withAlpha(50),
                          width: 1,
                        ),
              ),
              child: NavigationBar(
                selectedIndex: _tabController.index,
                onDestinationSelected: _onDestinationSelected,
                destinations:
                    _destinations.map((destination) {
                      return NavigationDestination(
                        icon: Icon(
                          (destination.icon as Icon).icon,
                          color:
                              _isOpaqueBottomNav
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimary.withAlpha(150)
                                  : null,
                        ),
                        selectedIcon: Icon(
                          (destination.selectedIcon as Icon).icon,
                          color:
                              _isOpaqueBottomNav
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                        ),
                        label: destination.label,
                      );
                    }).toList(),
                backgroundColor: Colors.transparent,
                elevation: 0,
                height: 48,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                animationDuration: const Duration(milliseconds: 500),
                indicatorColor:
                    _isOpaqueBottomNav
                        ? Theme.of(context).colorScheme.onPrimary.withAlpha(50)
                        : Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
            ),
          ),
        );
      },
    );
  }
}
