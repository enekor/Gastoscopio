import 'package:cashly/data/models/movement_value.dart';
import 'package:floor/floor.dart';

@entity
class FixedMovement {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String description;
  final double amount;
  final bool isExpense;
  final int day;
  String? category;

  FixedMovement(
    this.id,
    this.description,
    this.amount,
    this.isExpense,
    this.day,
    this.category,
  );

  MovementValue toMovementValue(int monthId) {
    return MovementValue(
      null, // ID will be auto-generated
      monthId,
      description,
      amount,
      isExpense,
      day,
      category,
    );
  }

  FixedMovement copyWith({
    int? id,
    String? description,
    double? amount,
    bool? isExpense,
    int? day,
    String? category,
  }) {
    return FixedMovement(
      id ?? this.id,
      description ?? this.description,
      amount ?? this.amount,
      isExpense ?? this.isExpense,
      _adjustDayForMonth(day ?? this.day),
      category ?? this.category,
    );
  }

  int _adjustDayForMonth(int day) {
    // Ensure day is within valid range (1-28 to be safe for all months)
    return DateTime.now().day > day &&
            DateTime.now().month == DateTime.now().month
        ? DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day
        : day <= DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day
        ? day
        : DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
  }
}
