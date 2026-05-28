import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/dao/fixed_movement_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/movement_value.dart';
import 'package:cashly/data/models/fixed_movement.dart';
import 'package:cashly/data/models/debt_definition.dart';
import 'package:cashly/data/models/debt_occurrence.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:cashly/data/services/shared_preferences_service.dart';
import 'package:cashly/data/services/sqlite_service.dart';
import 'package:cashly/l10n/app_localizations.dart';
import 'package:cashly/data/services/log_file_service.dart';
import 'package:cashly/modules/gastoscopio/widgets/loading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

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

  Database get _rawDb => SqliteService().db.database;

  DebtDefinition _debtDefinitionFromMap(Map<String, Object?> row) {
    return DebtDefinition(
      row['id'] as int?,
      row['description'] as String,
      (row['amount'] as num).toDouble(),
      (row['isExpense'] as int) == 1,
      row['category'] as String?,
      row['recurrenceType'] as String,
      row['startDay'] as int,
      row['startMonth'] as int,
      row['startYear'] as int,
      (row['isActive'] as int) == 1,
    );
  }

  DebtOccurrence _debtOccurrenceFromMap(Map<String, Object?> row) {
    return DebtOccurrence(
      row['id'] as int?,
      row['debtDefinitionId'] as int,
      row['monthId'] as int,
      row['dueDay'] as int,
      row['originMonth'] as int,
      row['originYear'] as int,
      row['status'] as String,
      row['completedAt'] as String?,
    );
  }

  Future<List<DebtDefinition>> _findActiveDebtDefinitionsRaw() async {
    final rows = await _rawDb.rawQuery(
      'SELECT * FROM DebtDefinition WHERE isActive = 1 ORDER BY id DESC',
    );
    return rows.map(_debtDefinitionFromMap).toList();
  }

  Future<DebtDefinition?> _findDebtDefinitionByIdRaw(int id) async {
    final rows = await _rawDb.rawQuery(
      'SELECT * FROM DebtDefinition WHERE id = ? LIMIT 1',
      [id],
    );
    if (rows.isEmpty) return null;
    return _debtDefinitionFromMap(rows.first);
  }

  Future<int> _insertDebtDefinitionRaw(DebtDefinition definition) {
    return _rawDb.rawInsert(
      'INSERT INTO DebtDefinition (description, amount, isExpense, category, recurrenceType, startDay, startMonth, startYear, isActive) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        definition.description,
        definition.amount,
        definition.isExpense ? 1 : 0,
        definition.category,
        definition.recurrenceType,
        definition.startDay,
        definition.startMonth,
        definition.startYear,
        definition.isActive ? 1 : 0,
      ],
    );
  }

  Future<void> _updateDebtDefinitionRaw(DebtDefinition definition) async {
    await _rawDb.rawUpdate(
      'UPDATE DebtDefinition SET description = ?, amount = ?, isExpense = ?, category = ?, recurrenceType = ?, '
      'startDay = ?, startMonth = ?, startYear = ?, isActive = ? WHERE id = ?',
      [
        definition.description,
        definition.amount,
        definition.isExpense ? 1 : 0,
        definition.category,
        definition.recurrenceType,
        definition.startDay,
        definition.startMonth,
        definition.startYear,
        definition.isActive ? 1 : 0,
        definition.id,
      ],
    );
  }

  Future<void> _deleteDebtDefinitionRaw(DebtDefinition definition) async {
    await _rawDb.rawDelete('DELETE FROM DebtDefinition WHERE id = ?', [definition.id]);
  }

  Future<int?> _countDebtOccurrenceByDefinitionAndMonthRaw(
    int debtDefinitionId,
    int monthId,
  ) async {
    final rows = await _rawDb.rawQuery(
      'SELECT COUNT(*) AS count FROM DebtOccurrence WHERE debtDefinitionId = ? AND monthId = ?',
      [debtDefinitionId, monthId],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['count'] as num?)?.toInt() ?? 0;
  }

  Future<int> _insertDebtOccurrenceRaw(DebtOccurrence occurrence) {
    return _rawDb.rawInsert(
      'INSERT INTO DebtOccurrence (debtDefinitionId, monthId, dueDay, originMonth, originYear, status, completedAt) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        occurrence.debtDefinitionId,
        occurrence.monthId,
        occurrence.dueDay,
        occurrence.originMonth,
        occurrence.originYear,
        occurrence.status,
        occurrence.completedAt,
      ],
    );
  }

  Future<void> _updateDebtOccurrenceRaw(DebtOccurrence occurrence) async {
    await _rawDb.rawUpdate(
      'UPDATE DebtOccurrence SET debtDefinitionId = ?, monthId = ?, dueDay = ?, originMonth = ?, originYear = ?, status = ?, completedAt = ? '
      'WHERE id = ?',
      [
        occurrence.debtDefinitionId,
        occurrence.monthId,
        occurrence.dueDay,
        occurrence.originMonth,
        occurrence.originYear,
        occurrence.status,
        occurrence.completedAt,
        occurrence.id,
      ],
    );
  }

  Future<List<DebtOccurrence>> _findPendingOccurrencesUpToMonthRaw(
    int month,
    int year,
  ) async {
    final rows = await _rawDb.rawQuery(
      'SELECT DebtOccurrence.* '
      'FROM DebtOccurrence '
      'INNER JOIN Month ON DebtOccurrence.monthId = Month.id '
      'WHERE DebtOccurrence.status = ? '
      'AND (Month.year < ? OR (Month.year = ? AND Month.month <= ?)) '
      'ORDER BY Month.year DESC, Month.month DESC, DebtOccurrence.dueDay ASC',
      [debtStatusPending, year, year, month],
    );
    return rows.map(_debtOccurrenceFromMap).toList();
  }

  bool _isMonthOnOrAfter(int month, int year, int referenceMonth, int referenceYear) {
    return year > referenceYear || (year == referenceYear && month >= referenceMonth);
  }

  int _adjustDayForMonth(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return day > lastDay ? lastDay : day;
  }

  Future<Month> _ensureMonthInitialized(int month, int year) async {
    final existing = await _monthDao.findMonthByMonthAndYear(month, year);
    if (existing != null) {
      await ensureDebtOccurrencesForMonth(existing.id!, month, year);
      return existing;
    }

    final newMonth = Month(month, year);
    await _monthDao.insertMonth(newMonth);
    final created = await _monthDao.findMonthByMonthAndYear(month, year);
    if (created == null) {
      throw Exception('Unable to create month $month/$year');
    }

    final fixedMovements = await _fixedMovementDao.findAllFixedMovements();
    for (final movement in fixedMovements) {
      final adjustedDay = _adjustDayForMonth(year, month, movement.day);
      final movementValue = movement.toMovementValue(created.id!).copyWith(
        day: adjustedDay,
        category: movement.category?.trim(),
      );
      await _movementValueDao.insertMovementValue(movementValue);
    }

    await ensureDebtOccurrencesForMonth(created.id!, month, year);

    if (fixedMovements.isNotEmpty) {
      await SharedPreferencesService().haveToUpload();
    }

    return created;
  }

  Future<void> ensureDebtOccurrencesForMonth(int monthId, int month, int year) async {
    final activeDebts = await _findActiveDebtDefinitionsRaw();
    for (final debt in activeDebts) {
      final startsBeforeOrAtCurrent = _isMonthOnOrAfter(
        month,
        year,
        debt.startMonth,
        debt.startYear,
      );
      if (!startsBeforeOrAtCurrent) continue;

      final isMonthly = debt.recurrenceType == debtRecurrenceMonthly;
      final isOneTime = debt.recurrenceType == debtRecurrenceOneTime;

      if (isOneTime && (debt.startMonth != month || debt.startYear != year)) {
        continue;
      }
      if (!isMonthly && !isOneTime) continue;

      final existingCount =
          await _countDebtOccurrenceByDefinitionAndMonthRaw(debt.id!, monthId) ?? 0;
      if (existingCount > 0) continue;

      final adjustedDay = _adjustDayForMonth(year, month, debt.startDay);
      await _insertDebtOccurrenceRaw(
        DebtOccurrence(
          null,
          debt.id!,
          monthId,
          adjustedDay,
          month,
          year,
          debtStatusPending,
          null,
        ),
      );
    }
  }

  Future<void> createMonthlyDebtDefinition({
    required String description,
    required double amount,
    required bool isExpense,
    required int day,
    String? category,
  }) async {
    if (_currentMonth == null) {
      throw Exception('No current month selected');
    }

    final createdId = await _insertDebtDefinitionRaw(
      DebtDefinition(
        null,
        description.trim(),
        amount,
        isExpense,
        category?.trim(),
        debtRecurrenceMonthly,
        day,
        _currentMonth!.month,
        _currentMonth!.year,
        true,
      ),
    );
    await _insertDebtOccurrenceRaw(
      DebtOccurrence(
        null,
        createdId,
        _currentMonth!.id!,
        _adjustDayForMonth(_currentMonth!.year, _currentMonth!.month, day),
        _currentMonth!.month,
        _currentMonth!.year,
        debtStatusPending,
        null,
      ),
    );

    await SharedPreferencesService().haveToUpload();
    notifyListeners();
  }

  Future<void> createOneTimeDebt({
    required String description,
    required double amount,
    required bool isExpense,
    required DateTime date,
    String? category,
  }) async {
    final monthId = await findMonthByMonthAndYear(date.month, date.year);
    final day = _adjustDayForMonth(date.year, date.month, date.day);

    final createdId = await _insertDebtDefinitionRaw(
      DebtDefinition(
        null,
        description.trim(),
        amount,
        isExpense,
        category?.trim(),
        debtRecurrenceOneTime,
        day,
        date.month,
        date.year,
        true,
      ),
    );

    await _insertDebtOccurrenceRaw(
      DebtOccurrence(
        null,
        createdId,
        monthId,
        day,
        date.month,
        date.year,
        debtStatusPending,
        null,
      ),
    );

    await SharedPreferencesService().haveToUpload();
    if (_currentMonth != null &&
        _currentMonth!.month == date.month &&
        _currentMonth!.year == date.year) {
      notifyListeners();
    }
  }

  Future<void> completeDebtOccurrence(DebtOccurrence occurrence) async {
    if (occurrence.status == debtStatusCompleted) {
      return;
    }
    final definition = await _findDebtDefinitionByIdRaw(
      occurrence.debtDefinitionId,
    );
    if (definition == null) {
      throw Exception('Debt definition not found');
    }

    final now = DateTime.now();
    final movementMonthId = await findMonthByMonthAndYear(now.month, now.year);
    final movement = MovementValue(
      null,
      movementMonthId,
      definition.description,
      definition.amount,
      definition.isExpense,
      now.day,
      definition.category?.trim(),
    );
    await _movementValueDao.insertMovementValue(movement);
    await _updateDebtOccurrenceRaw(
      occurrence.copyWith(
        status: debtStatusCompleted,
        completedAt: now.toIso8601String(),
      ),
    );

    await SharedPreferencesService().haveToUpload();
    if (_currentMonth != null) {
      await _updateMonthData();
    } else {
      notifyListeners();
    }
  }

  Future<List<DebtDefinition>> getMonthlyDebtDefinitions() {
    return _findActiveDebtDefinitionsRaw().then(
      (items) =>
          items.where((item) => item.recurrenceType == debtRecurrenceMonthly).toList(),
    );
  }

  Future<void> updateDebtDefinition(DebtDefinition debtDefinition) async {
    await _updateDebtDefinitionRaw(debtDefinition);
    await SharedPreferencesService().haveToUpload();
    notifyListeners();
  }

  Future<void> deleteDebtDefinition(DebtDefinition debtDefinition) async {
    await _deleteDebtDefinitionRaw(debtDefinition);
    await SharedPreferencesService().haveToUpload();
    notifyListeners();
  }

  Future<List<DebtViewItem>> getVisiblePendingDebtsForCurrentMonth() async {
    if (_currentMonth == null) return [];
    final pending =
        await _findPendingOccurrencesUpToMonthRaw(_currentMonth!.month, _currentMonth!.year);

    final Map<int, DebtDefinition> definitionCache = {};
    final Map<int, Month> monthCache = {};
    final List<DebtViewItem> result = [];

    for (final occurrence in pending) {
      final definition = definitionCache[occurrence.debtDefinitionId] ??
          await _findDebtDefinitionByIdRaw(occurrence.debtDefinitionId);
      if (definition == null) {
        continue;
      }
      definitionCache[occurrence.debtDefinitionId] = definition;
      final occurrenceMonth = monthCache[occurrence.monthId] ??
          await _monthDao.findMonthById(occurrence.monthId);
      if (occurrenceMonth == null) {
        continue;
      }
      monthCache[occurrence.monthId] = occurrenceMonth;
      result.add(DebtViewItem(definition: definition, occurrence: occurrence, month: occurrenceMonth));
    }
    return result;
  }

  Future<void> setCurrentMonth(int month, int year) async {
    _currentMonth = await _ensureMonthInitialized(month, year);
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

    await generateSavesByMonth(_monthTotal);

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

  String currentMonthName([BuildContext? context]) {
    if (_currentMonth == null) {
      return context != null
          ? AppLocalizations.of(context).noMonthSelected
          : 'No month selected';
    }
    return '${_getMonthName(_currentMonth!.month, context)} ${_currentMonth!.year}';
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
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).createNewMonth),
            content: Text(
              AppLocalizations.of(context).monthDoesNotExist(
                _getMonthName(month, context),
                year.toString(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context).no),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context).yes),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldCreate) {
      await setCurrentMonth(month, year);
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

  String _getMonthName(int month, [BuildContext? context]) {
    if (context != null) {
      final months = [
        AppLocalizations.of(context).january,
        AppLocalizations.of(context).february,
        AppLocalizations.of(context).march,
        AppLocalizations.of(context).april,
        AppLocalizations.of(context).may,
        AppLocalizations.of(context).june,
        AppLocalizations.of(context).july,
        AppLocalizations.of(context).august,
        AppLocalizations.of(context).september,
        AppLocalizations.of(context).october,
        AppLocalizations.of(context).november,
        AppLocalizations.of(context).december,
      ];
      return months[month - 1];
    }

    // Fallback to English if no context provided
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context).deleteMovement),
            content: Text(
              AppLocalizations.of(
                context,
              ).confirmDeleteMovement(movement.description),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context).cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(AppLocalizations.of(context).delete),
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
        builder: (context) => Center(child: Loading(context)),
      );
      await _movementValueDao.deleteMovementValue(movement);
      await _updateMonthData();
      notifyListeners();

      // Call haveToUpload() after deleting movement
      await SharedPreferencesService().haveToUpload();

      // Close loading dialog
      if (!context.mounted) return true;
      Navigator.of(context).pop();

      // Show success message
      if (!context.mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${movement.description} ${AppLocalizations.of(context).eliminatedSuccessfully}',
          ),
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
            content: Text(
              '${AppLocalizations.of(context).elimError} ${movement.description}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      LogFileService().appendLog('Error deleting movement: $e');
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
    final localizations = AppLocalizations.of(context);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.editMovement),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: localizations.name),
                validator: (value) =>
                    value?.isEmpty == true ? localizations.nameRequired : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: InputDecoration(labelText: localizations.amount),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true)
                    return localizations.amountRequired;
                  if (double.tryParse(value!) == null)
                    return localizations.invalidAmount;
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
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
                await _movementValueDao.updateMovementValue(updatedMovement);
                await _updateMonthData();
                Navigator.pop(context);
              }
            },
            child: Text(localizations.save),
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
    // Call haveToUpload() after updating movement
    await SharedPreferencesService().haveToUpload();
  }

  /// Gets all movements for a specific month and year
  Future<List<MovementValue>> getMovementsForMonth(int month, int year) async {
    final monthData = await _monthDao.findMonthByMonthAndYear(month, year);
    if (monthData == null) return [];
    return _movementValueDao.findMovementValuesByMonthId(monthData.id!);
  }

  Future<int> getMonthMovementsCount(int month, int year) async {
    int val =
        await _movementValueDao.countMovementValuesByMonth(month, year) ?? 0;
    return val;
  }

  Future<int> getMonthId(DateTime date) async {
    final month = await _monthDao.findMonthByMonthAndYear(
      date.month,
      date.year,
    );
    return month?.id ?? await _createMonth(date);
  }

  Future<int> _createMonth(DateTime date) async {
    final month = await _ensureMonthInitialized(date.month, date.year);
    return month.id!;
  }

  Future<int> findMonthByMonthAndYear(int month, int year) async {
    Month? targetMonth = await _monthDao.findMonthByMonthAndYear(month, year);
    if (targetMonth == null) {
      return _createMonth(DateTime(year, month, 1));
    }
    await ensureDebtOccurrencesForMonth(targetMonth.id!, month, year);
    return targetMonth.id!;
  }

  Future<void> migrateMonth(
    BuildContext context,
    MovementValue movementValue,
    int month,
    int year,
  ) async {
    final newMonthId = await findMonthByMonthAndYear(month, year);
    final updatedMovement = MovementValue(
      movementValue.id,
      newMonthId,
      movementValue.description,
      movementValue.amount,
      movementValue.isExpense,
      movementValue.day,
      movementValue.category,
    );
    await _movementValueDao.updateMovementValue(updatedMovement);
    await _updateMonthData();
    notifyListeners();
    // Call haveToUpload() after updating movement
    await SharedPreferencesService().haveToUpload();
  }

  Future<void> generateSavesByMonth(double savings) async {
    Saves save = Saves(
      monthId: _currentMonth!.id!,
      amount: savings,
      isInitialValue: false,
      dateStr: DateTime(
        _currentMonth!.year,
        _currentMonth!.month,
        1,
      ).toString(),
    );

    final db = SqliteService().db;
    await db.savesDao.deleteSavesByMonthId(_currentMonth!.id!);
    await db.savesDao.insertSaves(save);
  }

  Future<void> createNextMonth(BuildContext context) async {
    final now = DateTime.now();
    int nextMonth = now.month + 1 == 13 ? 1 : now.month + 1;
    int nextYear = now.month + 1 == 13 ? now.year + 1 : now.year;

    await handleMonthSelection(nextMonth, nextYear, context);
  }
}

class DebtViewItem {
  final DebtDefinition definition;
  final DebtOccurrence occurrence;
  final Month month;

  DebtViewItem({
    required this.definition,
    required this.occurrence,
    required this.month,
  });
}
