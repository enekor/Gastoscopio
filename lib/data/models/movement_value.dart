import 'package:floor/floor.dart';

@entity
class MovementValue {
  @primaryKey
  final int id;
  final int monthId; // Foreign key referencing Month
  final String description;
  final double amount;
  final bool isExpense;
  final int day;
  final String? category;

  MovementValue(
    this.id,
    this.monthId,
    this.description,
    this.amount,
    this.isExpense,
    this.day,
    this.category,
  );
}
