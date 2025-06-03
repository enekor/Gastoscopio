import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/home.dart';
import 'package:cashly/modules/gastoscopio/screens/movements_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isSelectingDate = false;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  late final FinanceService _financeService;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.list_outlined),
      selectedIcon: Icon(Icons.list),
      label: 'Movimientos',
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadInitialData() async {
    await SqliteService().initializeDatabase();

    // Crear una nueva instancia del servicio si no podemos obtenerla del Provider
    try {
      _financeService = Provider.of<FinanceService>(context, listen: false);
    } catch (e) {
      _financeService = FinanceService(
        SqliteService().database.monthDao,
        SqliteService().database.movementValueDao,
      );
    }

    setState(() {
      _availableYears = [];
      _availableMonths = [];
    });

    await _loadAvailableYearsAndMonths();
    // Establecer el mes actual al inicio
    await _financeService.updateSelectedDate(_month, _year);
  }

  Future<void> _loadAvailableYearsAndMonths() async {
    _availableYears = await _financeService.getAvailableYears();
    _availableMonths = await _financeService.getAvailableMonths(_year);
    setState(() {}); // Actualizar UI con los datos cargados
  }

  Future<void> _setNewDate(int month, int year) async {
    _availableMonths = await _financeService.getAvailableMonths(year);
    final selectedMonth = await _financeService.handleMonthSelection(
      month,
      year,
      context,
    );

    if (selectedMonth != null) {
      setState(() {
        _month = selectedMonth;
        _year = year;
        _isSelectingDate = false;
      });
    }
  }

  List<Widget> get _screens => [
    GastoscopioHomeScreen(year: _year, month: _month),
    MovementsScreen(year: _year, month: _month),
  ];
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadInitialData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return ChangeNotifierProvider.value(
          value: _financeService,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Companion Tools'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                IconButton(
                  onPressed:
                      () => setState(() {
                        _isSelectingDate = !_isSelectingDate;
                      }),
                  icon: const Icon(Icons.calendar_today),
                ),
              ],
            ),
            body: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedCard(
                    context,
                    isExpanded: _selectedIndex == 0 ? true : _isSelectingDate,
                    hiddenWidget: MonthYearSelector(
                      availableMonths: _availableMonths,
                      availableYears: _availableYears,
                      selectedMonth: _month,
                      selectedYear: _year,
                      onMonthChanged: (month) async {
                        await _setNewDate(month, _year);
                      },
                      onYearChanged: (year) async {
                        final months = await _financeService.getAvailableMonths(
                          year,
                        );
                        setState(() {
                          _availableMonths = months;
                          _year = year;
                        });
                        // Si el mes actual no está disponible en el nuevo año,
                        // seleccionar el último mes disponible
                        if (!months.contains(_month)) {
                          await _setNewDate(months.last, year);
                        } else {
                          await _setNewDate(_month, year);
                        }
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _destinations,
            ),
          ),
        );
      },
    );
  }
}
