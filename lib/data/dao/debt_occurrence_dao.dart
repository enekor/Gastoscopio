import 'package:cashly/data/models/debt_occurrence.dart';
import 'package:floor/floor.dart';

@dao
abstract class DebtOccurrenceDao {
  @Query('SELECT * FROM DebtOccurrence WHERE monthId = :monthId ORDER BY dueDay')
  Future<List<DebtOccurrence>> findOccurrencesByMonthId(int monthId);

  @Query(
    'SELECT * FROM DebtOccurrence '
    'WHERE debtDefinitionId = :debtDefinitionId AND monthId = :monthId LIMIT 1',
  )
  Future<DebtOccurrence?> findOccurrenceByDefinitionAndMonth(
    int debtDefinitionId,
    int monthId,
  );

  @Query(
    'SELECT DebtOccurrence.* '
    'FROM DebtOccurrence '
    'INNER JOIN Month ON DebtOccurrence.monthId = Month.id '
    'WHERE DebtOccurrence.status = :status '
    'AND (Month.year < :year OR (Month.year = :year AND Month.month <= :month)) '
    'ORDER BY Month.year DESC, Month.month DESC, DebtOccurrence.dueDay ASC',
  )
  Future<List<DebtOccurrence>> findPendingOccurrencesUpToMonth(
    int month,
    int year,
    String status,
  );

  @Query(
    'SELECT COUNT(*) FROM DebtOccurrence '
    'WHERE debtDefinitionId = :debtDefinitionId AND monthId = :monthId',
  )
  Future<int?> countByDefinitionAndMonth(int debtDefinitionId, int monthId);

  @insert
  Future<int> insertDebtOccurrence(DebtOccurrence debtOccurrence);

  @update
  Future<void> updateDebtOccurrence(DebtOccurrence debtOccurrence);

  @delete
  Future<void> deleteDebtOccurrence(DebtOccurrence debtOccurrence);
}
