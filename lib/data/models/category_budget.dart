import 'package:floor/floor.dart';

@entity
class CategoryBudget {
  @PrimaryKey(autoGenerate: true)
  final int? id;

  @ColumnInfo(name: 'category')
  final String category;

  @ColumnInfo(name: 'monthlyLimit')
  final double monthlyLimit;

  CategoryBudget({
    this.id,
    required this.category,
    required this.monthlyLimit,
  });

  CategoryBudget copyWith({int? id, String? category, double? monthlyLimit}) {
    return CategoryBudget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'monthlyLimit': monthlyLimit,
    };
  }
}
