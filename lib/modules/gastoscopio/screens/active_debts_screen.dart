import 'package:cashly/data/models/debt_definition.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/app_background.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/glass_button.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:cashly/theme/widgets/section_header.dart';
import 'package:flutter/material.dart';

class ActiveDebtsScreen extends StatefulWidget {
  /// When embedded in the bottom-nav tab, the screen renders content only
  /// (no Scaffold/AppBar/background — those are provided by MainScreen).
  final bool embedded;
  const ActiveDebtsScreen({super.key, this.embedded = false});

  @override
  State<ActiveDebtsScreen> createState() => _ActiveDebtsScreenState();
}

class _ActiveDebtsScreenState extends State<ActiveDebtsScreen> {
  late final FinanceService _financeService;
  List<DebtViewItem> _pendingDebts = [];
  bool _isLoading = true;
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then((value) {
          if (!mounted) return;
          setState(() {
            _currency = value ?? '€';
          });
        });
    _loadPendingDebts();
  }

  Future<void> _loadPendingDebts() async {
    try {
      final pending =
          await _financeService.getVisiblePendingDebtsForCurrentMonth();
      if (!mounted) return;
      setState(() {
        _pendingDebts = pending;
        _isLoading = false;
      });
    } catch (e) {
      LogFileService().appendLog('Error loading active debts: $e');
      if (!mounted) return;
      setState(() {
        _pendingDebts = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.debtLoadError(e.toString())),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _completeDebt(DebtViewItem debt) async {
    try {
      await _financeService.completeDebtOccurrence(debt.occurrence);
      await _loadPendingDebts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.debtCompletedMovementCreated,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      LogFileService().appendLog('Error completing active debt: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.debtCompleteError(e.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _isOverdue(DebtViewItem debt) {
    final currentMonth = _financeService.currentMonth;
    if (currentMonth == null) return false;
    return debt.occurrence.originYear < currentMonth.year ||
        (debt.occurrence.originYear == currentMonth.year &&
            debt.occurrence.originMonth < currentMonth.month);
  }

  Future<void> _createMonthlyDebt() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FixedMovementsScreen()),
    );
    await _loadPendingDebts();
  }

  Future<void> _createOneTimeDebt() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovementFormScreen(
          forceDebtMode: true,
          isExpense: true,
          asScreen: true,
        ),
      ),
    );
    await _loadPendingDebts();
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(AppLocalizations.of(context)!.activeDebts),
      ),
      body: AppBackground(child: SafeArea(child: content)),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return Center(child: Loading(context));
    }

    final overdue = _pendingDebts.where(_isOverdue).toList();
    final recurring = _pendingDebts
        .where((d) =>
            !_isOverdue(d) &&
            d.definition.recurrenceType == debtRecurrenceMonthly)
        .toList();
    final oneTime = _pendingDebts
        .where((d) =>
            !_isOverdue(d) &&
            d.definition.recurrenceType == debtRecurrenceOneTime)
        .toList();

    final totalPending = _pendingDebts.fold<double>(
      0,
      (sum, d) => sum + d.definition.amount,
    );

    return RefreshIndicator(
      onRefresh: _loadPendingDebts,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _buildHeaderCard(totalPending),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  icon: Icons.repeat,
                  label: AppLocalizations.of(context)!.createMonthlyDebt,
                  onPressed: _createMonthlyDebt,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GlassButton(
                  icon: Icons.request_page_outlined,
                  label: AppLocalizations.of(context)!.createDebt,
                  onPressed: _createOneTimeDebt,
                ),
              ),
            ],
          ),
          if (_pendingDebts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noPendingDebtsThisMonth,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (overdue.isNotEmpty) ...[
            _sectionTitle(
              context,
              AppLocalizations.of(context)!.previousMonth,
              urgent: true,
            ),
            ...overdue.map((d) => _debtRow(d, overdue: true)),
          ],
          if (recurring.isNotEmpty) ...[
            SectionHeader(title: AppLocalizations.of(context)!.recurrents),
            ...recurring.map((d) => _debtRow(d)),
          ],
          if (oneTime.isNotEmpty) ...[
            SectionHeader(title: AppLocalizations.of(context)!.oneTimeDebts),
            ...oneTime.map((d) => _debtRow(d)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(double totalPending) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.totalPending.toUpperCase(),
            style: TextStyle(
              color: glass.mutedText,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          AmountText(amount: totalPending, currency: _currency, fontSize: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {bool urgent = false}) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (urgent) ...[
            Icon(Icons.warning_amber_rounded, color: glass.expenseColor, size: 20),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (urgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: glass.expenseColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppLocalizations.of(context)!.urgent,
                style: TextStyle(
                  color: scheme.onError,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _debtRow(DebtViewItem debt, {bool overdue = false}) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final isExpense = debt.definition.isExpense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: overdue
                    ? glass.expenseColor.withValues(alpha: 0.15)
                    : scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isExpense ? Icons.credit_card : Icons.payments_outlined,
                size: 20,
                color: overdue ? glass.expenseColor : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.definition.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.createdInMonth(
                      debt.occurrence.originMonth.toString().padLeft(2, '0'),
                      debt.occurrence.originYear.toString(),
                    ),
                    style: TextStyle(color: glass.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  amount: debt.definition.amount,
                  currency: _currency,
                  isExpense: isExpense,
                  signed: true,
                  fontSize: 16,
                ),
                const SizedBox(height: 8),
                PrimaryPillButton(
                  label: overdue
                      ? AppLocalizations.of(context)!.resolve
                      : AppLocalizations.of(context)!.pay,
                  expand: false,
                  onPressed: () => _completeDebt(debt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
