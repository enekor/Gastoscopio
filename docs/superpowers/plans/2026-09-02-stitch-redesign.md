# Stitch "Smart Spend" Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the `stitch_smart_spend_dashboard` design to the cashly/Gastoscopio Flutter app: two selectable dark themes, a reusable glass component library, a 5-slot bottom navigation, and a restyle of all 13 screens — without changing any backend/business logic.

**Architecture:** A `ThemeController` (ChangeNotifier singleton) persists the chosen `AppThemeVariant` and drives `MaterialApp`. `CustomTheme.build(variant)` returns a fixed dark `ThemeData` per variant, plus an `AppGlass` `ThemeExtension` carrying tokens Material's `ColorScheme` can't (glass fill, blur sigma, radii, income/expense colors, background gradient). Screens are rebuilt from a small library of stateless components (`GlassCard`, `PrimaryPillButton`, `AmountText`, `AppSegmentedControl`, `AppListRow`, `StatTile`, `SectionHeader`, `MonthChip`, `AppBackground`, `AppBottomNav`) that read those tokens, so one widget renders correctly in both themes.

**Tech Stack:** Flutter (Dart SDK ^3.8.0), Material 3, `fl_chart` (existing), `shared_preferences` (existing), `flutter_svg` (existing). No new dependencies.

## Global Constraints

- Package name is `cashly`; imports use `package:cashly/...`.
- **Git is read-only in this project: never `git add`/`git commit`.** Each task ends at a verification checkpoint; the user commits. (Ignore the "Commit" step template from the writing-plans skill.)
- No backend/business logic changes: do not alter DB schema, DAO/service method signatures, or `floor` generated code. Only UI/theme/navigation.
- Both themes are **dark**; dynamic color is removed. `themeMode: ThemeMode.dark`.
- Default theme variant: **Ethereal Ledger**.
- **The agent must NOT run `flutter analyze`, `flutter test`, or `flutter run`.** Every step written as `Run: flutter ...` is a **checkpoint the USER executes**. At each checkpoint the agent pauses and asks the user to run the command and report results before continuing.
- Verification cycle for every task: `flutter analyze` must report **no new errors** for touched files, and the app must build. Component tasks add a widget smoke test under `test/` run with `flutter test`. (User runs these.)
- Currency symbol comes from `SharedPreferencesKeys.currency` (fallback `€`).
- Use existing `AppLocalizations` keys where present; only add new keys that are strictly required (theme names).
- Colors (verbatim):
  - Ethereal: bg `#0F172A`, surface `#131315`, emerald `#10B981`, emerald-2 `#4EDEA3`, coral `#FB7185`, onSurface `#E4E2E4`, onSurfaceVariant `#C6C6CD`, outline `#45464D`.
  - Obsidian: bg `#09090B`, surface `#0C0C0F`, surfaceContainer `#18181B`, violet `#A78BFA`, emerald `#34D399`, error `#EF4444`, onSurface `#FAFAFA`, onSurfaceVariant `#A1A1AA`, outline `#27272A`.

---

## File Structure

**New files (theme):**
- `lib/theme/app_theme_variant.dart` — `enum AppThemeVariant`.
- `lib/theme/app_glass.dart` — `AppGlass` ThemeExtension (tokens per variant).
- `lib/theme/theme_controller.dart` — persisted ChangeNotifier singleton.
- `lib/theme/custom_theme.dart` — **rewritten** `CustomTheme.build(variant)`.

**New files (components):**
- `lib/theme/widgets/app_background.dart`
- `lib/theme/widgets/glass_card.dart`
- `lib/theme/widgets/primary_pill_button.dart`
- `lib/theme/widgets/glass_button.dart`
- `lib/theme/widgets/amount_text.dart`
- `lib/theme/widgets/stat_tile.dart`
- `lib/theme/widgets/section_header.dart`
- `lib/theme/widgets/app_segmented_control.dart`
- `lib/theme/widgets/app_list_row.dart`
- `lib/theme/widgets/month_chip.dart`
- `lib/theme/widgets/app_bottom_nav.dart`

**New files (tests):**
- `test/theme/app_glass_test.dart`
- `test/widgets/components_smoke_test.dart`

**Modified files:**
- `lib/main.dart` — remove `DynamicColorBuilder`, wire `ThemeController`.
- `lib/data/services/shared_preferences_service.dart` — add `themeVariant` key.
- `lib/modules/main_screen.dart` — 5-slot nav, centered FAB, remove scan.
- `lib/modules/gastoscopio/screens/home.dart`
- `lib/modules/gastoscopio/screens/active_debts_screen.dart`
- `lib/modules/gastoscopio/screens/movements_screen.dart`
- `lib/modules/gastoscopio/screens/view_movements_filtered_screen.dart`
- `lib/modules/gastoscopio/screens/summary_screen.dart` (+ `widgets/summary_tab_content.dart`, `widgets/category_progress_chart.dart`)
- `lib/modules/gastoscopio/screens/movement_form_screen.dart` — Nuevo (Directo/Puntual + Gasto/Ingreso), remove scan button.
- `lib/modules/gastoscopio/screens/fixed_movements_screen.dart` (+ new `recurring_form_screen.dart`)
- `lib/modules/gastoscopio/widgets/month_grid_selector.dart`
- `lib/modules/gastoscopio/widgets/finance_widgets.dart`, `widgets/movement_tile.dart`
- `lib/modules/credit_card/screens/credit_card_screen.dart` (+ `credit_card_expense_form.dart`, `credit_card_history_screen.dart`)
- `lib/modules/notifications/screens/pending_notifications_screen.dart` (+ `widgets/pending_movement_card.dart`)
- `lib/modules/settings.dart/settings.dart` — theme picker, remove scan entries.
- `lib/l10n/app_localizations_es.dart`, `app_localizations_en.dart`, and the `.arb` sources if present — add theme-name keys.

**Deleted:**
- `lib/modules/image_scan/` (entire module) and all imports/usages.

---

## PHASE 1 — Theme foundation

### Task 1.1: AppThemeVariant enum

**Files:**
- Create: `lib/theme/app_theme_variant.dart`

**Interfaces:**
- Produces: `enum AppThemeVariant { etherealLedger, obsidian }` with `String get storageValue` and `static AppThemeVariant fromStorage(String?)` (defaults to `etherealLedger`), and `String get displayNameKey` returning `'themeEthereal'` / `'themeObsidian'`.

- [ ] **Step 1: Create the enum file**

```dart
enum AppThemeVariant {
  etherealLedger,
  obsidian;

  String get storageValue => switch (this) {
        AppThemeVariant.etherealLedger => 'ethereal_ledger',
        AppThemeVariant.obsidian => 'obsidian',
      };

  /// Localization key for the human-readable name.
  String get displayNameKey => switch (this) {
        AppThemeVariant.etherealLedger => 'themeEthereal',
        AppThemeVariant.obsidian => 'themeObsidian',
      };

  static AppThemeVariant fromStorage(String? value) {
    return AppThemeVariant.values.firstWhere(
      (v) => v.storageValue == value,
      orElse: () => AppThemeVariant.etherealLedger,
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/theme/app_theme_variant.dart`
Expected: No issues.

