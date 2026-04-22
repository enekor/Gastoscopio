import 'package:floor/floor.dart';

@entity
class SavingsGoal {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  final String name;

  @ColumnInfo(name: 'targetAmount')
  final double targetAmount;

  @ColumnInfo(name: 'currentAmount')
  final double currentAmount;

  @ColumnInfo(name: 'iconName')
  final String iconName;

  @ColumnInfo(name: 'createdAt')
  final String createdAt;

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.iconName,
    required this.createdAt,
  });

  SavingsGoal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? iconName,
    String? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentAmount >= targetAmount && targetAmount > 0;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'iconName': iconName,
      'createdAt': createdAt,
    };
  }
}
