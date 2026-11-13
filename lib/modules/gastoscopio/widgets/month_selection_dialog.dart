import 'package:flutter/material.dart';
import 'package:cashly/theme/design_systems.dart';
import 'package:cashly/data/services/theme_service.dart';
import 'package:cashly/l10n/app_localizations.dart';

class MonthSelectionDialog extends StatefulWidget {
  final int initialMonth;
  final int initialYear;

  const MonthSelectionDialog({
    super.key,
    required this.initialMonth,
    required this.initialYear,
  });

  @override
  State<MonthSelectionDialog> createState() => _MonthSelectionDialogState();
}

class _MonthSelectionDialogState extends State<MonthSelectionDialog> {
  late int _selectedMonth;
  late int _selectedYear;
  final int _currentYear = DateTime.now().year;
  final int _currentMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialMonth;
    _selectedYear = widget.initialYear;
  }

  void _onYearChanged(int delta) {
    final newYear = _selectedYear + delta;
    if (newYear > _currentYear) return;
    setState(() {
      _selectedYear = newYear;
      // If moving to current year and selected month is future, cap it
      if (_selectedYear == _currentYear && _selectedMonth > _currentMonth) {
        _selectedMonth = _currentMonth;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ds = ThemeService().designSystem;
    final loc = AppLocalizations.of(context)!;
    final monthNames = [
      loc.january, loc.february, loc.march, loc.april,
      loc.may, loc.june, loc.july, loc.august,
      loc.september, loc.october, loc.november, loc.december
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ds.surface,
          borderRadius: BorderRadius.circular(ds.borderRadius),
          border: Border.all(color: ds.outlineVariant.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.selectDate.toUpperCase(),
              style: TextStyle(
                color: ds.onSurface.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _onYearChanged(-1),
                  icon: Icon(Icons.chevron_left, color: ds.onSurface),
                ),
                Text(
                  '$_selectedYear',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _selectedYear < _currentYear ? () => _onYearChanged(1) : null,
                  icon: Icon(
                    Icons.chevron_right,
                    color: _selectedYear < _currentYear ? ds.onSurface : ds.onSurface.withOpacity(0.2),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Month Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final month = index + 1;
                final isFuture = _selectedYear == _currentYear && month > _currentMonth;
                final isSelected = month == _selectedMonth;

                return GestureDetector(
                  onTap: isFuture ? null : () {
                    setState(() => _selectedMonth = month);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? ds.primary : (isFuture ? ds.surface : ds.outlineVariant.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? ds.primary : ds.outlineVariant.withOpacity(0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        monthNames[index].substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          color: isSelected 
                            ? ds.onPrimary 
                            : (isFuture ? ds.onSurface.withOpacity(0.1) : ds.onSurface.withOpacity(0.6)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(loc.cancel, style: TextStyle(color: ds.onSurface.withOpacity(0.5))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, {'month': _selectedMonth, 'year': _selectedYear}),
                    child: Text(loc.accept),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
