import 'package:cashly/data/dao/month_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/dao/saves_dao.dart';
import 'package:cashly/data/models/month.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:flutter/material.dart';

class SavesService extends ChangeNotifier {
  final SavesDao _savesDao;
  final MonthDao _monthDao;
  final MovementValueDao _movementValueDao;

  SavesService(this._savesDao, this._monthDao, this._movementValueDao);

  Future<List<Saves>> getSaves(int anno, bool searchByWholeYear) async {
    List<Saves> saves = [];
    if (searchByWholeYear) {
      saves = await _savesDao.findAllSavesByYear(anno.toString());
    } else {
      final _savesUnfiltered = await _savesDao.findAllSaves();
      Map<int, List<Saves>> savesMapByYear = {};
      for (Saves save in _savesUnfiltered) {
        int _year = save.date.year;
        if (!savesMapByYear.containsKey(_year)) {
          savesMapByYear[_year] = [save];
        } else {
          savesMapByYear[_year]!.add(save);
        }
      }

      for (int year in savesMapByYear.keys) {
        double totalAmount = 0;
        for (Saves save in savesMapByYear[year]!) {
          totalAmount += save.amount;
        }

        Saves yearSave = Saves(
          monthId: -1,
          amount: totalAmount,
          isInitialValue: false,
          dateStr: DateTime(year, 1, 1).toString(),
        );

        saves.add(yearSave);
      }
    }

    return saves;
  }

  Future<void> addSave(double amount) async {
    final save = Saves(
      monthId: -1,
      amount: amount,
      isInitialValue: true,
      dateStr: DateTime(1, 1, 1).toString(),
    );
    await _savesDao.insertSaves(save);
  }

  Future<void> updateSave(Saves save) async {
    await _savesDao.updateSaves(save);
  }

  Future<void> deleteSave(Saves save) async {
    await _savesDao.deleteSaves(save);
  }

  Future<List<Saves>> getSavesByIsInitialValue() async {
    final saves = await _savesDao.findSavesByIsInitialValue(true);
    return saves;
  }

  Future<void> deleteInitialSave() async {
    final saves = await _savesDao.findSavesByIsInitialValue(true);
    if (saves.isNotEmpty) {
      await _savesDao.deleteSaves(saves.first);
    }
  }

  Future<void> generateAllSaves() async {
    //por cada mes guardado en la base de datos, sacar el total restante de cada mes, generar el ahorro para dicho mes y guardarlo en la base de datos con la fecha de dicho mes
    final months = await _monthDao.findAllMonths();
    for (final month in months) {
      final totalRemaining = await _getTotalRemaining(month.id!);
      final date = await _getMonthDate(month.id!);
      final save = Saves(
        monthId: month.id!,
        amount: totalRemaining,
        isInitialValue: false,
        dateStr: date.toString(),
      );
      await _savesDao.deleteSavesByMonthId(month.id!);
      await _savesDao.insertSaves(save);
    }
  }

  Future<double> _getTotalRemaining(int monthId) async {
    Month? _currentMonth = await _monthDao.findMonthById(monthId);
    final totalInserts = await _getCurrentMonthInserts(_currentMonth);
    final totalExpenses = await _getCurrentMonthExpenses(_currentMonth);
    return totalInserts - totalExpenses;
  }

  Future<DateTime> _getMonthDate(int monthId) async {
    final month = await _monthDao.findMonthById(monthId);
    return new DateTime(month!.year, month.month, 1);
  }

  Future<double> _getCurrentMonthInserts(Month? currentMonth) async {
    if (currentMonth == null) return 0.0;
    double _monthIncomes =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          currentMonth.id!,
          false,
        ) ??
        0.0;

    return _monthIncomes;
  }

  Future<double> _getCurrentMonthExpenses(Month? currentMonth) async {
    if (currentMonth == null) return 0.0;
    double _monthExpenses =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          currentMonth.id!,
          true,
        ) ??
        0.0;

    return _monthExpenses;
  }

  Future<bool> needToGenerate() async {
    int savesCount = await _savesDao.countNonInitialSaves() ?? 0;
    int monthCount = await _monthDao.countAllMonths() ?? 0;
    return monthCount != savesCount;
  }

  Future<double> getMonthlyAverage() async {
    final saves = await _savesDao.findAllSaves();
    if (saves.isEmpty) return 0.0;

    double total = saves.fold(0.0, (sum, save) => sum + save.amount);
    return total / saves.length;
  }

  Future<Saves?> getBestMonth() async {
    final saves = await _savesDao.findAllSaves();
    if (saves.isEmpty) return null;

    return saves.reduce(
      (curr, next) => curr.amount > next.amount ? curr : next,
    );
  }

  Future<Saves?> getWorstMonth() async {
    final saves = await _savesDao.findAllSaves();
    if (saves.isEmpty) return null;

    return saves.reduce(
      (curr, next) => curr.amount < next.amount ? curr : next,
    );
  }

  Future<void> exportToCSV() async {
    // TODO: Implementar exportación a CSV
  }

  double calculateProjectedDate(
    double currentAmount,
    double targetAmount,
    double monthlyAverage,
  ) {
    if (monthlyAverage <= 0) return -1;
    double remaining = targetAmount - currentAmount;
    return remaining / monthlyAverage;
  }
}
