import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:svg_flutter/svg.dart';

class MonthComparisonView extends StatefulWidget {
  final FinanceService financeService;
  final int month;
  final int year;

  const MonthComparisonView({
    super.key,
    required this.financeService,
    required this.month,
    required this.year,
  });

  @override
  State<MonthComparisonView> createState() => _MonthComparisonViewState();
}

class _MonthComparisonViewState extends State<MonthComparisonView> {
  List<MovementValue> _current = [];
  List<MovementValue> _previous = [];
  bool _isLoading = true;
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MonthComparisonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month || oldWidget.year != widget.year) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final prev = _previousMonth(widget.month, widget.year);
    final current = await widget.financeService
        .getMovementsForMonth(widget.month, widget.year);
    final previous = await widget.financeService
        .getMovementsForMonth(prev.month, prev.year);
    final currency = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency);

    if (!mounted) return;
    setState(() {
      _current = current;
      _previous = previous;
      _currency = currency ?? '€';
      _isLoading = false;
    });
  }

  ({int month, int year}) _previousMonth(int month, int year) {
    if (month == 1) return (month: 12, year: year - 1);
    return (month: month - 1, year: year);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: Loading(context));
    }

    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prev = _previousMonth(widget.month, widget.year);

    final currentExpenses = _sum(_current, isExpense: true);
    final previousExpenses = _sum(_previous, isExpense: true);
    final currentIncome = _sum(_current, isExpense: false);
    final previousIncome = _sum(_previous, isExpense: false);
    final currentBalance = currentIncome - currentExpenses;
    final previousBalance = previousIncome - previousExpenses;

    final byCategory = _deltaByCategory(_current, _previous);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHeader(context, prev),
              const SizedBox(height: 20),
              _buildTotalsCard(
                context,
                expenses: (currentExpenses, previousExpenses),
                income: (currentIncome, previousIncome),
                balance: (currentBalance, previousBalance),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.comparisonByCategory,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (byCategory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      localizations.comparisonNoData,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ...byCategory.map((c) => _buildCategoryRow(context, c)),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  double _sum(List<MovementValue> items, {required bool isExpense}) {
    return items
        .where((m) => m.isExpense == isExpense)
        .fold<double>(0, (a, b) => a + b.amount);
  }

  List<_CategoryDelta> _deltaByCategory(
    List<MovementValue> current,
    List<MovementValue> previous,
  ) {
    final curMap = <String, double>{};
    for (final m in current.where((m) => m.isExpense)) {
      final c = m.category ?? '—';
      curMap[c] = (curMap[c] ?? 0) + m.amount;
    }
    final prevMap = <String, double>{};
    for (final m in previous.where((m) => m.isExpense)) {
      final c = m.category ?? '—';
      prevMap[c] = (prevMap[c] ?? 0) + m.amount;
    }
    final keys = <String>{...curMap.keys, ...prevMap.keys};
    final list = keys
        .map((k) => _CategoryDelta(
              category: k,
              current: curMap[k] ?? 0,
              previous: prevMap[k] ?? 0,
            ))
        .where((d) => d.current > 0 || d.previous > 0)
        .toList();
    list.sort((a, b) => b.current.compareTo(a.current));
    return list;
  }

  Widget _buildHeader(BuildContext context, ({int month, int year}) prev) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              localizations.comparisonDescription(
                _monthName(context, prev.month),
                prev.year.toString(),
                _monthName(context, widget.month),
                widget.year.toString(),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsCard(
    BuildContext context, {
    required (double, double) expenses,
    required (double, double) income,
    required (double, double) balance,
  }) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return Card(
      color: theme.colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow(
              context,
              label: localizations.incomes,
              current: income.$1,
              previous: income.$2,
              positiveIsGood: true,
              icon: Icons.arrow_upward,
              color: Colors.green,
            ),
            const Divider(height: 24),
            _buildTotalRow(
              context,
              label: localizations.expenses,
              current: expenses.$1,
              previous: expenses.$2,
              positiveIsGood: false,
              icon: Icons.arrow_downward,
              color: theme.colorScheme.error,
            ),
            const Divider(height: 24),
            _buildTotalRow(
              context,
              label: localizations.balance,
              current: balance.$1,
              previous: balance.$2,
              positiveIsGood: true,
              icon: Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(
    BuildContext context, {
    required String label,
    required double current,
    required double previous,
    required bool positiveIsGood,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final delta = current - previous;
    final pct = previous.abs() > 0.01 ? (delta / previous.abs()) * 100 : null;
    final isImprovement = positiveIsGood ? delta >= 0 : delta <= 0;
    final changeColor = delta.abs() < 0.01
        ? theme.colorScheme.onSurfaceVariant
        : (isImprovement ? Colors.green : theme.colorScheme.error);

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${previous.toStringAsFixed(2)}$_currency',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_right_alt,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    '${current.toStringAsFixed(2)}$_currency',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (delta.abs() >= 0.01)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 14,
                  color: changeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  pct != null
                      ? '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%'
                      : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(0)}$_currency',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: changeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, _CategoryDelta d) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final delta = d.current - d.previous;
    final pct = d.previous.abs() > 0.01 ? (delta / d.previous.abs()) * 100 : null;
    final isIncrease = delta > 0.01;
    final isDecrease = delta < -0.01;
    final color = isIncrease
        ? theme.colorScheme.error
        : isDecrease
            ? Colors.green
            : theme.colorScheme.onSurfaceVariant;

    String? iconPath;
    try {
      iconPath = getIconPath(d.category);
    } catch (_) {
      iconPath = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: iconPath != null
                ? SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    Icons.category_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${d.previous.toStringAsFixed(0)}$_currency → ${d.current.toStringAsFixed(0)}$_currency',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (delta.abs() >= 0.01)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    pct != null
                        ? '${pct > 0 ? '+' : ''}${pct.toStringAsFixed(0)}%'
                        : (isIncrease
                            ? localizations.comparisonNew
                            : '—'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '—',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _monthName(BuildContext context, int month) {
    final l = AppLocalizations.of(context)!;
    switch (month) {
      case 1:
        return l.january;
      case 2:
        return l.february;
      case 3:
        return l.march;
      case 4:
        return l.april;
      case 5:
        return l.may;
      case 6:
        return l.june;
      case 7:
        return l.july;
      case 8:
        return l.august;
      case 9:
        return l.september;
      case 10:
        return l.october;
      case 11:
        return l.november;
      case 12:
        return l.december;
      default:
        return '';
    }
  }
}

class _CategoryDelta {
  final String category;
  final double current;
  final double previous;
  _CategoryDelta({
    required this.category,
    required this.current,
    required this.previous,
  });
}
