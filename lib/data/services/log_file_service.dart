import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LogFileService {
  static final LogFileService _instance = LogFileService._internal();
  late File _logFile;
  bool _initialized = false;

  LogFileService._internal();

  factory LogFileService() {
    return _instance;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/app_logs.txt');
    _initialized = true;

    // Check if log file exists and is from a previous day
    if (await _logFile.exists()) {
      final stat = await _logFile.stat();
      final fileDate = DateTime(
        stat.modified.year,
        stat.modified.month,
        stat.modified.day,
      );
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final yesterdayDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
      );

      if (fileDate.isBefore(yesterdayDate)) {
        await _logFile.delete();
        await _logFile.create();
      }
    }
  }

  Future<void> appendLog(String message) async {
    await _ensureInitialized();
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] - $message\n';
    await _logFile.writeAsString(logEntry, mode: FileMode.append);
  }

  Future<String> readLogs() async {
    await _ensureInitialized();
    if (await _logFile.exists()) {
      return await _logFile.readAsString();
    }
    return '';
  }

  Future<void> clearLogs() async {
    await _ensureInitialized();
    if (await _logFile.exists()) {
      await _logFile.delete();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }
}
