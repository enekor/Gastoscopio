import 'package:cashly/data/models/movement_value.dart';
import 'package:floor/floor.dart';

@dao
abstract class MovementValueDao {
  @Query('SELECT * FROM MovementValue WHERE monthId = :monthId')
  Future<List<MovementValue>> findMovementValuesByMonthId(int monthId);

  @insert
  Future<void> insertMovementValue(MovementValue movementValue);

  @update
  Future<void> updateMovementValue(MovementValue movementValue);

  @delete
  Future<void> deleteMovementValue(MovementValue movementValue);
}
