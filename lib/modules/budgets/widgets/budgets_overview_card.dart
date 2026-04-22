import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/services/budget_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:svg_flutter/svg.dart';

class BudgetsOverviewCard extends StatefulWidget {
  final int monthId;

  const BudgetsOverviewCard({super.key, required this.monthId});

  @override
  State<BudgetsOverviewCard> createState() => _BudgetsOverviewCardState();
}

class _BudgetsOverviewCardState extends State<BudgetsOverviewCard> {
  late final BudgetService _service;
  List<CategorySpend> _items = [];
  bool _isLoading = true;
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    final db = SqliteService().db;
    _service = BudgetService(db.categoryBudgetDao, db.movementValueDao);
    _load();
  }

  @override
  void didUpdateWidget(covariant BudgetsOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.monthId != widget.monthId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final currency = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency);
    final items = await _service.getSpendForMonth(widget.monthId);
    if (!mounted) return;
    setState(() {
      _currency = currency ?? '€';
      _items = items.where((i) => i.hasLimit).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  localizations.budgetsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._items.map((i) => _buildRow(context, i)),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, CategorySpend item) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    final progress = (item.spent / (item.limit ?? 1)).clamp(0.0, 1.0);
    final color = item.isExceeded
        ? theme.colorScheme.error
        : item.isNearLimit
            ? Colors.orange
            : theme.colorScheme.primary;

    String? iconPath;
    try {
      iconPath = getIconPath(item.category);
    } catch (_) {
      iconPath = null;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (iconPath != null)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(
                    iconPath,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${item.spent.toStringAsFixed(0)} / ${item.limit!.toStringAsFixed(0)}$_currency',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withAlpha(120),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (item.isExceeded)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                localizations.budgetExceededBy(
                  (item.spent - item.limit!).toStringAsFixed(2),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
