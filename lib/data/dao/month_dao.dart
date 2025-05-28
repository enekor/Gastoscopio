import 'package:cashly/data/models/month.dart';
import 'package:floor/floor.dart';

@dao
abstract class MonthDao {
  @Query('SELECT * FROM Month')
  Future<List<Month>> findAllMonths();

  @Query('SELECT * FROM Month WHERE id = :id')
  Stream<Month?> findMonthById(int id);

  @Query('SELECT * FROM Month WHERE month = :month AND year = :year')
  Stream<Month?> findMonthByMonthAndYear(int month, int year);
  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertMonth(Month month);

  @update
  Future<void> updateMonth(Month month);

  @delete
  Future<void> deleteMonth(Month month);
}
