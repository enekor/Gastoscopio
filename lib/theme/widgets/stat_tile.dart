import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';

/// Small income/expense summary card.
class StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final IconData icon;
  final bool isIncome;
  const StatTile({
    super.key,
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    this.isIncome = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final accent = isIncome ? glass.incomeColor : glass.expenseColor;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: glass.mutedText, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$currency${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
