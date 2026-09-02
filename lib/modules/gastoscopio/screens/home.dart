import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/view_movements_filtered_screen.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/modules/saves/home_saves.dart';
import 'package:cashly/modules/notifications/screens/pending_notifications_screen.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:cashly/theme/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

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

class _GastoscopioHomeScreenState extends State<GastoscopioHomeScreen>
    with WidgetsBindingObserver {
  bool _isCheckingPending = false;
  int _pendingNotificationsCount = 0;
  bool _showNotificationBanner = false;
  late String _moneda = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotifications();
    });
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.notificationListenerEnabled)
        .then((enabled) {
          setState(() {
            _showNotificationBanner = enabled != true;
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNotifications();
    }
  }

  Future<void> _checkPendingNotifications() async {
    if (_isCheckingPending) return;
    _isCheckingPending = true;
    try {
      final pendingCount = await SqliteService()
              .db
              .pendingNotificationMovementDao
              .countAll() ??
          0;
      if (!mounted) return;
      setState(() {
        _pendingNotificationsCount = pendingCount;
      });
    } catch (e) {
      LogFileService().appendLog(
        'Error checking pending notifications in home: $e',
      );
    } finally {
      _isCheckingPending = false;
    }
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

  bool _isLastDaysOfTheWeek() => DateTime.now().day >= 25;

  FinanceService get _service => FinanceService.getInstance(
        SqliteService().db.monthDao,
        SqliteService().db.movementValueDao,
        SqliteService().db.fixedMovementDao,
      );

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('home_scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_pendingNotificationsCount > 0) ...[
                _buildPendingNotificationsBanner(),
                const SizedBox(height: 16),
              ],
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildIncomeExpenseRow(),
              if (_showNotificationBanner) ...[
                const SizedBox(height: 16),
                _buildNotificationReminderBanner(),
              ],
              const SizedBox(height: 24),
              SectionHeader(title: AppLocalizations.of(context)!.quickAccess),
              const SizedBox(height: 4),
              _buildActionGrid(),
              const SizedBox(height: 12),
              SectionHeader(
                title: AppLocalizations.of(context)!.recentExpenses,
                actionLabel: AppLocalizations.of(context)!.seeAll,
                onAction: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewMovementsFilteredScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 4),
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
              children: [_ChartPart(_moneda), const SizedBox(height: 100)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) {
        return GlassCard(
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.totalBalance.toUpperCase(),
                style: TextStyle(
                  color: glass.mutedText,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AmountText(
                  amount: _service.monthTotal,
                  currency: _moneda,
                  fontSize: 44,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeExpenseRow() {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) => Row(
        children: [
          Expanded(
            child: StatTile(
              label: AppLocalizations.of(context)!.income,
              amount: _service.monthIncomes,
              currency: _moneda,
              icon: Icons.arrow_downward,
              isIncome: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              label: AppLocalizations.of(context)!.expenses,
              amount: _service.monthExpenses,
              currency: _moneda,
              icon: Icons.arrow_upward,
              isIncome: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsBanner() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final localizations = AppLocalizations.of(context)!;
    return GlassCard(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PendingNotificationsScreen(
              onComplete: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
        _checkPendingNotifications();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: scheme.onPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.pendingNotifications,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!
                      .pendingTransactions(_pendingNotificationsCount),
                  style: TextStyle(color: glass.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: glass.mutedText),
        ],
      ),
    );
  }

  Widget _buildNotificationReminderBanner() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined,
              color: scheme.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.notificationBannerTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.notificationBannerSubtitle,
                  style: TextStyle(color: glass.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: scheme.primary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              final enabled = await SharedPreferencesService().getBoolValue(
                SharedPreferencesKeys.notificationListenerEnabled,
              );
              if (mounted) {
                setState(() {
                  _showNotificationBanner = enabled != true;
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: glass.mutedText),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() {
                _showNotificationBanner = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final actions = <_QuickAction>[
      if (_isLastDaysOfTheWeek())
        _QuickAction(
          icon: Icons.calendar_month_rounded,
          title: AppLocalizations.of(context)!.createNextMonth,
          onTap: () async {
            await _service.createNextMonth(context);
            setState(() {});
          },
        ),
      _QuickAction(
        icon: Icons.repeat_rounded,
        title: AppLocalizations.of(context).manageRecurringMovements,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FixedMovementsScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.savings_rounded,
        title: AppLocalizations.of(context).savings,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeSaves()),
        ),
      ),
      _QuickAction(
        icon: Icons.credit_card,
        title: AppLocalizations.of(context)!.cardLabel,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreditCardScreen()),
        ),
      ),
      _QuickAction(
        icon: Icons.filter_alt_outlined,
        title: AppLocalizations.of(context).filteredMovements,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ViewMovementsFilteredScreen(),
          ),
        ),
      ),
    ];

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _buildActionCard(actions[index]),
      ),
    );
  }

  Widget _buildActionCard(_QuickAction action) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return SizedBox(
      width: 96,
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        onTap: action.onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: scheme.primary, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              action.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: glass.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastInteractionsSliver() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _service,
        builder: (context, child) {
          final movements = _service.todayMovements;
          if (movements.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            children: movements
                .map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _movementRow(m),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  Widget _movementRow(MovementValue movement) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long,
                size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (movement.category != null &&
                    movement.category!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    movement.category!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AmountText(
            amount: movement.amount,
            currency: _moneda,
            isExpense: movement.isExpense,
            signed: true,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  _QuickAction({required this.icon, required this.title, required this.onTap});
}

class _ChartPart extends StatelessWidget {
  const _ChartPart(this.moneda);
  final String moneda;

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
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final expenses = snapshot.data!.where((m) => m.isExpense).toList();
            if (expenses.isEmpty) return const SizedBox.shrink();
            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).expensesByCategory,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  HomeCategoryChart(
                    categoryData: _calculate(expenses, context),
                    moneda: moneda,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, double> _calculate(
    List<MovementValue> expenses,
    BuildContext context,
  ) {
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final totals = {for (var tag in localizedTags) tag: 0.0};
    for (var m in expenses) {
      if (m.category != null) {
        totals[m.category!] = (totals[m.category!] ?? 0) + m.amount;
      }
    }
    return Map.fromEntries(
      totals.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
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
    final total = categoryData.values.fold<double>(0, (sum, v) => sum + v);
    return Column(
      children: categoryData.entries.map((e) {
        final p = total > 0 ? (e.value / total) : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text(
                    '${(p * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: p,
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
