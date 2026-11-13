import 'locales/locale_config.dart';

class TransactionParser {
  /// Parsea una notificación usando los patrones del locale dado.
  static ({String? merchant, double? amount}) parse(
    String notification,
    LocaleConfig locale,
  ) {
    for (final pattern in [...locale.incomePatterns, ...locale.expensePatterns]) {
      final match = pattern.firstMatch(notification);
      if (match != null) {
        return (
          merchant: match.groupCount >= 1 ? match.group(1)?.trim() : null,
          amount: _parseAmount(match.group(match.groupCount), locale.localeCode),
        );
      }
    }
    return (merchant: null, amount: null);
  }

  static double? _parseAmount(String? raw, String locale) {
    if (raw == null) return null;
    // Formato español: 1.234,56 → Formato inglés: 1,234.56
    String clean = raw.replaceAll(RegExp(r'[^\d.,]'), '');
    if (locale == 'en') {
      return double.tryParse(clean.replaceAll(',', ''));
    }
    return double.tryParse(clean.replaceAll('.', '').replaceAll(',', '.'));
  }
}
