import 'locale_es.dart';
import 'locale_en.dart';

/// Todos los datos que varían por idioma de las notificaciones.
class LocaleConfig {
  final String localeCode; // "es", "en", ...

  /// Regex para extraer merchant+cantidad de notificaciones de GASTO.
  final List<RegExp> expensePatterns;

  /// Regex para extraer merchant+cantidad de notificaciones de INGRESO.
  final List<RegExp> incomePatterns;

  /// Palabras/frases que indican un ingreso.
  final List<String> incomeSignals;

  /// Palabras/frases que indican un gasto.
  final List<String> expenseSignals;

  /// Palabras vacías a eliminar al limpiar nombres.
  final List<String> stopWords;

  /// Patrones de ruido a eliminar.
  final List<RegExp> noisePatterns;

  /// Keywords genéricas por tag (solo las que dependen del idioma).
  final Map<String, List<String>> genericTagKeywords;

  const LocaleConfig({
    required this.localeCode,
    required this.expensePatterns,
    required this.incomePatterns,
    required this.incomeSignals,
    required this.expenseSignals,
    required this.stopWords,
    required this.noisePatterns,
    required this.genericTagKeywords,
  });
}

class LocaleRegistry {
  static final Map<String, LocaleConfig> _configs = {
    'es': localeEs,
    'en': localeEn,
  };

  /// Devuelve la config para un locale, o español como fallback.
  static LocaleConfig get(String localeCode) {
    final languageCode = localeCode.split('_')[0].split('-')[0].toLowerCase();
    return _configs[languageCode] ?? _configs['es']!;
  }

  /// Locales soportados.
  static List<String> get supportedLocales => _configs.keys.toList();
}
