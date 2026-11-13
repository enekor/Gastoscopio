import 'data/known_merchants.dart';
import 'locales/locale_config.dart';

class MerchantNameCleaner {
  /// Intenta devolver un nombre limpio.
  static String suggest(String rawMerchant, LocaleConfig locale) {
    final lower = rawMerchant.toLowerCase().trim();

    // 1. Mapa de conocidos (universal, parcial)
    for (final entry in knownMerchants.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Limpieza con datos del locale
    return _cleanRaw(rawMerchant, locale);
  }

  static String _cleanRaw(String raw, LocaleConfig locale) {
    String result = raw;

    for (final pattern in locale.noisePatterns) {
      result = result.replaceAll(pattern, ' ');
    }

    final words = result.split(RegExp(r'\s+'));
    final filtered = words.where((w) =>
      w.length > 1 &&
      !locale.stopWords.contains(w.toLowerCase())
    ).toList();

    result = filtered.join(' ').trim();
    if (result.isEmpty) return raw.trim();

    return _titleCase(result);
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    if (text == text.toUpperCase() && text.length > 3) {
      return text.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }
    return text;
  }
}
