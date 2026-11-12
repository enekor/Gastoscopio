import 'dart:math' as math;

import 'package:cashly/common/money_format.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/credit_card/logic/credit_card_service.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/view_movements_filtered_screen.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/modules/notifications/screens/pending_notifications_screen.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:cashly/theme/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  String? _moneda;
  bool _dataLoaded = false;

  DebtViewItem? _nextDebt;
  bool _hasCredit = false;
  double _creditAvailable = 0;

  bool _isLoadingCards = false;
  bool _reloadCardsQueued = false;

  late final FinanceService _service = FinanceService.getInstance(
    SqliteService().db.monthDao,
    SqliteService().db.movementValueDao,
    SqliteService().db.fixedMovementDao,
  );

  bool get _isReady => _dataLoaded && _moneda != null;
  String get _currency => _moneda ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Any change in the month data (new/edited/deleted movement, paid debt…)
    // also refreshes the debt and card summaries.
    _service.addListener(_onFinanceChanged);
    _loadInitialData().then((_) {
      if (!mounted) return;
      setState(() => _dataLoaded = true);
      _loadCards();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotifications();
    });
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = SharedPreferencesService();
    final currency = await prefs.getStringValue(SharedPreferencesKeys.currency);
    final listenerEnabled = await prefs
        .getBoolValue(SharedPreferencesKeys.notificationListenerEnabled);
    final bannerDismissed = await prefs
        .getBoolValue(SharedPreferencesKeys.notificationBannerDismissed);
    if (!mounted) return;
    setState(() {
      _moneda = currency ?? '€';
      _showNotificationBanner =
          listenerEnabled != true && bannerDismissed != true;
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
    _service.removeListener(_onFinanceChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNotifications();
      _loadCards();
    }
  }

  void _onFinanceChanged() {
    if (_dataLoaded) _loadCards();
  }

  Future<void> _refreshAll() async {
    await _loadInitialData();
    await Future.wait([_loadCards(), _checkPendingNotifications()]);
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

  /// Due date of a debt occurrence, clamped to the last day of its month
  /// (a debt due on the 31st falls on the 30th in a 30-day month).
  DateTime _dueDate(DebtViewItem debt) {
    final year = debt.month.year;
    final month = debt.month.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, math.min(debt.occurrence.dueDay, lastDay));
  }

  Future<void> _loadCards() async {
    // Coalesce bursts of change notifications into a single extra reload.
    if (_isLoadingCards) {
      _reloadCardsQueued = true;
      return;
    }
    _isLoadingCards = true;
    try {
      final debts = await _service.getVisiblePendingDebtsForCurrentMonth();
      debts.sort((a, b) => _dueDate(a).compareTo(_dueDate(b)));
      final cc = CreditCardService.getInstance();
      await cc.loadMonthData(widget.month, widget.year);
      if (!mounted) return;
      setState(() {
        _nextDebt = debts.isNotEmpty ? debts.first : null;
        _hasCredit = cc.currentMonth != null;
        _creditAvailable = cc.remainingAmount;
      });
    } catch (e) {
      LogFileService().appendLog('Error loading home cards: $e');
    } finally {
      _isLoadingCards = false;
      if (_reloadCardsQueued && mounted) {
        _reloadCardsQueued = false;
        _loadCards();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        key: const PageStorageKey<String>('home_scroll'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_pendingNotificationsCount > 0) ...[
                  _buildPendingNotificationsBanner(),
                  const SizedBox(height: 12),
                ],
                if (_showNotificationBanner) ...[
                  _buildNotificationReminderBanner(),
                  const SizedBox(height: 12),
                ],
                _buildBalanceCard(),
                const SizedBox(height: 16),
                _buildIncomeExpenseRow(),
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
            sliver: _buildRecentMovementsSliver(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(child: _buildBottomCards()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            sliver: SliverToBoxAdapter(child: _buildTopCategories()),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Balance + income/expense
  // ---------------------------------------------------------------------------

  Widget _buildBalanceCard() {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) {
        final total = _service.monthTotal;
        final color = total > 0
            ? glass.incomeColor
            : total < 0
                ? glass.expenseColor
                : scheme.onSurface;
        final hint = _balanceHint(total, l);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                l.totalBalance.toUpperCase(),
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
                    amount: total,
                    currency: _currency,
                    fontSize: 72,
                    color: color,
                  ),
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: glass.mutedText, fontSize: 13),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Context line under the balance: daily allowance for the rest of the
  /// current month, or a warning when the month is in the red.
  String? _balanceHint(double total, AppLocalizations l) {
    if (total < 0) return l.overspentThisMonth;
    final now = DateTime.now();
    final isCurrentMonth =
        widget.month == now.month && widget.year == now.year;
    if (!isCurrentMonth || total <= 0) return null;
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = lastDay - now.day + 1;
    return l.dailyAllowance(
      formatMoney(context, total / daysLeft, _currency),
      daysLeft,
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
              currency: _currency,
              icon: Icons.arrow_downward,
              isIncome: true,
              onTap: () => _openFiltered(isExpense: false),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatTile(
              label: AppLocalizations.of(context)!.expenses,
              amount: _service.monthExpenses,
              currency: _currency,
              icon: Icons.arrow_upward,
              isIncome: false,
              onTap: () => _openFiltered(isExpense: true),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFiltered({required bool isExpense}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewMovementsFilteredScreen(
          initialIsExpense: isExpense,
          initialMonth: widget.month,
          initialYear: widget.year,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Banners (shared layout)
  // ---------------------------------------------------------------------------

  Widget _banner({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onDismiss,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: glass.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: glass.mutedText),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onDismiss,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: glass.mutedText),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingNotificationsBanner() {
    final localizations = AppLocalizations.of(context)!;
    return _banner(
      icon: Icons.notifications_active,
      title: localizations.pendingNotifications,
      subtitle: localizations.pendingTransactions(_pendingNotificationsCount),
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
    );
  }

  Widget _buildNotificationReminderBanner() {
    final l = AppLocalizations.of(context)!;
    return _banner(
      icon: Icons.notifications_active_outlined,
      title: l.notificationBannerTitle,
      subtitle: l.notificationBannerSubtitle,
      onTap: () async {
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
      onDismiss: () {
        setState(() {
          _showNotificationBanner = false;
        });
        SharedPreferencesService().setBoolValue(
          SharedPreferencesKeys.notificationBannerDismissed,
          true,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Latest movements
  // ---------------------------------------------------------------------------

  Widget _buildRecentMovementsSliver() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _service,
        builder: (context, child) {
          final movements = _service.recentMovements;
          if (movements.isEmpty) {
            return _buildRecentEmptyState();
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

  Widget _buildRecentEmptyState() {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final l = AppLocalizations.of(context)!;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, color: glass.mutedText, size: 32),
          const SizedBox(height: 8),
          Text(
            l.noMovementsThisMonth,
            textAlign: TextAlign.center,
            style: TextStyle(color: glass.mutedText),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _openNewMovement,
            icon: const Icon(Icons.add),
            label: Text(l.addFirstMovement),
          ),
        ],
      ),
    );
  }

  Future<void> _openNewMovement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovementFormScreen(asScreen: true)),
    );
    await _loadInitialData();
  }

  Future<void> _editMovement(MovementValue movement) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => MovementFormScreen(movement: movement),
    );
    if (result == true) {
      await _loadInitialData();
    }
  }

  String _categoryIconPath(String? category) {
    if (category == null || category.isEmpty) {
      return 'assets/icons/miscellaneous.svg';
    }
    try {
      return getIconPath(category);
    } catch (_) {
      return 'assets/icons/miscellaneous.svg';
    }
  }

  Widget _categoryIcon(String? category, {double size = 44}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size / 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        _categoryIconPath(category),
        colorFilter: ColorFilter.mode(
          scheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _movementRow(MovementValue movement) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _editMovement(movement),
      child: Row(
        children: [
          _categoryIcon(movement.category),
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
            currency: _currency,
            isExpense: movement.isExpense,
            signed: true,
            fontSize: 15,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top expense categories
  // ---------------------------------------------------------------------------

  Widget _buildTopCategories() {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) {
        final entries = _service.expenseCategoryTotals.entries
            .where((e) => e.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        if (entries.isEmpty) return const SizedBox.shrink();
        final top = entries.take(3).toList();
        final totalExpenses = _service.monthExpenses;
        final l = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              title: l.expensesByCategory,
              actionLabel: l.seeAll,
              onAction: () => widget.onNavigateTab?.call(3),
            ),
            const SizedBox(height: 4),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _categoryBar(
                      top[i].key,
                      top[i].value,
                      totalExpenses > 0 ? top[i].value / totalExpenses : 0,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryBar(String category, double amount, double fraction) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Row(
      children: [
        _categoryIcon(category, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formatMoney(context, amount, _currency),
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(glass.expenseColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Debts + credit card
  // ---------------------------------------------------------------------------

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

  Future<void> _payDebt(DebtViewItem debt) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.payDebtConfirmTitle),
            content: Text(
              l.payDebtConfirmBody(
                formatMoney(context, debt.definition.amount, _currency),
                debt.definition.description,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l.pay),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      // completeDebtOccurrence notifies listeners, which reloads the cards.
      await _service.completeDebtOccurrence(debt.occurrence);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.debtCompletedMovementCreated),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      LogFileService().appendLog('Error completing debt from home: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.debtCompleteError(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildVencimientoCard() {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final l = AppLocalizations.of(context)!;
    final debt = _nextDebt;

    String? daysLabel;
    if (debt != null) {
      final today = DateTime.now();
      final days = _dueDate(debt)
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
              Expanded(
                child: Text(
                  l.navDebts,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: glass.mutedText),
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
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AmountText(
                amount: debt.definition.amount,
                currency: _currency,
                fontSize: 22,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => _payDebt(debt),
                style: FilledButton.styleFrom(
                  foregroundColor: glass.expenseColor,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(l.pay),
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
              Expanded(
                child: Text(
                  l.cardLabel,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(Icons.credit_card, size: 18, color: glass.mutedText),
            ],
          ),
          const SizedBox(height: 24),
          if (_hasCredit) ...[
            Text(
              l.available,
              style: TextStyle(color: glass.mutedText, fontSize: 12),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AmountText(
                amount: _creditAvailable,
                currency: _currency,
                fontSize: 22,
                color: _creditAvailable < 0
                    ? glass.expenseColor
                    : glass.incomeColor,
              ),
            ),
          ] else
            Row(
              children: [
                Icon(Icons.add_card, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.setUpCard,
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
