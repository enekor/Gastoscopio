import 'package:cashly/data/services/notification_capture_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/main_screen.dart';
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
      await SqliteService().initializeDatabase();

      FinanceService.getInstance(
        SqliteService().db.monthDao,
        SqliteService().db.movementValueDao,
        SqliteService().db.fixedMovementDao,
      );

      await NotificationCaptureService().logStatus();

      return true;
    } catch (e) {
      LogFileService().appendLog(
        'Error durante la inicialización: $e',
      );
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

        return MainScreen();
      },
    );
  }
}
