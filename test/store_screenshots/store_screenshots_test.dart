// Generates the Play Store screenshots without an emulator.
//
// Skipped in a normal `flutter test` run. Generate them with:
//   tool/store_screenshots.sh
// or for a single language:
//   flutter test test/store_screenshots \
//     --dart-define=STORE_SCREENSHOTS=true --dart-define=SCREENSHOT_LOCALE=es
//
// Output: screenshots/<locale>/{raw,framed}/*.png and
//         screenshots/<locale>/feature_graphic.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/modules/credit_card/screens/credit_card_screen.dart';
import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';
import 'package:cashly/modules/main_screen.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/app_theme_variant.dart';
import 'package:cashly/theme/custom_theme.dart';
import 'package:cashly/theme/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Transitive dependency (via floor); used only to open sqlite in tests.
// ignore: depend_on_referenced_packages
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'demo_data.dart';

const _enabled = bool.fromEnvironment('STORE_SCREENSHOTS');
const _localeCode = String.fromEnvironment(
  'SCREENSHOT_LOCALE',
  defaultValue: 'es',
);

// Play Store phone screenshots: 9:16, 1080x1920.
const _shotSize = Size(1080, 1920);
const _devicePixelRatio = 2.625; // ~411x731 logical, a typical phone.
const _statusBarHeight = 24.0;
const _themeVariant = AppThemeVariant.etherealLedger;

class _Shot {
  final String file;
  final String title;
  final String subtitle;
  const _Shot(this.file, this.title, this.subtitle);
}

