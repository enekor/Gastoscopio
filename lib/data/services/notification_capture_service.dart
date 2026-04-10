import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart' as p;
import 'dart:async';

class NotificationCaptureService {
  static final NotificationCaptureService _instance =
      NotificationCaptureService._internal();

  factory NotificationCaptureService() {
    return _instance;
  }

  NotificationCaptureService._internal();

  StreamSubscription<ServiceNotificationEvent>? _subscription;

  static final RegExp _currencyRegex = RegExp(
    r'(?:[\$\u20AC]\s?)(\d+(?:[.,]\d{1,2})?)|(\d+(?:[.,]\d{1,2})?)\s?(?:[\$\u20AC])',
  );

  Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  Future<void> requestPermission() async {
    await NotificationListenerService.requestPermission();
  }

  Future<void> initialize() async {
    final enabled = await SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.notificationListenerEnabled);
    if (enabled != true) return;

    final hasPermission = await isPermissionGranted();
    if (!hasPermission) return;

    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = NotificationListenerService.notificationsStream.listen(
      _onNotificationReceived,
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onNotificationReceived(ServiceNotificationEvent event) async {
    try {
      final title = event.title ?? '';
      final content = event.content ?? '';
      final fullText = '$title $content'.trim();
      final appName = event.packageName ?? 'Unknown';

      if (!fullText.contains('\$') &&
          !fullText.contains('\u20AC') &&
          !fullText.contains('€')) {
        return;
      }

      final amount = _extractAmount(fullText);
      if (amount == null || amount <= 0) return;

      await _insertPendingMovement(fullText, appName, amount);
    } catch (e) {
      LogFileService().appendLog('Error processing notification: $e');
    }
  }

  static double? _extractAmount(String text) {
    final matches = _currencyRegex.allMatches(text);
    if (matches.isEmpty) return null;

    for (final match in matches) {
      final value = match.group(1) ?? match.group(2);
      if (value != null) {
        final normalized = value.replaceAll(',', '.');
        final parsed = double.tryParse(normalized);
        if (parsed != null && parsed > 0) return parsed;
      }
    }
    return null;
  }

  Future<void> _insertPendingMovement(
    String text,
    String appName,
    double amount,
  ) async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = p.join(dbPath, 'cashly_database.db');
    final db = await sqflite.openDatabase(path);

    try {
      // Check for duplicates in the last 60 seconds
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(seconds: 60));
      final duplicates = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM PendingNotificationMovement '
        'WHERE notificationText = ? AND appName = ? AND timestamp > ?',
        [text, appName, oneMinuteAgo.toIso8601String()],
      );
      final count = (duplicates.first['cnt'] as int?) ?? 0;
      if (count > 0) return;

      await db.insert('PendingNotificationMovement', {
        'notificationText': text,
        'appName': appName,
        'extractedAmount': amount,
        'timestamp': now.toIso8601String(),
      });
    } finally {
      await db.close();
    }
  }
}
