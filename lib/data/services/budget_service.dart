import 'package:cashly/data/dao/category_budget_dao.dart';
import 'package:cashly/data/dao/movement_value_dao.dart';
import 'package:cashly/data/models/category_budget.dart';
import 'package:cashly/data/models/movement_value.dart';

class CategorySpend {
  final String category;
  final double spent;
  final double? limit;

  CategorySpend({required this.category, required this.spent, this.limit});

  bool get hasLimit => limit != null && limit! > 0;

  double get progress {
    if (!hasLimit) return 0;
    return (spent / limit!).clamp(0.0, double.infinity);
  }

  bool get isExceeded => hasLimit && spent > limit!;

  bool get isNearLimit => hasLimit && !isExceeded && progress >= 0.8;
}

class BudgetService {
  final CategoryBudgetDao _budgetDao;
  final MovementValueDao _movementValueDao;

  BudgetService(this._budgetDao, this._movementValueDao);

  Future<List<CategoryBudget>> getAll() => _budgetDao.findAll();

  Future<CategoryBudget?> getByCategory(String category) =>
      _budgetDao.findByCategory(category);

  Future<void> setBudget(String category, double monthlyLimit) async {
    final existing = await _budgetDao.findByCategory(category);
    if (existing == null) {
      await _budgetDao.insertBudget(
        CategoryBudget(category: category, monthlyLimit: monthlyLimit),
      );
    } else {
      await _budgetDao.updateBudget(
        existing.copyWith(monthlyLimit: monthlyLimit),
      );
    }
  }

  Future<void> removeBudget(String category) =>
      _budgetDao.deleteByCategory(category);

  /// Returns per-category spend with the associated limit (if any) for the
  /// given monthId. Only includes categories that have either spend or a limit.
  Future<List<CategorySpend>> getSpendForMonth(int monthId) async {
    final movements = await _movementValueDao.findMovementValuesByMonthIdAndType(
      monthId,
      true, // expenses only
    );
    final budgets = await _budgetDao.findAll();
    return _combine(movements, budgets);
  }

  List<CategorySpend> _combine(
    List<MovementValue> expenses,
    List<CategoryBudget> budgets,
  ) {
    final spendByCat = <String, double>{};
    for (final m in expenses) {
      final cat = m.category;
      if (cat == null || cat.isEmpty) continue;
      spendByCat[cat] = (spendByCat[cat] ?? 0) + m.amount;
    }

    final budgetMap = {for (final b in budgets) b.category: b.monthlyLimit};
    final keys = <String>{...spendByCat.keys, ...budgetMap.keys};

    final result = keys
        .map((cat) => CategorySpend(
              category: cat,
              spent: spendByCat[cat] ?? 0,
              limit: budgetMap[cat],
            ))
        .toList();

    result.sort((a, b) {
      // Exceeded first, then near limit, then rest by spent desc
      if (a.isExceeded != b.isExceeded) return a.isExceeded ? -1 : 1;
      if (a.isNearLimit != b.isNearLimit) return a.isNearLimit ? -1 : 1;
      return b.spent.compareTo(a.spent);
    });

    return result;
  }
}
