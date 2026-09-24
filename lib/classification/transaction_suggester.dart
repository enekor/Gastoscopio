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

  /// [rawMerchant] es el comercio extraído por el parser (o la notificación
  /// completa si no se pudo extraer). Es la clave que debe usarse en
  /// [learnName] para que la corrección se reutilice en futuras notificaciones.
  ({String name, String tag, bool isIncome, double? amount, String rawMerchant})
      suggest(
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

    return (
      name: name,
      tag: tag,
      isIncome: isIncome,
      amount: parsed.amount,
      rawMerchant: rawMerchant,
    );
  }

  String _suggestName(String rawMerchant, LocaleConfig locale) {
    final lower = rawMerchant.toLowerCase().trim();
    for (final entry in _userNames.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return MerchantNameCleaner.suggest(rawMerchant, locale);
  }

  /// Aprende el nombre elegido por el usuario para [rawMerchant] (el comercio
  /// devuelto por [suggest], no el texto completo de la notificación).
  void learnName(String rawMerchant, String userChosenName) {
    final key = rawMerchant.toLowerCase().trim();
    final value = userChosenName.trim();
    if (key.isEmpty || value.isEmpty) return;
    _userNames[key] = value;
  }

  void clearNames() => _userNames.clear();

  Map<String, String> get nameOverrides => Map.unmodifiable(_userNames);
}
