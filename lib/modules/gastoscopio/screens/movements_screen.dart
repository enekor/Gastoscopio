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

            return _buildContent(filteredMovements);
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

  Widget _buildContent(List<MovementValue> movements) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilters(),
          const SizedBox(height: 16),
          Expanded(child: _buildList(movements)),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_showExpenses ? 'Gastos' : 'Ingresos'),
      actions: [
        ToggleButtons(
          isSelected: [_showExpenses, !_showExpenses],
          onPressed: (index) {
            setState(() {
              _showExpenses = index == 0;
            });
          },
          children: const [Icon(Icons.money_off), Icon(Icons.money)],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildList(List<MovementValue> movements) {
    return ListView.builder(
      itemCount: movements.length,
      itemBuilder: (context, index) {
        final movement = movements[index];
        final isExpanded = _expandedItems[movement.id] ?? false;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              ListTile(
                title: Text(movement.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${movement.amount.toStringAsFixed(2)}',
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
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isExpanded ? 80 : 0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha: ${movement.day}/${widget.month}/${widget.year}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (movement.category != null)
                                  Text(
                                    'Categoría: ${movement.category}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