---

### Task 1.2: AppGlass ThemeExtension

**Files:**
- Create: `lib/theme/app_glass.dart`
- Test: `test/theme/app_glass_test.dart`

**Interfaces:**
- Produces: `class AppGlass extends ThemeExtension<AppGlass>` with fields:
  `Color glassFill`, `double blurSigma`, `Color glassBorder`, `double cardRadius`,
  `double pillRadius`, `Color incomeColor`, `Color expenseColor`, `Color mutedText`,
  `Gradient backgroundGradient`. Plus `static AppGlass ethereal` and
  `static AppGlass obsidian` factories, and `copyWith`/`lerp`.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashly/theme/app_glass.dart';

void main() {
  test('ethereal has blur, obsidian is flat', () {
    expect(AppGlass.ethereal.blurSigma, greaterThan(0));
    expect(AppGlass.obsidian.blurSigma, 0);
  });

  test('lerp returns an AppGlass', () {
    final a = AppGlass.ethereal;
    final b = AppGlass.obsidian;
    final mid = a.lerp(b, 0.5);
    expect(mid, isA<AppGlass>());
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/theme/app_glass_test.dart`
Expected: FAIL (target of URI doesn't exist / AppGlass undefined).

- [ ] **Step 3: Implement AppGlass**

```dart
import 'package:flutter/material.dart';

@immutable
class AppGlass extends ThemeExtension<AppGlass> {
  final Color glassFill;
  final double blurSigma;
  final Color glassBorder;
  final double cardRadius;
  final double pillRadius;
  final Color incomeColor;
  final Color expenseColor;
  final Color mutedText;
  final Gradient backgroundGradient;

  const AppGlass({
    required this.glassFill,
    required this.blurSigma,
    required this.glassBorder,
    required this.cardRadius,
    required this.pillRadius,
    required this.incomeColor,
    required this.expenseColor,
    required this.mutedText,
    required this.backgroundGradient,
  });

  static const AppGlass ethereal = AppGlass(
    glassFill: Color(0x0DFFFFFF), // 5% white
    blurSigma: 20,
    glassBorder: Color(0x14FFFFFF), // 8% white
    cardRadius: 24,
    pillRadius: 999,
    incomeColor: Color(0xFF10B981),
    expenseColor: Color(0xFFFB7185),
    mutedText: Color(0xFFC6C6CD),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF16223B), Color(0xFF0F172A), Color(0xFF0B0B0D)],
      stops: [0.0, 0.45, 1.0],
    ),
  );

  static const AppGlass obsidian = AppGlass(
    glassFill: Color(0xFF18181B),
    blurSigma: 0,
    glassBorder: Color(0xFF27272A),
    cardRadius: 12,
    pillRadius: 10,
    incomeColor: Color(0xFF34D399),
    expenseColor: Color(0xFFEF4444),
    mutedText: Color(0xFFA1A1AA),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0C0C0F), Color(0xFF09090B)],
    ),
  );

  @override
  AppGlass copyWith({
    Color? glassFill,
    double? blurSigma,
    Color? glassBorder,
    double? cardRadius,
    double? pillRadius,
    Color? incomeColor,
    Color? expenseColor,
    Color? mutedText,
    Gradient? backgroundGradient,
  }) {
    return AppGlass(
      glassFill: glassFill ?? this.glassFill,
      blurSigma: blurSigma ?? this.blurSigma,
      glassBorder: glassBorder ?? this.glassBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      pillRadius: pillRadius ?? this.pillRadius,
      incomeColor: incomeColor ?? this.incomeColor,
      expenseColor: expenseColor ?? this.expenseColor,
      mutedText: mutedText ?? this.mutedText,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    );
  }

  @override
  AppGlass lerp(ThemeExtension<AppGlass>? other, double t) {
    if (other is! AppGlass) return this;
    return AppGlass(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      blurSigma: t < 0.5 ? blurSigma : other.blurSigma,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      pillRadius: pillRadius + (other.pillRadius - pillRadius) * t,
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      backgroundGradient: t < 0.5 ? backgroundGradient : other.backgroundGradient,
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/theme/app_glass_test.dart`
Expected: PASS.

---

### Task 1.3: Rewrite CustomTheme

**Files:**
- Modify (replace): `lib/theme/custom_theme.dart`

**Interfaces:**
- Consumes: `AppThemeVariant` (1.1), `AppGlass` (1.2).
- Produces: `static ThemeData CustomTheme.build(AppThemeVariant variant)`.

- [ ] **Step 1: Replace file contents**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_theme_variant.dart';
import 'package:cashly/theme/app_glass.dart';

class CustomTheme {
  static ThemeData build(AppThemeVariant variant) {
    return switch (variant) {
      AppThemeVariant.etherealLedger => _ethereal(),
      AppThemeVariant.obsidian => _obsidian(),
    };
  }

  static ThemeData _ethereal() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFF10B981),
      onPrimary: Color(0xFF04231A),
      primaryContainer: Color(0xFF0E3D2E),
      onPrimaryContainer: Color(0xFF6FFBBE),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF00311F),
      surface: Color(0xFF131315),
      onSurface: Color(0xFFE4E2E4),
      surfaceContainerLowest: Color(0xFF0E0E10),
      surfaceContainerLow: Color(0xFF1B1B1D),
      surfaceContainer: Color(0xFF1F1F21),
      surfaceContainerHigh: Color(0xFF2A2A2B),
      surfaceContainerHighest: Color(0xFF353436),
      onSurfaceVariant: Color(0xFFC6C6CD),
      outline: Color(0xFF45464D),
      outlineVariant: Color(0xFF2A2A2E),
      error: Color(0xFFFB7185),
      onError: Color(0xFF3B0512),
    );
    return _baseFrom(scheme, AppGlass.ethereal, const Color(0xFF0F172A));
  }

  static ThemeData _obsidian() {
    const scheme = ColorScheme.dark(
      primary: Color(0xFFA78BFA),
      onPrimary: Color(0xFF20124D),
      primaryContainer: Color(0xFF2A2440),
      onPrimaryContainer: Color(0xFFCDBEFF),
      secondary: Color(0xFF34D399),
      onSecondary: Color(0xFF00291B),
      tertiary: Color(0xFF34D399),
      surface: Color(0xFF0C0C0F),
      onSurface: Color(0xFFFAFAFA),
      surfaceContainerLowest: Color(0xFF09090B),
      surfaceContainerLow: Color(0xFF121215),
      surfaceContainer: Color(0xFF18181B),
      surfaceContainerHigh: Color(0xFF1F1F23),
      surfaceContainerHighest: Color(0xFF27272A),
      onSurfaceVariant: Color(0xFFA1A1AA),
      outline: Color(0xFF27272A),
      outlineVariant: Color(0xFF27272A),
      error: Color(0xFFEF4444),
      onError: Color(0xFF2A0606),
    );
    return _baseFrom(scheme, AppGlass.obsidian, const Color(0xFF09090B));
  }

  static ThemeData _baseFrom(ColorScheme scheme, AppGlass glass, Color bg) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      extensions: <ThemeExtension<dynamic>>[glass],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(glass.cardRadius),
          side: BorderSide(color: glass.glassBorder, width: 1),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(glass.pillRadius)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          side: BorderSide(color: glass.glassBorder),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(glass.pillRadius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        hintStyle: TextStyle(color: glass.mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: glass.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(glass.cardRadius)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        contentTextStyle: TextStyle(color: scheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        side: BorderSide(color: glass.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/theme/custom_theme.dart`
Expected: No issues (references to old `createTheme`/`createDarkTheme` will now break in `main.dart`; fixed in Task 1.5).

---

### Task 1.4: ThemeController + SharedPreferences key

**Files:**
- Modify: `lib/data/services/shared_preferences_service.dart` (add enum value)
- Create: `lib/theme/theme_controller.dart`

**Interfaces:**
- Consumes: `SharedPreferencesService`, `AppThemeVariant`.
- Produces: `class ThemeController extends ChangeNotifier` singleton with
  `AppThemeVariant get variant`, `Future<void> initialize()`,
  `Future<void> setVariant(AppThemeVariant)`.

- [ ] **Step 1: Add the storage key**

In `lib/data/services/shared_preferences_service.dart`, add to the `SharedPreferencesKeys` enum (after `aiModel('ai_model')`, keep the trailing `;` on the last entry):

```dart
  aiModel('ai_model'),
  themeVariant('theme_variant');
```

- [ ] **Step 2: Create ThemeController**

```dart
import 'package:flutter/foundation.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/theme/app_theme_variant.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController _instance = ThemeController._internal();
  factory ThemeController() => _instance;
  ThemeController._internal();

  AppThemeVariant _variant = AppThemeVariant.etherealLedger;
  AppThemeVariant get variant => _variant;

  Future<void> initialize() async {
    final stored = await SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.themeVariant);
    _variant = AppThemeVariant.fromStorage(stored);
    notifyListeners();
  }

  Future<void> setVariant(AppThemeVariant variant) async {
    if (_variant == variant) return;
    _variant = variant;
    await SharedPreferencesService()
        .setStringValue(SharedPreferencesKeys.themeVariant, variant.storageValue);
    notifyListeners();
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/theme/theme_controller.dart lib/data/services/shared_preferences_service.dart`
Expected: No issues.

---

### Task 1.5: Wire ThemeController into main.dart

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `ThemeController` (1.4), `CustomTheme.build` (1.3).

- [ ] **Step 1: Initialize the controller in `main()`**

After the existing `await LocaleService().initialize();` line, add:

```dart
  await ThemeController().initialize();
```

Add the import at the top:

```dart
import 'package:cashly/theme/theme_controller.dart';
```

- [ ] **Step 2: Listen to the controller and drop DynamicColorBuilder**

In `_MyAppState`, add a field and register/unregister the listener alongside the existing `_localeService` ones:

```dart
  final ThemeController _themeController = ThemeController();
```

In `initState()` add `_themeController.addListener(_onLocaleChanged);` and in
`dispose()` add `_themeController.removeListener(_onLocaleChanged);`
(reusing the existing `_onLocaleChanged` which just calls `setState`).

- [ ] **Step 3: Replace the build body**

Replace the `DynamicColorBuilder(...)` wrapper and the `MaterialApp` `theme`/`darkTheme`/`themeMode` lines. The `MaterialApp` is returned directly (no builder), and:

```dart
          theme: CustomTheme.build(_themeController.variant),
          darkTheme: CustomTheme.build(_themeController.variant),
          themeMode: ThemeMode.dark,
```

Remove the `import 'package:dynamic_color/dynamic_color.dart';` line and add
`import 'package:cashly/theme/custom_theme.dart';` (already imported — keep one).

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/main.dart`
Expected: No issues. App still launches to the same screens (unstyled components come later).

Run: `flutter run` (or hot restart) — confirm the app boots with the new dark Ethereal palette and no crash.

---

## PHASE 2 — Component library

> All components live in `lib/theme/widgets/`. They read `Theme.of(context).colorScheme` and `Theme.of(context).extension<AppGlass>()!`. Add a private helper at top of each file: `AppGlass _glass(BuildContext c) => Theme.of(c).extension<AppGlass>()!;`

### Task 2.1: AppBackground + GlassCard

**Files:**
- Create: `lib/theme/widgets/app_background.dart`
- Create: `lib/theme/widgets/glass_card.dart`

**Interfaces:**
- Produces:
  - `class AppBackground extends StatelessWidget { const AppBackground({required this.child, this.imagePath}); final Widget child; final String? imagePath; }`
  - `class GlassCard extends StatelessWidget { const GlassCard({required this.child, this.padding, this.onTap, this.radius, this.gradientBorder = true}); }`

- [ ] **Step 1: AppBackground**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final String? imagePath;
  const AppBackground({super.key, required this.child, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(gradient: glass.backgroundGradient),
      child: Stack(
        children: [
          if (hasImage)
            Positioned(
              top: 0, left: 0, right: 0,
              height: MediaQuery.of(context).size.height * 0.42,
              child: ShaderMask(
                shaderCallback: (rect) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.transparent],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.file(File(imagePath!), fit: BoxFit.cover),
              ),
            ),
          child,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: GlassCard**

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? radius;
  final bool gradientBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
    this.gradientBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final glass = Theme.of(context).extension<AppGlass>()!;
    final r = radius ?? glass.cardRadius;
    final content = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass.glassFill,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: glass.glassBorder, width: 1),
      ),
      child: child,
    );
    final blurred = glass.blurSigma > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(r),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
              child: content,
            ),
          )
        : content;
    if (onTap == null) return blurred;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: blurred,
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/theme/widgets/app_background.dart lib/theme/widgets/glass_card.dart`
Expected: No issues.

---

### Task 2.2: Buttons — PrimaryPillButton + GlassButton

**Files:**
- Create: `lib/theme/widgets/primary_pill_button.dart`
- Create: `lib/theme/widgets/glass_button.dart`

**Interfaces:**
- Produces:
  - `class PrimaryPillButton extends StatelessWidget { const PrimaryPillButton({required this.label, required this.onPressed, this.icon, this.loading = false, this.expand = true}); }`
  - `class GlassButton extends StatelessWidget { const GlassButton({required this.label, required this.onPressed, this.icon}); }`

- [ ] **Step 1: PrimaryPillButton**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class PrimaryPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;
  const PrimaryPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
      ],
    );
    return SizedBox(
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(glass.pillRadius)),
        ),
        child: loading
            ? SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: scheme.onPrimary))
            : child,
      ),
    );
  }
}
```

- [ ] **Step 2: GlassButton**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const GlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        backgroundColor: glass.glassFill,
        minimumSize: const Size(0, 48),
        side: BorderSide(color: glass.glassBorder),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(glass.pillRadius)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

Run: `flutter analyze lib/theme/widgets/primary_pill_button.dart lib/theme/widgets/glass_button.dart`
Expected: No issues.

---

### Task 2.3: AmountText + StatTile + SectionHeader

**Files:**
- Create: `lib/theme/widgets/amount_text.dart`
- Create: `lib/theme/widgets/stat_tile.dart`
- Create: `lib/theme/widgets/section_header.dart`

**Interfaces:**
- Produces:
  - `class AmountText extends StatelessWidget { const AmountText({required this.amount, required this.currency, this.isExpense, this.signed = false, this.fontSize = 40, this.color}); }` — formats `amount` with 2 decimals; if `signed`, prefixes `+`/`-` and colors by `isExpense` using AppGlass income/expense colors.
  - `class StatTile extends StatelessWidget { const StatTile({required this.label, required this.amount, required this.currency, required this.icon, this.isIncome = true}); }`
  - `class SectionHeader extends StatelessWidget { const SectionHeader({required this.title, this.actionLabel, this.onAction}); }`

- [ ] **Step 1: AmountText**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final String currency;
  final bool? isExpense;
  final bool signed;
  final double fontSize;
  final Color? color;
  const AmountText({
    super.key,
    required this.amount,
    required this.currency,
    this.isExpense,
    this.signed = false,
    this.fontSize = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    String prefix = '';
    Color resolved = color ?? scheme.onSurface;
    if (signed && isExpense != null) {
      prefix = isExpense! ? '-' : '+';
      resolved = color ?? (isExpense! ? glass.expenseColor : glass.incomeColor);
    }
    return Text(
      '$prefix$currency${amount.toStringAsFixed(2)}',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: resolved,
      ),
    );
  }
}
```

