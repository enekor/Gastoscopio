import 'dart:io';
import 'dart:typed_data';

import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ExportResult {
  final bool success;
  final String? savedPath;
  final String? error;

  ExportResult._(this.success, this.savedPath, this.error);

  factory ExportResult.ok(String path) => ExportResult._(true, path, null);
  factory ExportResult.fail(String error) => ExportResult._(false, null, error);
  factory ExportResult.cancelled() => ExportResult._(false, null, null);

  bool get wasCancelled => !success && error == null;
}

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Exports all MovementValue rows (across all months) to a CSV file.
  /// Uses file_picker to let the user choose the destination.
  /// Columns: date (YYYY-MM-DD), description, amount, type, category
  Future<ExportResult> exportMovementsToCSV() async {
    try {
      final db = SqliteService().db;
      final months = await db.monthDao.findAllMonths();
      final monthMap = {for (final m in months) m.id: m};

      final rows = <List<String>>[
        ['date', 'description', 'amount', 'type', 'category'],
      ];

      for (final month in months) {
        final movements = await db.movementValueDao
            .findMovementValuesByMonthId(month.id!);
        for (final mv in movements) {
          final m = monthMap[mv.monthId];
          final year = m?.year ?? DateTime.now().year;
          final monthNum = m?.month ?? DateTime.now().month;
          final day = mv.day.clamp(1, 31);
          final dateStr =
              '$year-${monthNum.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          rows.add([
            dateStr,
            mv.description,
            mv.amount.toStringAsFixed(2),
            mv.isExpense ? 'expense' : 'income',
            mv.category ?? '',
          ]);
        }
      }

      final csv = _rowsToCsv(rows);
      final filename =
          'cashly_movements_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Write to a temp file first, then let user pick destination via SAF
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, filename));
      await tempFile.writeAsBytes(
        // BOM so Excel opens UTF-8 correctly
        Uint8List.fromList(
          [0xEF, 0xBB, 0xBF] + csv.codeUnits,
        ),
      );

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV export',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: await tempFile.readAsBytes(),
      );

      if (savedPath == null) {
        return ExportResult.cancelled();
      }

      return ExportResult.ok(savedPath);
    } catch (e, st) {
      LogFileService().appendLog('CSV export failed: $e\n$st');
      return ExportResult.fail(e.toString());
    }
  }

  String _rowsToCsv(List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final escaped = row.map(_escapeCell).join(',');
      buffer.writeln(escaped);
    }
    return buffer.toString();
  }

  String _escapeCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
