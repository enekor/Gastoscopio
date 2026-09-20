import 'package:cashly/classification/tag_classifier.dart';
import 'package:cashly/classification/transaction_suggester.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'dart:convert';

class ClassificationService {
  static final ClassificationService _instance = ClassificationService._internal();
  factory ClassificationService() => _instance;
  ClassificationService._internal();

  late TagClassifier _classifier;
  late TransactionSuggester _suggester;

  Future<void> initialize() async {
    final prefs = SharedPreferencesService();
    
    final String? overridesJson = await prefs.getStringValue(SharedPreferencesKeys.classificationOverrides);
    Map<String, String> overrides = {};
    if (overridesJson != null) {
      try {
        overrides = Map<String, String>.from(jsonDecode(overridesJson));
      } catch (_) {}
    }

    final String? namesJson = await prefs.getStringValue(SharedPreferencesKeys.classificationNames);
    Map<String, String> names = {};
    if (namesJson != null) {
      try {
        names = Map<String, String>.from(jsonDecode(namesJson));
      } catch (_) {}
    }

    _classifier = TagClassifier(savedOverrides: overrides);
    _suggester = TransactionSuggester(
      classifier: _classifier,
      savedUserNames: names,
    );
  }

  TransactionSuggester get suggester => _suggester;
  TagClassifier get classifier => _classifier;

  Future<void> saveOverrides() async {
    final prefs = SharedPreferencesService();
    await prefs.setStringValue(SharedPreferencesKeys.classificationOverrides, jsonEncode(_classifier.overrides));
    await prefs.setStringValue(SharedPreferencesKeys.classificationNames, jsonEncode(_suggester.nameOverrides));
  }
}
