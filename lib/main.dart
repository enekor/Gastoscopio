import 'package:cashly/app.dart';
import 'package:cashly/common/handlers/lifecycle_handler.dart';
import 'package:cashly/data/services/login_service.dart';
import 'package:cashly/data/services/gemini_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar servicio de Gemini para cargar API Key existente
  await GeminiService().initializeGemini();

  // Configurar detector de estado de la app
  bool isInForeground = true;

  // Detectar cuando la app va a segundo plano
  WidgetsBinding.instance.addObserver(
    LifecycleEventHandler(
      resumeCallBack: () async {
        if (!isInForeground) {
          isInForeground = true;
          var a = await LoginService().checkExistingBackup();
          print(
            '----------------------------------------------------------------' +
                a.toString(),
          );
        }
      },
      suspendingCallBack: () async {
        if (isInForeground) {
          isInForeground = false;
          var a = await LoginService().uploadDatabase();
          print(
            '----------------------------------------------------------------' +
                a.toString(),
          );
        }
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Cashly',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme:
                lightDynamic ??
                ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme:
                darkDynamic ??
                ColorScheme.fromSeed(
                  seedColor: Colors.deepPurple,
                  brightness: Brightness.dark,
                ),
          ),
          themeMode: ThemeMode.system,
          home: App(),
        );
      },
    );
  }
}
