import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/common/month_names.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/theme/app_glass.dart';

class MonthGridSelector extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final List<int> availableYears;
  final List<int> availableMonths;
  final Function(int) onYearChanged;
  final Function(int) onMonthChanged;

  const MonthGridSelector({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.availableYears,
    required this.availableMonths,
    required this.onYearChanged,
    required this.onMonthChanged,
  });

  @override
  State<MonthGridSelector> createState() => _MonthGridSelectorState();
}

class _MonthGridSelectorState extends State<MonthGridSelector> {
  Map<int, double> _monthTotals = {};
  String _currency = '€';

  @override
  void initState() {
    super.initState();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then((value) {
          if (mounted) setState(() => _currency = value ?? '€');
        });
    _loadTotals(widget.selectedYear);
  }

  @override
  void didUpdateWidget(MonthGridSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear) {
      _loadTotals(widget.selectedYear);
    }
  }

  Future<void> _loadTotals(int year) async {
    try {
      final fs = FinanceService.getInstance(
        SqliteService().db.monthDao,
        SqliteService().db.movementValueDao,
        SqliteService().db.fixedMovementDao,
      );
      final data = await fs.getYearlyData(year);
      final totals = <int, double>{};
      for (var i = 0; i < data.length; i++) {
        totals[i + 1] = (data[i]['incomes'] ?? 0) - (data[i]['expenses'] ?? 0);
      }
      if (mounted) setState(() => _monthTotals = totals);
    } catch (_) {
      // Ignore: totals are a non-critical enhancement.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildYearHeader(context, colorScheme, textTheme, glass),
        const SizedBox(height: 24),
        _buildMonthGrid(context, colorScheme, textTheme, glass),
      ],
    );
  }

  Widget _buildYearHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppGlass glass,
  ) {
    final canGoPrev = widget.availableYears.contains(widget.selectedYear - 1);
    final canGoNext = widget.availableYears.contains(widget.selectedYear + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildYearArrow(
          colorScheme: colorScheme,
          glass: glass,
          icon: Icons.chevron_left_rounded,
          onPressed: canGoPrev
              ? () => widget.onYearChanged(widget.selectedYear - 1)
              : null,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.yearLabel,
                style: textTheme.labelSmall?.copyWith(
                  color: glass.mutedText,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.selectedYear.toString(),
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildYearArrow(
          colorScheme: colorScheme,
          glass: glass,
          icon: Icons.chevron_right_rounded,
          onPressed: canGoNext
              ? () => widget.onYearChanged(widget.selectedYear + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildYearArrow({
    required ColorScheme colorScheme,
    required AppGlass glass,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final enabled = onPressed != null;
    return Material(
      color: colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: enabled ? colorScheme.onSurface : glass.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    AppGlass glass,
  ) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(12, (index) {
        final month = index + 1;
        final isAvailable = widget.availableMonths.contains(month);
        final isSelected = month == widget.selectedMonth;
        final total = _monthTotals[month];

        final Color background;
        final Color textColor;
        final Border? border;

        if (isSelected) {
          background = colorScheme.primary.withValues(alpha: 0.12);
          textColor = colorScheme.primary;
          border = Border.all(color: colorScheme.primary, width: 1.5);
        } else if (isAvailable) {
          background = colorScheme.surfaceContainerHigh;
          textColor = colorScheme.onSurface;
          border = Border.all(color: glass.glassBorder);
        } else {
          background = colorScheme.surfaceContainerHigh.withValues(alpha: 0.4);
          textColor = glass.mutedText;
          border = null;
        }

        return Material(
          color: background,
          borderRadius: BorderRadius.circular(glass.pillRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isAvailable ? () => widget.onMonthChanged(month) : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(glass.pillRadius),
                border: border,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthShortNames(AppLocalizations.of(context)!)[month - 1],
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    if (isAvailable && total != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$_currency${total.toStringAsFixed(2)}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: isSelected ? colorScheme.primary : glass.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
