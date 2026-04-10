import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/modules/notifications/screens/pending_notifications_screen.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late Future<bool> _initializationFuture;
  bool _isInForeground = true;
  bool _hasPendingNotifications = false;

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

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   switch (state) {
  //     case AppLifecycleState.resumed:
  //       if (!_isInForeground) {
  //         _isInForeground = true;
  //         // Verificar recordatorio de backup cuando la app vuelve al foreground
  //         WidgetsBinding.instance.addPostFrameCallback((_) {
  //           if (mounted) {
  //             BackupReminderService.checkAndShowBackupReminder(context);
  //           }
  //         });
  //       }
  //       break;
  //     case AppLifecycleState.inactive:
  //     case AppLifecycleState.paused:
  //     case AppLifecycleState.detached:
  //     case AppLifecycleState.hidden:
  //       _isInForeground = false;
  //       break;
  //   }
  // }

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

      // Paso 4: Comprobar notificaciones pendientes
      final pendingCount = await SqliteService()
              .db
              .pendingNotificationMovementDao
              .countAll() ??
          0;
      _hasPendingNotifications = pendingCount > 0;

      return true;
    } catch (e) {
      LogFileService().appendLog(
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
          return Scaffold(body: Center(child: Loading(context)));
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (_hasPendingNotifications) {
          return PendingNotificationsScreen(
            onComplete: () {
              setState(() {
                _hasPendingNotifications = false;
              });
            },
          );
        }

        return MainScreen();
      },
    );
  }
}
