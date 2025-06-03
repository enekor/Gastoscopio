import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GastoscopioHomeScreen extends StatefulWidget {
  const GastoscopioHomeScreen({
    Key? key,
    required this.year,
    required this.month,
  }) : super(key: key);
  final int year;
  final int month;

  @override
  State<GastoscopioHomeScreen> createState() => _GastoscopioHomeScreenState();
}

class _GastoscopioHomeScreenState extends State<GastoscopioHomeScreen> {
  String _greeting = '';
  late String _moneda = 'loading...';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadInitialData();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  @override
  void didUpdateWidget(GastoscopioHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _loadInitialData();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Establecer el mes actual y cargar sus datos
      final service = Provider.of<FinanceService>(context, listen: false);
      await service.updateSelectedDate(widget.month, widget.year);
    } catch (e) {
      debugPrint('Error al cargar datos iniciales: $e');
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
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MovementFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        heroTag: 'home_fab',
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingsPart(),
              const SizedBox(height: 24),
              _buildLastInteractionsPart(),
              const SizedBox(height: 16),
              _buildTotalPart(),
              const SizedBox(width: 16),
              _ChartPart(_moneda),
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
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withAlpha(90),
            ),
          ),
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
                          moneda: _moneda,
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
                    '${total < 0 ? '-' : ''}${total.abs().toStringAsFixed(2)}${_moneda}',
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
  _ChartPart(this.moneda);
  String moneda;

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, service, _) {
        if (service.currentMonth == null) return const SizedBox.shrink();
        return YearlyChart(year: service.currentMonth!.year, moneda: moneda);
      },
    );
  }
}
