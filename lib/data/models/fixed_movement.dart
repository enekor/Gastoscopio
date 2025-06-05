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
      day ?? this.day,
      category ?? this.category,
    );
  }
}
