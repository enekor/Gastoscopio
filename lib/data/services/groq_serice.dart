import 'dart:convert';
import 'dart:math';
import 'package:cashly/common/tag_list.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'log_file_service.dart';
import 'package:properties/properties.dart';

class GroqService {
  String _apiKey = '';
  static final GroqService _instance = GroqService._internal();

  factory GroqService() {
    return _instance;
  }

  GroqService._internal();

  Future<String> _generateContent(
      String prompt, {
        BuildContext? context,
      }) async {
    
    if(_apiKey.isEmpty) {
      try {
        // Hay que cargarlos mediante rootBundle y luego usar Properties.fromString
        final propertiesContent = await rootBundle.loadString('config.properties');
        Properties p = Properties.fromString(propertiesContent);

        _apiKey = p.get('GROQ_API_KEY')  ?? 'error';

        if (_apiKey != null && (_apiKey!.isEmpty || _apiKey == 'tu_api_key_aqui')) {
          _apiKey = 'error';
        }
      } catch (e) {
        debugPrint('Error cargando config.properties: $e');
      }
    }
    
    if(_apiKey == 'error') {
      return 'Error: No se pudo cargar la clave de API de Groq.';
    }

    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO GroqService: Intento ${attempt + 1} enviando petición...');

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'llama-3.3-70b-versatile',
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.7,
            }),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            // Se usa utf8.decode con allowMalformed: true para evitar el error de "Missing extension byte"
            // si la respuesta contiene caracteres extraños o mal formados.
            final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
            final data = jsonDecode(decodedBody);
            final content = data['choices'][0]['message']['content'] as String;

            if (content.isNotEmpty) {
              return content;
            } else {
              final errorMsg = 'Respuesta vacía de Groq (Intento ${attempt + 1})';
              attemptErrors.add(errorMsg);
              await logService.appendLog('ERROR GroqService: $errorMsg');
            }
          } else {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
            final errorMsg = 'Status ${response.statusCode} (Intento ${attempt + 1}): $errorMessage';
            attemptErrors.add(errorMsg);

            await logService.appendLog('ERROR GroqService: $errorMsg');

            if (response.statusCode == 401) {
              return 'Error: API Key de Groq inválida. Por favor, revísala en Ajustes.';
            }

            if (response.statusCode == 429) {
              if (context != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Límite de velocidad excedido en Groq. Reintentando...'),
                    backgroundColor: Colors.orangeAccent,
                  ),
                );
              }
              final waitMs = pow(2, attempt) * 1000 + 500;
              await Future.delayed(Duration(milliseconds: waitMs.toInt()));
              continue;
            }

            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
        } catch (e) {
          final errorMsg = 'Error en intento ${attempt + 1}: $e';
          attemptErrors.add(errorMsg);
          await logService.appendLog('ERROR GroqService (Catch Intento): $errorMsg');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final details = attemptErrors.join(' | ');
      String userMessage = 'No se pudo generar respuesta con Groq tras varios intentos.';

      if (details.toLowerCase().contains('rate_limit') || details.contains('429')) {
        userMessage = 'Error: Has excedido el límite de velocidad de Groq. Por favor, espera un poco o cambia la clave.';
      }

      await logService.appendLog('FATAL GroqService: $userMessage. Detalles: $details');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userMessage), backgroundColor: Colors.redAccent),
        );
      }
      return userMessage;

    } catch (e) {
      await logService.appendLog('ERROR GroqService (Outer catch): $e');
      return 'Error crítico: $e';
    }
  }


  Future<String> generateCategory(
      String name,
      bool isExpense,
      BuildContext context,
      ) async {
    final locale = AppLocalizations.of(context).localeName;
    final categoryList = getTagList(locale);

    String prompt =
        'dime la mejor categoria para el siguiente movimiento (solo dime la categoria, nada mas): "$name". Ten en cuenta que es un ${isExpense ? 'gasto' : 'ingreso'}'
        'Elige una de las siguientes categorías: ${categoryList.join(', ')}. '
        'Si no encuentras una categoría adecuada, responde con la ultima categoria.';

    String response = await _generateContent(prompt, context: context);
    return response;
  }

  Future<List<String>> generateTags(String names, BuildContext context) async {
    final locale = AppLocalizations.of(context).localeName;
    final tagList = getTagList(locale);

    String prompt =
        'Dime las mejores etiquetas para los siguientes movimientos (solo dime las etiquetas separadas por comas en el orden de los nombres que te mando, nada mas): "$names". '
        'Elige entre las siguientes etiquetas: ${tagList.join(', ')}. '
        'Si no encuentras una etiqueta adecuada, responde con la ultima etiqueta.'
        'Ten en cuenta que cada uno de los movimientos tiene entre paréntesis su tipo (gasto o ingreso), para que te sea mas sencillo elegir una etiqueta.'
        'Como separador de los tags usa un pipeline (|) en lugar de una coma';

    String response = await _generateContent(prompt,context: context);
    return response.split('|').map((e) => e.trim()).toList();
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

    String response = await _generateContent(
      prompt,
      context: context,
    );

    if (response.isEmpty) {
      LogFileService().appendLog(
        'groqService generateSummary: Empty response from AI',
      );
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
      LogFileService().appendLog(
        'groqService generateSummary: No response generated after cleanup',
      );
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
