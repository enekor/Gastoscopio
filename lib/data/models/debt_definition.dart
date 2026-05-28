import 'package:floor/floor.dart';

const String debtRecurrenceMonthly = 'monthly';
const String debtRecurrenceOneTime = 'oneTime';

@Entity(tableName: 'DebtDefinition')
class DebtDefinition {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String description;
  final double amount;
  final bool isExpense;
  final String? category;
  final String recurrenceType;
  final int startDay;
  final int startMonth;
  final int startYear;
  final bool isActive;

  DebtDefinition(
    this.id,
    this.description,
    this.amount,
    this.isExpense,
    this.category,
    this.recurrenceType,
    this.startDay,
    this.startMonth,
    this.startYear,
    this.isActive,
  );

  DebtDefinition copyWith({
    int? id,
    String? description,
    double? amount,
    bool? isExpense,
    String? category,
    String? recurrenceType,
    int? startDay,
    int? startMonth,
    int? startYear,
    bool? isActive,
  }) {
    return DebtDefinition(
      id ?? this.id,
      description ?? this.description,
      amount ?? this.amount,
      isExpense ?? this.isExpense,
      category ?? this.category,
      recurrenceType ?? this.recurrenceType,
      startDay ?? this.startDay,
      startMonth ?? this.startMonth,
      startYear ?? this.startYear,
      isActive ?? this.isActive,
    );
  }
}
