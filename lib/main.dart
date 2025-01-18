import 'package:cuentas_android/firebase_options.dart';
import 'package:cuentas_android/pantallas/login/widgetTree.dart';
import 'package:cuentas_android/themes/DarkTheme.dart';
import 'package:cuentas_android/themes/LightTheme.dart';
import 'package:cuentas_android/values.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  // 1. Initialize WidgetsFlutterBinding
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase

  //no se por que, pero con android ahora da error de instancia duplicada
  if (kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } else {
    await Firebase.initializeApp(

    //windows
        options: DefaultFirebaseOptions.currentPlatform
        );
  }

  // 4. Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     Values().init(kIsWeb,context);
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
