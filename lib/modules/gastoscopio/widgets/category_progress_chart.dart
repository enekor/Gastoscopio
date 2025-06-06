import 'package:flutter/material.dart';

class CategoryProgressChart extends StatelessWidget {
  final Map<String, double> categoryData;

  const CategoryProgressChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          categoryData.entries.map((entry) {
            final category = entry.key;
            final percentage = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(category),
                      Text('${percentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      HSLColor.fromColor(
                        Theme.of(context).colorScheme.primary,
                      ).withLightness(0.5).toColor(),
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
