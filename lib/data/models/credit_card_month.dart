import 'package:floor/floor.dart';

@entity
class CreditCardMonth {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int month;
  final int year;
  final double limitAmount;

  CreditCardMonth({
    this.id,
    required this.month,
    required this.year,
    required this.limitAmount,
  });
}
