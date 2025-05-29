import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<bool> init() async {
    bool a = await SharedPreferencesService.getBoolValue(
      SharedPreferencesKeys.isFirstStartup,
    );

    if (!a) {
      await SqliteService().initializeDatabase();
    }

    return a;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => FinanceService(
                SqliteService().db.monthDao,
                SqliteService().db.movementValueDao,
              ),
        ),
      ],
      child: FutureBuilder<bool>(
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data == true
                ? const OnboardingScreen()
                : const MainScreen();
          }
        },
      ),
    );
  }
}
