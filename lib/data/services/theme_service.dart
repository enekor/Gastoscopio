import 'package:flutter/material.dart';
import 'package:cashly/theme/design_systems.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';

class ThemeService with ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  DesignSystemType _currentType = DesignSystemType.ethereal;
  
  DesignSystemType get currentDesignSystem => _currentType;
  DesignSystem get designSystem => _currentType == DesignSystemType.ethereal ? EtherealLedger() : ObsidianSystem();

  Future<void> initialize() async {
    final saved = await SharedPreferencesService().getStringValue(SharedPreferencesKeys.designSystem);
    if (saved == 'obsidian') {
      _currentType = DesignSystemType.obsidian;
    } else {
      _currentType = DesignSystemType.ethereal;
    }
    notifyListeners();
  }

  Future<void> setDesignSystem(DesignSystemType type) async {
    _currentType = type;
    await SharedPreferencesService().setStringValue(SharedPreferencesKeys.designSystem, type.name);
    notifyListeners();
  }
}
