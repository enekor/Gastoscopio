import 'package:cuentas_android/firebase_options.dart';
import 'package:cuentas_android/pantallas/login/widgetTree.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() async {
  // 1. Initialize WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp(/*options: DefaultFirebaseOptions.windows*/);
  }

  Values().init(kIsWeb);

  // 4. Run the app
  runApp(DynamicColorBuilder(
    builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      return GetMaterialApp(
        title: 'Gastoscopio',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightDynamic ??
              ColorScheme.fromSeed(
                seedColor: Colors.purpleAccent,
                brightness: Brightness.light,
              ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
              ),
        ),
        themeMode: ThemeMode.system,
        home: const Tree(),
        debugShowCheckedModeBanner: false,
      );
    },
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      }),
      title: 'Gastoscopio',
      theme: MyLightTheme,
      darkTheme: MyDarkTheme,
      home: const Tree(),
      debugShowCheckedModeBanner: false,
    );
  }
}
