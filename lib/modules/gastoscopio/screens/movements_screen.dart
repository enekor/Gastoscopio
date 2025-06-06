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
              context,
              isExpanded: isExpanded,
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
                onTap: () {
                  setState(() {
                    final key = movement.id.toString();
                    _expandedItems[key] = !(_expandedItems[key] ?? false);
                  });
                },
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
        context,
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

  void _selectCategory(BuildContext context, Set<String> categories) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecciona una categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Todas'),
                  leading:
                      _selectedCategory == null
                          ? const Icon(Icons.check)
                          : null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(context);
                  },
                ),
                ...categories.map(
                  (category) => ListTile(
                    title: Text(category),
                    leading:
                        _selectedCategory == category
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () {
                      setState(() => _selectedCategory = category);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(MovementValue movement) async {
    // Show edit dialog
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => MovementFormScreen(),
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
}
