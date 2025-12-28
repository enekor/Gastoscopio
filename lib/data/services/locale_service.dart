import 'package:cashly/data/services/log_file_service.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  Locale? _currentLocale;

  Locale? get currentLocale => _currentLocale;

  /// Idiomas soportados por la aplicación
  static const List<Locale> supportedLocales = [
    Locale('es', 'ES'), // Español
    Locale('en', 'US'), // Inglés
  ];

  /// Inicializa el idioma de la aplicación
  Future<void> initialize() async {
    final savedLanguage = await SharedPreferencesService().getStringValue(
      SharedPreferencesKeys.selectedLanguage,
    );

    if (savedLanguage != null && savedLanguage != 'system') {
      // Usar idioma seleccionado manualmente
      _currentLocale = Locale(savedLanguage);
    } else {
      // Usar idioma del sistema o null para que Flutter use el predeterminado
      _currentLocale = null;
    }

    notifyListeners();
  }

  /// Obtiene el idioma actual efectivo (incluyendo el del sistema)
  Locale getEffectiveLocale() {
    if (_currentLocale != null) {
      return _currentLocale!;
    }

    // Si no hay idioma establecido, usar el del sistema
    final systemLocale = _getSystemLocale();

    // Verificar si el idioma del sistema está soportado
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == systemLocale.languageCode) {
        return supportedLocale;
      }
    }

    // Si el idioma del sistema no está soportado, usar español por defecto
    return const Locale('es', 'ES');
  }

  /// Cambia el idioma de la aplicación
  Future<void> setLocale(String? languageCode) async {
    if (languageCode == null || languageCode == 'system') {
      // Usar idioma del sistema
      _currentLocale = null;
      await SharedPreferencesService().setStringValue(
        SharedPreferencesKeys.selectedLanguage,
        'system',
      );
    } else {
      // Usar idioma específico
      _currentLocale = Locale(languageCode);
      await SharedPreferencesService().setStringValue(
        SharedPreferencesKeys.selectedLanguage,
        languageCode,
      );
    }

    notifyListeners();
  }

  /// Obtiene el idioma del sistema
  Locale _getSystemLocale() {
    try {
      final systemLocales = WidgetsBinding.instance.platformDispatcher.locales;
      if (systemLocales.isNotEmpty) {
        return systemLocales.first;
      }
    } catch (e) {
      // En caso de error, usar español por defecto
      LogFileService().appendLog('Error obteniendo el locale del sistema: $e');
    }

    // Fallback a español
    return const Locale('es', 'ES');
  }

  /// Obtiene el nombre del idioma actual para mostrar en UI
  String getCurrentLanguageName() {
    final effectiveLocale = getEffectiveLocale();

    switch (effectiveLocale.languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }

  /// Verifica si está usando el idioma del sistema
  bool get isUsingSystemLanguage => _currentLocale == null;

  /// Obtiene el código del idioma seleccionado manualmente (null si es sistema)
  String? get selectedLanguageCode => _currentLocale?.languageCode;
}
