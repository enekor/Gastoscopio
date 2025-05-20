import 'package:cashly/data/models/month.dart';
import 'package:floor/floor.dart';

@dao
abstract class MonthDao {
  @Query('SELECT * FROM Month')
  Future<List<Month>> findAllMonths();

  @Query('SELECT * FROM Month WHERE id = :id')
  Stream<Month?> findMonthById(int id);

  @insert
  Future<void> insertMonth(Month month);

  @update
  Future<void> updateMonth(Month month);

  @delete
  Future<void> deleteMonth(Month month);
}
