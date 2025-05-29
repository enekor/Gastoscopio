import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<bool> init() async {
    bool a =
        SharedPreferencesService().getBool(
          SharedPrefsKeys.isFirstStartup.name,
        ) ??
        true;

    return a;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
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
    );
  }
}
