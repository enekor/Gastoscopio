import 'locales/locale_config.dart';

class TransactionDirection {
  /// Devuelve true si la notificación indica un ingreso.
  /// En caso de empate o sin señales, asume gasto (más frecuente).
  static bool isIncome(String notification, LocaleConfig locale) {
    final lower = notification.toLowerCase();

    int incomeScore = 0;
    int expenseScore = 0;

    for (final signal in locale.incomeSignals) {
      if (lower.contains(signal.toLowerCase())) incomeScore++;
    }
    for (final signal in locale.expenseSignals) {
      if (lower.contains(signal.toLowerCase())) expenseScore++;
    }

    return incomeScore > expenseScore;
  }
}
