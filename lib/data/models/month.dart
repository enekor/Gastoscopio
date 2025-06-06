import 'package:floor/floor.dart';

@entity
class Month {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int month;
  final int year;

  Month(this.month, this.year, {this.id});
}