const _copy = {
  'es': {
    'home': _Shot(
      '01_inicio',
      'Tu dinero, de un vistazo',
      'Balance, ingresos y gastos del mes al momento',
    ),
    'history': _Shot(
      '02_historial',
      'Todos tus movimientos',
      'Ordenados por día y con su categoría',
    ),
    'stats': _Shot(
      '03_estadisticas',
      'Descubre a dónde va tu dinero',
      'Gráficos claros por categoría y por mes',
    ),
    'management': _Shot(
      '04_gestion',
      'Gastos fijos bajo control',
      'Nómina, alquiler y suscripciones en automático',
    ),
    'card': _Shot(
      '05_tarjeta',
      'Tu tarjeta de crédito, al día',
      'Límite, gastos y fecha de cobro en una pantalla',
    ),
    'debts': _Shot(
      '06_deudas',
      'Que no se te pase ningún pago',
      'Deudas y pagos pendientes con su vencimiento',
    ),
    'tagline': _Shot(
      '',
      'Gastoscopio',
      'Controla tus gastos sin complicaciones',
    ),
  },
  'en': {
    'home': _Shot(
      '01_home',
      'Your money at a glance',
      'Balance, income and expenses for the month',
    ),
    'history': _Shot(
      '02_history',
      'Every movement, organized',
      'Sorted by day, each with its category',
    ),
    'stats': _Shot(
      '03_statistics',
      'See where your money goes',
      'Clear charts by category and by month',
    ),
    'management': _Shot(
      '04_management',
      'Recurring costs under control',
      'Paycheck, rent and subscriptions on autopilot',
    ),
    'card': _Shot(
      '05_credit_card',
      'Keep your credit card in check',
      'Limit, spending and billing date on one screen',
    ),
    'debts': _Shot(
      '06_debts',
      'Never miss a payment',
      'Pending debts and payments with due dates',
    ),
    'tagline': _Shot('', 'Gastoscopio', 'Track your spending, effortlessly'),
  },
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final demo = _localeCode == 'en' ? demoEn : demoEs;
  final copy = _copy[_localeCode]!;
  final outDir = Directory('screenshots/$_localeCode');
  late Directory tmp;

  setUpAll(() async {
    if (!_enabled) return;
    tmp = Directory.systemTemp.createTempSync('gastoscopio_shots');
    _mockPlatformChannels(binding, tmp.path);
    // Register the Android implementation; its channel is mocked above.
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    // Same factory floor uses on Linux; the app's own sqflite calls
    // (getDatabasesPath) go through it too.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await databaseFactoryFfi.setDatabasesPath(tmp.path);
    SharedPreferences.setMockInitialValues({
      SharedPreferencesKeys.isFirstStartup.value: false,
      SharedPreferencesKeys.currency.value: demo.currency,
      SharedPreferencesKeys.notificationListenerEnabled.value: true,
      SharedPreferencesKeys.creditCardBillingCycle.value: 'monthly',
      SharedPreferencesKeys.creditCardBillingDay.value: 25.0,
      SharedPreferencesKeys.creditCardDefaultLimit.value: 1200.0,
      SharedPreferencesKeys.creditCardHolderName.value: demo.cardHolder,
      SharedPreferencesKeys.themeVariant.value: _themeVariant.storageValue,
    });
    await _loadFonts();
    if (outDir.existsSync()) outDir.deleteSync(recursive: true);
    Directory('${outDir.path}/raw').createSync(recursive: true);
    Directory('${outDir.path}/framed').createSync(recursive: true);
  });

  tearDownAll(() {
    if (_enabled) tmp.deleteSync(recursive: true);
  });

  testWidgets(
    'Play Store screenshots ($_localeCode)',
    (tester) async {
      final l = lookupAppLocalizations(Locale(_localeCode));
      final theme = _deviceLikeTheme(CustomTheme.build(_themeVariant));
      final now = DateTime.now();

      await tester.runAsync(() async {
        await SqliteService().initializeDatabase();
        await seedDemoData(demo, now);
      });

      _setView(
        tester,
        _shotSize,
        _devicePixelRatio,
        topInset: _statusBarHeight,
      );
      final appKey = GlobalKey();
      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        RepaintBoundary(
          key: appKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navKey,
            locale: Locale(_localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: theme,
            darkTheme: theme,
            themeMode: ThemeMode.dark,
            builder: (context, child) => Stack(
              children: [
                // Screens with a transparent AppBar show the window background on a
                // device; paint the app background there instead of transparency.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: Theme.of(
                        context,
                      ).extension<AppGlass>()!.backgroundGradient,
                    ),
                  ),
                ),
                child!,
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _FakeStatusBar(height: _statusBarHeight),
                ),
              ],
            ),
            home: const MainScreen(),
          ),
        ),
      );
      await _settle(tester, rounds: 80);

      final raw = <String, Uint8List>{};
      Future<void> shoot(String id) async {
        await _settle(tester);
        final bytes = await _capture(tester, appKey, _devicePixelRatio);
        raw[id] = bytes;
        File(
          '${outDir.path}/raw/${copy[id]!.file}.png',
        ).writeAsBytesSync(bytes);
      }

      Future<void> openTab(String label) async {
        await tester.tap(
          find.descendant(
            of: find.byType(AppBottomNav),
            matching: find.text(label),
          ),
        );
        await _settle(tester, rounds: 40);
      }

      await shoot('home');
      await openTab(l.navHistory);
      await shoot('history');
      await openTab(l.navStatistics);
      await shoot('stats');
      await openTab(l.navManagement);
      await shoot('management');
      await openTab(l.home);

      navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const CreditCardScreen()),
      );
      await _settle(tester, rounds: 60);
      await shoot('card');
      navKey.currentState!.pop();
      await _settle(tester, rounds: 20);

      navKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const ActiveDebtsScreen()),
      );
      await _settle(tester, rounds: 60);
      await shoot('debts');
      navKey.currentState!.pop();
      await _settle(tester, rounds: 20);

      // ---- Framed versions (headline + phone mockup), 1080x1920 @1x ----
      _setView(tester, _shotSize, 1);
      for (final id in [
        'home',
        'history',
        'stats',
        'management',
        'card',
        'debts',
      ]) {
        final image = await _decode(tester, raw[id]!);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _FramedShot(theme: theme, shot: copy[id]!, screen: image),
          ),
        );
        await _settle(tester, rounds: 4);
        File(
          '${outDir.path}/framed/${copy[id]!.file}.png',
        ).writeAsBytesSync(await _capture(tester, key, 1));
      }

      // ---- Feature graphic, 1024x500 @1x ----
      _setView(tester, const Size(1024, 500), 1);
      final homeImage = await _decode(tester, raw['home']!);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: _FeatureGraphic(
            theme: theme,
            tagline: copy['tagline']!,
            screen: homeImage,
          ),
        ),
      );
      await _settle(tester, rounds: 30);
      File(
        '${outDir.path}/feature_graphic.png',
      ).writeAsBytesSync(await _capture(tester, key, 1));

      // Unmount everything so pending timers/listeners are disposed.
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester, rounds: 5);
    },
    skip: !_enabled,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

// ---------------------------------------------------------------------------
// Harness helpers
// ---------------------------------------------------------------------------

/// The theme's FilledButton text style has no fontFamily. On Android that
/// resolves to Roboto; in tests it resolves to a box-glyph font. Pin Roboto so
/// the capture matches the device.
ThemeData _deviceLikeTheme(ThemeData theme) {
  final style = theme.filledButtonTheme.style ?? const ButtonStyle();
  final textStyle = style.textStyle?.resolve({}) ?? const TextStyle();
  return theme.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: style.copyWith(
        textStyle: WidgetStatePropertyAll(
          textStyle.copyWith(fontFamily: 'Roboto'),
        ),
      ),
    ),
  );
}

void _setView(
  WidgetTester tester,
  Size physical,
  double dpr, {
  double topInset = 0,
}) {
  tester.view.physicalSize = physical;
  tester.view.devicePixelRatio = dpr;
  tester.view.padding = FakeViewPadding(top: topInset * dpr);
  tester.view.viewPadding = FakeViewPadding(top: topInset * dpr);
}

