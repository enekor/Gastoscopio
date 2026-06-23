import 'package:floor/floor.dart';
import 'package:cashly/data/models/credit_card_month.dart';

@dao
abstract class CreditCardMonthDao {
  @Query('SELECT * FROM CreditCardMonth WHERE month = :month AND year = :year')
  Future<CreditCardMonth?> findMonth(int month, int year);

  @Query('SELECT * FROM CreditCardMonth ORDER BY year DESC, month DESC')
  Future<List<CreditCardMonth>> findAllMonths();

  @insert
  Future<int> insertMonth(CreditCardMonth month);

  @update
  Future<void> updateMonth(CreditCardMonth month);
}
