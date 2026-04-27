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
        double temperature = 0.7,
        int? maxTokens,
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
              'temperature': temperature,
              if (maxTokens != null) 'max_tokens': maxTokens,
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


  String _buildCompactTags(String locale) {
    final isEs = locale == 'es';
    return tagDataList.asMap().entries.map((e) {
      final name = isEs ? e.value.tagEs : e.value.tagEn;
      final short = name.split('(')[0].trim();
      return '${e.key}:$short';
    }).join(',');
  }

  String _resolveTag(String value, String locale) {
    final index = int.tryParse(value.trim());
    if (index != null && index >= 0 && index < tagDataList.length) {
      return locale == 'es' ? tagDataList[index].tagEs : tagDataList[index].tagEn;
    }
    final tags = getTagList(locale);
    if (tags.contains(value.trim())) return value.trim();
    final lower = value.trim().toLowerCase();
    for (final tag in tags) {
      if (tag.toLowerCase().startsWith(lower) || tag.toLowerCase().contains(lower)) {
        return tag;
      }
    }
    return tags.last;
  }

  Future<String> generateCategory(
      String name,
      bool isExpense,
      BuildContext context,
      ) async {
    final locale = AppLocalizations.of(context).localeName;
    final compactTags = _buildCompactTags(locale);

    String prompt =
        'Categorize: "$name" (${isExpense ? 'expense' : 'income'}). '
        'Tags: $compactTags. Reply with the tag number ONLY.';

    String response = await _generateContent(prompt, context: context, temperature: 0.2, maxTokens: 10);
    return _resolveTag(response, locale);
  }

  /// Parses a notification text and extracts a transaction.
  /// Returns a map with keys: 'title' (String), 'amount' (double), 'isExpense' (bool).
  /// Returns null if parsing fails or the notification doesn't describe a transaction.
  Future<Map<String, dynamic>?> parseNotificationTransaction(
    String notificationText,
    String appName,
    double fallbackAmount,
    BuildContext context,
  ) async {
    final locale = AppLocalizations.of(context).localeName;
    final language = locale == 'es' ? 'español' : 'english';

    final prompt =
        'Analiza el siguiente texto de una notificación de la app "$appName" y extrae los datos '
        'de la transacción financiera que describe. Responde ÚNICAMENTE con un objeto JSON válido, '
        'sin markdown, sin explicaciones, sin bloques de código. El JSON debe tener exactamente estas claves:\n'
        '- "title": string corto y descriptivo en $language (máximo 40 caracteres, ej: "Compra en Mercadona", "Nómina", "Pago Netflix")\n'
        '- "amount": number con el importe positivo (ej: 15.50)\n'
        '- "isExpense": boolean (true si es gasto, false si es ingreso)\n\n'
        'Si no puedes determinar si es gasto o ingreso, asume que es gasto (true). '
        'Si no puedes extraer el importe claramente, usa $fallbackAmount.\n\n'
        'Texto de la notificación: "$notificationText"';

    String response = await _generateContent(prompt, context: context);

    try {
      // Clean possible markdown code fences
      response = response.trim();
      response = response.replaceAll('```json', '').replaceAll('```', '').trim();

      // Extract JSON substring (in case the model adds extra text)
      final start = response.indexOf('{');
      final end = response.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) {
        await LogFileService().appendLog(
          'parseNotificationTransaction: no JSON in response: $response',
        );
        return null;
      }
      final jsonStr = response.substring(start, end + 1);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;

      final title = (parsed['title'] ?? '').toString().trim();
      final amountRaw = parsed['amount'];
      final isExpense = parsed['isExpense'] == true;

      double amount = fallbackAmount;
      if (amountRaw is num) {
        amount = amountRaw.toDouble();
      } else if (amountRaw is String) {
        amount = double.tryParse(amountRaw.replaceAll(',', '.')) ?? fallbackAmount;
      }

      return {
        'title': title.isEmpty ? notificationText : title,
        'amount': amount.abs(),
        'isExpense': isExpense,
      };
    } catch (e) {
      await LogFileService().appendLog(
        'parseNotificationTransaction: parse error $e — response: $response',
      );
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> parseNotificationsBatch(
    List<Map<String, String>> notifications,
    BuildContext context,
  ) async {
    if (notifications.isEmpty) return [];

    final locale = AppLocalizations.of(context).localeName;
    final language = locale == 'es' ? 'español' : 'english';
    final compactTags = _buildCompactTags(locale);

    final notifLines = notifications.asMap().entries.map((e) {
      return '${e.key}|${e.value['app']}|${e.value['text']}|${e.value['amount']}';
    }).join('\n');

    final prompt =
        'Parse these notifications into financial transactions.\n'
        'Input: index|app|text|fallbackAmount\n'
        '$notifLines\n\n'
        'Categories: $compactTags\n\n'
        'Return ONLY a JSON array. Each element: '
        '{"i":index,"t":"title in $language max 40 chars","a":amount,"e":true/false,"c":categoryNumber}\n'
        'e=true if expense. Use fallbackAmount if amount unclear. No markdown.';

    final response = await _generateContent(
      prompt,
      context: context,
      temperature: 0.3,
      maxTokens: notifications.length * 80,
    );

    try {
      String cleaned = response.trim().replaceAll('```json', '').replaceAll('```', '').trim();
      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) return null;

      final parsed = jsonDecode(cleaned.substring(start, end + 1)) as List<dynamic>;

      return parsed.map((item) {
        final map = item as Map<String, dynamic>;
        final title = (map['t'] ?? '').toString().trim();
        final amountRaw = map['a'];
        final isExpense = map['e'] == true;
        final categoryRaw = (map['c'] ?? '').toString();

        double amount = 0;
        if (amountRaw is num) {
          amount = amountRaw.toDouble();
        } else if (amountRaw is String) {
          amount = double.tryParse(amountRaw.replaceAll(',', '.')) ?? 0;
        }

        return {
          'index': (map['i'] is int) ? map['i'] : int.tryParse(map['i'].toString()) ?? 0,
          'title': title,
          'amount': amount.abs(),
          'isExpense': isExpense,
          'category': _resolveTag(categoryRaw, locale),
        };
      }).toList();
    } catch (e) {
      await LogFileService().appendLog('parseNotificationsBatch: parse error $e — response: $response');
      return null;
    }
  }

  Future<String> _generateVisionContent(
    String prompt,
    String base64Image,
    String mimeType, {
    BuildContext? context,
    double temperature = 0.3,
    int? maxTokens,
  }) async {
    if (_apiKey.isEmpty) {
      try {
        final propertiesContent = await rootBundle.loadString('config.properties');
        Properties p = Properties.fromString(propertiesContent);
        _apiKey = p.get('GROQ_API_KEY') ?? 'error';
        if (_apiKey.isEmpty || _apiKey == 'tu_api_key_aqui') {
          _apiKey = 'error';
        }
      } catch (e) {
        debugPrint('Error cargando config.properties: $e');
      }
    }

    if (_apiKey == 'error') {
      return 'Error: No se pudo cargar la clave de API de Groq.';
    }

    final logService = LogFileService();
    const int maxAttempts = 3;
    List<String> attemptErrors = [];

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          await logService.appendLog('INFO GroqService Vision: Intento ${attempt + 1}...');

          final response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
              'messages': [
                {
                  'role': 'user',
                  'content': [
                    {'type': 'text', 'text': prompt},
                    {
                      'type': 'image_url',
                      'image_url': {
                        'url': 'data:$mimeType;base64,$base64Image',
                      },
                    },
                  ],
                }
              ],
              'temperature': temperature,
              if (maxTokens != null) 'max_tokens': maxTokens,
            }),
          ).timeout(const Duration(seconds: 60));

          if (response.statusCode == 200) {
            final decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);
            final data = jsonDecode(decodedBody);
            final content = data['choices'][0]['message']['content'] as String;
            if (content.isNotEmpty) return content;

            attemptErrors.add('Respuesta vacía (Intento ${attempt + 1})');
            await logService.appendLog('ERROR GroqService Vision: Respuesta vacía');
          } else {
            final errorData = jsonDecode(response.body);
            final errorMessage = errorData['error']?['message'] ?? 'Error desconocido';
            attemptErrors.add('Status ${response.statusCode}: $errorMessage');
            await logService.appendLog('ERROR GroqService Vision: ${response.statusCode} $errorMessage');

            if (response.statusCode == 401) return 'Error: API Key inválida.';
            if (response.statusCode == 429) {
              final waitMs = pow(2, attempt) * 1000 + 500;
              await Future.delayed(Duration(milliseconds: waitMs.toInt()));
              continue;
            }
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          attemptErrors.add('Error intento ${attempt + 1}: $e');
          await logService.appendLog('ERROR GroqService Vision: $e');
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final details = attemptErrors.join(' | ');
      await logService.appendLog('FATAL GroqService Vision: $details');
      return '';
    } catch (e) {
      await logService.appendLog('ERROR GroqService Vision (Outer): $e');
      return '';
    }
  }

  Future<List<Map<String, dynamic>>?> parseImageMovements(
    String base64Image,
    String mimeType,
    BuildContext context,
  ) async {
    final locale = AppLocalizations.of(context).localeName;
    final language = locale == 'es' ? 'español' : 'english';
    final compactTags = _buildCompactTags(locale);

    final prompt =
        'Extract ALL financial transactions from this image (receipt/statement/screenshot). '
        'Return ONLY a JSON array. Each element: '
        '{"t":"title in $language max 40 chars","a":amount,"e":true/false,"c":categoryNumber}\n'
        'Categories: $compactTags\n'
        'e=true if expense. If no transactions, return []. No markdown.';

    final response = await _generateVisionContent(prompt, base64Image, mimeType, context: context, maxTokens: 1000);

    if (response.isEmpty) return null;

    try {
      String cleaned = response.trim();
      cleaned = cleaned.replaceAll('```json', '').replaceAll('```', '').trim();

      final start = cleaned.indexOf('[');
      final end = cleaned.lastIndexOf(']');
      if (start == -1 || end == -1 || end <= start) {
        await LogFileService().appendLog('parseImageMovements: no JSON array in response: $response');
        return null;
      }

      final jsonStr = cleaned.substring(start, end + 1);
      final parsed = jsonDecode(jsonStr) as List<dynamic>;

      return parsed.map((item) {
        final map = item as Map<String, dynamic>;
        final title = (map['t'] ?? map['title'] ?? '').toString().trim();
        final amountRaw = map['a'] ?? map['amount'];
        final isExpense = (map['e'] ?? map['isExpense']) == true;
        final categoryRaw = (map['c'] ?? map['category'] ?? '').toString();

        double amount = 0;
        if (amountRaw is num) {
          amount = amountRaw.toDouble();
        } else if (amountRaw is String) {
          amount = double.tryParse(amountRaw.replaceAll(',', '.')) ?? 0;
        }

        return {
          'title': title,
          'amount': amount.abs(),
          'isExpense': isExpense,
          'category': _resolveTag(categoryRaw, locale),
        };
      }).where((m) => (m['amount'] as double) > 0).toList();
    } catch (e) {
      await LogFileService().appendLog('parseImageMovements: parse error $e — response: $response');
      return null;
    }
  }

  Future<List<String>> generateTags(String names, BuildContext context) async {
    final locale = AppLocalizations.of(context).localeName;
    final compactTags = _buildCompactTags(locale);
    final count = names.split(',').length;

    String prompt =
        'Assign tags to these movements (type in parentheses). '
        'Tags: $compactTags. '
        'Reply with tag numbers separated by |, in order. Nothing else.\n'
        'Movements: "$names"';

    String response = await _generateContent(prompt, context: context, temperature: 0.2, maxTokens: count * 5);
    return response.split('|').map((e) => _resolveTag(e.trim(), locale)).toList();
  }

  Future<String> generateSummary(
      List<MovementValue> movements,
      Month month,
      BuildContext context,
      ) async {
    final locale = AppLocalizations.of(context).localeName;
    final language = locale == 'es' ? 'español' : 'english';

    final dataLines = movements.map((m) =>
      '${m.day}|${m.description}|${m.amount}|${m.isExpense ? 'G' : 'I'}|${m.category ?? ''}'
    ).join('\n');

    String prompt =
        'Financial analysis in $language using markdown (## headers, - lists, **bold**).\n'
        'Sections: ## Resumen General, ## Análisis de Gastos, ## Recomendaciones\n'
        'Analyze: balance, top expense categories, patterns, unnecessary expenses, suggestions.\n\n'
        'Month ${month.month}/${month.year}, format: day|desc|amount|G(expense)/I(income)|category\n'
        '$dataLines';

    String response = await _generateContent(
      prompt,
      context: context,
      maxTokens: 1500,
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
