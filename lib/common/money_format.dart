import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats [amount] as money using the active app locale, e.g. `1.234,50 €`
/// in Spanish or `€1,234.50` in English.
String formatMoney(BuildContext context, double amount, String currency) {
  final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
  return NumberFormat.currency(
    locale: locale,
    symbol: currency,
    decimalDigits: 2,
  ).format(amount);
}
