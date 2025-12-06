import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/summary_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/finance_widgets.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/modules/saves/home_saves.dart';
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
  String _greetingTitle = '';
  String _greetingSubtitle = ''; // Separé el saludo para mejor estilo
  bool _isSvg = false;
  bool _isOpaqueBottomNav = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;
  late String _moneda = '';
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _showIaBanner = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
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
            _r = int.tryParse(value?.split(",")[0] ?? "255") ?? 255;
            _g = int.tryParse(value?.split(",")[1] ?? "255") ?? 255;
            _b = int.tryParse(value?.split(",")[2] ?? "255") ?? 255;
          });
        });
    // IA API KEY
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.apiKey)
        .then((apiKey) {
          setState(() {
            _showIaBanner = (apiKey == null || apiKey.trim().isEmpty);
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

  bool _isLastDaysOfTheWeek() {
    DateTime today = DateTime.now();
    DateTime lastDayOfTheWeek = DateTime(
      today.year,
      today.month + 1,
      1,
    ).add(const Duration(days: -1));
    DateTime lastLimitDaysOfTheWeek = lastDayOfTheWeek.add(
      const Duration(days: -5),
    );

    return today.isAfter(lastLimitDaysOfTheWeek) &&
        (today.isBefore(lastDayOfTheWeek) ||
            today.isAtSameMomentAs(lastDayOfTheWeek));
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    final userName =
        LoginService().currentUser?.displayName?.split(' ')[0] ?? '';
    final nameGreeting = userName.isNotEmpty ? ', $userName' : '';

    if (mounted) {
      setState(() {
        if (hour < 12) {
          _greetingTitle =
              '¡${AppLocalizations.of(context)!.goodMorning}$nameGreeting!';
          _greetingSubtitle = AppLocalizations.of(context)!.startDayWithEnergy;
        } else if (hour < 18) {
          _greetingTitle =
              '¡${AppLocalizations.of(context)!.goodAfternoon}$nameGreeting!';
          _greetingSubtitle = AppLocalizations.of(
            context,
          )!.keepBuildingFinancialFuture;
        } else {
          _greetingTitle =
              '¡${AppLocalizations.of(context)!.goodEvening}$nameGreeting!';
          _greetingSubtitle = AppLocalizations.of(
            context,
          )!.perfectTimeToReviewFinances;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos un color primario local para usar en gradientes si el del tema es plano
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // Floating Action Button más moderno
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          child: const Icon(Icons.add_card, size: 28),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (BuildContext context) => MovementFormScreen(),
            );
          },

          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showIaBanner) ...[
                  _buildIaBanner(context),
                  const SizedBox(height: 16),
                ],
                _buildHeader(),
                const SizedBox(height: 20),
                _buildModernBalanceCard(primaryColor, secondaryColor),
                const SizedBox(height: 24),

                // Título de sección Acciones Rápidas
                Text(
                  AppLocalizations.of(
                    context,
                  )!.quickActions, // Puedes usar localizaciones aquí
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                _buildActionGrid(),
                const SizedBox(height: 12),
                // Título de sección Movimientos
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.lastMovements,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    // Icono opcional para "Ver todo" si quisieras implementarlo
                  ],
                ),
                const SizedBox(height: 12),
                _buildLastInteractionsPart(),

                const SizedBox(height: 24),
                _ChartPart(_moneda),
                // Espacio extra para que el FAB no tape contenido
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- NUEVO HEADER ---
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _greetingSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Avatar más pequeño y elegante
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            //color: Theme.of(context).colorScheme.surfaceVariant,
            shape: BoxShape.circle,
            // border: Border.all(
            //   color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            // ),
          ),
          child: ClipOval(
            child: _isSvg
                ? SvgPicture.asset(
                    'assets/logo.svg',
                    color: Color.fromARGB(255, _r, _g, _b),
                    fit: BoxFit.contain,
                  )
                : Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  // --- TARJETA DE BALANCE PRINCIPAL (MODERNA) ---
  Widget _buildModernBalanceCard(Color primary, Color secondary) {
    final service = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );

    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        final total = service.monthTotal;
        final incomes = service.monthIncomes;
        final expenses = service.monthExpenses;
        final isPositive = total >= 0;

        return Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                primary.withOpacity(0.7), // Gradiente sutil
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decoración de fondo (círculos abstractos)
              Positioned(
                right: -10,
                top: -10,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 20,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
              ),

              // Contenido
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          service.currentMonthName(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ),

                    // Carrusel Vertical para el Total / Desglose
                    Expanded(
                      child: CarouselSlider(
                        carouselController: _carouselController,
                        options: CarouselOptions(
                          scrollDirection: Axis.vertical,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: false,
                          height: 100, // Ajustar altura interna
                        ),
                        items: [
                          // Página 1: Balance Total
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.monthBalance,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${total < 0 ? '-' : ''}${total.abs().toStringAsFixed(2)}$_moneda',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _carouselController.nextPage(
                                    curve: Curves.easeOut,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.only(top: 5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Ver desglose",
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                            fontSize: 12,
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Página 2: Ingresos vs Gastos
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBalanceDetailItem(
                                Icons.arrow_downward,
                                "Ingresos",
                                incomes,
                                Colors.greenAccent,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white.withOpacity(0.3),
                              ),
                              _buildBalanceDetailItem(
                                Icons.arrow_upward,
                                "Gastos",
                                expenses,
                                Colors.redAccent.shade100,
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.arrow_drop_up,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                                onPressed: () => _carouselController
                                    .previousPage(curve: Curves.easeOut),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceDetailItem(
    IconData icon,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${amount.abs().toStringAsFixed(0)}$_moneda',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // --- GRID DE ACCIONES (Botones cuadrados modernos) ---
  Widget _buildActionGrid() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_isLastDaysOfTheWeek()) ...[
              _buildActionCard(
                icon: Icons.calendar_month_rounded,
                title: AppLocalizations.of(context)!.createNextMonth,
                color: Colors.teal,
                onTap: () async {
                  await FinanceService.getInstance(
                    SqliteService().db.monthDao,
                    SqliteService().db.movementValueDao,
                    SqliteService().db.fixedMovementDao,
                  ).createNextMonth(context);
                  setState(() {});
                },
              ),
            ],
            _buildActionCard(
              icon: Icons.repeat_rounded,
              title: AppLocalizations.of(context).manageRecurringMovements,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FixedMovementsScreen(),
                ),
              ),
            ),

            _buildActionCard(
              icon: Icons.savings_rounded,
              title: AppLocalizations.of(context).savings,
              color: Colors.amber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeSaves()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Usamos el color del tema actual para el fondo de las tarjetas
    final cardBg = Theme.of(context).colorScheme.primary.withAlpha(15);

    return SizedBox(
      width: 100,
      height: 110,
      child: Material(
        //color: cardBg,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(15),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 50),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- LISTA DE MOVIMIENTOS RECIENTES (Sin borde feo) ---
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

        if (movements.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 40,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.noMovementsToShow,
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: movements.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: Theme.of(context).dividerColor.withOpacity(0.2),
            ),
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
        );
      },
    );
  }

  // --- IA BANNER (Rediseñado ligeramente) ---
  Widget _buildIaBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => _showIaInfoDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade100, Colors.amber.shade200],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: Colors.amber.shade900,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.activateIaFeatures,
                style: TextStyle(
                  color: Colors.amber.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.amber.shade900),
          ],
        ),
      ),
    );
  }

  // (Mantengo tus funciones auxiliares como _showIaInfoDialog sin cambios mayores,
  // solo asegúrate de que existen en tu archivo o cópialas del anterior)
  void _showIaInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.flash_on, color: Colors.amber.shade800),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.iaFeaturesText),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.noIaFeaturesHomeTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noIaFeaturesHomeSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.amber.shade900),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.later),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return const SettingsScreen();
                  },
                ),
              );
            },
            child: Text(AppLocalizations.of(context)!.letsGo),
          ),
        ],
      ),
    );
  }
}

// --- CHART PART (Rediseñado para encajar en una tarjeta limpia) ---
class _ChartPart extends StatelessWidget {
  const _ChartPart(this.moneda);
  final String moneda;

  Map<String, double> _calculateCategoryPercentages(
    List<MovementValue> expenses,
    BuildContext context,
  ) {
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final categoryTotals = <String, double>{};
    for (var tag in localizedTags) {
      categoryTotals[tag] = 0;
    }
    for (var movement in expenses) {
      if (movement.category != null) {
        categoryTotals[movement.category!] =
            (categoryTotals[movement.category!] ?? 0) + movement.amount;
      }
    }
    final sortedEntries =
        categoryTotals.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
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
            final categoryData = _calculateCategoryPercentages(
              expenses,
              context,
            );

            if (categoryData.isEmpty) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                // Borde sutil en lugar de sombra pesada
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).expensesByCategory,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
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
    final total = categoryData.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return Column(
      children: categoryData.entries.map((entry) {
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
                  Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Barra de progreso más gruesa y redondeada
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${amount.toStringAsFixed(2)}$moneda',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
