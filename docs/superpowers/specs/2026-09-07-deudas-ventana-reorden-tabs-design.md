# Diseño: Deudas en ventana propia + reordenar pestañas

Fecha: 2026-09-07

## Objetivo

1. Sacar las **Deudas** de la pestaña "Gestión" y abrirlas en una ventana propia
   desde el botón "movimientos futuros" de la home.
2. Dejar la pestaña "Gestión" únicamente con la gestión de movimientos y deudas
   recurrentes (`FixedMovementsScreen`).
3. Reordenar el bottom nav para que **Historial** sea la segunda pestaña y
   **Gestión** la tercera.

## Situación actual

Bottom nav en `lib/modules/main_screen.dart` (4 pestañas, `TabController length: 4`):

| Índice | Pantalla | Icono | Título |
|---|---|---|---|
| 0 | `GastoscopioHomeScreen` | `home` | Inicio |
| 1 | `ManagementScreen` | `credit_score` | Gestión |
| 2 | `MovementsScreen` | `history` | Historial |
| 3 | `SummaryScreen` | `bar_chart` | Estadísticas |

- `ManagementScreen` (`lib/modules/gastoscopio/screens/management_screen.dart`)
  tiene un `AppSegmentedControl` con dos vistas en un `IndexedStack`:
  `ActiveDebtsScreen(embedded: true)` (Deudas) y
  `FixedMovementsScreen(embedded: true)` (Recurrentes).
- La tarjeta "movimientos futuros" en la home
  (`_buildVencimientoCard`, `lib/modules/gastoscopio/screens/home.dart`) hace
  `widget.onNavigateTab?.call(1)`, llevando a Gestión sobre la sub-pestaña Deudas.
- `ActiveDebtsScreen` ya soporta modo standalone: con `embedded: false` (valor por
  defecto) se envuelve en su propio `Scaffold` + `AppBar` (título "activeDebts") +
  `AppBackground`.
- La tarjeta de tarjeta de crédito (`_buildBilleteraCard`) abre `CreditCardScreen`
  con `Navigator.push(MaterialPageRoute(...))` y recarga datos al volver
  (`_loadCards()`). Este es el patrón a replicar para Deudas.

## Cambios

### 1. `ManagementScreen` — solo Recurrentes

- Eliminar el `AppSegmentedControl` y el `IndexedStack`.
- Renderizar directamente `FixedMovementsScreen(embedded: true)`.
- Eliminar el estado `_tab` y el import de `ActiveDebtsScreen` y del control
  segmentado si dejan de usarse.

### 2. Home — botón "movimientos futuros" abre Deudas en ventana propia

En `_buildVencimientoCard` (`home.dart`):

- Sustituir `onTap: () => widget.onNavigateTab?.call(1)` por un `Navigator.push`
  a `ActiveDebtsScreen()` (sin `embedded`, usa su Scaffold/AppBar propios),
  siguiendo el mismo patrón que `_buildBilleteraCard`, y recargando datos al
  volver (`_loadCards()`).

### 3. Reordenar bottom nav (intercambiar Gestión ↔ Historial)

Nuevo orden en `main_screen.dart`:

| Índice | Pantalla | Icono | Título |
|---|---|---|---|
| 0 | `GastoscopioHomeScreen` | `home` | Inicio |
| 1 | `MovementsScreen` | `history` | Historial |
| 2 | `ManagementScreen` | `repeat_rounded` | Gestión |
| 3 | `SummaryScreen` | `bar_chart` | Estadísticas |

Ajustes concretos:

- `_screens`: intercambiar posiciones de `ManagementScreen` y `MovementsScreen`.
- `_titleForIndex`: pasar de `[home, navManagement, navHistory, navStatistics]`
  a `[home, navHistory, navManagement, navStatistics]`.
- `items` del `AppBottomNav`: reordenar para que el segundo sea Historial
  (`history` / `navHistory`) y el tercero Gestión, cambiando además el icono de
  Gestión a `repeat_rounded` (outline y filled iguales) por decisión de diseño.
- El `if (_selectedIndex != 3)` del `_buildTopBar` no cambia (Estadísticas sigue
  en índice 3). El fondo de la home (`_selectedIndex == 0`) tampoco cambia.

### 4. Referencias a índices en `home.dart`

- `SectionHeader` de "recentExpenses" (`onAction: () => widget.onNavigateTab?.call(2)`)
  apunta a Historial; con el nuevo orden Historial es el índice **1**, así que pasa
  a `call(1)`.
- Actualizar el comentario de `onNavigateTab` (doc del parámetro) para reflejar el
  nuevo orden (0 Inicio, 1 Historial, 2 Gestión, 3 Estadísticas).

## Fuera de alcance

- No se toca el contenido interno de `ActiveDebtsScreen`, `FixedMovementsScreen`,
  `MovementsScreen` ni `SummaryScreen`.
- No se añaden ni cambian cadenas de localización (se reutilizan las existentes:
  `navManagement`, `navHistory`, `activeDebts`, etc.).

## Verificación

El usuario ejecuta la verificación de Flutter (`flutter analyze` / `run`) por su
cuenta. Comprobaciones esperadas:

- La segunda pestaña del nav y el scroll lateral derecha→izquierda desde la home
  muestran Historial; la tercera muestra Gestión (solo recurrentes).
- El botón "movimientos futuros" abre Deudas como ventana nueva con flecha atrás.
- "Ver todos" de gastos recientes en la home lleva a Historial.
