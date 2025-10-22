import 'package:floor/floor.dart';
import '../models/saves.dart';

@dao
abstract class SavesDao {
  @Query('SELECT * FROM Saves where isInitialValue = 0')
  Future<List<Saves>> findAllSaves();

  @Query('SELECT * FROM Saves WHERE date LIKE :anno || "-%"')
  Future<List<Saves>> findAllSavesByYear(String anno);

  @Query('SELECT * FROM Saves WHERE monthId = :monthId')
  Future<Saves?> findSavesByMonthId(int monthId);

  @Query('SELECT * FROM Saves WHERE isInitialValue = :isInitialValue ')
  Future<List<Saves>> findSavesByIsInitialValue(bool isInitialValue);

  @Query('Select count(*) from saves where isInitialValue = 0')
  Future<int?> countNonInitialSaves();

  @insert
  Future<void> insertSaves(Saves saves);

  @update
  Future<void> updateSaves(Saves saves);

  @delete
  Future<void> deleteSaves(Saves saves);

  @Query('DELETE FROM Saves where isInitialValue = 0')
  Future<void> deleteAllNonInitialSaves();

  @Query('DELETE FROM Saves WHERE monthId = :monthId')
  Future<void> deleteSavesByMonthId(int monthId) async {}
}
