import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/modules/gastoscopio/widgets/movement_tile.dart';
import 'package:cashly/common/tag_list.dart' show getTagList;
import 'package:cashly/modules/gastoscopio/widgets/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';

class MovementsScreen extends StatefulWidget {
  final int year;
  final int month;

  const MovementsScreen({Key? key, required this.year, required this.month})
    : super(key: key);

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen>
    with TickerProviderStateMixin {
  bool _showExpenses = true;
  DateTime? _selectedDate;
  String? _selectedCategory;
  String _searchQuery = '';
  final Map<String, bool> _expandedItems = {};
  late String _moneda;
  late FinanceService _financeService;
  final TextEditingController _searchController = TextEditingController();
  bool _isOpaqueBottomNav = false;

  // Variables para el orden
  String? _currentSortType;
  bool _isAscending = true;

  // Cache para los movimientos y estado de carga
  List<MovementValue> _cachedMovements = [];
  bool _isLoading = true;

  // Animaciones para transiciones suaves
  late AnimationController _listAnimationController;
  late AnimationController _toggleAnimationController;
  late Animation<double> _listFadeAnimation;
  late Animation<double> _toggleAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animación
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toggleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _listFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toggleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );

    // Escuchar cambios del servicio
    _financeService.addListener(_onFinanceServiceChanged);

    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );

    // Cargar configuración de opacidad de navegación inferior
    SharedPreferencesService()
        .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
        .then(
          (isOpaque) => setState(() {
            _isOpaqueBottomNav = isOpaque ?? false;
          }),
        );

    _searchController.text = _searchQuery;
    // Cargar datos iniciales
    _loadMovements();

    // Iniciar las animaciones
    _listAnimationController.forward();
    _toggleAnimationController.forward();
  }

  void _onFinanceServiceChanged() {
    // Cuando el servicio notifica cambios, recargar datos con animación
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    try {
      var movements = await _financeService.getCurrentMonthMovements();

      // Animar la transición de la lista
      if (_cachedMovements.isNotEmpty) {
        await _listAnimationController.reverse();
      }

      movements.sort((a, b) => a.day.compareTo(b.day));
      movements = movements.reversed.toList();

      setState(() {
        _cachedMovements = movements;
        _isLoading = false;
        // Aplicar ordenamiento si existe
        _applySorting();
      });

      await _listAnimationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAllTags() async {
    bool delete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).confrmTagDelete),
            content: Text(AppLocalizations.of(context).confirmDeleteAllTags),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
        ) ??
        false;
    List<MovementValue> movements = await _financeService
        .getCurrentMonthMovements();
    movements = movements
        .where((m) => m.category != null && m.category!.isNotEmpty)
        .toList();

    if (movements.isEmpty) return;

    for (final movement in movements) {
      final updatedMovement = MovementValue(
        movement.id,
        movement.monthId,
        movement.description,
        movement.amount,
        movement.isExpense,
        movement.day,
        null, // Eliminar la categoría
      );
      await _financeService.updateMovement(updatedMovement);
      // Call haveToUpload() after updating movement tag
      await SharedPreferencesService().haveToUpload();
    }

    // Recargar movimientos después de eliminar las etiquetas
    await _loadMovements();
  }

  Future<void> _autoGenerateTags() async {
    List<MovementValue> movements = await _financeService
        .getCurrentMonthMovements();
    movements = movements
        .where((m) => m.category == null || m.category!.isEmpty)
        .toList();

    if (movements.isEmpty) return;
    List<String> tags = await GeminiService().generateTags(
      movements
          .map((m) => '${m.description} (${m.isExpense ? "gasto" : "ingreso"})')
          .join(','),
      context,
    );
    if (tags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.noTagsGenerated,
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    for (int i = 0; i < movements.length; i++) {
      final movement = movements[i];
      final tag = tags[i % tags.length]; // Asignar etiquetas cíclicamente
      final updatedMovement = MovementValue(
        movement.id,
        movement.monthId,
        movement.description,
        movement.amount,
        movement.isExpense,
        movement.day,
        tag, // Actualizar la categoría con la etiqueta generada
      );
      await _financeService.updateMovement(updatedMovement);
      // Call haveToUpload() after updating movement tag
      await SharedPreferencesService().haveToUpload();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _financeService.removeListener(_onFinanceServiceChanged);
    _listAnimationController.dispose();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MovementsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _loadMovements();
      // También recargar configuración de opacidad por si cambió
      SharedPreferencesService()
          .getBoolValue(SharedPreferencesKeys.isOpaqueBottomNav)
          .then(
            (isOpaque) => setState(() {
              _isOpaqueBottomNav = isOpaque ?? false;
            }),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: Loading(context)));
    }

    final filteredMovements = _filterMovements(_cachedMovements);
    final totalAmount = filteredMovements.fold<double>(
      0,
      (sum, movement) =>
          sum + (movement.isExpense ? -movement.amount : movement.amount),
    );

    // Color temático según si vemos gastos o ingresos
    final themeColor = _showExpenses
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            // 1. Selector Superior (Más limpio)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildTypeSelector(),
            ),

            // 2. Tarjeta "Hero" con Gradiente (Resumen del filtro actual)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildModernTotalCard(
                totalAmount,
                filteredMovements.length,
                themeColor,
              ),
            ),

            // 3. Barra de Herramientas (Filtros, Orden, IA)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildModernToolBar(context),
            ),

            // 4. Panel de Filtros Expandible
            if (_expandedItems['filters'] ?? false) _buildFilters(),

            // 5. Movimientos Futuros (Si aplica)
            if (_financeService.currentMonth!.month == DateTime.now().month &&
                filteredMovements.any((mov) => mov.day > DateTime.now().day))
              _buildFutureMovementsCard(
                filteredMovements
                    .where((mov) => mov.day > DateTime.now().day)
                    .toList(),
              ),

            // 6. Lista de Movimientos (Sin Card envolvente, diseño limpio)
            Expanded(
              child: _cachedMovements.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showExpenses
                                ? Icons.money_off
                                : Icons.attach_money,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).disabledColor.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showExpenses
                                ? AppLocalizations.of(context).noExpenses
                                : AppLocalizations.of(context).noIncomes,
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _listFadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _listFadeAnimation.value,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount:
                                _financeService.currentMonth!.month <
                                    DateTime.now().month
                                ? filteredMovements.length
                                : filteredMovements
                                      .where(
                                        (mov) => mov.day <= DateTime.now().day,
                                      )
                                      .length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(
                                  height: 12,
                                ), // Espacio entre items
                            itemBuilder: (context, index) {
                              final movement =
                                  _financeService.currentMonth!.month <
                                      DateTime.now().month
                                  ? filteredMovements.toList()[index]
                                  : filteredMovements
                                        .where(
                                          (mov) =>
                                              mov.day <= DateTime.now().day,
                                        )
                                        .toList()[index];

                              final isExpanded =
                                  _expandedItems[movement.id.toString()] ??
                                  false;

                              // Aquí usamos tu MovementTile existente, pero podrías envolverlo
                              // en un Container con decoración si MovementTile no tiene sombra propia.
                              return MovementTile(
                                movement: movement,
                                isExpanded: isExpanded,
                                currency: _moneda,
                                onTap: () =>
                                    _toggleMovementExpansion(movement.id!),
                                expandedContent: _buildExpandedContent(
                                  context,
                                  movement,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: FloatingActionButton(
          onPressed: _createNewMovement,
          child: const Icon(Icons.add_card, size: 28),
          tooltip: 'Añadir movimiento',
        ),
      ),
    );
  }

  // --- WIDGETS NUEVOS Y REDISEÑADOS ---

  Widget _buildTypeSelector() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          side: MaterialStateProperty.all(
            BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              // Color diferente para Gastos (Rojo suave) vs Ingresos (Primario)
              return _showExpenses
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer;
            }
            return Colors.transparent;
          }),
        ),
        segments: [
          ButtonSegment<bool>(
            value: false,
            label: Text(
              AppLocalizations.of(context).incomes,
              style: TextStyle(
                fontWeight: !_showExpenses
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: !_showExpenses
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
            icon: Icon(Icons.arrow_upward, size: 16),
          ),
          ButtonSegment<bool>(
            value: true,
            label: Text(
              AppLocalizations.of(context).expenses,
              style: TextStyle(
                fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                color: _showExpenses
                    ? Theme.of(context).colorScheme.onErrorContainer
                    : null,
              ),
            ),
            icon: Icon(Icons.arrow_downward, size: 16),
          ),
        ],
        selected: {_showExpenses},
        onSelectionChanged: (newSelection) {
          setState(() {
            _showExpenses = newSelection.first;
          });
        },
      ),
    );
  }

  // Tarjeta moderna que reemplaza al indicador total antiguo
  Widget _buildModernTotalCard(double total, int count, Color color) {
    return Container(
      width: double.infinity,
      height: 100,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showExpenses
                    ? AppLocalizations.of(context).expenses
                    : AppLocalizations.of(
                        context,
                      ).incomes, // Asegúrate de tener estas keys o usa strings fijos
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count movs.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Center(
            child: Text(
              '${total < 0 ? '-' : ''}${total.abs().toStringAsFixed(2)}$_moneda',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Barra de herramientas limpia (Filtro, Ordenar, IA)
  Widget _buildModernToolBar(BuildContext context) {
    // Definimos el estilo base de los botones para consistencia
    final buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        Theme.of(context).colorScheme.surface,
      ),
      elevation: MaterialStateProperty.all(2),
      shadowColor: MaterialStateProperty.all(Colors.black.withOpacity(0.1)),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
    );

    return Row(
      children: [
        // Botón Filtros
        Expanded(
          child: ElevatedButton.icon(
            style: buttonStyle.copyWith(
              backgroundColor: MaterialStateProperty.resolveWith(
                (states) => (_expandedItems['filters'] ?? false)
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surface,
              ),
            ),
            onPressed: () {
              setState(() {
                _expandedItems['filters'] =
                    !(_expandedItems['filters'] ?? false);
              });
            },
            icon: Icon(
              Icons.filter_list,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            label: Text(
              "Filtrar",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Botón Ordenar (Solo icono para ahorrar espacio o Texto si cabe)
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(12),
          ),
          onPressed: () => _showSortMenu(context),
          icon: const Icon(Icons.sort),
          tooltip: "Ordenar",
        ),

        const SizedBox(width: 10),

        // Botón IA (Magic Tags)
        GestureDetector(
          onLongPress: () {
            _deleteAllTags();
          },
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
            ),
            onPressed: () async {
              await _autoGenerateTags();
              await _loadMovements();
            },
            icon: Icon(Icons.auto_awesome, color: Colors.amber.shade900),
            tooltip: "Auto-etiquetar",
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: ToggleButtons(
        borderRadius: BorderRadius.circular(25),
        borderColor: Theme.of(context).colorScheme.primary,
        fillColor: Theme.of(context).colorScheme.primary.withAlpha(45),
        selectedColor: Theme.of(context).colorScheme.onPrimary,
        isSelected: [!_showExpenses, _showExpenses],
        onPressed: (index) async {
          if ((index == 1) != _showExpenses) {
            // Animar la transición
            await _toggleAnimationController.reverse();
            setState(() {
              _showExpenses = index == 1;
            });
            await _toggleAnimationController.forward();
          }
        },

        children: [
          TextButton.icon(
            onPressed: () async {
              if (_showExpenses) {
                await _toggleAnimationController.reverse();
                setState(() {
                  _showExpenses = false;
                });
                await _toggleAnimationController.forward();
              }
            },
            icon: const Icon(Icons.money),
            label: Text(AppLocalizations.of(context)!.incomes),
          ),
          TextButton.icon(
            onPressed: () async {
              if (!_showExpenses) {
                await _toggleAnimationController.reverse();
                setState(() {
                  _showExpenses = true;
                });
                await _toggleAnimationController.forward();
              }
            },
            icon: const Icon(Icons.money_off),
            label: Text(AppLocalizations.of(context)!.expenses),
          ),
        ],
      ),
      actions: [_buildGenerateTagsButton(), _buildOrderByButton()],
      centerTitle: false,
      actionsPadding: const EdgeInsets.only(right: 16),
    );
  }

  Widget _buildContent(List<MovementValue> movements, String moneda) {
    bool showFutureMovements =
        _financeService.currentMonth!.month == DateTime.now().month;
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTotalIndicator(movements, moneda),
          _buildFilters(),
          if (showFutureMovements)
            _buildFutureMovementsList(
              movements.where((mov) => mov.day > DateTime.now().day).toList(),
              moneda,
            ),
          Expanded(
            child: _buildList(
              showFutureMovements
                  ? movements
                        .where((mov) => mov.day <= DateTime.now().day)
                        .toList()
                  : movements,
              moneda,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFutureMovementsList(
    List<MovementValue> movements,
    String moneda,
  ) {
    if (movements.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isFutureExpanded = _expandedItems['future_movements'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AnimatedCard(
        isExpanded: isFutureExpanded,
        leadingWidget: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(
                  Icons.upcoming,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).futureMovements,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    movements.length.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              isFutureExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          onTap: () {
            setState(() {
              _expandedItems['future_movements'] = !isFutureExpanded;
            });
          },
        ),
        hiddenWidget: Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: movements.map((mov) {
              final isExpanded = _expandedItems['future_${mov.id}'] ?? false;

              return AnimatedCard(
                isExpanded: isExpanded,
                onTap: () {
                  setState(() {
                    _expandedItems['future_${mov.id}'] = !isExpanded;
                  });
                },
                leadingWidget: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 4.0,
                  ),
                  title: Text(
                    mov.description,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: mov.category != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.label_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                mov.category!,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${mov.amount.toStringAsFixed(2)} $moneda',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: mov.isExpense
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        '${mov.day}/${widget.month}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                hiddenWidget: _buildExpandedContent(context, mov),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<MovementValue> movements, String moneda) {
    if (movements.isEmpty) {
      return FadeTransition(
        opacity: _toggleAnimation,
        child: Center(
          child: Text(
            _showExpenses
                ? AppLocalizations.of(context).noExpenses
                : AppLocalizations.of(context).noIncomes,
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMovements,
      child: FadeTransition(
        opacity: _toggleAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            final isExpanded = _expandedItems[movement.id.toString()] ?? false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: MovementTile(
                movement: movement,
                isExpanded: isExpanded,
                currency: moneda,
                onTap: () {
                  setState(() {
                    final key = movement.id.toString();
                    _expandedItems[key] = !(_expandedItems[key] ?? false);
                  });
                },
                expandedContent: _buildExpandedContent(context, movement),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderByButton() {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, color: Theme.of(context).colorScheme.primary),
            if (_currentSortType != null) ...[
              const SizedBox(width: 4),
              Icon(
                _isAscending
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ],
          ],
        ),
        tooltip: AppLocalizations.of(context)!.sortBy,
        onSelected: (String value) {
          setState(() {
            _expandedItems.clear(); // Reset expanded items

            // Si se selecciona el mismo tipo de orden, cambiar dirección
            if (_currentSortType == value) {
              _isAscending = !_isAscending;
            } else {
              _currentSortType = value;
              _isAscending = true; // Por defecto ascendente para nuevo tipo
            }

            _applySorting();
          });
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'fecha',
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.byDate),
                const Spacer(),
                if (_currentSortType == 'fecha')
                  Icon(
                    _isAscending
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'alfabetico',
            child: Row(
              children: [
                Icon(
                  Icons.sort_by_alpha,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.alphabetical),
                const Spacer(),
                if (_currentSortType == 'alfabetico')
                  Icon(
                    _isAscending
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'valor',
            child: Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(AppLocalizations.of(context)!.byValue),
                const Spacer(),
                if (_currentSortType == 'valor')
                  Icon(
                    _isAscending
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
              ],
            ),
          ),
          if (_currentSortType != null) ...[
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'reset',
              child: Row(
                children: [
                  Icon(Icons.clear, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.clearSort,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  _currentSortType = null;
                  _isAscending = true;
                  _loadMovements(); // Recargar en orden original
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateTagsButton() {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      child: IconButton(
        icon: Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
        ),
        tooltip: AppLocalizations.of(context)!.generateTagsAutomatically,
        onPressed: () async {
          await _autoGenerateTags();
          await _loadMovements();
        },
      ),
    );
  }

  Widget _buildTotalIndicator(List<MovementValue> movements, String moneda) {
    if (movements.isEmpty) return const SizedBox.shrink();

    final totalAmount = movements.fold<double>(
      0,
      (sum, movement) =>
          sum + (movement.isExpense ? -movement.amount : movement.amount),
    );
    final totalCount = movements.length;
    final hasFilters =
        _selectedDate != null ||
        _selectedCategory != null ||
        _searchQuery.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        children: [
          Icon(
            hasFilters ? Icons.filter_list : Icons.analytics,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          // Text(
          //   hasFilters
          //       ? AppLocalizations.of(context)!.filteredMovements
          //       : AppLocalizations.of(context)!.totalMovements,
          //   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          //     color: Theme.of(context).colorScheme.onPrimaryContainer,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(width: 6),
          Text(
            '$totalCount ${_showExpenses ? AppLocalizations.of(context)!.expenses.toLowerCase() : AppLocalizations.of(context)!.incomes.toLowerCase()}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${totalAmount >= 0 ? '+' : ''}${totalAmount.toStringAsFixed(2)}$moneda',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: totalAmount >= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final bool isFiltersExpanded = _expandedItems['filters'] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        top: isFiltersExpanded ? 16 : 0,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isFiltersExpanded ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).filters,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_selectedDate != null ||
                      _selectedCategory != null ||
                      _searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(_selectedDate != null ? 1 : 0) + (_selectedCategory != null ? 1 : 0) + (_searchQuery.isNotEmpty ? 1 : 0)}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              trailing: RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(
                  CurvedAnimation(
                    parent: _toggleAnimationController,
                    curve: Curves.easeInOut,
                  ),
                ),
                child: const Icon(Icons.expand_more),
              ),
              onTap: () {
                setState(() {
                  _expandedItems['filters'] = !isFiltersExpanded;
                });
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isFiltersExpanded ? null : 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFiltersExpanded ? 1.0 : 0.0,
                child: isFiltersExpanded
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: () => _selectDate(context),
                                    style: FilledButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.3),
                                      elevation: 0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.date_range,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            _selectedDate != null
                                                ? _selectedDate!.day.toString()
                                                : AppLocalizations.of(
                                                    context,
                                                  ).all,
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (_selectedDate != null) ...[
                                          const SizedBox(width: 4),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedDate = null;
                                              });
                                            },
                                            child: Icon(
                                              Icons.clear,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FutureBuilder<List<MovementValue>>(
                                    future: _financeService
                                        .getCurrentMonthMovements(),
                                    builder: (context, snapshot) {
                                      final categories =
                                          _getAvailableCategories(
                                            snapshot.data ?? [],
                                          );
                                      return FilledButton.tonal(
                                        onPressed: () => _selectCategory(
                                          context,
                                          categories,
                                        ),
                                        style: FilledButton.styleFrom(
                                          foregroundColor: Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.3),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.category,
                                              size: 20,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _selectedCategory ??
                                                    AppLocalizations.of(
                                                      context,
                                                    ).all,
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            if (_selectedCategory != null) ...[
                                              const SizedBox(width: 4),
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedCategory = null;
                                                  });
                                                },
                                                child: Icon(
                                                  Icons.clear,
                                                  size: 16,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).search,
                                prefixIcon: const Icon(Icons.abc),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, MovementValue movement) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ElevatedButton.icon(
                  onPressed: () => _showDatePicker(context, movement),
                  label: Text(
                    '${movement.day}/${widget.month}/${widget.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  icon: const Icon(Icons.calendar_month),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(movement),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.category),
                tooltip: 'Cambiar categoría',
                onPressed: () => _showCategoryChangeDialog(context, movement),
              ),
            ),
            Expanded(
              flex: 2,
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(movement),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortButton() {
    return IconButton(
      icon: Stack(
        children: [
          const Icon(Icons.sort),
          if (_currentSortType != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      onPressed: () => _showSortMenu(context),
    );
  }

  void _toggleMovementExpansion(int movementId) {
    final key = movementId.toString();
    _expandedItems[key] = !(_expandedItems[key] ?? false);
    setState(() {});
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(AppLocalizations.of(context).byDate),
                trailing: _currentSortType == 'fecha'
                    ? Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'fecha') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'fecha';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: Text(AppLocalizations.of(context).alphabetical),
                trailing: _currentSortType == 'alfabetico'
                    ? Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'alfabetico') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'alfabetico';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.euro),
                title: Text(AppLocalizations.of(context).byValue),
                trailing: _currentSortType == 'valor'
                    ? Icon(
                        _isAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_currentSortType == 'valor') {
                      _isAscending = !_isAscending;
                    } else {
                      _currentSortType = 'valor';
                      _isAscending = true;
                    }
                    _applySorting();
                  });
                  Navigator.pop(context);
                },
              ),
              if (_currentSortType != null)
                ListTile(
                  leading: const Icon(Icons.clear),
                  title: Text(AppLocalizations.of(context).clearSort),
                  onTap: () {
                    setState(() {
                      _currentSortType = null;
                      _isAscending = true;
                      _loadMovements();
                    });
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _applySorting() {
    if (_currentSortType == null) {
      _cachedMovements.sort((a, b) => b.day.compareTo(a.day));
      return;
    }

    _cachedMovements.sort((a, b) {
      int comparison;
      switch (_currentSortType) {
        case 'fecha':
          comparison = a.day.compareTo(b.day);
          break;
        case 'alfabetico':
          comparison = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          break;
        case 'valor':
          comparison = a.amount.compareTo(b.amount);
          break;
        default:
          comparison = b.day.compareTo(a.day);
      }
      return _isAscending ? comparison : -comparison;
    });
    if (_currentSortType == null) return;

    switch (_currentSortType) {
      case 'fecha':
        _cachedMovements.sort((a, b) {
          final comparison = a.day.compareTo(b.day);
          return _isAscending ? comparison : -comparison;
        });
        break;
      case 'alfabetico':
        _cachedMovements.sort((a, b) {
          final comparison = a.description.toLowerCase().compareTo(
            b.description.toLowerCase(),
          );
          return _isAscending ? comparison : -comparison;
        });
        break;
      case 'valor':
        _cachedMovements.sort((a, b) {
          final comparison = a.amount.compareTo(b.amount);
          return _isAscending ? comparison : -comparison;
        });
        break;
    }
  }

  List<MovementValue> _filterMovements(List<MovementValue> movements) {
    return movements.where((movement) {
      // Filtrar por tipo (gastos/ingresos)
      if (movement.isExpense != _showExpenses) return false;

      // Filtrar por fecha
      if (_selectedDate != null && movement.day != _selectedDate!.day) {
        return false;
      }

      // Filtrar por categoría
      if (_selectedCategory != null && movement.category != _selectedCategory) {
        return false;
      }

      // Filtrar por búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description = movement.description.toLowerCase();
        final category = (movement.category ?? '').toLowerCase();
        return description.contains(query) || category.contains(query);
      }

      return true;
    }).toList();
  }

  Set<String> _getAvailableCategories(List<MovementValue> movements) {
    return movements
        .where((m) => m.category != null)
        .map((m) => m.category!)
        .toSet();
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(widget.year, widget.month, 1),
      firstDate: DateTime(widget.year, widget.month, 1),
      lastDate: DateTime(widget.year, widget.month + 1, 0),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  String? _filteredCategory;
  void _selectCategory(BuildContext context, Set<String> existingCategories) {
    // Combinar categorías existentes con TagList localizado y ordenar alfabéticamente
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories = {...existingCategories, ...localizedTags}.toList()
      ..sort((a, b) => a.compareTo(b));

    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return TagList(
              tags: allCategories,
              context: context,
              scrollController: scrollController,
              onTagSelected: (tag) {
                setState(() {
                  _selectedCategory = tag;
                });
                Navigator.pop(context);
              },
              selectedCategory: _selectedCategory,
            );
          },
        );
      },
    );
  }

  Future<void> _createNewMovement() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => MovementFormScreen(),
    );

    // Si se creó un movimiento, recargar los datos
    if (result == true) {
      await _loadMovements();
    }
  }

  Future<void> _showEditDialog(MovementValue movement) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => MovementFormScreen(movement: movement),
    );

    // Si se editó un movimiento, recargar los datos
    if (result == true) {
      await _loadMovements();
    }
  }

  Future<void> _showDeleteDialog(MovementValue movement) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteMovement),
        content: Text(
          AppLocalizations.of(
            context,
          )!.confirmDeleteMovement(movement.description),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    if (shouldDelete == true) {
      await _financeService.deleteMovement(context, movement);
      if (mounted) {
        setState(() {
          _expandedItems.remove(movement.id.toString());
        });
      }
    }
  }

  Widget _buildFutureMovementsCard(List<MovementValue> values) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isExpanded = _expandedItems['future_movements'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              title: Row(
                children: [
                  Icon(
                    Icons.upcoming,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)!.futureMovements,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      values.length.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                setState(() {
                  _expandedItems['future_movements'] = !isExpanded;
                });
              },
            ),
            if (isExpanded)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: values.length,
                itemBuilder: (context, index) {
                  final movement = values[index];
                  return MovementTile(
                    movement: movement,
                    isExpanded: _expandedItems[movement.id.toString()] ?? false,
                    currency: _moneda,
                    onTap: () => _toggleMovementExpansion(movement.id!),
                    expandedContent: _buildExpandedContent(context, movement),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryChangeDialog(
    BuildContext context,
    MovementValue movement,
  ) async {
    // Combine existing categories with localized TagList and sort alphabetically
    final movements = await _financeService.getCurrentMonthMovements();
    final existingCategories = _getAvailableCategories(movements);
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories = {...existingCategories, ...localizedTags}.toList()
      ..sort((a, b) => a.compareTo(b));

    await showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return TagList(
              scrollController: scrollController,
              tags: allCategories,
              context: context,
              onTagSelected: (tag) async {
                movement.category = tag;

                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(child: Loading(context)),
                );
                await _financeService.updateMovement(movement);
                Navigator.pop(context);
              },
              selectedCategory: movement.category,
            );
          },
        );
      },
    );
  }

  Future<void> _showDatePicker(
    BuildContext context,
    MovementValue movement,
  ) async {
    final DateTime initialDate = DateTime(
      widget.year,
      widget.month,
      movement.day,
    );
    final DateTime firstDate = DateTime(widget.year, widget.month, 1);
    final DateTime lastDate = DateTime(
      widget.year,
      widget.month + 1,
      0,
    ); // Último día del mes

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectDate,
      cancelText: AppLocalizations.of(context)!.cancel,
      confirmText: AppLocalizations.of(context)!.accept,
    );

    if (selectedDate != null && selectedDate.day != movement.day) {
      await _updateMovementDate(movement, selectedDate.day);
    }
  }

  Future<void> _updateMovementDate(MovementValue movement, int newDay) async {
    try {
      // Crear una copia del movimiento con la nueva fecha usando copyWith
      final updatedMovement = movement.copyWith(day: newDay);

      // Actualizar en la base de datos
      await SqliteService().database.movementValueDao.updateMovementValue(
        updatedMovement,
      );

      // Mostrar mensaje de confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.dateUpdatedToDay(newDay),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Recargar los movimientos para reflejar el cambio
      await _loadMovements();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorUpdatingDate(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
