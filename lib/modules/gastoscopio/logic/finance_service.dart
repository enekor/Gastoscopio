import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FinanceService extends ChangeNotifier {
  final MonthDao _monthDao;
  final MovementValueDao _movementValueDao;
  Month? _currentMonth;
  List<MovementValue> _todayMovements = [];
  Map<String, double> _monthSummary = {};
  double _monthTotal = 0;

  FinanceService(this._monthDao, this._movementValueDao);

  Month? get currentMonth => _currentMonth;
  List<MovementValue> get todayMovements => _todayMovements;
  Map<String, double> get monthSummary => _monthSummary;
  double get monthTotal => _monthTotal;

  Future<void> setCurrentMonth(int month, int year) async {
    final monthStream =
        await _monthDao.findMonthByMonthAndYear(month, year).first;
    if (monthStream == null) {
      // Crear nuevo mes si no existe
      final newMonth = Month(month, year);
      await _monthDao.insertMonth(newMonth);
      _currentMonth =
          await _monthDao.findMonthByMonthAndYear(month, year).first;
    } else {
      _currentMonth = monthStream;
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

  /// Verifica si un mes existe en la base de datos
  Future<bool> monthExists(int month, int year) async {
    final monthData =
        await _monthDao.findMonthByMonthAndYear(month, year).first;
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
}
