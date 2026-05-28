import 'package:cashly/data/models/debt_definition.dart';
import 'package:floor/floor.dart';

@dao
abstract class DebtDefinitionDao {
  @Query('SELECT * FROM DebtDefinition ORDER BY id DESC')
  Future<List<DebtDefinition>> findAllDebtDefinitions();

  @Query('SELECT * FROM DebtDefinition WHERE id = :id LIMIT 1')
  Future<DebtDefinition?> findDebtDefinitionById(int id);

  @Query(
    'SELECT * FROM DebtDefinition '
    'WHERE isActive = 1 AND recurrenceType = :recurrenceType '
    'ORDER BY id DESC',
  )
  Future<List<DebtDefinition>> findActiveByRecurrenceType(String recurrenceType);

  @Query('SELECT * FROM DebtDefinition WHERE isActive = 1 ORDER BY id DESC')
  Future<List<DebtDefinition>> findActiveDebtDefinitions();

  @insert
  Future<int> insertDebtDefinition(DebtDefinition debtDefinition);

  @update
  Future<void> updateDebtDefinition(DebtDefinition debtDefinition);

  @delete
  Future<void> deleteDebtDefinition(DebtDefinition debtDefinition);
}
