import 'dart:convert';
import 'dart:io';
import 'package:cashly/data/models/json_import_account.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  static Future<Map<String, dynamic>?> selectAndProcessJsonFile() async {
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

        return processedData;
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

      Account _jsonAccount = Account.fromJson(jsonData);
      Map<String, dynamic> _jsonAccountProccessed = {};
      _jsonAccountProccessed['Months'] = [];
      _jsonAccountProccessed['Movements'] = [];

      if (_jsonAccount.meses == null) return _jsonAccountProccessed;

      int _id = 0;
      for (Meses mes in _jsonAccount.meses!) {
        Month month = Month(
          _monthNames[mes.nMes] ?? -1,
          mes.anno ?? -1,
          id: _id++,
        );
        _jsonAccountProccessed['Months'].add(month);

        _jsonAccountProccessed['Movements'].addAll(
          _processMovementsForMonth(mes.gastos, mes.extras, month.id!),
        );
      }

      return _jsonAccountProccessed;
    } catch (e) {
      throw Exception('Error al parsear JSON: $e');
    }
  }

  /// Procesa todos los movimientos de un mes específico
  static List<MovementValue> _processMovementsForMonth(
    List<Gastos>? gastos,
    List<Gastos>? extras,
    int monthId,
  ) {
    List<MovementValue> movements = [];
    if (gastos != null) {
      movements.addAll(
        gastos
            .where((g) => g.valor! > 0)
            .map(
              (g) => MovementValue(
                null,
                monthId,
                g.nombre ?? '',
                g.valor ?? 0.0,
                true,
                g.dia ?? 1,
                g.tag ?? '',
              ),
            ),
      );

      movements.addAll(
        gastos
            .where((g) => g.valor! < 0)
            .map(
              (g) => MovementValue(
                null,
                monthId,
                g.nombre ?? '',
                -g.valor!,
                false,
                g.dia ?? 1,
                g.tag ?? '',
              ),
            ),
      );
    }

    if (extras != null) {
      movements.addAll(
        extras.map(
          (e) => MovementValue(
            null,
            monthId,
            e.nombre ?? '',
            e.valor ?? 0.0,
            true,
            e.dia ?? 1,
            e.tag ?? '',
          ),
        ),
      );
    }

    return movements;
  }
}
