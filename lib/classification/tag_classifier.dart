import 'data/merchant_tag_keywords.dart';
import 'locales/locale_config.dart';

class TagClassifier {
  final Map<String, String> _userOverrides;

  TagClassifier({Map<String, String>? savedOverrides})
      : _userOverrides = savedOverrides ?? {};

  String classify(String merchant, {
    required bool isIncome,
    required LocaleConfig locale,
  }) {
    final lower = merchant.toLowerCase().trim();

    // 1. Override del usuario (máxima prioridad, sin idioma)
    if (_userOverrides.containsKey(lower)) {
      return _userOverrides[lower]!;
    }

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

  void learn(String merchant, String tagEs) {
    _userOverrides[merchant.toLowerCase().trim()] = tagEs;
  }

  Map<String, String> get overrides => Map.unmodifiable(_userOverrides);
}
