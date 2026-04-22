import 'package:cashly/data/models/savings_goal.dart';
import 'package:floor/floor.dart';

@dao
abstract class SavingsGoalDao {
  @Query('SELECT * FROM SavingsGoal ORDER BY createdAt ASC')
  Future<List<SavingsGoal>> findAll();

  @Query('SELECT * FROM SavingsGoal WHERE id = :id')
  Future<SavingsGoal?> findById(int id);

  @insert
  Future<int> insertGoal(SavingsGoal goal);

  @update
  Future<void> updateGoal(SavingsGoal goal);

  @delete
  Future<void> deleteGoal(SavingsGoal goal);

  @Query('DELETE FROM SavingsGoal')
  Future<void> deleteAll();
}
