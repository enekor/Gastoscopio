import 'package:cashly/app.dart';
import 'package:cashly/onboarding/onboarding.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
