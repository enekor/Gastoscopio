# Rediseño Stitch "Smart Spend" — Diseño

Fecha: 2026-09-02
App: `cashly` (Gastoscopio) — Flutter, Material 3
Rama: v4.1

## Objetivo

Aplicar el diseño del pack `stitch_smart_spend_dashboard` (13 pantallas) a las
pantallas existentes de la app. El backend ya existe: no se crean funciones
nuevas de negocio. Se re-estilan pantallas, se reestructura la navegación y se
añade selección de tema.

## Decisiones tomadas (con el usuario)

1. **Dos temas seleccionables** en Ajustes: **Ethereal Ledger** (por defecto) y
   **Obsidian**. Sin dynamic color (temas fijos), modo oscuro forzado.
2. **Navegación de 5 posiciones**: Inicio · Deudas · **+** · Historial · Estadísticas.
3. **Alcance**: las 13 pantallas en un solo bloque de trabajo.
4. **Botón `+` central** → solo creación Directo/Puntual (`nuevo_gasto`). La
   creación de recurrentes vive en la pantalla Recurrentes, con su propio `+`.
5. **Ingresos**: toggle Gasto | Ingreso en la parte superior de la pantalla Nuevo.
6. **Escaneo desde imagen**: se elimina (feature descartada por falta de uso).
   Se quitan sus puntos de entrada y el módulo `image_scan`.

## Arquitectura de tema

### AppThemeVariant
`enum AppThemeVariant { etherealLedger, obsidian }` (nuevo, en `lib/theme/`).

### ThemeController
`ChangeNotifier` singleton (patrón idéntico a `LocaleService`), en
`lib/theme/theme_controller.dart`:
- `AppThemeVariant get current`
- `Future<void> initialize()` — carga desde `SharedPreferences`
- `Future<void> setVariant(AppThemeVariant)` — persiste + `notifyListeners()`

Se añade clave a `SharedPreferencesKeys`: `themeVariant('theme_variant')`.

Se inicializa en `main()` (como `LocaleService`) y `MyApp` escucha sus cambios
para reconstruir. Se elimina `DynamicColorBuilder`; `MaterialApp` usa
`theme: CustomTheme.build(controller.current)` con `themeMode: ThemeMode.dark`.

### CustomTheme (reescritura)
`CustomTheme.build(AppThemeVariant)` devuelve `ThemeData` por variante, con
`ColorScheme` fija derivada de los `DESIGN.md`:

**Ethereal Ledger**
- background/surface base: `#0F172A` / `#131315`
- primary (esmeralda): `#10B981` (verde de acción/éxito/ingreso)
- expense/deuda (coral): `#FB7185`
- surface-container: escala translúcida (glass)
- radios: cards 24px, botones/inputs 28–32px (pill)
- tipografía: Inter (usar la fuente ya disponible o fallback del sistema)

**Obsidian**
- background: `#09090b`; surfaces zinc `#0c0c0f`→`#27272a`
- primary (violeta): `#a78bfa`; tertiary esmeralda `#34d399`; error `#ef4444`
- separación por borde `1px #27272a`, sin blur; radios 8px

### ThemeExtension: AppGlass
`ThemeExtension<AppGlass>` (en `lib/theme/app_glass.dart`) con tokens que
`ColorScheme` no cubre y que difieren por variante:
- `glassFill` (Color con opacidad), `blurSigma` (double; 0 en Obsidian),
  `innerGlowBorder` (Gradient/Border), `cardRadius`, `pillRadius`,
  `backgroundGradient`, `incomeColor`, `expenseColor`, `mutedText`.
Accesible con `Theme.of(context).extension<AppGlass>()!`.
Los componentes leen de aquí para comportarse distinto en cada tema con el
mismo widget.

## Librería de componentes (nuevos)

Ubicación: `lib/theme/widgets/`. Todos consumen `AppGlass` + `ColorScheme`.

- `AppBackground` — fondo con gradiente navy / near-black (por variante).
- `GlassCard` — tarjeta translúcida con blur + borde inner-glow. En Obsidian
  degrada a superficie plana + borde fino.
- `PrimaryPillButton` — botón pastilla (esmeralda / violeta), estado pressed
  con inner-shadow (Ethereal).
- `GlassButton` — botón translúcido secundario.
- `AmountText` — importe grande; color por signo (income/expense).
- `StatTile` — mini-card Ingresos/Gastos con icono y valor.
- `SectionHeader` — título de sección + acción a la derecha ("Ver todos").
- `AppSegmentedControl<T>` — segmentado tipo pill (2–3 opciones) como el diseño.
- `AppListRow` — fila con icono circular, título, subtítulo/chip y trailing.
- `MonthChip` — chip "Septiembre ⌄" que abre el selector de mes.
- `AppBottomNav` — barra inferior de 5 posiciones con FAB central acoplado
  (reemplaza/extiende `CustomBottomNavigationBar`).

Nota: se reutilizan y re-estilan `finance_widgets.dart`,
`main_screen_widgets.dart`, `movement_tile.dart`, `category_progress_chart.dart`
en lugar de duplicarlos.

## Navegación (`main_screen.dart`)

- `TabController(length: 4)` para las 4 pestañas; el `+` es el FAB central
  (`FloatingActionButtonLocation.centerDocked`).
- Destinos:
  - 0 Inicio → `GastoscopioHomeScreen`
  - 1 Deudas → `ActiveDebtsScreen`
  - 2 Historial → `MovementsScreen`
  - 3 Estadísticas → `SummaryScreen`
- FAB `+` (esmeralda) → abre pantalla **Nuevo** (`MovementFormScreen`
  re-estilada, ver abajo). Se elimina la rama `scan`.
