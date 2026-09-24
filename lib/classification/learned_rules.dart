import 'learning_key.dart';

/// Tipo de regla aprendida.
enum LearnedRuleKind {
  /// Comercio → categoría.
  tag('tag'),

  /// Comercio → nombre limpio elegido por el usuario.
  name('name');

  final String dbValue;
  const LearnedRuleKind(this.dbValue);

  static LearnedRuleKind? fromDb(String value) {
    for (final k in LearnedRuleKind.values) {
      if (k.dbValue == value) return k;
    }
    return null;
  }
}

/// Un valor candidato para una clave, con cuántas veces lo eligió el usuario.
class LearnedRuleValue {
  final String value;
  final int hits;
  final int updatedAt;

  const LearnedRuleValue(this.value, this.hits, this.updatedAt);
}

/// Vista resuelta de una regla, pensada para mostrarla en la UI.
class LearnedRule {
  final LearnedRuleKind kind;
  final String key;
  final String value;
  final int hits;

  /// Otros valores que el usuario eligió alguna vez para esta clave.
  final List<String> alternatives;

  const LearnedRule({
    required this.kind,
    required this.key,
    required this.value,
    required this.hits,
    required this.alternatives,
  });
}

/// Conjunto en memoria de reglas aprendidas de un tipo.
///
/// Cada clave guarda todos los valores que el usuario ha elegido, con un
/// contador. Gana el valor con más aciertos y, a igualdad, el más reciente.
/// El contador se limita a [maxHits]: un toque accidental no borra una regla
/// asentada, y un cambio de opinión real se impone en pocas correcciones.
class LearnedRuleSet {
  static const int maxHits = 3;

  final Map<String, Map<String, LearnedRuleValue>> _entries = {};
  List<String>? _keysByLength;

  /// Carga un valor ya persistido, sin incrementar nada.
  void load(String key, String value, int hits, int updatedAt) {
    _entries.putIfAbsent(key, () => {})[value] =
        LearnedRuleValue(value, hits.clamp(1, maxHits), updatedAt);
    _keysByLength = null;
  }

  /// Registra que el usuario eligió [value] para [key] y devuelve el valor
  /// actualizado, listo para persistir.
  LearnedRuleValue record(String key, String value, int now) {
    final values = _entries.putIfAbsent(key, () => {});
    final previous = values[value];
    final updated = LearnedRuleValue(
      value,
      ((previous?.hits ?? 0) + 1).clamp(1, maxHits),
      now,
    );
    values[value] = updated;
    _keysByLength = null;
    return updated;
  }

  bool containsKey(String key) => _entries.containsKey(key);

  /// Valor ganador para una clave exacta.
  String? winner(String key) {
    final values = _entries[key];
    if (values == null || values.isEmpty) return null;
    LearnedRuleValue? best;
    for (final v in values.values) {
      if (best == null ||
          v.hits > best.hits ||
          (v.hits == best.hits && v.updatedAt > best.updatedAt)) {
        best = v;
      }
    }
    return best!.value;
  }

  /// Busca la regla cuya clave aparece como palabras completas dentro de
  /// [normalizedText]. Se prueban primero las claves más largas, que son las
  /// más específicas.
  String? lookup(String normalizedText) {
    if (normalizedText.isEmpty || _entries.isEmpty) return null;
    final padded = ' $normalizedText ';
    for (final key in _sortedKeys()) {
      if (!LearningKey.isValid(key)) continue;
      if (padded.contains(' $key ')) return winner(key);
    }
    return null;
  }

  List<String> _sortedKeys() => _keysByLength ??= (_entries.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length)));

  void remove(String key) {
    _entries.remove(key);
    _keysByLength = null;
  }

  void clear() {
    _entries.clear();
    _keysByLength = null;
  }

  int get length => _entries.length;

  List<LearnedRule> toRules(LearnedRuleKind kind) {
    final rules = <LearnedRule>[];
    for (final entry in _entries.entries) {
      final best = winner(entry.key);
      if (best == null) continue;
      rules.add(LearnedRule(
        kind: kind,
        key: entry.key,
        value: best,
        hits: entry.value[best]!.hits,
        alternatives: entry.value.keys.where((v) => v != best).toList(),
      ));
    }
    rules.sort((a, b) => a.key.compareTo(b.key));
    return rules;
  }
}
