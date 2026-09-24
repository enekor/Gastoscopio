import 'data/merchant_tag_keywords.dart';
import 'learned_rules.dart';
import 'learning_key.dart';
import 'locales/locale_config.dart';

class TagClassifier {
  final LearnedRuleSet _learnedTags;

  TagClassifier({LearnedRuleSet? learnedTags})
      : _learnedTags = learnedTags ?? LearnedRuleSet();

  /// Clasifica [merchant].
  ///
  /// [learnedLookupText] permite buscar lo aprendido sobre un texto distinto
  /// del usado para las keywords (p. ej. el nombre limpio cuando el parser no
  /// pudo extraer el comercio). Por defecto se usa [merchant].
  String classify(
    String merchant, {
    required bool isIncome,
    required LocaleConfig locale,
    String? learnedLookupText,
  }) {
    // 1. Lo aprendido del usuario (máxima prioridad, sin idioma).
    final learned = _learnedTags.lookup(
      LearningKey.normalize(learnedLookupText ?? merchant),
    );
    if (learned != null) return learned;

    final lower = merchant.toLowerCase().trim();

    // 2. Mapa de comercios UNIVERSALES (sin idioma)
    for (final entry in merchantTagKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 3. Keywords genéricas DEL LOCALE
    final searchScope = isIncome
        ? locale.genericTagKeywords.entries.where((e) =>
            e.key == 'Salario y sueldo' || e.key == 'Otros ingresos')
        : locale.genericTagKeywords.entries.where((e) =>
            e.key != 'Salario y sueldo' && e.key != 'Otros ingresos');

    for (final entry in searchScope) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }

    // 4. Fallback
    return isIncome ? 'Otros ingresos' : 'Otros Gastos Misceláneos';
  }
}
