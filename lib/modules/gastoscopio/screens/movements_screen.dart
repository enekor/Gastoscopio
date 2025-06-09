import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:flutter/material.dart';
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

class _MovementsScreenState extends State<MovementsScreen> {
  bool _showExpenses = true;
  DateTime? _selectedDate;
  String? _selectedCategory;
  String _searchQuery = '';
  final Map<String, bool> _expandedItems = {};
  late String _moneda;
  late FinanceService _financeService;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _financeService = FinanceService.getInstance(
      SqliteService().db.monthDao,
      SqliteService().db.movementValueDao,
      SqliteService().db.fixedMovementDao,
    );
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
    _searchController.text = _searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _financeService,
      builder: (context, child) {
        return FutureBuilder<List<MovementValue>>(
          future: _financeService.getCurrentMonthMovements(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyScreen();
            }

            final allMovements = snapshot.data!;
            final filteredMovements = _filterMovements(allMovements);

            return _buildContent(filteredMovements, _moneda);
          },
        );
      },
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      appBar: _buildAppBar(),
      body: const Center(child: Text('No hay movimientos para mostrar')),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildFAB() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,

      elevation: 8,
      shape: const CircleBorder(),
      child: Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: FloatingActionButton.small(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              useSafeArea: true,
              builder: (BuildContext context) => MovementFormScreen(),
            );
          },
          child: const Icon(Icons.add),
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
        onPressed: (index) {
          setState(() {
            _showExpenses = index == 1;
          });
        },
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showExpenses = false;
              });
            },
            icon: const Icon(Icons.money),
            label: const Text('Ingresos'),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showExpenses = true;
              });
            },
            icon: const Icon(Icons.money_off),
            label: const Text('Gastos'),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildContent(List<MovementValue> movements, String moneda) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFAB(),
      body: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildList(movements, moneda)),
        ],
      ),
    );
  }

  Widget _buildList(List<MovementValue> movements, String moneda) {
    if (movements.isEmpty) {
      return Center(
        child: Text(
          _showExpenses ? 'No hay gastos' : 'No hay ingresos',
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _financeService.getCurrentMonthMovements();
        setState(() {});
      },
      child: ListView.builder(
        itemCount: movements.length,
        itemBuilder: (context, index) {
          final movement = movements[index];
          final isExpanded = _expandedItems[movement.id.toString()] ?? false;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          );
        },
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
              Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
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
        hiddenWidget: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _selectDate(context),
                    child: Text(
                      _selectedDate != null
                          ? 'Día ${_selectedDate!.day}'
                          : 'Seleccionar día',
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
                        child: Text(
                          _selectedCategory ?? 'Categoría: Todas',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                      labelText: 'Buscar',
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
                ElevatedButton.icon(
                  onPressed:
                      () =>
                          setState(() => _searchQuery = _searchController.text),
                  label: Text('Buscar'),
                  icon: Icon(Icons.search),
                ),
              ],
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
                  onPressed: () {},
                  label: Text(
                    '${movement.day}/${widget.month}/${widget.year}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  icon: const Icon(Icons.calendar_month),
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

  List<MovementValue> _filterMovements(List<MovementValue> movements) {
    return movements.where((movement) {
      // Filter by type (expense/income)
      if (movement.isExpense != _showExpenses) return false;

      // Filter by date if selected
      if (_selectedDate != null && movement.day != _selectedDate!.day) {
        return false;
      }

      // Filter by category if selected
      if (_selectedCategory != null &&
          _selectedCategory != 'Todas' &&
          movement.category != _selectedCategory) {
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
    // Combinar categorías existentes con TagList y ordenar alfabéticamente
    final allCategories =
        {...existingCategories, ...TagList}.toList()
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
                        'Selecciona una categoría',
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
                        title: const Text('Todas las categorías'),
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
                            'Editar movimiento',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una descripción';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: _moneda,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa una cantidad';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) ==
                              null) {
                            return 'Por favor ingresa un número válido';
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
                                'Fecha: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              ),
                            ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
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

                              // Close both dialogs
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading
                              Navigator.pop(context); // Close form

                              // Show success message
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Movimiento actualizado con éxito',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text('Guardar'),
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
            title: const Text('¿Eliminar movimiento?'),
            content: Text(
              '¿Estás seguro de que quieres eliminar "${movement.description}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
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
    // Combine existing categories with TagList and sort alphabetically
    final movements = await _financeService.getCurrentMonthMovements();
    final existingCategories = _getAvailableCategories(movements);
    final allCategories =
        {...existingCategories, ...TagList}.toList()
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
                        'Cambiar categoría',
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

                            // Close loading dialog and bottom sheet
                            if (!context.mounted) return;
                            Navigator.pop(context); // Close loading
                            Navigator.pop(context); // Close bottom sheet

                            // Show success message
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Categoría actualizada: ${updatedMovement.category}',
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
}
