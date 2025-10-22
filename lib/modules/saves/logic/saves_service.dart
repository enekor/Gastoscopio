import 'package:cashly/data/dao/saves_dao.dart';
import 'package:cashly/data/models/saves.dart';
import 'package:flutter/material.dart';

class SavesService extends ChangeNotifier {
  final SavesDao _savesDao;

  SavesService(this._savesDao);

  Future<List<Saves>> getSaves(int anno, bool searchByWholeYear) async {
    List<Saves> saves = [];
    if (searchByWholeYear) {
      saves = await _savesDao.findAllSavesByYear(anno);
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
}
