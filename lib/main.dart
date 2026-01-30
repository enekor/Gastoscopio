import 'package:cashly/app.dart';
import 'package:cashly/data/services/auth_service.dart';
import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/groq_serice.dart';
import 'package:cashly/data/services/locale_service.dart';
import 'package:cashly/modules/auth/screens/auth_screen.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:cashly/theme/custom_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el modo de UI del sistema para ocultar la barra de navegación
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );

  // Inicializar servicio de Gemini para cargar API Key existente
  await GeminiService().initializeGemini();
  //await GroqService().initializeGroq();

  // Inicializar servicio de localización
  await LocaleService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocaleService _localeService = LocaleService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _localeService.addListener(_onLocaleChanged);
    LogFileService().initialize();
  }

  @override
  void dispose() {
    _localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Gastoscopio',

          // Configuración de localizaciones
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleService.supportedLocales,
          locale: _localeService.currentLocale,

          theme: CustomTheme.createTheme(lightDynamic),
          darkTheme: CustomTheme.createDarkTheme(darkDynamic),
          themeMode: ThemeMode.system,
          home: FutureBuilder<bool>(
            future: _authService.getUseAuth(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: Loading(context));
              }

              final useAuth = snapshot.data ?? false;
              if (!useAuth) {
                return const App();
              }

              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
