import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static Future<void> setStringValue(
    SharedPreferencesKeys key,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString(), value);
  }

  static Future<String?> getStringValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getString(key.toString());

    return ret;
  }

  static Future<List<String>> getStringListValue(
    SharedPreferencesKeys key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getStringList(key.toString());

    return ret ?? [];
  }

  static void setStringListValue(
    SharedPreferencesKeys key,
    List<String> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key.toString(), value);
  }

  // Suggested code may be subject to a license. Learn more: ~LicenseLog:1442050122.
  static Future<void> setBoolValue(
    SharedPreferencesKeys key,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key.toString(), value);
  }

  static Future<bool> getBoolValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getBool(key.toString());

    return ret ?? false;
  }
}

enum SharedPreferencesKeys { isFirstStartup }
