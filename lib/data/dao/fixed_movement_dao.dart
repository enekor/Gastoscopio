import 'package:floor/floor.dart';
import 'package:cashly/data/models/fixed_movement.dart';

@dao
abstract class FixedMovementDao {
  @Query('SELECT * FROM FixedMovement')
  Future<List<FixedMovement>> findAllFixedMovements();

  @Query('SELECT * FROM FixedMovement WHERE id = :id')
  Future<FixedMovement?> findFixedMovementById(int id);

  @Query('SELECT * FROM FixedMovement WHERE isExpense = :isExpense')
  Future<List<FixedMovement>> findFixedMovementsByType(bool isExpense);

  @insert
  Future<void> insertFixedMovement(FixedMovement fixedMovement);

  @update
  Future<void> updateFixedMovement(FixedMovement fixedMovement);

  @delete
  Future<void> deleteFixedMovement(FixedMovement fixedMovement);
}
