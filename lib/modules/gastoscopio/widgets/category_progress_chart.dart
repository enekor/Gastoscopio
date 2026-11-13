import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Donut chart + legend showing category distribution.
/// [categoryData] maps a category name to its percentage share (0-100).
/// Robust to empty data.
class CategoryProgressChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const CategoryProgressChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;

    final entries = categoryData.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noData,
            style: TextStyle(color: glass.mutedText),
          ),
        ),
      );
    }

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final palette = _palette(scheme, glass);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 38,
                  startDegreeOffset: -90,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value,
                        color: palette[i % palette.length],
                        radius: 16,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.total,
                    style: TextStyle(color: glass.mutedText, fontSize: 11),
                  ),
                  Text(
                    '${total.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: palette[i % palette.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: scheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entries[i].value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: glass.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Color> _palette(ColorScheme scheme, AppGlass glass) {
    return [
      scheme.primary,
      glass.incomeColor,
      scheme.tertiary,
      glass.expenseColor,
      scheme.secondary,
      scheme.primary.withValues(alpha: 0.6),
      glass.mutedText,
    ];
  }
}
