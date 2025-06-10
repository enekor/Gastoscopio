import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/dao/fixed_movement_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/models/fixed_movement.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FinanceService extends ChangeNotifier {
  static FinanceService? _instance;
  final MonthDao _monthDao;
  final MovementValueDao _movementValueDao;
  final FixedMovementDao _fixedMovementDao;
  Month? _currentMonth;
  List<MovementValue> _todayMovements = [];
  Map<String, double> _monthSummary = {};
  double _monthTotal = 0;
  double _monthIncomes = 0;
  double _monthExpenses = 0;

  // Private constructor
  FinanceService._internal(
    this._monthDao,
    this._movementValueDao,
    this._fixedMovementDao,
  );

  // Factory constructor to get instance
  static FinanceService getInstance(
    MonthDao monthDao,
    MovementValueDao movementValueDao,
    FixedMovementDao fixedMovementDao,
  ) {
    _instance ??= FinanceService._internal(
      monthDao,
      movementValueDao,
      fixedMovementDao,
    );
    return _instance!;
  }

  Month? get currentMonth => _currentMonth;
  List<MovementValue> get todayMovements => _todayMovements;
  Map<String, double> get monthSummary => _monthSummary;
  double get monthTotal => _monthTotal;
  double get monthIncomes => _monthIncomes;
  double get monthExpenses => _monthExpenses;

  Future<void> setCurrentMonth(int month, int year) async {
    final monthData = await _monthDao.findMonthByMonthAndYear(month, year);
    if (monthData == null) {
      // Create new month if it doesn't exist
      final newMonth = Month(month, year);
      await _monthDao.insertMonth(newMonth);
      _currentMonth = await _monthDao.findMonthByMonthAndYear(month, year);

      // Copy fixed movements to new month
      if (_currentMonth != null) {
        final fixedMovements = await _fixedMovementDao.findAllFixedMovements();
        for (final movement in fixedMovements) {
          final movementValue = movement.toMovementValue(_currentMonth!.id!);
          await _movementValueDao.insertMovementValue(movementValue);
        }
      }
    } else {
      _currentMonth = monthData;
    }
    await _updateMonthData();
    notifyListeners();
  }

  Future<void> _updateMonthData() async {
    if (_currentMonth == null) return;

    // Obtener movimientos del mes actual
    final expenses = await _movementValueDao.findMovementValuesByMonthIdAndType(
      _currentMonth!.id!,
      true,
    );
    final incomes = await _movementValueDao.findMovementValuesByMonthIdAndType(
      _currentMonth!.id!,
      false,
    );

    // Calcular total del mes
    final totalExpenses =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          _currentMonth!.id!,
          true,
        ) ??
        0.0;
    final totalIncomes =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          _currentMonth!.id!,
          false,
        ) ??
        0.0;

    _monthTotal = totalIncomes - totalExpenses;
    _monthIncomes = totalIncomes;
    _monthExpenses = totalExpenses;

    // Actualizar movimientos de hoy
    final now = DateTime.now();
    if (now.month == _currentMonth!.month && now.year == _currentMonth!.year) {
      _todayMovements =
          [...expenses, ...incomes].where((m) => m.day == now.day).toList()
            ..sort((a, b) => b.id!.compareTo(a.id!));
    } else {
      _todayMovements = [];
    }

    notifyListeners();
  }

  Future<List<int>> getAvailableYears() async {
    final months = await _monthDao.findAllMonths();
    final years = months.map((m) => m.year).toSet().toList()..sort();

    // Asegurar que el año actual esté disponible
    final currentYear = DateTime.now().year;
    if (!years.contains(currentYear)) {
      years.add(currentYear);
      years.sort();
    }

    return years;
  }

  Future<List<int>> getAvailableMonths(int year) async {
    final now = DateTime.now();

    // Para el año actual, mostrar hasta el mes actual
    if (year == now.year) {
      return List.generate(now.month, (index) => index + 1);
    }

    // Para años pasados, mostrar todos los meses
    if (year < now.year) {
      return List.generate(12, (index) => index + 1);
    }

    // Para años futuros, solo mostrar los meses que existan
    final months = await _monthDao.findAllMonths();
    return months
        .where((m) => m.year == year)
        .map((m) => m.month)
        .toSet()
        .toList()
      ..sort();
  }

  String currentMonthName() {
    if (_currentMonth == null) return 'Mes no seleccionado';
    return '${_getMonthName(_currentMonth!.month)} ${_currentMonth!.year}';
  }

  /// Verifica si un mes existe en la base de datos
  Future<bool> monthExists(int month, int year) async {
    final monthData = await _monthDao.findMonthByMonthAndYear(month, year);
    return monthData != null;
  }

  /// Crea un nuevo mes si el usuario lo confirma, o permite seleccionar uno existente
  /// Retorna el mes que se debe usar (el nuevo, el seleccionado, o null si se canceló)
  Future<int?> handleMonthSelection(
    int month,
    int year,
    BuildContext context,
  ) async {
    if (await monthExists(month, year)) {
      await setCurrentMonth(month, year);
      return month;
    }

    final shouldCreate =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Crear nuevo mes'),
                content: Text(
                  'El mes ${_getMonthName(month)} de $year no existe. ¿Deseas crearlo?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sí'),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldCreate) {
      final newMonth = Month(month, year);
      await _monthDao.insertMonth(newMonth);
      return month;
    } // Si el usuario no quiere crear el mes, seleccionar el último mes existente
    final existingMonths = await _monthDao.findAllMonths();
    final availableMonths =
        existingMonths.where((m) => m.year == year).map((m) => m.month).toList()
          ..sort();

    if (availableMonths.isEmpty) return null;

    final lastMonth = availableMonths.last;
    await setCurrentMonth(lastMonth, year);
    return lastMonth;
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return monthNames[month - 1];
  }

  Future<Map<String, double>> getCategoryTotals() async {
    if (_currentMonth == null) return {};

    final movements = await _movementValueDao.findMovementValuesByMonthId(
      _currentMonth!.id!,
    );
    final Map<String, double> totals = {};

    for (var movement in movements) {
      if (movement.category == null) continue;
      totals[movement.category!] =
          (totals[movement.category!] ?? 0) + movement.amount;
    }

    return totals;
  }

  Future<List<MapEntry<DateTime, double>>> getDailyTotals() async {
    if (_currentMonth == null) return [];

    final movements = await _movementValueDao.findMovementValuesByMonthId(
      _currentMonth!.id!,
    );
    final Map<DateTime, double> dailyTotals = {};

    for (var movement in movements) {
      final date = DateTime(
        _currentMonth!.year,
        _currentMonth!.month,
        movement.day,
      );
      dailyTotals[date] =
          (dailyTotals[date] ?? 0) +
          (movement.isExpense ? -movement.amount : movement.amount);
    }

    return dailyTotals.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  /// Actualiza la fecha seleccionada y carga los datos correspondientes
  Future<void> updateSelectedDate(int month, int year) async {
    await setCurrentMonth(month, year);
    // setCurrentMonth ya hace notifyListeners() internamente
  }

  Future<List<MovementValue>> getCurrentMonthMovements() async {
    if (_currentMonth == null) return [];
    return _movementValueDao.findMovementValuesByMonthId(_currentMonth!.id!);
  }

  Future<void> getCurrentMonthInserts() async {
    if (_currentMonth == null) return;
    _monthIncomes =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          _currentMonth!.id!,
          false,
        ) ??
        0.0;
  }

  Future<void> getCurrentMonthExpenses() async {
    if (_currentMonth == null) return;
    _monthExpenses =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          _currentMonth!.id!,
          true,
        ) ??
        0.0;
  }

  Future<bool> deleteMovement(
    BuildContext context,
    MovementValue movement,
  ) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: Text(
                  '¿Estás seguro de que quieres eliminar "${movement.description}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;

    if (!shouldDelete) return false;

    try {
      // Show loading indicator
      if (!context.mounted) return false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _movementValueDao.deleteMovementValue(movement);
      await _updateMonthData();
      notifyListeners();

      // Close loading dialog
      if (!context.mounted) return true;
      Navigator.of(context).pop();

      // Show success message
      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${movement.description} eliminado con éxito'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return true;
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar ${movement.description}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }
  }

  Future<void> showEditMovementDialog(
    BuildContext context,
    MovementValue movement,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: movement.description);
    final amountController = TextEditingController(
      text: movement.amount.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Editar movimiento'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator:
                        (value) =>
                            value?.isEmpty == true
                                ? 'El nombre es requerido'
                                : null,
                  ),
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty == true)
                        return 'El monto es requerido';
                      if (double.tryParse(value!) == null)
                        return 'Monto inválido';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState?.validate() == true) {
                    final updatedMovement = MovementValue(
                      movement.id,
                      movement.monthId,
                      nameController.text,
                      double.parse(amountController.text),
                      movement.isExpense,
                      movement.day,
                      movement.category,
                    );
                    await _movementValueDao.updateMovementValue(
                      updatedMovement,
                    );
                    await _updateMonthData();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  /// Obtiene los totales mensuales de ingresos y gastos para un año específico
  Future<List<Map<String, double>>> getYearlyData(int year) async {
    final months = await _monthDao.findAllMonths();
    List<Map<String, double>> yearlyData = List.generate(
      12,
      (index) => {'expenses': 0.0, 'incomes': 0.0},
    );

    for (var month in months) {
      if (month.year != year) continue;

      final expenses =
          await _movementValueDao.sumMovementValuesByMonthIdAndType(
            month.id!,
            true,
          ) ??
          0.0;

      final incomes =
          await _movementValueDao.sumMovementValuesByMonthIdAndType(
            month.id!,
            false,
          ) ??
          0.0;

      yearlyData[month.month - 1] = {'expenses': expenses, 'incomes': incomes};
    }

    return yearlyData;
  }

  /// Updates a movement value in the database and refreshes the UI
  Future<void> updateMovement(MovementValue movement) async {
    await _movementValueDao.updateMovementValue(movement);
    await _updateMonthData();
    notifyListeners();
  }

  /// Gets all movements for a specific month and year
  Future<List<MovementValue>> getMovementsForMonth(int month, int year) async {
    final monthData = await _monthDao.findMonthByMonthAndYear(month, year);
    if (monthData == null) return [];
    return _movementValueDao.findMovementValuesByMonthId(monthData.id!);
  }
}
