import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final bool? isExpense;
  final bool signed;
  final double fontSize;
  final Color? color;
  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    this.isExpense,
    this.signed = false,
    this.fontSize = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    String prefix = '';
    Color resolved = color ?? scheme.onSurface;
    if (signed && isExpense != null) {
      prefix = isExpense! ? '-' : '+';
      resolved = color ?? (isExpense! ? glass.expenseColor : glass.incomeColor);
    }
    return Text(
      '$prefix${amount.toStringAsFixed(2)}$currency',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: resolved,
      ),
    );
  }
}
