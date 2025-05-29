import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GastoscopioHomeScreen extends StatefulWidget {
  const GastoscopioHomeScreen({Key? key}) : super(key: key);

  @override
  State<GastoscopioHomeScreen> createState() => _GastoscopioHomeScreenState();
}

class _GastoscopioHomeScreenState extends State<GastoscopioHomeScreen> {
  late FinanceService _financeService;
  String _greeting = '';
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  List<int> _availableYears = [];
  List<int> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _initializeFinanceService();
  }

  void _initializeFinanceService() {
    final db = SqliteService().db;
    _financeService = FinanceService(db.monthDao, db.movementValueDao);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Obtener años disponibles
      final years = await _financeService.getAvailableYears();
      setState(() {
        _availableYears = years;
        _selectedYear =
            years.contains(DateTime.now().year)
                ? DateTime.now().year
                : years.last;
      });

      // Obtener meses disponibles para el año seleccionado
      final months = await _financeService.getAvailableMonths(_selectedYear);
      setState(() {
        _availableMonths = months;
        _selectedMonth =
            months.contains(DateTime.now().month)
                ? DateTime.now().month
                : months.last;
      });

      // Establecer el mes actual
      await _financeService.setCurrentMonth(_selectedMonth, _selectedYear);
    } catch (e) {
      debugPrint('Error al cargar datos iniciales: $e');
      // Establecer valores por defecto
      setState(() {
        _selectedYear = DateTime.now().year;
        _selectedMonth = DateTime.now().month;
        _availableYears = [_selectedYear];
        _availableMonths = [_selectedMonth];
      });
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour < 12) {
        _greeting = 'Bienvenido al nuevo día ✨';
      } else if (hour < 18) {
        _greeting = 'El sol brilla en tu camino ☀️';
      } else {
        _greeting = 'Las estrellas te acompañan 🌟';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _financeService,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingsPart(),
              const SizedBox(height: 24),
              _buildLastInteractionsPart(),
              const SizedBox(height: 16),
              _buildDatePart(),
              const SizedBox(height: 16),
              _buildTotalPart(),
              const SizedBox(width: 16),
              const _ChartPart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingsPart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestiona tus finanzas con tranquilidad',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLastInteractionsPart() {
    return Consumer<FinanceService>(
      builder: (context, service, _) {
        final movements = service.todayMovements;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Últimos movimientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (movements.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No hay movimientos para mostrar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: movements.length,
                    itemBuilder: (context, index) {
                      final movement = movements[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: MovementCard(
                          description: movement.description,
                          amount: movement.amount,
                          isExpense: movement.isExpense,
                          category: movement.category,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatePart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Período', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            MonthYearSelector(
              selectedYear: _selectedYear,
              selectedMonth: _selectedMonth,
              availableYears: _availableYears,
              availableMonths: _availableMonths,
              onYearChanged: (year) async {
                setState(() => _selectedYear = year);
                final months = await _financeService.getAvailableMonths(year);
                setState(() {
                  _availableMonths = months;
                  _selectedMonth =
                      months.contains(DateTime.now().month)
                          ? DateTime.now().month
                          : months.last;
                });
                await _financeService.setCurrentMonth(
                  _selectedMonth,
                  _selectedYear,
                );
              },
              onMonthChanged: (month) async {
                final selectedMonth = await _financeService
                    .handleMonthSelection(month, _selectedYear, context);
                if (selectedMonth != null) {
                  // Actualizar el mes seleccionado
                  setState(() => _selectedMonth = selectedMonth);
                  // Actualizar los meses disponibles
                  final months = await _financeService.getAvailableMonths(
                    _selectedYear,
                  );
                  setState(() {
                    _availableMonths = months;
                  });
                  // Actualizar el mes actual en el servicio
                  await _financeService.setCurrentMonth(
                    _selectedMonth,
                    _selectedYear,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalPart() {
    return Consumer<FinanceService>(
      builder: (context, service, _) {
        final total = service.monthTotal;
        final isPositive = total >= 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance del mes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '\$${total.abs().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color:
                          isPositive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChartPart extends StatelessWidget {
  const _ChartPart();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, service, _) {
        return FutureBuilder(
          future: Future.wait([
            service.getCategoryTotals(),
            service.getDailyTotals(),
          ]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final categoryTotals = snapshot.data![0] as Map<String, double>;
            final dailyTotals =
                snapshot.data![1] as List<MapEntry<DateTime, double>>;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Análisis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (categoryTotals.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Center(child: CategoryPieChart(data: categoryTotals)),
                      const SizedBox(height: 24),
                    ],
                    if (dailyTotals.isNotEmpty) ...[
                      Text(
                        'Evolución diaria',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      DailyTotalChart(data: dailyTotals),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
