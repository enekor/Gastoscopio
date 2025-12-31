import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ViewMovementsFilteredScreen extends StatefulWidget {
  const ViewMovementsFilteredScreen({super.key});

  @override
  State<ViewMovementsFilteredScreen> createState() =>
      _ViewMovementsFilteredScreenState();
}

class _ViewMovementsFilteredScreenState
    extends State<ViewMovementsFilteredScreen> {
  List<MovementValue> movements = const [];
  List<Month> months = [];
  SqliteService sqliteService = SqliteService();
  DateTimeRange? selectedDateRange;
  bool isExpense = true;
  String _searchQuery = '';
  String _moneda = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€';
          }),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    movements = [];

    for (
      DateTime date = selectedDateRange!.start;
      date.isBefore(selectedDateRange!.end) ||
          date.isAtSameMomentAs(selectedDateRange!.end);
      date = DateTime(date.year, date.month + 1)
    ) {
      Month? month = await sqliteService.db.monthDao.findMonthByMonthAndYear(
        date.month,
        date.year,
      );
      if (month != null) {
        months.add(month);
        List<MovementValue> _movementsFiltered = await sqliteService
            .db
            .movementValueDao
            .findMovementValuesByMonthId(month.id!);

        movements.addAll(
          _movementsFiltered
              .where((mov) => mov.isExpense == isExpense)
              .toList(),
        );
      }
    }

    setState(() {});
  }

  List<MovementValue> _filterMovements() => movements.where((movement) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final description = movement.description.toLowerCase();
        return description.contains(query);
      }
      return true;
    }).toList();


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 35.0),
          child: Text(localizations.filteredMovements),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Filtros
            Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withAlpha(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de tipo
                  Row(
                    children: [
                      Text(
                        '${localizations.movementType}: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ToggleButtons(
                          isSelected: [isExpense, !isExpense],
                          onPressed: (index) {
                            setState(() {
                              isExpense = index == 0;
                            });
                            if (selectedDateRange != null) {
                              _loadMovements();
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          fillColor: Theme.of(context).colorScheme.primary,
                          color: Theme.of(context).colorScheme.onSurface,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(localizations.expenses),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Text(localizations.incomes),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Selector de rango de fechas
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.date,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTimeRange? picked =
                              await showDateRangePicker(
                                saveText: localizations.save,
                                cancelText: localizations.cancel,
                                confirmText: localizations.accept,
                                helpText: localizations.selectDateRange,
                                barrierColor: Colors.transparent,
                                builder: (context, child) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 15),
                                  child: Card(child: child)
                                ),
                                context: context,

                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                initialDateRange: selectedDateRange,
                              );
                          if (picked != null) {
                            setState(() {
                              selectedDateRange = picked;
                            });
                            await _loadMovements();
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          selectedDateRange == null
                              ? localizations.selectDate
                              : '${selectedDateRange!.start.toLocal().toString().split(' ')[0]} - ${selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Buscador por nombre
                  if (movements.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: localizations.search,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: _filterMovements().isEmpty && selectedDateRange == null
                  ? Center(
                      child: Text(localizations.selectDateRange),
                    )
                  : ListView.builder(
                      itemCount: _filterMovements().length,
                      itemBuilder: (context, index) {
                        final movement = _filterMovements()[index];
                        return ListTile(
                          title: Text(movement.description),
                          subtitle: Text('${movement.day}/${months.firstWhere((month) => month.id == movement.monthId).month}/${months.firstWhere((month) => month.id == movement.monthId).year}'),
                          leading: Icon(movement.isExpense
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: movement.isExpense
                              ? Colors.red
                              : Colors.green,),
                            trailing: Text(
                              '${movement.amount}$_moneda',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: movement.isExpense ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${localizations.total}: ${_filterMovements().fold(0.0, (previousValue, element) => previousValue + element.amount).toStringAsFixed(2)}$_moneda',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
