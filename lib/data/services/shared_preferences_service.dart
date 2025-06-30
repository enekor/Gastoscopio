import 'package:cashly/data/services/login_service.dart';
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

  Future<void> haveToUpload() async {
    final prefs = await SharedPreferences.getInstance();
    var ret = prefs.getInt(SharedPreferencesKeys.numberOfMovements.toString());
    if (ret == null || ret <= 4) {
      ret ??= 0;
      ret++;

      await prefs.setInt(
        SharedPreferencesKeys.numberOfMovements.toString(),
        ret,
      );

      return;
    }

    await LoginService().uploadDatabase();

    await prefs.setInt(SharedPreferencesKeys.numberOfMovements.toString(), 1);
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
  selectedLanguage('selected_language');

  final String value;
  const SharedPreferencesKeys(this.value);

  @override
  String toString() => value;
}
