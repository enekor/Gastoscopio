import 'package:cashly/data/models/movement_value.dart';
import 'package:floor/floor.dart';

@dao
abstract class MovementValueDao {
  @Query('SELECT * FROM MovementValue WHERE monthId = :monthId')
  Future<List<MovementValue>> findMovementValuesByMonthId(int monthId);

  @Query(
    'SELECT * FROM MovementValue WHERE monthId = :monthId AND isExpense = :isExpense',
  )
  Future<List<MovementValue>> findMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  );
  @Query(
    'SELECT COALESCE(SUM(amount), 0.0) FROM MovementValue WHERE monthId = :monthId AND isExpense = :isExpense',
  )
  Future<double?> sumMovementValuesByMonthIdAndType(
    int monthId,
    bool isExpense,
  );

  @insert
  Future<void> insertMovementValue(MovementValue movementValue);

  @update
  Future<void> updateMovementValue(MovementValue movementValue);
  @delete
  Future<void> deleteMovementValue(MovementValue movementValue);

  @Query('DELETE FROM MovementValue')
  Future<void> deleteAllMovements();
}
