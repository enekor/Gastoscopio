import 'dart:convert';

import 'package:cashly/classification/learned_rules.dart';
import 'package:cashly/classification/learned_rules_repository.dart';
import 'package:cashly/classification/learning_key.dart';
import 'package:cashly/classification/locales/locale_config.dart';
import 'package:cashly/classification/tag_classifier.dart';
import 'package:cashly/classification/transaction_suggester.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';

/// Punto de entrada del modo aprendizaje.
///
/// [initialize] deja listos el clasificador y el sugeridor, sin reglas.
/// [loadLearnedRules] carga lo aprendido desde la base de datos y debe
/// llamarse justo después de abrirla.
class ClassificationService {
  static final ClassificationService _instance =
      ClassificationService._internal();
  factory ClassificationService() => _instance;
  ClassificationService._internal();

  final LearnedRuleSet _tags = LearnedRuleSet();
  final LearnedRuleSet _names = LearnedRuleSet();
  final LearnedRulesRepository _repository = LearnedRulesRepository();

  late TagClassifier _classifier;
  late TransactionSuggester _suggester;
  bool _rulesLoaded = false;

  Future<void> initialize() async {
    _classifier = TagClassifier(learnedTags: _tags);
    _suggester = TransactionSuggester(
      classifier: _classifier,
      learnedNames: _names,
    );
  }

  TransactionSuggester get suggester => _suggester;
  TagClassifier get classifier => _classifier;

  LearnedRuleSet _setFor(LearnedRuleKind kind) =>
      kind == LearnedRuleKind.tag ? _tags : _names;

  /// Carga lo aprendido desde la base de datos. Migra una única vez los datos
  /// antiguos guardados en SharedPreferences.
  Future<void> loadLearnedRules({bool force = false}) async {
    if (_rulesLoaded && !force) return;
    try {
      _tags.clear();
      _names.clear();
      for (final row in await _repository.loadAll()) {
        final kind = LearnedRuleKind.fromDb(row['kind'] as String);
        if (kind == null) continue;
        _setFor(kind).load(
          row['ruleKey'] as String,
          row['value'] as String,
          (row['hits'] as num).toInt(),
          (row['updatedAt'] as num).toInt(),
        );
      }
      await _migrateLegacyPreferences();
      await _repository.deleteOrphanMerchantKeys();
      _rulesLoaded = true;
    } catch (e) {
      LogFileService().appendLog('Error loading learned rules: $e');
    }
  }

  Future<void> _migrateLegacyPreferences() async {
    final prefs = SharedPreferencesService();
    final legacy = {
      LearnedRuleKind.tag: SharedPreferencesKeys.classificationOverrides,
      LearnedRuleKind.name: SharedPreferencesKeys.classificationNames,
    };
    for (final entry in legacy.entries) {
      final json = await prefs.getStringValue(entry.value);
      if (json == null) continue;
      try {
        final map = Map<String, dynamic>.from(jsonDecode(json));
        for (final rule in map.entries) {
          final key = LearningKey.normalize(rule.key);
          final value = rule.value?.toString().trim() ?? '';
          if (!LearningKey.isValid(key) || value.isEmpty) continue;
          if (_setFor(entry.key).containsKey(key)) continue;
          await _record(entry.key, key, value);
        }
      } catch (e) {
        LogFileService().appendLog('Error migrating learned rules: $e');
      }
      await prefs.remove(entry.value);
    }
  }

  /// Clave normalizada del comercio de [text], la misma que usará [suggester]
  /// al clasificar un texto parecido en el futuro.
  String merchantKeyFor(String text, LocaleConfig locale) =>
      LearningKey.normalize(_suggester.merchantTextFor(text, locale));

  /// Aprende que los comercios [keyTexts] van con la categoría [tag].
  /// Cada texto se normaliza; los vacíos, cortos o repetidos se ignoran.
  Future<void> learnTag(Iterable<String?> keyTexts, String tag) async {
    final value = tag.trim();
    if (value.isEmpty) return;
    final keys = keyTexts
        .whereType<String>()
        .map(LearningKey.normalize)
        .where(LearningKey.isValid)
        .toSet();
    for (final key in keys) {
      await _record(LearnedRuleKind.tag, key, value);
    }
  }

  /// Aprende que el comercio [keyText] se llama [name].
  Future<void> learnName(String keyText, String name) async {
    final key = LearningKey.normalize(keyText);
    final value = name.trim();
    if (!LearningKey.isValid(key) || value.isEmpty) return;
    await _record(LearnedRuleKind.name, key, value);
  }

  Future<void> _record(LearnedRuleKind kind, String key, String value) async {
    final updated = _setFor(kind).record(
      key,
      value,
      DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await _repository.save(kind, key, updated);
    } catch (e) {
      LogFileService().appendLog('Error saving learned rule: $e');
    }
  }

  /// Guarda de qué comercio salió un movimiento, para seguir aprendiendo si el
  /// usuario lo corrige más adelante.
  Future<void> saveMovementMerchantKey(int movementId, String merchantText) async {
    final key = LearningKey.normalize(merchantText);
    if (!LearningKey.isValid(key)) return;
    try {
      await _repository.saveMovementMerchantKey(movementId, key);
    } catch (e) {
      LogFileService().appendLog('Error saving movement merchant key: $e');
    }
  }

  Future<String?> merchantKeyForMovement(int? movementId) async {
    if (movementId == null) return null;
    try {
      return await _repository.findMovementMerchantKey(movementId);
    } catch (e) {
      LogFileService().appendLog('Error reading movement merchant key: $e');
      return null;
    }
  }

  /// Reglas aprendidas de un tipo, ordenadas por clave.
  List<LearnedRule> rules(LearnedRuleKind kind) => _setFor(kind).toRules(kind);

  /// Borra una regla concreta.
  Future<void> deleteRule(LearnedRuleKind kind, String key) async {
    _setFor(kind).remove(key);
    await _repository.deleteKey(kind, key);
  }

  /// Borra todo lo aprendido (tags y nombres corregidos por el usuario).
  Future<void> clearLearnedData() async {
    _tags.clear();
    _names.clear();
    await _repository.deleteAll();
  }

  /// Número de correcciones aprendidas (tags + nombres).
  int get learnedCount => _tags.length + _names.length;
}
