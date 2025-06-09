import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:cashly/modules/gastoscopio/widgets/category_progress_chart.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:flutter/material.dart';

import 'package:svg_flutter/svg.dart';

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
  bool _isSvg = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;
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
    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.isSvgAvatar)
        .then((isSvg) {
          setState(() {
            _isSvg = isSvg ?? false;
          });
        });
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.avatarColor)
        .then((value) {
          setState(() {
            _r =
                int.tryParse(value?.split(",")[0] ?? "255") ??
                255; // Valor por defecto si no se encuentra
            _g = int.tryParse(value?.split(",")[1] ?? "255") ?? 255;
            _b = int.tryParse(value?.split(",")[2] ?? "255") ?? 255;
          });
        });
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
      final service = FinanceService.getInstance(
        SqliteService().db.monthDao,
        SqliteService().db.movementValueDao,
        SqliteService().db.fixedMovementDao,
      );
      await service.updateSelectedDate(widget.month, widget.year);
    } catch (e) {
      debugPrint('Error al cargar datos iniciales: $e');
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final userName =
        LoginService().currentUser?.displayName?.split(' ')[0] ?? '';
    final nameGreeting = userName.isNotEmpty ? ', $userName' : '';

    setState(() {
      if (hour < 12) {
        _greeting =
            '¡Buenos días$nameGreeting! ✨\nComienza el día con energía renovada';
      } else if (hour < 18) {
        _greeting =
            '¡Buenas tardes$nameGreeting! ☀️\nSigue construyendo tu futuro financiero';
      } else {
        _greeting =
            '¡Buenas noches$nameGreeting! 🌟\nMomento perfecto para revisar tus finanzas';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Card(
        color: Theme.of(context).colorScheme.secondary.withAlpha(25),
        elevation: 8,
        shape: const CircleBorder(),
        child: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: FloatingActionButton.small(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                useSafeArea: true,
                builder: (BuildContext context) => const MovementFormScreen(),
              );
            },
            child: const Icon(Icons.add),
            heroTag: 'home_fab',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGreetingsPart(),
              const SizedBox(height: 24),
              _buildTotalPart(),
              const SizedBox(height: 8),
              _buildLastInteractionsPart(),
              const SizedBox(height: 8),
              _ChartPart(_moneda),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingsPart() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child:
              _isSvg
                  ? SvgPicture.asset(
                    height: 120,
                    width: 120,
                    'assets/logo.svg',
                    color: Color.fromARGB(255, _r, _g, _b),
                  )
                  : Image.asset('assets/logo.png'),
        ),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _greeting,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLastInteractionsPart() {
    final service = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        final movements = service.todayMovements;

        return Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
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
                      return MovementCard(
                        description: movement.description,
                        amount: movement.amount,
                        isExpense: movement.isExpense,
                        category: movement.category,
                        moneda: _moneda,
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
    final service = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        final total = service.monthTotal;
        final isPositive = total >= 0;

        return Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
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
  const _ChartPart(this.moneda);
  final String moneda;

  Map<String, double> _calculateCategoryPercentages(
    List<MovementValue> expenses,
  ) {
    final categoryTotals = <String, double>{};
    for (var tag in TagList) {
      categoryTotals[tag] = 0;
    }

    // Calculate totals for each category
    for (var movement in expenses) {
      if (movement.category != null) {
        categoryTotals[movement.category!] =
            (categoryTotals[movement.category!] ?? 0) + movement.amount;
      }
    } // Ordenar por monto en lugar de porcentaje
    final sortedEntries =
        categoryTotals.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Tomar solo las 3 primeras categorías
    return Map.fromEntries(sortedEntries.take(3));
  }

  @override
  Widget build(BuildContext context) {
    final service = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (service.currentMonth == null) return const SizedBox.shrink();

        return FutureBuilder<List<MovementValue>>(
          future: service.getMovementsForMonth(
            service.currentMonth!.month,
            service.currentMonth!.year,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const SizedBox.shrink();

            final movements = snapshot.data!;
            final expenses = movements.where((m) => m.isExpense).toList();
            final categoryData = _calculateCategoryPercentages(expenses);

            return Card(
              color: Theme.of(context).colorScheme.secondary.withAlpha(25),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gastos por Categoría',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    HomeCategoryChart(
                      categoryData: categoryData,
                      moneda: moneda,
                    ),
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

class HomeCategoryChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final String moneda;

  const HomeCategoryChart({
    super.key,
    required this.categoryData,
    required this.moneda,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular el total para los porcentajes
    final total = categoryData.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return Column(
      children:
          categoryData.entries.map((entry) {
            final category = entry.key;
            final amount = entry.value;
            final percentage = total > 0 ? (amount / total) * 100 : 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category),
                      Row(
                        children: [
                          Text(
                            '${amount.toStringAsFixed(2)}$moneda',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      HSLColor.fromColor(
                        Theme.of(context).colorScheme.primary,
                      ).withLightness(0.5).toColor(),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
