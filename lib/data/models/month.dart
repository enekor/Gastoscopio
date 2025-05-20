import 'package:floor/floor.dart';

@entity
class Month {
  @primaryKey
  final int id;
  final int month;
  final int year;

  Month(this.id, this.month, this.year);
}
