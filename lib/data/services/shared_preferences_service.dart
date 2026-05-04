import 'dart:convert';

import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();

  factory SharedPreferencesService() {
    return _instance;
  }

  SharedPreferencesService._internal();

  /// If a key was stored with a different type in a previous version, reading
  /// with the wrong typed getter throws a TypeError. We log it, remove the
  /// corrupted entry so subsequent reads work, and return the default.
  Future<T?> _safeGet<T>(
    SharedPreferences prefs,
    String key,
    T? Function() reader,
  ) async {
    try {
      return reader();
    } catch (e) {
      await LogFileService().appendLog(
        '[SharedPreferences] Type mismatch reading "$key": $e — removing corrupted key',
      );
      await prefs.remove(key);
      return null;
    }
  }

  Future<void> setStringValue(SharedPreferencesKeys key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString(), value);
  }

  Future<String?> getStringValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGet<String>(prefs, key.toString(), () => prefs.getString(key.toString()));
  }

  Future<double?> getDoubleValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGet<double>(prefs, key.toString(), () => prefs.getDouble(key.toString()));
  }

  Future<void> setDoubleValue(SharedPreferencesKeys key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key.toString(), value);
  }

  Future<List<String>> getStringListValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    final ret = await _safeGet<String>(
      prefs,
      key.toString(),
      () => prefs.getString(key.toString()),
    );
    try {
      return List<String>.from(jsonDecode(ret ?? '[]'));
    } catch (e) {
      await LogFileService().appendLog(
        '[SharedPreferences] Invalid JSON in "$key": $e — resetting',
      );
      await prefs.remove(key.toString());
      return [];
    }
  }

  Future<void> setStringListValue(
    SharedPreferencesKeys key,
    List<String> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString(), jsonEncode(value));
  }

  Future<void> setBoolValue(SharedPreferencesKeys key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key.toString(), value);
  }

  Future<bool?> getBoolValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    return _safeGet<bool>(prefs, key.toString(), () => prefs.getBool(key.toString()));
  }

  Future<void> haveToUpload() async {
    final prefs = await SharedPreferences.getInstance();
    final keyStr = SharedPreferencesKeys.numberOfMovements.toString();
    var ret = await _safeGet<int>(prefs, keyStr, () => prefs.getInt(keyStr));
    if (ret == null || ret <= 4) {
      ret ??= 0;
      ret++;

      await prefs.setInt(keyStr, ret);

      return;
    }

    await LoginService().uploadDatabase();

    await prefs.setInt(keyStr, 1);
  }
}

enum SharedPreferencesKeys {
  isFirstStartup('is_first_startup'),
  apiKey('api_key'),
  currency('currency'),
  avatarColor('avatar_color'),
  isSvgAvatar('is_svg_avatar'),
  numberOfMovements('number_of_movements'),
  isOpaqueBottomNav('is_opaque_bottom_nav'),
  selectedLanguage('selected_language'),
  backgroundImage('background_image'),
  savingGoal('saving_goal'),
  notificationListenerEnabled('notification_listener_enabled'),
  googleWalletNotificationsEnabled('google_wallet_notifications_enabled'),
  notificationAllowedApps('notification_allowed_apps'),
  lastMonthlySummaryPromptShown('last_monthly_summary_prompt_shown');

  final String value;
  const SharedPreferencesKeys(this.value);

  @override
  String toString() => value;
}