- [ ] **Step 2: StatTile** (small income/expense card used on Home)

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';

class StatTile extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final IconData icon;
  final bool isIncome;
  const StatTile({
    super.key,
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    this.isIncome = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final accent = isIncome ? glass.incomeColor : glass.expenseColor;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: glass.mutedText, fontSize: 13)),
          ]),
          const SizedBox(height: 8),
          Text('$currency${amount.toStringAsFixed(2)}',
              style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: SectionHeader**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: TextStyle(
                      color: scheme.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/theme/widgets/amount_text.dart lib/theme/widgets/stat_tile.dart lib/theme/widgets/section_header.dart`
Expected: No issues.

---

### Task 2.4: AppSegmentedControl + AppListRow + MonthChip

**Files:**
- Create: `lib/theme/widgets/app_segmented_control.dart`
- Create: `lib/theme/widgets/app_list_row.dart`
- Create: `lib/theme/widgets/month_chip.dart`

**Interfaces:**
- Produces:
  - `class AppSegmentedControl<T> extends StatelessWidget { const AppSegmentedControl({required this.segments, required this.selected, required this.onChanged}); final List<({T value, String label, IconData? icon})> segments; final T selected; final ValueChanged<T> onChanged; }`
  - `class AppListRow extends StatelessWidget { const AppListRow({required this.title, this.subtitle, this.chip, this.leadingIcon, this.trailing, this.onTap}); }`
  - `class MonthChip extends StatelessWidget { const MonthChip({required this.label, required this.onTap}); }`

- [ ] **Step 1: AppSegmentedControl**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

typedef SegmentSpec<T> = ({T value, String label, IconData? icon});

class AppSegmentedControl<T> extends StatelessWidget {
  final List<SegmentSpec<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  const AppSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(glass.pillRadius),
        border: Border.all(color: glass.glassBorder),
      ),
      child: Row(
        children: segments.map((s) {
          final isSel = s.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(s.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSel ? scheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(glass.pillRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (s.icon != null) ...[
                      Icon(s.icon,
                          size: 18,
                          color: isSel ? scheme.onPrimary : glass.mutedText),
                      const SizedBox(width: 6),
                    ],
                    Text(s.label,
                        style: TextStyle(
                            color: isSel ? scheme.onPrimary : glass.mutedText,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 2: AppListRow** (movement/debt/expense row with circular icon)

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';
import 'package:cashly/theme/widgets/glass_card.dart';

class AppListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? chip;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.chip,
    this.leadingIcon,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(leadingIcon ?? Icons.receipt_long,
                size: 20, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                if (subtitle != null || chip != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    if (chip != null) chip!,
                    if (chip != null && subtitle != null)
                      const SizedBox(width: 8),
                    if (subtitle != null)
                      Text(subtitle!,
                          style:
                              TextStyle(color: glass.mutedText, fontSize: 12)),
                  ]),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: MonthChip**

```dart
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

class MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const MonthChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: glass.glassBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label,
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down,
              size: 18, color: scheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/theme/widgets/app_segmented_control.dart lib/theme/widgets/app_list_row.dart lib/theme/widgets/month_chip.dart`
Expected: No issues.

---

### Task 2.5: Components smoke test

**Files:**
- Create: `test/widgets/components_smoke_test.dart`

- [ ] **Step 1: Write the test** (renders each component inside both themes without throwing)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cashly/theme/app_theme_variant.dart';
import 'package:cashly/theme/custom_theme.dart';
import 'package:cashly/theme/widgets/glass_card.dart';
import 'package:cashly/theme/widgets/primary_pill_button.dart';
import 'package:cashly/theme/widgets/amount_text.dart';
import 'package:cashly/theme/widgets/app_segmented_control.dart';
import 'package:cashly/theme/widgets/app_list_row.dart';

Widget _host(AppThemeVariant v, Widget child) => MaterialApp(
      theme: CustomTheme.build(v),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  for (final v in AppThemeVariant.values) {
    testWidgets('components render in $v', (tester) async {
      await tester.pumpWidget(_host(
        v,
        Column(children: [
          const GlassCard(child: Text('card')),
          PrimaryPillButton(label: 'Save', onPressed: () {}),
          const AmountText(amount: 12.5, currency: '€', isExpense: true, signed: true),
          AppSegmentedControl<bool>(
            segments: const [
              (value: true, label: 'A', icon: null),
              (value: false, label: 'B', icon: null),
            ],
            selected: true,
            onChanged: (_) {},
          ),
          const AppListRow(title: 'Row', subtitle: 'sub'),
        ]),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Save'), findsOneWidget);
    });
  }
}
```

- [ ] **Step 2: Run**

Run: `flutter test test/widgets/components_smoke_test.dart`
Expected: PASS for both variants.

---

## PHASE 3 — Navigation

### Task 3.1: AppBottomNav (5-slot with centered FAB notch)

**Files:**
- Create: `lib/theme/widgets/app_bottom_nav.dart`

**Interfaces:**
- Produces: `class AppBottomNav extends StatelessWidget { const AppBottomNav({required this.items, required this.selectedIndex, required this.onSelected}); final List<({IconData icon, IconData selectedIcon, String label})> items; final int selectedIndex; final ValueChanged<int> onSelected; }`
  - Renders exactly `items.length` tabs (expect 4) evenly, leaving a visual gap in the center for the FAB. Uses a glass container with rounded top corners.

- [ ] **Step 1: Implement** (4 tabs split 2 + gap + 2)

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cashly/theme/app_glass.dart';

typedef NavItem = ({IconData icon, IconData selectedIcon, String label});

class AppBottomNav extends StatelessWidget {
  final List<NavItem> items; // expect length 4
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const AppBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final glass = Theme.of(context).extension<AppGlass>()!;
    final left = items.take(2).toList();
    final right = items.skip(2).toList();

    Widget tab(NavItem item, int index) {
      final sel = index == selectedIndex;
      return Expanded(
        child: InkWell(
          onTap: () => onSelected(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(sel ? item.selectedIcon : item.icon,
                  color: sel ? scheme.primary : glass.mutedText, size: 24),
              const SizedBox(height: 2),
              Text(item.label,
                  style: TextStyle(
                      fontSize: 11,
                      color: sel ? scheme.primary : glass.mutedText)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: glass.blurSigma, sigmaY: glass.blurSigma),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: glass.blurSigma > 0
                ? scheme.surface.withOpacity(0.75)
                : scheme.surfaceContainer,
            border: Border(top: BorderSide(color: glass.glassBorder)),
          ),
          child: Row(children: [
            tab(left[0], 0),
            tab(left[1], 1),
            const SizedBox(width: 72), // gap for the FAB
            tab(right[0], 2),
            tab(right[1], 3),
          ]),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

Run: `flutter analyze lib/theme/widgets/app_bottom_nav.dart`
Expected: No issues.

---

### Task 3.2: Restructure MainScreen (4 tabs + centered FAB, remove scan)

**Files:**
- Modify: `lib/modules/main_screen.dart`

**Interfaces:**
- Consumes: `AppBottomNav` (3.1), `AppBackground` (2.1), `MonthChip` (2.4),
  `ActiveDebtsScreen`, `MovementsScreen`, `SummaryScreen`, `GastoscopioHomeScreen`,
  `MovementFormScreen`.

- [ ] **Step 1: Change tab count to 4 and screen list**

- Change `TabController(length: 3, ...)` to `length: 4`.
- Replace `_screens` getter with:

```dart
  List<Widget> get _screens => [
    GastoscopioHomeScreen(key: const ValueKey('home'), year: _year, month: _month),
    ActiveDebtsScreen(key: const ValueKey('debts')),
    MovementsScreen(key: const ValueKey('movements'), year: _year, month: _month),
    const SummaryScreen(key: ValueKey('summary')),
  ];
```

Add import: `import 'package:cashly/modules/gastoscopio/screens/active_debts_screen.dart';`

> Note: verify `ActiveDebtsScreen`'s constructor — if it currently requires no
> args this is correct; if it takes `year`/`month`, pass `_year`/`_month`.

- [ ] **Step 2: Remove scan plumbing**

- Delete the `_pickAndScanImage` method.
- Remove the `import '.../image_scan/screens/image_scan_screen.dart';` and
  `import 'package:file_picker/file_picker.dart';` if now unused.
- In the FAB `onPressed`, replace the `showModalBottomSheet` result handling with:

```dart
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovementFormScreen()),
              );
              setState(() {}); // refresh after returning
            },
```

- [ ] **Step 3: Swap the bottom bar + FAB location**

- Replace `bottomNavigationBar:` with:

```dart
          bottomNavigationBar: AppBottomNav(
            selectedIndex: _selectedIndex,
            onSelected: _onDestinationSelected,
            items: [
              (icon: Icons.home_outlined, selectedIcon: Icons.home, label: AppLocalizations.of(context)!.navHome),
              (icon: Icons.credit_score_outlined, selectedIcon: Icons.credit_score, label: AppLocalizations.of(context)!.navDebts),
              (icon: Icons.history, selectedIcon: Icons.history, label: AppLocalizations.of(context)!.navHistory),
              (icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: AppLocalizations.of(context)!.navStats),
            ],
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: FloatingActionButton(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 30),
            onPressed: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MovementFormScreen()));
              setState(() {});
            },
          ),
```

- Keep `extendBody: true`. Wrap the existing body `Stack` content in
  `AppBackground(imagePath: _backgroundImagePath, child: ...)` and remove the
  old manual gradient/background `Positioned` block (now handled by AppBackground).
- Update the `SliverAppBar` `actions`/`title`: put `MonthChip` (calling
  `_showMonthSelector`) as a leading widget when `_selectedIndex != 3`, the
  screen title centered, and keep the settings `IconButton`. Remove the separate
  calendar `IconButton`.

> Fallback for i18n keys `navHome/navDebts/navHistory/navStats`: if the keys are
> not yet added (Task 5.x), temporarily use literals `'Inicio'`, `'Deudas'`,
> `'Historial'`, `'Estadísticas'`. Prefer adding the keys.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/modules/main_screen.dart`
Expected: No issues (image_scan import removed).

Run: `flutter run` — confirm 4 tabs + centered green FAB; tapping FAB opens the
Nuevo screen; Deudas tab shows the debts screen.

---

## PHASE 4 — Screens

> **Convention for every screen task:** Preserve ALL existing state, controllers,
> service calls, and handler method names — only replace the *presentation*
> (widget tree, colors, spacing) with the component library. Each implementing
> subagent should first read the target file to learn the exact existing handler
> names, then swap the visual layer. Wrap each screen body in scrollable content
> over the transparent scaffold (the `AppBackground` is provided by MainScreen for
> tabbed screens; pushed screens set their own `Scaffold(backgroundColor: Colors.transparent)`
> inside an `AppBackground`). Data getters referenced below already exist on
> `FinanceService` / `CreditCardService`.

### Task 4.1: Home (inicio)

**Files:**
- Modify: `lib/modules/gastoscopio/screens/home.dart`
- Modify (as needed): `lib/modules/gastoscopio/widgets/main_screen_widgets.dart`

**Design:** `inicio/screen.png` — Balance total hero, "N nuevos movimientos" banner,
Ingresos/Gastos stat tiles, "Gastos Recientes"+"Ver todos", Vencimiento + Billetera cards.

**Data (existing):** `FinanceService` `monthTotal`, `monthIncomes`, `monthExpenses`,
`todayMovements`; pending count via `PendingNotificationMovementDao`; currency from
`SharedPreferencesKeys.currency`.

- [ ] **Step 1: Build the hero balance card**

Replace the balance display with a centered `GlassCard`:

```dart
GlassCard(
  child: Column(children: [
    Text(AppLocalizations.of(context)!.totalBalance.toUpperCase(),
        style: TextStyle(letterSpacing: 1.5, color: glass.mutedText, fontSize: 12)),
    const SizedBox(height: 8),
    AmountText(amount: financeService.monthTotal, currency: currency, fontSize: 44),
  ]),
),
```
(`final glass = Theme.of(context).extension<AppGlass>()!;` and read `currency` from state.)

- [ ] **Step 2: Pending-movements banner → notifications**

Render only when pending count > 0; tap navigates to `PendingNotificationsScreen`
(keep the existing navigation call already used in this file):

```dart
GlassCard(
  onTap: _openPendingNotifications, // existing handler / navigation
  child: Row(children: [
    Icon(Icons.notifications_active, color: scheme.primary),
    const SizedBox(width: 12),
    Expanded(child: Text(AppLocalizations.of(context)!.newMovementsBanner(pendingCount))),
    const Icon(Icons.chevron_right),
  ]),
),
```

- [ ] **Step 3: Ingresos/Gastos row**

```dart
Row(children: [
  Expanded(child: StatTile(label: AppLocalizations.of(context)!.income,
      amount: financeService.monthIncomes, currency: currency,
      icon: Icons.arrow_upward, isIncome: true)),
  const SizedBox(width: 12),
  Expanded(child: StatTile(label: AppLocalizations.of(context)!.expenses,
      amount: financeService.monthExpenses, currency: currency,
      icon: Icons.arrow_downward, isIncome: false)),
]),
```

- [ ] **Step 4: Recent movements + Vencimiento/Billetera cards**

- Add `SectionHeader(title: 'Gastos Recientes', actionLabel: 'Ver todos', onAction: ...)`
  where `onAction` switches to the Historial tab (expose a callback from MainScreen or
  navigate). Render `financeService.todayMovements` (or recent) as `AppListRow`s with
  `AmountText(signed:true, isExpense: m.isExpense, fontSize: 15)` as trailing.
- Keep the existing quick-action navigations but reshape the "Vencimiento" card
  (→ Deudas tab / `ActiveDebtsScreen`) and "Billetera/Premium Card" card
  (→ `CreditCardScreen`, route `/credit_card`) as two `GlassCard`s in a Row.

- [ ] **Step 5: Checkpoint (user runs)**

Run: `flutter analyze lib/modules/gastoscopio/screens/home.dart`
Then `flutter run` and visually compare Home to `inicio/screen.png`.

---

### Task 4.2: Deudas (gestión de deudas)

**Files:**
- Modify: `lib/modules/gastoscopio/screens/active_debts_screen.dart`

**Design:** `gesti_n_de_deudas/screen.png` — "Total pendiente" card + progress,
sections Mes Anterior (URGENTE) / Recurrentes / Puntuales, each row with
"Pagar/Resolver".

**Data (existing):** `FinanceService.getVisiblePendingDebtsForCurrentMonth()` →
`List<DebtViewItem>` (`.definition`, `.occurrence`, `.month`); complete via
`FinanceService.completeDebtOccurrence(occurrence)`.

- [ ] **Step 1: Hero "Total pendiente"**

Sum `items` amounts into a `GlassCard` with `AmountText` and a progress bar
(`LinearProgressIndicator` themed with `scheme.primary`). Compute paid ratio from
completed vs pending if available, else show pending total only.

- [ ] **Step 2: Group into sections**

Split `items` into: overdue (occurrence.month before current → URGENTE badge, coral),
recurrentes (`definition.recurrenceType == debtRecurrenceMonthly`), puntuales
(`debtRecurrenceOneTime`). Each group gets a `SectionHeader`. Render each item as
`AppListRow` with `leadingIcon` by category, trailing `AmountText`, and a
`PrimaryPillButton(label: 'Pagar', expand:false, onPressed: () => _complete(item))`
calling the existing `completeDebtOccurrence` + reload.

- [ ] **Step 3: Keep create buttons**

Preserve the existing "Create Monthly Debt" → recurring form and "Create Debt"
(`MovementFormScreen(forceDebtMode:true)`) actions, restyled as `GlassButton`s in
the app bar or a header row.

- [ ] **Step 4: Checkpoint (user runs)**

Run: `flutter analyze lib/modules/gastoscopio/screens/active_debts_screen.dart`; then visual check vs design.

---

### Task 4.3: Historial (movements_screen)

**Files:**
- Modify: `lib/modules/gastoscopio/screens/movements_screen.dart`
- Modify: `lib/modules/gastoscopio/widgets/movement_tile.dart`

**Design:** `historial_con_filtros_y_ordenaci_n/screen.png` — pill tabs
Todos/Ingresos/Gastos, search field, sort icon, date-grouped list with balance header.

- [ ] **Step 1: Replace the expense/income toggle** with `AppSegmentedControl<int>`
(0 Todos / 1 Ingresos / 2 Gastos). Wire selection to the existing filter state
(add a "Todos" case that shows both; keep existing expense/income filtering logic).

- [ ] **Step 2: Restyle the search + sort toolbar** using themed `TextField`
(rounded, `Icons.search` prefix) and a `GlassButton`/icon for the existing sort
bottom sheet. Keep the existing sort and auto-tag handlers.

- [ ] **Step 3: Restyle rows** — update `movement_tile.dart` to the `AppListRow`
look: circular category icon, title, category chip, trailing signed `AmountText`.
Preserve the existing expand/edit/delete/date/category interactions and swipe.

- [ ] **Step 4: Balance header** — keep the gradient total card but rebuild as a
`GlassCard` showing month name + count + signed total.

- [ ] **Step 5: Checkpoint (user runs)**

Run: `flutter analyze` on both files; visual check vs design.

---

### Task 4.4: Buscador avanzado (view_movements_filtered_screen)

**Files:**
- Modify: `lib/modules/gastoscopio/screens/view_movements_filtered_screen.dart`

**Design:** `buscador_de_movimientos_avanzado/screen.png` — search bar, DATE RANGE
month chips row, "MATCHES (n)" + result rows.

- [ ] **Step 1:** Replace the app bar/search with a themed `TextField`.
- [ ] **Step 2:** Replace the date-range picker trigger with a wrap of selectable
month chips (use `ChoiceChip` themed, or small `GestureDetector` pills) that map to
the existing date-range state; keep `showDateRangePicker` as an optional "custom"
action. Keep the existing multi-month movement loading logic.
- [ ] **Step 3:** Render results as `AppListRow` with signed `AmountText`; keep the
sticky total footer as a `GlassCard`.
- [ ] **Step 4: Checkpoint (user runs)** `flutter analyze` + visual check.

---

### Task 4.5: Estadísticas (summary_screen + tab content + chart)

**Files:**
- Modify: `lib/modules/gastoscopio/screens/summary_screen.dart`
- Modify: `lib/modules/gastoscopio/widgets/summary_tab_content.dart`
- Modify: `lib/modules/gastoscopio/widgets/category_progress_chart.dart`

**Design:** `estad_sticas_y_resumen/screen.png` — "Resumen Financiero" (Ahorro neto
big + %), Ingresos/Gastos tiles, "Evolución" line chart (glow), "Distribución" donut
+ legend.

- [ ] **Step 1:** "Resumen Financiero" `GlassCard` with `AmountText` for net savings
(`monthTotal`) colored by sign; Ingresos/Gastos as `StatTile`s. Data from existing
`FinanceService` getters and `getYearlyData(year)` for the chart.
- [ ] **Step 2:** Restyle the `fl_chart` line chart: remove grid/axes chrome, use a
1.5–2px `scheme.primary` line with a vertical gradient fill (emerald→transparent)
via `LineChartBarData(belowBarData: BarAreaData(gradient: ...))`. Keep the existing
"Este Año" selector.
- [ ] **Step 3:** Restyle `category_progress_chart.dart`: either keep progress bars
(themed with `scheme.primary` and category colors) or a `fl_chart` donut per design;
show a legend with percentages from existing `getCategoryTotals()`.
- [ ] **Step 4:** Keep the AI-analysis tab; restyle its "Generate" button as
`PrimaryPillButton` and markdown container as a `GlassCard`.
- [ ] **Step 5: Checkpoint (user runs)** `flutter analyze` on the three files + visual check.

---

### Task 4.6: Tarjeta de crédito (screen + form + history)

**Files:**
- Modify: `lib/modules/credit_card/screens/credit_card_screen.dart`
- Modify: `lib/modules/credit_card/screens/credit_card_expense_form.dart`
- Modify: `lib/modules/credit_card/screens/credit_card_history_screen.dart`

**Design:** `tarjeta_de_cr_dito/screen.png` — "Premium card" visual, "Saldo Utilizado"
+ progress vs limit, Próximo Pago / Cierre Facturación cards, info note; FAB add.

**Data (existing):** `CreditCardService` (currentMonth, currentExpenses, limit),
`addExpense/updateExpense/deleteExpense`, `getDefaultLimit`, billing prefs
(`creditCardBillingDay`, `creditCardBillingCycle`).

- [ ] **Step 1:** Build the credit-card visual as a `GlassCard` with a subtle gradient
(navy/emerald), masked number `**** 4921`, holder, expiry; keep the existing sync
button in the corner.
- [ ] **Step 2:** "Saldo Utilizado" `GlassCard` with `AmountText`, a
`LinearProgressIndicator` (used/limit), and the limit row; tap opens the existing
limit dialog.
- [ ] **Step 3:** Próximo Pago / Cierre Facturación as two `GlassCard`s computed from
the existing billing-day/cycle prefs (reuse current computation; do not add logic).
- [ ] **Step 4:** Info note `GlassCard` (existing copy). Restyle expenses list as
`AppListRow`s (keep swipe edit/delete). FAB → `CreditCardExpenseForm`. Restyle the
form fields and history expansion tiles with themed containers.
- [ ] **Step 5: Checkpoint (user runs)** `flutter analyze` on the three files + visual check.

---

### Task 4.7: Recurrentes (fixed_movements_screen) + new recurring form

**Files:**
- Modify: `lib/modules/gastoscopio/screens/fixed_movements_screen.dart`
- Create: `lib/modules/gastoscopio/screens/recurring_form_screen.dart`

**Design:** `movimientos_recurrentes/screen.png` (list) +
`nuevo_movimiento_selector_recurrente/screen.png` (create).

**Data (existing):** fixed movements + monthly debts from `SqliteService` /
`FinanceService`; create via `FixedMovementDao.insertFixedMovement` (fixed) and
`FinanceService.createMonthlyDebtDefinition(...)` (recurring debt). Keep
convert/edit/delete handlers.

- [ ] **Step 1: List screen** — "Total mensual estimado" `GlassCard`, then a
"Próximos Cobros" section rendering both fixed movements and monthly debts as
`AppListRow`/`GlassCard`s with Detalles / Editar (existing dialogs) and, for debts,
a Completar action. Preserve swipe-convert/delete. Replace the FAB bottom-sheet
chooser with a single FAB `+` → `RecurringFormScreen`.

- [ ] **Step 2: RecurringFormScreen** — new screen mirroring the design:

```dart
// Fields: amount (big), name, category, type segmented, frequency, chargeDay.
// Type: AppSegmentedControl<bool>(true=Gasto Recurrente, false=Deuda Recurrente)
// On save:
if (isRecurringExpense) {
  await SqliteService().db.fixedMovementDao.insertFixedMovement(
    FixedMovement(null, name, amount, /*isExpense*/ true, chargeDay, category));
} else {
  await FinanceService.getInstance(/*daos*/).createMonthlyDebtDefinition(
    description: name, amount: amount, isExpense: true, day: chargeDay, category: category);
}
```
Frequency shows "Mensual" (only supported value). Save button = `PrimaryPillButton`.
Reuse the existing daos/service instances the file already constructs.

- [ ] **Step 3: Checkpoint (user runs)** `flutter analyze` on both files + visual check.

---

### Task 4.8: Notificaciones pendientes (pending_notifications + card)

**Files:**
- Modify: `lib/modules/notifications/screens/pending_notifications_screen.dart`
- Modify: `lib/modules/notifications/widgets/pending_movement_card.dart`

**Design:** `movimientos_de_notificaciones/screen.png` — cards with app icon, editable
name/amount, Gasto/Ingreso toggle, TARJETA chip, "Procesar Seleccionados" button.

- [ ] **Step 1:** Rebuild `PendingMovementCard` as a `GlassCard`: leading app icon,
name + amount editable fields (themed), `AppSegmentedControl<bool>` for expense/income,
optional TARJETA chip, delete/disallow icons. Keep the existing
`EditablePendingMovement` controllers and callbacks.
- [ ] **Step 2:** Restyle the date-chip row and info banner; replace the bottom save
button with `PrimaryPillButton(label: 'Procesar Seleccionados', ...)` calling the
existing save-all handler.
- [ ] **Step 3: Checkpoint (user runs)** `flutter analyze` on both files + visual check.

---

### Task 4.9: Selección de mes (month_grid_selector)

**Files:**
- Modify: `lib/modules/gastoscopio/widgets/month_grid_selector.dart`

**Design:** `selecci_n_de_mes/screen.png` — AÑO with arrows, 3×4 month grid, selected
month emerald-outlined with total, "Confirmar Selección" button.

- [ ] **Step 1:** Restyle year header (left/right arrow `GlassButton`/icon + big year).
- [ ] **Step 2:** Rebuild the grid: each month a `GlassCard`/pill; unavailable months
dimmed; selected month uses `scheme.primary` outline + emerald text; keep the existing
`onMonthChanged`/`onYearChanged` callbacks. Optionally show per-month total if already
available; otherwise omit the amount (no new backend call).
- [ ] **Step 3:** Since this is used inside a dialog from MainScreen, keep the callback
contract identical. (The "Confirmar" button is optional — current UX confirms on tap.)
- [ ] **Step 4: Checkpoint (user runs)** `flutter analyze` + visual check.

---

### Task 4.10: Nuevo (movement_form_screen) — Directo/Puntual + Gasto/Ingreso

**Files:**
- Modify: `lib/modules/gastoscopio/screens/movement_form_screen.dart`

**Design:** `nuevo_gasto/screen.png`.

- [ ] **Step 1: Convert to a full screen** presentation (it is already pushed as a
route from MainScreen now). Header: back + "Nuevo" + settings icon (optional). Wrap in
`AppBackground`.

- [ ] **Step 2: Top toggle Gasto | Ingreso** using `AppSegmentedControl<bool>`
bound to `widget.isExpense` (true=Gasto). Accent follows income/expense color.

- [ ] **Step 3: Fields** — Name `TextFormField`, Category chip (keep the existing
Groq auto-category behavior; the chip shows/sets `_category`), big Valor field
(themed, large font) with currency prefix, Fecha row (existing `_selectDate`).

- [ ] **Step 4: Tipo de Movimiento** — `AppSegmentedControl<bool>`
(true=Gasto Directo, false=Deuda Puntual) bound to `_createAsOneTimeDebt`
(inverted: Directo → `_createAsOneTimeDebt=false`; Deuda Puntual → `true`). Keep the
existing `_saveMovement` logic (it already branches on `_createAsOneTimeDebt`).

- [ ] **Step 5: Remove scan** — delete the `OutlinedButton.icon` that returns
`'scan'` (and any `scan` handling). Save button = `PrimaryPillButton`
(label "Guardar Gasto"/"Guardar Ingreso" per toggle).

- [ ] **Step 6: Checkpoint (user runs)** `flutter analyze` on the file; create a
direct expense, an income, and a one-time debt to confirm each path still writes.

---

### Task 4.11: Ajustes (settings) — restyle + theme picker

**Files:**
- Modify: `lib/modules/settings.dart/settings.dart`
- Modify (if referenced): the widget cards under `lib/modules/settings.dart/widgets/`

**Design:** `configuraci_n/screen.png` — sectioned cards.

- [ ] **Step 1:** Wrap sections in `GlassCard`s with `SectionHeader`s; restyle toggles,
dropdowns, and buttons to the theme. Preserve every existing setting handler.

- [ ] **Step 2: Add a Theme selector** in the "Aspecto Visual" section:

```dart
// Read current: ThemeController().variant
AppSegmentedControl<AppThemeVariant>(
  segments: [
    (value: AppThemeVariant.etherealLedger, label: AppLocalizations.of(context)!.themeEthereal, icon: Icons.auto_awesome),
    (value: AppThemeVariant.obsidian, label: AppLocalizations.of(context)!.themeObsidian, icon: Icons.dark_mode),
  ],
  selected: ThemeController().variant,
  onChanged: (v) async { await ThemeController().setVariant(v); setState(() {}); },
),
```

- [ ] **Step 3: Remove scan-related entries** if any exist in settings (import/scan).
Do not touch notification/backup/security handlers.

- [ ] **Step 4: Checkpoint (user runs)** `flutter analyze` on the file; toggle the theme
and confirm the whole app restyles live (Ethereal ↔ Obsidian).

---

## PHASE 5 — Localization keys

### Task 5.1: Add required l10n keys

**Files:**
- Modify: the ARB sources if present (`lib/l10n/app_en.arb`, `lib/l10n/app_es.arb`) OR
  directly `lib/l10n/app_localizations_en.dart` and `app_localizations_es.dart` if
  the project edits the generated files. (Check which pattern the repo uses;
  `pubspec.yaml` has `generate: true`, so prefer ARB + regenerate.)

**Keys to add:** `navHome`, `navDebts`, `navHistory`, `navStats`, `themeEthereal`
(`"Ethereal"`), `themeObsidian` (`"Obsidian"`), `totalBalance`, `newMovementsBanner`
(param count), and any literal introduced above not already present. ES/EN values:
- navHome: "Inicio"/"Home", navDebts: "Deudas"/"Debts", navHistory:
  "Historial"/"History", navStats: "Estadísticas"/"Statistics",
  totalBalance: "Balance total"/"Total balance".

- [ ] **Step 1:** Add the keys to both locales (mirror an existing key's format;
`newMovementsBanner` uses a placeholder like existing parameterized messages).
- [ ] **Step 2:** If ARB-based, the user regenerates via `flutter gen-l10n` /
`flutter pub get`. **Checkpoint (user runs).** If the repo hand-edits the generated
`app_localizations_*.dart`, add the getters/methods directly and to the abstract
base `app_localizations.dart`.
- [ ] **Step 3:** Replace any temporary literals from Task 3.2 with the new keys.
- [ ] **Step 4: Checkpoint (user runs)** `flutter analyze`.

---

## PHASE 6 — Remove image_scan feature

### Task 6.1: Delete the image_scan module

**Files:**
- Delete: `lib/modules/image_scan/` (all files:
  `screens/image_scan_screen.dart`, `widgets/scanned_movement_card.dart`).

- [ ] **Step 1:** Grep for remaining references and remove them:

Run (user or agent, read-only grep): search `image_scan`, `ImageScanScreen`,
`ScannedMovementCard`, `_pickAndScanImage`, and `'scan'` result handling across `lib/`.
Remove every import and usage found (main_screen already handled in 3.2; check
`movement_form_screen.dart` handled in 4.10; check settings in 4.11).

- [ ] **Step 2:** Remove the module directory.

- [ ] **Step 3: Checkpoint (user runs)** `flutter analyze` on the whole project;
expect no unresolved references to the deleted module.

---

## Self-Review

**Spec coverage:**
- Two selectable themes (default Ethereal), no dynamic color → Tasks 1.1–1.5, 4.11. ✓
- 5-slot navigation (Inicio/Deudas/+/Historial/Estadísticas) → Tasks 3.1–3.2. ✓
- All 13 design screens mapped → Tasks 4.1–4.10 + 4.11 (settings) + credit card sub-screens. ✓
  (inicio 4.1, deudas 4.2, historial 4.3, buscador 4.4, estadísticas 4.5, tarjeta 4.6,
  recurrentes + nuevo recurrente 4.7, notificaciones 4.8, selección de mes 4.9,
  nuevo gasto 4.10, configuración 4.11.)
- `+` = Directo/Puntual only, with Gasto/Ingreso toggle → Task 4.10. ✓
- Recurring creation lives on Recurrentes screen → Task 4.7. ✓
- Remove image scan (module + entry points) → Tasks 3.2, 4.10, 4.11, 6.1. ✓
- No backend changes → enforced by Global Constraints; all tasks reuse existing services. ✓
- Component library → Phase 2. ✓

**Placeholder scan:** Screen tasks intentionally instruct "read the file first, then
swap the visual layer" because exact existing widget trees vary; the *new* structures,
components, data getters, and handler names are concrete. No "TBD"/"handle edge cases"
left. Foundation + components have full code.

**Type consistency:** `AppGlass` fields, `AppThemeVariant.storageValue/fromStorage`,
`ThemeController.variant/setVariant`, `CustomTheme.build`, `AppBottomNav` `items`
record type, `AppSegmentedControl<T>` record segments — all referenced consistently
across tasks.

**Known verification note:** Per user instruction, the agent never runs
`flutter analyze/test/run`; the user executes each checkpoint and reports back before
the next task proceeds.

