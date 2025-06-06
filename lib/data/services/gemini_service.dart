import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  String? _apiKey;
  late final GenerativeModel model;

  factory GeminiService() {
    return _instance;
  }

  GeminiService._internal();

  bool get hasApiKey => _apiKey != null && _apiKey!.isNotEmpty;

  Future<String> _generateContent(String prompt, String apiKey) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } catch (e) {
      return '';
    }
  }

  Future<String> _initGenerateContent(
    String prompt,
    BuildContext context,
  ) async {
    if (_apiKey == null || _apiKey == "" || _apiKey!.isEmpty) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Configurar API Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para utilizar las funciones de IA, por favor ingrese su API Key:',
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                label: const Text('Más tarde'),
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
                label: const Text('Vamos allá'),
                icon: const Icon(Icons.settings),
              ),
            ],
          );
        },
      );
      return '';
    } else {
      return await _generateContent(prompt, _apiKey!);
    }
  }

  Future initializeGemini() async {
    String _apiKey =
        await SharedPreferencesService().getStringValue(
          SharedPreferencesKeys.apiKey,
        ) ??
        '';

    if (_apiKey.isNotEmpty) {
      this._apiKey = _apiKey;
      model = GenerativeModel(apiKey: _apiKey, model: 'gemini-2.0-flash');
    }
  }

  Future<String> generateCategory(String name, BuildContext context) async {
    String prompt =
        'dime la mejor categoria para el siguiente movimiento (solo dime la categoria, nada mas): "$name". '
        'Elige una de las siguientes categorías: ${TagList.join(', ')}. '
        'Si no encuentras una categoría adecuada, responde con la ultima categoria.';

    return await _initGenerateContent(prompt, context);
  }
}

Future<String> generateSummary(
  List<MovementValue> movements,
  Month month,
  BuildContext context,
) async {
  String prompt =
      'Quiero que me des un resumen de la contabilidad de mi usuario para el mes de ${month.month}/${month.year}. '
      'Quieron que me des solo el resultado de tu analisis en formato markdown.'
      'Para el analisis quiero que me digas en que me he gastado mas, en que menos, como podria mejorar, cuales han sido potencialmente gastos inutiles...todo tipo de información que me de información sobre como ha ido el mes financieramente.'
      'Te paso en modo json los datos de los gastos e ingresos de mi usuario:'
      '${movements.map((m) => m.toJson()).toList()}';

  String response = await GeminiService()._initGenerateContent(prompt, context);
  return response;
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
