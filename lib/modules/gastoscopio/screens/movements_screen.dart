import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/modules/gastoscopio/screens/movement_form_screen.dart';
import 'package:cashly/modules/gastoscopio/widgets/main_screen_widgets.dart';
import 'package:cashly/common/tag_list.dart';
import 'package:flutter/material.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/modules/gastoscopio/logic/finance_service.dart';
import 'package:provider/provider.dart';

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
  final Map<int, bool> _expandedItems = {};
  late String _moneda;

  @override
  void initState() {
    super.initState();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceService>(
      builder: (context, financeService, _) {
        return FutureBuilder<List<MovementValue>>(
          future: financeService.getCurrentMonthMovements(),
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
    );
  }

  Widget _buildContent(List<MovementValue> movements, String moneda) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => Theme(
                    data: Theme.of(context),
                    child: const MovementFormScreen(),
                  ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
        heroTag: 'movements_fab',
      ),
      body: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildList(movements, moneda)),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: ToggleButtons(
        borderRadius: BorderRadius.circular(25),
        borderColor: Theme.of(context).colorScheme.primary,
        fillColor: Theme.of(context).colorScheme.primary.withAlpha(45),
        selectedColor: Theme.of(context).colorScheme.onPrimary,
        isSelected: [_showExpenses, !_showExpenses],
        onPressed: (index) {
          setState(() {
            _showExpenses = index == 0;
          });
        },
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showExpenses = true;
              });
            },
            label: Text('Gastos'),
            icon: Icon(Icons.money_off),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showExpenses = false;
              });
            },
            label: Text('Ingresos'),
            icon: Icon(Icons.money),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedCard(
        context,
        isExpanded: false,
        color: Theme.of(context).colorScheme.secondary.withAlpha(45),
        leadingWidget: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              Icon(Icons.filter_list),
            ],
          ),
        ),
        hiddenWidget: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<List<MovementValue>>(
                      future:
                          Provider.of<FinanceService>(
                            context,
                            listen: false,
                          ).getCurrentMonthMovements(),
                      builder: (context, snapshot) {
                        final categories = _getAvailableCategories(
                          snapshot.data ?? [],
                        );
                        return FilledButton.tonal(
                          onPressed: () => _selectCategory(context, categories),
                          child: Text(
                            _selectedCategory ?? 'Seleccionar categoría',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<MovementValue> movements, String moneda) {
    return ListView.builder(
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        final isExpanded = _expandedItems[movement.id] ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: AnimatedCard(
            context,
            isExpanded: isExpanded,
            leadingWidget: Column(
              children: [
                ListTile(
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
                      IconButton(
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _expandedItems[movement.id] = !isExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            hiddenWidget: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        label: Text(
                          'Fecha: ${movement.day}/${widget.month}/${widget.year}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        icon: Icon(Icons.calendar_month),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showTagSelection(context, movement),
                        label: Text(
                          'Categoría: ${movement.category ?? 'Sin categoría'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        icon: Icon(Icons.category),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          context.read<FinanceService>().showEditMovementDialog(
                            context,
                            movement,
                          );
                        },
                        label: Text(
                          'Editar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        icon: Icon(Icons.edit),
                      ),

                      TextButton.icon(
                        onPressed: () {
                          context
                              .read<FinanceService>()
                              .deleteMovement(movement)
                              .then((_) => setState(() {}));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${movement.description} eliminado',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                        label: Text(
                          'Eliminar',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        icon: Icon(Icons.remove),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  void _selectCategory(BuildContext context, List<String> categories) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Todas'),
                  selected: _selectedCategory == null,
                  onTap: () {
                    setState(() => _selectedCategory = null);
                    Navigator.pop(context);
                  },
                ),
                ...categories.map(
                  (category) => ListTile(
                    title: Text(category),
                    selected: category == _selectedCategory,
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

  void _showTagSelection(BuildContext parentContext, MovementValue movement) {
    // Get the FinanceService before opening the modal
    final financeService = parentContext.read<FinanceService>();

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Seleccionar categoría',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: TagList.length,
                    itemBuilder: (context, index) {
                      final category = TagList[index];
                      final isSelected = category == movement.category;

                      return ListTile(
                        title: Text(category),
                        selected: isSelected,
                        leading: isSelected ? Icon(Icons.check) : null,
                        onTap: () async {
                          final updatedMovement = movement.copyWith(
                            category: category,
                          );
                          await financeService.updateMovement(updatedMovement);
                          Navigator.pop(context);
                          setState(() {}); // Refresh UI
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _getAvailableCategories(List<MovementValue> movements) {
    return movements
        .where((m) => m.category != null)
        .map((m) => m.category!)
        .toSet()
        .toList();
  }

  List<MovementValue> _filterMovements(List<MovementValue> movements) {
    return movements.where((movement) {
      // Filtrar por tipo (gasto/ingreso)
      if (movement.isExpense != _showExpenses) return false;

      // Filtrar por fecha si está seleccionada
      if (_selectedDate != null && movement.day != _selectedDate!.day) {
        return false;
      }

      // Filtrar por categoría si está seleccionada
      if (_selectedCategory != null && movement.category != _selectedCategory) {
        return false;
      }

      // Filtrar por texto de búsqueda
      if (_searchQuery.isNotEmpty &&
          !movement.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          )) {
        return false;
      }

      return true;
    }).toList();
  }
}
