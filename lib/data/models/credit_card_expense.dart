import 'package:floor/floor.dart';
import 'package:cashly/data/models/credit_card_month.dart';

@Entity(
  foreignKeys: [
    ForeignKey(
      childColumns: ['monthId'],
      parentColumns: ['id'],
      entity: CreditCardMonth,
      onDelete: ForeignKeyAction.cascade,
    )
  ],
)
class CreditCardExpense {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int monthId;
  final String description;
  final double amount;
  final int day;
  final String date;
  final String uuid;
  final int ts;

  CreditCardExpense({
    this.id,
    required this.monthId,
    required this.description,
    required this.amount,
    required this.day,
    required this.date,
    required this.uuid,
    required this.ts,
  });
}
