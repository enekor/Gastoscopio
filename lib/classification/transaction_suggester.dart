import 'locales/locale_config.dart';
import 'transaction_parser.dart';
import 'transaction_direction.dart';
import 'merchant_name_cleaner.dart';
import 'tag_classifier.dart';

class TransactionSuggester {
  final TagClassifier _classifier;
  final Map<String, String> _userNames;

  TransactionSuggester({
    required TagClassifier classifier,
    Map<String, String>? savedUserNames,
  })  : _classifier = classifier,
        _userNames = savedUserNames ?? {};

  ({String name, String tag, bool isIncome, double? amount}) suggest(
    String notification, {
    required LocaleConfig locale,
  }) {
    // 1. ¿Ingreso o gasto?
    final isIncome = TransactionDirection.isIncome(notification, locale);

    // 2. Extraer merchant y cantidad
    final parsed = TransactionParser.parse(notification, locale);

    // 3. Nombre limpio
    final String name;
    final rawMerchant = parsed.merchant ?? notification;
    name = _suggestName(rawMerchant, locale);

    // 4. Clasificar tag
    final tag = _classifier.classify(
      rawMerchant,
      isIncome: isIncome,
      locale: locale,
    );

    return (name: name, tag: tag, isIncome: isIncome, amount: parsed.amount);
  }

  String _suggestName(String rawMerchant, LocaleConfig locale) {
    final lower = rawMerchant.toLowerCase().trim();
    for (final entry in _userNames.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return MerchantNameCleaner.suggest(rawMerchant, locale);
  }

  void learnName(String rawMerchant, String userChosenName) {
    _userNames[rawMerchant.toLowerCase().trim()] = userChosenName;
  }

  void clearNames() => _userNames.clear();

  Map<String, String> get nameOverrides => Map.unmodifiable(_userNames);
}