- Top bar por pantalla: `MonthChip` (izq.) + título centrado + ajustes (der.),
  según diseño. El selector de mes sigue usando `_showMonthSelector`.

## Mapeo de pantallas y cableado

| Diseño | Archivo real | Cambios clave |
|---|---|---|
| inicio | `screens/home.dart` | Balance total (card grande), banner "N nuevos movimientos"→Notificaciones, Ingresos/Gastos (StatTile), "Gastos Recientes"+"Ver todos"→Historial, cards Vencimiento→Deudas y Billetera/Premium→Tarjeta |
| gestión de deudas | `screens/active_debts_screen.dart` | Card "Total pendiente" + progreso; secciones Mes Anterior (URGENTE) / Recurrentes / Puntuales; botón Pagar/Resolver→`completeDebtOccurrence` |
| historial con filtros | `screens/movements_screen.dart` | Tabs pill Todos/Ingresos/Gastos, buscador, orden; filas con icono+chip categoría; swipe editar/borrar (flujos actuales) |
| buscador avanzado | `screens/view_movements_filtered_screen.dart` | Buscador + rango por meses (chips) + lista con total |
| estadísticas y resumen | `screens/summary_screen.dart` (+ `summary_tab_content`, `category_progress_chart`) | Resumen Financiero (Ahorro neto), Evolución (line chart glow), Distribución (donut + leyenda); tab IA se mantiene |
| tarjeta de crédito | `credit_card/screens/credit_card_screen.dart` (+ form, history) | "Premium card" visual, Saldo utilizado + progreso, Próximo pago / Cierre facturación, nota informativa; FAB nuevo gasto |
| movimientos recurrentes | `screens/fixed_movements_screen.dart` | "Total mensual estimado", Próximos cobros (cards Detalles/Editar/Completar), FAB `+`→**Nuevo recurrente** |
| mov. de notificaciones | `notifications/screens/pending_notifications_screen.dart` (+ `pending_movement_card`) | Cards con icono app, toggle Gasto/Ingreso, campos editables, chip TARJETA, botón "Procesar seleccionados" |
| selección de mes | `widgets/month_grid_selector.dart` | Selector de AÑO con flechas + grid 3×4 de meses con total; mes activo resaltado esmeralda |
| nuevo gasto | `screens/movement_form_screen.dart` | Ver "Flujo Nuevo" abajo |
| nuevo mov. recurrente | nuevo `screens/recurring_form_screen.dart` (o re-estilo de los diálogos de recurrentes) | Monto grande, Nombre, Categoría, segmentado Gasto/Deuda Recurrente, Programación (Frecuencia, Día de cobro), "Guardar Recurrente" |
| configuración | `settings.dart/settings.dart` | Re-estilo por secciones (cards glass) + **nuevo bloque "Aspecto Visual → Tema"** (Ethereal/Obsidian). Se quita el bloque/entradas de escaneo |

## Flujo "Nuevo" (`movement_form_screen.dart`)

Pantalla (no bottom sheet grande) según `nuevo_gasto`:
- Toggle superior **Gasto | Ingreso** (define `isExpense`; acento coral/esmeralda).
- Campo Nombre + chip "Categoría (IA Tag)" (categoría autogenerada por
  `GroqService` como hoy; el chip permite fijarla/verla).
- Valor grande con símbolo de moneda.
- Fecha (date picker existente).
- Segmentado **Gasto Directo | Deuda Puntual** = mapea al actual
  `_createAsOneTimeDebt` (Directo→movimiento normal `insertMovementValue`;
  Deuda Puntual→`createOneTimeDebt`).
- Botón "Guardar" (pill esmeralda / violeta).
- **Se elimina** el `OutlinedButton` de "Escanear desde imagen".

En modo edición (`movement != null`) se conserva el comportamiento actual
(update + migrar mes), re-estilado.

## Flujo "Nuevo recurrente" (desde Recurrentes)

Según `nuevo_movimiento_selector_recurrente`:
- Monto grande + Nombre + Categoría.
- Segmentado **Gasto Recurrente | Deuda Recurrente**:
  - Gasto Recurrente → `FixedMovement` (`insertFixedMovement`).
  - Deuda Recurrente → `createMonthlyDebtDefinition`.
- Programación: Frecuencia (Mensual — única soportada hoy) + Día de cobro
  (`startDay`/`day`).
- "Guardar Recurrente".

Reemplaza/re-estila los diálogos actuales de creación en
`fixed_movements_screen.dart` manteniendo sus llamadas de servicio.

## Eliminación de escaneo de imagen

- Quitar rama `scan` y `_pickAndScanImage` de `main_screen.dart`.
- Quitar botón de escaneo de `movement_form_screen.dart`.
- Eliminar módulo `lib/modules/image_scan/` y sus imports.
- (No afecta a `pending_notifications` ni a otras features.)

## Consideraciones

- i18n: usar las claves de `AppLocalizations` existentes; añadir solo las nuevas
  imprescindibles (p. ej. nombres de tema) en `app_localizations_es/en`.
- La moneda se lee de `SharedPreferencesKeys.currency` (símbolo mostrado).
- No se modifican esquemas de BD ni firmas de servicios.
- Fondo por imagen de usuario (`backgroundImage`) se mantiene compatible con
  el nuevo `AppBackground`.

## Fuera de alcance

- Nuevas capacidades de negocio (frecuencias distintas de mensual, multi-cuenta,
  etc.). El diseño muestra algunos textos ilustrativos (p. ej. "Semanal") que se
  mapean a lo que el backend soporta hoy.
