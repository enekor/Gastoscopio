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

  Future<bool> init(BuildContext context) async {
    bool isFirstStartup =
        await SharedPreferencesService().getBoolValue(
          SharedPreferencesKeys.isFirstStartup,
        ) ??
        true;

    if (!isFirstStartup) {
      await SqliteService().initializeDatabase();
    }

    if (!isFirstStartup &&
        await SharedPreferencesService().getStringValue(
              SharedPreferencesKeys.apiKey,
            ) ==
            null) {
      // Delay the dialog slightly to ensure the app is fully rendered
    }

    // Initialize Gemini service and check API key
    await GeminiService().initializeGemini();

    return isFirstStartup;
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => FinanceService(
                SqliteService().database.monthDao,
                SqliteService().database.movementValueDao,
              ),
        ),
      ],
      child: FutureBuilder<bool>(
        future: init(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data == false
                ? const MainScreen()
                : const OnboardingScreen();

            // return MainScreen();
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