/// Lets real I/O (sqlite runs on another isolate) progress between frames.
Future<void> _settle(WidgetTester tester, {int rounds = 20}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<Uint8List> _capture(
  WidgetTester tester,
  GlobalKey key,
  double pixelRatio,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
    image.dispose();
  });
  return bytes;
}

Future<ui.Image> _decode(WidgetTester tester, Uint8List bytes) async {
  late ui.Image image;
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
  });
  return image;
}

/// The test environment renders text with a placeholder font; load the real
/// ones so the screenshots look like the app.
Future<void> _loadFonts() async {
  Future<void> family(String name, List<Future<ByteData>> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      loader.addFont(f);
    }
    await loader.load();
  }

  Future<ByteData> file(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  final sdkFonts =
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts';

  // Note: assets/fonts/SpaceGrotesk-*.ttf are not valid font files (they are
  // saved HTML pages), so they are not loaded; on a device that family falls
  // back to the default font as well.
  await family('Space Mono', [
    rootBundle.load('assets/fonts/SpaceMono-Regular.ttf'),
    rootBundle.load('assets/fonts/SpaceMono-Bold.ttf'),
  ]);
  await family('Roboto', [
    file('$sdkFonts/Roboto-Regular.ttf'),
    file('$sdkFonts/Roboto-Medium.ttf'),
    file('$sdkFonts/Roboto-Bold.ttf'),
  ]);
  await family('MaterialIcons', [file('$sdkFonts/MaterialIcons-Regular.otf')]);
}

/// Native plugins are not available in tests: answer their channels with
/// neutral values.
void _mockPlatformChannels(TestWidgetsFlutterBinding binding, String tmp) {
  final messenger = binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.tekartik.sqflite'),
    (call) async => call.method == 'getDatabasesPath' ? tmp : null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tmp,
  );
  for (final name in [
    'dexterous.com/flutter/local_notifications',
    'notifications/permissions',
    'x-slayer/notifications_channel',
    'nearby_connections',
    'nearby_connections/events',
    'plugins.flutter.io/google_sign_in',
    'plugins.it_nomads.com/flutter_secure_storage',
    'flutter.baseflow.com/permissions/methods',
    'com.N3k0chan.cashly/settings',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}

// ---------------------------------------------------------------------------
// Visual pieces
// ---------------------------------------------------------------------------

class _FakeStatusBar extends StatelessWidget {
  final double height;
  const _FakeStatusBar({required this.height});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final style = TextStyle(
      color: color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
    );
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: height,
        child: Padding(
          // Wide margins: the phone frame has rounded corners.
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Row(
            children: [
              Text('9:41', style: style),
              const Spacer(),
              Icon(Icons.signal_cellular_alt, size: 15, color: color),
              const SizedBox(width: 4),
              Icon(Icons.wifi, size: 15, color: color),
              const SizedBox(width: 4),
              Icon(Icons.battery_full, size: 15, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

BoxDecoration _brandBackground(ThemeData theme) {
  final scheme = theme.colorScheme;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(scheme.primary, Colors.black, 0.35)!,
        Color.lerp(scheme.surface, Colors.black, 0.2)!,
      ],
    ),
  );
}

class _Phone extends StatelessWidget {
  final ui.Image screen;
  final double width;
  const _Phone({required this.screen, required this.width});

  @override
  Widget build(BuildContext context) {
    final bezel = width * 0.022;
    final radius = width * 0.085;
    return Container(
      width: width,
      height: (width - 2 * bezel) * 16 / 9 + 2 * bezel,
      padding: EdgeInsets.all(bezel),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0F),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF2A2A33), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - bezel),
        child: RawImage(image: screen, fit: BoxFit.cover),
      ),
    );
  }
}

class _FramedShot extends StatelessWidget {
  final ThemeData theme;
  final _Shot shot;
  final ui.Image screen;
  const _FramedShot({
    required this.theme,
    required this.shot,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: _brandBackground(theme),
        padding: const EdgeInsets.fromLTRB(70, 110, 70, 0),
        child: Column(
          children: [
            Text(
              shot.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 70,
                height: 1.1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              shot.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 38,
                height: 1.2,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 70),
            Expanded(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                // Keep the phone at its own 9:16 size (Expanded would stretch it).
                minHeight: 0,
                maxHeight: double.infinity,
                child: _Phone(screen: screen, width: 840),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGraphic extends StatelessWidget {
  final ThemeData theme;
  final _Shot tagline;
  final ui.Image screen;
  const _FeatureGraphic({
    required this.theme,
    required this.tagline,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: _brandBackground(theme),
        child: Stack(
          children: [
            Positioned(
              left: 70,
              top: 0,
              bottom: 0,
              width: 560,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset('assets/logo.svg', height: 96),
                  const SizedBox(height: 24),
                  Text(
                    tagline.title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tagline.subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 30,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 80,
              top: 40,
              child: _Phone(screen: screen, width: 300),
            ),
          ],
        ),
      ),
    );
  }
}
