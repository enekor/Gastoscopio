import 'dart:convert';
import 'dart:io';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:file_picker/file_picker.dart';

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
      // Seleccionar archivo
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

  /// Procesa el contenido JSON y retorna los objetos Month y MovementValue
  static Future<Map<String, dynamic>> _processJsonData(
    String jsonString,
  ) async {
    try {
      Map<String, dynamic> jsonData = json.decode(jsonString);

      List<Month> months = [];
      List<MovementValue> movements = [];

      // Procesar meses
      List<dynamic> mesesData = jsonData['Meses'] ?? [];

      for (int i = 0; i < mesesData.length; i++) {
        Map<String, dynamic> mesData = mesesData[i];

        // Crear objeto Month
        String nombreMes = mesData['NMes'] ?? '';
        int numeroMes = _monthNames[nombreMes] ?? 1;
        int anno = mesData['Anno'] ?? DateTime.now().year;

        Month month = Month(numeroMes, anno);
        months.add(month);

        // Procesar movimientos para este mes
        final monthMovements = _processMovementsForMonth(mesData, i + 1);
        movements.addAll(monthMovements);
      }

      return {'months': months, 'movements': movements};
    } catch (e) {
      throw Exception('Error al parsear JSON: $e');
    }
  }

  /// Procesa todos los movimientos de un mes específico
  static List<MovementValue> _processMovementsForMonth(
    Map<String, dynamic> mesData,
    int monthId,
  ) {
    List<MovementValue> movements = [];
    int movementIdCounter = 1;

    // Procesar Gastos
    List<dynamic> gastos = mesData['Gastos'] ?? [];
    for (Map<String, dynamic> gasto in gastos) {
      double valor = (gasto['valor'] ?? 0.0).toDouble();
      bool isExpense = valor > 0; // Gastos positivos son expenses

      MovementValue movement = MovementValue(
        movementIdCounter++,
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
        movementIdCounter++,
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
        movementIdCounter++,
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
}
