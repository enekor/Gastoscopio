import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/data/services/backup_reminder_service.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late Future<bool> _initializationFuture;
  bool _isInForeground = true;

  @override
  void initState() {
    super.initState();
    _initializationFuture = init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isInForeground) {
          _isInForeground = true;
          // Verificar recordatorio de backup cuando la app vuelve al foreground
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              BackupReminderService.checkAndShowBackupReminder(context);
            }
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isInForeground = false;
        break;
    }
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
