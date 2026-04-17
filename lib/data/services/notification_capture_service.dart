import 'dart:convert';
import 'dart:typed_data';

import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

/// Service that manages the notification listener permission and state.
///
/// The actual notification capture runs natively in Kotlin
/// (TransactionNotificationListener) and works even when the app is closed.
/// This Dart service only handles permission checking and preference management.
class NotificationCaptureService {
  static final NotificationCaptureService _instance =
      NotificationCaptureService._internal();
  static const _channel = MethodChannel('com.N3k0chan.cashly/settings');

  factory NotificationCaptureService() {
    return _instance;
  }

  NotificationCaptureService._internal();

  Future<bool> isPermissionGranted() async {
    return await NotificationListenerService.isPermissionGranted();
  }

  /// Opens notification listener settings via native Intent and gracefully
  /// finishes the activity. This prevents the "app has stopped" dialog that
  /// Android shows when it kills the process upon permission toggle.
  /// The app will need to be reopened by the user after granting permission.
  Future<void> openNotificationSettingsAndFinish() async {
    await _channel.invokeMethod('openNotificationListenerSettings');
  }

  /// Checks if the service is properly configured (enabled + permission granted).
  Future<bool> isActive() async {
    final enabled = await SharedPreferencesService().getBoolValue(
      SharedPreferencesKeys.notificationListenerEnabled,
    );
    if (enabled != true) return false;

    final hasPermission = await isPermissionGranted();
    return hasPermission;
  }

  /// Returns the list of user-allowed app package names.
  Future<List<String>> getAllowedApps() async {
    return await SharedPreferencesService().getStringListValue(
      SharedPreferencesKeys.notificationAllowedApps,
    );
  }

  /// Adds a package name to the allowed list.
  Future<void> allowApp(String packageName) async {
    final current = await getAllowedApps();
    if (!current.contains(packageName)) {
      current.add(packageName);
      await SharedPreferencesService().setStringValue(
        SharedPreferencesKeys.notificationAllowedApps,
        jsonEncode(current),
      );
    }
  }

  /// Removes a package name from the allowed list.
  Future<void> disallowApp(String packageName) async {
    final current = await getAllowedApps();
    current.remove(packageName);
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.notificationAllowedApps,
      jsonEncode(current),
    );
  }

  /// Returns the app icon as PNG bytes for a given package name.
  Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _channel.invokeMethod<Uint8List>('getAppIcon', {
        'packageName': packageName,
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  /// Returns installed apps via native MethodChannel.
  /// Each map has 'packageName' and 'appName'.
  Future<List<Map<String, String>>> getInstalledApps() async {
    final result = await _channel.invokeListMethod('getInstalledApps');
    if (result == null) return [];
    return result.map((e) => Map<String, String>.from(e as Map)).toList();
  }

  /// Resolves a package name to its human-readable app name.
  Future<String> getAppName(String packageName) async {
    final result = await _channel.invokeMethod<String>('getAppName', {
      'packageName': packageName,
    });
    return result ?? packageName;
  }

  /// Logs the current state for debugging.
  Future<void> logStatus() async {
    final enabled = await SharedPreferencesService().getBoolValue(
      SharedPreferencesKeys.notificationListenerEnabled,
    );
    final hasPermission = await isPermissionGranted();

    LogFileService().appendLog(
      'NotificationCapture status: enabled=$enabled, permission=$hasPermission',
    );
  }
}
