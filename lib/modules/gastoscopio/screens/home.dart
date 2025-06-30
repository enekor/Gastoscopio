import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

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
  bool _isOpaqueBottomNav = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;
  late String _moneda = '';
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );

    // Load bottom navigation style configuration
    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
        .then(
          (isOpaque) => setState(() {
            _isOpaqueBottomNav = isOpaque ?? false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGreeting();
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

    if (mounted) {
      setState(() {
        if (hour < 12) {
          _greeting =
              '¡${AppLocalizations.of(context)!.goodMorning}$nameGreeting! ✨\n${AppLocalizations.of(context)!.startDayWithEnergy}';
        } else if (hour < 18) {
          _greeting =
              '¡${AppLocalizations.of(context)!.goodAfternoon}$nameGreeting! ☀️\n${AppLocalizations.of(context)!.keepBuildingFinancialFuture}';
        } else {
          _greeting =
              '¡${AppLocalizations.of(context)!.goodEvening}$nameGreeting! 🌟\n${AppLocalizations.of(context)!.perfectTimeToReviewFinances}';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Card(
        color:
            _isOpaqueBottomNav
                ? Theme.of(context).colorScheme.primary.withAlpha(200)
                : Theme.of(context).colorScheme.secondary.withAlpha(25),
        elevation: _isOpaqueBottomNav ? 4 : 8,
        shape: CircleBorder(
          side:
              _isOpaqueBottomNav
                  ? BorderSide.none
                  : BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
        ),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                _isOpaqueBottomNav
                    ? null
                    : Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      width: 2,
                    ),
          ),
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
            child: Icon(
              Icons.add,
              color:
                  _isOpaqueBottomNav
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
            ),
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
              const SizedBox(height: 30),
              SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(flex: 5, child: _buildTotalPart()),
                    Expanded(flex: 5, child: _buildLastInteractionsPart()),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFixedMovementsButton(),
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
        _isSvg
            ? SvgPicture.asset(
              height: 140,
              width: 140,
              'assets/logo.svg',
              color: Color.fromARGB(255, _r, _g, _b),
            )
            : Image.asset('assets/logo.png', height: 140, width: 140),
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

  Widget _buildFixedMovementsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixedMovementsScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.repeat,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              AppLocalizations.of(context)!.manageRecurringMovements,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.secondary.withAlpha(25),
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              elevation: 1,
            ),
          ),
        ),
      ),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.lastMovements,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withAlpha(90),
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (movements.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Center(
                              child: Text(
                                AppLocalizations.of(context)!.noMovementsToShow,
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
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
                ),
              ),
            ),
          ],
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

    Widget _firstPage(double total, bool isPositive) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(service.currentMonthName()),

        Text(
          '${AppLocalizations.of(context)!.total}: ${total < 0 ? '-' : ''}${total.abs().toStringAsFixed(2)}${_moneda}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color:
                isPositive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        InkWell(
          onTap:
              () => setState(() {
                _carouselController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
          child: Icon(Icons.expand_more),
        ),
      ],
    );

    Widget _secondPage(double incomes, double expenses) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap:
              () => setState(() {
                _carouselController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }),
          child: Icon(
            Icons.expand_less,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          '${AppLocalizations.of(context)!.incomes}: ${incomes.abs().toStringAsFixed(2)}${_moneda}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${AppLocalizations.of(context)!.expenses}: -${expenses.abs().toStringAsFixed(2)}${_moneda}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        final total = service.monthTotal;
        final incomes = service.monthIncomes;
        final expenses = service.monthExpenses;
        final isPositive = total >= 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.monthBalance,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Card(
                color: Theme.of(context).colorScheme.secondary.withAlpha(25),
                child: Center(
                  child: CarouselSlider(
                    carouselController: _carouselController,
                    options: CarouselOptions(
                      scrollDirection: Axis.vertical,
                      height: 280,
                      viewportFraction: 0.9,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                      autoPlay: false,
                      pageSnapping: true,
                      padEnds: true,
                    ),
                    items: [
                      _firstPage(total, isPositive),
                      _secondPage(incomes, expenses),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                      AppLocalizations.of(context)!.expensesByCategory,
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
