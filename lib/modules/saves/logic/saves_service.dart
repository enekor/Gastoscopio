//service that manages the saves using servicedao from the database service
import 'package:cashly/data/dao/saves_dao.dart';

class SavesService extends ChangeNotifier {
    final SavesDao _savesDao;
    final MonthDao _monthDao;
    final MovementValueDao _movementValueDao;

    SavesService._internal(this._savesDao, this._monthDao, this._movementValueDao);

    factory SavesService() {
        return _instance;
    }

    SavesService._internal();

    Future<void> getSaves() async {
        final saves = await _savesDao.findAllSaves();
        return saves;
    }

    Future<void> addSave(double amount) async {
        final save = Saves(monthId: -1, amount: amount, isInitialValue: true);
        await _savesDao.insertSaves(save);
    }

    Future<void> updateSave(Saves save) async {
        await _savesDao.updateSaves(save);
    }

    Future<void> deleteSave(Saves save) async {
        await _savesDao.deleteSaves(save);
    }

    Future<void> getSavesByIsInitialValue() async {
        final saves = await _savesDao.findSavesByIsInitialValue(true);
        return saves;
    }

    Future<List<Saves>> generateSaves() async{
        if (await _savesDao.findAllSaves().isEmpty) {
            //por cada mes guardado en la base de datos, sacar el total restante de cada mes, generar el ahorro para dicho mes y guardarlo en la base de datos con la fecha de dicho mes
            final months = await _monthDao.findAllMonths();
            for (final month in months) {
                final totalRemaining = await _getTotalRemaining(month.id!);
                final date = await _getMonthDate(month.id!);
                final save = Saves(monthId: month.id!, amount: totalRemaining, isInitialValue: false, date: date, date:date);
                await _savesDao.insertSaves(save);
            }
        }

        return await _savesDao.findAllSaves();
    }

    Future<double> _getTotalRemaining(int monthId) async {
        final totalInserts = await _getCurrentMonthInserts(monthId);
        final totalExpenses = await _getCurrentMonthExpenses(monthId);
        return totalInserts - totalExpenses;
    }

    Future<DateTime> _getMonthDate(int monthId) async {
        final month = await _monthDao.findMonthById(monthId);
        return new DateTime(month!.year, month.month, 1);
    }

    Future<void> _getCurrentMonthInserts(int monthId) async {
    if (_currentMonth == null) return;
    _monthIncomes =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          monthId,
          false,
        ) ??
        0.0;
  }

  Future<void> _getCurrentMonthExpenses(int monthId) async {
    if (_currentMonth == null) return;
    _monthExpenses =
        await _movementValueDao.sumMovementValuesByMonthIdAndType(
          monthId,
          true,
        ) ??
        0.0;
  }
}       