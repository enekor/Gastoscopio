import 'package:floor/floor.dart';
import '../models/saves.dart';

@dao
abstract class SavesDao {
  @Query('SELECT * FROM Saves WHERE')
  Future<List<Saves>> findAllSaves();

  @Query('SELECT * FROM Saves WHERE dateStr like "%:anno-%"')
  Future<List<Saves>> findAllSavesByYear(int anno);

  @Query('SELECT * FROM Saves WHERE monthId = :monthId')
  Future<Saves?> findSavesByMonthId(int monthId);

  @Query('SELECT * FROM Saves WHERE isInitialValue = :isInitialValue ')
  Future<List<Saves>> findSavesByIsInitialValue(bool isInitialValue);

  @insert
  Future<void> insertSaves(Saves saves);

  @update
  Future<void> updateSaves(Saves saves);

  @delete
  Future<void> deleteSaves(Saves saves);

  @Query('DELETE FROM Saves where isInitialValue = 0')
  Future<void> deleteAllNonInitialSaves();
}
