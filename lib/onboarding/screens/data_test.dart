import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:flutter/material.dart';

class DataTestPage extends StatefulWidget {
  const DataTestPage({super.key});

  @override
  State<DataTestPage> createState() => _DataTestPageState();
}

class _DataTestPageState extends State<DataTestPage> {
  final AppDatabase _db = SqliteService().db;
  List<Month> _months = [];
  List<MovementValue> _movements = [];
  Month? _selectedMonth;
  bool? _showExpenses;
  late String _moneda;

  @override
  void initState() {
    super.initState();
    _loadMonths();
    SharedPreferencesService()
        .getStringValue(SharedPreferencesKeys.currency)
        .then(
          (currency) => setState(() {
            _moneda = currency ?? '€'; // Valor por defecto si no se encuentra
          }),
        );
  }

  Future<void> _loadMonths() async {
    final months = await _db.monthDao.findAllMonths();
    setState(() {
      _months = months;
      _movements = [];
      _selectedMonth = null;
      _showExpenses = null;
    });
  }

  Future<void> _loadMovements(Month month, bool isExpense) async {
    final movements = await _db.movementValueDao
        .findMovementValuesByMonthIdAndType(month.id!, isExpense);
    setState(() {
      _movements = movements;
      _selectedMonth = month;
      _showExpenses = isExpense;
    });
  }

  void _showMovementTypeDialog(Month month) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${month.month}/${month.year}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Ver Gastos'),
                  leading: const Icon(Icons.money_off),
                  onTap: () {
                    Navigator.pop(context);
                    _loadMovements(month, true);
                  },
                ),
                ListTile(
                  title: const Text('Ver Ingresos'),
                  leading: const Icon(Icons.money),
                  onTap: () {
                    Navigator.pop(context);
                    _loadMovements(month, false);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMovementsList() {
    if (_movements.isEmpty) {
      return const Center(child: Text('No hay movimientos para mostrar'));
    }

    return ListView.builder(
      itemCount: _movements.length,
      itemBuilder: (context, index) {
        final movement = _movements[index];
        return Card(
          color: Theme.of(context).colorScheme.secondary.withAlpha(25),
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(movement.description),
            subtitle: Text('Día ${movement.day}'),
            trailing: Text(
              '${movement.isExpense ? "-" : "+"}${movement.amount.toStringAsFixed(2)}${_moneda}',
              style: TextStyle(
                color: movement.isExpense ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedMonth != null
              ? '${_selectedMonth!.month}/${_selectedMonth!.year} - ${_showExpenses! ? "Gastos" : "Ingresos"}'
              : 'Selecciona un mes',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _selectedMonth != null
                    ? () => _loadMovements(_selectedMonth!, _showExpenses!)
                    : _loadMonths,
          ),
        ],
      ),
      body:
          _selectedMonth == null
              ? ListView.builder(
                itemCount: _months.length,
                itemBuilder: (context, index) {
                  final month = _months[index];
                  return Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withAlpha(25),
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text('${month.month}/${month.year}'),
                      onTap: () => _showMovementTypeDialog(month),
                    ),
                  );
                },
              )
              : _buildMovementsList(),
    );
  }
}
