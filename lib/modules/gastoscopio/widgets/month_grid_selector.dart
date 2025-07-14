import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

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

  String _getMonthName(BuildContext context, int month) {
    final localizations = AppLocalizations.of(context);
    switch (month) {
      case 1:
        return localizations.january;
      case 2:
        return localizations.february;
      case 3:
        return localizations.march;
      case 4:
        return localizations.april;
      case 5:
        return localizations.may;
      case 6:
        return localizations.june;
      case 7:
        return localizations.july;
      case 8:
        return localizations.august;
      case 9:
        return localizations.september;
      case 10:
        return localizations.october;
      case 11:
        return localizations.november;
      case 12:
        return localizations.december;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selector de año
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed:
                      availableYears.contains(selectedYear - 1)
                          ? () => onYearChanged(selectedYear - 1)
                          : null,
                ),
                Text(
                  selectedYear.toString(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed:
                      availableYears.contains(selectedYear + 1)
                          ? () => onYearChanged(selectedYear + 1)
                          : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Grid de meses
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (index) {
                final month = index + 1;
                final isAvailable = availableMonths.contains(month);
                final isSelected = month == selectedMonth;

                return InkWell(
                  onTap: isAvailable ? () => onMonthChanged(month) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.primary
                              : isAvailable
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.surfaceVariant,
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getMonthName(context, month),
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : isAvailable
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
