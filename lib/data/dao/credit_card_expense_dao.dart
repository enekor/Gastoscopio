import 'package:floor/floor.dart';
import 'package:cashly/data/models/credit_card_expense.dart';

@dao
abstract class CreditCardExpenseDao {
  @Query('SELECT * FROM CreditCardExpense WHERE monthId = :monthId ORDER BY day DESC, id DESC')
  Future<List<CreditCardExpense>> findExpensesByMonthId(int monthId);

  @insert
  Future<int> insertExpense(CreditCardExpense expense);

  @delete
  Future<void> deleteExpense(CreditCardExpense expense);
}
