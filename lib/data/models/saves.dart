import 'package:floor/floor.dart';

@entity
class Saves {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int monthId;
  final double amount;
  @ColumnInfo(name: 'date')
  String dateStr;
  final bool isInitialValue;

  DateTime get date => DateTime.parse(dateStr);
  void set date(DateTime date) {
    dateStr = date.toString();
  }

  Saves({
    this.id,
    required this.monthId,
    required this.amount,
    required this.isInitialValue,
    required this.dateStr,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthId': monthId,
      'amount': amount,
      'isInitialValue': isInitialValue,
      'date': dateStr,
    };
  }
}
