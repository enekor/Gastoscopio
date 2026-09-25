import 'learned_rules.dart';
import 'learning_key.dart';
import 'locales/locale_config.dart';
import 'transaction_parser.dart';
import 'transaction_direction.dart';
import 'merchant_name_cleaner.dart';
import 'tag_classifier.dart';

class TransactionSuggester {
  final TagClassifier _classifier;
  final LearnedRuleSet _learnedNames;

  TransactionSuggester({
    required TagClassifier classifier,
    LearnedRuleSet? learnedNames,
  })  : _classifier = classifier,
        _learnedNames = learnedNames ?? LearnedRuleSet();

  /// [rawMerchant] es el texto del comercio con el que se aprende y se busca:
  /// el comercio extraído por el parser o, si no se pudo extraer, el nombre
  /// limpio del texto. Nunca es la notificación completa, que no se repite.
  ({String name, String tag, bool isIncome, double? amount, String rawMerchant})
      suggest(
    String notification, {
    required LocaleConfig locale,
  }) {
    // 1. ¿Ingreso o gasto?
    final isIncome = TransactionDirection.isIncome(notification, locale);

    // 2. Extraer merchant y cantidad
    final parsed = TransactionParser.parse(notification, locale);
    final keywordText = parsed.merchant ?? notification;
    final merchantText = _merchantTextFrom(parsed.merchant, notification, locale);

    // 3. Nombre: lo aprendido o el nombre limpio
    final name = _learnedNames.lookup(LearningKey.normalize(merchantText)) ??
        MerchantNameCleaner.suggest(merchantText, locale);

    // 4. Clasificar tag
    final tag = _classifier.classify(
      keywordText,
      isIncome: isIncome,
      locale: locale,
      learnedLookupText: merchantText,
    );

    return (
      name: name,
      tag: tag,
      isIncome: isIncome,
      amount: parsed.amount,
      rawMerchant: merchantText,
    );
  }

  /// Texto del comercio para [text], el mismo que usa [suggest]. Sirve para
  /// aprender a partir de descripciones escritas a mano.
  String merchantTextFor(String text, LocaleConfig locale) {
    final parsed = TransactionParser.parse(text, locale);
    return _merchantTextFrom(parsed.merchant, text, locale);
  }

  String _merchantTextFrom(
    String? parsedMerchant,
    String original,
    LocaleConfig locale,
  ) {
    if (parsedMerchant != null && parsedMerchant.trim().isNotEmpty) {
      return parsedMerchant;
    }
    // Sin comercio extraído: la notificación completa lleva importes y fechas
    // que no se repiten, así que se usa su versión limpia.
    return MerchantNameCleaner.suggest(original, locale);
  }
}
