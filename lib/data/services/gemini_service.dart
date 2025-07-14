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
        'Genera un análisis financiero usando SOLO los siguientes elementos de markdown:\n'
        '- Encabezados con ## (no uses #)\n'
        '- Listas con guiones (-)\n'
        '- Texto en negrita con **texto**\n'
        '- Párrafos simples\n\n'
        'Estructura requerida:\n'
        '## Resumen General\n'
        '(análisis general)\n\n'
        '## Análisis de Gastos\n'
        '(detalles de gastos)\n\n'
        '## Recomendaciones\n'
        '(recomendaciones)\n\n'
        'La respuesta debe estar en $language y analizar:\n'
        '- Balance general y tendencias\n'
        '- Principales categorías de gasto\n'
        '- Patrones de gasto destacables\n'
        '- Gastos potencialmente innecesarios\n'
        '- Sugerencias de mejora\n\n'
        'Datos (mes ${month.month}/${month.year}):\n'
        '${movements.map((m) => m.toJson()).toList()}';

    String response = await GeminiService()._initGenerateContent(
      prompt,
      context,
    );

    if (response.isEmpty) {
      return '## Error\n\nNo se pudo generar el análisis. Por favor, intenta de nuevo.';
    }

    // Asegurarse de que la respuesta esté en formato markdown válido
    if (!response.contains('##')) {
      response = '## Análisis Financiero\n\n' + response;
    }

    // Limpiar cualquier bloque de código o formato extra que pueda interferir
    response = response.replaceAll('```markdown', '');
    response = response.replaceAll('```', '');

    if (response.isEmpty) {
      return '## ${AppLocalizations.of(context).error}\n\n${AppLocalizations.of(context).noResponseGenerated}';
    }

    // Asegurarnos de que la respuesta comience con un encabezado markdown
    if (!response.trim().startsWith('#')) {
      response =
          '## ${AppLocalizations.of(context).aiAnalysisTitle}\n\n' + response;
    }

    return response;
  }
}
