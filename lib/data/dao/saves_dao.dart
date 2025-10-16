import 'package:floor/floor.dart';
import '../models/saves.dart';

@dao
abstract class SavesDao {
  @Query('SELECT * FROM Saves')
  Future<List<Saves>> findAllSaves();

  @Query('SELECT * FROM Saves WHERE monthId = :monthId')
  Future<Saves?> findSavesByMonthId(int monthId);

  @Query('SELECT * FROM Saves WHERE isInitialValue = :isInitialValue')
  Future<List<Saves>> findSavesByIsInitialValue(bool isInitialValue);

  @insert
  Future<void> insertSaves(Saves saves);

  @update
  Future<void> updateSaves(Saves saves);

  @delete
  Future<void> deleteSaves(Saves saves);

}