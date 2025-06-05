import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @pragma('vm:prefer-inline')
  Future<(bool, AppDatabase?)> init(BuildContext context) async {
    try {
      // Paso 1: Verificar si es primera ejecución
      final isFirstStartup =
          await SharedPreferencesService().getBoolValue(
            SharedPreferencesKeys.isFirstStartup,
          ) ??
          true;

      // Si es primera ejecución, no necesitamos inicializar la BD
      if (isFirstStartup) {
        return (true, null);
      }

      // Paso 2: Inicializar la base de datos con retry
      AppDatabase? database;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('App.init: Intento $attempt de inicializar base de datos');
          await SqliteService().initializeDatabase();
          database = SqliteService().database;
          debugPrint('App.init: Base de datos inicializada correctamente');
          break;
        } catch (e, stack) {
          debugPrint('App.init: Error en intento $attempt: $e');
          debugPrint('App.init: Stack trace: $stack');
          if (attempt == 3) {
            // Si fallamos 3 veces, reiniciamos como first startup
            debugPrint(
              'App.init: Demasiados intentos fallidos, reiniciando como first startup',
            );
            await SharedPreferencesService().setBoolValue(
              SharedPreferencesKeys.isFirstStartup,
              true,
            );
            return (true, null);
          }
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }
      }

      // Paso 3: Inicializar servicios adicionales
      try {
        await GeminiService().initializeGemini();
      } catch (e) {
        // Error no crítico, podemos continuar
        debugPrint('App.init: Error no crítico inicializando Gemini: $e');
      }

      debugPrint('App.init: Inicialización completada exitosamente');
      return (false, database);
    } catch (e, stack) {
      debugPrint('App.init: Error crítico en inicialización: $e');
      debugPrint('App.init: Stack trace: $stack');
      // En caso de error, volvemos al onboarding
      await SharedPreferencesService().setBoolValue(
        SharedPreferencesKeys.isFirstStartup,
        true,
      );
      return (true, null);
    }
  }

  void _showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Configurar API Key de Gemini'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Para utilizar las funciones de IA, necesitas una API Key de Gemini.\n\n'
                  'Es gratis y fácil de obtener.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Más tarde'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('Ir a configuración'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(bool, AppDatabase?)>(
      future: init(context),
      builder: (context, snapshot) {
        // Asegurarnos de que la inicialización está completa
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        final (isFirstStartup, database) = snapshot.data!;

        // Si es first startup, mostrar onboarding
        if (isFirstStartup) {
          return const MaterialApp(home: OnboardingScreen());
        }

        // Si no tenemos base de datos, algo salió mal
        if (database == null) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al inicializar la aplicación',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        SharedPreferencesService()
                            .setBoolValue(
                              SharedPreferencesKeys.isFirstStartup,
                              true,
                            )
                            .then((_) {
                              // Reiniciar la app como first startup
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const OnboardingScreen(),
                                ),
                              );
                            });
                      },
                      child: const Text('Reiniciar configuración'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create:
                    (_) => FinanceService(
                      database.monthDao,
                      database.movementValueDao,
                      database.fixedMovementDao,
                    ),
              ),
            ],
            child: const MainScreen(),
          ),
        );
      },
    );
  }
}
