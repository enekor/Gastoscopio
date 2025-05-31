import 'package:cashly/data/services/shared_preferences_service.dart';
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

  Future<String> _generateContent(String prompt, String apiKey) async {
    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'No se pudo generar una respuesta';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> generateContent(String prompt, BuildContext context) async {
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
                onPressed: () {
                  Navigator.pop(context);
                  //ir a settings
                },
                label: const Text('Vamos allá'),
                icon: const Icon(Icons.settings),
              ),
            ],
          );
        },
      );

      throw NoApiKeyException();
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
}

class NoApiKeyException implements Exception {
  @override
  String toString() => 'API Key no configurada';
}
