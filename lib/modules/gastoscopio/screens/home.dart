import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/summary_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/view_movements_filtered_screen.dart';
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
  String _greetingSubtitle = '';
  bool _isSvg = false;
  bool _isOpaqueBottomNav = false;
  int _r = 255;
  int _g = 255;
  int _b = 255;
  late String _moneda = '';
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _showIaBanner = false;
  String? _backgroundImagePath;

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
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.backgroundImage)
        .then((path) {
          setState(() {
            _backgroundImagePath = path;
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
      LogFileService().appendLog('Error al cargar datos iniciales: $e');
    }
  }

  bool _isLastDaysOfTheWeek() {
    DateTime today = DateTime.now();
    return today.day >= 25;
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final hasBackground =
        _backgroundImagePath != null && _backgroundImagePath!.isNotEmpty;

    return CustomScrollView(
      key: const PageStorageKey<String>('home_scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(hasBackground),
              const SizedBox(height: 20),
              _buildModernBalanceCard(primaryColor, secondaryColor),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.quickActions,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasBackground
                      ? Colors.white.withOpacity(0.9)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              _buildActionGrid(),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.lastMovements,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: _buildLastInteractionsSliver(),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _ChartPart(_moneda),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool hasBackground) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _greetingTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasBackground ? Colors.white : null,
                  shadows: hasBackground
                      ? [
                          const Shadow(
                            blurRadius: 10.0,
                            color: Colors.black54,
                            offset: Offset(2.0, 2.0),
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _greetingSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasBackground
                      ? Colors.white.withOpacity(0.9)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                  shadows: hasBackground
                      ? [
                          const Shadow(
                            blurRadius: 10.0,
                            color: Colors.black54,
                            offset: Offset(1.0, 1.0),
                          ),
                        ]
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          height: 60,
          width: 60,
          decoration: const BoxDecoration(shape: BoxShape.circle),
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

        return Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primary, primary.withOpacity(0.7)],
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
                    Expanded(
                      child: CarouselSlider(
                        carouselController: _carouselController,
                        options: CarouselOptions(
                          scrollDirection: Axis.vertical,
                          viewportFraction: 1.0,
                          enableInfiniteScroll: false,
                          height: 100,
                        ),
                        items: [
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
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildBalanceDetailItem(Icons.arrow_downward, "Ingresos", incomes, Colors.greenAccent),
                              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                              _buildBalanceDetailItem(Icons.arrow_upward, "Gastos", expenses, Colors.redAccent.shade100),
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

  Widget _buildBalanceDetailItem(IconData icon, String label, double amount, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text('${amount.abs().toStringAsFixed(0)}$_moneda', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  Widget _buildActionGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_isLastDaysOfTheWeek()) ...[
            _buildActionCard(
              icon: Icons.calendar_month_rounded,
              title: AppLocalizations.of(context)!.createNextMonth,
              color: Colors.teal,
              onTap: () async {
                await FinanceService.getInstance(SqliteService().db.monthDao, SqliteService().db.movementValueDao, SqliteService().db.fixedMovementDao).createNextMonth(context);
                setState(() {});
              },
            ),
            const SizedBox(width: 12),
          ],
          _buildActionCard(icon: Icons.repeat_rounded, title: AppLocalizations.of(context).manageRecurringMovements, color: Colors.blueAccent, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FixedMovementsScreen()))),
          const SizedBox(width: 12),
          _buildActionCard(icon: Icons.savings_rounded, title: AppLocalizations.of(context).savings, color: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => HomeSaves()))),
          const SizedBox(width: 12),
          _buildActionCard(icon: Icons.filter_alt, title: AppLocalizations.of(context).filteredMovements, color: Colors.grey, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewMovementsFilteredScreen()))),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: 100,
      height: 110,
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color, size: 40)),
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastInteractionsSliver() {
    final service = FinanceService.getInstance(SqliteService().db.monthDao, SqliteService().db.movementValueDao, SqliteService().db.fixedMovementDao);
    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        final movements = service.todayMovements;
        if (movements.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final movement = movements[index];
              return MovementCard(description: movement.description, amount: movement.amount, isExpense: movement.isExpense, category: movement.category, moneda: _moneda);
            },
            childCount: movements.length,
          ),
        );
      },
    );
  }
}

class _ChartPart extends StatelessWidget {
  const _ChartPart(this.moneda);
  final String moneda;

  @override
  Widget build(BuildContext context) {
    final service = FinanceService.getInstance(SqliteService().db.monthDao, SqliteService().db.movementValueDao, SqliteService().db.fixedMovementDao);
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (service.currentMonth == null) return const SizedBox.shrink();
        return FutureBuilder<List<MovementValue>>(
          future: service.getMovementsForMonth(service.currentMonth!.month, service.currentMonth!.year),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
            final expenses = snapshot.data!.where((m) => m.isExpense).toList();
            if (expenses.isEmpty) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).expensesByCategory, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  HomeCategoryChart(categoryData: _calculate(expenses, context), moneda: moneda),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _calculate(List<MovementValue> expenses, BuildContext context) {
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final totals = {for (var tag in localizedTags) tag: 0.0};
    for (var m in expenses) { if (m.category != null) totals[m.category!] = (totals[m.category!] ?? 0) + m.amount; }
    return Map.fromEntries(totals.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value)));
  }
}

class HomeCategoryChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final String moneda;
  const HomeCategoryChart({super.key, required this.categoryData, required this.moneda});
  @override
  Widget build(BuildContext context) {
    final total = categoryData.values.fold<double>(0, (sum, v) => sum + v);
    return Column(
      children: categoryData.entries.map((e) {
        final p = total > 0 ? (e.value / total) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.key), Text('${(p * 100).toStringAsFixed(1)}%', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: p, minHeight: 8, borderRadius: BorderRadius.circular(4)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
