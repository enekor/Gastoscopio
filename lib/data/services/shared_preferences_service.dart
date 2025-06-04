import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static final SharedPreferencesService _instance =
      SharedPreferencesService._internal();

  factory SharedPreferencesService() {
    return _instance;
  }

  SharedPreferencesService._internal();

  Future<void> setStringValue(SharedPreferencesKeys key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key.toString(), value);
  }

  Future<String?> getStringValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getString(key.toString());
    return ret;
  }

  Future<List<String>> getStringListValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getStringList(key.toString());
    return ret ?? [];
  }

  Future<void> setStringListValue(
    SharedPreferencesKeys key,
    List<String> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key.toString(), value);
  }

  Future<void> setBoolValue(SharedPreferencesKeys key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key.toString(), value);
  }

  Future<bool?> getBoolValue(SharedPreferencesKeys key) async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getBool(key.toString());
    return ret;
  }
}

enum SharedPreferencesKeys {
  isFirstStartup,
  apiKey,
  currency,
  avatarColor,
  isSvgAvatar,
}
