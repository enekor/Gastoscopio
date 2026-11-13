import 'package:flutter/foundation.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/theme/app_theme_variant.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  AppThemeVariant _variant = AppThemeVariant.etherealLedger;
  AppThemeVariant get variant => _variant;

  Future<void> initialize() async {
    final stored = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.themeVariant);
    _variant = AppThemeVariant.fromStorage(stored);
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_variant == variant) return;
    _variant = variant;
    await SharedPreferencesService().setStringValue(
      SharedPreferencesKeys.themeVariant,
      variant.storageValue,
    );
    notifyListeners();
  }
}
