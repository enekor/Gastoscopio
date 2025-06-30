import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  String? _apiKey;
  GenerativeModel? model = null;

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<String> _generateContent(
    String prompt,
    String apiKey,
    BuildContext context,
  ) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model!.generateContent(content);
      return response.text ?? AppLocalizations.of(context).noResponseGenerated;
    } catch (e) {
      return '';
    }
  }

  Future<String> _initGenerateContent(
    String prompt,
    BuildContext context,
  ) async {
    await initializeGemini();
    if (_apiKey == null || _apiKey == "" || _apiKey!.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).configureApiKey),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text(AppLocalizations.of(context).enterApiKeyMessage)],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                label: Text(AppLocalizations.of(context).later),
                icon: const Icon(Icons.close),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const SettingsScreen();
                      },
                    ),
                  );
                },
                label: Text(AppLocalizations.of(context).letsGo),
                icon: const Icon(Icons.settings),
              ),
            ],
          );
        },
      );
      return '';
    } else {
      return await _generateContent(prompt, _apiKey!, context);
    }
  }

  Future initializeGemini() async {
    String _apiKey =
        await SharedPreferencesService().getStringValue(
          SharedPreferencesKeys.apiKey,
        ) ??
        '';

    this._apiKey = _apiKey;

    if (_apiKey.isNotEmpty) {
      model ??= GenerativeModel(apiKey: _apiKey, model: 'gemini-2.0-flash');
    }
  }

  Future<String> generateCategory(String name, BuildContext context) async {
    final locale = AppLocalizations.of(context).localeName;
    final categoryList = getTagList(locale);

    String prompt =
        'dime la mejor categoria para el siguiente movimiento (solo dime la categoria, nada mas): "$name". '
        'Elige una de las siguientes categorías: ${categoryList.join(', ')}. '
        'Si no encuentras una categoría adecuada, responde con la ultima categoria.';

    String response = await _initGenerateContent(prompt, context);
    return response;
  }

  Future<List<String>> generateTags(String names, BuildContext context) async {
    final locale = AppLocalizations.of(context).localeName;
    final tagList = getTagList(locale);

    String prompt =
        'Dime las mejores etiquetas para los siguientes movimientos (solo dime las etiquetas separadas por comas en el orden de los nombres que te mando, nada mas): "$names". '
        'Elige entre las siguientes etiquetas: ${tagList.join(', ')}. '
        'Si no encuentras una etiqueta adecuada, responde con la ultima etiqueta.';

    String response = await _initGenerateContent(prompt, context);
    return response.split(',').map((e) => e.trim()).toList();
  }

  Future<String> generateSummary(
    List<MovementValue> movements,
    Month month,
    BuildContext context,
  ) async {
    final locale = AppLocalizations.of(context).localeName;
    final language = locale == 'es' ? 'español' : 'english';

    String prompt =
        'Quiero que me des un resumen de la contabilidad de mi usuario para el mes de ${month.month}/${month.year}. '
        'Quiero que me des solo el resultado de tu analisis en formato markdown, sin que me digas nada mas, solo el markdown, ya que tu respuesta se decodifica desde markdown directramente en la aplicacion'
        'Genera la respuesta en $language. '
        'Para el analisis quiero que me digas en que me he gastado mas, en que menos, como podria mejorar, cuales han sido potencialmente gastos inutiles...todo tipo de información que me de información sobre como ha ido el mes financieramente. '
        'Te paso en modo json los datos de los gastos e ingresos de mi usuario: '
        '${movements.map((m) => m.toJson()).toList()}';

    String response = await GeminiService()._initGenerateContent(
      prompt,
      context,
    );
    return response;
  }
}

class NoApiKeyException implements Exception {
  final BuildContext context;

  NoApiKeyException(this.context);

  @override
  String toString() => AppLocalizations.of(context).apiKeyNotConfigured;
}
