import 'dart:convert';
import 'dart:io';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class JsonImportResult {
  final List<Month> months;
  final List<MovementValue> movements;
  final String fileName;

  JsonImportResult({
    required this.months,
    required this.movements,
    required this.fileName,
  });
}

class JsonImportService {
  // Mapa para convertir nombres de meses en español a números
  static const Map<String, int> _monthNames = {
    'Enero': 1,
    'Febrero': 2,
    'Marzo': 3,
    'Abril': 4,
    'Mayo': 5,
    'Junio': 6,
    'Julio': 7,
    'Agosto': 8,
    'Septiembre': 9,
    'Octubre': 10,
    'Noviembre': 11,
    'Diciembre': 12,
  };

  /// Selecciona un archivo JSON y procesa su contenido
  static Future<JsonImportResult?> selectAndProcessJsonFile() async {
    try {
      // Seleccionar archivo usando file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        // Leer archivo
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();

        // Procesar JSON
        final processedData = await _processJsonData(contents);

        return JsonImportResult(
          months: processedData['months'],
          movements: processedData['movements'],
          fileName: result.files.single.name,
        );
      }

      return null; // Usuario canceló la selección
    } catch (e) {
      throw Exception('Error al procesar el archivo: $e');
    }
  }

  /// Validates the structure of the imported JSON data
  static void _validateJsonStructure(Map<String, dynamic> jsonData) {
    if (!jsonData.containsKey('Meses')) {
      throw Exception('El archivo no contiene la sección "Meses" requerida');
    }

    if (!(jsonData['Meses'] is List)) {
      throw Exception('La sección "Meses" debe ser una lista');
    }

    if ((jsonData['Meses'] as List).isEmpty) {
      throw Exception('No se encontraron meses en el archivo');
    }

    for (var mes in jsonData['Meses']) {
      if (!(mes is Map<String, dynamic>)) {
        throw Exception('Formato inválido: cada mes debe ser un objeto');
      }

      if (!mes.containsKey('NMes')) {
        throw Exception('Falta el nombre del mes (NMes) en uno de los meses');
      }

      if (!mes.containsKey('Anno')) {
        throw Exception('Falta el año (Anno) en uno de los meses');
      }

      // Validate movements if present
      if (mes.containsKey('Gastos') && mes['Gastos'] != null) {
        if (!(mes['Gastos'] is List)) {
          throw Exception('La sección "Gastos" debe ser una lista');
        }

        for (var gasto in mes['Gastos']) {
          if (!(gasto is Map<String, dynamic>)) {
            throw Exception('Formato inválido: cada gasto debe ser un objeto');
          }
          if (!gasto.containsKey('nombre')) {
            throw Exception('Falta el nombre en uno de los gastos');
          }
          if (!gasto.containsKey('valor')) {
            throw Exception('Falta el valor en uno de los gastos');
          }
        }
      }
    }
  }

  /// Procesa el contenido JSON y retorna los objetos Month y MovementValue
  static Future<Map<String, dynamic>> _processJsonData(
    String jsonString,
  ) async {
    try {
      // First try to parse the JSON
      Map<String, dynamic> jsonData;
      try {
        jsonData = json.decode(jsonString);
      } catch (e) {
        throw Exception(
          'El archivo no contiene un JSON válido. Verifica su formato.',
        );
      }

      // Validate the structure
      _validateJsonStructure(jsonData);

      List<Month> months = [];
      List<MovementValue> movements = [];

      // Procesar meses
      List<dynamic> mesesData = jsonData['Meses'];

      for (int i = 0; i < mesesData.length; i++) {
        Map<String, dynamic> mesData = mesesData[i];

        // Crear objeto Month
        String nombreMes = mesData['NMes'];
        if (!_monthNames.containsKey(nombreMes)) {
          throw Exception(
            'Nombre de mes inválido: "$nombreMes". '
            'Debe ser uno de: ${_monthNames.keys.join(", ")}',
          );
        }

        int numeroMes = _monthNames[nombreMes]!;
        int anno = mesData['Anno'];

        Month month = Month(numeroMes, anno);
        months.add(month);

        // Procesar movimientos para este mes
        final monthMovements = _processMovementsForMonth(mesData, i + 1);
        movements.addAll(monthMovements);
      }

      if (movements.isEmpty) {
        throw Exception(
          'No se encontraron movimientos en el archivo. '
          'Verifica que contenga gastos, ingresos o extras.',
        );
      }

      return {'months': months, 'movements': movements};
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al procesar el archivo: $e');
    }
  }

  /// Procesa todos los movimientos de un mes específico
  static List<MovementValue> _processMovementsForMonth(
    Map<String, dynamic> mesData,
    int monthId,
  ) {
    List<MovementValue> movements = [];

    // Procesar Gastos
    List<dynamic> gastos = mesData['Gastos'] ?? [];
    for (Map<String, dynamic> gasto in gastos) {
      double valor = (gasto['valor'] ?? 0.0).toDouble();
      bool isExpense = valor > 0; // Gastos positivos son expenses

      MovementValue movement = MovementValue(
        null, // Let SQLite handle the ID auto-increment
        monthId,
        gasto['nombre'] ?? '',
        valor.abs(), // Guardamos el valor absoluto
        isExpense,
        gasto['dia'] ?? 1,
        gasto['tag']?.isNotEmpty == true ? gasto['tag'] : null,
      );
      movements.add(movement);
    }

    // Procesar Extras
    List<dynamic> extras = mesData['Extras'] ?? [];
    for (Map<String, dynamic> extra in extras) {
      double valor = (extra['valor'] ?? 0.0).toDouble();

      MovementValue movement = MovementValue(
        null, // Let SQLite handle the ID auto-increment
        monthId,
        extra['nombre'] ?? '',
        valor,
        true, // Extras siempre son expenses
        extra['dia'] ?? 1,
        extra['tag']?.isNotEmpty == true ? extra['tag'] : null,
      );
      movements.add(movement);
    }

    // Procesar Ingreso (si existe)
    double ingreso = (mesData['Ingreso'] ?? 0.0).toDouble();
    if (ingreso > 0) {
      MovementValue ingresoMovement = MovementValue(
        null, // Let SQLite handle the ID auto-increment
        monthId,
        'Ingreso',
        ingreso,
        false, // Ingresos no son expenses
        1,
        'ingreso',
      );
      movements.add(ingresoMovement);
    }

    return movements;
  }

  static Future<String> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory.path;
      }
      // Intentar alternativa
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadDir = Directory('${externalDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir.path;
      }
      throw Exception('No se pudo acceder al directorio de descargas');
    }
    throw Exception('Plataforma no soportada');
  }

  /// Obtiene una lista de archivos JSON en el directorio de importación
  static Future<List<FileSystemEntity>> _listJsonFiles() async {
    try {
      final directory = Directory(await _getDownloadsDirectory());

      final files =
          directory
              .listSync()
              .where((entity) => entity.path.toLowerCase().endsWith('.json'))
              .toList();

      if (files.isEmpty) {
        throw Exception(
          'No se encontraron archivos JSON en la carpeta de descargas',
        );
      }

      return files;
    } catch (e) {
      throw Exception('Error al listar archivos JSON: $e');
    }
  }

  // Método para verificar si hay archivos JSON en el directorio
  static Future<bool> hasJsonFiles() async {
    final files = await _listJsonFiles();
    return files.isNotEmpty;
  }
}
