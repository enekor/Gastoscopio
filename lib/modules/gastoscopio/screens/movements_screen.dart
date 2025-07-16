import 'package:cashly/data/services/gemini_service.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/common/tag_list.dart' show getTagList;
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
        _cachedMovements = movements; //aqui
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

  Future<void> _autoGenerateTags() async {
    List<MovementValue> movements =
        await _financeService.getCurrentMonthMovements();
    movements =
        movements
            .where((m) => m.category == null || m.category!.isEmpty)
            .toList();

    if (movements.isEmpty) return;
    List<String> tags = await GeminiService().generateTags(
      movements
          .map((m) => '${m.description} (${m.isExpense ? 'gasto' : 'ingreso'})')
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_cachedMovements.isEmpty) {
      return _buildEmptyScreen();
    }

    final filteredMovements = _filterMovements(_cachedMovements);

    return FadeTransition(
      opacity: _listFadeAnimation,
      child: _buildContent(filteredMovements, _moneda),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Center(
        child: Text(AppLocalizations.of(context)!.noMovementsToShow),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Card(
      color:
          _isOpaqueBottomNav
              ? Theme.of(context).colorScheme.primary.withAlpha(200)
              : Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: _isOpaqueBottomNav ? 4 : 8,
      shape: CircleBorder(
        side:
            _isOpaqueBottomNav
                ? BorderSide.none
                : BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
      ),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              _isOpaqueBottomNav
                  ? null
                  : Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
        ),
        child: FloatingActionButton.small(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () async {
            final result = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (BuildContext context) => MovementFormScreen(),
            );

            // Si se agregó un movimiento, recargar los datos
            if (result == true) {
              await _loadMovements();
            }
          },
          child: Icon(
            Icons.add,
            color:
                _isOpaqueBottomNav
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
          ),
          heroTag: 'movements_fab',
        ),
      ),
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
      floatingActionButton: _buildFAB(),
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
            children:
                movements.map((mov) {
                  final isExpanded =
                      _expandedItems['future_${mov.id}'] ?? false;

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
                      subtitle:
                          mov.category != null
                              ? Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.label_outline,
                                      size: 16,
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      mov.category!,
                                      style: TextStyle(
                                        color:
                                            Theme.of(
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
                            style: Theme.of(
                              context,
                            ).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color:
                                  mov.isExpense
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${mov.day}/${widget.month}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
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
                ? AppLocalizations.of(context)!.noExpenses
                : AppLocalizations.of(context)!.noIncomes,
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
          itemCount: movements.length,
          itemBuilder: (context, index) {
            final movement = movements[index];
            final isExpanded = _expandedItems[movement.id.toString()] ?? false;

            return AnimatedSlide(
              offset: Offset(0, isExpanded ? 0 : 0.1),
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: AnimatedCard(
                  isExpanded: isExpanded,
                  onTap: () {
                    setState(() {
                      final key = movement.id.toString();
                      _expandedItems[key] = !(_expandedItems[key] ?? false);
                    });
                  },
                  leadingWidget: ListTile(
                    title: Text(movement.description),
                    subtitle:
                        movement.category != null
                            ? Text(
                              movement.category!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            )
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${movement.amount.toStringAsFixed(2)}${moneda}',
                          style: TextStyle(
                            color:
                                movement.isExpense
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  hiddenWidget: _buildExpandedContent(context, movement),
                ),
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
        itemBuilder:
            (BuildContext context) => [
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
                      Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.error,
                      ),
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
          Text(
            hasFilters
                ? AppLocalizations.of(context)!.filteredMovements
                : AppLocalizations.of(context)!.totalMovements,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
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
              color:
                  totalAmount >= 0
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AnimatedCard(
        isExpanded: isFiltersExpanded,
        leadingWidget: ListTile(
          title: Row(
            children: [
              const Icon(Icons.filter_list),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.filters,
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
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Icon(
            isFiltersExpanded ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).colorScheme.primary,
          ),
          onTap: () {
            setState(() {
              _expandedItems['filters'] = !isFiltersExpanded;
            });
          },
        ),
        hiddenWidget: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => _selectDate(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.date_range,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedDate != null
                                  ? _selectedDate!.day.toString()
                                  : AppLocalizations.of(context)!.all,
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
                                color: Theme.of(context).colorScheme.error,
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
                      future: _financeService.getCurrentMonthMovements(),
                      builder: (context, snapshot) {
                        final categories = _getAvailableCategories(
                          snapshot.data ?? [],
                        );
                        return FilledButton.tonal(
                          onPressed: () => _selectCategory(context, categories),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _selectedCategory ??
                                      AppLocalizations.of(context)!.all,
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
                                    color: Theme.of(context).colorScheme.error,
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.search,
                        prefixIcon: const Icon(Icons.abc),
                        suffixIcon:
                            _searchQuery.isNotEmpty
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Card(
                    color: Colors.transparent,
                    shape: const CircleBorder().copyWith(
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(35),
                        width: 2,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = _searchController.text;
                        });
                      },
                      icon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  void _applySorting() {
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
      // Filter by type (expense/income)
      if (movement.isExpense != _showExpenses) return false;

      // Filter by date if selected
      if (_selectedDate != null && movement.day != _selectedDate!.day) {
        return false;
      }

      // Filter by category if selected
      if (_selectedCategory != null && movement.category != _selectedCategory) {
        return false;
      }

      // Filter by search text
      if (_searchQuery.isNotEmpty &&
          !movement.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
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

  void _selectCategory(BuildContext context, Set<String> existingCategories) {
    // Combinar categorías existentes con TagList localizado y ordenar alfabéticamente
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories =
        {...existingCategories, ...localizedTags}.toList()
          ..sort((a, b) => a.compareTo(b));

    showModalBottomSheet(
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context).selectCategory,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ListTile(
                        title: Text(
                          AppLocalizations.of(context)!.allCategories,
                        ),
                        leading:
                            _selectedCategory == null
                                ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                                : const Icon(Icons.label_outline),
                        onTap: () {
                          setState(() => _selectedCategory = null);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ...allCategories.map(
                        (category) => ListTile(
                          title: Text(category),
                          leading:
                              _selectedCategory == category
                                  ? Icon(
                                    Icons.check,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                  : const Icon(Icons.label_outline),
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(MovementValue movement) async {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController(
      text: movement.description,
    );
    final amountController = TextEditingController(
      text: movement.amount.toStringAsFixed(2),
    );
    DateTime selectedDate = DateTime(widget.year, widget.month, movement.day);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder:
          (BuildContext context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit),
                          const SizedBox(width: 16),
                          Text(
                            AppLocalizations.of(context).editMovement,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).description,
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).pleaseEnterDescription;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).amount,
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: _moneda,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).pleaseEnterAmount;
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return AppLocalizations.of(
                              context,
                            ).pleaseEnterValidAmount;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StatefulBuilder(
                        builder:
                            (context, setDateState) => FilledButton.icon(
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(
                                    widget.year,
                                    widget.month,
                                    1,
                                  ),
                                  lastDate: DateTime(
                                    widget.year,
                                    widget.month + 1,
                                    0,
                                  ),
                                );
                                if (date != null) {
                                  setDateState(() => selectedDate = date);
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                '${AppLocalizations.of(context).date}: \\${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                            ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.cancel),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;

                              // Show loading indicator
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );
                              final updatedMovement = MovementValue(
                                movement.id,
                                movement.monthId,
                                descriptionController.text,
                                double.parse(
                                  amountController.text.replaceAll(',', '.'),
                                ),
                                movement.isExpense,
                                selectedDate.day,
                                movement.category,
                              );

                              await _financeService.updateMovement(
                                updatedMovement,
                              );

                              // Call haveToUpload() after updating movement
                              await SharedPreferencesService().haveToUpload();

                              // Close both dialogs
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading
                              Navigator.pop(context); // Close form

                              // Show success message
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.movementUpdatedSuccessfully,
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Text(AppLocalizations.of(context)!.save),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Future<void> _showDeleteDialog(MovementValue movement) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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

  Future<void> _showCategoryChangeDialog(
    BuildContext context,
    MovementValue movement,
  ) async {
    // Combine existing categories with localized TagList and sort alphabetically
    final movements = await _financeService.getCurrentMonthMovements();
    final existingCategories = _getAvailableCategories(movements);
    final locale = AppLocalizations.of(context).localeName;
    final localizedTags = getTagList(locale);
    final allCategories =
        {...existingCategories, ...localizedTags}.toList()
          ..sort((a, b) => a.compareTo(b));

    await showModalBottomSheet(
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
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.category),
                      const SizedBox(width: 16),
                      Text(
                        AppLocalizations.of(context).changeCategory,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ...allCategories.map(
                        (category) => ListTile(
                          title: Text(category),
                          leading:
                              movement.category == category
                                  ? Icon(
                                    Icons.check,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                  : const Icon(Icons.label_outline),
                          onTap: () async {
                            final updatedMovement = MovementValue(
                              movement.id,
                              movement.monthId,
                              movement.description,
                              movement.amount,
                              movement.isExpense,
                              movement.day,
                              category,
                            ); // Show loading indicator
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );
                            await _financeService.updateMovement(
                              updatedMovement,
                            );

                            // Call haveToUpload() after updating movement category
                            await SharedPreferencesService().haveToUpload();

                            // Close loading dialog and bottom sheet
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context); // Close bottom sheet

                            // Show success message
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppLocalizations.of(context)!.categoryUpdated(
                                    updatedMovement.category ?? "",
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
