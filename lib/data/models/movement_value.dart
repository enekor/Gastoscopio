import 'package:floor/floor.dart';

@entity
class MovementValue {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int monthId; // Foreign key referencing Month
  final String description;
  final double amount;
  final bool isExpense;
  final int day;
  String? category;

  MovementValue(
    this.id,
    this.monthId,
    this.description,
    this.amount,
    this.isExpense,
    this.day,
    this.category,
  );

  MovementValue copyWith({
    int? id,
    int? monthId,
    String? description,
    double? amount,
    bool? isExpense,
    int? day,
    String? category,
  }) {
    return MovementValue(
      id ?? this.id,
      monthId ?? this.monthId,
      description ?? this.description,
      amount ?? this.amount,
      isExpense ?? this.isExpense,
      day ?? this.day,
      category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': description,
      'amount': amount,
      'isExpense': isExpense,
      'day': day,
      'category': category,
    };
  }
}
