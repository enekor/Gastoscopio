/// Normalización de las claves con las que se aprende y se busca.
///
/// Se aplica igual al aprender y al buscar, así que dos textos que solo se
/// diferencian en mayúsculas, acentos, importes, fechas o números de tarjeta
/// producen la misma clave: "MERCADONA S.A. 23,45€ 12/03" → "mercadona s a".
class LearningKey {
  LearningKey._();

  /// Longitud mínima de una clave válida. Evita que claves muy cortas
  /// acaben capturando cualquier texto.
  static const int minLength = 3;

  static final RegExp _ibanLike =
      RegExp(r'\b[a-z]{2}\d{2}[a-z0-9]{4,}\b', caseSensitive: false);
  static final RegExp _nonLetters = RegExp(r'[^\p{L}\s]', unicode: true);
  static final RegExp _currencyTokens = RegExp(r'\b(eur|euros?|usd|gbp)\b');
  static final RegExp _spaces = RegExp(r'\s+');

  static const Map<String, String> _diacritics = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  /// Devuelve la clave normalizada. Es idempotente.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(_diacritics[ch] ?? ch);
    }
    var s = buffer.toString();
    s = s.replaceAll(_ibanLike, ' ');
    s = s.replaceAll(_nonLetters, ' ');
    s = s.replaceAll(_currencyTokens, ' ');
    return s.replaceAll(_spaces, ' ').trim();
  }

  /// True si la clave (ya normalizada) es suficientemente larga para aprender.
  static bool isValid(String normalizedKey) =>
      normalizedKey.length >= minLength;
}
