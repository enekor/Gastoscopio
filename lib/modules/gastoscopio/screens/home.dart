import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
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
    this.onNavigateTab,
  }) : super(key: key);
  final int year;
  final int month;

  /// Switches the MainScreen bottom-nav tab (0 Inicio, 1 Historial, 2 Gestión,
  /// 3 Estadísticas).
  final void Function(int index)? onNavigateTab;

  @override
  State<GastoscopioHomeScreen> createState() => _GastoscopioHomeScreenState();
}

class _GastoscopioHomeScreenState extends State<GastoscopioHomeScreen>
    with WidgetsBindingObserver {
  bool _isCheckingPending = false;
  int _pendingNotificationsCount = 0;
  bool _showNotificationBanner = false;
  late String _moneda = '';

  DebtViewItem? _nextDebt;
  bool _hasCredit = false;
  double _creditAvailable = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData().then((_) {
      if (mounted) _loadCards();
    });
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
      _loadInitialData().then((_) {
        if (mounted) _loadCards();
      });
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
      await _service.updateSelectedDate(widget.month, widget.year);
    } catch (e) {
      debugPrint('Error al cargar datos iniciales: $e');
      LogFileService().appendLog('Error al cargar datos iniciales: $e');
    }
  }

  Future<void> _loadCards() async {
    try {
      final debts = await _service.getVisiblePendingDebtsForCurrentMonth();
      final cc = CreditCardService.getInstance();
      final now = DateTime.now();
      await cc.loadMonthData(now.month, now.year);
      if (!mounted) return;
      setState(() {
        _nextDebt = debts.isNotEmpty ? debts.first : null;
        _hasCredit = cc.currentMonth != null;
        _creditAvailable = cc.remainingAmount;
      });
    } catch (e) {
      LogFileService().appendLog('Error loading home cards: $e');
    }
  }

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
              SectionHeader(
                title: AppLocalizations.of(context)!.recentExpenses,
                actionLabel: AppLocalizations.of(context)!.seeAll,
                onAction: () => widget.onNavigateTab?.call(1),
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          sliver: SliverToBoxAdapter(child: _buildBottomCards()),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.totalBalance.toUpperCase(),
                style: TextStyle(
                  color: glass.mutedText,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AmountText(
                    amount: _service.monthTotal,
                    currency: _moneda,
                    fontSize: 72,
                  ),
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
              label: AppLocalizations.of(context)!.incomes,
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
                  localizations.pendingTransactions(_pendingNotificationsCount),
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

  Widget _buildBottomCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildVencimientoCard()),
          const SizedBox(width: 12),
          Expanded(child: _buildBilleteraCard()),
        ],
      ),
    );
  }

  Widget _buildVencimientoCard() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final l = AppLocalizations.of(context)!;
    final debt = _nextDebt;

    String? daysLabel;
    if (debt != null) {
      final due = DateTime(
        debt.month.year,
        debt.month.month,
        debt.occurrence.dueDay,
      );
      final today = DateTime.now();
      final days = due
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      daysLabel = days < 0
          ? l.urgent
          : days == 0
              ? l.today
              : '$days ${l.days}';
    }

    return GlassCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ActiveDebtsScreen()),
        );
        _loadCards();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.navDebts,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (debt == null)
            Text(
              l.noPendingDebtsThisMonth,
              style: TextStyle(color: glass.mutedText, fontSize: 13),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: glass.expenseColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 12, color: glass.expenseColor),
                  const SizedBox(width: 4),
                  Text(
                    daysLabel ?? '',
                    style: TextStyle(
                      color: glass.expenseColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              debt.definition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            AmountText(
              amount: debt.definition.amount,
              currency: _moneda,
              fontSize: 22,
            ),
            const SizedBox(height: 4),
            Text(
              l.pay,
              style: TextStyle(
                color: glass.expenseColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBilleteraCard() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreditCardScreen()),
        );
        _loadCards();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.cardLabel,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.credit_card, size: 18, color: glass.mutedText),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l.available,
            style: TextStyle(color: glass.mutedText, fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (_hasCredit)
            AmountText(
              amount: _creditAvailable,
              currency: _moneda,
              fontSize: 22,
              color: glass.incomeColor,
            )
          else
            Text(
              '—',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
