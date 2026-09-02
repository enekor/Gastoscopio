import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/common/month_names.dart';
import 'package:cashly/theme/app_glass.dart';

class MonthGridSelector extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final List<int> availableYears;
  final List<int> availableMonths;
  final Function(int) onYearChanged;
  final Function(int) onMonthChanged;

  const MonthGridSelector({
    Key? key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.availableYears,
    required this.availableMonths,
    required this.onYearChanged,
    required this.onMonthChanged,
  }) : super(key: key);

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
    final canGoPrev = availableYears.contains(selectedYear - 1);
    final canGoNext = availableYears.contains(selectedYear + 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildYearArrow(
          context: context,
          colorScheme: colorScheme,
          glass: glass,
          icon: Icons.chevron_left_rounded,
          onPressed: canGoPrev ? () => onYearChanged(selectedYear - 1) : null,
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
                selectedYear.toString(),
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildYearArrow(
          context: context,
          colorScheme: colorScheme,
          glass: glass,
          icon: Icons.chevron_right_rounded,
          onPressed: canGoNext ? () => onYearChanged(selectedYear + 1) : null,
        ),
      ],
    );
  }

  Widget _buildYearArrow({
    required BuildContext context,
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
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(12, (index) {
        final month = index + 1;
        final isAvailable = availableMonths.contains(month);
        final isSelected = month == selectedMonth;

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
            onTap: isAvailable ? () => onMonthChanged(month) : null,
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
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
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
