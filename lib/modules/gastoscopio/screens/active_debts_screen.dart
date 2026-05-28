import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/screens/fixed_movements_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ActiveDebtsScreen extends StatefulWidget {
  const ActiveDebtsScreen({super.key});

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
      final pending = await _financeService.getVisiblePendingDebtsForCurrentMonth();
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

  @override
  Widget build(BuildContext context) {
    final currentMonth = _financeService.currentMonth;
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadPendingDebts,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text(AppLocalizations.of(context)!.activeDebts),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FixedMovementsScreen(),
                            ),
                          );
                          await _loadPendingDebts();
                        },
                        icon: const Icon(Icons.repeat),
                        label: Text(AppLocalizations.of(context)!.createMonthlyDebt),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await showModalBottomSheet<bool>(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            useSafeArea: true,
                            builder: (context) => MovementFormScreen(
                              forceDebtMode: true,
                              isExpense: true,
                            ),
                          );
                          await _loadPendingDebts();
                        },
                        icon: const Icon(Icons.request_page_outlined),
                        label: Text(AppLocalizations.of(context)!.createDebt),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Loading(context)),
              )
            else if (_pendingDebts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      AppLocalizations.of(context)!.noPendingDebtsThisMonth,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final debt = _pendingDebts[index];
                    final isPropagated =
                        currentMonth != null &&
                        (debt.occurrence.originYear < currentMonth.year ||
                            (debt.occurrence.originYear == currentMonth.year &&
                                debt.occurrence.originMonth < currentMonth.month));
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              debt.definition.isExpense
                                  ? Icons.money_off
                                  : Icons.payments_outlined,
                              color: debt.definition.isExpense
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    debt.definition.description,
                                    style: Theme.of(context).textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      Chip(
                                        label: Text(
                                          AppLocalizations.of(context)!
                                              .createdInMonth(
                                                debt.occurrence.originMonth
                                                    .toString()
                                                    .padLeft(2, '0'),
                                                debt.occurrence.originYear
                                                    .toString(),
                                              ),
                                        ),
                                      ),
                                      if (isPropagated)
                                        Chip(
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .propagatedDebt,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${debt.definition.isExpense ? '-' : '+'}${debt.definition.amount.toStringAsFixed(2)}$_currency',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: debt.definition.isExpense
                                            ? Colors.red
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.tonal(
                                  onPressed: () => _completeDebt(debt),
                                  child: Text(
                                    AppLocalizations.of(context)!.completed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _pendingDebts.length),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
