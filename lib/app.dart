import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:cashly/modules/settings.dart/settings.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<bool> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = init();
  }

  Future<bool> init() async {
    try {
      // Paso 2: Inicializar la base de datos
      await SqliteService().initializeDatabase();

      // Paso 3: Inicializar FinanceService singleton
      FinanceService.getInstance(
        SqliteService().db.monthDao,
        SqliteService().db.movementValueDao,
        SqliteService().db.fixedMovementDao,
      );

      return true;
    } catch (e) {
      debugPrint(
        'Error durante la inicialización: $e',
      ); // Volver a la pantalla de onboarding en caso de error
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        return MainScreen();
      },
    );
  }
}
