import 'package:floor/floor.dart';

@entity
class Saves {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final int monthId;
  final double amount;

  final bool isInitialValue;

  Saves({
    this.id,
    required this.monthId,
    required this.amount,
    required this.isInitialValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthId': monthId,
      'amount': amount,
      'isInitialValue': isInitialValue,
    };
  }
}
