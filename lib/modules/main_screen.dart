import 'dart:io';

import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/home.dart';
import 'package:cashly/modules/gastoscopio/screens/movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/summary_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/month_grid_selector.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/modules/settings.dart/widgets/custom_navbar.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

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
  String? _backgroundImagePath;

  final List<CustomNavigationDestination> _destinations = const [
    CustomNavigationDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    CustomNavigationDestination(
      icon: Icons.list_outlined,
      selectedIcon: Icons.list,
      label: 'List',
    ),
    CustomNavigationDestination(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      label: 'Analytics',
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
    final prefs = SharedPreferencesService();
    final isFirstStartup =
        await prefs.getBoolValue(
          SharedPreferencesKeys.isFirstStartup,
        ) ??
        true;

    // Load bottom navigation style configuration
    final isOpaqueBottomNav =
        await prefs.getBoolValue(
          SharedPreferencesKeys.isOpaqueBottomNav,
        ) ??
        false;

    final backgroundImage = await prefs.getStringValue(
      SharedPreferencesKeys.backgroundImage,
    );

    if (mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaqueBottomNav;
        _backgroundImagePath = backgroundImage;
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
                    final months = await financeService.getAvailableMonths(
                      year,
                    );

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

  Future<void> _reloadConfigs() async {
    final prefs = SharedPreferencesService();
    final isOpaqueBottomNav =
        await prefs.getBoolValue(
          SharedPreferencesKeys.isOpaqueBottomNav,
        ) ??
        false;
    
    final backgroundImage = await prefs.getStringValue(
      SharedPreferencesKeys.backgroundImage,
    );

    if (mounted) {
      setState(() {
        _isOpaqueBottomNav = isOpaqueBottomNav;
        _backgroundImagePath = backgroundImage;
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
          return Scaffold(body: Center(child: Loading(context)));
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
          return Scaffold(body: Center(child: Loading(context)));
        }

        final hasBackground = _backgroundImagePath != null && _backgroundImagePath!.isNotEmpty;

        return Scaffold(
          extendBody: _selectedIndex != 2,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            toolbarHeight: kToolbarHeight + 32,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Padding(
              padding: const EdgeInsets.only(top: 35.0),
              child: Text(
                AppLocalizations.of(context)!.appTitle,
                style: TextStyle(
                  fontFamily: 'Pacifico',
                  fontSize: 24,
                  letterSpacing: 1.2,
                  color: hasBackground && _selectedIndex == 0 ? Colors.white : null,
                  shadows: hasBackground && _selectedIndex == 0 ? [
                    const Shadow(
                      blurRadius: 10.0,
                      color: Colors.black54,
                      offset: Offset(2.0, 2.0),
                    ),
                  ] : null,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(top: 35.0),
                child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: hasBackground && _selectedIndex == 0 ? Colors.white : null,
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                    // Reload configuration when returning from settings
                    await _reloadConfigs();
                  },
                ),
              ),
              if (_selectedIndex != 2)
                Padding(
                  padding: const EdgeInsets.only(top: 35.0),
                  child: IconButton(
                    onPressed: _showMonthSelector,
                    icon: Icon(
                      Icons.calendar_today,
                      color: hasBackground && _selectedIndex == 0 ? Colors.white : null,
                    ),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              if (hasBackground && _selectedIndex == 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 2,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_backgroundImagePath!),
                        fit: BoxFit.cover,
                      ),
                      // Overlay oscuro y fadeout al final
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.7), // Oscurecimiento inicial más fuerte
                              Colors.black.withOpacity(0.3), // Parte media algo más clara
                              Theme.of(context).colorScheme.surface, // Fadeout total al color de fondo
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TabBarView(
                controller: _tabController,
                physics: const ClampingScrollPhysics(),
                children: _screens,
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            height: 45,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: _destinations,
            backgroundColor: _isOpaqueBottomNav
                ? Theme.of(context).colorScheme.primary.withAlpha(200)
                : Theme.of(context).colorScheme.secondary.withAlpha(25),
            elevation: _isOpaqueBottomNav ? 4 : 8,
            animationDuration: const Duration(milliseconds: 500),
            indicatorColor: _isOpaqueBottomNav
                ? Theme.of(context).colorScheme.onPrimary.withAlpha(50)
                : Theme.of(context).colorScheme.primary.withAlpha(50),
            isOpaque: _isOpaqueBottomNav,
            margin: EdgeInsets.only(left: 24.0, right: 24.0, bottom: 18.0),
            borderRadius: BorderRadius.circular(24),
            border: _isOpaqueBottomNav
                ? null
                : Border.all(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                    width: 1,
                  ),
          ),
        );
      },
    );
  }
}
